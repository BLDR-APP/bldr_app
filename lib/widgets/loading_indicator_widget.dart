// lib/widgets/loading_indicator_widget.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Ajuste o caminho se necessário

class LoadingIndicatorWidget extends StatelessWidget {
  const LoadingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.accentGold,
      ),
    );
  }
}