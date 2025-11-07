import 'package:flutter/material.dart';
import 'havok_hub.dart'; // Importa para usar as cores consistentes

class WorkoutDetailScreen extends StatelessWidget {
  final Map<String, dynamic> workoutData;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutData,
  });

  @override
  Widget build(BuildContext context) {
    // Extrai o nome e a lista de exercícios dos dados recebidos
    final String workoutName = workoutData['nome'] ?? 'Treino HAVOK';
    final List exercises = workoutData['exercicios'] ?? [];

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: Text(workoutName.toUpperCase(), style: const TextStyle(color: goldColor, fontSize: 18)),
        backgroundColor: cardBackgroundColor,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final String exerciseName = exercise['nome'] ?? 'Exercício Desconhecido';
          final int series = exercise['series'] ?? 0;
          final String reps = exercise['repeticoes'] ?? '0';

          return Card(
            color: cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: goldColor.withOpacity(0.3)),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nome do Exercício (ocupa o espaço disponível)
                  Expanded(
                    child: Text(
                      exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Séries e Repetições
                  Text(
                    '${series}x $reps',
                    style: const TextStyle(
                      color: goldColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}