import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class ExerciseService {
  static ExerciseService? _instance;
  static ExerciseService get instance => _instance ??= ExerciseService._();

  ExerciseService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get all exercises
  Future<List<Map<String, dynamic>>> getExercises({
    String? exerciseType,
    String? muscleGroup,
    String? search,
    bool systemOnly = false,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('exercises').select();

      if (systemOnly) {
        query = query.eq('is_system_exercise', true);
      }

      if (exerciseType != null) {
        query = query.eq('exercise_type', exerciseType);
      }

      if (muscleGroup != null) {
        query = query.eq('primary_muscle_group', muscleGroup);
      }

      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,description.ilike.%$search%');
      }

      final response = await query.order('name', ascending: true).limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get exercises: $error');
    }
  }

  /// Get exercise by ID
  Future<Map<String, dynamic>?> getExercise(String exerciseId) async {
    try {
      final response = await _client
          .from('exercises')
          .select()
          .eq('id', exerciseId)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get exercise: $error');
    }
  }

  /// Create custom exercise
  Future<Map<String, dynamic>> createExercise({
    required String name,
    String? description,
    required String exerciseType,
    required String primaryMuscleGroup,
    List<String>? secondaryMuscleGroups,
    List<String>? instructions,
    List<String>? tips,
    List<String>? equipmentNeeded,
    String? imageUrl,
    String? videoUrl,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('exercises')
          .insert({
            'name': name,
            'description': description,
            'exercise_type': exerciseType,
            'primary_muscle_group': primaryMuscleGroup,
            'secondary_muscle_groups': secondaryMuscleGroups,
            'instructions': instructions,
            'tips': tips,
            'equipment_needed': equipmentNeeded,
            'image_url': imageUrl,
            'video_url': videoUrl,
            'created_by': currentUser.id,
            'is_system_exercise': false,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create exercise: $error');
    }
  }

  /// Update exercise
  Future<Map<String, dynamic>> updateExercise({
    required String exerciseId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('exercises')
          .update(updates)
          .eq('id', exerciseId)
          .eq('created_by', currentUser.id)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update exercise: $error');
    }
  }

  /// Delete exercise
  Future<void> deleteExercise(String exerciseId) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      await _client
          .from('exercises')
          .delete()
          .eq('id', exerciseId)
          .eq('created_by', currentUser.id);
    } catch (error) {
      throw Exception('Failed to delete exercise: $error');
    }
  }

  /// Get exercises by muscle group
  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(
      String muscleGroup) async {
    try {
      final response = await _client
          .from('exercises')
          .select()
          .or('primary_muscle_group.eq.$muscleGroup,secondary_muscle_groups.cs.{$muscleGroup}')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get exercises by muscle group: $error');
    }
  }

  /// Get exercises by type
  Future<List<Map<String, dynamic>>> getExercisesByType(
      String exerciseType) async {
    try {
      final response = await _client
          .from('exercises')
          .select()
          .eq('exercise_type', exerciseType)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get exercises by type: $error');
    }
  }

  /// Search exercises
  Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    try {
      final response = await _client
          .from('exercises')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('name', ascending: true)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to search exercises: $error');
    }
  }
}
