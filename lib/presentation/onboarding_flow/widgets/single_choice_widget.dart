import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SingleChoiceWidget extends StatelessWidget {
  final List<String> options;
  final String? selectedOption;
  final Function(String) onOptionSelected;

  const SingleChoiceWidget({
    Key? key,
    required this.options,
    this.selectedOption,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedOption == option;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onOptionSelected(option);
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentGold.withValues(alpha: 0.1)
                  : AppTheme.cardDark,
              border: Border.all(
                color: isSelected ? AppTheme.accentGold : AppTheme.dividerGray,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentGold
                          : AppTheme.dividerGray,
                      width: 2,
                    ),
                    color:
                        isSelected ? AppTheme.accentGold : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 2.5.w,
                            height: 2.5.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    option,
                    style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? AppTheme.accentGold
                          : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
