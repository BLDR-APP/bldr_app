import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OuraApiService {
  static final OuraApiService _instance = OuraApiService._internal();
  static OuraApiService get instance => _instance;

  final Dio _dio = Dio();
  String? _accessToken;

  OuraApiService._internal() {
    _dio.options.baseUrl = 'https://api.ouraring.com/v2';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Initialize with OAuth access token
  void initialize({required String accessToken}) {
    _accessToken = accessToken;
    _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
  }

  /// Check if service is authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Get daily sleep data for a specific date
  Future<Map<String, dynamic>> getDailySleep({required DateTime day}) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Oura API not authenticated');
      }

      final dateString = day.toIso8601String().substring(0, 10);

      final response = await _dio.get(
        '/usercollection/daily_sleep',
        queryParameters: {
          'start_date': dateString,
          'end_date': dateString,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch sleep data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Oura API Error: ${e.message}');
      }
      // Return mock data for development/demo purposes
      return _getMockSleepData();
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in getDailySleep: $e');
      }
      // Return mock data for development/demo purposes
      return _getMockSleepData();
    }
  }

  /// Get daily activity data for a specific date
  Future<Map<String, dynamic>> getDailyActivity({required DateTime day}) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Oura API not authenticated');
      }

      final dateString = day.toIso8601String().substring(0, 10);

      final response = await _dio.get(
        '/usercollection/daily_activity',
        queryParameters: {
          'start_date': dateString,
          'end_date': dateString,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to fetch activity data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Oura API Error: ${e.message}');
      }
      return _getMockActivityData();
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in getDailyActivity: $e');
      }
      return _getMockActivityData();
    }
  }

  /// Get daily readiness data for a specific date
  Future<Map<String, dynamic>> getDailyReadiness(
      {required DateTime day}) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Oura API not authenticated');
      }

      final dateString = day.toIso8601String().substring(0, 10);

      final response = await _dio.get(
        '/usercollection/daily_readiness',
        queryParameters: {
          'start_date': dateString,
          'end_date': dateString,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to fetch readiness data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Oura API Error: ${e.message}');
      }
      return _getMockReadinessData();
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in getDailyReadiness: $e');
      }
      return _getMockReadinessData();
    }
  }

  /// Mock sleep data for development/demo
  Map<String, dynamic> _getMockSleepData() {
    return {
      "data": [
        {
          "id": "mock-sleep-id",
          "day": DateTime.now().toIso8601String().substring(0, 10),
          "score": 85,
          "total_sleep_duration": 28800, // 8 hours in seconds
          "deep_sleep_duration": 7200, // 2 hours
          "light_sleep_duration": 18000, // 5 hours
          "rem_sleep_duration": 3600, // 1 hour
          "restless_periods": 2,
          "sleep_efficiency": 92,
          "sleep_latency": 480, // 8 minutes in seconds
          "sleep_timing": 75,
          "bedtime_start": "2025-01-22T23:30:00+00:00",
          "bedtime_end": "2025-01-23T07:30:00+00:00",
          "resting_heart_rate": 52,
          "average_hrv": 45,
          "temperature_deviation": -0.2,
          "temperature_trend_deviation": 0.1
        }
      ],
      "next_token": null
    };
  }

  /// Mock activity data for development/demo
  Map<String, dynamic> _getMockActivityData() {
    return {
      "data": [
        {
          "id": "mock-activity-id",
          "day": DateTime.now().toIso8601String().substring(0, 10),
          "score": 78,
          "active_calories": 420,
          "average_met_minutes": 180,
          "equivalent_walking_distance": 8500,
          "high_activity_met_minutes": 45,
          "high_activity_time": 3600,
          "inactivity_alerts": 2,
          "low_activity_met_minutes": 120,
          "low_activity_time": 7200,
          "medium_activity_met_minutes": 90,
          "medium_activity_time": 5400,
          "met": {
            "interval": 60,
            "items": [],
            "timestamp": DateTime.now().toIso8601String()
          },
          "meters_to_target": 1500,
          "non_wear_time": 0,
          "resting_time": 75600,
          "sedentary_met_minutes": 600,
          "sedentary_time": 36000,
          "steps": 8500,
          "target_calories": 500,
          "target_meters": 10000,
          "total_calories": 2100
        }
      ],
      "next_token": null
    };
  }

  /// Mock readiness data for development/demo
  Map<String, dynamic> _getMockReadinessData() {
    return {
      "data": [
        {
          "id": "mock-readiness-id",
          "day": DateTime.now().toIso8601String().substring(0, 10),
          "score": 82,
          "temperature_deviation": -0.1,
          "temperature_trend_deviation": 0.2,
          "activity_balance": 75,
          "body_temperature": 98.6,
          "hrv_balance": 80,
          "previous_day_activity": 78,
          "previous_night_sleep": 85,
          "recovery_index": 88,
          "resting_heart_rate": 52,
          "sleep_balance": 90
        }
      ],
      "next_token": null
    };
  }

  /// Clear authentication
  void clearAuthentication() {
    _accessToken = null;
    _dio.options.headers.remove('Authorization');
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
