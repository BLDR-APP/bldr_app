// Salve este arquivo como: lib/services/exercise_db_service.dart

import 'dart:async'; // Adicionado para o Future
import 'dart:convert';
import 'package:http/http.dart' as http;
// Importe seu modelo
import '../models/exercise_model.dart';

class ExerciseDbService {
  final String _baseUrl = "https://www.exercisedb.dev/api/v1";

  /// Função principal para buscar os detalhes de um exercício pelo ID
  Future<ExerciseDetail?> getExerciseById(String exerciseId) async {
    // Retorna nulo se o ID estiver vazio (evita chamadas de API desnecessárias)
    if (exerciseId.isEmpty) {
      print('Aviso: getExerciseById foi chamado com um ID vazio.');
      return null;
    }

    final uri = Uri.parse('$_baseUrl/exercises/$exerciseId');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // A API encapsula os dados em uma chave 'data'
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true && responseBody['data'] != null) {
          return ExerciseDetail.fromJson(responseBody['data']);
        } else {
          print('Erro ao buscar exercício (ID: $exerciseId): Resposta sem sucesso ou sem dados.');
          return null;
        }
      } else {
        print('Erro de API (ID: $exerciseId): Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exceção ao buscar exercício (ID: $exerciseId): $e');
      return null;
    }
  }

  /// (Opção 2)
  /// Esta função recebe uma lista de IDs e busca todos de uma vez
  /// em paralelo para popular o cache.
  Future<List<ExerciseDetail>> prefetchAllExercises(List<String> exerciseIds) async {
    // Filtra IDs vazios antes de criar os futuros
    final validIds = exerciseIds.where((id) => id.isNotEmpty).toList();

    final List<Future<ExerciseDetail?>> futures = [];

    // Cria uma lista de "tarefas" de busca
    for (final id in validIds) {
      futures.add(getExerciseById(id));
    }

    // Aguarda todas as tarefas completarem
    final results = await Future.wait(futures);

    // Filtra apenas os resultados que não falharam (não são nulos)
    return results.where((detail) => detail != null).cast<ExerciseDetail>().toList();
  }
}