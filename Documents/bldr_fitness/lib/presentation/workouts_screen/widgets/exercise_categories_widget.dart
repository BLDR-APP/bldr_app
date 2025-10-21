import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExerciseCategoriesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> exercises;
  final Function(String) onCategoryTap;

  const ExerciseCategoriesWidget({
    Key? key,
    required this.exercises,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = _getExerciseCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biblioteca de Exercícios',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // 👉 Centralizado: usando Wrap com alignment center
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 3.w,
          runSpacing: 2.h,
          children: categories.map(_buildCategoryCard).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => onCategoryTap(category['type']),
      child: SizedBox(
        width: 38.w,              // largura fixa pra alinhar bonito
        height: 18.h,             // altura consistente com o print
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerGray),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,   // centraliza vertical
            crossAxisAlignment: CrossAxisAlignment.center, // centraliza horizontal
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: category['icon'],
                  color: category['color'],
                  size: 8.w,
                ),
              ),
              SizedBox(height: 1.6.h),
              Text(
                category['name'],
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.4.h),
              Text(
                '${category['count']} exercícios',
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getExerciseCategories() {
    int strengthCount = 0;
    int hiitCount = 0;
    int flexibilityCount = 0;

    for (final exercise in exercises) {
      final type = (exercise['exercise_type'] ?? '').toString().toLowerCase();
      if (type == 'compound' || type == 'strength') {
        strengthCount++;
      } else if (type == 'cardio' || type == 'plyometric' || type == 'hiit') {
        hiitCount++;
      } else if (type == 'stretching' || type == 'flexibility') {
        flexibilityCount++;
      }
    }

    return [
      {
        'name': 'Força',
        'type': 'strength',
        'icon': 'fitness_center',
        'color': AppTheme.accentGold,
        'count': strengthCount,
      },
      {
        'name': 'HIIT',
        'type': 'HIIT',
        'icon': 'flash_on',
        'color': AppTheme.warningAmber,
        'count': hiitCount,
      },
      // Caso queira reativar Mobilidade, o Wrap já está pronto pra acomodar 3+ itens.
      // {
      //   'name': 'Mobilidade',
      //   'type': 'flexibility',
      //   'icon': 'accessibility',
      //   'color': AppTheme.successGreen,
      //   'count': flexibilityCount,
      // },
    ];
  }
}
