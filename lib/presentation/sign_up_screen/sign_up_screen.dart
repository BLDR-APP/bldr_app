import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/sign_up_form.dart';
import './widgets/video_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();

  Future<void> _handleSignUp(
      String email, String password, String fullName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use real Supabase authentication
      final authResponse = await AuthService.instance.signUp(
        email: email,
        password: password,
        fullName: fullName,
        emailRedirectTo: 'bldr://email-confirmation',
      );

      if (authResponse.user != null) {
        // Success - trigger haptic feedback
        HapticFeedback.mediumImpact();

        if (mounted) {
          // For new users, always show onboarding
          Navigator.pushReplacementNamed(context, '/wait-for-confirmation');
        }
      } else {
        setState(() {
          _errorMessage = 'Sign up failed. Please try again.';
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Sign up failed: ${error.toString()}';
        _isLoading = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  void initState() {
    super.initState();
    // Set status bar style for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: VideoBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                physics: ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.h),
                          _buildHeader(),
                          SizedBox(height: 6.h),
                          _buildSignUpForm(),
                          SizedBox(height: 4.h),
                          // 🔥 Removido _buildLoginLink()
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          margin: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo/Brand
        Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'B',
                  style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              'BLDR',
              style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),

        // Welcome text
        Text(
          'Criar Conta',
          style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 28.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Junte-se à BLDR e comece sua jornada fitness com treinos personalizados e acompanhamento nutricional.',
          style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 13.sp,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowBlack,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SignUpForm(
        onSignUpSuccess: _handleSignUpSuccess,
      ),
    );
  }

  void _handleSignUpSuccess() {
    Navigator.pushReplacementNamed(context, '/wait-for-confirmation');
  }
}