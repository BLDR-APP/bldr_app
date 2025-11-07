import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/achievements_gallery_widget.dart';
import './widgets/export_progress_widget.dart';
import './widgets/goal_tracking_widget.dart';
import './widgets/measurements_chart_widget.dart';
import './widgets/nutrition_analytics_widget.dart';
import './widgets/photo_progress_widget.dart';
import './widgets/progress_overview_widget.dart';
import './widgets/workout_progress_widget.dart';

// ADIÇÕES ↓↓↓
import '../../services/oura_api_service.dart';
import './widgets/daily_sleep_overview_widget.dart';
// ADIÇÕES ↑↑↑

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedPeriod = '30';
  TabController? _tabController;

  // ===== Sono (Oura) =====
  DateTime _sleepDate = DateTime.now();
  Map<String, dynamic>? _sleep; // daily_sleep[0] do Oura
  bool _sleepLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Carrega tudo em paralelo
    Future.wait([
      _loadProgressData(),
      _loadSleep(),
    ]);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);

    try {
      // Substitua pelo carregamento real dos seus dados de progresso
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao carregar dados do progresso'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== Carregar sono da Oura para o dia selecionado =====
  Future<void> _loadSleep() async {
    setState(() => _sleepLoading = true);
    try {
      final json = await OuraApiService.instance.getDailySleep(day: _sleepDate);
      final list = (json['data'] as List?) ?? [];
      _sleep = list.isNotEmpty ? Map<String, dynamic>.from(list.first) : null;
    } catch (_) {
      _sleep = null; // silencioso
    } finally {
      if (mounted) setState(() => _sleepLoading = false);
    }
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    // Mantemos o sono por data escolhida; período afeta só análises gerais.
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadProgressData(),
      _loadSleep(),
    ]);
  }

  Future<void> _pickSleepDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sleepDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentGold,
              surface: AppTheme.cardDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _sleepDate = date);
      await _loadSleep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: Text('Progresso'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showExportOptions,
            icon: Icon(
              Icons.file_download_outlined,
              color: AppTheme.textPrimary,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _onPeriodChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: '7', child: Text('Últimos 7 dias')),
              PopupMenuItem(value: '30', child: Text('Últimos 30 dias')),
              PopupMenuItem(value: '90', child: Text('Últimos 3 meses')),
              PopupMenuItem(value: '365', child: Text('Último ano')),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              margin: EdgeInsets.only(right: 2.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerGray),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedPeriod}D',
                    style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  CustomIconWidget(
                    iconName: 'keyboard_arrow_down',
                    color: AppTheme.textSecondary,
                    size: 4.w,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.accentGold,
        backgroundColor: AppTheme.cardDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              // Resumo geral
              ProgressOverviewWidget(
                selectedPeriod: int.parse(_selectedPeriod),
              ),

              SizedBox(height: 3.h),

              // ==== SEÇÃO: SONO (Oura) ====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _buildSleepSection(),
              ),

              SizedBox(height: 3.h),

              _buildTabSection(),
              SizedBox(height: 2.h),
              SizedBox(
                height: 60.h,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorkoutTab(),
                    _buildMeasurementsTab(),
                    _buildNutritionTab(),
                    _buildAchievementsTab(),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              GoalTrackingWidget(
                selectedPeriod: int.parse(_selectedPeriod),
              ),
              SizedBox(height: 3.h),
              PhotoProgressWidget(),
              SizedBox(height: 15.h), // espaço para navegação
            ],
          ),
        ),
      ),
    );
  }

  // ====== UI helpers ======

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 3),
          SizedBox(height: 3.h),
          Text(
            'Carregando dados do progresso...',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.accentGold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: AppTheme.accentGold,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Treinos'),
          Tab(text: 'Corpo'),
          Tab(text: 'Nutrição'),
          Tab(text: 'Badges'),
        ],
      ),
    );
  }

  // === Seção do Sono (header + date picker + card) ===
  Widget _buildSleepSection() {
    // Converte JSON em métricas do widget (seguindo sua tela de Nutrição)
    final int totalSleepMin =
        ((_sleep?['total_sleep_duration'] ?? 0) as num).round() ~/ 60;
    final int? sleepScore =
    _sleep?['score'] != null ? (_sleep!['score'] as num).round() : null;
    final int? restingHr = _sleep?['resting_heart_rate'] != null
        ? (_sleep!['resting_heart_rate'] as num).round()
        : null;
    final int? hrv = _sleep?['average_hrv'] != null
        ? (_sleep!['average_hrv'] as num).round()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com seletor de data
        Row(
          children: [
            Text(
              'Sono',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _pickSleepDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerGray),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sleepDate.day == DateTime.now().day &&
                          _sleepDate.month == DateTime.now().month &&
                          _sleepDate.year == DateTime.now().year
                          ? 'Hoje'
                          : '${_sleepDate.day}/${_sleepDate.month}',
                      style:
                      AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    CustomIconWidget(
                      iconName: 'calendar_today',
                      color: AppTheme.textSecondary,
                      size: 4.w,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),

        // Loader do card de sono
        if (_sleepLoading)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerGray.withAlpha(77)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18.w,
                  height: 6.h,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Carregando sono...',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
        // Card de sono (mesmo widget que estava na Nutrição)
          DailySleepOverviewWidget(
            selectedDate: _sleepDate,
            totalSleepMin: totalSleepMin,
            score: sleepScore,
            restingHr: restingHr,
            hrv: hrv,
          ),
      ],
    );
  }

  Widget _buildWorkoutTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: WorkoutProgressWidget(selectedPeriod: int.parse(_selectedPeriod)),
    );
  }

  Widget _buildMeasurementsTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: MeasurementsChartWidget(
        selectedPeriod: int.parse(_selectedPeriod),
      ),
    );
  }

  Widget _buildNutritionTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: NutritionAnalyticsWidget(
        selectedPeriod: int.parse(_selectedPeriod),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: AchievementsGalleryWidget(),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ExportProgressWidget(
        onExport: (format) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exportando relatório do progresso como $format...'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
