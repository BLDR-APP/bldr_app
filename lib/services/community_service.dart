// lib/services/community_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import './auth_service.dart';
import './supabase_service.dart';

class CommunityService {
  CommunityService._();
  static CommunityService? _instance;
  static CommunityService get instance => _instance ??= CommunityService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Retorna 'female' | 'male' | 'other' | null
  Future<String?> getMyGender() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null;

    final row = await _client
        .from('user_profiles') // public.user_profiles
        .select('gender')
        .eq('id', user.id)
        .maybeSingle();

    final Map<String, dynamic>? m =
    (row is Map) ? Map<String, dynamic>.from(row as Map) : null;
    final String? g = m?['gender']?.toString();
    return g?.toLowerCase();
  }

  /// Anúncios (mais novos primeiro).
  Future<List<Map<String, dynamic>>> fetchAnnouncements({int limit = 20}) async {
    try {
      final q = _client
          .from('club_announcements')
      // ALTERAÇÃO: Adicionada a nova coluna ao select.
          .select('*, image_url_main')
          .eq('is_active', true);

      final rows = await q.order('created_at', ascending: false).limit(limit);
      print('Anúncios encontrados: ${rows.length}');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      print('Erro ao buscar anúncios: $e');
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  /// Eventos (mais novos primeiro).
  Future<List<Map<String, dynamic>>> fetchEvents({int limit = 20}) async {
    try {
      final q = _client
          .from('club_events')
          .select('*')
          .eq('is_active', true);

      final rows = await q.order('created_at', ascending: false).limit(limit);
      print('Eventos encontrados: ${rows.length}');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      print('Erro ao buscar eventos: $e');
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  /// Salas: lista TODAS as salas para qualquer usuário autenticado.
  Future<List<Map<String, dynamic>>> fetchRooms({int limit = 20}) async {
    try {
      final rows = await _client
          .from('club_chat_rooms')
          .select('id, name, women_only, created_at')
          .order('created_at', ascending: false)
          .limit(limit);

      print('Salas encontradas: ${rows.length}');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      print('Erro ao buscar salas: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Feed de posts (mais novos primeiro). Cursor opcional por created_at (ISO).
  Future<List<Map<String, dynamic>>> fetchFeed({
    int limit = 20,
    String? cursorIso,
  }) async {
    try {
      var q = _client
          .from('club_posts')
          .select('*')
          .eq('is_active', true);

      if (cursorIso != null && cursorIso.isNotEmpty) {
        q = q.lt('created_at', cursorIso);
      }

      final rows = await q.order('created_at', ascending: false).limit(limit);
      print('Posts do feed encontrados: ${rows.length}');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      print('Erro ao buscar feed: $e');
      return []; // Retorna uma lista vazia em caso de erro
    }
  }
}