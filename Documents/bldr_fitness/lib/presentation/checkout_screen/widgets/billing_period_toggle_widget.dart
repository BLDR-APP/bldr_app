import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BillingPeriodToggleWidget extends StatelessWidget {
  final bool isAnnual;
  final ValueChanged<bool> onToggle;

  const BillingPeriodToggleWidget({
    super.key,
    required this.isAnnual,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              context,
              'Mensal',
              !isAnnual,
              () => onToggle(false),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              context,
              'Anual',
              isAnnual,
              () => onToggle(true),
              badge: 'ECONOMIZE',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String title,
    bool isSelected,
    VoidCallback onTap, {
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentGold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.textVariant
                          : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
              if (badge != null && !isSelected) ...[
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
