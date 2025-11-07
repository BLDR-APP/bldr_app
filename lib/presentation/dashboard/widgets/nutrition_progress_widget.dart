import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
// REMOVIDO: import '../../../services/nutrition_service.dart'; // Serviço Antigo

// NOVAS DEPENDÊNCIAS
import '../../../services/firebase_nutrition_service.dart'; // Novo serviço de dados
import '../../../services/firebase_auth_service.dart'; // Novo serviço de Auth (Custom Token)

class NutritionProgressWidget extends StatefulWidget {
  const NutritionProgressWidget({Key? key}) : super(key: key);

  @override
  State<NutritionProgressWidget> createState() =>
      _NutritionProgressWidgetState();
}

class _NutritionProgressWidgetState extends State<NutritionProgressWidget> {
  Map<String, dynamic>? nutritionData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = false;
          });
        }
        return;
      }

      final userId = AuthService.instance.currentUser?.id;

      // 1. AUTENTICAÇÃO NO FIREBASE (Custom Token)
      if (userId != null) {
        // Obtém o token (se não estiver em cache) e faz login no Firebase Auth.
        final token = await FirebaseAuthService().getFirebaseCustomToken();
        if (token != null) {
          await FirebaseAuthService().signInWithCustomToken(token);
        }
      }

      // 2. BUSCA DE DADOS (USANDO O NOVO SERVIÇO)
      final data = await FirebaseNutritionService.instance
          .getDailyNutritionSummaryFirebase(date: DateTime.now());

      if (mounted) {
        setState(() {
          nutritionData = data;
          isLoading = false;
          hasError = false;
        });
      }
    } catch (error) {
      // Captura erros de permissão ou falhas na Edge Function
      debugPrint('Erro ao carregar dados de nutrição: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerGray, width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CustomIconWidget(
                iconName: 'restaurant',
                color: AppTheme.successGreen,
                size: 6.w),
            SizedBox(width: 3.w),
            Expanded(
                child: Text('Nutrição de Hoje',
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600))),
            if (!isLoading && !hasError && AuthService.instance.isAuthenticated)
              TextButton(
                  onPressed: () {
                    // Navigate to nutrition screen
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Abrindo detalhes da nutrição...'),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating));
                  },
                  child: Text('Ver tudo',
                      style: TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w600))),
          ]),
          SizedBox(height: 3.h),
          if (isLoading)
            _buildLoadingState()
          else if (!AuthService.instance.isAuthenticated)
            _buildUnauthenticatedState()
          else if (hasError)
              _buildErrorState()
            else
              _buildNutritionContent(),
        ]));
  }

  Widget _buildLoadingState() {
    return Center(
        child: Column(children: [
          CircularProgressIndicator(color: AppTheme.successGreen, strokeWidth: 2),
          SizedBox(height: 2.h),
          Text('Carregando dados de nutrição...',
              style: AppTheme.darkTheme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary)),
        ]));
  }

  Widget _buildUnauthenticatedState() {
    return Column(children: [
      CustomIconWidget(
          iconName: 'login', color: AppTheme.inactiveGray, size: 12.w),
      SizedBox(height: 2.h),
      Text('Entre para acompanhar sua nutrição',
          style: AppTheme.darkTheme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textSecondary)),
      SizedBox(height: 2.h),
      SizedBox(
          width: double.infinity,
          child: OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.loginScreen),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.successGreen,
                  side: BorderSide(color: AppTheme.successGreen, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Entrar'))),
    ]);
  }

  Widget _buildErrorState() {
    return Column(children: [
      CustomIconWidget(
          iconName: 'error_outline', color: AppTheme.warningAmber, size: 12.w),
      SizedBox(height: 2.h),
      Text('Unable to load nutrition data',
          style: AppTheme.darkTheme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textSecondary)),
      SizedBox(height: 2.h),
      SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
              onPressed: _loadNutritionData,
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.successGreen,
                  side: BorderSide(color: AppTheme.successGreen, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: CustomIconWidget(
                  iconName: 'refresh', color: AppTheme.successGreen, size: 4.w),
              label: Text('Tentar Novamente'))),
    ]);
  }

  Widget _buildNutritionContent() {
    // If no data available, show empty state
    if (nutritionData == null || nutritionData!.isEmpty) {
      return Column(children: [
        CustomIconWidget(
            iconName: 'restaurant', color: AppTheme.inactiveGray, size: 12.w),
        SizedBox(height: 2.h),
        Text('Nenhuma refeição adicionada hoje',
            style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        SizedBox(height: 1.h),
        Text('Começe adicionando suas refeições para visualizar seu progresso nutricional',
            style: AppTheme.darkTheme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
        SizedBox(height: 3.h),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Abrindo registrador...'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: AppTheme.textPrimary,
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: CustomIconWidget(
                    iconName: 'add', color: AppTheme.textPrimary, size: 4.w),
                label: Text('Adicionar primeira refeição',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)))),
      ]);
    }

    // Show actual nutrition data
    final calories = nutritionData!['total_calories'] ?? 0;
    final protein = nutritionData!['total_protein'] ?? 0;
    final carbs = nutritionData!['total_carbs'] ?? 0;
    final fat = nutritionData!['total_fat'] ?? 0;

    return Column(children: [
      // Calories
      _buildMacroRow(
        'Calorias',
        '$calories',
        'kcal',
        AppTheme.accentGold,
        progress: (calories / 2000).clamp(0.0, 1.0), // Assuming 2000 cal target
      ),
      SizedBox(height: 2.h),

      // Macros
      Row(children: [
        Expanded(
            child:
            _buildMacroCard('Proteina', '${protein}g', AppTheme.errorRed)),
        SizedBox(width: 3.w),
        Expanded(child: _buildMacroCard('Carbs', '${carbs}g', Colors.blue)),
        SizedBox(width: 3.w),
        Expanded(
            child: _buildMacroCard('Gordura', '${fat}g', AppTheme.warningAmber)),
      ]),
    ]);
  }

  Widget _buildMacroRow(String name, String value, String unit, Color color,
      {double progress = 0.0}) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(name,
            style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        Text('$value $unit',
            style: AppTheme.darkTheme.textTheme.bodyLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
      SizedBox(height: 1.h),
      LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.surfaceDark,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4)),
    ]);
  }

  Widget _buildMacroCard(String name, String value, Color color) {
    return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerGray, width: 1)),
        child: Column(children: [
          Text(name,
              style: AppTheme.darkTheme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.textSecondary)),
          SizedBox(height: 0.5.h),
          Text(value,
              style: AppTheme.darkTheme.textTheme.titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ]));
  }
}