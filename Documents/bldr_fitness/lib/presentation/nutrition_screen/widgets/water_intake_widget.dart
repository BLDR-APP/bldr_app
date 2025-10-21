import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/progress_service.dart';

class WaterIntakeWidget extends StatelessWidget {
  final double intake;
  final VoidCallback onIncrement;

  const WaterIntakeWidget({
    Key? key,
    required this.intake,
    required this.onIncrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ProgressService.instance.getDailyWaterIntake(
        date: DateTime.now(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        final waterData = snapshot.data;
        return _buildWaterIntakeCard(context, waterData);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: 'local_drink',
              color: Colors.blue,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hidratação',
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Carregando...',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeCard(
      BuildContext context, Map<String, dynamic>? waterData) {
    final totalAmountMl = waterData?['total_amount_ml'] ?? 0;
    final totalAmountLiters = waterData?['total_amount_liters'] ?? '0.0';
    final logCount = waterData?['log_count'] ?? 0;
    final targetMl = 2500; // 2.5L daily target
    final progress = (totalAmountMl / targetMl).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'local_drink',
                  color: Colors.blue,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hidratação',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${totalAmountLiters}L / 2.5L target',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.dividerGray,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 1.5.h,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildWaterStat('${totalAmountMl}ml', 'Total Hoje'),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildWaterStat('$logCount', 'Entradas'),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () => _showAddWaterDialog(context),
            icon: Icon(Icons.add, size: 5.w),
            label: Text('Adicionar Água'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterStat(String value, String label) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddWaterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final amounts = [250, 500, 750, 1000];
        return AlertDialog(
          backgroundColor: AppTheme.dialogDark,
          title: Text(
            'Adicionar',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: amounts.map((amount) {
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 2.h),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ProgressService.instance.logWaterIntake(
                        amountMl: amount,
                      );
                      Navigator.pop(context);
                      onIncrement(); // Trigger parent refresh
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Water intake logged: ${amount}ml'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to log water intake'),
                          backgroundColor: AppTheme.errorRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('${amount}ml'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
