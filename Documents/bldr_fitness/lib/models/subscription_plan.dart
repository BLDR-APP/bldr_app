class SubscriptionPlan {
  final String id;
  final String name;
  final String planType;
  final double monthlyPrice;
  final double annualPrice;
  final String monthlyPriceText;
  final String annualPriceText;
  final String description;
  final List<String> features;
  final bool isPopular;
  final String? stripeMonthlyPriceId;
  final String? stripeAnnualPriceId;
  final int trialPeriodDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.monthlyPriceText,
    required this.annualPriceText,
    required this.description,
    required this.features,
    required this.isPopular,
    this.stripeMonthlyPriceId,
    this.stripeAnnualPriceId,
    this.trialPeriodDays = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      planType: json['plan_type'],
      monthlyPrice: double.parse(json['monthly_price'].toString()),
      annualPrice: double.parse(json['annual_price'].toString()),
      monthlyPriceText: json['monthly_price_text'],
      annualPriceText: json['annual_price_text'],
      description: json['description'],
      features: List<String>.from(json['features']),
      isPopular: json['is_popular'] ?? false,
      stripeMonthlyPriceId: json['stripe_monthly_price_id'],
      stripeAnnualPriceId: json['stripe_annual_price_id'],
      trialPeriodDays: json['trial_period_days'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plan_type': planType,
      'monthly_price': monthlyPrice,
      'annual_price': annualPrice,
      'monthly_price_text': monthlyPriceText,
      'annual_price_text': annualPriceText,
      'description': description,
      'features': features,
      'is_popular': isPopular,
      'stripe_monthly_price_id': stripeMonthlyPriceId,
      'stripe_annual_price_id': stripeAnnualPriceId,
      'trial_period_days': trialPeriodDays,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final String status;
  final String billingPeriod;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final DateTime? canceledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    required this.status,
    required this.billingPeriod,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEnd,
    this.canceledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['user_id'],
      planId: json['plan_id'],
      stripeSubscriptionId: json['stripe_subscription_id'],
      stripeCustomerId: json['stripe_customer_id'],
      status: json['status'],
      billingPeriod: json['billing_period'],
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'])
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
      trialEnd:
      json['trial_end'] != null ? DateTime.parse(json['trial_end']) : null,
      canceledAt: json['canceled_at'] != null
          ? DateTime.parse(json['canceled_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'stripe_subscription_id': stripeSubscriptionId,
      'stripe_customer_id': stripeCustomerId,
      'status': status,
      'billing_period': billingPeriod,
      'current_period_start': currentPeriodStart?.toIso8601String(),
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'trial_end': trialEnd?.toIso8601String(),
      'canceled_at': canceledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PaymentIntentData {
  final String id;
  final String userId;
  final String? subscriptionId;
  final String stripePaymentIntentId;
  final double amount;
  final String currency;
  final String status;
  final String planType;
  final String billingPeriod;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentIntentData({
    required this.id,
    required this.userId,
    this.subscriptionId,
    required this.stripePaymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.planType,
    required this.billingPeriod,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentIntentData.fromJson(Map<String, dynamic> json) {
    return PaymentIntentData(
      id: json['id'],
      userId: json['user_id'],
      subscriptionId: json['subscription_id'],
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      status: json['status'],
      planType: json['plan_type'],
      billingPeriod: json['billing_period'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subscription_id': subscriptionId,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'plan_type': planType,
      'billing_period': billingPeriod,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}