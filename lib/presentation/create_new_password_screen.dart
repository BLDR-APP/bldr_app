import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart'; // Para AppTheme e AppRoutes
import '../../services/auth_service.dart'; // Para o AuthService

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({Key? key}) : super(key: key);

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Usa a função que já existe no seu AuthService
      await AuthService.instance.updatePassword(
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      // Sucesso!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha atualizada com sucesso!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      // Envia o usuário para a tela de login
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.loginScreen,
            (route) => false,
      );

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar senha: ${error.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: const Text('Criar Nova Senha'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_reset_outlined,
                color: AppTheme.accentGold,
                size: 20.w,
              ),
              SizedBox(height: 4.h),
              Text(
                'Defina sua Nova Senha',
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Por favor, insira uma nova senha forte para sua conta.',
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 6.h),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nova Senha',
                  hintText: 'Insira sua nova senha',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.accentGold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Senha é obrigatória';
                  }
                  if (value!.length < 8) {
                    return 'Senha deverá conter pelo menos 8 caracteres';
                  }
                  // Adicione outras regras se quiser (maiúscula, número, etc.)
                  return null;
                },
              ),
              SizedBox(height: 2.h),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirmar Nova Senha',
                  hintText: 'Confirme sua nova senha',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.accentGold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor, confirme sua senha';
                  }
                  if (value != _passwordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              SizedBox(height: 6.h),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryBlack,
                  ),
                )
                    : Text(
                  'Salvar Nova Senha',
                  style: TextStyle(color: AppTheme.primaryBlack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}