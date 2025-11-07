import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/progress_service.dart';
import '../../../services/workout_service.dart';
import '../../../services/club_workouts_service.dart'; // Importe seu serviço do clube

class WorkoutProgressWidget extends StatefulWidget {
  final int selectedPeriod;

  const WorkoutProgressWidget({Key? key, required this.selectedPeriod})
      : super(key: key);

  @override
  State<WorkoutProgressWidget> createState() => _WorkoutProgressWidgetState();
}

class _WorkoutProgressWidgetState extends State<WorkoutProgressWidget> {
  Map<String, dynamic>? _workoutProgress;
  List<Map<String, dynamic>> _recentWorkouts = [];
  List<Map<String, dynamic>> _workoutHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  @override
  void didUpdateWidget(WorkoutProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadWorkoutData();
    }
  }

  Future<void> _loadWorkoutData() async {
    setState(() => _isLoading = true);

    try {
      final workoutProgressData = await ProgressService.instance
          .getWorkoutProgress(daysPeriod: widget.selectedPeriod);

      // --- CORREÇÃO AQUI ---
      // Chamando as funções com os nomes corretos que você já tem
      final results = await Future.wait([
        WorkoutService.instance.getUserWorkouts(limit: 50),
        ClubWorkoutsService.instance.getClubUserWorkouts(limit: 50),
      ]);
      // --- FIM DA CORREÇÃO ---

      final regularWorkouts = List<Map<String, dynamic>>.from(results[0]);
      final clubWorkouts = List<Map<String, dynamic>>.from(results[1]);

      final allWorkouts = [...regularWorkouts, ...clubWorkouts];

      allWorkouts.sort((a, b) {
        final dateAString = a['completed_at'] ?? a['started_at'];
        final dateBString = b['completed_at'] ?? b['started_at'];
        final dateA = dateAString != null ? DateTime.tryParse(dateAString) : null;
        final dateB = dateBString != null ? DateTime.tryParse(dateBString) : null;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      final recentWorkoutsData = allWorkouts.take(5).toList();
      final workoutHistoryData = _getWorkoutHistory(allWorkouts);

      if (mounted) {
        setState(() {
          _workoutProgress = workoutProgressData;
          _recentWorkouts = recentWorkoutsData;
          _workoutHistory = workoutHistoryData;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Erro ao carregar dados dos treinos: $error');
      }
    }
  }

  List<Map<String, dynamic>> _getWorkoutHistory(List<Map<String, dynamic>> allWorkouts) {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final filteredWorkouts = allWorkouts.where((workout) {
        final workoutDateString = workout['started_at'] ?? workout['completed_at'];
        if (workoutDateString == null) return false;
        final workoutDate = DateTime.parse(workoutDateString);
        return workoutDate.isAfter(startDate) && workoutDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      final Map<int, int> dailyCounts = { for (int i = 0; i < 7; i++) i: 0 };

      for (final workout in filteredWorkouts) {
        final workoutDate = DateTime.parse(workout['started_at'] ?? workout['completed_at']);
        final dayIndex = 6 - endDate.difference(workoutDate).inDays;
        if (dayIndex >= 0 && dayIndex < 7 && (workout['is_completed'] ?? false)) {
          dailyCounts[dayIndex] = (dailyCounts[dayIndex] ?? 0) + 1;
        }
      }

      return List.generate(
        7,
            (index) => {
          'day': index,
          'workouts': dailyCounts[index] ?? 0,
          'date': endDate.subtract(Duration(days: 6 - index)),
        },
      );
    } catch (error) {
      print('Erro ao gerar histórico de treinos: $error');
      return List.generate(
        7,
            (index) => {
          'day': index,
          'workouts': 0,
          'date': DateTime.now().subtract(Duration(days: 6 - index)),
        },
      );
    }
  }

  // O resto do código (build, _buildWorkoutChart, etc.) permanece exatamente o mesmo
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    final completedWorkouts = _workoutProgress?['completed_workouts'] ?? 0;
    final totalWorkouts = _workoutProgress?['total_workouts'] ?? 0;
    final avgDuration =
        _workoutProgress?['average_workout_duration_minutes'] ?? 0;
    final totalTime = _workoutProgress?['total_workout_time_hours'] ?? '0.0';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          _buildWorkoutChart(),
          SizedBox(height: 3.h),
          _buildStatsGrid(
            completedWorkouts,
            totalWorkouts,
            avgDuration,
            totalTime,
          ),
          SizedBox(height: 3.h),
          _buildRecentWorkouts(),
        ],
      ),
    );
  }

  Widget _buildWorkoutChart() {
    final spots = _generateWorkoutSpots();

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
                iconName: 'show_chart',
                color: AppTheme.accentGold,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Frequência de Treinos',
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 25.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppTheme.dividerGray, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1.0, // <-- Correção anterior
                      // --- INÍCIO DA CORREÇÃO DAS INICIAIS ---
                      getTitlesWidget: (value, meta) {
                        final int index = value.toInt();

                        // Garante que o índice esteja dentro dos limites
                        if (index < 0 || index >= _workoutHistory.length) {
                          return const Text('');
                        }

                        // Pega a data de dentro dos dados do histórico
                        final DateTime date = _workoutHistory[index]['date'];

                        // Mapeia o 'weekday' (Seg=1, Dom=7) para as iniciais em PT-BR
                        final List<String> dayInitials = [
                          'S', // Segunda
                          'T', // Terça
                          'Q', // Quarta
                          'Q', // Quinta
                          'S', // Sexta
                          'S', // Sábado
                          'D'  // Domingo
                        ];

                        // date.weekday - 1 converte o dia da semana para um índice
                        final String initial = dayInitials[date.weekday - 1];

                        return Text(
                          initial, // Usa a inicial dinâmica
                          style: AppTheme.darkTheme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        );
                      },
                      // --- FIM DA CORREÇÃO DAS INICIAIS ---
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          value.toInt().toString(),
                          style: AppTheme.darkTheme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: _getMaxWorkouts().toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.accentGold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentGold.withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.accentGold,
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

  List<FlSpot> _generateWorkoutSpots() {
    if (_workoutHistory.isEmpty) {
      return List.generate(7, (index) => FlSpot(index.toDouble(), 0));
    }

    return _workoutHistory.map((data) {
      return FlSpot(
        (data['day'] as int).toDouble(),
        (data['workouts'] as int).toDouble(),
      );
    }).toList();
  }

  int _getMaxWorkouts() {
    if (_workoutHistory.isEmpty) return 4;

    final maxWorkouts = _workoutHistory
        .map((data) => data['workouts'] as int)
        .reduce((a, b) => a > b ? a : b);
    return maxWorkouts > 0 ? maxWorkouts + 1 : 4;
  }

  Widget _buildStatsGrid(
      int completed,
      int total,
      int avgDuration,
      String totalTime,
      ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Completos',
            completed.toString(),
            AppTheme.successGreen,
            'check_circle',
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            'Duração Média',
            '${avgDuration}m',
            AppTheme.warningAmber,
            'schedule',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      Color color,
      String iconName,
      ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 5.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkouts() {
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
                'Treinos Recentes',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (_recentWorkouts.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  CustomIconWidget(
                    iconName: 'fitness_center',
                    color: AppTheme.inactiveGray,
                    size: 10.w,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Ainda sem treinos',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            )
          else
            ..._recentWorkouts
                .take(3)
                .map((workout) => _buildWorkoutItem(workout)),
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(Map<String, dynamic> workout) {
    final name = workout['name'] ?? 'Treino Desconhecido';
    final completedAt = workout['completed_at'];
    final duration = workout['total_duration_seconds'];

    String timeAgo = 'Recentemente';
    if (completedAt != null) {
      final date = DateTime.parse(completedAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) {
        timeAgo = 'Hoje';
      } else if (difference.inDays == 1) {
        timeAgo = 'Ontem';
      } else {
        timeAgo = '${difference.inDays}d atrás';
      }
    }

    String durationText = '';
    if (duration != null) {
      final minutes = (duration / 60).round();
      durationText = '${minutes}min';
    }

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
              color: AppTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.successGreen,
              size: 4.w,
            ),
          ),
          SizedBox(width: 3.w),
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
                if (durationText.isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    durationText,
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
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
  }
}