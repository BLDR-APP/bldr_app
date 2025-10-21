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
    _checkEmailConfirmationStatus();
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

  Future<void> _checkEmailConfirmationStatus() async {
    try {
      final status = await AuthService.instance.getEmailConfirmationStatus();

      if (status != null && status['email_confirmed'] == true) {
        // Email is already confirmed, navigate to onboarding
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
        }
      }
    } catch (error) {
      // Handle error silently, user can still use resend functionality
    }
  }

  Future<void> _handleResendConfirmation() async {
    if (!_canResend || _userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.instance
          .resendConfirmationEmail(email: _userEmail!);

      if (success) {
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('E-mail de confirmação reenviado'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Aguarde antes de reenviar novamente'),
            behavior: SnackBarBehavior.floating));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao reenviar e-mail: ${error.toString()}'),
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

  Future<void> _handleManualCheck() async {
    setState(() => _isLoading = true);

    try {
      // Check if email is now confirmed
      await _checkEmailConfirmationStatus();

      // If we're still here, email isn't confirmed yet
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'E-mail ainda não confirmado. Verifique sua caixa de entrada.'),
          behavior: SnackBarBehavior.floating));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao verificar confirmação'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                            // Check Again Button
                            ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleManualCheck,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentGold,
                                    foregroundColor: AppTheme.primaryBlack,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 4.w),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 5.w,
                                        width: 5.w,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppTheme.primaryBlack)))
                                    : Text('Verificar Confirmação',
                                        style: AppTheme
                                            .darkTheme.textTheme.titleMedium
                                            ?.copyWith(
                                                color: AppTheme.primaryBlack,
                                                fontWeight: FontWeight.w600))),
                            SizedBox(height: 2.h),

                            // Resend Email Button
                            ElevatedButton(
                                onPressed: (_canResend && !_isLoading)
                                    ? _handleResendConfirmation
                                    : null,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.cardDark,
                                    foregroundColor: AppTheme.textPrimary,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 4.w),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: AppTheme.accentGold
                                                .withValues(alpha: 0.3)))),
                                child: Text(
                                    _canResend
                                        ? 'Reenviar E-mail'
                                        : 'Reenviar em ${_resendTimer}s',
                                    style: AppTheme
                                        .darkTheme.textTheme.titleMedium
                                        ?.copyWith(
                                            color: _canResend
                                                ? AppTheme.textPrimary
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
