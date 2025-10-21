import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DailyNutritionOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> nutritionSummary;
  final DateTime selectedDate;

  const DailyNutritionOverviewWidget({
    Key? key,
    required this.nutritionSummary,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalCalories = nutritionSummary['total_calories'] ?? 0;
    final totalProtein = nutritionSummary['total_protein'] ?? 0;
    final totalCarbs = nutritionSummary['total_carbs'] ?? 0;
    final totalFat = nutritionSummary['total_fat'] ?? 0;

    // Mock target values - in real app these would come from user profile
    const calorieTarget = 2200;
    const proteinTarget = 150;
    const carbsTarget = 250;
    const fatTarget = 75;

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
                child: _buildCalorieProgress(totalCalories, calorieTarget),
              ),
              SizedBox(width: 4.w),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildMacroProgress('Proteina', totalProtein, proteinTarget,
                        'g', AppTheme.errorRed),
                    SizedBox(height: 2.h),
                    _buildMacroProgress('Carboidrato', totalCarbs, carbsTarget, 'g',
                        AppTheme.warningAmber),
                    SizedBox(height: 2.h),
                    _buildMacroProgress(
                        'Gordura', totalFat, fatTarget, 'g', AppTheme.successGreen),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieProgress(int current, int target) {
    final progress = math.min(current / target, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 25.w,
          height: 25.w,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 25.w,
                  height: 25.w,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.dividerGray,
                    color: AppTheme.accentGold,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$current',
                      style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      'de $target',
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Calorias',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${target - current} restantes',
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroProgress(
      String name, int current, int target, String unit, Color color) {
    final progress = math.min(current / target, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$current / $target$unit',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          height: 1.h,
          decoration: BoxDecoration(
            color: AppTheme.dividerGray,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
