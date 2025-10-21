import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class NutritionService {
  static NutritionService? _instance;
  static NutritionService get instance => _instance ??= NutritionService._();

  NutritionService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get food items with search
  Future<List<Map<String, dynamic>>> searchFoodItems({
    String? search,
    bool verifiedOnly = false,
    int limit = 20,
  }) async {
    try {
      var query = _client.from('food_items').select();

      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,brand.ilike.%$search%');
      }

      if (verifiedOnly) {
        query = query.eq('is_verified', true);
      }

      final response = await query.order('name', ascending: true).limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to search food items: $error');
    }
  }

  /// Get food item by ID
  Future<Map<String, dynamic>?> getFoodItem(String foodItemId) async {
    try {
      final response = await _client
          .from('food_items')
          .select()
          .eq('id', foodItemId)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get food item: $error');
    }
  }

  /// Create custom food item
  Future<Map<String, dynamic>> createFoodItem({
    required String name,
    String? brand,
    String? barcode,
    required double caloriesPer100g,
    double proteinPer100g = 0,
    double carbsPer100g = 0,
    double fatPer100g = 0,
    double fiberPer100g = 0,
    double sugarPer100g = 0,
    double sodiumPer100g = 0,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário tem que estar autenticado');
      }

      final response = await _client
          .from('food_items')
          .insert({
            'name': name,
            'brand': brand,
            'barcode': barcode,
            'calories_per_100g': caloriesPer100g,
            'protein_per_100g': proteinPer100g,
            'carbs_per_100g': carbsPer100g,
            'fat_per_100g': fatPer100g,
            'fiber_per_100g': fiberPer100g,
            'sugar_per_100g': sugarPer100g,
            'sodium_per_100g': sodiumPer100g,
            'created_by': currentUser.id,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Falha ao criar item: $error');
    }
  }

  /// Create meal
  Future<Map<String, dynamic>> createMeal({
    required String mealType,
    required DateTime mealDate,
    String? name,
    String? notes,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário tem que estar autenticado');
      }

      final response = await _client
          .from('user_meals')
          .insert({
            'user_id': currentUser.id,
            'meal_type': mealType,
            'meal_date': mealDate.toIso8601String().split('T')[0],
            'name': name,
            'notes': notes,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Falha ao criar refeição: $error');
    }
  }

  /// Add food item to meal
  Future<Map<String, dynamic>> addFoodToMeal({
    required String mealId,
    required String foodItemId,
    required double quantityGrams,
  }) async {
    try {
      // Get food item nutrition info
      final foodItem = await getFoodItem(foodItemId);
      if (foodItem == null) {
        throw Exception('Comida não localizada');
      }

      // Calculate nutrition values based on quantity
      final multiplier = quantityGrams / 100.0;
      final calories =
          (foodItem['calories_per_100g'] as num).toDouble() * multiplier;
      final protein =
          (foodItem['protein_per_100g'] as num).toDouble() * multiplier;
      final carbs = (foodItem['carbs_per_100g'] as num).toDouble() * multiplier;
      final fat = (foodItem['fat_per_100g'] as num).toDouble() * multiplier;

      final response = await _client
          .from('meal_food_items')
          .insert({
            'meal_id': mealId,
            'food_item_id': foodItemId,
            'quantity_grams': quantityGrams,
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add food to meal: $error');
    }
  }

  /// Get user meals for a date
  Future<List<Map<String, dynamic>>> getUserMealsForDate({
    String? userId,
    required DateTime date,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('user_meals')
          .select('''
            id, meal_type, meal_date, name, notes, created_at,
            meal_food_items(
              id, quantity_grams, calories, protein, carbs, fat,
              food_items(id, name, brand)
            )
          ''')
          .eq('user_id', targetUserId)
          .eq('meal_date', dateStr)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user meals: $error');
    }
  }

  /// Get daily nutrition summary
  Future<Map<String, dynamic>> getDailyNutritionSummary({
    String? userId,
    required DateTime date,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;
      final dateStr = date.toIso8601String().split('T')[0];

      // Get all meals for the date with food items
      final meals = await getUserMealsForDate(userId: targetUserId, date: date);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      // Calculate totals
      for (final meal in meals) {
        final foodItems = meal['meal_food_items'] as List;
        for (final foodItem in foodItems) {
          totalCalories += (foodItem['calories'] as num).toDouble();
          totalProtein += (foodItem['protein'] as num).toDouble();
          totalCarbs += (foodItem['carbs'] as num).toDouble();
          totalFat += (foodItem['fat'] as num).toDouble();
        }
      }

      return {
        'date': dateStr,
        'total_calories': totalCalories.round(),
        'total_protein': totalProtein.round(),
        'total_carbs': totalCarbs.round(),
        'total_fat': totalFat.round(),
        'meals_count': meals.length,
      };
    } catch (error) {
      throw Exception('Failed to get daily nutrition summary: $error');
    }
  }

  /// Update meal
  Future<Map<String, dynamic>> updateMeal({
    required String mealId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client
          .from('user_meals')
          .update(updates)
          .eq('id', mealId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update meal: $error');
    }
  }

  /// Delete meal
  Future<void> deleteMeal(String mealId) async {
    try {
      await _client.from('user_meals').delete().eq('id', mealId);
    } catch (error) {
      throw Exception('Failed to delete meal: $error');
    }
  }

  /// Remove food from meal
  Future<void> removeFoodFromMeal(String mealFoodItemId) async {
    try {
      await _client.from('meal_food_items').delete().eq('id', mealFoodItemId);
    } catch (error) {
      throw Exception('Failed to remove food from meal: $error');
    }
  }

  Future<List<Map<String, dynamic>>> searchByBarcode(String ean) async {
    // chama a Edge Function 'food-search' com { barcode }
    final sb = Supabase.instance.client;

    final resp = await sb.functions.invoke('food-search', body: {'barcode': ean});
    final data = (resp.data as List?) ?? [];

    // mapeia para o formato que sua UI usa hoje:
    // name / brand / calories_per_100g / protein_per_100g / carbs_per_100g / fat_per_100g / id
    return data.map<Map<String, dynamic>>((raw) {
      final j = Map<String, dynamic>.from(raw as Map);
      return {
        'id': j['id'],
        'name': j['name'],
        'brand': j['brand'],
        'calories_per_100g': j['kcal'],
        'protein_per_100g': j['protein_g'],
        'carbs_per_100g': j['carbs_g'],
        'fat_per_100g': j['fat_g'],
      };
    }).toList();
  }
}
