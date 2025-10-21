import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SummaryWidget extends StatelessWidget {
  final Map<String, dynamic> responses;
  final Function(String) onEdit;

  const SummaryWidget({
    Key? key,
    required this.responses,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revise suas Escolhas',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          ...responses.entries
              .map((entry) => _buildSummaryItem(entry.key, entry.value)),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.accentGold,
                  size: 8.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Perfeito! Usaremos essas informações para criar a sua experiência fitness personalizada!',
                  textAlign: TextAlign.center,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String key, dynamic value) {
    String displayValue = '';
    if (value is List) {
      displayValue = (value).join(', ');
    } else {
      displayValue = value.toString();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatKey(key),
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => onEdit(key),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Editar',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            displayValue,
            style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
