//import 'package:flutter/material.dart';
//import 'package:sizer/sizer.dart';
//
//import '../../../core/app_export.dart';
//
//class AchievementsWidget extends StatelessWidget {
//  const AchievementsWidget({Key? key}) : super(key: key);
//
//  @override
//  Widget build(BuildContext context) {
//    final List<Map<String, dynamic>> achievements = [
//      {
//        "id": 1,
//        "title": "Sequência de 7 Dias",
//        "description": "Treinos concluídos por 7 dias consecutivos",
//        "icon": "local_fire_department",
//        "date": "Hoje",
//        "isNew": true,
//      },
//      {
//        "id": 2,
//        "title": "Recorde Pessoal",
//        "description": "Novo recorde no levantamento terra: 102 kg",
//        "icon": "emoji_events",
//        "date": "Ontem",
//        "isNew": false,
//      },
//      {
//        "id": 3,
//        "title": "Meta de Nutrição",
//        "description": "Atingiu a meta de proteína por 5 dias seguidos",
//        "icon": "restaurant_menu",
//        "date": "Há 2 dias",
//        "isNew": false,
//      },
//    ];
//
//    return Container(
//      width: double.infinity,
//      margin: EdgeInsets.symmetric(horizontal: 4.w),
//      padding: EdgeInsets.all(4.w),
//      decoration: BoxDecoration(
//        color: AppTheme.cardDark,
//        borderRadius: BorderRadius.circular(16),
//        border: Border.all(
//          color: AppTheme.dividerGray,
//          width: 1,
//        ),
//        boxShadow: [
//          BoxShadow(
//            color: AppTheme.shadowBlack,
//            blurRadius: 8,
//            offset: Offset(0, 4),
//          ),
//        ],
//      ),
//      child: Column(
//        crossAxisAlignment: CrossAxisAlignment.start,
//        children: [
//          Row(
//            children: [
//              Container(
//                padding: EdgeInsets.all(2.w),
//                decoration: BoxDecoration(
//                  color: AppTheme.accentGold.withValues(alpha: 0.2),
//                  borderRadius: BorderRadius.circular(8),
//                ),
//                child: CustomIconWidget(
//                  iconName: 'emoji_events',
//                  color: AppTheme.accentGold,
//                  size: 5.w,
//                ),
//              ),
//              SizedBox(width: 3.w),
//              Expanded(
//                child: Text(
//                  'Conquistas Recentes',
//                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
//                    color: AppTheme.textPrimary,
//                    fontWeight: FontWeight.w600,
//                  ),
//                  overflow: TextOverflow.ellipsis,
//                ),
//              ),
//            ],
//          ),
//          SizedBox(height: 3.h),
//          ListView.separated(
//            shrinkWrap: true,
//            physics: NeverScrollableScrollPhysics(),
//            itemCount: achievements.length,
//            separatorBuilder: (context, index) => SizedBox(height: 2.h),
//            itemBuilder: (context, index) {
//              final achievement = achievements[index];
//              return _buildAchievementItem(achievement);
//            },
//          ),
//        ],
//      ),
//    );
//  }
//
//  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
//    return Container(
//      padding: EdgeInsets.all(3.w),
//      decoration: BoxDecoration(
//        color: AppTheme.surfaceDark,
//        borderRadius: BorderRadius.circular(12),
//        border: achievement["isNew"] as bool
//            ? Border.all(
//                color: AppTheme.accentGold.withValues(alpha: 0.5), width: 1)
//            : null,
//      ),
//      child: Row(
//        children: [
//          Container(
//            padding: EdgeInsets.all(2.w),
//            decoration: BoxDecoration(
//              color: AppTheme.accentGold.withValues(alpha: 0.2),
//              borderRadius: BorderRadius.circular(8),
//            ),
//            child: CustomIconWidget(
//              iconName: achievement["icon"] as String,
//              color: AppTheme.accentGold,
//              size: 5.w,
//            ),
//          ),
//          SizedBox(width: 3.w),
//          Expanded(
//            child: Column(
//              crossAxisAlignment: CrossAxisAlignment.start,
//              children: [
//                Row(
//                  children: [
//                    Expanded(
//                      child: Text(
//                        achievement["title"] as String,
//                        style:
//                            AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
//                          color: AppTheme.textPrimary,
//                          fontWeight: FontWeight.w600,
//                        ),
//                        overflow: TextOverflow.ellipsis,
//                      ),
//                    ),
//                    if (achievement["isNew"] as bool)
//                      Container(
//                        padding: EdgeInsets.symmetric(
//                            horizontal: 2.w, vertical: 0.5.h),
//                        decoration: BoxDecoration(
//                          color: AppTheme.accentGold,
//                          borderRadius: BorderRadius.circular(12),
//                        ),
//                        child: Text(
//                          'NOVO',
//                          style:
//                              AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
//                            color: AppTheme.primaryBlack,
//                            fontWeight: FontWeight.w600,
//                            fontSize: 8.sp,
//                          ),
//                        ),
//                      ),
//                  ],
//                ),
//                SizedBox(height: 0.5.h),
//                Text(
//                  achievement["description"] as String,
//                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
//                    color: AppTheme.textSecondary,
//                  ),
//                  overflow: TextOverflow.ellipsis,
//                  maxLines: 2,
//                ),
//                SizedBox(height: 0.5.h),
//                Text(
//                  achievement["date"] as String,
//                  style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
//                    color: AppTheme.inactiveGray,
//                  ),
//                ),
//              ],
//            ),
//          ),
//        ],
//      ),
//    );
//  }
//}