import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/user_service.dart';

class AchievementsGalleryWidget extends StatefulWidget {
  const AchievementsGalleryWidget({Key? key}) : super(key: key);

  @override
  State<AchievementsGalleryWidget> createState() =>
      _AchievementsGalleryWidgetState();
}

class _AchievementsGalleryWidgetState extends State<AchievementsGalleryWidget> {
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    try {
      final userProfile = await UserService.instance.getCurrentUserProfile();
      if (userProfile != null) {
        final achievementsData =
            await UserService.instance.getUserAchievements(userProfile.id);

        if (mounted) {
          setState(() {
            _achievements = achievementsData;
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          _buildAchievementSummary(),
          SizedBox(height: 3.h),
          _buildAchievementCategories(),
          SizedBox(height: 3.h),
          _buildRecentAchievements(),
        ],
      ),
    );
  }

  Widget _buildAchievementSummary() {
    final totalAchievements = _achievements.length;
    final categories = <String, int>{};

    for (final achievement in _achievements) {
      final type = achievement['achievement_type'] as String? ?? 'general';
      categories[type] = (categories[type] ?? 0) + 1;
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.1),
            AppTheme.warningAmber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'emoji_events',
                  color: AppTheme.accentGold,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conquistas',
                      style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Suas conquistas fitness',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$totalAchievements',
                  style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (totalAchievements > 0) ...[
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Treino',
                    categories['workout'] ?? 0,
                    AppTheme.successGreen,
                    'fitness_center',
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Força',
                    categories['strength'] ?? 0,
                    AppTheme.warningAmber,
                    'trending_up',
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Conquista',
                    categories['milestone'] ?? 0,
                    Colors.purple,
                    'star',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, int count, Color color, String iconName) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 5.w,
          ),
          SizedBox(height: 1.h),
          Text(
            '$count',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCategories() {
    final categories = [
      {
        'title': 'Conquistas de treino',
        'type': 'workout',
        'color': AppTheme.successGreen,
        'icon': 'fitness_center'
      },
      {
        'title': 'Objetivos de Força',
        'type': 'strength',
        'color': AppTheme.warningAmber,
        'icon': 'trending_up'
      },
      {
        'title': 'Badges Especiais',
        'type': 'milestone',
        'color': Colors.purple,
        'icon': 'star'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias de Conquista',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...categories.map((category) => _buildCategoryCard(category)),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final categoryAchievements = _achievements
        .where((a) => a['achievement_type'] == category['type'])
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: category['icon'],
                  color: category['color'],
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['title'],
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${categoryAchievements.length} conquistado',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.textSecondary,
                size: 5.w,
              ),
            ],
          ),
          if (categoryAchievements.isNotEmpty) ...[
            SizedBox(height: 2.h),
            SizedBox(
              height: 6.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryAchievements.take(5).length,
                itemBuilder: (context, index) {
                  final achievement = categoryAchievements[index];
                  return Container(
                    width: 6.h,
                    height: 6.h,
                    margin: EdgeInsets.only(right: 2.w),
                    decoration: BoxDecoration(
                      color:
                          (category['color'] as Color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: category['color'], width: 2),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'emoji_events',
                        color: category['color'],
                        size: 4.w,
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            SizedBox(height: 2.h),
            Center(
              child: Text(
                'Sem conquistas nessa categoria',
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    final recentAchievements = _achievements.take(3).toList();

    return Container(
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
              CustomIconWidget(
                iconName: 'history',
                color: AppTheme.accentGold,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Conquistas Recentes',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (recentAchievements.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  CustomIconWidget(
                    iconName: 'emoji_events',
                    color: AppTheme.inactiveGray,
                    size: 10.w,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Ainda sem conquistas',
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Complete treinos e alcançe conquistas para desbloquear badges',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to workouts or show motivation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Inicie seu primeiro treino para desbloquear conquistas!'),
                          backgroundColor: AppTheme.accentGold,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.play_arrow, size: 5.w),
                    label: Text('Começar Treino'),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            )
          else
            ...recentAchievements
                .map((achievement) => _buildAchievementItem(achievement)),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final name = achievement['achievement_name'] ?? 'Unknown Achievement';
    final description = achievement['achievement_description'] ?? '';
    final achievedAt = achievement['achieved_at'];
    final achievementType = achievement['achievement_type'] ?? 'general';
    final value = achievement['value'];
    final unit = achievement['unit'];

    String timeAgo = 'Recently';
    if (achievedAt != null) {
      final date = DateTime.parse(achievedAt);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      if (difference == 0) {
        timeAgo = 'Today';
      } else if (difference == 1) {
        timeAgo = 'Yesterday';
      } else {
        timeAgo = '${difference}d ago';
      }
    }

    Color achievementColor = AppTheme.accentGold;
    String iconName = 'emoji_events';

    switch (achievementType) {
      case 'workout':
        achievementColor = AppTheme.successGreen;
        iconName = 'fitness_center';
        break;
      case 'strength':
        achievementColor = AppTheme.warningAmber;
        iconName = 'trending_up';
        break;
      case 'milestone':
        achievementColor = Colors.purple;
        iconName = 'star';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: achievementColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: achievementColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: achievementColor,
              size: 6.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (value != null && unit != null) ...[
                  SizedBox(height: 1.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: achievementColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$value $unit',
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: achievementColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo,
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: achievementColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'check',
                  color: achievementColor,
                  size: 3.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
