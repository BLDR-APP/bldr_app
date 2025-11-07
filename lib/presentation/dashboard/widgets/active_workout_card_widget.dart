import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import '../../../services/workout_service.dart';

class ActiveWorkoutCardWidget extends StatefulWidget {
  final VoidCallback onStartPressed;

  const ActiveWorkoutCardWidget({
    Key? key,
    required this.onStartPressed,
  }) : super(key: key);

  @override
  State<ActiveWorkoutCardWidget> createState() =>
      _ActiveWorkoutCardWidgetState();
}

class _ActiveWorkoutCardWidgetState extends State<ActiveWorkoutCardWidget> {
  Map<String, dynamic>? activeWorkout;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadActiveWorkout();
  }

  Future<void> _loadActiveWorkout() async {
    try {
      // Check if user is authenticated first
      if (!AuthService.instance.isAuthenticated) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = false;
          });
        }
        return;
      }

      // Get user's most recent incomplete workout
      final workouts = await WorkoutService.instance.getUserWorkouts(
        completedOnly: false,
        limit: 1,
      );

      if (mounted) {
        setState(() {
          activeWorkout =
              workouts.isNotEmpty && workouts.first['is_completed'] == false
                  ? workouts.first
                  : null;
          isLoading = false;
          hasError = false;
        });
      }
    } catch (error) {
      debugPrint('Erro ao carregar treino ativo: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  String _formatDuration(DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard();
    }

    if (hasError) {
      return _buildErrorCard();
    }

    if (!AuthService.instance.isAuthenticated) {
      return _buildUnauthenticatedCard();
    }

    return activeWorkout != null
        ? _buildActiveWorkoutCard()
        : _buildStartWorkoutCard();
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      height: 20.h,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerGray,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.accentGold,
              strokeWidth: 2,
            ),
            SizedBox(height: 2.h),
            Text(
              'Carregando seu treino...',
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'warning',
                  color: AppTheme.warningAmber,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unable to load workouts',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Check your connection and try again',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadActiveWorkout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentGold,
                side: BorderSide(color: AppTheme.accentGold, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.accentGold,
                size: 4.w,
              ),
              label: Text(
                'Try Again',
                style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'fitness_center',
                  color: AppTheme.accentGold,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem vindo ao BLDR',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Entre para acompanhar seus treinos',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.loginScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.primaryBlack,
                padding: EdgeInsets.symmetric(vertical: 4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: CustomIconWidget(
                iconName: 'login',
                color: AppTheme.primaryBlack,
                size: 5.w,
              ),
              label: Text(
                'Entrar',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkoutCard() {
    final workout = activeWorkout!;
    final startTime = DateTime.parse(workout['started_at']);
    final workoutName = workout['name'] as String? ?? 'Workout';
    final templateName = workout['workout_templates'] != null
        ? workout['workout_templates']['name'] as String?
        : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.2),
            AppTheme.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'fitness_center',
                  color: AppTheme.primaryBlack,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treino em andamento',
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      workoutName,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (templateName != null)
                      Text(
                        templateName,
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Workout Duration
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.dividerGray,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'timer',
                      color: AppTheme.accentGold,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _formatDuration(startTime),
                      style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Resume workout feature coming soon'),
                        backgroundColor: AppTheme.warningAmber,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGold,
                    side: BorderSide(color: AppTheme.accentGold, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: CustomIconWidget(
                    iconName: 'play_arrow',
                    color: AppTheme.accentGold,
                    size: 4.w,
                  ),
                  label: Text(
                    'Resumir',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCompleteWorkoutDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: AppTheme.textPrimary,
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: CustomIconWidget(
                    iconName: 'check',
                    color: AppTheme.textPrimary,
                    size: 4.w,
                  ),
                  label: Text(
                    'Completo',
                    style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartWorkoutCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'fitness_center',
                  color: AppTheme.accentGold,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pronto para treinar?',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Começar próxima sessão',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Start Workout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onStartPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.primaryBlack,
                padding: EdgeInsets.symmetric(vertical: 4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: CustomIconWidget(
                iconName: 'play_arrow',
                color: AppTheme.primaryBlack,
                size: 5.w,
              ),
              label: Text(
                'Inicar Treino',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        title: Text(
          'Finalizar Treino',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Você tem certeza que quer completar seu treino atual?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await WorkoutService.instance.completeWorkout(
                  workoutId: activeWorkout!['id'],
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Treino finalizado com sucesso!'),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                // Refresh the card
                _loadActiveWorkout();
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao finalizar treino: $error'),
                    backgroundColor: AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: AppTheme.textPrimary,
            ),
            child: Text('Completar'),
          ),
        ],
      ),
    );
  }
}
