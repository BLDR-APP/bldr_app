import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// === REMOVIDA: Função de Recálculo _calculateNutritionPlanFromData ===
// A lógica agora lê diretamente os valores salvos.
// === FIM DA REMOÇÃO ===


class DailyNutritionOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> nutritionSummary;
  final DateTime selectedDate;
  // Recebe o mapa completo do perfil do usuário
  final Map<String, dynamic>? userProfileData;

  const DailyNutritionOverviewWidget({
    Key? key,
    required this.nutritionSummary,
    required this.selectedDate,
    required this.userProfileData, // Continua recebendo o perfil
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Valores Consumidos (do Nutrition Service) ---
    final int totalCalories = (nutritionSummary['total_calories'] as num?)?.round() ?? 0;
    final int totalProtein = (nutritionSummary['total_protein'] as num?)?.round() ?? 0;
    final int totalCarbs = (nutritionSummary['total_carbs'] as num?)?.round() ?? 0;
    final int totalFat = (nutritionSummary['total_fat'] as num?)?.round() ?? 0;

    // --- Metas (Lidas DIRETAMENTE do onboarding_data) ---
    final Map<String, dynamic>? onboardingData = userProfileData?['onboarding_data'] is Map
        ? userProfileData!['onboarding_data'] as Map<String, dynamic>
        : null; // Pega o mapa onboarding_data

    // Valores padrão caso onboarding_data ou as chaves não existam
    const int defaultCalorieTarget = 2000;
    const int defaultProteinTarget = 120;
    const int defaultCarbsTarget = 250;
    const int defaultFatTarget = 67;

    // Tenta ler as metas salvas, convertendo de forma segura e usando padrão se falhar
    final int calorieTarget = (onboardingData?['target_calories'] as num?)?.round() ?? defaultCalorieTarget;
    final int proteinTarget = (onboardingData?['target_protein'] as num?)?.round() ?? defaultProteinTarget;
    final int carbsTarget = (onboardingData?['target_carbs'] as num?)?.round() ?? defaultCarbsTarget;
    final int fatTarget = (onboardingData?['target_fat'] as num?)?.round() ?? defaultFatTarget;
    // final double hydrationTarget = (onboardingData?['target_hydration_liters'] as num?)?.toDouble() ?? 2.0; // Hidratação (se precisar)
    // final int calculatedTdee = (onboardingData?['calculated_tdee'] as num?)?.round() ?? 0; // TDEE (se precisar)

    // Log para depuração (opcional)
    // print("Metas lidas do onboarding_data: Cals=$calorieTarget, Prot=$proteinTarget, Carb=$carbsTarget, Fat=$fatTarget");

    // --- FIM DA LEITURA DE METAS ---


    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo Diário',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                // Passa a meta lida diretamente
                child: _buildCalorieProgress(totalCalories, calorieTarget),
              ),
              SizedBox(width: 4.w),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Passa as metas lidas diretamente
                    _buildMacroProgress('Proteína', totalProtein, proteinTarget, 'g', Colors.red.shade300),
                    SizedBox(height: 1.5.h),
                    _buildMacroProgress('Carboidrato', totalCarbs, carbsTarget, 'g', Colors.blue.shade300),
                    SizedBox(height: 1.5.h),
                    _buildMacroProgress('Gordura', totalFat, fatTarget, 'g', Colors.orange.shade300),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // As funções _buildCalorieProgress e _buildMacroProgress permanecem
  // idênticas à versão anterior, pois já recebiam os valores current/target.

  Widget _buildCalorieProgress(int current, int target) {
    final double progress = (target > 0) ? math.min(current / target, 1.0) : 0.0;
    final remaining = math.max(target - current, 0);

    return Column(
      children: [
        SizedBox(
          width: 25.w, height: 25.w,
          child: Stack(fit: StackFit.expand, children: [
            Center(child: SizedBox(width: 25.w, height: 25.w, child: CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: AppTheme.dividerGray))),
            Center(child: SizedBox(width: 25.w, height: 25.w, child: CircularProgressIndicator(value: progress, strokeWidth: 8, color: AppTheme.accentGold, strokeCap: StrokeCap.round))),
            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$current', style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
              Text('de $target', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            ])),
          ]),
        ),
        SizedBox(height: 1.5.h),
        Text('Calorias', style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        Text('$remaining restantes', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMacroProgress(String name, int current, int target, String unit, Color color) {
    final double progress = (target > 0) ? math.min(current / target, 1.0) : 0.0;
    Color quantityColor = AppTheme.textSecondary;
    if (target > 0 && current > target * 1.1) { quantityColor = Colors.red.shade300; }
    else if (target > 0 && current >= target) { quantityColor = color; }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(name, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          Text('$current / $target$unit', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: quantityColor, fontWeight: FontWeight.w600)),
        ]),
        SizedBox(height: 0.8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 0.8.h, backgroundColor: AppTheme.dividerGray, color: color, borderRadius: BorderRadius.circular(4)),
        ),
      ],
    );
  }
}