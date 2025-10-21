// club_featured_workouts_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubFeaturedWorkoutsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> workouts;
  final Function(Map<String, dynamic>) onWorkoutTap;
  final Function(Map<String, dynamic>) onStartWorkout;

  const ClubFeaturedWorkoutsWidget({
    Key? key,
    required this.workouts,
    required this.onWorkoutTap,
    required this.onStartWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Treinos em Destaque',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 26.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: workouts.length,
            separatorBuilder: (context, index) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return _ClubFeaturedCardVIP(
                workout: workout,
                onTap: () => onWorkoutTap(workout),
                onStart: () => onStartWorkout(workout),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ====================== CARD VIP ====================== */

class _ClubFeaturedCardVIP extends StatelessWidget {
  const _ClubFeaturedCardVIP({
    required this.workout,
    required this.onTap,
    required this.onStart,
  });

  final Map<String, dynamic> workout;
  final VoidCallback onTap;
  final VoidCallback onStart;

  // Normalizações para compatibilidade (CLUB + legado)
  String get _name => (workout['name'] ?? 'Treino').toString();

  String get _typeRaw =>
      (workout['type'] ?? workout['workout_type'] ?? '').toString();

  String get _type {
    final s = _typeRaw.toLowerCase();
    if (s == 'força' || s == 'forca' || s == 'strength' || s == 'compound') {
      return 'Força';
    }
    if (s == 'hiit' || s == 'cardio' || s == 'plyometric') {
      return 'HIIT';
    }
    return 'Força';
  }

  int get _level {
    final l = workout['level'] ?? workout['difficulty_level'] ?? 1;
    if (l is int) return l.clamp(1, 4);
    if (l is num) return l.toInt().clamp(1, 4);
    return int.tryParse(l.toString())?.clamp(1, 4) ?? 1;
  }

  int get _minutes {
    final m = workout['estimated_duration_minutes'] ?? 30;
    if (m is int) return m;
    if (m is num) return m.toInt();
    return int.tryParse(m.toString()) ?? 30;
  }

  String get _iconName {
    switch (_type.toLowerCase()) {
      case 'força':
      case 'forca':
        return 'fitness_center';
      case 'hiit':
        return 'flash_on';
      default:
        return 'fitness_center';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70.w,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22D4AF37)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com gradiente VIP + selo de nível e tipo
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentGold.withValues(alpha: 0.35),
                      AppTheme.accentGold.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Ícone central estilizado
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.accentGold.withOpacity(0.25)),
                        ),
                        child: CustomIconWidget(
                          iconName: _iconName,
                          color: AppTheme.accentGold,
                          size: 15.w,
                        ),
                      ),
                    ),
                    // Badge: Nível
                    Positioned(
                      top: 2.2.w,
                      right: 2.2.w,
                      child: _ClubGoldBadge(text: 'Nível $_level'),
                    ),
                    // Selo do tipo (Força/HIIT)
                    Positioned(
                      bottom: 2.2.w,
                      left: 2.2.w,
                      child: _ClubTypePill(type: _type),
                    ),
                  ],
                ),
              ),
            ),

            // Body: título, duração e play
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.8.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: AppTheme.textSecondary,
                          size: 3.6.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$_minutes min',
                          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onStart,
                          child: Container(
                            padding: EdgeInsets.all(1.8.w),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGold.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CustomIconWidget(
                              iconName: 'play_arrow',
                              color: AppTheme.primaryBlack,
                              size: 4.6.w,
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
}

/* ====================== SUBWIDGETS VIP ====================== */

class _ClubGoldBadge extends StatelessWidget {
  const _ClubGoldBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.4.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8D18F), Color(0xFFD4AF37), Color(0xFFA8872A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: 'star', color: Colors.black87, size: 3.6.w),
          SizedBox(width: 1.6.w),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubTypePill extends StatelessWidget {
  const _ClubTypePill({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isForca = type.toLowerCase() == 'força' || type.toLowerCase() == 'forca';
    final color = isForca ? AppTheme.accentGold : AppTheme.warningAmber;
    final icon = isForca ? 'fitness_center' : 'flash_on';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.4.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 3.4.w),
          SizedBox(width: 1.4.w),
          Text(
            type,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
