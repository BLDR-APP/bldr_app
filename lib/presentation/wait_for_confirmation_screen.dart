import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/auth_service.dart';

class WaitForConfirmationScreen extends StatefulWidget {
  const WaitForConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<WaitForConfirmationScreen> createState() => _WaitForConfirmationScreenState();
}

class _WaitForConfirmationScreenState extends State<WaitForConfirmationScreen> {
  bool _isResending = false;

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);

    // Você está pegando o e-mail do usuário logado (mas não confirmado). Isso está correto.
    final email = AuthService.instance.currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível encontrar o e-mail do usuário.')),
      );
      setState(() => _isResending = false);
      return;
    }

    try {
      // <<< CORREÇÃO AQUI >>>
      // Adicionamos o 'emailRedirectTo' para bater com a nova assinatura
      // da função no AuthService.
      await AuthService.instance.resendConfirmationEmail(
        email: email,
        emailRedirectTo: 'bldr://email-confirmation',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail de confirmação reenviado com sucesso!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reenviar e-mail: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              color: AppTheme.accentGold,
              size: 20.w,
            ),
            SizedBox(height: 4.h),
            Text(
              'Confirme seu E-mail',
              textAlign: TextAlign.center,
              style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Enviamos um link de confirmação para o seu endereço de e-mail. Por favor, clique no link para ativar sua conta.',
              textAlign: TextAlign.center,
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 6.h),
            ElevatedButton(
              onPressed: _isResending ? null : _resendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: _isResending
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryBlack,
                ),
              )
                  : Text(
                'Reenviar E-mail',
                style: TextStyle(color: AppTheme.primaryBlack),
              ),
            ),
            SizedBox(height: 2.h),
            TextButton(
              onPressed: () {
                AuthService.instance.signOut(); // Desloga o usuário não confirmado
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.loginScreen,
                      (route) => false,
                );
              },
              child: const Text(
                'Voltar para o Login',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}