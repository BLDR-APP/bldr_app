import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import './auth_service.dart';
import './supabase_service.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();

  UserService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    return getUserProfile(currentUser.id);
  }

  /// Update user profile
  Future<UserProfile> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }

  /// Update current user profile
  Future<UserProfile?> updateCurrentUserProfile({
    required Map<String, dynamic> updates,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    return updateUserProfile(userId: currentUser.id, updates: updates);
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Get workout count
      final workoutData = await _client
          .from('user_workouts')
          .select('id')
          .eq('user_id', userId)
          .count();

      // Get completed workouts count
      final completedWorkoutData = await _client
          .from('user_workouts')
          .select('id')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .count();

      // Get achievements count
      final achievementData = await _client
          .from('user_achievements')
          .select('id')
          .eq('user_id', userId)
          .count();

      // Get latest weight measurement
      final weightResponse = await _client
          .from('user_measurements')
          .select('value, measured_at')
          .eq('user_id', userId)
          .eq('measurement_type', 'weight')
          .order('measured_at', ascending: false)
          .limit(1);

      double? currentWeight;
      if (weightResponse.isNotEmpty) {
        currentWeight = (weightResponse.first['value'] as num?)?.toDouble();
      }

      return {
        'total_workouts': workoutData.count ?? 0,
        'completed_workouts': completedWorkoutData.count ?? 0,
        'achievements': achievementData.count ?? 0,
        'current_weight': currentWeight,
        'completion_rate': (workoutData.count ?? 0) > 0
            ? ((completedWorkoutData.count ?? 0) /
            (workoutData.count ?? 0) *
            100)
            .round()
            : 0,
      };
    } catch (error) {
      throw Exception('Failed to get user statistics: $error');
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (error) {
      throw Exception('Failed to check username availability: $error');
    }
  }

  /// Search users by username or full name
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .eq('is_active', true)
          .limit(20);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to search users: $error');
    }
  }

  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('achieved_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user achievements: $error');
    }
  }

  /// Add user achievement
  Future<Map<String, dynamic>> addUserAchievement({
    required String userId,
    required String achievementType,
    required String achievementName,
    String? achievementDescription,
    double? value,
    String? unit,
  }) async {
    try {
      final response = await _client
          .from('user_achievements')
          .insert({
        'user_id': userId,
        'achievement_type': achievementType,
        'achievement_name': achievementName,
        'achievement_description': achievementDescription,
        'value': value,
        'unit': unit,
      })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add user achievement: $error');
    }
  }

  /// Mark user onboarding as completed
  Future<UserProfile?> markOnboardingCompleted() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .update({'onboarding_completed': true})
          .eq('id', currentUser.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to mark onboarding complete: $error');
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final response = await _client
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', currentUser.id)
          .single();

      return response['onboarding_completed'] as bool? ?? false;
    } catch (error) {
      // If user profile doesn't exist yet, onboarding not completed
      return false;
    }
  }

  /// Save onboarding data to user profile
  Future<UserProfile?> saveOnboardingData({
    required Map<String, dynamic> onboardingData,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    try {
      // Convert onboarding responses to profile fields
      final profileUpdates = <String, dynamic>{
        'onboarding_completed': true,
      };

      // Map onboarding responses to profile fields
      if (onboardingData['fitness_goals'] != null) {
        final goal = onboardingData['fitness_goals'] as String;
        switch (goal.toLowerCase()) {
          case 'lose weight':
            profileUpdates['fitness_goal'] = 'weight_loss';
            break;
          case 'build muscle':
            profileUpdates['fitness_goal'] = 'muscle_gain';
            break;
          case 'improve endurance':
            profileUpdates['fitness_goal'] = 'endurance';
            break;
          case 'general fitness':
            profileUpdates['fitness_goal'] = 'general_fitness';
            break;
          case 'athletic performance':
          case 'rehabilitation':
            profileUpdates['fitness_goal'] = 'strength';
            break;
        }
      }

      if (onboardingData['experience_level'] != null) {
        final experience = onboardingData['experience_level'] as String;
        if (experience.contains('Beginner')) {
          profileUpdates['activity_level'] = 'lightly_active';
        } else if (experience.contains('Intermediate')) {
          profileUpdates['activity_level'] = 'moderately_active';
        } else if (experience.contains('Advanced')) {
          profileUpdates['activity_level'] = 'very_active';
        } else if (experience.contains('Expert')) {
          profileUpdates['activity_level'] = 'extremely_active';
        }
      }

      // Update user profile with onboarding data
      final response = await _client
          .from('user_profiles')
          .update(profileUpdates)
          .eq('id', currentUser.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to save onboarding data: $error');
    }
  }
}

