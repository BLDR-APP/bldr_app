import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import './password_strength_indicator.dart';

class SignUpForm extends StatefulWidget {
  final VoidCallback? onSignUpSuccess;

  const SignUpForm({Key? key, this.onSignUpSuccess}) : super(key: key);

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _showEmailConfirmation = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Por favor concorde com os Termos de Serviço'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // <<< CORREÇÃO 1: Adicionado o 'emailRedirectTo' >>>
      final response = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        emailRedirectTo: 'bldr://email-confirmation',
      );

      // <<< CORREÇÃO 2: Lógica simplificada >>>
      // Se o 'signUp' foi bem-sucedido (não deu erro) e o
      // 'Confirm Email' está ativo no Supabase, o usuário *sempre*
      // precisará confirmar.
      if (response.user != null) {
        setState(() {
          _showEmailConfirmation = true;
          _isLoading = false;
        });
      } else {
        // Isso pode acontecer se o usuário já existir mas não estiver confirmado
        setState(() {
          _showEmailConfirmation = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Erro no cadastro: ${error.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted && !_showEmailConfirmation) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendConfirmation() async {
    try {
      // <<< CORREÇÃO 3: Lógica ajustada para a nova função (void) >>>
      // A nova função não retorna 'bool' e requer 'emailRedirectTo'.
      await AuthService.instance.resendConfirmationEmail(
        email: _emailController.text.trim(),
        emailRedirectTo: 'bldr://email-confirmation', // <-- Adicionado
      );

      // Se o 'await' acima não deu erro, foi um sucesso.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('E-mail de confirmação reenviado'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating));

      // Removemos o 'else'. O Supabase já tem um rate-limit que
      // vai disparar um 'Exception' (pego pelo 'catch') se o
      // usuário tentar reenviar rápido demais.

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao reenviar e-mail: ${error.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showEmailConfirmation) {
      return _buildEmailConfirmationView();
    }

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
                  Text('Juntar-se a BLDR',
                      style: AppTheme.darkTheme.textTheme.headlineSmall
                          ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  SizedBox(height: 1.h),
                  Text('Começe sua transformação fitness hoje',
                      style: AppTheme.darkTheme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                  SizedBox(height: 4.h),

                  // Full Name Field
                  TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: 'Nome completo',
                          hintText: 'Insira seu nome completo',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppTheme.accentGold)),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Nome completo é obrigatório';
                        }
                        if (value!.trim().length < 2) {
                          return 'Nome completo deve ter pelo menos 2 caractéres';
                        }
                        return null;
                      }),
                  SizedBox(height: 2.h),

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
                          return 'Senha é obrigatório';
                        }
                        if (value!.length < 8) {
                          return 'Senha deverá conter 8 caractéres';
                        }
                        if (!value.contains(RegExp(r'[A-Z]'))) {
                          return 'Senha deverá conter pelo menos um caractére em maiúsculo';
                        }
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return 'Senha deverá conter pelo menos um número';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(
                                () {}); // Trigger rebuild for password strength indicator
                      }),
                  SizedBox(height: 1.h),

                  // Password Strength Indicator
                  if (_passwordController.text.isNotEmpty)
                    PasswordStrengthIndicator(
                        password: _passwordController.text),

                  SizedBox(height: 2.h),

                  // Confirm Password Field
                  TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          hintText: 'Confirme sua senha',
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppTheme.accentGold),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                                });
                              })),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Por favor confirme sua senha';
                        }
                        if (value != _passwordController.text) {
                          return 'Senhas não coincidem';
                        }
                        return null;
                      }),
                  SizedBox(height: 3.h),

                  // Terms and Conditions
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppTheme.accentGold,
                        checkColor: AppTheme.primaryBlack),
                    Expanded(
                        child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child: Text(
                                'Eu concordo com os Termos de Serviço e Privacidade',
                                style: AppTheme.darkTheme.textTheme.bodySmall
                                    ?.copyWith(
                                    color: AppTheme.textSecondary)))),
                  ]),
                  SizedBox(height: 3.h),

                  // Sign Up Button
                  ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.primaryBlack,
                          padding: EdgeInsets.symmetric(vertical: 4.w),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _isLoading
                          ? SizedBox(
                          height: 5.w,
                          width: 5.w,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlack)))
                          : Text('Criar Conta',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.w600))),
                  SizedBox(height: 3.h),

                  // Sign In Link
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Já possui uma conta? ',
                        style: AppTheme.darkTheme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary)),
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text('Entrar',
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w600))),
                  ]),
                ])));
  }

  Widget _buildEmailConfirmationView() {
    return Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
            color: AppTheme.cardDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Success Icon
          Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: Icon(Icons.email_outlined,
                  color: AppTheme.accentGold, size: 8.w)),
          SizedBox(height: 4.h),

          Text('Confirme seu E-mail',
              style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          SizedBox(height: 2.h),

          Text('Enviamos um e-mail de confirmação para:',
              style: AppTheme.darkTheme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          SizedBox(height: 1.h),

          Text(_emailController.text,
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentGold, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          SizedBox(height: 3.h),

          Text('Clique no link do e-mail para confirmar sua conta e continuar.',
              style: AppTheme.darkTheme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          SizedBox(height: 4.h),

          // Resend Button
          TextButton(
              onPressed: _handleResendConfirmation,
              child: Text('Reenviar E-mail',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600))),
          SizedBox(height: 2.h),

          // Back to Login Button
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardDark,
                  foregroundColor: AppTheme.textPrimary,
                  padding: EdgeInsets.symmetric(vertical: 3.w, horizontal: 8.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: AppTheme.accentGold.withValues(alpha: 0.3)))),
              child: Text('Voltar ao Login',
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600))),
        ]));
  }
}