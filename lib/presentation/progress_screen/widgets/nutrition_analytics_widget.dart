import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
// REMOVIDO: import '../../../services/nutrition_service.dart'; // Serviço antigo

// ADICIONADOS: Novos serviços de Firebase
import '../../../services/firebase_nutrition_service.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/auth_service.dart'; // Para checar se está autenticado

class NutritionAnalyticsWidget extends StatefulWidget {
  final int selectedPeriod;

  const NutritionAnalyticsWidget({
    Key? key,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<NutritionAnalyticsWidget> createState() =>
      _NutritionAnalyticsWidgetState();
}

class _NutritionAnalyticsWidgetState extends State<NutritionAnalyticsWidget> {
  Map<String, dynamic>? _waterIntakeData;
  List<Map<String, dynamic>> _recentMeals = []; // AGORA VAI ARMAZENAR OS LOGS PLANOS DO FIREBASE
  Map<String, dynamic>? _macrosData;
  List<FlSpot> _caloriesData = [];
  bool _isLoading = true;
  String _selectedMetric = 'macros';

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  @override
  void didUpdateWidget(NutritionAnalyticsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadNutritionData();
    }
  }

  Future<void> _loadNutritionData() async {
    setState(() => _isLoading = true);

    try {
      final today = DateTime.now();

      // 1. AUTENTICAÇÃO NO FIREBASE (Obrigatório antes de ler dados)
      if (AuthService.instance.isAuthenticated) {
        final token = await FirebaseAuthService().getFirebaseCustomToken();
        if (token != null) {
          await FirebaseAuthService().signInWithCustomToken(token);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
        return; // Não busca dados se não estiver logado
      }

      // 2. BUSCA DE DADOS (MIGRADO PARA FIREBASE)
      final recentMealsFuture = FirebaseNutritionService.instance.getUserMealsForDateFirebase(date: today);

      List<Future<Map<String, dynamic>>> dailySummaryFutures = [];
      for (int i = 0; i < widget.selectedPeriod; i++) {
        final date = today.subtract(Duration(days: i));
        dailySummaryFutures.add(FirebaseNutritionService.instance.getDailyNutritionSummaryFirebase(date: date));
      }
      // FIM DA MIGRAÇÃO DE BUSCA

      final recentMeals = await recentMealsFuture;
      final dailySummaries = await Future.wait(dailySummaryFutures);

      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      final calorieHistory = dailySummaries.map((summary) {
        totalProtein += (summary['total_protein'] as num?)?.toDouble() ?? 0.0;
        totalCarbs += (summary['total_carbs'] as num?)?.toDouble() ?? 0.0;
        totalFat += (summary['total_fat'] as num?)?.toDouble() ?? 0.0;
        return (summary['total_calories'] as num?)?.toDouble() ?? 0.0;
      }).toList().reversed.toList();

      final totalMacros = totalProtein + totalCarbs + totalFat;
      final Map<String, dynamic> macrosData = {
        'protein_percentage': totalMacros > 0 ? (totalProtein / totalMacros) * 100 : 0,
        'carbs_percentage': totalMacros > 0 ? (totalCarbs / totalMacros) * 100 : 0,
        'fat_percentage': totalMacros > 0 ? (totalFat / totalMacros) * 100 : 0,
      };

      final caloriesData = calorieHistory.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value);
      }).toList();

      if (mounted) {
        setState(() {
          _recentMeals = recentMeals; // Salva os logs planos do Firebase
          _macrosData = macrosData;
          _caloriesData = caloriesData;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Erro ao carregar dados de nutrição para progresso: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          _buildMetricSelector(),
          SizedBox(height: 3.h),
          if (_selectedMetric == 'water')
            _buildWaterIntakeCard()
          else if (_selectedMetric == 'macros')
            _buildMacroChart()
          else
            _buildCalorieChart(),
          SizedBox(height: 3.h),
          _buildRecentMeals(),
          SizedBox(height: 3.h),
          _buildNutritionTips(),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = {
      'water': {'label': 'Água', 'icon': 'local_drink', 'color': Colors.blue},
      'macros': {
        'label': 'Macros',
        'icon': 'pie_chart',
        'color': AppTheme.successGreen
      },
      'calories': {
        'label': 'Calorias',
        'icon': 'local_fire_department',
        'color': AppTheme.warningAmber
      },
    };

    return SizedBox(
      height: 10.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemBuilder: (context, index) {
          final key = metrics.keys.elementAt(index);
          final metric = metrics[key]!;
          final isSelected = key == _selectedMetric;

          return GestureDetector(
            onTap: () => setState(() => _selectedMetric = key),
            child: Container(
              width: 25.w,
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentGold.withOpacity(0.2) // Correção de Opacity
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                  isSelected ? AppTheme.accentGold : AppTheme.dividerGray,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: metric['icon'] as String,
                    color: isSelected ? AppTheme.accentGold : (metric['color'] as Color),
                    size: 6.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    metric['label'] as String,
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.accentGold
                          : AppTheme.textSecondary,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaterIntakeCard() {
    final totalAmountMl = _waterIntakeData?['total_amount_ml'] ?? 0;
    final totalAmountLiters = _waterIntakeData?['total_amount_liters'] ?? '0.0';
    final logCount = _waterIntakeData?['log_count'] ?? 0;
    final targetMl = 2500;
    final progress = (totalAmountMl / targetMl).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2), // Correção de Opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: 'local_drink',
                  color: Colors.blue,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hidratação Diária',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${totalAmountLiters}L / 2.5L objetivo',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2), // Correção de Opacity
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.dividerGray,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 1.5.h,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildWaterStat('${totalAmountMl}ml', 'Total Hoje'),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildWaterStat('$logCount', 'Registros'),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _showAddWaterDialog,
            icon: Icon(Icons.add, size: 5.w),
            label: Text('Registrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterStat(String value, String label) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddWaterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final amounts = [250, 500, 750, 1000];
        return AlertDialog(
          backgroundColor: AppTheme.dialogDark,
          title: Text(
            'Registrar Água',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: amounts.map((amount) {
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 2.h),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      Navigator.pop(context);
                      _loadNutritionData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registrado com sucesso: ${amount}ml'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Falha ao registrar'),
                          backgroundColor: AppTheme.errorRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('${amount}ml'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMacroChart() {
    final macros = {
      'Proteina': {
        'value': (_macrosData?['protein_percentage'] as num?)?.toDouble() ?? 0.0,
        'color': AppTheme.successGreen
      },
      'Carbs': {'value': (_macrosData?['carbs_percentage'] as num?)?.toDouble() ?? 0.0, 'color': AppTheme.warningAmber},
      'Fat': {'value': (_macrosData?['fat_percentage'] as num?)?.toDouble() ?? 0.0, 'color': AppTheme.errorRed},
    };

    final validMacros = macros.entries.where((e) => (e.value['value'] as double) > 0.1).toList();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribuição de Macronutrientes',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          validMacros.isEmpty
              ? SizedBox(
            height: 25.h,
            child: Center(
              child: Text(
                'Sem dados de macronutrientes no período.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
              : SizedBox(
            height: 25.h,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: validMacros.map((entry) {
                        final data = entry.value;
                        return PieChartSectionData(
                          color: data['color'] as Color,
                          value: data['value'] as double,
                          title: '${(data['value'] as double).round()}%',
                          radius: 50,
                          titleStyle: AppTheme.darkTheme.textTheme.labelMedium
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: validMacros.map((entry) {
                      final macro = entry.key;
                      final data = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: Row(
                          children: [
                            Container(
                              width: 3.w,
                              height: 3.w,
                              decoration: BoxDecoration(
                                color: data['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                macro,
                                style: AppTheme.darkTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieChart() {
    final calorieData = _caloriesData;
    if (calorieData.isEmpty || calorieData.every((spot) => spot.y == 0)) {
      return Container(
        padding: EdgeInsets.all(4.w),
        height: 30.h,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Center(
          child: Text(
            'Sem dados de calorias no período.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    // --- INÍCIO DA CORREÇÃO ---
    // Calcula um intervalo dinâmico para o eixo X.
    // A ideia é mostrar ~6 rótulos, independentemente do período.
    final double bottomInterval = max(1.0, ((calorieData.length - 1) / 5).ceilToDouble());
    // --- FIM DA CORREÇÃO ---

    final yValues = calorieData.map((spot) => spot.y).toList();
    double minYValue = yValues[0];
    double maxYValue = yValues[0];
    for (var y in yValues) {
      if (y < minYValue) minYValue = y;
      if (y > maxYValue) maxYValue = y;
    }

    final minY = (minYValue * 0.9).floorToDouble();
    final maxY = (maxYValue * 1.1).ceilToDouble();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calorias Diárias',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 25.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.dividerGray.withOpacity(0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        // --- INÍCIO DA CORREÇÃO ---
                        getTitlesWidget: (value, meta) {
                          final dayIndex = value.toInt();
                          final daysAgo = (calorieData.length - 1) - dayIndex;

                          if (daysAgo == 0) {
                            return Text('Hoje', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary));
                          }

                          // Evita desenhar rótulos fora do intervalo calculado
                          if (value != meta.min && value != meta.max && value % bottomInterval != 0) {
                            return const Text('');
                          }

                          return Text('D-${daysAgo}', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary));
                        },
                        interval: bottomInterval // Usa o intervalo dinâmico
                      // --- FIM DA CORREÇÃO ---
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) > 0 ? (maxY - minY) / 3 : 100,
                      getTitlesWidget: (value, meta) {
                        if (value == minY || value == maxY) return const Text('');
                        return Text(
                          '${(value / 1000).toStringAsFixed(1)}k',
                          style:
                          AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (calorieData.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: calorieData,
                    isCurved: true,
                    color: AppTheme.warningAmber,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.warningAmber.withOpacity(0.1), // Correção de Opacity
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // >>> CORREÇÃO: Lendo a lista plana do Firebase (user_meals) <<<
  Widget _buildRecentMeals() {
    // A variável _recentMeals (do _loadNutritionData) agora é a lista plana
    final allFoodItems = _recentMeals;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'restaurant',
                color: AppTheme.accentGold,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Refeições Recentes',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (allFoodItems.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  CustomIconWidget(
                    iconName: 'restaurant',
                    color: AppTheme.inactiveGray,
                    size: 10.w,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Nenhuma refeição registrada hoje',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            )
          else
          // Itera sobre os documentos planos e os passa para _buildMealItem
            ...allFoodItems.take(5).map((foodItem) => _buildMealItem(foodItem)),
        ],
      ),
    );
  }

  // >>> CORREÇÃO: Lendo os campos agregados do documento (foodItem) <<<
  Widget _buildMealItem(Map<String, dynamic> foodItem) {
    // A estrutura antiga era: foodItem['food_items']['name']
    // A nova estrutura do Firebase é: foodItem['food_name']

    final name = foodItem['food_name'] ?? 'Comida Desconhecida';
    final brand = foodItem['brand'] as String?; // O campo 'brand' não existe no user_meals
    final calories = (foodItem['calories'] as num?)?.toInt() ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (brand != null && brand.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      brand,
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$calories cal',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTips() {
    final tips = [
      'Beba água 30 minutos antes da refeição para melhor digestão',
      'Inclua proteína em toda refeição para manter massa muscular',
      'Coma vegetais coloridos para diversificação de micronutrientes',
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successGreen.withOpacity(0.1), // Correção de Opacity
            AppTheme.accentGold.withOpacity(0.05), // Correção de Opacity
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)), // Correção de Opacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'lightbulb',
                color: AppTheme.successGreen,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Dicas Nutricionais',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...tips.map((tip) => Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 1.w,
                  height: 1.w,
                  margin: EdgeInsets.only(top: 2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    tip,
                    style:
                    AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}