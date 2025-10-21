import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class ClubWorkoutsService {
  static ClubWorkoutsService? _instance;
  static ClubWorkoutsService get instance => _instance ??= ClubWorkoutsService._();

  ClubWorkoutsService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // ==========================================================
  // BUSCAS DE TEMPLATES
  // ==========================================================

  /// Lista templates de treino do CLUB
  Future<List<Map<String, dynamic>>> getClubWorkoutTemplates({
    String? workoutType,
    int? difficultyLevel,
    bool publicOnly = false,
  }) async {
    try {
      var query = _client.from('club_workout_templates').select('''
        id, name, description, workout_type, estimated_duration_minutes,
        difficulty_level, is_public, created_at
      ''');

      if (publicOnly) query = query.eq('is_public', true);
      if (workoutType != null) query = query.eq('workout_type', workoutType);
      if (difficultyLevel != null) query = query.eq('difficulty_level', difficultyLevel);

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get club workout templates: $error');
    }
  }

  /// Detalha um template com exercícios
  Future<Map<String, dynamic>?> getClubWorkoutTemplateWithExercises(String templateId) async {
    try {
      final response = await _client.from('club_workout_templates').select('''
        id, name, description, workout_type, estimated_duration_minutes,
        difficulty_level, is_public, created_at,
        club_workout_template_exercises(
          id, order_index, sets, reps, duration_seconds, rest_seconds,
          weight_kg, distance_meters, notes,
          exercises(
            id, name, description, exercise_type, primary_muscle_group,
            secondary_muscle_groups, instructions, tips, image_url,
            equipment_needed
          )
        )
      ''').eq('id', templateId).single();

      return response;
    } catch (error) {
      throw Exception('Failed to get club workout template: $error');
    }
  }

  // ==========================================================
  // INÍCIO E FIM DO TREINO
  // ==========================================================

  /// Inicia um treino do CLUB
  Future<Map<String, dynamic>> startClubWorkout({
    required String name,
    required String clubWorkoutTemplateId,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('User must be authenticated');

      // 1) cria o club_user_workouts (UTC evita deslocamento de fuso)
      final baseInsert = {
        'user_id': currentUser.id,
        'workout_template_id': clubWorkoutTemplateId, // CORRETO
        'name': name,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'is_completed': false, // pode não existir; tratamos abaixo
      };

      Map<String, dynamic> workout;
      try {
        workout = await _client.from('club_user_workouts').insert(baseInsert).select().single();
      } on PostgrestException catch (e) {
        // Fallback se 'is_completed' não existir
        if ((e.message ?? '').toLowerCase().contains('is_completed')) {
          final withoutFlag = Map<String, dynamic>.from(baseInsert)..remove('is_completed');
          workout = await _client.from('club_user_workouts').insert(withoutFlag).select().single();
        } else {
          rethrow;
        }
      }

      // 2) clona sets do template
      final tpl = await _client
          .from('club_workout_template_exercises')
          .select('''
            order_index, sets, reps, duration_seconds, rest_seconds,
            weight_kg, distance_meters, notes, exercise_id
          ''')
          .eq('workout_template_id', clubWorkoutTemplateId) // CORRETO
          .order('order_index', ascending: true);

      final setsToInsert = <Map<String, dynamic>>[];
      for (final row in tpl) {
        final totalSets = (row['sets'] as int?) ?? 1;
        for (int s = 1; s <= totalSets; s++) {
          setsToInsert.add({
            'user_workout_id': workout['id'],
            'exercise_id': row['exercise_id'],
            'set_number': s,
            'reps': row['reps'],
            'weight_kg': row['weight_kg'],
            'duration_seconds': row['duration_seconds'],
            'distance_meters': row['distance_meters'],
            'rest_seconds': row['rest_seconds'],
            'notes': row['notes'],
            'completed_at': null,
            'is_completed': false, // pode não existir; tratamos abaixo
          });
        }
      }

      // 3) Insere sets
      if (setsToInsert.isNotEmpty) {
        try {
          await _client.from('club_workout_exercise_sets').insert(setsToInsert);
        } on PostgrestException catch (e) {
          // Fallback se 'is_completed' não existir
          if ((e.message ?? '').toLowerCase().contains('is_completed')) {
            final fallback = setsToInsert
                .map((m) => Map<String, dynamic>.from(m)..remove('is_completed'))
                .toList();
            await _client.from('club_workout_exercise_sets').insert(fallback);
          } else {
            rethrow;
          }
        }
      }

      return Map<String, dynamic>.from(workout);
    } catch (error) {
      throw Exception('Failed to start club workout: $error');
    }
  }

  /// Conclui um treino do CLUB
  Future<Map<String, dynamic>> completeClubWorkout({
    required String workoutId,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();

      final workoutResponse = await _client
          .from('club_user_workouts')
          .select('started_at')
          .eq('id', workoutId)
          .single();

      final startedAt = DateTime.parse(workoutResponse['started_at'].toString());
      final duration = now.difference(startedAt).inSeconds;

      final response = await _client
          .from('club_user_workouts')
          .update({
        'completed_at': now.toIso8601String(),
        'total_duration_seconds': duration,
        'notes': notes,
        'is_completed': true,
      })
          .eq('id', workoutId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to complete club workout: $error');
    }
  }

  // ==========================================================
  // LISTAGENS/ACÕES AUXILIARES
  // ==========================================================

  /// Lista treinos do usuário
  Future<List<Map<String, dynamic>>> getClubUserWorkouts({
    String? userId,
    bool completedOnly = false,
    int limit = 20,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      var query = _client
          .from('club_user_workouts')
          .select('''
            id, name, started_at, completed_at, total_duration_seconds,
            notes, is_completed,
            club_workout_templates(name, workout_type, estimated_duration_minutes)
          ''')
          .eq('user_id', targetUserId);

      if (completedOnly) {
        query = query.eq('is_completed', true);
      }

      final response = await query.order('started_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user club workouts: $error');
    }
  }

  /// Insere um set pontual (não usado no clone)
  Future<Map<String, dynamic>> logClubExerciseSet({
    required String userWorkoutId,
    required String exerciseId,
    required int setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    int? restSeconds,
    String? notes,
  }) async {
    try {
      final response = await _client
          .from('club_workout_exercise_sets')
          .insert({
        'user_workout_id': userWorkoutId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'reps': reps,
        'weight_kg': weightKg,
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'rest_seconds': restSeconds,
        'notes': notes,
      })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to log club exercise set: $error');
    }
  }

  /// Marca série como concluída
  Future<void> completeClubSet({required String setId}) async {
    try {
      await _client
          .from('club_workout_exercise_sets')
          .update({
        'completed_at': DateTime.now().toIso8601String(),
        // 'is_completed': true, // mantemos pela presença de completed_at
      })
          .eq('id', setId);
    } catch (e) {
      throw Exception('Failed to complete club set: $e');
    }
  }

  /// Desfaz conclusão da série
  Future<void> undoClubSet({required String setId}) async {
    try {
      // tenta zerar ambos; se 'is_completed' não existir, o Supabase ignora a chave desconhecida
      await _client
          .from('club_workout_exercise_sets')
          .update({
        'completed_at': null,
        'is_completed': false,
      })
          .eq('id', setId);
    } catch (e) {
      throw Exception('Failed to undo club set: $e');
    }
  }

  // ==========================================================
  // BUSCA DETALHADA (SEM EMBED) E STREAM DO BANNER
  // ==========================================================

  /// Detalhes do treino (head + sets + nomes dos exercícios via 2ª query).
  /// Não depende de FKs entre sets->exercises (evita PGRST200).
  Future<Map<String, dynamic>?> getClubWorkoutDetails(String workoutId) async {
    try {
      // 1) Head + template (embed do template pode existir)
      Map<String, dynamic> head;
      try {
        head = await _client
            .from('club_user_workouts')
            .select('''
              id, name, started_at, completed_at, total_duration_seconds,
              notes, is_completed, workout_template_id,
              club_workout_templates(
                id, name, workout_type, difficulty_level, estimated_duration_minutes
              )
            ''')
            .eq('id', workoutId)
            .single();
      } on PostgrestException catch (_) {
        head = await _client
            .from('club_user_workouts')
            .select('id, name, started_at, completed_at, total_duration_seconds, notes, is_completed, workout_template_id')
            .eq('id', workoutId)
            .single();
        head['club_workout_templates'] = null;
      }

      // 2) Sets (sem embed de exercises)
      final rawSets = await _client
          .from('club_workout_exercise_sets')
          .select('''
            id, user_workout_id, exercise_id, set_number, reps, weight_kg,
            duration_seconds, distance_meters, rest_seconds, completed_at, notes
          ''')
          .eq('user_workout_id', workoutId)
          .order('set_number', ascending: true);

      final sets = List<Map<String, dynamic>>.from(rawSets);

      // 3) Enriquecer sets com nomes dos exercícios via 2ª query (sem .in_)
      final exerciseIds = sets
          .map((m) => (m['exercise_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> exById = {};
      if (exerciseIds.isNotEmpty) {
        // Fallback universal: OR com múltiplos id.eq.
        final orCond = exerciseIds.map((id) => 'id.eq.$id').join(',');
        final exRows = await _client
            .from('exercises')
            .select('id, name, primary_muscle_group')
            .or(orCond);

        for (final e in (exRows as List)) {
          final id = (e['id'] ?? '').toString();
          exById[id] = {
            'id': id,
            'name': (e['name'] ?? 'Exercício').toString(),
            'primary_muscle_group': e['primary_muscle_group'],
          };
        }
      }

      // 4) Anexar um campo "exercises" em cada set (formato que o banner espera)
      final setsWithNames = sets.map((s) {
        final exId = (s['exercise_id'] ?? '').toString();
        final ex = exById[exId] ??
            {
              'id': exId,
              'name': 'Exercício',
              'primary_muscle_group': null,
            };
        return {...s, 'exercises': ex};
      }).toList();

      final workout = {
        ...head,
        'club_workout_exercise_sets': setsWithNames,
      };

      return _decorateClubSetsWithIsCompleted(workout);
    } catch (error) {
      throw Exception('Failed to get club workout details: $error');
    }
  }

  /// Retorna o head do treino ativo (NULL ou FALSE)
  Future<Map<String, dynamic>?> _getActiveClubWorkoutHead() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) throw Exception('User must be authenticated');

    final rows = await _client
        .from('club_user_workouts')
        .select('id, is_completed, started_at')
        .eq('user_id', currentUser.id)
        .or('is_completed.is.null,is_completed.eq.false')
        .order('started_at', ascending: false)
        .limit(1);

    if (rows.isNotEmpty) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    return null;
  }

  /// Injeta `is_completed` em cada set com base em `completed_at`, caso não exista
  Map<String, dynamic>? _decorateClubSetsWithIsCompleted(Map<String, dynamic>? workout) {
    if (workout == null) return null;
    final sets = workout['club_workout_exercise_sets'];
    if (sets is List) {
      final newSets = sets.map<Map<String, dynamic>>((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        if (!m.containsKey('is_completed')) {
          m['is_completed'] = m['completed_at'] != null;
        }
        return m;
      }).toList();
      workout = {...workout, 'club_workout_exercise_sets': newSets};
    }
    return workout;
  }

  /// Stream do treino ativo com detalhes; fecha quando o treino é concluído
  Stream<Map<String, dynamic>?> activeClubWorkoutStream() {
    final controller = StreamController<Map<String, dynamic>?>.broadcast();

    RealtimeChannel? setsChannel;
    RealtimeChannel? workoutsChannel;
    String? currentWorkoutId;

    Future<void> _emitById(String workoutId) async {
      final details = await getClubWorkoutDetails(workoutId);
      final decorated = _decorateClubSetsWithIsCompleted(details);
      controller.add(decorated);
    }

    Future<void> _wireForActiveWorkout() async {
      final head = await _getActiveClubWorkoutHead();
      if (head == null) {
        currentWorkoutId = null;
        controller.add(null);
        setsChannel?.unsubscribe();
        setsChannel = null;
        return;
      }

      final workoutId = head['id'] as String;
      currentWorkoutId = workoutId;

      // Emite agora
      await _emitById(workoutId);

      // (re)assina canal de sets
      if (setsChannel != null) {
        setsChannel!.unsubscribe();
        setsChannel = null;
      }
      setsChannel = _client
          .channel('club_sets_${workoutId}_${DateTime.now().millisecondsSinceEpoch}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_workout_exercise_sets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_workout_id',
            value: workoutId,
          ),
          callback: (payload) async {
            await _emitById(workoutId);
          },
        )
        ..subscribe();
    }

    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      Future.microtask(() => controller.addError('User must be authenticated'));
      return controller.stream;
    }

    // Observa mudanças nos treinos do usuário
    workoutsChannel = _client
        .channel('club_uw_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'club_user_workouts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUser.id,
        ),
        callback: (payload) async {
          final newRec = payload.newRecord;

          // Se a mudança refere-se ao treino atual e ele foi concluído, zera imediatamente
          if (currentWorkoutId != null &&
              (newRec['id']?.toString() == currentWorkoutId) &&
              (newRec['is_completed'] == true)) {
            currentWorkoutId = null;
            controller.add(null); // banner deve sumir imediatamente
            setsChannel?.unsubscribe();
            setsChannel = null;
            return;
          }

          // Senão, recalcule qual é o ativo e (re)assine os sets
          await _wireForActiveWorkout();
        },
      )
      ..subscribe();

    // Emissão inicial
    _wireForActiveWorkout();

    controller.onCancel = () {
      setsChannel?.unsubscribe();
      workoutsChannel?.unsubscribe();
    };

    return controller.stream;
  }
}
