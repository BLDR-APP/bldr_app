import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WorkoutCardWidget extends StatelessWidget {
  final Map<String, dynamic> workout;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const WorkoutCardWidget({
    Key? key,
    required this.workout,
    required this.onTap,
    required this.onStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: _getWorkoutTypeColor(workout['workout_type'])
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: _getWorkoutTypeIcon(workout['workout_type']),
                    color: _getWorkoutTypeColor(workout['workout_type']),
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['name'] ?? 'Untitled Workout',
                        style:
                            AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (workout['description'] != null)
                        Text(
                          workout['description'],
                          style:
                              AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'play_arrow',
                      color: AppTheme.primaryBlack,
                      size: 5.w,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                _buildInfoChip(
                  '${workout['estimated_duration_minutes'] ?? 30} min',
                  Icons.schedule,
                  AppTheme.textSecondary,
                ),
                SizedBox(width: 2.w),
                _buildInfoChip(
                  'Nível ${workout['difficulty_level'] ?? 1}',
                  Icons.star,
                  AppTheme.accentGold,
                ),
                SizedBox(width: 2.w),
                _buildInfoChip(
                  _formatWorkoutType(workout['workout_type']),
                  Icons.category,
                  _getWorkoutTypeColor(workout['workout_type']),
                ),
                Spacer(),
                if (workout['user_profiles'] != null)
                  Text(
                    'by ${workout['user_profiles']['full_name']}',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getWorkoutTypeIcon(String? workoutType) {
    switch (workoutType) {
      case 'strength':
        return 'fitness_center';
      case 'hiit':
        return 'directions_run';
      case 'mobilidade':
        return 'accessibility';
      case 'esportes':
        return 'sports_martial_arts';
      default:
        return 'fitness_center';
    }
  }

  Color _getWorkoutTypeColor(String? workoutType) {
    switch (workoutType) {
      case 'strength':
        return AppTheme.accentGold;
      case 'hiit':
        return AppTheme.errorRed;
      case 'mobilidade':
        return AppTheme.successGreen;
      case 'esportes':
        return AppTheme.warningAmber;
      default:
        return AppTheme.accentGold;
    }
  }

  String _formatWorkoutType(String? workoutType) {
    if (workoutType == null) return 'Custom';
    return workoutType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
