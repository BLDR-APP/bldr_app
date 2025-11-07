import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <<< ADICIONADO IMPORT

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart'; // <<< Import Mantido
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

  // --- MODIFICADO: Função _handleLogin (Ajuste no try/catch) ---
  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Tenta fazer login
      final authResponse = await AuthService.instance.signIn(
        email: email,
        password: password,
      );

      // Verifica se o login foi bem-sucedido
      if (authResponse.user != null) {
        HapticFeedback.mediumImpact();

        // <<< CORREÇÃO AQUI >>>
        // A verificação de 'needsEmailConfirmation' foi removida.
        // Se o 'signIn' foi bem-sucedido, o e-mail JÁ está confirmado.
        // A lógica de 'e-mail não confirmado' agora é tratada no 'catch' block.

        // 3. Verifica se o onboarding JÁ foi completado (lógica original)
        final bool hasCompletedOnboarding = await UserService.instance.hasCompletedOnboarding();

        if (!mounted) return;

        if (hasCompletedOnboarding) {
          // --- INÍCIO DA ADIÇÃO: Verifica a VERSÃO se já completou ---
          const String currentOnboardingVersion = '2.0';
          bool versionMatches = false;

          try {
            final userId = authResponse.user!.id;
            final profileResponse = await Supabase.instance.client
                .from('user_profiles')
                .select('onboarding_data') // Busca apenas o JSON
                .eq('id', userId)
                .maybeSingle();

            if (profileResponse != null && profileResponse['onboarding_data'] is Map) {
              final onboardingDataMap = profileResponse['onboarding_data'] as Map<String, dynamic>;
              final savedVersion = onboardingDataMap['onboarding_version']?.toString() ?? '';
              if (savedVersion == currentOnboardingVersion) {
                versionMatches = true;
              }
            }
          } catch (e) {
            print("Erro ao verificar versão do onboarding: $e. Assumindo que precisa refazer.");
            versionMatches = false; // Força refazer em caso de erro
          }

          if (!mounted) return;

          // Navega baseado na versão
          if (versionMatches) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          } else {
            print("Versão do onboarding desatualizada ou não encontrada. Redirecionando para refazer.");
            Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
          }
          // --- FIM DA ADIÇÃO ---

        } else {
          // Se onboarding NÃO foi completado, vai para o onboarding (lógica original)
          Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
        }
        // <<< FIM DA CORREÇÃO >>>

      } else {
        // Falha no login (usuário/senha inválidos)
        setState(() {
          _errorMessage = 'Login falhou. Verifique suas credenciais.';
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      }
    } catch (error) {
      // Erro durante o processo
      print("Erro no handleLogin: $error");

      // <<< CORREÇÃO AQUI: LÓGICA DO CATCH >>>
      String displayError;

      if (error is AuthException) {
        displayError = error.message; // Mensagem da AuthException

        // Verifica se o erro é "Email not confirmed"
        if (displayError.contains('Email not confirmed')) {
          if (!mounted) return;
          // Navega para a tela de espera, como a lógica original queria
          Navigator.pushReplacementNamed(context, AppRoutes.waitForConfirmationScreen);

          // Não precisa setar _errorMessage, a próxima tela explica
          setState(() => _isLoading = false);
          HapticFeedback.lightImpact();
          return; // Sai da função
        }

      } else if (error is PostgrestException) {
        displayError = error.message; // Mensagem da PostgrestException
      } else {
        displayError = error.toString().replaceAll("Exception: ", ""); // Erro genérico
      }

      // Se NÃO for "Email not confirmed", mostra o erro
      setState(() {
        _errorMessage = 'Falha no login: ${displayError.replaceFirst("Exception: ", "")}';
        _isLoading = false;
      });
      HapticFeedback.lightImpact();
      // <<< FIM DA CORREÇÃO >>>
    }
  }
  // --- FIM DA MODIFICAÇÃO ---


  void _navigateToSignUp() {
    Navigator.pushNamed(context, AppRoutes.signUpScreen); // Ajustado para usar AppRoutes
  }

  // --- NOVO MÉTODO PARA O DIÁLOGO ---
  void _showProfessionalOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Acesso Profissional'),
          content: const Text('Você já possui uma conta profissional?'),
          actions: <Widget>[
            TextButton(child: const Text('Cadastrar'), onPressed: () { Navigator.of(dialogContext).pop(); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfessionalRegisterScreen())); }),
            TextButton(child: const Text('Entrar'), onPressed: () { Navigator.of(dialogContext).pop(); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfessionalLoginScreen())); }),
          ],
        );
      },
    );
  }
  // --- FIM ---

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
                      mainAxisSize: MainAxisSize.min, // Ajustado para evitar overflow
                      children: [
                        SizedBox(height: 15.h), // Reduzido espaço superior
                        // Mensagem de erro (se houver)
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                            margin: EdgeInsets.only(bottom: 2.h),
                            decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.errorRed.withOpacity(0.5))
                            ),
                            child: Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.w500),
                            ),
                          ),
                        // Formulário de Login
                        LoginFormWidget(
                          onLogin: _handleLogin,
                          isLoading: _isLoading,
                        ),
                        SizedBox(height: 3.h), // Espaço ajustado
                        // Botões "Sou Personal" / "Sou Nutricionista"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => _showProfessionalOptions(context),
                              child: Text('Sou Personal', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: Colors.white70, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () => _showProfessionalOptions(context),
                              child: Text('Sou Nutricionista', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: Colors.white70, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
                            ),
                          ],
                        ),
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