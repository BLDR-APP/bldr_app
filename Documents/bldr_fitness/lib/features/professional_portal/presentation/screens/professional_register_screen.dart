import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:flutter/material.dart';

class ProfessionalRegisterScreen extends StatefulWidget {
  const ProfessionalRegisterScreen({Key? key}) : super(key: key);

  @override
  _ProfessionalRegisterScreenState createState() =>
      _ProfessionalRegisterScreenState();
}

class _ProfessionalRegisterScreenState extends State<ProfessionalRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para pegar o texto dos campos
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _professionalIdController = TextEditingController();

  // Instância do nosso repositório
  final _repository = ProfessionalRepository();

  // Variável para o Dropdown (Personal ou Nutricionista)
  String? _selectedRole; // 'personal' ou 'nutritionist'
  bool _isLoading = false;

  @override
  void dispose() {
    // Limpar os controladores quando a tela for destruída
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _professionalIdController.dispose();
    super.dispose();
  }

  // --- MÉTODO _register() ATUALIZADO ---
  Future<void> _register() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == null) {
      // Mostra um erro se o tipo de profissional não for selecionado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione seu tipo de atuação.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Chamando o método do nosso repositório
      await _repository.registerNewProfessional(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole!,
        professionalId: _professionalIdController.text.trim(),
      );

      // Se chegou aqui, o cadastro foi um sucesso!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Volta para a tela de login após o sucesso
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Mostra a mensagem de erro que veio do repositório/backend
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // Garante que o loading sempre vai parar, mesmo se der erro
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- FIM DA ATUALIZAÇÃO ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro Profissional'),
        backgroundColor: Colors.black, // Mantendo a identidade visual
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome completo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Por favor, insira um e-mail válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'A senha deve ter no mínimo 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                hint: const Text('Eu sou...'),
                items: const [
                  DropdownMenuItem(
                      value: 'personal', child: Text('Personal Trainer')),
                  DropdownMenuItem(
                      value: 'nutritionist', child: Text('Nutricionista')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _professionalIdController,
                decoration: const InputDecoration(
                    labelText: 'Nº de Registro (CREF/CRN)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu número de registro.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cadastrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, // Cor de destaque
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