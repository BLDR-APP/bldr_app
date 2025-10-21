import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../../../theme/app_theme.dart';

class PaymentFormWidget extends StatelessWidget {
  final VoidCallback onPaymentProcess;
  final bool isProcessing;
  final String? errorMessage;
  final String? successMessage;

  const PaymentFormWidget({
    super.key,
    required this.onPaymentProcess,
    required this.isProcessing,
    this.errorMessage,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações do Cartão',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerGray),
          ),
          child: stripe.CardField(
            onCardChanged: (card) {
              if (kDebugMode) {
                print('Card changed: ${card?.complete}');
              }
            },
            decoration: InputDecoration(
              labelText: 'Dados do Cartão',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              border: InputBorder.none,
              helperText: 'Digite o número, validade e CVV do seu cartão',
              helperStyle: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (kDebugMode)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withAlpha(26),
              border: Border.all(color: AppTheme.warningAmber.withAlpha(77)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cartões de Teste (Modo Desenvolvimento):',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.warningAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('• Sucesso: 4242 4242 4242 4242', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                Text('• Recusado: 4000 0000 0000 9995', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                Text('• Use qualquer data futura e CVV válido', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withAlpha(26),
              border: Border.all(color: AppTheme.errorRed.withAlpha(77)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error, color: AppTheme.errorRed, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isProcessing ? null : onPaymentProcess,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.textVariant,
              disabledBackgroundColor: AppTheme.inactiveGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isProcessing
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.textVariant,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Processando...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Finalizar Pagamento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}