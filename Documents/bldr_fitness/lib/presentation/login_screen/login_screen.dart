import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
// -- INÍCIO DA ALTERAÇÃO: NOVOS IMPORTS --
import '../../features/professional_portal/presentation/screens/professional_login_screen.dart';
import '../../features/professional_portal/presentation/screens/professional_register_screen.dart';
// -- FIM DA ALTERAÇÃO --
import './widgets/login_form_widget.dart';
import './widgets/video_background_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  // Sua função _handleLogin original permanece 100% INTACTA
  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authResponse = await AuthService.instance.signIn(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        HapticFeedback.mediumImpact();

        final bool needsConfirmation =
        await AuthService.instance.needsEmailConfirmation();

        if (!mounted) return;

        if (needsConfirmation) {
          Navigator.pushReplacementNamed(
              context, AppRoutes.waitForConfirmationScreen);
        } else {
          final hasCompletedOnboarding =
          await UserService.instance.hasCompletedOnboarding();
          if (!mounted) return;

          if (hasCompletedOnboarding) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      }
    } catch (error) {
      setState(() {
        _errorMessage =
        'Login failed: ${error.toString().replaceFirst("Exception: ", "")}';
        _isLoading = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _navigateToSignUp() {
    Navigator.pushNamed(context, '/sign-up-screen');
  }

  // A função antiga de navegação direta não é mais usada, mas pode ser mantida ou removida.
  // void _navigateToProfessionalSignUp() { ... }

  // --- INÍCIO DA ALTERAÇÃO: NOVO MÉTODO PARA O DIÁLOGO ---
  void _showProfessionalOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Acesso Profissional'),
          content: const Text('Você já possui uma conta profissional?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cadastrar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                // Navega para a tela de registro que já existe
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfessionalRegisterScreen()),
                );
              },
            ),
            TextButton(
              child: const Text('Entrar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                // Navega para a NOVA tela de login profissional
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfessionalLoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }
  // --- FIM DA ALTERAÇÃO ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: VideoBackgroundWidget(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20.h),
                        if (_errorMessage.isNotEmpty)
                          Container(
                            // ... seu container de erro ...
                          ),
                        LoginFormWidget(
                          onLogin: _handleLogin,
                          isLoading: _isLoading,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              // --- INÍCIO DA ALTERAÇÃO: onPressed ATUALIZADO ---
                              onPressed: () => _showProfessionalOptions(context),
                              // --- FIM DA ALTERAÇÃO ---
                              child: Text(
                                'Sou Personal',
                                style: AppTheme.darkTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: Colors.white70,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white70,
                                ),
                              ),
                            ),
                            TextButton(
                              // --- INÍCIO DA ALTERAÇÃO: onPressed ATUALIZADO ---
                              onPressed: () => _showProfessionalOptions(context),
                              // --- FIM DA ALTERAÇÃO ---
                              child: Text(
                                'Sou Nutricionista',
                                style: AppTheme.darkTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: Colors.white70,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}