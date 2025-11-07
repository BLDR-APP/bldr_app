// lib/presentation/bldr_club/widgets/club_workout_search_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubWorkoutSearchBarWidget extends StatelessWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onTypeFilter;     // 'Força' | 'HIIT' | null
  final Function(int?) onDifficultyFilter;  // 1..4 | null
  final String? selectedType;               // aceita 'Força'/'HIIT' ou legado
  final int? selectedDifficulty;

  const ClubWorkoutSearchBarWidget({
    Key? key,
    required this.onSearchChanged,
    required this.onTypeFilter,
    required this.onDifficultyFilter,
    this.selectedType,
    this.selectedDifficulty,
  }) : super(key: key);

  // normalização para destacar chips mesmo com valores legados
  String? get _normalizedType {
    final t = (selectedType ?? '').toLowerCase();
    if (t.isEmpty) return null;
    if (t == 'força' || t == 'forca' || t == 'strength' || t == 'compound') {
      return 'Força';
    }
    if (t == 'hiit' || t == 'cardio' || t == 'plyometric' || t == 'sports') {
      return 'HIIT';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selType = _normalizedType;

    return Column(
      children: [
        // Search
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
              contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Chips: Treinos (Força/HIIT) + Nível
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                label: 'Todos',
                isSelected: selType == null,
                onTap: () => onTypeFilter(null),
              ),
              SizedBox(width: 2.w),
              _filterChip(
                label: 'Força',
                isSelected: selType == 'Força',
                onTap: () => onTypeFilter('Força'),
              ),
              SizedBox(width: 2.w),
              _filterChip(
                label: 'HIIT',
                isSelected: selType == 'HIIT',
                onTap: () => onTypeFilter('HIIT'),
              ),
              SizedBox(width: 2.w),
              _difficultyFilter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _difficultyFilter() {
    return PopupMenuButton<int?>(
      onSelected: onDifficultyFilter,
      color: AppTheme.cardDark,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: selectedDifficulty != null ? AppTheme.accentGold : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedDifficulty != null ? AppTheme.accentGold : AppTheme.dividerGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedDifficulty != null ? 'Nível $selectedDifficulty' : 'Nível',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: selectedDifficulty != null ? AppTheme.primaryBlack : AppTheme.textPrimary,
                fontWeight: selectedDifficulty != null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            SizedBox(width: 1.w),
            CustomIconWidget(
              iconName: 'arrow_drop_down',
              color: selectedDifficulty != null ? AppTheme.primaryBlack : AppTheme.textSecondary,
              size: 4.w,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem<int?>(
          value: null,
          child: Text('Todos os níveis', style: TextStyle(color: Colors.white)),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Text('Nível 1 - Iniciante', style: TextStyle(color: Colors.white)),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Text('Nível 2 - Intermediário', style: TextStyle(color: Colors.white)),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Text('Nível 3 - Avançado', style: TextStyle(color: Colors.white)),
        ),
        PopupMenuItem<int>(
          value: 4,
          child: Text('Nível 4 - Experiente', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
