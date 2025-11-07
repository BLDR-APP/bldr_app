import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../services/supabase_service.dart';
import '../models/subscription_plan.dart';

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  PaymentService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1/create-subscription';

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('plan_type', ascending: true);

      return response
          .map<SubscriptionPlan>((json) => SubscriptionPlan.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

  Future<PaymentIntentResponse> createSubscription({
    required String planId,
    required String billingPeriod,
    String? couponCode,
  }) async {
    print('FLUTTER (PaymentService): Método createSubscription chamado com couponCode: $couponCode');
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please login and try again.');
      }

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session found. Please login again.');
      }

      final response = await _dio.post(
        _baseUrl,
        data: {
          'plan_id': planId,
          'billing_period': billingPeriod,
          'coupon_code': couponCode,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return PaymentIntentResponse.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to create subscription: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';

      if (e.response?.data != null) {
        errorMessage = 'Payment error: ${e.response?.data['error'] ?? 'Unknown server error'}';
      } else if (e.message?.contains('SocketException') == true) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentResult> processPayment({
    required String clientSecret,
    required BillingDetails billingDetails,
  }) async {
    try {
      if (Stripe.publishableKey.isEmpty) {
        throw Exception('Payment service not properly initialized');
      }

      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        return PaymentResult(
          success: true,
          message: 'Payment completed successfully',
          paymentIntentId: paymentIntent.id,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Payment was not completed. Status: ${paymentIntent.status}',
        );
      }
    } on StripeException catch (e) {
      return PaymentResult(
        success: false,
        message: _getStripeErrorMessage(e),
        errorCode: e.error.code.name,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }

  String _getStripeErrorMessage(StripeException e) {
    switch (e.error.code) {
      case FailureCode.Canceled:
        return 'Payment was cancelled';
      case FailureCode.Failed:
        return 'Payment failed. Please try again.';
      case FailureCode.Timeout:
        return 'Payment timed out. Please try again.';
      default:
        return e.error.localizedMessage ?? 'Payment failed. Please try again.';
    }
  }

  Future<UserSubscription?> getCurrentUserSubscription() async {
    final client = SupabaseService.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      print("DEBUG: getCurrentUserSubscription chamado, mas o usuário não está logado.");
      return null;
    }

    // --- ESTE É O PRINT MAIS IMPORTANTE DE TODOS ---
    print("DEBUG: ID do usuário LOGADO NO APP: ${user.id}");
    // --- FIM DO PRINT ---

    print("DEBUG: Buscando na tabela 'user_subscriptions' por user_id = ${user.id} E status = 'active'");

    try {
      final response = await client
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      print("DEBUG: Resposta da busca no banco de dados: $response");

      if (response == null) {
        print("DEBUG: Nenhuma assinatura ativa foi encontrada para este usuário.");
        return null;
      }

      print("DEBUG: Assinatura encontrada, retornando para a tela.");
      return UserSubscription.fromJson(response);

    } catch (e) {
      print("DEBUG: ERRO ao buscar assinatura: $e");
      return null;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) throw Exception('User not authenticated');

      await client
          .from('user_subscriptions')
          .update({
        'status': 'canceled',
        'canceled_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', user.id)
          .eq('status', 'active');

      return true;
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }
}

class PaymentIntentResponse {
  final String? clientSecret;
  final String? subscriptionId;

  PaymentIntentResponse({
    this.clientSecret,
    this.subscriptionId,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['client_secret'],
      subscriptionId: json['subscription_id'],
    );
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? errorCode;
  final String? paymentIntentId;

  PaymentResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.paymentIntentId,
  });
}