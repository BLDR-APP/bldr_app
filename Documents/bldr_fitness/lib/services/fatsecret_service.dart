// lib/services/fatsecret_service.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class FatSecretService {
  FatSecretService._();
  static final FatSecretService instance = FatSecretService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // -------- chamadas via Edge Function "fatsecret" --------

  Future<Map<String, dynamic>> foodsSearch({
    required String query,
    int pageNumber = 0,
    int maxResults = 20,
    String? country,   // "BR"
    String? language,  // "pt_BR"
  }) async {
    final payload = {
      'action': 'foods_search',
      'query': query,
      'page': pageNumber,
      'maxResults': maxResults,
      if (country != null) 'region': country,
      if (language != null) 'language': language,
    };

    final resp = await _client.functions.invoke('fatsecret', body: payload);
    final map = _normalize(resp.data);
    if (map['ok'] != true) {
      throw Exception('foods.search (edge) error: ${map['error']}');
    }
    return (map['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> foodGet({
    required String foodId,
    String? country,
    String? language,
  }) async {
    final payload = {
      'action': 'food_get',
      'food_id': foodId,
      if (country != null) 'region': country,
      if (language != null) 'language': language,
    };

    final resp = await _client.functions.invoke('fatsecret', body: payload);
    final map = _normalize(resp.data);
    if (map['ok'] != true) {
      throw Exception('food.get (edge) error: ${map['error']}');
    }
    return (map['data'] as Map<String, dynamic>);
  }

  Future<String?> findFoodIdForBarcode(String gtin13) async {
    final payload = {'action': 'barcode', 'barcode': gtin13};

    final resp = await _client.functions.invoke('fatsecret', body: payload);
    final map = _normalize(resp.data);
    if (map['ok'] != true) {
      throw Exception('barcode (edge) error: ${map['error']}');
    }
    final data = map['data'] as Map<String, dynamic>;
    final foodId = data['food_id']?.toString();
    if (foodId == null || foodId.isEmpty || foodId == '0') return null;
    return foodId;
  }

  // ---------- Helpers (mesmos mapeadores de antes) ----------

  Map<String, dynamic> mapFoodSummaryToApp(Map<String, dynamic> fsFood) {
    return {
      'id': fsFood['food_id']?.toString(),
      'name': fsFood['food_name'],
      'brand': fsFood['brand_name'],
      'description': fsFood['food_description'],
      'source': 'fatsecret',
    };
  }

  Map<String, dynamic> mapFoodDetailsToApp(Map<String, dynamic> fsFood) {
    final food = fsFood['food'] ?? {};
    final servings = food['servings']?['serving'];
    final first = (servings is List)
        ? (servings.isNotEmpty ? servings.first : null)
        : servings;

    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return {
      'id': food['food_id']?.toString(),
      'name': food['food_name'],
      'brand': food['brand_name'],
      'serving_description': first?['serving_description'],
      'serving_qty': _toDouble(first?['number_of_units']),
      'serving_unit': first?['measurement_description'],
      'calories': _toDouble(first?['calories']),
      'protein_g': _toDouble(first?['protein']),
      'fat_g': _toDouble(first?['fat']),
      'carbs_g': _toDouble(first?['carbohydrate']),
      'fiber_g': _toDouble(first?['fiber']),
      'sugar_g': _toDouble(first?['sugar']),
      'sodium_mg': _toDouble(first?['sodium']),
      'source': 'fatsecret',
      'raw': fsFood,
    };
  }

  Map<String, dynamic> _normalize(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return {};
  }
}
