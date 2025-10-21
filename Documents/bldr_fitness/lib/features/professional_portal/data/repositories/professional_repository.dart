// lib/features/professional_portal/data/repositories/professional_repository.dart

import 'dart:io'; // Necessário para o File
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p; // Para pegar a extensão do arquivo

class ProfessionalRepository {
  final _supabase = Supabase.instance.client;

  // ... (Todos os seus outros métodos, 'registerNewProfessional', 'isProfessionalUser', 'addClientByEmail', 'getMyProfessionalRole', 'getDietPlans', 'uploadDietPlan', 'getWorkoutPlans', 'createWorkoutPlan', 'getWorkoutPlanExercises', 'addExerciseToPlan' continuam aqui em cima, INTACTOS) ...
  Future<void> registerNewProfessional({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String professionalId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'register-professional',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
          'professionalId': professionalId,
        },
      );
      if (response.status != 200) {
        final errorMessage =
            response.data['error'] ?? 'Ocorreu um erro desconhecido.';
        throw Exception(errorMessage);
      }
      return;
    } on FunctionException catch (e) {
      print('FunctionException: ${e.details}');
      throw Exception('Erro de comunicação com o servidor.');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isProfessionalUser({required String userId}) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('professional_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Erro ao verificar perfil profissional: $e');
      return false;
    }
  }

  Future<String> addClientByEmail(String clientEmail) async {
    try {
      final response = await _supabase.functions.invoke(
        'link-professional-client', // Nome da nova Edge Function
        body: {'clientEmail': clientEmail},
      );

      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Erro desconhecido.');
      }
      return response.data['message']; // Retorna a mensagem de sucesso
    } catch (e) {
      // Relança o erro para a UI poder tratá-lo
      rethrow;
    }
  }

  // --- INÍCIO DA MUDANÇA (SEGUINDO SUA IDEIA) ---

  /// Busca APENAS OS IDs dos clientes do profissional.
  Future<List<String>> getMyClientsIds() async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Consulta simples que FUNCIONA
      final response = await _supabase
          .schema('bldr_club')
          .from('professional_clients')
          .select('client_user_id')
          .eq('professional_user_id', _supabase.auth.currentUser!.id);

      // Converte a resposta para uma lista de Strings (IDs)
      final clientList = (response as List).map((item) {
        return item['client_user_id'] as String;
      }).toList();

      return clientList;
    } catch (e) {
      print('Erro ao buscar IDs de clientes: $e');
      throw Exception('Não foi possível carregar seus clientes.');
    }
  }

  /// Busca os dados de um perfil de cliente específico pelo ID.
  Future<Map<String, dynamic>> getClientProfileById(String clientId) async {
    try {
      // Esta consulta será permitida pela nossa RLS na tabela 'profiles'
      final response = await _supabase
          .from('profiles')
          .select('id, full_name') // Mudamos 'id' aqui para 'user_id' se sua FK aponta para user_id
          .eq('id', clientId) // ou .eq('user_id', clientId)
          .single();

      return response;
    } catch (e) {
      print('Erro ao buscar perfil do cliente $clientId: $e');
      throw Exception('Não foi possível carregar dados do cliente.');
    }
  }

  // --- FIM DA MUDANÇA ---


  /// Busca o 'role' (cargo) do profissional logado.
  Future<String> getMyProfessionalRole() async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Busca na tabela de perfis profissionais pelo 'role'
      final response = await _supabase
          .schema('bldr_club')
          .from('professional_profiles')
          .select('role') // Pede apenas a coluna 'role'
          .eq('user_id', _supabase.auth.currentUser!.id)
          .single(); // .single() garante que esperamos exatamente 1 linha (ou dá erro)

      final role = response['role'] as String?;

      if (role == null || (role != 'personal' && role != 'nutritionist')) {
        throw Exception('Tipo de profissional inválido ou não encontrado.');
      }

      return role; // Retorna 'personal' ou 'nutritionist'

    } catch (e) {
      print('Erro ao buscar o cargo do profissional: $e');
      throw Exception('Não foi possível identificar seu perfil profissional.');
    }
  }

  // --- NOVAS FUNÇÕES DE DIETA ---
  // ... (getDietPlans e uploadDietPlan continuam aqui, INTACTAS) ...
  Future<List<Map<String, dynamic>>> getDietPlans(String clientId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('diet_plans')
          .select('id, plan_title, file_path, created_at')
          .eq('client_user_id', clientId)
          .order('created_at', ascending: false); // Mostra os mais recentes primeiro

      return (response as List).map((item) => item as Map<String, dynamic>).toList();

    } catch (e) {
      print('Erro ao buscar planos de dieta: $e');
      throw Exception('Não foi possível carregar as dietas do cliente.');
    }
  }
  Future<void> uploadDietPlan({
    required File file,
    required String planTitle,
    required String clientId,
  }) async {
    try {
      final professionalId = _supabase.auth.currentUser!.id;
      final fileExtension = p.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = '$professionalId/$clientId/$fileName';
      await _supabase.storage
          .from('diet_plans')
          .upload(filePath, file);
      final fileUrl = _supabase.storage
          .from('diet_plans')
          .getPublicUrl(filePath);
      await _supabase
          .schema('bldr_club')
          .from('diet_plans')
          .insert({
        'professional_user_id': professionalId,
        'client_user_id': clientId,
        'plan_title': planTitle,
        'file_path': fileUrl,
      });
    } catch (e) {
      print('Erro no upload da dieta: $e');
      throw Exception('Falha ao enviar o plano de dieta.');
    }
  }

  // --- NOVAS FUNÇÕES DE TREINO (PERSONAL) ---
  // ... (getWorkoutPlans, createWorkoutPlan, getWorkoutPlanExercises, addExerciseToPlan continuam aqui, INTACTAS) ...
  Future<List<Map<String, dynamic>>> getWorkoutPlans(String clientId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('workout_plans')
          .select('id, plan_name, created_at')
          .eq('client_user_id', clientId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();

    } catch (e) {
      print('Erro ao buscar planos de treino: $e');
      throw Exception('Não foi possível carregar os planos de treino.');
    }
  }
  Future<Map<String, dynamic>> createWorkoutPlan({
    required String planName,
    required String clientId,
  }) async {
    try {
      final professionalId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .schema('bldr_club')
          .from('workout_plans')
          .insert({
        'professional_user_id': professionalId,
        'client_user_id': clientId,
        'plan_name': planName,
      })
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao criar plano de treino: $e');
      throw Exception('Falha ao criar o plano de treino.');
    }
  }
  Future<List<Map<String, dynamic>>> getWorkoutPlanExercises(int planId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('workout_plan_exercises')
          .select('*')
          .eq('workout_plan_id', planId)
          .order('exercise_order', ascending: true);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Erro ao buscar exercícios: $e');
      throw Exception('Não foi possível carregar os exercícios.');
    }
  }
  Future<void> addExerciseToPlan({
    required int planId,
    required String name,
    required String sets,
    required String reps,
    required String rest,
    required String notes,
    required int order,
  }) async {
    try {
      await _supabase
          .schema('bldr_club')
          .from('workout_plan_exercises')
          .insert({
        'workout_plan_id': planId,
        'exercise_name': name,
        'sets': sets,
        'reps': reps,
        'rest_period': rest,
        'notes': notes,
        'exercise_order': order,
      });
    } catch (e) {
      print('Erro ao adicionar exercício: $e');
      throw Exception('Falha ao adicionar o exercício.');
    }
  }
}