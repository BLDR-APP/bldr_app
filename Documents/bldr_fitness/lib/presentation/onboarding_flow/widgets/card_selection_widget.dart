import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CardSelectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final List<String> selectedOptions;
  final Function(List<String>) onOptionsChanged;
  final bool multiSelect;

  const CardSelectionWidget({
    Key? key,
    required this.options,
    required this.selectedOptions,
    required this.onOptionsChanged,
    this.multiSelect = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.2,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final title = option['title'] as String;
        final icon = option['icon'] as String;
        final isSelected = selectedOptions.contains(title);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            List<String> newSelection = List.from(selectedOptions);

            if (multiSelect) {
              if (isSelected) {
                newSelection.remove(title);
              } else {
                newSelection.add(title);
              }
            } else {
              newSelection = isSelected ? [] : [title];
            }

            onOptionsChanged(newSelection);
          },
          child: Container(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: icon,
                  color:
                      isSelected ? AppTheme.accentGold : AppTheme.textSecondary,
                  size: 8.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color:
                        isSelected ? AppTheme.accentGold : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isSelected && multiSelect) ...[
                  SizedBox(height: 1.h),
                  Container(
                    width: 5.w,
                    height: 5.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentGold,
                    ),
                    child: CustomIconWidget(
                      iconName: 'check',
                      color: AppTheme.primaryBlack,
                      size: 3.w,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
