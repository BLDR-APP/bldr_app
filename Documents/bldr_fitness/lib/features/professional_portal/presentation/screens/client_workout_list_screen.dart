// lib/features/professional_portal/presentation/screens/client_workout_list_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar a data

class ClientWorkoutListScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientWorkoutListScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  _ClientWorkoutListScreenState createState() => _ClientWorkoutListScreenState();
}

class _ClientWorkoutListScreenState extends State<ClientWorkoutListScreen> {
  final _repository = ProfessionalRepository();
  late Future<List<Map<String, dynamic>>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  void _loadWorkoutPlans() {
    setState(() {
      _plansFuture = _repository.getWorkoutPlans(widget.clientId);
    });
  }

  // Função que abre o diálogo para criar um novo plano
  Future<void> _showCreatePlanDialog() async {
    final planNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final planName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo Plano de Treino'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: planNameController,
              decoration: const InputDecoration(hintText: "Ex: Treino A - Foco Peito"),
              validator: (value) => (value == null || value.isEmpty) ? 'Dê um nome ao plano' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(planNameController.text);
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    // Se o usuário inseriu um nome e clicou em "Criar"
    if (planName != null && planName.isNotEmpty) {
      try {
        await _repository.createWorkoutPlan(
          planName: planName,
          clientId: widget.clientId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano criado com sucesso!'), backgroundColor: Colors.green),
        );
        _loadWorkoutPlans(); // Recarrega a lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _navigateToPlanDetails(int planId, String planName) {
    // Este é o nosso próximo passo: criar a tela 'WorkoutPlanEditorScreen'
    print('Navegando para o plano $planName (ID: $planId)');
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => WorkoutPlanEditorScreen(
    //       planId: planId,
    //       planName: planName,
    //     ),
    //   ),
    // ).then((_) => _loadWorkoutPlans()); // Recarrega os planos caso algo mude
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treinos de ${widget.clientName}'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum plano de treino criado.\nClique no + para começar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final plans = snapshot.data!;
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final createdAt = DateTime.parse(plan['created_at']);
              final formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);

              return ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.amber),
                title: Text(plan['plan_name']),
                subtitle: Text('Criado em $formattedDate'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateToPlanDetails(plan['id'], plan['plan_name']),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlanDialog,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}