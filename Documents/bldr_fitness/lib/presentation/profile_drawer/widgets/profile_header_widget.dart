import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;
  final bool isPremiumMember;
  final bool isClubMember;
  final VoidCallback onProfileImageTap;

  const ProfileHeaderWidget({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    this.isPremiumMember = false,
    this.isClubMember = false,
    required this.onProfileImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Profile Image and Badge
          Stack(
            children: [
              GestureDetector(
                onTap: onProfileImageTap,
                child: Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPremiumMember
                          ? AppTheme.accentGold
                          : AppTheme.dividerGray,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: profileImageUrl,
                      width: 25.w,
                      height: 25.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Premium badge
              if (isPremiumMember)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlack,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: AppTheme.primaryBlack,
                      size: 4.w,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 2.h),

          // User Name
          Text(
            userName,
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 0.5.h),

          // User Email
          Text(
            userEmail,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          // BLDR CLUB Badge
          if (isClubMember) ...[
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.h,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.accentGold,
                    Color(0xFFFFE082),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    color: AppTheme.primaryBlack,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'BLDR CLUB',
                    style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Icon(
                    Icons.stars,
                    color: AppTheme.primaryBlack,
                    size: 4.w,
                  ),
                ],
              ),
            ),
          ] else if (isPremiumMember) ...[
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 0.8.h,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppTheme.accentGold,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: AppTheme.accentGold,
                    size: 3.5.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'PREMIUM',
                    style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}