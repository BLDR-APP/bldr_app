import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class QuestionCardWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const QuestionCardWidget({
    Key? key,
    required this.title,
    this.subtitle,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // REMOVIDO: A restrição de altura mínima que podia causar conflitos.
      // A rolagem da página principal cuidará do alinhamento.
      // constraints: BoxConstraints(minHeight: 70.h),
      padding: EdgeInsets.symmetric(vertical: 4.h), // Padding horizontal foi removido daqui e colocado na página principal.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle!,
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: 4.h),

          // --- CORREÇÃO PRINCIPAL: O Expanded FOI REMOVIDO DAQUI ---
          child,
        ],
      ),
    );
  }
}