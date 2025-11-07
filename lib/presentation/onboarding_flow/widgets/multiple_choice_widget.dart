import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MultipleChoiceWidget extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onOptionsChanged;

  const MultipleChoiceWidget({
    Key? key,
    required this.options,
    required this.selectedOptions,
    required this.onOptionsChanged,
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
        final isSelected = selectedOptions.contains(option);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            List<String> newSelection = List.from(selectedOptions);
            if (isSelected) {
              newSelection.remove(option);
            } else {
              newSelection.add(option);
            }
            onOptionsChanged(newSelection);
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
                    borderRadius: BorderRadius.circular(4),
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
                      ? CustomIconWidget(
                          iconName: 'check',
                          color: AppTheme.primaryBlack,
                          size: 4.w,
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
