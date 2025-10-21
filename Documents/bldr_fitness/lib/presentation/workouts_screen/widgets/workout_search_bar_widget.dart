import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WorkoutSearchBarWidget extends StatelessWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onTypeFilter;
  final Function(int?) onDifficultyFilter;
  final String? selectedType;
  final int? selectedDifficulty;

  const WorkoutSearchBarWidget({
    Key? key,
    required this.onSearchChanged,
    required this.onTypeFilter,
    required this.onDifficultyFilter,
    this.selectedType,
    this.selectedDifficulty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerGray),
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar treinos...',
              hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              prefixIcon: CustomIconWidget(
                iconName: 'search',
                color: AppTheme.textSecondary,
                size: 5.w,
              ),
              suffixIcon: CustomIconWidget(
                iconName: 'mic',
                color: AppTheme.textSecondary,
                size: 5.w,
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Todos',
                selectedType == null,
                () => onTypeFilter(null),
              ),
              SizedBox(width: 2.w),
              _buildFilterChip(
                'Força',
                selectedType == 'strength',
                () => onTypeFilter('strength'),
              ),
            // SizedBox(width: 2.w),
            // _buildFilterChip(
            //   'Cardio',
            //   selectedType == 'cardio',
            //   () => onTypeFilter('cardio'),
            // ),
            // SizedBox(width: 2.w),
            // _buildFilterChip(
            //   'Flexibilidade',
            //   selectedType == 'flexibility',
            //   () => onTypeFilter('flexibility'),
            // ),
              SizedBox(width: 2.w),
              _buildFilterChip(
                'HIIT',
                selectedType == 'sports',
                () => onTypeFilter('sports'),
              ),
              SizedBox(width: 2.w),
              _buildDifficultyFilter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGold : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentGold : AppTheme.dividerGray,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return PopupMenuButton<int?>(
      onSelected: onDifficultyFilter,
      color: AppTheme.cardDark,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: selectedDifficulty != null
              ? AppTheme.accentGold
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedDifficulty != null
                ? AppTheme.accentGold
                : AppTheme.dividerGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedDifficulty != null
                  ? 'Nível $selectedDifficulty'
                  : 'Dificuldade',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: selectedDifficulty != null
                    ? AppTheme.primaryBlack
                    : AppTheme.textPrimary,
                fontWeight: selectedDifficulty != null
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
            SizedBox(width: 1.w),
            CustomIconWidget(
              iconName: 'arrow_drop_down',
              color: selectedDifficulty != null
                  ? AppTheme.primaryBlack
                  : AppTheme.textSecondary,
              size: 4.w,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<int?>(
          value: null,
          child:
              Text('Todos os níveis', style: TextStyle(color: AppTheme.textPrimary)),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Text('Nível 1 - Iniciante',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Text('Nível 2 - Intermediário',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Text('Nível 3 - Avançado',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
        PopupMenuItem<int>(
          value: 4,
          child: Text('Nível 4 - Experiente',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}
