// lib/presentation/bldr_club/havok/free_workout_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'havok_hub.dart'; // Importa para usar as cores consistentes
import 'workout_detail_screen.dart'; // Importa a tela de detalhes que já criamos

class FreeWorkoutScreen extends StatefulWidget {
  const FreeWorkoutScreen({super.key});

  @override
  State<FreeWorkoutScreen> createState() => _FreeWorkoutScreenState();
}

class _FreeWorkoutScreenState extends State<FreeWorkoutScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _generateFreeWorkout() async {
    final userPrompt = _textController.text.trim();
    if (userPrompt.isEmpty) {
      // Opcional: Mostrar um snackbar se o campo estiver vazio
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'gerar-treino-livre',
        body: {'userPrompt': userPrompt}, // Enviando o texto do usuário
      );

      if (response.status == 200 && mounted) {
        // REUTILIZAMOS A TELA DE DETALHES!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(
              workoutData: response.data['workout_data'],
            ),
          ),
        );
      } else {
        throw 'A IA não conseguiu gerar o treino. Tente novamente.';
      }
    } catch (e) {
      // Opcional: Mostrar um snackbar de erro
      print('Erro ao gerar treino livre: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: const Text('TREINO LIVRE', style: TextStyle(color: goldColor)),
        backgroundColor: cardBackgroundColor,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Descreva o treino que você quer',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Ex: "Um treino rápido de 20 minutos para peito e ombros em casa"',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Digite seu comando aqui...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                fillColor: cardBackgroundColor,
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: goldColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                disabledBackgroundColor: goldColor.withOpacity(0.5),
              ),
              onPressed: _isLoading ? null : _generateFreeWorkout,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
              )
                  : const Text('GERAR COM HAVOK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}