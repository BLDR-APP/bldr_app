import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Current user getter
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final Map<String, dynamic> metadata = {
        'full_name': fullName,
        ...?additionalData,
      };

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
        emailRedirectTo: null, // Will be handled by our custom flow
      );

      // If user was created, generate confirmation token
      if (response.user != null) {
        await _generateConfirmationToken(email);
      }

      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  /// Update user password
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response;
    } catch (error) {
      throw Exception('Password update failed: $error');
    }
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );

      return response;
    } catch (error) {
      throw Exception('User metadata update failed: $error');
    }
  }

  /// Check if current user needs email confirmation
  Future<bool> needsEmailConfirmation() async {
    if (!isAuthenticated) return false;

    try {
      final response = await _client
          .from('user_profiles')
          .select('email_confirmed')
          .eq('id', currentUser!.id)
          .single();

      return !(response['email_confirmed'] as bool? ?? false);
    } catch (error) {
      return false;
    }
  }

  /// Generate confirmation token (internal)
  Future<String?> _generateConfirmationToken(String email) async {
    try {
      final response = await _client
          .rpc('generate_confirmation_token', params: {'user_email': email});
      return response as String?;
    } catch (error) {
      print('Error generating confirmation token: $error');
      return null;
    }
  }

  /// Confirm email with token
  Future<bool> confirmEmail({required String token}) async {
    try {
      final response =
      await _client.rpc('confirm_user_email', params: {'token': token});
      return response as bool? ?? false;
    } catch (error) {
      throw Exception('Email confirmation failed: $error');
    }
  }

  /// Resend confirmation email
  Future<bool> resendConfirmationEmail({required String email}) async {
    try {
      final response = await _client
          .rpc('resend_confirmation_email', params: {'user_email': email});
      return response as bool? ?? false;
    } catch (error) {
      throw Exception('Failed to resend confirmation email: $error');
    }
  }

  /// Get email confirmation status
  Future<Map<String, dynamic>?> getEmailConfirmationStatus() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select('email_confirmed, email_confirmed_at, confirmation_sent_at')
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (error) {
      return null;
    }
  }

  Future<void> deleteUserAccount() async {
    final response = await Supabase.instance.client.functions.invoke('delete-user-account');

    if (response.status != 200) {
      throw Exception('Erro ao excluir a conta: ${response.data['error']}');
    }

    // Se a exclusão for bem-sucedida, o JWT do usuário se torna inválido.
    // O Supabase client geralmente lida com isso, mas podemos forçar um signOut local.
    await signOut();
  }

  // --- CORREÇÃO: ESTAS FUNÇÕES ESTAVAM FORA DA CLASSE ---

  /// Get current user ID
  String? getCurrentUserId() {
    return currentUser?.id;
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return currentUser?.email;
  }

  /// Get current user metadata
  Map<String, dynamic>? getCurrentUserMetadata() {
    return currentUser?.userMetadata;
  }
}