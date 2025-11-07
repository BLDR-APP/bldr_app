import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  bool _isLoading = false;
  bool _canResend = true;
  int _resendTimer = 60;
  Timer? _timer;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    // <<< CORREÇÃO: _checkEmailConfirmationStatus() removido >>>
    // O novo fluxo de deep link é reativo e não precisa
    // que esta tela verifique o status manualmente.
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    _userEmail = AuthService.instance.getCurrentUserEmail();
    if (mounted) setState(() {});
  }

  // <<< CORREÇÃO: Método _checkEmailConfirmationStatus removido >>>

  Future<void> _handleResendConfirmation() async {
    if (!_canResend || _userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      // <<< CORREÇÃO: Ajuste na chamada da função >>>
      await AuthService.instance.resendConfirmationEmail(
        email: _userEmail!,
        emailRedirectTo: 'bldr://email-confirmation', // <-- Adicionado
      );

      // Se não deu erro, foi sucesso.
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('E-mail de confirmação reenviado'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating));

      // <<< 'else' removido (não é mais necessário) >>>

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao reenviar e-mail: ${error.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // <<< CORREÇÃO: Método _handleManualCheck removido >>>

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 8.h),

                      // Email Icon
                      Container(
                          width: 25.w,
                          height: 25.w,
                          decoration: BoxDecoration(
                              color: AppTheme.accentGold.withValues(alpha: 0.2),
                              shape: BoxShape.circle),
                          child: Icon(Icons.mark_email_read_outlined,
                              color: AppTheme.accentGold, size: 12.w)),
                      SizedBox(height: 4.h),

                      // Header
                      Text('Confirme seu E-mail',
                          style: AppTheme.darkTheme.textTheme.displaySmall
                              ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 24.sp),
                          textAlign: TextAlign.center),
                      SizedBox(height: 2.h),

                      // Description
                      Text('Enviamos um e-mail de confirmação para:',
                          style: AppTheme.darkTheme.textTheme.bodyLarge
                              ?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 14.sp),
                          textAlign: TextAlign.center),
                      SizedBox(height: 1.h),

                      // User Email
                      Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 2.h),
                          decoration: BoxDecoration(
                              color: AppTheme.cardDark.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.accentGold
                                      .withValues(alpha: 0.3),
                                  width: 1)),
                          child: Text(_userEmail ?? 'Carregando...',
                              style: AppTheme.darkTheme.textTheme.bodyLarge
                                  ?.copyWith(
                                  color: AppTheme.accentGold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp),
                              textAlign: TextAlign.center)),
                      SizedBox(height: 4.h),

                      // Instructions
                      Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                              color: AppTheme.cardDark.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppTheme.accentGold
                                      .withValues(alpha: 0.2),
                                  width: 1)),
                          child: Column(children: [
                            Icon(Icons.info_outline,
                                color: AppTheme.accentGold, size: 6.w),
                            SizedBox(height: 2.h),
                            Text(
                                'Clique no link do e-mail para confirmar sua conta e continuar com o processo de cadastro.',
                                style: AppTheme.darkTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13.sp,
                                    height: 1.5),
                                textAlign: TextAlign.center),
                          ])),
                      SizedBox(height: 6.h),

                      // Action Buttons
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // <<< CORREÇÃO: Botão "Verificar Confirmação" removido >>>

                            // Resend Email Button
                            ElevatedButton(
                                onPressed: (_canResend && !_isLoading)
                                    ? _handleResendConfirmation
                                    : null,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentGold, // Estilo de botão principal
                                    foregroundColor: AppTheme.primaryBlack, // Estilo de botão principal
                                    padding:
                                    EdgeInsets.symmetric(vertical: 4.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    )),
                                child: Text(
                                    _canResend
                                        ? 'Reenviar E-mail'
                                        : 'Reenviar em ${_resendTimer}s',
                                    style: AppTheme
                                        .darkTheme.textTheme.titleMedium
                                        ?.copyWith(
                                        color: _canResend
                                            ? AppTheme.primaryBlack // Cor do texto do botão principal
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600))),
                            SizedBox(height: 4.h),

                            // Back to Login
                            TextButton(
                                onPressed: () async {
                                  await AuthService.instance.signOut();
                                  Navigator.pushNamedAndRemoveUntil(context,
                                      AppRoutes.loginScreen, (route) => false);
                                },
                                child: Text('Voltar ao Login',
                                    style: AppTheme
                                        .darkTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                        color: AppTheme.accentGold,
                                        fontWeight: FontWeight.w600))),
                          ]),
                    ]))));
  }
}