import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_error_widget.dart';
import './widgets/active_workout_banner_widget.dart';
import './widgets/exercise_categories_widget.dart';
import './widgets/featured_workouts_widget.dart';
import './widgets/workout_card_widget.dart';
import './widgets/workout_search_bar_widget.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  List<Map<String, dynamic>> _workoutTemplates = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredWorkouts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  String? _selectedType;
  int? _selectedDifficulty;
  bool _hasActiveWorkout = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!_isLoading) setState(() => _isLoading = true);

      final workouts =
      await WorkoutService.instance.getWorkoutTemplates(publicOnly: true);
      final exercises = await ExerciseService.instance.getExercises();

      final bool isActive = await WorkoutService.instance.hasActiveWorkout();

      if (!mounted) return;
      setState(() {
        _workoutTemplates = (workouts ?? []).cast<Map<String, dynamic>>();
        _exercises = (exercises ?? []).cast<Map<String, dynamic>>();
        _filteredWorkouts = _workoutTemplates;
        _hasActiveWorkout = isActive; // sem checagem automática
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _filterWorkouts() {
    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      _filteredWorkouts = _workoutTemplates.where((workout) {
        final name = (workout['name'] ?? '').toString().toLowerCase();
        final desc = (workout['description'] ?? '').toString().toLowerCase();
        final type = workout['workout_type']?.toString();

        final levelRaw = workout['difficulty_level'];
        final levelInt =
        (levelRaw is int) ? levelRaw : int.tryParse(levelRaw?.toString() ?? '');

        final matchesSearch =
            query.isEmpty || name.contains(query) || desc.contains(query);
        final matchesType = _selectedType == null || type == _selectedType;
        final matchesDifficulty =
            _selectedDifficulty == null || levelInt == _selectedDifficulty;

        return matchesSearch && matchesType && matchesDifficulty;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterWorkouts();
  }

  void _onTypeFilter(String? type) {
    setState(() {
      _selectedType = type;
    });
    _filterWorkouts();
  }

  void _onDifficultyFilter(int? difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    _filterWorkouts();
  }

  void _startWorkout(Map<String, dynamic> workoutTemplate) async {
    try {
      await WorkoutService.instance.startWorkout(
        name: workoutTemplate['name'],
        workoutTemplateId: workoutTemplate['id'],
      );

      if (!mounted) return;
      setState(() {
        _hasActiveWorkout = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Treino iniciado: ${workoutTemplate['name']}'),
          backgroundColor: AppTheme.accentGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Falha ao iniciar treino'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _viewWorkoutDetails(Map<String, dynamic> workoutTemplate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.only(left: 38.w, bottom: 3.h),
                decoration: BoxDecoration(
                  color: AppTheme.dividerGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                workoutTemplate['name'],
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              if (workoutTemplate['description'] != null)
                Text(
                  workoutTemplate['description'],
                  style: AppTheme.darkTheme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
              SizedBox(height: 3.h),
              Row(children: [
                _buildInfoChip(
                    '${workoutTemplate['estimated_duration_minutes']} min',
                    Icons.schedule),
                SizedBox(width: 2.w),
                _buildInfoChip(
                    'Nível ${workoutTemplate['difficulty_level']}',
                    Icons.trending_up),
                SizedBox(width: 2.w),
                _buildInfoChip(
                    (workoutTemplate['workout_type'] ?? '')
                        .toString()
                        .replaceAll('_', ' '),
                    Icons.category),
              ]),
              SizedBox(height: 3.h),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: WorkoutService.instance
                      .getWorkoutTemplateWithExercises(workoutTemplate['id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Erro ao carregar exercícios',
                        style: AppTheme.darkTheme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.errorRed),
                      );
                    }

                    final data = snapshot.data ?? {};
                    final List exercises =
                        (data['workout_template_exercises'] as List?) ?? const [];

                    if (exercises.isEmpty) {
                      return Text(
                        'Nenhum exercício neste treino.',
                        style: AppTheme.darkTheme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                      itemBuilder: (context, index) {
                        final row = (exercises[index] as Map).cast<String, dynamic>();
                        final ex  = (row['exercises'] as Map?)?.cast<String, dynamic>() ?? const {};
                        final name = ex['name'] ?? 'Exercise';

                        return Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dividerGray),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.5.w),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.dividerGray),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 5.w,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTheme.darkTheme.textTheme.bodyLarge
                                          ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 0.3.h),
                                    Text(
                                      'Sets: ${row['sets'] ?? '-'}'
                                          '${row['reps'] != null ? ' · Reps: ${row['reps']}' : ''}'
                                          '${row['duration_seconds'] != null ? ' · ' : ''}'
                                          '${row['duration_seconds'] != null ? '${row['duration_seconds']}s' : ''}',
                                      style: AppTheme.darkTheme.textTheme.bodySmall
                                          ?.copyWith(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '#${row['order_index'] ?? index + 1}',
                                style: AppTheme.darkTheme.textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 2.h),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startWorkout(workoutTemplate);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Iniciar Treino',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 4.w, color: AppTheme.accentGold),
          SizedBox(width: 1.w),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentGold)),
      );
    }

    if (_hasError) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(child: CustomErrorWidget()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // PARTE 1: A BARRA DE BUSCA FICA FIXA NO TOPO
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: WorkoutSearchBarWidget(
                onSearchChanged: _onSearchChanged,
                onTypeFilter: _onTypeFilter,
                onDifficultyFilter: _onDifficultyFilter,
                selectedType: _selectedType,
                selectedDifficulty: _selectedDifficulty,
              ),
            ),
            // PARTE 2: O RESTO DO CONTEÚDO FICA NUMA ÁREA ROLÁVEL
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.accentGold,
                backgroundColor: AppTheme.cardDark,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    if (_hasActiveWorkout)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
                        sliver: const SliverToBoxAdapter(
                          child: ActiveWorkoutBannerWidget(),
                        ),
                      ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
                      sliver: SliverToBoxAdapter(
                        child: FeaturedWorkoutsWidget(
                          workouts: _filteredWorkouts.take(3).toList(),
                          onWorkoutTap: _viewWorkoutDetails,
                          onStartWorkout: _startWorkout,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
                      sliver: SliverToBoxAdapter(
                        child: ExerciseCategoriesWidget(
                          exercises: _exercises,
                          onCategoryTap: (category) {
                            _onTypeFilter(category);
                          },
                        ),
                      ),
                    ),
                    if (_filteredWorkouts.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nenhum treino encontrado', style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                              SizedBox(height: 1.5.h),
                              Text('Tente ajustar os filtros ou limpar a busca.', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                              SizedBox(height: 2.h),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedType = null;
                                    _selectedDifficulty = null;
                                    _filteredWorkouts = _workoutTemplates;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentGold,
                                  foregroundColor: AppTheme.primaryBlack,
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Limpar filtros'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final workout = _filteredWorkouts[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 2.h),
                                child: WorkoutCardWidget(
                                  workout: workout,
                                  onTap: () => _viewWorkoutDetails(workout),
                                  onStart: () => _startWorkout(workout),
                                ),
                              );
                            },
                            childCount: _filteredWorkouts.length,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}