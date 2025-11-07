// lib/features/professional_portal/presentation/screens/professional_dashboard_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:bldr_fitness/services/auth_service.dart'; // Ajuste o caminho se necessário
import 'package:flutter/material.dart';

import 'package:bldr_fitness/features/professional_portal/presentation/screens/client_diet_screen.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/screens/client_workout_list_screen.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDashboardScreen> createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> {
  final _repository = ProfessionalRepository();

  String? _professionalRole;
  String _errorMessage = '';

  // Esta é a nossa nova variável de estado para a lista
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true; // Controla o estado de carregamento da tela inteira

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Busca o 'role' do profissional
      final role = await _repository.getMyProfessionalRole();

      // 2. Busca a lista de IDs de clientes
      final clientIds = await _repository.getMyClientsIds();

      // 3. Para cada ID, busca o perfil
      // Usamos Future.wait para fazer todas as buscas em paralelo
      final clientProfiles = await Future.wait(
          clientIds.map((id) => _repository.getClientProfileById(id))
      );

      if (mounted) {
        setState(() {
          _professionalRole = role;
          _clients = clientProfiles.map((profile) {
            return {
              'id': profile['id'], // ou 'user_id' dependendo da sua tabela
              'full_name': profile['full_name'] ?? 'Nome não encontrado'
            };
          }).toList();
          _isLoading = false; // Terminou de carregar
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  // Esta função agora é chamada DEPOIS de adicionar um cliente
  void _refreshClientList() {
    setState(() { _isLoading = true; }); // Mostra o loading
    _loadInitialData(); // Recarrega tudo
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login-screen', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showAddClientDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Cliente'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail do Cliente'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@')) ? 'E-mail inválido' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final email = emailController.text.trim();
                  Navigator.of(context).pop();

                  try {
                    final successMessage = await _repository.addClientByEmail(email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
                    );
                    _refreshClientList(); // Recarrega a lista
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _professionalRole == 'personal'
              ? 'Meus Alunos (Personal)'
              : _professionalRole == 'nutritionist'
              ? 'Meus Pacientes (Nutri)'
              : 'Painel do Profissional',
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _buildBody(), // O corpo agora é construído pela função _buildBody
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // Esta função agora constrói o corpo com base no estado (loading, erro, lista)
  Widget _buildBody() {
    // 1. Estado de Carregamento
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Estado de Erro
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text('Erro: $_errorMessage'));
    }

    // 3. Estado de Lista Vazia
    if (_clients.isEmpty) {
      return const Center(
        child: Text(
          'Você ainda não adicionou nenhum cliente.\nClique no botão + para começar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // 4. Estado de Sucesso (mostrar a lista)
    return ListView.builder(
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        final clientName = client['full_name'] ?? 'Nome não encontrado';
        return ListTile(
          leading: CircleAvatar(child: Text(clientName.isNotEmpty ? clientName[0] : '?')),
          title: Text(clientName),
          onTap: () {
            if (_professionalRole == 'personal') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientWorkoutListScreen(
                    clientId: client['id'],
                    clientName: clientName,
                  ),
                ),
              );
            } else if (_professionalRole == 'nutritionist') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientDietScreen(
                    clientId: client['id'],
                    clientName: clientName,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}