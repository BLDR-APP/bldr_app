// firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// CORREÇÃO 1: Prefixo 'sb' para evitar conflito com User
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
// Importado apenas para o ID do usuário
import './auth_service.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instanceFor(
      app: Firebase.app('alimentosDB')
  );

  // Usa o prefixo 'sb'
  final sb.SupabaseClient _supabaseClient = sb.Supabase.instance.client;

  static const String functionName = 'generateFirebaseToken';

  // >>> CORREÇÃO APLICADA AQUI: O retorno agora é Future<String?> <<<
  Future<String?> getFirebaseCustomToken() async {
    // Usa o prefixo 'sb' para o User do Supabase
    final supabaseUser = _supabaseClient.auth.currentUser;

    if (supabaseUser == null) {
      throw Exception('Usuário Supabase não autenticado. Impossível gerar token Firebase.');
    }

    // CORREÇÃO: Usa a propriedade currentSession, não o método session().
    final jwt = _supabaseClient.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw Exception('Falha ao obter JWT do Supabase. Sessão expirada ou não encontrada.');
    }

    // Opcional: currentFirebaseUser (tipo User do Firebase Auth)
    // 1. Lógica de Cache (Retorna null se já logado)
    if (_firebaseAuth.currentUser?.uid == supabaseUser.id) {
      print("Aviso: Usuário já autenticado no Firebase com UID do Supabase.");
      return null; // CORRIGIDO: Retorna null de um Future<String?>
    }

    try {
      final response = await _supabaseClient.functions.invoke(
        functionName,
        headers: {'Authorization': 'Bearer $jwt'},
        body: {'supabase_uid': supabaseUser.id},
      );

      final firebaseToken = response.data['firebaseToken'] as String?;

      if (firebaseToken == null) {
        throw Exception('Função de backend não retornou o token do Firebase.');
      }

      // Retorna o token, a tela principal faz o login (signInWithCustomToken)
      return firebaseToken;

    } catch (e) {
      print('Erro ao obter token do Firebase via Edge Function: $e');
      rethrow;
    }
  }

  // Novo método dedicado para fazer o login no Firebase
  Future<void> signInWithCustomToken(String token) async {
    try {
      await _firebaseAuth.signInWithCustomToken(token);
      print("Sucesso! Usuário Supabase logado no Firebase Auth.");
    } catch (e) {
      print('Erro no Firebase Auth ao usar Custom Token: $e');
      rethrow;
    }
  }


  // O tipo de retorno User é do Firebase Auth (sem prefixo)
  User? get currentFirebaseUser => _firebaseAuth.currentUser;
}