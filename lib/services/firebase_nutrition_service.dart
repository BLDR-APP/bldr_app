// firebase_nutrition_service.dart (COMPLETO COM UPDATE E DELETE)

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import './auth_service.dart';
import './supabase_service.dart';

class FirebaseNutritionService {
  static FirebaseNutritionService? _instance;
  static FirebaseNutritionService get instance => _instance ??= FirebaseNutritionService._();

  FirebaseNutritionService._() {
    // Inicializa o cliente nomeado 'alimentosDB' para TODAS as operações de Firestore.
    try {
      _dbAlimentos = FirebaseFirestore.instanceFor(app: Firebase.app('alimentosDB'));
    } catch (e) {
      print("Aviso: Firebase app 'alimentosDB' não encontrado. Verifique a inicialização do Firebase. Erro: $e");
      // Fallback: Se o app nomeado falhar, usa a instância padrão (o que causou o erro anterior, mas é um fallback de segurança).
      _dbAlimentos = FirebaseFirestore.instance;
    }
  }

  SupabaseClient get _supabaseClient => SupabaseService.instance.client;
  // O cliente _firestoreClient padrão não será mais usado diretamente para persistência de dados.
  // FirebaseFirestore get _firestoreClient => FirebaseFirestore.instance;
  late FirebaseFirestore _dbAlimentos; // Cliente ÚNICO para todos os dados de Nutrição (alimentosDB)

  String? get _currentSupabaseUserId => AuthService.instance.currentUser?.id;

  // =================================================================
  // === LÓGICA DE CÁLCULO CENTRAL (MANTIDA) ===
  // =================================================================
  Map<String, double> calculateMacros({
    required double quantityGrams,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
  }) {
    if (quantityGrams <= 0) {
      return {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    }

    final double multiplier = quantityGrams / 100.0;

    final double calories = caloriesPer100g * multiplier;
    final double protein = proteinPer100g * multiplier;
    final double carbs = carbsPer100g * multiplier;
    final double fat = fatPer100g * multiplier;

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  // =================================================================
  // === 1. BUSCA DE ALIMENTOS (USA _dbAlimentos) ===
  // =================================================================
  Future<List<Map<String, dynamic>>> searchFoodItemsFirebase({
    required String query,
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) return [];

      final String startQuery = query.toUpperCase();
      final String endQuery = startQuery + '\uf8ff';

      final snapshot = await _dbAlimentos // USANDO CLIENTE NOMEADO
          .collection('alimentos')
          .where('name', isGreaterThanOrEqualTo: startQuery)
          .where('name', isLessThan: endQuery)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (error) {
      throw Exception('Falha ao buscar alimentos na base externa: $error');
    }
  }

  // =================================================================
  // === 2. FAVORITOS / MANUAIS (USA _dbAlimentos) ===
  // =================================================================
  Future<Map<String, dynamic>> saveFoodItemToFavorites({
    required String name,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    required String userId,
  }) async {
    try {
      // CORREÇÃO: USANDO _dbAlimentos (Projeto Nutrição)
      final docRef = await _dbAlimentos.collection('user_favorites').add({
        'user_id': userId,
        'name': name,
        'calories_per_100g': caloriesPer100g,
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fat_per_100g': fatPer100g,
        'created_at': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;
      data['created_by'] = userId;
      return data;
    } catch (error) {
      throw Exception('Falha ao salvar item nos favoritos do Firebase: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteFoodItemsFirebase(String userId) async {
    try {
      // CORREÇÃO: USANDO _dbAlimentos (Projeto Nutrição)
      final snapshot = await _dbAlimentos
          .collection('user_favorites')
          .where('user_id', isEqualTo: userId)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (error) {
      throw Exception('Falha ao obter favoritos do Firebase: $error');
    }
  }

  // =================================================================
  // === 3. PERSISTÊNCIA DA REFEIÇÃO (USA _dbAlimentos) ===
  // =================================================================
  Future<void> addFoodToMealFirebase({
    required String mealType,
    required DateTime mealDate,
    required Map<String, dynamic> foodItem,
    required double quantityGrams,
    String? createdBy,
  }) async {
    final userId = _currentSupabaseUserId;
    if (userId == null) throw Exception('Usuário Supabase não autenticado.');

    final double calsPer100g = (foodItem['calories_per_100g'] as num?)?.toDouble() ?? 0.0;
    final double protPer100g = (foodItem['protein_per_100g'] as num?)?.toDouble() ?? 0.0;
    final double carbsPer100g = (foodItem['carbs_per_100g'] as num?)?.toDouble() ?? 0.0;
    final double fatPer100g = (foodItem['fat_per_100g'] as num?)?.toDouble() ?? 0.0;

    final calculatedMacros = calculateMacros(
      quantityGrams: quantityGrams,
      caloriesPer100g: calsPer100g,
      proteinPer100g: protPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
    );

    final mealData = {
      'user_id': userId,
      'meal_type': mealType,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'date': mealDate.toIso8601String().split('T')[0],
      'food_item_id': foodItem['id'],
      'food_name': foodItem['name'],
      'quantity_grams': quantityGrams,
      'calories': calculatedMacros['calories']?.roundToDouble(),
      'protein': calculatedMacros['protein']?.roundToDouble(),
      'carbs': calculatedMacros['carbs']?.roundToDouble(),
      'fat': calculatedMacros['fat']?.roundToDouble(),
      'created_by': foodItem['created_by'] ?? createdBy,
    };

    try {
      // CORREÇÃO: USANDO _dbAlimentos (Projeto Nutrição)
      await _dbAlimentos.collection('user_meals').add(mealData);
    } catch (error) {
      throw Exception('Falha ao persistir refeição no Firebase: $error');
    }
  }

  // >>> NOVO MÉTODO: UPDATE (PARA A NOVA FUNCIONALIDADE) <<<
  /// Atualiza a quantidade (grams) de um log existente e recalcula os macros.
  Future<void> updateFoodLogItem({
    required String foodLogId,
    required Map<String, dynamic> foodItem, // Detalhes do item (do documento que será atualizado)
    required double newQuantityGrams,
  }) async {
    // Os campos per 100g já estão nos documentos user_meals como "calories", "protein", etc.,
    // mas precisamos recalcular a proporção de 100g para usar calculateMacros.

    // 1. Recalcular a taxa / 100g a partir dos valores do documento (protegendo contra zero)
    final double currentQuantity = (foodItem['quantity_grams'] as num?)?.toDouble() ?? 0.0;

    // Se a quantidade for zero, usamos o valor fixo de 100 para o cálculo.
    final double safeQuantity = currentQuantity > 0 ? currentQuantity : 100.0;

    // Calcula a taxa de 100g (Ex: (Total Cal / Qtd Consumida) * 100)
    final double calsPer100g = ((foodItem['calories'] as num?)?.toDouble() ?? 0.0) / safeQuantity * 100.0;
    final double protPer100g = ((foodItem['protein'] as num?)?.toDouble() ?? 0.0) / safeQuantity * 100.0;
    final double carbsPer100g = ((foodItem['carbs'] as num?)?.toDouble() ?? 0.0) / safeQuantity * 100.0;
    final double fatPer100g = ((foodItem['fat'] as num?)?.toDouble() ?? 0.0) / safeQuantity * 100.0;

    // 2. Recalcular os novos totais com a nova quantidade
    final calculatedMacros = calculateMacros(
      quantityGrams: newQuantityGrams,
      caloriesPer100g: calsPer100g,
      proteinPer100g: protPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
    );

    // 3. Montar o payload de atualização
    final updates = {
      'quantity_grams': newQuantityGrams,
      'calories': calculatedMacros['calories']?.roundToDouble(),
      'protein': calculatedMacros['protein']?.roundToDouble(),
      'carbs': calculatedMacros['carbs']?.roundToDouble(),
      'fat': calculatedMacros['fat']?.roundToDouble(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    try {
      await _dbAlimentos.collection('user_meals').doc(foodLogId).update(updates);
    } catch (error) {
      throw Exception('Falha ao atualizar log de comida: $error');
    }
  }


  // >>> MÉTODO: DELEÇÃO (PARA A NOVA FUNCIONALIDADE) <<<
  /// Deleta um único item de comida da coleção 'user_meals' pelo ID do documento.
  Future<void> deleteFoodLogItem(String foodLogId) async {
    try {
      // Usa o cliente _dbAlimentos que está configurado para o projeto de Nutrição
      await _dbAlimentos.collection('user_meals').doc(foodLogId).delete();
      print('Documento $foodLogId deletado com sucesso.');
    } catch (error) {
      print('Erro ao deletar log de comida: $error');
      throw Exception('Falha ao deletar log de comida: $error');
    }
  }

  // =================================================================
  // === 4. FUNÇÕES DE LEITURA (USA _dbAlimentos) ===
  // =================================================================

  Future<List<Map<String, dynamic>>> getUserMealsForDateFirebase({
    String? userId, required DateTime date,
  }) async {
    final targetUserId = userId ?? _currentSupabaseUserId;
    if (targetUserId == null) return [];
    final dateStr = date.toIso8601String().split('T')[0];

    try {
      // CORREÇÃO: USANDO _dbAlimentos (Projeto Nutrição)
      final snapshot = await _dbAlimentos
          .collection('user_meals')
          .where('user_id', isEqualTo: targetUserId)
          .where('date', isEqualTo: dateStr)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (error) {
      throw Exception('Falha ao obter refeições do Firebase: $error');
    }
  }

  Future<Map<String, dynamic>> getDailyNutritionSummaryFirebase({
    String? userId, required DateTime date,
  }) async {
    // Reutiliza a função de busca (que agora usa _dbAlimentos)
    final meals = await getUserMealsForDateFirebase(userId: userId, date: date);

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in meals) {
      totalCalories += (meal['calories'] as num?)?.toDouble() ?? 0.0;
      totalProtein += (meal['protein'] as num?)?.toDouble() ?? 0.0;
      totalCarbs += (meal['carbs'] as num?)?.toDouble() ?? 0.0;
      totalFat += (meal['fat'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'date': date.toIso8601String().split('T')[0],
      'total_calories': totalCalories.round(),
      'total_protein': totalProtein.round(),
      'total_carbs': totalCarbs.round(),
      'total_fat': totalFat.round(),
      'meals_count': meals.length,
    };
  }
}