import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    Key? key,
    required this.password,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(password);
    final strengthText = _getStrengthText(strength);
    final strengthColor = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 0.5.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppTheme.dividerGray,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: strength / 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: strengthColor,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              strengthText,
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        if (password.isNotEmpty && strength < 3) ...[
          SizedBox(height: 1.h),
          Text(
            _getPasswordRequirements(),
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 9.sp,
            ),
          ),
        ],
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;

    // Contains uppercase
    if (password.contains(RegExp(r'[A-Z]'))) strength++;

    // Contains lowercase
    if (password.contains(RegExp(r'[a-z]'))) strength++;

    // Contains number
    if (password.contains(RegExp(r'[0-9]'))) strength++;

    // Contains special character
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength > 4 ? 4 : strength;
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Weak';
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppTheme.errorRed;
      case 2:
        return AppTheme.warningAmber;
      case 3:
        return AppTheme.accentGold;
      case 4:
        return AppTheme.successGreen;
      default:
        return AppTheme.errorRed;
    }
  }

  String _getPasswordRequirements() {
    return 'Password must contain: 8+ characters, uppercase, lowercase, number, special character';
  }
}
