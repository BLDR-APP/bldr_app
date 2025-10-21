import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FeaturedWorkoutsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> workouts;
  final Function(Map<String, dynamic>) onWorkoutTap;
  final Function(Map<String, dynamic>) onStartWorkout;

  const FeaturedWorkoutsWidget({
    Key? key,
    required this.workouts,
    required this.onWorkoutTap,
    required this.onStartWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Treinos em Destaque',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 25.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: workouts.length,
            separatorBuilder: (context, index) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return _buildFeaturedCard(workout);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> workout) {
    return GestureDetector(
      onTap: () => onWorkoutTap(workout),
      child: Container(
        width: 70.w,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentGold.withValues(alpha: 0.3),
                      AppTheme.accentGold.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: CustomIconWidget(
                        iconName: _getWorkoutTypeIcon(workout['workout_type']),
                        color: AppTheme.accentGold,
                        size: 15.w,
                      ),
                    ),
                    Positioned(
                      top: 2.w,
                      right: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              color: AppTheme.primaryBlack,
                              size: 3.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${workout['difficulty_level'] ?? 1}',
                              style: AppTheme.darkTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.primaryBlack,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout['name'] ?? 'Untitled Workout',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: AppTheme.textSecondary,
                          size: 3.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${workout['estimated_duration_minutes'] ?? 30} min',
                          style:
                              AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () => onStartWorkout(workout),
                          child: Container(
                            padding: EdgeInsets.all(1.5.w),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomIconWidget(
                              iconName: 'play_arrow',
                              color: AppTheme.primaryBlack,
                              size: 4.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWorkoutTypeIcon(String? workoutType) {
    switch (workoutType) {
      case 'força':
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
}
