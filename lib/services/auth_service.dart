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
    String? emailRedirectTo,
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
        emailRedirectTo: emailRedirectTo,
      );

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
  Future<void> resetPassword({
    required String email,
    required String redirectTo,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  /// Reenvia o e-mail de confirmação (método padrão Supabase)
  Future<void> resendConfirmationEmail({
    required String email,
    required String emailRedirectTo,
  }) async {
    try {
      // Usamos o 'resend' padrão do Supabase.
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: emailRedirectTo,
      );
    } catch (error) {
      throw Exception('Failed to resend confirmation email: $error');
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

  Future<void> deleteUserAccount() async {
    final response = await Supabase.instance.client.functions.invoke('delete-user-account');

    if (response.status != 200) {
      throw Exception('Erro ao excluir a conta: ${response.data['error']}');
    }

    await signOut();
  }

  // --- Funções de getter (mantidas como estavam) ---

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

  // <<< INÍCIO DA ADIÇÃO: Login com Provedores OAuth >>>

  /// Sign in with Apple (OAuth)
  Future<void> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        // Não precisamos de 'redirectTo' aqui, pois o
        // 'bldr://' já foi configurado no Supabase, no Xcode
        // e no AndroidManifest. O Supabase usará o padrão.
      );
    } catch (error) {
      throw Exception('Apple Sign-In failed: $error');
    }
  }

  /// Sign in with Google (OAuth)
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    } catch (error) {
      throw Exception('Google Sign-In failed: $error');
    }
  }

// <<< FIM DA ADIÇÃO >>>
}