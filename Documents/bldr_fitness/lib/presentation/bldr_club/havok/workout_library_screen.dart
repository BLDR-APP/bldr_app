import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pacote para formatação de data
import 'package:supabase_flutter/supabase_flutter.dart'; // Cliente Supabase
import 'havok_hub.dart'; // Importa para usar as cores consistentes
import 'workout_detail_screen.dart';

// Modelo de dados para representar um treino salvo
class SavedWorkout {
  final String id;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> workoutData;

  SavedWorkout({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.workoutData,
  });

  factory SavedWorkout.fromMap(Map<String, dynamic> map) {
    return SavedWorkout(
      id: map['id'],
      name: map['workout_name'],
      createdAt: DateTime.parse(map['created_at']),
      workoutData: map['workout_data'],
    );
  }
}


class WorkoutLibraryScreen extends StatefulWidget {
  const WorkoutLibraryScreen({super.key});

  @override
  State<WorkoutLibraryScreen> createState() => _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends State<WorkoutLibraryScreen> {
  bool _isLoading = true;
  List<SavedWorkout> _workouts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSavedWorkouts();
  }

  Future<void> _fetchSavedWorkouts() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'Usuário não autenticado.';
      }

      // Busca na tabela 'havok_workouts' do schema 'bldr_club'
      final response = await supabase
          .schema('bldr_club')
          .from('havok_workouts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false); // Mais recentes primeiro

      // Converte a lista de mapas em uma lista de objetos SavedWorkout
      final workouts = response.map((map) => SavedWorkout.fromMap(map)).toList();

      if (mounted) {
        setState(() {
          _workouts = workouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocorreu um erro ao buscar seus treinos.';
          _isLoading = false;
        });
      }
      print('Erro ao buscar treinos salvos: $e');
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: goldColor));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_workouts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, color: Colors.white38, size: 50),
            SizedBox(height: 16),
            Text(
              'Você ainda não gerou nenhum treino.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Vá para o Hub do HAVOK para criar o seu.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Se tivermos treinos, exibe a lista
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return _WorkoutCard(workout: workout);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: const Text('BIBLIOTECA HAVOK', style: TextStyle(color: goldColor)),
        backgroundColor: cardBackgroundColor,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: _buildBody(),
    );
  }
}

// Widget para exibir cada card de treino na lista
class _WorkoutCard extends StatelessWidget {
  final SavedWorkout workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: goldColor.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text(
          workout.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Gerado em: ${DateFormat('dd/MM/yyyy \'às\' HH:mm').format(workout.createdAt)}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: goldColor, size: 16),

        // ===============================================================
        // =========== ALTERAÇÃO APLICADA AQUI ===========
        // ===============================================================
        onTap: () {
          // Agora, em vez de um print, nós navegamos para a tela de detalhes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(
                workoutData: workout.workoutData, // Passando os dados do treino
              ),
            ),
          );
        },
      ),
    );
  }
}