import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MealTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final Function(String) onAddMeal;
  final Function(Map<String, dynamic>) onEditMeal;
  // NOVO: Callback para a tela-mãe lidar com a deleção
  final Function(String) onDeleteFoodLog;

  const MealTimelineWidget({
    Key? key,
    required this.meals,
    required this.onAddMeal,
    required this.onEditMeal,
    // NOVO: O parâmetro é obrigatório
    required this.onDeleteFoodLog,
  }) : super(key: key);

  // ====================================================================
  // >>> NOVO MÉTODO: Abre o modal para escolher Editar ou Deletar <<<
  // ====================================================================
  void _showEditOrDeleteModal(BuildContext context, Map<String, dynamic> meal) {
    // ID do documento no Firebase que será deletado
    final foodLogId = meal['id'] as String?;
    if (foodLogId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID do item de comida não encontrado.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Opções para ${meal['food_name'] ?? 'este item'}',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary)),
        content: const Text('O que você deseja fazer com este item?'),
        backgroundColor: AppTheme.cardDark,
        contentTextStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        actions: [
          TextButton(
            child: Text('Editar Quantidade', style: TextStyle(color: AppTheme.accentGold)),
            onPressed: () {
              Navigator.pop(ctx);
              // Chama a função de edição (abrir modal de quantidade)
              onEditMeal(meal);
            },
          ),
          TextButton(
            child: const Text('Remover Item', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx); // Fecha o modal de opções
              // Chama o callback, que acionará o serviço de deleção na NutritionScreen
              onDeleteFoodLog(foodLogId);
            },
          ),
        ],
      ),
    );
  }
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
          final dbKey = _getDatabaseKey(mealType);
          final mealsOfType =
          meals.where((meal) => meal['meal_type'] == dbKey).toList();
          return _buildMealSection(context, mealType, mealsOfType);
        }).toList(),
      ],
    );
  }

  // Corrigindo a assinatura para receber o BuildContext
  Widget _buildMealSection(
      BuildContext context, String mealType, List<Map<String, dynamic>> mealsOfType) {
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
            // Passa o context para o buildMealCard
            ...mealsOfType.map((meal) => _buildMealCard(context, meal)).toList(),
            SizedBox(height: 2.h),
            GestureDetector(
              onTap: () => onAddMeal(mealType),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
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

  // CORRIGIDO: Assinatura para receber o BuildContext
  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    // Campos lidos diretamente do documento user_meals (plano)
    final totalCalories = (meal['calories'] as num?)?.toInt() ?? 0;
    final foodName = meal['food_name'] ?? 'Alimento sem nome';
    final quantity = (meal['quantity_grams'] as num?)?.toInt() ?? 0;
    final protein = (meal['protein'] as num?)?.toInt() ?? 0;
    final carbs = (meal['carbs'] as num?)?.toInt() ?? 0;
    final fat = (meal['fat'] as num?)?.toInt() ?? 0;

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
              // Exibe o nome do item de comida
              Expanded(
                child: Text(
                  foodName,
                  style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
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
                // NOVO: Chama o modal de opções ao invés de edição direta
                onTap: () {
                  _showEditOrDeleteModal(context, meal);
                },
                child: CustomIconWidget(
                  iconName: 'edit',
                  color: AppTheme.textSecondary,
                  size: 4.w,
                ),
              ),
            ],
          ),
          // Exibe os macros detalhados e a quantidade consumida
          SizedBox(height: 1.h),
          Text(
            '${quantity}g • P:${protein}g • C:${carbs}g • G:${fat}g',
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // >>> MÉTODO _buildFoodItem REMOVIDO/OBOSOLETO <<<

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

  // >>> MÉTODO CORRIGIDO: Soma o campo 'calories' do documento <<<
  int _calculateTotalCalories(List<Map<String, dynamic>> mealsOfType) {
    int total = 0;
    for (final meal in mealsOfType) {
      total += (meal['calories'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  // >>> MÉTODO CORRIGIDO: Retorna a caloria do campo agregado <<<
  int _calculateMealCalories(Map<String, dynamic> meal) {
    return (meal['calories'] as num?)?.toInt() ?? 0;
  }
}