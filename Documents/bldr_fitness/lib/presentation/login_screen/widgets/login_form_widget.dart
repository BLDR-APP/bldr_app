import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💡 Import necessário

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';

// 💡 Chave para SharedPreferences
const String _kRememberMeEmailKey = 'rememberMeEmail';

class LoginFormWidget extends StatefulWidget {
  final Function(String, String)? onLogin;
  final bool isLoading;

  const LoginFormWidget({
    Key? key,
    this.onLogin,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 💡 Chamada para carregar o e-mail salvo
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 💡 Implementação da lógica de SharedPreferences
  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kRememberMeEmailKey);

    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberMeState(bool value, String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      // Salva o e-mail se 'Lembrar-me' estiver marcado
      await prefs.setString(_kRememberMeEmailKey, email);
    } else {
      // Remove o e-mail se 'Lembrar-me' estiver desmarcado
      await prefs.remove(_kRememberMeEmailKey);
    }
    setState(() {
      _rememberMe = value;
    });
  }
  // Fim da implementação da lógica de SharedPreferences

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 💡 Salva o estado do 'Lembrar-me' ANTES do login
    await _saveRememberMeState(_rememberMe, email);

    // Call the onLogin callback if provided
    if (widget.onLogin != null) {
      widget.onLogin!(email, password);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signIn(
          email: email,
          password: password);

      if (response.user != null) {
        // ... (resto da lógica de navegação)
        // Check if email confirmation is needed
        final needsConfirmation =
        await AuthService.instance.needsEmailConfirmation();

        if (needsConfirmation) {
          _showEmailConfirmationDialog();
        } else {
          // Navigate to dashboard or onboarding based on profile completion
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      }
    } catch (error) {
      String errorMessage = error.toString().replaceAll('Exception: ', '');

      // Handle specific error cases
      if (errorMessage.contains('Invalid login credentials')) {
        errorMessage = 'E-mail ou senha incorretos';
      } else if (errorMessage.contains('Email not confirmed')) {
        errorMessage = 'Por favor confirme seu e-mail antes de fazer login';
        _showEmailConfirmationDialog();
        return;
      } else if (errorMessage.contains('Too many requests')) {
        errorMessage = 'Muitas tentativas. Tente novamente em alguns minutos';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailConfirmationDialog() {
    // ... (Mantido inalterado)
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              Icon(Icons.email_outlined,
                  color: AppTheme.accentGold, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                  child: Text('E-mail não confirmado',
                      style: AppTheme.darkTheme.textTheme.titleLarge
                          ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600))),
            ]),
            content: Text(
                'Você precisa confirmar seu e-mail antes de fazer login. Verifique sua caixa de entrada e clique no link de confirmação.',
                style: AppTheme.darkTheme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () async {
                    try {
                      final success = await AuthService.instance
                          .resendConfirmationEmail(
                          email: _emailController.text.trim());

                      if (mounted) Navigator.of(context).pop();

                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                              Text('E-mail de confirmação reenviado'),
                              backgroundColor: AppTheme.successGreen,
                              behavior: SnackBarBehavior.floating));
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                              Text('Aguarde antes de reenviar novamente'),
                              behavior: SnackBarBehavior.floating));
                        }
                      }
                    } catch (error) {
                      if (mounted) Navigator.of(context).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erro ao reenviar e-mail'),
                            backgroundColor: AppTheme.errorRed,
                            behavior: SnackBarBehavior.floating));
                      }
                    }
                  },
                  child: Text('Reenviar',
                      style: TextStyle(color: AppTheme.accentGold))),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack),
                  child: Text('OK')),
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
            color: AppTheme.cardDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3), width: 1)),
        child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Bem-Vindo!',
                      style: AppTheme.darkTheme.textTheme.headlineSmall
                          ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  SizedBox(height: 1.h),
                  Text('Faça login para continuar sua jornada fitness',
                      style: AppTheme.darkTheme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                  SizedBox(height: 4.h),

                  // Email Field
                  TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Insira seu endereço de e-mail',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppTheme.accentGold)),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'E-mail é obrigatório';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value!)) {
                          return 'Insira um endereço de e-mail válido';
                        }
                        return null;
                      }),
                  SizedBox(height: 2.h),

                  // Password Field
                  TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Insira sua senha',
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppTheme.accentGold),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              })),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Senha é obrigatória';
                        }
                        return null;
                      }),
                  SizedBox(height: 2.h),

                  // Remember Me and Forgot Password
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                // 💡 Chamada da nova função de salvar estado
                                _saveRememberMeState(value ?? false, _emailController.text.trim());
                              },
                              activeColor: AppTheme.accentGold,
                              checkColor: AppTheme.primaryBlack),
                          Text('Lembrar-me',
                              style: AppTheme.darkTheme.textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary)),
                        ]),
                        GestureDetector(
                            onTap: () {
                              // Handle forgot password
                              _showForgotPasswordDialog();
                            },
                            child: Text('Esqueceu a senha?',
                                style: AppTheme.darkTheme.textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.accentGold))),
                      ]),
                  SizedBox(height: 3.h),

                  // Sign In Button
                  ElevatedButton(
                      onPressed: widget.isLoading || _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.primaryBlack,
                          padding: EdgeInsets.symmetric(vertical: 4.w),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: widget.isLoading || _isLoading
                          ? SizedBox(
                          height: 5.w,
                          width: 5.w,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlack)))
                          : Text('Entrar',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.w600))),
                  SizedBox(height: 3.h),

                  // Sign Up Link
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Não possui uma conta? ',
                        style: AppTheme.darkTheme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary)),
                    GestureDetector(
                        onTap: () {
                          if (mounted) Navigator.pushNamed(context, AppRoutes.signUpScreen);
                        },
                        child: Text('Criar conta',
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w600))),
                  ]),
                ])));
  }

  void _showForgotPasswordDialog() {
    // ... (Mantido inalterado)
    final emailController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Recuperar Senha',
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                  'Insira seu e-mail para receber um link de recuperação de senha.',
                  style: AppTheme.darkTheme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary)),
              SizedBox(height: 2.h),
              TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.darkTheme.textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Insira seu e-mail',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppTheme.accentGold))),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar',
                      style: TextStyle(color: AppTheme.textSecondary))),
              ElevatedButton(
                  onPressed: () async {
                    try {
                      await AuthService.instance.resetPassword(
                          email: emailController.text.trim());

                      if (mounted) Navigator.of(context).pop();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('E-mail de recuperação enviado'),
                            backgroundColor: AppTheme.successGreen,
                            behavior: SnackBarBehavior.floating));
                      }
                    } catch (error) {
                      if (mounted) Navigator.of(context).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                            Text('Erro ao enviar e-mail de recuperação'),
                            backgroundColor: AppTheme.errorRed,
                            behavior: SnackBarBehavior.floating));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack),
                  child: Text('Enviar')),
            ]));
  }
}