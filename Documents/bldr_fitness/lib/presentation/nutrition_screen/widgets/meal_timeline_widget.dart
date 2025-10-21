import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MealTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final Function(String) onAddMeal;
  final Function(Map<String, dynamic>) onEditMeal;

  const MealTimelineWidget({
    Key? key,
    required this.meals,
    required this.onAddMeal,
    required this.onEditMeal,
  }) : super(key: key);

  // ====================================================================
  // <<< ADIÇÃO 1: Função para "traduzir" o nome da refeição >>>
  // ====================================================================
  String _getDatabaseKey(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'café da manhã':
        return 'breakfast';
      case 'almoço':
        return 'lunch';
      case 'jantar':
        return 'dinner';
      case 'lanche':
        return 'snack';
      default:
        return mealType; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealTypes = ['café da manhã', 'almoço', 'jantar', 'lanche'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refeições',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...mealTypes.map((mealType) {
          // ====================================================================
          // <<< ALTERAÇÃO 2: Usa a função de "tradução" na filtragem >>>
          // ====================================================================
          final dbKey = _getDatabaseKey(mealType);
          final mealsOfType =
          meals.where((meal) => meal['meal_type'] == dbKey).toList();
          return _buildMealSection(mealType, mealsOfType);
        }).toList(),
      ],
    );
  }

  Widget _buildMealSection(
      String mealType, List<Map<String, dynamic>> mealsOfType) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: _getMealIcon(mealType),
                color: _getMealColor(mealType),
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                _formatMealType(mealType),
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              if (mealsOfType.isNotEmpty)
                Text(
                  '${_calculateTotalCalories(mealsOfType)} cal',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: _getMealColor(mealType),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (mealsOfType.isEmpty) ...[
            SizedBox(height: 2.h),
            GestureDetector(
              onTap: () => onAddMeal(mealType),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.dividerGray,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'add',
                      color: AppTheme.textSecondary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Adicionar ${_formatMealType(mealType)}',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 2.h),
            ...mealsOfType.map((meal) => _buildMealCard(meal)).toList(),
            SizedBox(height: 2.h),
            GestureDetector(
              onTap: () => onAddMeal(mealType),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentGold),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'add',
                      color: AppTheme.accentGold,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Adicionar Mais',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final foodItems = meal['meal_food_items'] as List? ?? [];
    final totalCalories = _calculateMealCalories(meal);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (meal['name'] != null)
                Text(
                  meal['name'],
                  style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Spacer(),
              Text(
                '$totalCalories cal',
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: () => onEditMeal(meal),
                child: CustomIconWidget(
                  iconName: 'edit',
                  color: AppTheme.textSecondary,
                  size: 4.w,
                ),
              ),
            ],
          ),
          if (foodItems.isNotEmpty) ...[
            SizedBox(height: 2.h),
            ...foodItems.map((foodItem) => _buildFoodItem(foodItem)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> foodItem) {
    final food = foodItem['food_items'] as Map<String, dynamic>? ?? {};
    final quantity = foodItem['quantity_grams']?.toInt() ?? 0;
    final calories = foodItem['calories']?.toInt() ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name'] ?? 'Unknown Food',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (food['brand'] != null)
                  Text(
                    food['brand'],
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${quantity}g',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${calories} cal',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMealIcon(String mealType) {
    switch (mealType) {
      case 'café da manhã':
        return 'wb_sunny';
      case 'almoço':
        return 'wb_sunny';
      case 'jantar':
        return 'nightlight';
      case 'lanche':
        return 'local_cafe';
      default:
        return 'restaurant';
    }
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'café da manhã':
        return AppTheme.warningAmber;
      case 'almoço':
        return AppTheme.successGreen;
      case 'jantar':
        return Colors.purple;
      case 'lanche':
        return Colors.blue;
      default:
        return AppTheme.accentGold;
    }
  }

  String _formatMealType(String mealType) {
    return mealType[0].toUpperCase() + mealType.substring(1);
  }

  int _calculateTotalCalories(List<Map<String, dynamic>> mealsOfType) {
    int total = 0;
    for (final meal in mealsOfType) {
      total += _calculateMealCalories(meal);
    }
    return total;
  }

  int _calculateMealCalories(Map<String, dynamic> meal) {
    final foodItems = meal['meal_food_items'] as List? ?? [];
    int total = 0;
    for (final foodItem in foodItems) {
      total += (foodItem['calories']?.toInt() ?? 0) as int;
    }
    return total;
  }
}