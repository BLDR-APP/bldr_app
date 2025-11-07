import 'package:flutter/material.dart';
import '../../../models/subscription_plan.dart';
import '../../../theme/app_theme.dart';

class PlanCardWidget extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isAnnual;
  final bool isSelected;
  final VoidCallback onTap;

  const PlanCardWidget({
    super.key,
    required this.plan,
    required this.isAnnual,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = isAnnual ? plan.annualPriceText : plan.monthlyPriceText;
    final annualSavings =
    isAnnual ? (plan.monthlyPrice * 12) - plan.annualPrice : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.accentGold : AppTheme.dividerGray,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppTheme.accentGold.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (plan.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'POPULAR',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.textVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isAnnual && annualSavings > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Economize R\$${annualSavings.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (plan.trialPeriodDays > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successGreen.withAlpha(77)),
                    ),
                    child: Text(
                      '${plan.trialPeriodDays} DIAS DE TESTE GRÁTIS INCLUÍDOS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(
                  plan.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plan.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentGold,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: AppTheme.textVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}