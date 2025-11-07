import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class ProgressService {
  static ProgressService? _instance;
  static ProgressService get instance => _instance ??= ProgressService._();

  ProgressService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Record user measurement
  Future<Map<String, dynamic>> recordMeasurement({
    required String measurementType,
    required double value,
    String unit = 'kg',
    DateTime? measuredAt,
    String? notes,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final response =
      await _client
          .from('user_measurements')
          .insert({
        'user_id': currentUser.id,
        'measurement_type': measurementType,
        'value': value,
        'unit': unit,
        // CORRETO: Já estava com .toUtc()
        'measured_at': (measuredAt ?? DateTime.now()).toUtc().toIso8601String(),
        'notes': notes,
      })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to record measurement: $error');
    }
  }

  /// Get user measurements
  Future<List<Map<String, dynamic>>> getUserMeasurements({
    String? userId,
    String? measurementType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      var query = _client
          .from('user_measurements')
          .select()
          .eq('user_id', targetUserId);

      if (measurementType != null) {
        query = query.eq('measurement_type', measurementType);
      }

      // CORREÇÃO: Garante que as datas de filtro também sejam UTC
      if (startDate != null) {
        query = query.gte('measured_at', startDate.toUtc().toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('measured_at', endDate.toUtc().toIso8601String());
      }

      final response = await query
          .order('measured_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user measurements: $error');
    }
  }

  /// Get latest measurement by type
  Future<Map<String, dynamic>?> getLatestMeasurement({
    String? userId,
    required String measurementType,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      final response = await _client
          .from('user_measurements')
          .select()
          .eq('user_id', targetUserId)
          .eq('measurement_type', measurementType)
          .order('measured_at', ascending: false)
          .limit(1);

      return response.isNotEmpty ? response.first : null;
    } catch (error) {
      throw Exception('Failed to get latest measurement: $error');
    }
  }

  /// Get measurement progress (comparison over time)
  Future<Map<String, dynamic>> getMeasurementProgress({
    String? userId,
    required String measurementType,
    int daysPeriod = 30,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      // CORREÇÃO: Usa UTC para os limites do período
      final endDate = DateTime.now().toUtc();
      final startDate = endDate.subtract(Duration(days: daysPeriod));

      final measurements = await getUserMeasurements(
        userId: targetUserId,
        measurementType: measurementType,
        startDate: startDate,
        endDate: endDate,
      );

      if (measurements.isEmpty) {
        return {
          'has_data': false,
          'latest_value': null,
          'previous_value': null,
          'change': null,
          'change_percentage': null,
        };
      }

      // Sort by date to ensure proper ordering
      measurements.sort(
            (a, b) => DateTime.parse(
          a['measured_at'],
        ).compareTo(DateTime.parse(b['measured_at'])),
      );

      final latestValue = (measurements.last['value'] as num).toDouble();
      final previousValue =
      measurements.length > 1
          ? (measurements.first['value'] as num).toDouble()
          : latestValue;

      final change = latestValue - previousValue;
      final changePercentage =
      previousValue != 0 ? (change / previousValue) * 100 : 0.0;

      return {
        'has_data': true,
        'latest_value': latestValue,
        'previous_value': previousValue,
        'change': change,
        'change_percentage': changePercentage,
        'measurement_count': measurements.length,
        'period_days': daysPeriod,
      };
    } catch (error) {
      throw Exception('Failed to get measurement progress: $error');
    }
  }

  /// Log water intake
  Future<Map<String, dynamic>> logWaterIntake({
    required int amountMl,
    DateTime? loggedAt,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      // CORREÇÃO: Converte para UTC PRIMEIRO
      final nowUtc = (loggedAt ?? DateTime.now()).toUtc();
      // CORREÇÃO: Pega a data (string) a partir do UTC
      final dateUtcStr = nowUtc.toIso8601String().split('T')[0];

      final response =
      await _client
          .from('user_water_intake')
          .insert({
        'user_id': currentUser.id,
        'amount_ml': amountMl,
        'logged_at': nowUtc.toIso8601String(), // <-- Envia o timestamp UTC
        'date_logged': dateUtcStr, // <-- Envia a DATA UTC
      })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to log water intake: $error');
    }
  }

  /// Get daily water intake
  Future<Map<String, dynamic>> getDailyWaterIntake({
    String? userId,
    required DateTime date,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      // CORREÇÃO: Converte a data do filtro para UTC antes de extrair a string
      final dateStr = date.toUtc().toIso8601String().split('T')[0];

      final response = await _client
          .from('user_water_intake')
          .select()
          .eq('user_id', targetUserId)
          .eq('date_logged', dateStr) // <-- Agora o filtro bate com o dado salvo
          .order('logged_at', ascending: true);

      final logs = List<Map<String, dynamic>>.from(response);
      final totalAmount = logs.fold<int>(
        0,
            (sum, log) => sum + (log['amount_ml'] as int),
      );

      return {
        'date': dateStr,
        'total_amount_ml': totalAmount,
        'total_amount_liters': (totalAmount / 1000.0).toStringAsFixed(1),
        'logs': logs,
        'log_count': logs.length,
      };
    } catch (error) {
      throw Exception('Failed to get daily water intake: $error');
    }
  }

  /// Get workout progress statistics
  Future<Map<String, dynamic>> getWorkoutProgress({
    String? userId,
    int daysPeriod = 30,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      // CORREÇÃO: Usa UTC para os limites do período
      final endDate = DateTime.now().toUtc();
      final startDate = endDate.subtract(Duration(days: daysPeriod));

      // Get workout counts
      final totalWorkoutsData =
      await _client
          .from('user_workouts')
          .select('id')
          .eq('user_id', targetUserId)
          .gte('started_at', startDate.toIso8601String()) // <-- Envia UTC
          .count();

      final completedWorkoutsData =
      await _client
          .from('user_workouts')
          .select('id')
          .eq('user_id', targetUserId)
          .eq('is_completed', true)
          .gte('started_at', startDate.toIso8601String()) // <-- Envia UTC
          .count();

      // Get total workout time
      final workoutTimeResponse = await _client
          .from('user_workouts')
          .select('total_duration_seconds')
          .eq('user_id', targetUserId)
          .eq('is_completed', true)
          .gte('started_at', startDate.toIso8601String()) // <-- Envia UTC
          .not('total_duration_seconds', 'is', null);

      int totalWorkoutTime = 0;
      for (final workout in workoutTimeResponse) {
        totalWorkoutTime += (workout['total_duration_seconds'] as int?) ?? 0;
      }

      final totalWorkouts = totalWorkoutsData.count ?? 0;
      final completedWorkouts = completedWorkoutsData.count ?? 0;
      final completionRate =
      totalWorkouts > 0
          ? (completedWorkouts / totalWorkouts * 100).round()
          : 0;

      return {
        'period_days': daysPeriod,
        'total_workouts': totalWorkouts,
        'completed_workouts': completedWorkouts,
        'completion_rate': completionRate,
        'total_workout_time_seconds': totalWorkoutTime,
        'total_workout_time_hours': (totalWorkoutTime / 3600).toStringAsFixed(
          1,
        ),
        'average_workout_duration_minutes':
        completedWorkouts > 0
            ? ((totalWorkoutTime / completedWorkouts) / 60).round()
            : 0,
      };
    } catch (error) {
      throw Exception('Failed to get workout progress: $error');
    }
  }

  /// Update measurement
  Future<Map<String, dynamic>> updateMeasurement({
    required String measurementId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // CORREÇÃO: Se 'measured_at' estiver sendo atualizado, ele também precisa ser UTC
      if (updates.containsKey('measured_at') && updates['measured_at'] is DateTime) {
        updates['measured_at'] = (updates['measured_at'] as DateTime).toUtc().toIso8601String();
      }

      final response =
      await _client
          .from('user_measurements')
          .update(updates)
          .eq('id', measurementId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update measurement: $error');
    }
  }

  /// Delete measurement
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _client.from('user_measurements').delete().eq('id', measurementId);
    } catch (error) {
      throw Exception('Failed to delete measurement: $error');
    }
  }

  /// Get nutrition progress (for meals)
  Future<Map<String, dynamic>> getNutritionProgress({
    String? userId,
    int daysPeriod = 30,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      // CORREÇÃO: Usa datas UTC para o filtro
      final endDate = DateTime.now().toUtc();
      final startDate = endDate.subtract(Duration(days: daysPeriod));
      final endDateStr = endDate.toIso8601String().split('T')[0];
      final startDateStr = startDate.toIso8601String().split('T')[0];

      // Get meals in the period
      final mealsResponse = await _client
          .from('user_meals')
          .select('*, meal_food_items(*)')
          .eq('user_id', targetUserId)
          .gte('meal_date', startDateStr) // <-- Filtra pela data UTC
          .lte('meal_date', endDateStr) // <-- Filtra pela data UTC
          .order('meal_date', ascending: false);

      final meals = List<Map<String, dynamic>>.from(mealsResponse);

      // Calculate nutrition statistics
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      final Set<String> uniqueDays = {};

      for (final meal in meals) {
        final mealDate = meal['meal_date'] as String;
        uniqueDays.add(mealDate);

        final foodItems = meal['meal_food_items'] as List<dynamic>? ?? [];
        for (final foodItem in foodItems) {
          totalCalories += (foodItem['calories'] as num?)?.toDouble() ?? 0;
          totalProtein += (foodItem['protein'] as num?)?.toDouble() ?? 0;
          totalCarbs += (foodItem['carbs'] as num?)?.toDouble() ?? 0;
          totalFat += (foodItem['fat'] as num?)?.toDouble() ?? 0;
        }
      }

      final daysWithMeals = uniqueDays.length;

      return {
        'period_days': daysPeriod,
        'total_meals': meals.length,
        'days_with_meals': daysWithMeals,
        'consistency_rate':
        daysPeriod > 0 ? (daysWithMeals / daysPeriod * 100).round() : 0,
        'total_calories': totalCalories,
        'total_protein': totalProtein,
        'total_carbs': totalCarbs,
        'total_fat': totalFat,
        'avg_daily_calories':
        daysWithMeals > 0 ? (totalCalories / daysWithMeals).round() : 0,
        'avg_daily_protein':
        daysWithMeals > 0 ? (totalProtein / daysWithMeals).round() : 0,
      };
    } catch (error) {
      throw Exception('Failed to get nutrition progress: $error');
    }
  }

  /// Calculate workout streak
  Future<Map<String, dynamic>> getWorkoutStreak({String? userId}) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      // CORREÇÃO: Usa UTC para o filtro
      final sixtyDaysAgo = DateTime.now().toUtc().subtract(Duration(days: 60));

      // Get recent workouts (last 60 days)
      final response = await _client
          .from('user_workouts')
          .select()
          .eq('user_id', targetUserId)
          .eq('is_completed', true)
          .gte(
        'completed_at',
        sixtyDaysAgo.toIso8601String(), // <-- Filtra por UTC
      )
          .order('completed_at', ascending: false);

      final workouts = List<Map<String, dynamic>>.from(response);

      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;

      // CORREÇÃO: Compara com a data UTC de hoje
      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);

      // Group workouts by date
      final Map<String, int> workoutsByDate = {};
      for (final workout in workouts) {
        // CORREÇÃO: Interpreta o timestamp salvo (que deve ser UTC)
        final completedAt = DateTime.parse(workout['completed_at']).toUtc();
        final dateKey =
            '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';
        workoutsByDate[dateKey] = (workoutsByDate[dateKey] ?? 0) + 1;
      }

      // Calculate current streak from today backwards
      for (int i = 0; i < 60; i++) {
        // CORREÇÃO: Checa as datas em UTC
        final checkDate = today.subtract(Duration(days: i));
        final dateKey =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

        if (workoutsByDate.containsKey(dateKey)) {
          currentStreak++;
        } else if (currentStreak > 0) {
          break; // Streak broken
        }
      }

      // Calculate longest streak in the period
      final sortedDates = workoutsByDate.keys.toList()..sort();
      DateTime? lastDate;

      for (final dateStr in sortedDates) {
        final currentDate = DateTime.parse(dateStr); // Já é uma data UTC (só data)

        if (lastDate == null || currentDate.difference(lastDate).inDays == 1) {
          tempStreak++;
          longestStreak =
          tempStreak > longestStreak ? tempStreak : longestStreak;
        } else {
          tempStreak = 1;
        }

        lastDate = currentDate;
      }

      return {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'total_workout_days': workoutsByDate.length,
      };
    } catch (error) {
      return {
        'current_streak': 0,
        'longest_streak': 0,
        'total_workout_days': 0,
      };
    }
  }

  /// Delete water intake log
  Future<void> deleteWaterIntakeLog(String logId) async {
    try {
      await _client.from('user_water_intake').delete().eq('id', logId);
    } catch (error) {
      throw Exception('Failed to delete water intake log: $error');
    }
  }
}