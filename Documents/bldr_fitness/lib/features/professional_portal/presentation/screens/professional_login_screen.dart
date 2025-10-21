// lib/features/professional_portal/presentation/screens/professional_login_screen.dart

import 'package:bldr_fitness/features/professional_portal/presentation/screens/professional_dashboard_screen.dart';
import 'package:bldr_fitness/services/auth_service.dart'; // Verifique este import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfessionalLoginScreen extends StatefulWidget {
  const ProfessionalLoginScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalLoginScreen> createState() => _ProfessionalLoginScreenState();
}

class _ProfessionalLoginScreenState extends State<ProfessionalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleProfessionalLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Tenta fazer o login
      final authResponse = await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        HapticFeedback.mediumImpact();
        if (!mounted) return;

        // 2. Se o login for bem-sucedido, SEMPRE redireciona para o dashboard profissional
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfessionalDashboardScreen()),
        );
      } else {
        // Este 'else' pode não ser alcançado se signIn sempre joga um erro.
        throw Exception('Credenciais inválidas.');
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Login falhou: ${error.toString().replaceFirst("Exception: ", "")}';
        _isLoading = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Você pode reutilizar seu LoginFormWidget aqui se ele for genérico,
    // ou construir o formulário diretamente como no exemplo abaixo.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso Profissional'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'E-mail inválido.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) => (value == null || value.length < 6) ? 'Senha muito curta.' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleProfessionalLogin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}