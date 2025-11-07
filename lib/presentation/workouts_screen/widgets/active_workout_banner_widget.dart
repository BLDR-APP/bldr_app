// Salve este arquivo: lib/presentation/workouts_screen/widgets/active_workout_banner_widget.dart
// (Código final com Notificação Local + Vibração)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vibration/vibration.dart'; // <-- 1. IMPORT DA VIBRAÇÃO

import '../../../core/app_export.dart';
import '../../../services/workout_service.dart';

import '../../../models/exercise_model.dart';
import '../../../services/exercise_db_service.dart';
import '../../../services/notification_service.dart'; // <-- 2. IMPORT DO SERVIÇO DE NOTIFICAÇÃO

class ActiveWorkoutBannerWidget extends StatefulWidget {
  const ActiveWorkoutBannerWidget({Key? key}) : super(key: key);

  @override
  State<ActiveWorkoutBannerWidget> createState() =>
      _ActiveWorkoutBannerWidgetState();
}

class _ActiveWorkoutBannerWidgetState extends State<ActiveWorkoutBannerWidget>
    with SingleTickerProviderStateMixin {
  // anima do chip atual
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // stream/state
  Map<String, dynamic>? _activeWorkout;
  bool _hideBanner = false;

  StreamSubscription? _workoutSubscription;
  String? _lastDataHash;

  // cronômetro do treino
  Timer? _ticker;
  bool _isPaused = false;
  int _elapsedSeconds = 0;

  // descanso fixo
  static const int _restFixedSeconds = 50;
  bool _isResting = false;
  int _restRemaining = 0;
  Timer? _restTimer;

  // set/exercício atual
  int? _currentSetIndex;
  String? _currentSetId;
  String? _currentExerciseName; // O nome em PT do Supabase

  int _currentExerciseSetsTotal = 0;
  int _currentExerciseSetsCompleted = 0;

  // UI
  bool _expanded = true;
  bool _completingSet = false;
  final _scrollCtrl = ScrollController();

  // Serviços
  final ExerciseDbService _exerciseDbService = ExerciseDbService();
  final NotificationService _notificationService = NotificationService(); // <-- 3. INSTÂNCIA DO SERVIÇO

  // Cache (Opção 2)
  String? _currentWorkoutIdForCache;
  bool _isPrefetching = false;
  Map<String, ExerciseDetail> _exerciseCache = {};
  ExerciseDetail? _currentExerciseDetail;
  String? _currentExerciseDbId;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.repeat(reverse: true);
    _startTicker();

    _workoutSubscription =
        WorkoutService.instance.activeWorkoutStream().listen(_onWorkoutDataReceived);

    // Garante que qualquer notificação pendente seja cancelada ao abrir o banner
    _notificationService.cancelRestNotification();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    _workoutSubscription?.cancel();
    super.dispose();
  }

  // Orquestra o pré-carregamento
  void _onWorkoutDataReceived(Map<String, dynamic>? data) {
    if (!mounted) return;

    if (data == null) {
      if (_activeWorkout != null) {
        setState(() {
          _activeWorkout = null;
          _lastDataHash = null;
          _currentWorkoutIdForCache = null;
          _exerciseCache = {};
          _currentExerciseDetail = null;
        });
      }
      return;
    }

    final String newDataHash = jsonEncode(data);
    if (newDataHash == _lastDataHash) {
      return;
    }

    _lastDataHash = newDataHash;
    _activeWorkout = data;

    final newWorkoutId = data['id'] as String?;

    if (newWorkoutId != null && newWorkoutId != _currentWorkoutIdForCache) {
      print("ATIVO BANNER: Novo treino detectado. Iniciando pré-carregamento...");
      _currentWorkoutIdForCache = newWorkoutId;
      _exerciseCache = {};
      _currentExerciseDetail = null;

      setState(() {
        _isPrefetching = true;
      });

      _prefetchAllExerciseData(data);
    }

    if (!_isResting) {
      _resolveCurrentSet(data);
    }
  }

  // Função de Pré-carregamento (Opção 2) com .trim()
  Future<void> _prefetchAllExerciseData(Map<String, dynamic> workoutData) async {
    print("PREFETCH (DEBUG 1): Iniciando _prefetchAllExerciseData.");

    final allSets = (workoutData['workout_exercise_sets'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];

    if (allSets.isEmpty) {
      if (!mounted) return;
      setState(() => _isPrefetching = false);
      return;
    }

    final Set<String> allDbIds = {};
    for (var set in allSets) {
      final exerciseDetails = (set['exercises'] as Map?) ?? {};
      String? dbId = exerciseDetails['exercise_db_id'] as String?;
      dbId = dbId?.trim();
      if (dbId != null && dbId.isNotEmpty) {
        allDbIds.add(dbId);
      }
    }

    if (allDbIds.isEmpty) {
      if (!mounted) return;
      setState(() => _isPrefetching = false);
      return;
    }

    print("PREFETCH (DEBUG 7): Buscando ${allDbIds.length} IDs na API...");

    final List<ExerciseDetail> fetchedDetails =
    await _exerciseDbService.prefetchAllExercises(allDbIds.toList());

    final newCache = <String, ExerciseDetail>{};
    for (var detail in fetchedDetails) {
      newCache[detail.exerciseId] = detail;
    }

    if (!mounted) return;
    print("PREFETCH (DEBUG 8): Cache construído com ${newCache.length} itens.");

    setState(() {
      _exerciseCache = newCache;
      _isPrefetching = false;
    });

    _resolveCurrentSet(_activeWorkout);
  }


  // ---------------- TIME ----------------
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused || _activeWorkout == null) return;
      _elapsedSeconds = _computeElapsed(_activeWorkout);
      setState(() {});
    });
  }

  int _computeElapsed(Map<String, dynamic>? w) {
    if (w == null) return 0;
    final raw = w['started_at'];
    if (raw == null) return 0;
    try {
      final started = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(started).inSeconds;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}'
        : '$m:${ss.toString().padLeft(2, '0')}';
  }

  int? _plannedMinutes(Map<String, dynamic>? w) {
    final t = (w?['workout_templates'] as Map?) ?? {};
    final m = t['estimated_duration_minutes'];
    if (m == null) return null;
    if (m is int) return m;
    if (m is num) return m.toInt();
    return int.tryParse(m.toString());
  }

  String _plannedOrElapsedText(Map<String, dynamic>? w) {
    final m = _plannedMinutes(w);
    if (m != null && m > 0) return '$m min';
    return _fmt(_elapsedSeconds);
  }

  // --------------- DATA HELPERS ---------------
  bool _isSetDone(Map s) =>
      (s['is_completed'] == true) || (s['completed_at'] != null);

  bool _hasOpenSet(List<Map<String, dynamic>> sets) =>
      sets.any((s) => !_isSetDone(s));

  int _countDone(List<Map<String, dynamic>> sets) =>
      sets.where(_isSetDone).length;

  String _workoutName(Map<String, dynamic>? w) {
    if (w == null) return 'Sem treinos ativos';
    String name = (w['name'] as String?) ?? 'Workout';
    final tmpl = w['workout_templates'];
    final tname = (tmpl is Map ? tmpl['name'] as String? : null);
    if (tname != null && tname.isNotEmpty && tname != name) name = tname;
    return name;
  }

  List<Map<String, dynamic>> _groupByExercise(List sets) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final raw in sets) {
      final s = Map<String, dynamic>.from(raw as Map);
      final ex = (s['exercises'] as Map?) ?? {};

      final n = (ex['name'] as String?) ??
          (s['exercise_id']?.toString() ?? 'Exercício');

      map.putIfAbsent(n, () => []).add(s);
    }
    return map.entries.map((e) => {'name': e.key, 'sets': e.value}).toList();
  }

  // Função que decide qual é a série/exercício atual
  void _resolveCurrentSet(Map<String, dynamic>? workout) {
    if (!mounted) return;

    int? newSetIndex;
    String? newSetId;
    String? supabaseExerciseName; // Nome do Supabase (fallback)
    String? newExerciseDbId; // ID para a API
    int newExerciseSetsTotal = 0;
    int newExerciseSetsCompleted = 0;

    if (workout != null) {
      final allSets = (workout['workout_exercise_sets'] as List?)
          ?.cast<Map<String, dynamic>>() ??
          [];
      if (allSets.isNotEmpty) {

        // CORREÇÃO (BUG ii) - Ordenação correta
        allSets.sort((a, b) {
          final orderA = (a['order_index'] as int?) ?? 999;
          final orderB = (b['order_index'] as int?) ?? 999;
          final orderComparison = orderA.compareTo(orderB);

          if (orderComparison == 0) {
            final numA = (a['set_number'] as int?) ?? 999;
            final numB = (b['set_number'] as int?) ?? 999;
            return numA.compareTo(numB);
          }
          return orderComparison;
        });

        final nextIncompleteSet = allSets.firstWhere(
              (s) => !_isSetDone(s),
          orElse: () => <String, dynamic>{},
        );

        if (nextIncompleteSet.isEmpty) {
          supabaseExerciseName = 'Treino Concluído!';
        } else {
          final exerciseDetails = (nextIncompleteSet['exercises'] as Map?) ?? {};
          // Esta é a fonte da verdade para o NOME (PT-BR)
          supabaseExerciseName = (exerciseDetails['name'] as String?) ??
              (nextIncompleteSet['exercise_id']?.toString() ?? 'N/A');

          newExerciseDbId = exerciseDetails['exercise_db_id'] as String?;
          newExerciseDbId = newExerciseDbId?.trim(); // Limpa o ID

          final currentSetMap = Map<String, dynamic>.from(nextIncompleteSet);

          // Lógica para contar séries do exercício ATUAL
          final setsForCurrentExercise = allSets.where((s) {
            final ex = (s['exercises'] as Map?) ?? {};
            // Compara usando o NOME do Supabase
            final supabaseNameForFilter = (ex['name'] as String?) ?? (s['exercise_id']?.toString() ?? 'N/A');
            return supabaseNameForFilter == supabaseExerciseName;
          }).toList();

          newSetIndex = allSets.indexOf(nextIncompleteSet);
          newSetId = currentSetMap['id']?.toString();
          newExerciseSetsTotal = setsForCurrentExercise.length;
          newExerciseSetsCompleted =
              setsForCurrentExercise.where(_isSetDone).length;
        }
      }
    }

    // CORREÇÃO (Bug de Cache): Lógica simplificada
    _currentExerciseDbId = newExerciseDbId;

    if (newExerciseDbId != null && _exerciseCache.containsKey(newExerciseDbId)) {
      _currentExerciseDetail = _exerciseCache[newExerciseDbId];
    } else {
      _currentExerciseDetail = null;
    }

    setState(() {
      _currentSetIndex = newSetIndex;
      _currentSetId = newSetId;

      // CORREÇÃO (BUG do Nome em PT): Prioriza o nome do Supabase
      _currentExerciseName = supabaseExerciseName ?? _currentExerciseDetail?.name;

      _currentExerciseSetsTotal = newExerciseSetsTotal;
      _currentExerciseSetsCompleted = newExerciseSetsCompleted;
    });
  }

  // --------------- REST ---------------

  // =============================================
  // === ⬇️ MODIFICAÇÃO (Notificação Local) ⬇️ ===
  // =============================================
  void _startRestFixed() {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restRemaining = _restFixedSeconds;
    });

    // 1. Agenda a notificação push (para o caso do app fechar)
    _notificationService.scheduleRestNotification(_restFixedSeconds);

    // 2. Inicia o timer visual (in-app)
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _isPaused) return;
      if (_restRemaining <= 0) {
        _stopRest();
      } else {
        setState(() => _restRemaining -= 1);
      }
    });
  }

  // =============================================
  // === ⬇️ MODIFICAÇÃO (Notificação Local) ⬇️ ===
  // =============================================
  void _stopRest() {
    _restTimer?.cancel();
    _restTimer = null;

    // 1. Cancela a notificação push (porque o usuário está no app)
    _notificationService.cancelRestNotification();

    if (mounted) {
      // 2. Vibra (notificação in-app)
      Vibration.vibrate(duration: 400);

      // 3. Atualiza a UI
      setState(() {
        _isResting = false;
      });
      // 4. Resolve a próxima série
      _resolveCurrentSet(_activeWorkout);
    }
  }


  // --------------- ACTIONS ---------------

  Future<void> _togglePause() async {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      HapticFeedback.selectionClick();
      _ticker?.cancel();
    } else {
      _startTicker();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPaused ? 'Treino pausado' : 'Treino resumido'),
        backgroundColor:
        _isPaused ? AppTheme.warningAmber : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _finalizeWorkoutNow() async {
    if (_activeWorkout == null) return;
    try {
      await WorkoutService.instance.completeWorkout(
        workoutId: _activeWorkout!['id'],
        notes: 'Workout completed from banner',
      );
      if (!mounted) return;
      setState(() {
        _activeWorkout = null;
        _hideBanner = true;
      });
      _stopRest();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao finalizar treino'),
        ),
      );
    }
  }

  Future<void> _confirmAndFinishWorkout() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Finalizar treino?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Tem certeza que deseja finalizar "${_workoutName(_activeWorkout)}"? Todo o seu progresso será salvo.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _finalizeWorkoutNow();
            },
            child:
            Text('Finalizar', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  // CORREÇÃO (BUG ii - Lógica de Pular)
  Future<void> _completeCurrentSet() async {
    if (_activeWorkout == null || _isResting || _completingSet) return;

    String? setIdStr = _currentSetId;
    int? setIndex = _currentSetIndex;
    final setsList = (_activeWorkout!['workout_exercise_sets'] as List?)
        ?.cast<Map<String, dynamic>>() ??
        [];

    if (setIdStr == null || setIndex == null) {
      final idx = setsList.indexWhere((s) => !_isSetDone(s));
      if (idx == -1) return;
      setIndex = idx;
      setIdStr = setsList[idx]['id']?.toString();
    }
    if(setIdStr == null) return;

    _completingSet = true;
    HapticFeedback.selectionClick();

    // Lógica otimista: Atualiza a UI primeiro
    final original = _activeWorkout!;
    final newSets = List<Map<String, dynamic>>.from(setsList);
    newSets[setIndex] = {
      ...newSets[setIndex],
      'is_completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    };

    // Atualiza o estado local do treino
    _activeWorkout = {...original, 'workout_exercise_sets': newSets};

    // 1. Re-calcula a contagem *com* o set que acabamos de marcar
    final setsForCurrentExercise = setsList.where((s) {
      final ex = (s['exercises'] as Map?) ?? {};
      final supabaseName = (ex['name'] as String?) ?? (s['exercise_id']?.toString() ?? 'N/A');
      return supabaseName == _currentExerciseName;
    }).toList();

    final newSetsCompleted = setsForCurrentExercise.where(_isSetDone).length;
    final totalSetsForThis = setsForCurrentExercise.length;

    // 2. Decide se descansa ou avança
    if (newSetsCompleted < totalSetsForThis) {
      // Ainda há séries deste exercício, então apenas descansa
      print("Série $newSetsCompleted/$totalSetsForThis concluída. Iniciando descanso...");
      setState(() {
        _currentExerciseSetsCompleted = newSetsCompleted;
      });
      _startRestFixed();
    } else {
      // Este foi o último set deste exercício, então NÃO descansa
      print("Último set do exercício concluído. Avançando...");
      _resolveCurrentSet(_activeWorkout);
    }
    // FIM DA CORREÇÃO

    try {
      // Salva no banco de dados em segundo plano
      await WorkoutService.instance.completeSet(setId: setIdStr);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Série concluída'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      // Se a chamada ao Supabase falhar, reverte o estado
      _stopRest();
      setState(() {
        _activeWorkout = original;
        _resolveCurrentSet(_activeWorkout);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Falha ao concluir série'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _completingSet = false;
    }
  }

  Future<void> _undoSet(String setId) async {
    try {
      await WorkoutService.instance.undoSet(setId: setId);
    } catch (_) {
      // opcional
    }
  }

  // --------------- UI HELPERS ---------------

  bool _isThisCurrentSet(Map s) =>
      s['id']?.toString() != null && s['id'].toString() == _currentSetId;

  Widget _buildSetChip(Map s) {
    final done = _isSetDone(s);
    final isCurrent = _isThisCurrentSet(s);
    final label = 'S${s['set_number'] ?? s['set_num'] ?? ''}';

    final baseTextStyle = AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.identity()..scale(isCurrent ? _pulse.value : 1.0),
      padding: EdgeInsets.symmetric(vertical: 0.45.h, horizontal: 2.6.w),
      decoration: BoxDecoration(
        color: done
            ? AppTheme.accentGold
            : (isCurrent
            ? AppTheme.accentGold.withValues(alpha: 0.12)
            : AppTheme.surfaceDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppTheme.accentGold
              : (isCurrent ? AppTheme.accentGold : AppTheme.dividerGray),
          width: isCurrent ? 1.6 : 1,
        ),
        boxShadow: isCurrent
            ? [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 0.2,
          ),
        ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrent)
            Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: 1.2.w),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: baseTextStyle?.copyWith(
              color: done ? AppTheme.primaryBlack : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: (!done && isCurrent && !_isResting && !_completingSet)
          ? _completeCurrentSet
          : null,
      onLongPress: done && s['id'] != null
          ? () async {
        HapticFeedback.lightImpact();
        await _undoSet(s['id'].toString());
        final setsList = (_activeWorkout!['workout_exercise_sets'] as List)
            .cast<Map<String, dynamic>>();
        final idx = setsList
            .indexWhere((x) => x['id'].toString() == s['id'].toString());
        if (idx >= 0) {
          final clone = List<Map<String, dynamic>>.from(setsList);
          clone[idx] = {
            ...clone[idx],
            'is_completed': false,
            'completed_at': null,
          };
          setState(() {
            _activeWorkout = {
              ..._activeWorkout!,
              'workout_exercise_sets': clone
            };
            _resolveCurrentSet(_activeWorkout);
          });
        }
      }
          : null,
      child: chip,
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    if (_hideBanner) return const SizedBox.shrink();

    if (_activeWorkout == null) {
      _stopRest();
      return const SizedBox.shrink();
    }

    final bool isCompleted = (_activeWorkout?['is_completed'] as bool?) ?? false;
    if (isCompleted) {
      _stopRest();
      return const SizedBox.shrink();
    }

    _elapsedSeconds = _computeElapsed(_activeWorkout);

    final setsList =
        (_activeWorkout!['workout_exercise_sets'] as List?)
            ?.cast<Map<String, dynamic>>() ??
            [];
    final totalSets = setsList.length;
    final doneSets = _countDone(setsList);
    final progress = totalSets == 0 ? 0.0 : (doneSets / totalSets);

    const canFinish = true;
    final hasOpen = _hasOpenSet(setsList);

    final curCounts = (_currentExerciseName == null ||
        _currentExerciseName == 'Treino Concluído!')
        ? (0, 0)
        : (_currentExerciseSetsCompleted, _currentExerciseSetsTotal);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.20),
            AppTheme.accentGold.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _togglePause,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _isPaused ? AppTheme.warningAmber : AppTheme.accentGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: _isPaused ? 'pause' : 'play_arrow',
                    color: AppTheme.primaryBlack,
                    size: 6.w,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treino Atual',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      _workoutName(_activeWorkout),
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: AppTheme.accentGold,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _plannedOrElapsedText(_activeWorkout),
                          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.6.h),
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isResting)
                      Padding(
                        padding: EdgeInsets.only(top: 0.6.h),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'hourglass_bottom',
                              color: AppTheme.warningAmber,
                              size: 3.6.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Descanso: ${_fmt(_restRemaining)}',
                              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.warningAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: canFinish ? _confirmAndFinishWorkout : null,
                child: Opacity(
                  opacity: canFinish ? 1.0 : 0.5,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorRed),
                    ),
                    child: CustomIconWidget(
                      iconName: 'stop',
                      color: AppTheme.errorRed,
                      size: 5.w,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.6.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'fitness_center',
                color: AppTheme.textSecondary,
                size: 4.w,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  _currentExerciseName ?? 'Carregando...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              finalCounts(curCounts),
            ],
          ),
          SizedBox(height: 0.6.h),

          _buildGifDisplay(),

          SizedBox(height: 1.2.h),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: (!hasOpen || _isResting || _completingSet)
                      ? null
                      : _completeCurrentSet,
                  child: Opacity(
                    opacity: (!hasOpen || _isResting || _completingSet) ? 0.5 : 1.0,
                    child: Container(
                      padding: EdgeInsets.all(2.6.w),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.successGreen),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.successGreen,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Concluir série',
                            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    padding: EdgeInsets.all(2.6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.dividerGray),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: _isPaused ? 'play_arrow' : 'pause',
                          color: AppTheme.textPrimary,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _isPaused ? 'Retomar' : 'Pausar',
                          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (setsList.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 1.4.h),
              child: SizedBox(
                height: 32.h,
                child: _buildExpandedSets(setsList),
              ),
            ),
        ],
      ),
    );
  }

  // NOVO: Widget helper para exibir o GIF
  Widget _buildGifDisplay() {
    return Container(
      width: double.infinity,
      height: 18.h,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      clipBehavior: Clip.antiAlias, // Importante para o Image.network
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildGifContent(), // Lógica de exibição movida para cá
      ),
    );
  }


  // =========================================================================
  // ============= ESTA FUNÇÃO AGORA TEM O PRINT DE DEBUG DO GIF =============
  // =========================================================================

  Widget _buildGifContent() {
    // 1. Estado de Pré-carregamento (Primeira vez que o treino é aberto)
    if (_isPrefetching) {
      print("GIF_DEBUG: Mostrando 'Carregando exercícios...'");
      return Center(
        key: const ValueKey('prefetching'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 2),
            SizedBox(height: 2.h),
            Text(
              'Carregando exercícios...',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
          ],
        ),
      );
    }

    // 2. Estado com GIF (Já está no cache)
    final gifUrl = _currentExerciseDetail?.gifUrl;

    print("GIF_DEBUG: Tentando carregar a URL: $gifUrl");

    if (gifUrl != null && gifUrl.isNotEmpty) {
      return CachedNetworkImage(
        key: ValueKey(gifUrl),
        imageUrl: gifUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGold)),

        errorWidget: (context, url, error) {
          print("GIF_DEBUG (ERRO): Falha ao carregar $url. Erro: $error");
          return _buildGifError('Falha ao carregar GIF');
        },
      );
    }

    // 3. Estado de Treino Concluído
    if (_currentExerciseName == 'Treino Concluído!') {
      print("GIF_DEBUG: Mostrando 'Treino Concluído!'");
      return _buildGifError('Treino Concluído!', icon: Icons.check_circle_outline);
    }

    // 4. Estado de Fallback (Carregando individualmente ou ID nulo)
    print("GIF_DEBUG: Mostrando loading individual (fallback).");
    return Center(
      key: const ValueKey('loading_individual'),
      child: CircularProgressIndicator(
        color: AppTheme.accentGold,
        strokeWidth: 2,
      ),
    );
  }

  // NOVO: Fallback/Erro unificado para o display do GIF
  Widget _buildGifError(String message, {IconData icon = Icons.image_not_supported_outlined}) {
    return Center(
      key: ValueKey(message),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondary,
            size: 10.w,
          ),
          SizedBox(height: 0.6.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --------------- WIDGETS BUILDERS ---------------
  // (Funções de Helper do seu código original - RE-ADICIONADAS)

  Widget finalCounts((int, int) curCounts) {
    if (curCounts.$2 <= 0) return const SizedBox.shrink();
    return Text(
      'Série ${curCounts.$1 + 1}/${curCounts.$2}',
      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  (int, int) _byNameCounts(String exerciseName, List<Map<String, dynamic>> list) {
    final same = list.where((s) {
      final ex = (s['exercises'] as Map?) ?? {};
      final n = (ex['name'] as String?) ?? s['exercise_id']?.toString();
      return n == exerciseName;
    }).toList();
    if (same.isEmpty) return (0, 0);
    final total = same.length;
    final done = same.where(_isSetDone).length;
    return (done, total);
  }

  Widget _loadingCard() {
    return Container(
      height: 80,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.1),
            AppTheme.accentGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
        ),
      ),
    );
  }

  Widget _buildExpandedSets(List<Map<String, dynamic>> sets) {
    final groups = _groupByExercise(sets);

    final titleStyle = AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
    );
    final labelStyle =
    AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary);
    final valueStyle = AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
      color: AppTheme.accentGold,
      fontWeight: FontWeight.w700,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 0.6.h),
          itemCount: groups.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.dividerGray.withValues(alpha: 0.6),
            indent: 3.w,
            endIndent: 3.w,
          ),
          itemBuilder: (_, i) {
            final name = groups[i]['name'] as String;
            final gsets = List<Map<String, dynamic>>.from(groups[i]['sets'] as List);

            final first = gsets.isNotEmpty ? gsets.first : null;
            final reps = first?['reps'];
            final restSec = first?['rest_seconds'];
            final totalSeries = gsets.length;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.2.w, vertical: 0.6.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dividerGray.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, // <-- Este nome agora vem do _groupByExercise (PT-BR)
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    SizedBox(height: 0.6.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _meta(label: 'Séries:', value: '$totalSeries', labelStyle: labelStyle, valueStyle: valueStyle),
                        if (reps != null)
                          _meta(label: 'Repetições:', value: reps.toString(), labelStyle: labelStyle, valueStyle: valueStyle),
                        if (restSec != null)
                          _meta(label: 'Descanso:', value: '${restSec} seg', labelStyle: labelStyle, valueStyle: valueStyle),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _meta({
    required String label,
    required String value,
    required TextStyle? labelStyle,
    required TextStyle? valueStyle,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label ', style: labelStyle),
          TextSpan(text: value, style: valueStyle),
        ],
      ),
    );
  }
}