import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onLogMealPressed;
  final VoidCallback onStartWorkoutPressed;
  final VoidCallback onViewProgressPressed;

  const QuickActionsWidget({
    Key? key,
    required this.onLogMealPressed,
    required this.onStartWorkoutPressed,
    required this.onViewProgressPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              'Ações Rápidas',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Adicionar Refeição',
                  icon: 'restaurant',
                  color: AppTheme.successGreen,
                  onPressed: onLogMealPressed,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Começar Treino',
                  icon: 'fitness_center',
                  color: AppTheme.accentGold,
                  onPressed: onStartWorkoutPressed,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Visualizar Progresso',
                  icon: 'trending_up',
                  color: AppTheme.warningAmber,
                  onPressed: onViewProgressPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.dividerGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowBlack,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: color,
                size: 6.w,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
