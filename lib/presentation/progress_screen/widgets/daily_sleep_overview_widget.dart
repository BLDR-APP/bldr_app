import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DailySleepOverviewWidget extends StatelessWidget {
  final DateTime selectedDate;
  final int totalSleepMin;
  final int? score;
  final int? restingHr;
  final int? hrv;

  const DailySleepOverviewWidget({
    Key? key,
    required this.selectedDate,
    required this.totalSleepMin,
    this.score,
    this.restingHr,
    this.hrv,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 3.h),
          _buildSleepMetrics(),
          SizedBox(height: 2.h),
          _buildHealthMetrics(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomIconWidget(
            iconName: 'bedtime',
            color: AppTheme.accentGold,
            size: 6.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sono',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDate(selectedDate),
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (score != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _getScoreColor(score!).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$score',
              style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                color: _getScoreColor(score!),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSleepMetrics() {
    final hours = totalSleepMin ~/ 60;
    final minutes = totalSleepMin % 60;
    final sleepText = totalSleepMin > 0 ? '${hours}h ${minutes}min' : '--';

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Duração Total',
            sleepText,
            AppTheme.accentGold,
            'sleep',
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildMetricCard(
            'Qualidade',
            score != null ? _getScoreLabel(score!) : '--',
            _getScoreColor(score ?? 0),
            'star',
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'FC Repouso',
            restingHr != null ? '${restingHr} bpm' : '--',
            AppTheme.errorRed,
            'favorite',
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildMetricCard(
            'HRV',
            hrv != null ? '${hrv} ms' : '--',
            AppTheme.successGreen,
            'timeline',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, Color color, String iconName) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hoje';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Ontem';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return AppTheme.successGreen;
    if (score >= 70) return AppTheme.accentGold;
    if (score >= 55) return Colors.orange;
    return AppTheme.errorRed;
  }

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Excelente';
    if (score >= 70) return 'Bom';
    if (score >= 55) return 'Regular';
    return 'Ruim';
  }
}
