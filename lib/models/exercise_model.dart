// Salve este arquivo como: lib/models/exercise_model.dart
// (ou onde você preferir)

import 'dart:convert';

class ExerciseDetail {
  final String exerciseId;
  final String name;
  final String gifUrl;
  final List<String> instructions;
  final List<String> targetMuscles;
  final List<String> bodyParts;
  final List<String> equipments;
  final List<String> secondaryMuscles;

  ExerciseDetail({
    required this.exerciseId,
    required this.name,
    required this.gifUrl,
    required this.instructions,
    required this.targetMuscles,
    required this.bodyParts,
    required this.equipments,
    required this.secondaryMuscles,
  });

  // Factory constructor para criar uma instância a partir de um JSON
  factory ExerciseDetail.fromJson(Map<String, dynamic> json) {
    String originalUrl = json['gifUrl'] as String? ?? '';

    return ExerciseDetail(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? 'Exercício não encontrado',

      gifUrl: _fixGifUrl(originalUrl),

      // Converte listas de dynamic para List<String>
      instructions: List<String>.from(json['instructions'] as List? ?? []),
      targetMuscles: List<String>.from(json['targetMuscles'] as List? ?? []),
      bodyParts: List<String>.from(json['bodyParts'] as List? ?? []),
      equipments: List<String>.from(json['equipments'] as List? ?? []),
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] as List? ?? []),
    );
  }

  static String _fixGifUrl(String originalUrl) {
    // O link quebrado que vem do JSON
    const String brokenDomain = 'https://v1.cdn.exercisedb.dev';

    // O link CORRETO que você encontrou no navegador
    const String correctDomain = 'https://static.exercisedb.dev/media';

    if (originalUrl.startsWith(brokenDomain)) {
      // Substitui o domínio quebrado pelo domínio correto
      return originalUrl.replaceFirst(brokenDomain, correctDomain);
    }

    // Se a URL já for diferente (talvez eles corrigiram no futuro), apenas a retorna
    return originalUrl;
  }
}