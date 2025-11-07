import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

class GreetingHeaderWidget extends StatefulWidget {
  final VoidCallback onSettingsPressed;

  const GreetingHeaderWidget({
    Key? key,
    required this.onSettingsPressed,
  }) : super(key: key);

  @override
  State<GreetingHeaderWidget> createState() => _GreetingHeaderWidgetState();
}

class _GreetingHeaderWidgetState extends State<GreetingHeaderWidget> {
  UserProfile? userProfile;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Check if user is authenticated first
      if (!AuthService.instance.isAuthenticated) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = false;
          });
        }
        return;
      }

      final profile = await UserService.instance.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          userProfile = profile;
          isLoading = false;
          hasError = false;
        });
      }
    } catch (error) {
      debugPrint('Error loading user profile: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom Dia';
    } else if (hour < 17) {
      return 'Boa Tarde';
    } else {
      return 'Boa Noite';
    }
  }

  String _getMotivationalMessage() {
    final messages = [
      'Ready to crush your goals?',
      'Let\'s make today count!',
      'Time to build greatness!',
      'Your fitness journey continues!',
      'Ready for another strong day?',
    ];
    return messages[DateTime.now().day % messages.length];
  }

  String _getDisplayName() {
    if (isLoading) return 'Loading...';

    if (!AuthService.instance.isAuthenticated) {
      return 'Guest User';
    }

    if (hasError || userProfile == null) {
      return AuthService.instance.getCurrentUserEmail()?.split('@')[0] ??
          'User';
    }

    return userProfile!.fullName.isNotEmpty
        ? userProfile!.fullName
        : AuthService.instance.getCurrentUserEmail()?.split('@')[0] ?? 'User';
  }

  String _getInitials() {
    if (isLoading) return '...';

    if (!AuthService.instance.isAuthenticated) {
      return 'G';
    }

    if (hasError || userProfile == null) {
      return AuthService.instance.getCurrentUserEmail()?[0].toUpperCase() ??
          'U';
    }

    return userProfile!.fullName.isNotEmpty
        ? userProfile!.fullName[0].toUpperCase()
        : AuthService.instance.getCurrentUserEmail()?[0].toUpperCase() ?? 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.w),
      child: Row(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 6.w,
            backgroundColor: AuthService.instance.isAuthenticated
                ? AppTheme.accentGold
                : AppTheme.inactiveGray,
            backgroundImage: userProfile?.avatarUrl != null && !hasError
                ? NetworkImage(userProfile!.avatarUrl!)
                : null,
            child: userProfile?.avatarUrl == null || hasError
                ? Text(
                    _getInitials(),
                    style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 4.w),

          // Greeting and Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _getDisplayName(),
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  AuthService.instance.isAuthenticated
                      ? _getMotivationalMessage()
                      : 'Bem-Vindo ao BLDR!',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AuthService.instance.isAuthenticated
                        ? AppTheme.accentGold
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Settings/Profile Button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.dividerGray,
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: widget.onSettingsPressed,
              icon: CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.accentGold,
                size: 6.w,
              ),
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
    );
  }
}
