import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/progress_service.dart';

class MeasurementsChartWidget extends StatefulWidget {
  final int selectedPeriod;

  const MeasurementsChartWidget({
    Key? key,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<MeasurementsChartWidget> createState() =>
      _MeasurementsChartWidgetState();
}

class _MeasurementsChartWidgetState extends State<MeasurementsChartWidget> {
  String _selectedMeasurement = 'weight';
  List<Map<String, dynamic>> _measurements = [];
  bool _isLoading = true;
  Map<String, dynamic>? _progressData;

  final Map<String, Map<String, dynamic>> measurementTypes = {
    'weight': {
      'label': 'Peso',
      'unit': 'kg',
      'icon': 'monitor_weight',
      'color': AppTheme.accentGold
    },
    'body_fat': {
      'label': 'Gordura Corporal',
      'unit': '%',
      'icon': 'fitness_center',
      'color': AppTheme.warningAmber
    },
    'muscle_mass': {
      'label': 'Massa Muscular',
      'unit': 'kg',
      'icon': 'accessibility',
      'color': AppTheme.successGreen
    },
    'waist': {
      'label': 'Cintura',
      'unit': 'cm',
      'icon': 'straighten',
      'color': Colors.purple
    },
  };

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  @override
  void didUpdateWidget(MeasurementsChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadMeasurements();
    }
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: widget.selectedPeriod));

      final measurementsData =
      await ProgressService.instance.getUserMeasurements(
        measurementType: _selectedMeasurement,
        startDate: startDate,
        endDate: endDate,
        limit: 30,
      );

      final progressData =
      await ProgressService.instance.getMeasurementProgress(
        measurementType: _selectedMeasurement,
        daysPeriod: widget.selectedPeriod,
      );

      if (mounted) {
        setState(() {
          _measurements = measurementsData;
          _progressData = progressData;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMeasurementTypeChanged(String type) {
    setState(() => _selectedMeasurement = type);
    _loadMeasurements();
  }

  void _showAddMeasurementDialog() {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        title: Text(
          'Adicionar ${measurementTypes[_selectedMeasurement]!['label']}',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText:
                'Valor (${measurementTypes[_selectedMeasurement]!['unit']})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.accentGold, width: 2),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: notesController,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.accentGold, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(valueController.text);
              if (value != null) {
                try {
                  await ProgressService.instance.recordMeasurement(
                    measurementType: _selectedMeasurement,
                    value: value,
                    unit: measurementTypes[_selectedMeasurement]!['unit'],
                    notes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );

                  Navigator.pop(context);
                  _loadMeasurements();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dado salvo com sucesso'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Falha ao salvar dado'),
                      backgroundColor: AppTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ========= Helpers para o chart =========
  double _safeInterval(double diff, {double fallback = 1}) {
    final v = diff / 4;
    return v > 0 ? v : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          _buildMeasurementSelector(),
          SizedBox(height: 3.h),
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: AppTheme.accentGold))
          else ...[
            _buildProgressSummary(),
            SizedBox(height: 3.h),
            _buildChart(),
            SizedBox(height: 3.h),
            _buildRecentMeasurements(),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementSelector() {
    return Container(
      height: 12.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: measurementTypes.length,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemBuilder: (context, index) {
          final key = measurementTypes.keys.elementAt(index);
          final measurement = measurementTypes[key]!;
          final isSelected = key == _selectedMeasurement;

          return GestureDetector(
            onTap: () => _onMeasurementTypeChanged(key),
            child: Container(
              width: 20.w,
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentGold.withValues(alpha: 0.2)
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
                    iconName: measurement['icon'],
                    color:
                    isSelected ? AppTheme.accentGold : measurement['color'],
                    size: 6.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    measurement['label'],
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

  Widget _buildProgressSummary() {
    if (_progressData == null || !(_progressData!['has_data'] ?? false)) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'info',
              color: AppTheme.textSecondary,
              size: 8.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Nenhum dado disponível',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Adicione valores para visualizar seu progresso',
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: _showAddMeasurementDialog,
              icon: Icon(Icons.add, size: 5.w),
              label: Text('Adicionar Dados'),
            ),
          ],
        ),
      );
    }

    final latestValue = _progressData!['latest_value'];
    final change = _progressData!['change'];
    // final changePercentage = _progressData!['change_percentage']; // Não é mais usado
    final isPositive = change > 0;
    final measurement = measurementTypes[_selectedMeasurement]!;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atual ${measurement['label']}',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '${latestValue.toStringAsFixed(1)} ${measurement['unit']}',
                    style:
                    AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // --- INÍCIO DA CORREÇÃO 3 (Card de Resumo) ---
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  // Cor neutra
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: isPositive ? 'trending_up' : 'trending_down',
                      // Cor neutra
                      color: AppTheme.accentGold,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      // Mostra a mudança absoluta (ex: -1.5 kg)
                      '${isPositive ? '+' : ''}${change.toStringAsFixed(1)} ${measurement['unit']}',
                      style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                        // Cor neutra
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // --- FIM DA CORREÇÃO 3 ---
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddMeasurementDialog,
                  icon: Icon(Icons.add, size: 4.w),
                  label: Text('Adicionar Dados'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_measurements.isEmpty) {
      return Container(
        height: 25.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'show_chart',
                color: AppTheme.inactiveGray,
                size: 10.w,
              ),
              SizedBox(height: 2.h),
              Text(
                'No chart data available',
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- INÍCIO DA CORREÇÃO 1 (Inverter Eixo X) ---
    // Inverte a lista para que o mais antigo seja o índice 0 (esquerda)
    final spots = _measurements.reversed.toList().asMap().entries.map((entry) {
      // --- FIM DA CORREÇÃO 1 ---
      final index = entry.key;
      final measurement = entry.value;
      final value = (measurement['value'] as num).toDouble();
      return FlSpot(index.toDouble(), value);
    }).toList();

    final measurement = measurementTypes[_selectedMeasurement]!;

    // ====== cálculo seguro de min/max/range/padding ======
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      // evita range zero quando só há um valor (ou todos iguais)
      minY -= 1;
      maxY += 1;
    }

    final range = maxY - minY;
    final padding = range * 0.1;

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
            '${measurement['label']} Trend',
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
                  horizontalInterval: _safeInterval(range, fallback: 1),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.dividerGray,
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
                      // O intervalo dinâmico aqui está bom
                      interval: spots.length > 5
                          ? (spots.length / 5).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        // --- CORREÇÃO 1 (Continuação) ---
                        // A lista de spots agora está invertida, então _measurements também precisa ser acessada com a lista invertida
                        final invertedMeasurements = _measurements.reversed.toList();
                        if (index >= 0 && index < invertedMeasurements.length) {
                          final date = DateTime.parse(
                              invertedMeasurements[index]['measured_at']);
                          // --- FIM DA CORREÇÃO 1 (Continuação) ---
                          return Text(
                            '${date.day}/${date.month}',
                            style: AppTheme.darkTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  // --- INÍCIO DA CORREÇÃO 2 (Eixo Y Limpo) ---
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      // Força o intervalo a ser de 1.0 (ex: 68.0, 69.0)
                      interval: 1.0,
                      getTitlesWidget: (value, meta) {
                        // Não desenha o label do topo/base para um visual mais limpo
                        if (value == meta.max || value == meta.min) {
                          return const Text('');
                        }

                        return Text(
                          // Mostra uma casa decimal (ex: 68.5)
                          value.toStringAsFixed(1),
                          style:
                          AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  // --- FIM DA CORREÇÃO 2 ---
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.length.toDouble() - 1,
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: measurement['color'],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: (measurement['color'] as Color)
                          .withValues(alpha: 0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: measurement['color'],
                          strokeWidth: 2,
                          strokeColor: AppTheme.cardDark,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeasurements() {
    // A lista _measurements original (não invertida) ainda funciona
    // perfeitamente aqui, pois ela já vem com os mais recentes primeiro.
    final recentMeasurements = _measurements.take(5).toList();
    final measurement = measurementTypes[_selectedMeasurement]!;

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
                iconName: 'history',
                color: AppTheme.accentGold,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Dados Recentes',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (recentMeasurements.isEmpty)
            Center(
              child: Text(
                'Sem dados salvos',
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            ...recentMeasurements.map((measurementData) {
              final value = (measurementData['value'] as num).toDouble();
              final measuredAt = DateTime.parse(measurementData['measured_at']);
              final notes = measurementData['notes'] as String?;

              final timeAgo = _getTimeAgo(measuredAt);

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
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: (measurement['color'] as Color)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: measurement['icon'],
                        color: measurement['color'],
                        size: 4.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${value.toStringAsFixed(1)} ${measurement['unit']}',
                            style: AppTheme.darkTheme.textTheme.bodyLarge
                                ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (notes != null && notes.isNotEmpty) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              notes,
                              style: AppTheme.darkTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    // A correção de fuso horário foi aplicada no ProgressService,
    // então o DateTime.parse() irá funcionar corretamente e
    // esta função agora exibirá "Agora" ou "Xm atrás"
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}