// lib/presentation/bldr_club/widgets/club_workout_card_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubWorkoutCardWidget extends StatelessWidget {
  final Map<String, dynamic> workout;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const ClubWorkoutCardWidget({
    Key? key,
    required this.workout,
    required this.onTap,
    required this.onStart,
  }) : super(key: key);

  // ===== Normalizações (CLUB + legado) =====
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

  String get _desc => (workout['description'] ?? '').toString();

  Map<String, dynamic>? get _creator {
    // CLUB: user_profiles!created_by(full_name) → já vem como map simples
    final up = workout['user_profiles'];
    if (up is Map<String, dynamic>) return up;
    return null;
  }

  String get _iconName =>
      _type == 'Força' ? 'fitness_center' : 'flash_on';

  Color get _typeColor =>
      _type == 'Força' ? AppTheme.accentGold : AppTheme.warningAmber;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22D4AF37)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // medalhão VIP do tipo
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_typeColor.withOpacity(0.20), _typeColor.withOpacity(0.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _typeColor.withOpacity(0.35)),
                  ),
                  child: CustomIconWidget(
                    iconName: _iconName,
                    color: _typeColor,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 3.w),
                // Título + descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_desc.isNotEmpty)
                        Text(
                          _desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Play
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
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
                      size: 5.w,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.2.h),

            // Chips: duração, nível, tipo + autor
            Row(
              children: [
                _infoChip(
                  label: '$_minutes min',
                  iconName: 'schedule',
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: 2.w),
                _infoChip(
                  label: 'Nível $_level',
                  iconName: 'star',
                  color: AppTheme.accentGold,
                ),
                SizedBox(width: 2.w),
                _infoChip(
                  label: _type,
                  iconName: _iconName,
                  color: _typeColor,
                ),
                const Spacer(),
                if (_creator != null && (_creator!['full_name']?.toString().isNotEmpty ?? false))
                  Text(
                    'by ${_creator!['full_name']}',
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

  Widget _infoChip({
    required String label,
    required String iconName,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.6.w, vertical: 0.9.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: iconName, color: color, size: 3.8.w),
          SizedBox(width: 1.2.w),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
