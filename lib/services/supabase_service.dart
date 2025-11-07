import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bldr_fitness/main.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  // CORREÇÃO: O cliente Supabase agora é acessado diretamente.
  // Isso resolve o problema de travamento que vimos antes.
  SupabaseClient get client => Supabase.instance.client;

  static String get supabaseUrl => appConfig['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => appConfig['SUPABASE_ANON_KEY'] ?? '';

  /// Initialize Supabase with URL and Anon Key
  static Future<void> initialize() async {
    try {
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be provided as environment variables',
        );
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
          detectSessionInUri: false, // Prevent deep-link auth issues
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          timeout: Duration(seconds: 30),
        ),
      );

      if (kDebugMode) {
        print('Supabase initialized successfully');
        print('URL: $supabaseUrl');
        print(
          'Auth: ${Supabase.instance.client.auth.currentUser?.id ?? "Not authenticated"}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase initialization error: $e');
      }
      rethrow;
    }
  }

  /// Get current authenticated user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Sign out current user
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${supabaseUrl}/auth/callback',
    );
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    await client.from('user_profiles').update(updates).eq('id', currentUser!.id);
  }

  /// Create user profile
  Future<void> createUserProfile(Map<String, dynamic> profile) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    profile['id'] = currentUser!.id;
    await client.from('user_profiles').insert(profile);
  }

  /// Generic query method
  Future<List<Map<String, dynamic>>> query(
      String table, {
        String? select,
        Map<String, dynamic>? filters,
        String? orderBy,
        bool ascending = true,
        int? limit,
      }) async {
    try {
      dynamic query = client.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        for (var entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Query error on table $table: $e');
      }
      rethrow;
    }
  }

  /// Generic insert method
  Future<Map<String, dynamic>?> insert(
      String table,
      Map<String, dynamic> data, {
        String? select,
      }) async {
    try {
      final response = await client
          .from(table)
          .insert(data)
          .select(select ?? '*')
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Insert error on table $table: $e');
      }
      rethrow;
    }
  }

  /// Generic update method
  Future<Map<String, dynamic>?> update(
      String table,
      Map<String, dynamic> data,
      Map<String, dynamic> filters, {
        String? select,
      }) async {
    try {
      PostgrestFilterBuilder query = client.from(table).update(data);

      for (var entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      final response = await query.select(select ?? '*').maybeSingle();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Update error on table $table: $e');
      }
      rethrow;
    }
  }

  /// Generic delete method
  Future<void> delete(String table, Map<String, dynamic> filters) async {
    try {
      PostgrestFilterBuilder query = client.from(table).delete();

      for (var entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      await query;
    } catch (e) {
      if (kDebugMode) {
        print('Delete error on table $table: $e');
      }
      rethrow;
    }
  }

  /// Execute RPC (Remote Procedure Call)
  Future<List<Map<String, dynamic>>> rpc(
      String functionName, {
        Map<String, dynamic>? params,
      }) async {
    try {
      final response = await client.rpc(functionName, params: params ?? {});
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('RPC error for function $functionName: $e');
      }
      rethrow;
    }
  }

  /// Real-time subscription helper
  RealtimeChannel subscribe(
      String table, {
        String? filter,
        void Function(Map<String, dynamic>)? onInsert,
        void Function(Map<String, dynamic>)? onUpdate,
        void Function(Map<String, dynamic>)? onDelete,
      }) {
    final channel = client.channel('public:$table');

    if (onInsert != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        filter: filter != null
            ? PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: filter.split('=')[0],
          value: filter.split('=')[1],
        )
            : null,
        callback: (payload) => onInsert(payload.newRecord),
      );
    }

    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        filter: filter != null
            ? PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: filter.split('=')[0],
          value: filter.split('=')[1],
        )
            : null,
        callback: (payload) => onUpdate(payload.newRecord),
      );
    }

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        filter: filter != null
            ? PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: filter.split('=')[0],
          value: filter.split('=')[1],
        )
            : null,
        callback: (payload) => onDelete(payload.oldRecord),
      );
    }

    channel.subscribe();
    return channel;
  }
}
