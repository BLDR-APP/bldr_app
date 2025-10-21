import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BldrLogoWidget extends StatelessWidget {
  final double? size;

  const BldrLogoWidget({
    Key? key,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? 80.0;

    return Container(
      width: logoSize * 2,
      height: logoSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background accent
          Container(
            width: logoSize * 1.8,
            height: logoSize * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.1),
                  AppTheme.accentGold.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          // BLDR Text
          Text(
            'BLDR',
            style: TextStyle(
              fontSize: logoSize * 0.4,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: logoSize * 0.02,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: AppTheme.accentGold.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          // Fitness accent line
          Positioned(
            bottom: logoSize * 0.1,
            child: Container(
              width: logoSize * 1.2,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.accentGold,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Fitness subtitle
          Positioned(
            bottom: -logoSize * 0.15,
            child: Text(
              'FITNESS',
              style: TextStyle(
                fontSize: logoSize * 0.12,
                fontWeight: FontWeight.w500,
                color: AppTheme.accentGold,
                letterSpacing: logoSize * 0.01,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
