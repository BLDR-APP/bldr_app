import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import para kDebugMode
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';

class CouponWidget extends StatefulWidget {
  // 💡 O primeiro parâmetro agora é o ID do Stripe para ser usado na próxima requisição
  final Function(String couponId, double discountDisplay) onCouponApplied;
  final VoidCallback onCouponRemoved;
  final Function(String error) onCouponError;

  final String? appliedCouponCode;
  final double discount;
  final int? subtotalCents;

  const CouponWidget({
    Key? key,
    required this.onCouponApplied,
    required this.onCouponRemoved,
    required this.onCouponError,
    this.appliedCouponCode,
    required this.discount,
    this.subtotalCents,
  }) : super(key: key);

  @override
  State<CouponWidget> createState() => _CouponWidgetState();
}

class _CouponWidgetState extends State<CouponWidget> {
  final TextEditingController _couponController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      widget.onCouponError('Informe um código de cupom');
      return;
    }

    // Limpa o cupom anterior antes de validar um novo
    widget.onCouponRemoved();
    setState(() => _isValidating = true);

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;

      // 💡 1. URL CORRETO: Chama a Edge Function de VALIDAÇÃO SEPARADA
      final uri = Uri.parse(
        'https://vhxwujoymxkxyiognual.supabase.co/functions/v1/validate-coupon',
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // 💡 2. CORPO DA REQUISIÇÃO: Envia SÓ o código
      final body = jsonEncode({'code': code});

      final resp = await http.post(uri, headers: headers, body: body);

      // ===== DEBUG: imprime tudo no console do app =====
      if (kDebugMode) {
        print('[COUPON] POST $uri');
        print('[COUPON] body (req): $body');
        print('[COUPON] status: ${resp.statusCode}');
        print('[COUPON] resp.body: ${resp.body}');
      }
      // =================================================

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;

        // 💡 3. RECEBE O coupon_id DO STRIPE E DETALHES DO DESCONTO
        final couponId = data['coupon_id'] as String?;
        final type = (data['discountType'] as String?) ?? 'percentage';
        final discountValue = (data['discountValue'] as num?)?.toDouble() ?? 0.0;

        if (couponId == null) throw Exception('Validação bem-sucedida, mas ID do cupom ausente.');

        double displayDiscount = 0.0;

        // Lógica para calcular o valor do desconto para exibição
        if (type == 'fixed') {
          displayDiscount = discountValue;
        } else if (type == 'percent') {
          if (widget.subtotalCents != null) {
            // Aplica a porcentagem no subtotal (em centavos), divide por 100 para converter para reais
            final calc = (widget.subtotalCents! * (discountValue / 100)) / 100.0;
            displayDiscount = double.parse(calc.toStringAsFixed(2));
          }
        }

        // 💡 4. CHAMA onCouponApplied com o ID DO STRIPE
        widget.onCouponApplied(couponId, displayDiscount);
        _couponController.clear();
      } else {
        String msg = 'Erro ao validar cupom';
        try {
          // Tenta extrair a mensagem de erro do servidor
          final err = jsonDecode(resp.body) as Map<String, dynamic>;
          final serverMsg = (err['error'] ?? err['message'] ?? '').toString();
          if (serverMsg.isNotEmpty) msg = serverMsg;
        } catch (_) {
          msg = 'HTTP ${resp.statusCode}: ${resp.body}';
        }
        widget.onCouponError(msg);
      }
    } catch (e) {
      widget.onCouponError('Erro de conexão ao validar cupom: $e');
      if (kDebugMode) print('[COUPON] network error: $e');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _removeCoupon() {
    _couponController.clear();
    widget.onCouponRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final hasCoupon = widget.appliedCouponCode != null;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: AppTheme.accentGold, size: 20),
              SizedBox(width: 2.w),
              Text(
                'Código de Cupom',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          if (hasCoupon) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1), // Usando withOpacity
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.successGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Aqui você precisaria de uma lógica para mostrar o CÓDIGO
                          // digitado originalmente, se a variável appliedCouponCode
                          // estiver recebendo o ID do Stripe. Se você ajustou seu
                          // controller para passar o código original, isso funciona.
                          widget.appliedCouponCode!,
                          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.discount > 0.0)
                          Text(
                            'R\$ ${widget.discount.toStringAsFixed(2)} de desconto',
                            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.successGreen,
                            ),
                          )
                        else
                          Text(
                            'Cupom aplicado',
                            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.successGreen,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeCoupon,
                    icon: const Icon(Icons.close, color: AppTheme.successGreen, size: 20),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponController,
                    style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.dividerGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.accentGold, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.dividerGray),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      hintText: 'EX: BLDRFREE',
                      hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.inactiveGray,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    enabled: !_isValidating,
                  ),
                ),
                SizedBox(width: 3.w),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isValidating ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                    ),
                    child: _isValidating
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryBlack,
                      ),
                    )
                        : Text(
                      'Aplicar',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ],
      ),
    );
  }
}