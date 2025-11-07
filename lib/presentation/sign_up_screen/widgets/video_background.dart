import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class VideoBackground extends StatefulWidget {
  final Widget child;

  const VideoBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video background placeholder with animated fitness imagery
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlack.withValues(alpha: 0.3),
                        AppTheme.primaryBlack.withValues(alpha: 0.7),
                        AppTheme.primaryBlack.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: CustomImageWidget(
                    imageUrl:
                        "https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),

        // Dark overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlack.withValues(alpha: 0.4),
                  AppTheme.primaryBlack.withValues(alpha: 0.6),
                  AppTheme.primaryBlack.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),

        // Animated overlay pattern
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [
                          AppTheme.accentGold.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}
