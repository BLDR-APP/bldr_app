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
    bool includeUserItems = false,
  }) async {
    try {
      var query = _client.from('food_items').select();
      if (search != null && search.isNotEmpty) query = query.or('name.ilike.%$search%,brand.ilike.%$search%');
      final currentUser = AuthService.instance.currentUser;
      if (verifiedOnly && !includeUserItems) query = query.eq('is_verified', true);
      else if (includeUserItems && currentUser != null) query = query.or('is_verified.eq.true,user_id.eq.${currentUser.id}');
      else query = query.or('is_verified.eq.true,user_id.is.null');
      final response = await query.order('name', ascending: true).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) { throw Exception('Failed to search food items: $error'); }
  }

  /// Get favorite food items for a specific user
  Future<List<Map<String, dynamic>>> getFavoriteFoodItems(String userId) async {
    try {
      final response = await _client.from('food_items').select().eq('user_id', userId).eq('is_favorite', true).order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) { throw Exception('Failed to get favorite food items: $error'); }
  }

  /// Get food item by ID
  Future<Map<String, dynamic>?> getFoodItem(String foodItemId) async {
    try {
      final response = await _client.from('food_items').select().eq('id', foodItemId).maybeSingle();
      return response as Map<String, dynamic>?;
    } catch (error) { print('Failed to get food item: $error'); return null; }
  }

  /// Create or update a custom food item defined by the user
  Future<Map<String, dynamic>> createOrUpdateUserFoodItem({
    required String name, String? servingDescription, required double caloriesPerServing,
    required double proteinPerServing, required double carbsPerServing, required double fatPerServing,
    required bool isFavorite,
  }) async {
    final currentUser = AuthService.instance.currentUser; if (currentUser == null) throw Exception('User must be authenticated.');
    try {
      final response = await _client.from('food_items').insert({
        'user_id': currentUser.id, 'name': name, 'serving_description': '100g',
        'calories_per_serving': caloriesPerServing, 'protein_per_serving': proteinPerServing,
        'carbs_per_serving': carbsPerServing, 'fat_per_serving': fatPerServing, 'is_favorite': isFavorite,
        'is_verified': true, 'calories_per_100g': caloriesPerServing, 'protein_per_100g': proteinPerServing, 'carbs_per_100g': carbsPerServing, 'fat_per_100g': fatPerServing,
      }).select().single();
      return response;
    } catch (error) { print('Error in createOrUpdateUserFoodItem: $error'); throw Exception('Failed to create/update user food item: $error'); }
  }

  /* createFoodItem comentado pois foi substituído por createOrUpdateUserFoodItem
  Future<Map<String, dynamic>> createFoodItem({ ... }) async { ... }
  */

  /// Create or get existing meal
  Future<Map<String, dynamic>> createMeal({
    required String mealType, required DateTime mealDate, String? name, String? notes,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser; if (currentUser == null) throw Exception('Usuário tem que estar autenticado');
      final dateStr = mealDate.toIso8601String().split('T')[0];
      final existingMeal = await _client.from('user_meals').select('id').eq('user_id', currentUser.id).eq('meal_type', mealType).eq('meal_date', dateStr).maybeSingle();
      if (existingMeal != null) return existingMeal;
      final response = await _client.from('user_meals').insert({'user_id': currentUser.id, 'meal_type': mealType, 'meal_date': dateStr, 'name': name, 'notes': notes }).select('id').single();
      return response;
    } catch (error) { throw Exception('Falha ao criar/obter refeição: $error'); }
  }

  // --- MODIFICADO: addFoodToMeal (Lógica de Cálculo Corrigida) ---
  /// Add food item to meal
  Future<Map<String, dynamic>> addFoodToMeal({
    required String mealId,
    required String foodItemId,
    required double quantity, // Nome genérico: pode ser gramas OU fator de porção
    String? name,
  }) async {
    try {
      final foodItem = await getFoodItem(foodItemId);
      if (foodItem == null) {
        throw Exception('Comida não localizada (ID: $foodItemId)');
      }

      double calories = 0, protein = 0, carbs = 0, fat = 0;
      double multiplier = 0;

      // --- LÓGICA DE CÁLCULO CORRIGIDA ---
      // PRIORIZA dados por porção. Se existirem, 'quantity' é um multiplicador (ex: 1.5 porções).
      if (foodItem['calories_per_serving'] != null) {
        multiplier = quantity; // quantity é o fator (ex: 0.5, 1.0, 2.0)
        calories = ((foodItem['calories_per_serving'] as num?)?.toDouble() ?? 0.0) * multiplier;
        protein = ((foodItem['protein_per_serving'] as num?)?.toDouble() ?? 0.0) * multiplier;
        carbs = ((foodItem['carbs_per_serving'] as num?)?.toDouble() ?? 0.0) * multiplier;
        fat = ((foodItem['fat_per_serving'] as num?)?.toDouble() ?? 0.0) * multiplier;
      }
      // Se não houver dados por porção, usa dados por 100g. 'quantity' são gramas.
      else if (foodItem['calories_per_100g'] != null) {
        multiplier = quantity / 100.0; // quantity são gramas (ex: 150g)
        calories = ((foodItem['calories_per_100g'] as num?)?.toDouble() ?? 0.0) * multiplier;
        protein = ((foodItem['protein_per_100g'] as num?)?.toDouble() ?? 0.0) * multiplier;
        carbs = ((foodItem['carbs_per_100g'] as num?)?.toDouble() ?? 0.0) * multiplier;
        fat = ((foodItem['fat_per_100g'] as num?)?.toDouble() ?? 0.0) * multiplier;
      } else {
        // Item não tem dados nutricionais válidos
        print("Aviso: FoodItem ID $foodItemId não tem dados nutricionais.");
      }
      // --- FIM DA LÓGICA DE CÁLCULO ---

      final response = await _client
          .from('meal_food_items')
          .insert({
        'meal_id': mealId,
        'food_item_id': foodItemId,
        'quantity_grams': quantity, // Salva a quantidade (seja fator ou gramas)
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'name': name,
      })
          .select()
          .single();

      return response;
    } catch (error) {
      // Verifica se é erro de overflow numérico
      if (error is PostgrestException && error.code == '22003') {
        throw Exception('Erro de cálculo. Verifique os valores de macro e porção inseridos.');
      }
      throw Exception('Failed to add food to meal: $error');
    }
  }
  // --- FIM DA MODIFICAÇÃO ---


  /// Get user meals for a date
  Future<List<Map<String, dynamic>>> getUserMealsForDate({
    String? userId, required DateTime date,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser; if (currentUser == null) throw Exception('User must be authenticated');
      final targetUserId = userId ?? currentUser.id;
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _client.from('user_meals').select('''
            id, meal_type, meal_date, name, notes, created_at,
            meal_food_items(
              id, quantity_grams, calories, protein, carbs, fat,
              food_items(id, name, brand, serving_description)
            )
          ''').eq('user_id', targetUserId).eq('meal_date', dateStr);
      // Linha .order(...) foi REMOVIDA
      final meals = List<Map<String, dynamic>>.from(response);
      for (var meal in meals) { /* ... processamento de null ... */ }
      return meals;
    } catch (error) { throw Exception('Failed to get user meals: $error'); }
  }


  /// Get daily nutrition summary (Lógica Original - Client Side)
  Future<Map<String, dynamic>> getDailyNutritionSummary({
    String? userId,
    required DateTime date,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        print("Aviso: Usuário não autenticado em getDailyNutritionSummary.");
        return {'date': date.toIso8601String().split('T')[0], 'total_calories': 0, 'total_protein': 0, 'total_carbs': 0, 'total_fat': 0, 'meals_count': 0};
      }
      final targetUserId = userId ?? currentUser.id;
      final dateStr = date.toIso8601String().split('T')[0];

      // Busca todas as refeições do dia
      final meals = await getUserMealsForDate(userId: targetUserId, date: date);

      // Inicializa totais
      double totalCalories = 0; double totalProtein = 0; double totalCarbs = 0; double totalFat = 0;

      // Soma os valores de cada item em cada refeição
      for (final meal in meals) {
        final foodItems = meal['meal_food_items'] as List;
        for (final foodItem in foodItems) {
          totalCalories += (foodItem['calories'] as num?)?.toDouble() ?? 0.0;
          totalProtein += (foodItem['protein'] as num?)?.toDouble() ?? 0.0;
          totalCarbs += (foodItem['carbs'] as num?)?.toDouble() ?? 0.0;
          totalFat += (foodItem['fat'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return { 'date': dateStr, 'total_calories': totalCalories.round(), 'total_protein': totalProtein.round(), 'total_carbs': totalCarbs.round(), 'total_fat': totalFat.round(), 'meals_count': meals.length };
    } catch (error) {
      print("Erro em getDailyNutritionSummary (Client-side calculation): $error");
      return {'date': date.toIso8601String().split('T')[0], 'total_calories': 0, 'total_protein': 0, 'total_carbs': 0, 'total_fat': 0, 'meals_count': 0};
    }
  }

  // _calculateSummaryClientSide foi removido e sua lógica movida para getDailyNutritionSummary

  // --- Métodos restantes (update, delete, remove, searchByBarcode) permanecem iguais ---
  Future<Map<String, dynamic>> updateMeal({required String mealId, required Map<String, dynamic> updates}) async { try { final response = await _client.from('user_meals').update(updates).eq('id', mealId).select().single(); return response; } catch (error) { throw Exception('Failed to update meal: $error'); } }
  Future<void> deleteMeal(String mealId) async { try { await _client.from('user_meals').delete().eq('id', mealId); } catch (error) { throw Exception('Failed to delete meal: $error'); } }
  Future<void> removeFoodFromMeal(String mealFoodItemId) async { try { await _client.from('meal_food_items').delete().eq('id', mealFoodItemId); } catch (error) { throw Exception('Failed to remove food from meal: $error'); } }
  Future<List<Map<String, dynamic>>> searchByBarcode(String ean) async { try { final resp = await _client.functions.invoke('food-search', body: {'barcode': ean}); if (resp.status != 200) { throw Exception('Edge function failed with status ${resp.status}: ${resp.data}'); } final data = (resp.data as List?) ?? []; return data.map<Map<String, dynamic>>((raw) { final j = Map<String, dynamic>.from(raw as Map); return { 'id': j['id']?.toString(), 'name': j['name']?.toString() ?? 'Sem nome', 'brand': j['brand']?.toString() ?? '', 'calories_per_100g': (j['kcal'] as num?)?.toDouble() ?? 0.0, 'protein_per_100g': (j['protein_g'] as num?)?.toDouble() ?? 0.0, 'carbs_per_100g': (j['carbs_g'] as num?)?.toDouble() ?? 0.0, 'fat_per_100g': (j['fat_g'] as num?)?.toDouble() ?? 0.0, 'serving_description': null, 'calories_per_serving': null, 'protein_per_serving': null, 'carbs_per_serving': null, 'fat_per_serving': null, }; }).toList(); } catch (error) { print('Error in searchByBarcode: $error'); return []; } }

} // Fim da classe NutritionService