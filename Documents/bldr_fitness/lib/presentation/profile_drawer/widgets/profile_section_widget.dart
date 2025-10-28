import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProfileSectionWidget extends StatelessWidget {
  final String title;
  final List<ProfileSectionItem> items;

  const ProfileSectionWidget({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            title,
            style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 1.5.h),

          // Section Items
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerGray),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      leading: _buildIcon(item.iconName, item.isDestructive),
                      title: Text(
                        item.title,
                        style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                          color: item.isDestructive
                              ? AppTheme.errorRed
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(
                              item.subtitle!,
                              style: AppTheme.darkTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            )
                          : null,
                      trailing: item.trailing ??
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                      onTap: item.onTap,
                    ),

                    // Divider between items (except for last item)
                    if (!isLast)
                      Container(
                        margin: EdgeInsets.only(left: 16.w),
                        height: 1,
                        color: AppTheme.dividerGray,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String iconName, bool isDestructive) {
    IconData iconData;

    switch (iconName.toLowerCase()) {
      case 'edit':
        iconData = Icons.edit;
        break;
      case 'fitness_center':
        iconData = Icons.fitness_center;
        break;
      case 'straighten':
        iconData = Icons.straighten;
        break;
      case 'notifications':
        iconData = Icons.notifications;
        break;
      case 'sync':
        iconData = Icons.sync;
        break;
      case 'privacy_tip':
        iconData = Icons.privacy_tip;
        break;
      case 'share':
        iconData = Icons.share;
        break;
      case 'download':
        iconData = Icons.download;
        break;
      case 'logout':
        iconData = Icons.logout;
        break;
      case 'delete':
        iconData = Icons.delete;
      case 'checklist_outlined':
        iconData = Icons.checklist_outlined;
      case 'arrow_upward':
        iconData = Icons.arrow_upward;
      case 'attach_money':
        iconData = Icons.attach_money;
      default:
        iconData = Icons.help;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDestructive
            ? AppTheme.errorRed.withAlpha(26)
            : AppTheme.accentGold.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: isDestructive ? AppTheme.errorRed : AppTheme.accentGold,
      ),
    );
  }
}

class ProfileSectionItem {
  final String iconName;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const ProfileSectionItem({
    required this.iconName,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });
}
