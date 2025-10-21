import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/club_workouts_service.dart';

class ActiveWorkoutBannerClubWidget extends StatefulWidget {
  const ActiveWorkoutBannerClubWidget({Key? key}) : super(key: key);

  @override
  State<ActiveWorkoutBannerClubWidget> createState() =>
      _ActiveWorkoutBannerClubWidgetState();
}

class _ActiveWorkoutBannerClubWidgetState
    extends State<ActiveWorkoutBannerClubWidget>
    with SingleTickerProviderStateMixin {
  // anima do chip atual
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // stream/state
  Map<String, dynamic>? _localWorkoutState;
  bool _isLoading = true;
  bool _hideBanner = false;

  // ✅ stream mantida entre rebuilds
  late final Stream<Map<String, dynamic>?> _activeStream;

  // cronômetro do treino (fallback quando não há duração planejada)
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
  String? _currentExerciseName;

  // Contadores para a UI
  int _currentExerciseSetsTotal = 0;
  int _currentExerciseSetsCompleted = 0;


  // UI
  bool _expanded = true; // deixa a área aberta por padrão
  bool _completingSet = false;
  final _scrollCtrl = ScrollController();

  // ---------- DIAGNÓSTICO ----------
  String? _lastWorkoutId;
  bool _probeScheduled = false;

  void _log(String msg) => debugPrint('[CLUB Banner] $msg');

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.repeat(reverse: true);

    _activeStream = ClubWorkoutsService.instance.activeClubWorkoutStream();
    _log('init -> stream criado');

    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------------- TIME ----------------

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused || _localWorkoutState == null) return;
      _elapsedSeconds = _computeElapsed(_localWorkoutState);
      setState(() {}); // atualiza timer/descanso
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
    final t = (w?['club_workout_templates'] as Map?) ?? {};
    final m = t['estimated_duration_minutes'];
    if (m == null) return null;
    if (m is int) return m;
    if (m is num) return m.toInt();
    return int.tryParse(m.toString());
  }

  String _plannedOrElapsedText(Map<String, dynamic>? w) {
    final m = _plannedMinutes(w);
    if (m != null && m > 0) return '$m min';
    return _fmt(_elapsedSeconds); // fallback
  }

  // --------------- DATA HELPERS ---------------

  bool _isSetDone(Map s) =>
      (s['is_completed'] == true) || (s['completed_at'] != null);

  bool _hasOpenSet(List<Map<String, dynamic>> sets) =>
      sets.any((s) => !_isSetDone(s));

  // ✅ CORREÇÃO APLICADA AQUI: Adicionando SORT antes da busca e usando orElse para compatibilidade.
  void _resolveCurrentSet(Map<String, dynamic>? workout) {
    _currentSetIndex = null;
    _currentSetId = null;
    _currentExerciseName = null;
    _currentExerciseSetsTotal = 0;
    _currentExerciseSetsCompleted = 0;
    if (workout == null) return;

    final allSets = (workout['club_workout_exercise_sets'] as List?)
        ?.cast<Map<String, dynamic>>() ??
        [];
    if (allSets.isEmpty) return;

    // NOVO: ORDENAR AS SÉRIES LOCALMENTE
    // Garante que a série pendente mais próxima seja encontrada primeiro.
    allSets.sort((a, b) {
      // 1. Comparação pelo ID do exercício para garantir a ordem dos exercícios
      final exA = a['exercise_id']?.toString() ?? 'A';
      final exB = b['exercise_id']?.toString() ?? 'B';
      final exComparison = exA.compareTo(exB);

      // 2. Se os exercícios são os mesmos, ordene pelo número da série
      if (exComparison == 0) {
        final numA = (a['set_number'] as int?) ?? 999;
        final numB = (b['set_number'] as int?) ?? 999;
        return numA.compareTo(numB);
      }
      return exComparison;
    });


    // 1. Encontrar a primeira série NÃO concluída em TODO O TREINO.
    final nextIncompleteSet = allSets.firstWhere(
          (s) => !_isSetDone(s),
      orElse: () => <String, dynamic>{}, // Retorna um Map vazio
    );

    if (nextIncompleteSet.isEmpty) {
      // Treino concluído
      final last = Map<String, dynamic>.from(allSets.last as Map);
      final ex = (last['exercises'] as Map?) ?? {};
      _currentExerciseName = 'Treino Concluído!';
      _log('Treino concluído.');
      return;
    }

    // 2. IDENTIFICAÇÃO DO EXERCÍCIO ATUAL:
    // Pega o nome do exercício da próxima série pendente
    final exerciseDetails = (nextIncompleteSet['exercises'] as Map?) ?? {};
    final nextExerciseName = (exerciseDetails['name'] as String?) ??
        (nextIncompleteSet['exercise_id']?.toString() ?? 'N/A');

    // 3. ATUALIZAÇÃO DO ESTADO:
    final currentSetMap = Map<String, dynamic>.from(nextIncompleteSet);

    // 4. Contador de séries para o exercício atual (importante para o banner)
    final setsForCurrentExercise = allSets.where((s) {
      final ex = (s['exercises'] as Map?) ?? {};
      final n = (ex['name'] as String?) ?? (s['exercise_id']?.toString() ?? 'N/A');
      return n == nextExerciseName;
    }).toList();

    // Atualiza o estado
    setState(() {
      _currentSetIndex = allSets.indexOf(nextIncompleteSet);
      _currentSetId = currentSetMap['id']?.toString();
      _currentExerciseName = nextExerciseName;

      _currentExerciseSetsTotal = setsForCurrentExercise.length;
      _currentExerciseSetsCompleted = setsForCurrentExercise.where(_isSetDone).length;
    });

    _log('Próxima tarefa: Exercício="$_currentExerciseName", Série #${currentSetMap['set_number']}');
  }


  bool _allSetsDone(Map<String, dynamic>? w) {
    final sets =
    (w?['club_workout_exercise_sets'] as List?)?.cast<Map<String, dynamic>>();
    if (sets == null || sets.isEmpty) return false;
    return sets.every(_isSetDone);
  }

  int _countDone(List<Map<String, dynamic>> sets) =>
      sets.where(_isSetDone).length;

  String _workoutName(Map<String, dynamic>? w) {
    if (w == null) return 'Sem treinos ativos';
    String name = (w['name'] as String?) ?? 'Workout';
    final tmpl = w['club_workout_templates'];
    final tname = (tmpl is Map ? tmpl['name'] as String? : null);
    if (tname != null && tname.isNotEmpty && tname != name) name = tname;
    return name;
  }

  List<Map<String, dynamic>> _groupByExercise(List sets) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final raw in sets) {
      final s = Map<String, dynamic>.from(raw as Map);
      final ex = (s['exercises'] as Map?) ?? {};
      final n =
          (ex['name'] as String?) ?? (s['exercise_id']?.toString() ?? 'Exercício');
      map.putIfAbsent(n, () => []).add(s);
    }
    return map.entries.map((e) => {'name': e.key, 'sets': e.value}).toList();
  }

  // --------------- REST ---------------

  void _startRestFixed() {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restRemaining = _restFixedSeconds;
    });
    _log('Descanso iniciado ($_restFixedSeconds s)');
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _isPaused) return;
      if (_restRemaining <= 1) {
        _stopRest();
      } else {
        setState(() => _restRemaining -= 1);
      }
    });
  }

  /// É chamada ao final do descanso para avançar para a próxima tarefa.
  void _stopRest() {
    // --- CÓDIGO DE DIAGNÓSTICO MANTIDO ---
    _log('--- DEBUG: Verificando estado antes de avançar ---');
    _log('Exercício em foco durante o descanso: $_currentExerciseName');
    final allSets = (_localWorkoutState?['club_workout_exercise_sets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final setsOfCurrentExercise = allSets.where((s) {
      final ex = (s['exercises'] as Map?) ?? {};
      final n = (ex['name'] as String?) ?? (s['exercise_id']?.toString() ?? 'N/A');
      return n == _currentExerciseName;
    }).toList();

    if (setsOfCurrentExercise.isEmpty) {
      _log('DEBUG RESULT: Não foram encontradas séries para o exercício atual!');
    } else {
      _log('DEBUG RESULT: Status das séries do exercício "$_currentExerciseName":');
      for (final set in setsOfCurrentExercise) {
        _log(' - Série #${set['set_number']}: is_completed: ${set['is_completed']}');
      }
    }
    _log('-------------------------------------------');
    // --- FIM DO CÓDIGO DE DIAGNÓSTICO ---

    _restTimer?.cancel();
    _restTimer = null;
    if (mounted) {
      setState(() {
        _isResting = false;
        _restRemaining = 0;
        // Resolve qual é a próxima série/exercício APÓS o descanso.
        _resolveCurrentSet(_localWorkoutState);
      });
      _log('Descanso encerrado, resolvendo próxima tarefa.');
    }
  }

  // ---------- PROBE ----------
  void _scheduleProbeNoActive() {
    if (_probeScheduled) return;
    _probeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final rows = await ClubWorkoutsService.instance
            .getClubUserWorkouts(completedOnly: false, limit: 5);
        _log('Probe: últimos ${rows.length} treinos do usuário:');
        if (rows.isEmpty) {
          _log('Probe RESULT -> Nenhuma linha em club_user_workouts p/ este usuário.');
        } else {
          // ... (código de probe mantido para diagnóstico)
        }
      } catch (e) {
        _log('Probe ERROR -> Falha ao listar treinos do usuário: $e');
      }
    });
  }

  // --------------- ACTIONS ---------------

  Future<void> _togglePause() async {
    setState(() => _isPaused = !_isPaused);
    _log(_isPaused ? 'Treino pausado' : 'Treino retomado');
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
    if (_localWorkoutState == null) return;
    try {
      _log('Finalizando treino id=${_localWorkoutState!['id']}');
      await ClubWorkoutsService.instance.completeClubWorkout(
        workoutId: _localWorkoutState!['id'],
        notes: 'Workout completed from banner (CLUB)',
      );
      if (!mounted) return;
      setState(() {
        _localWorkoutState = null;
        _hideBanner = true;
      });
      _stopRest();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Treino concluído!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _log('ERRO ao finalizar treino: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao finalizar treino')),
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
          'Tem certeza que deseja finalizar "${_workoutName(_localWorkoutState)}"? Todo o seu progresso será salvo.',
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

  /// Apenas conclui a série atual e inicia o descanso.
  Future<void> _completeCurrentSet() async {
    if (_localWorkoutState == null || _isResting || _completingSet) return;

    String? setIdStr = _currentSetId;
    int? setIndex = _currentSetIndex;
    final setsList =
        (_localWorkoutState!['club_workout_exercise_sets'] as List?)
            ?.cast<Map<String, dynamic>>() ??
            [];

    if (setIdStr == null || setIndex == null) {
      final idx = setsList.indexWhere(
            (s) => !_isSetDone(s),
      );
      if (idx == -1) return;
      setIndex = idx;
      setIdStr = setsList[idx]['id']?.toString();
    }
    if(setIdStr == null) return;

    _log('Concluir série setId=$setIdStr (ex="${_currentExerciseName}")');

    _completingSet = true;
    HapticFeedback.selectionClick();

    final original = _localWorkoutState!;
    final newSets = List<Map<String, dynamic>>.from(setsList);
    newSets[setIndex] = {
      ...newSets[setIndex],
      'is_completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    };
    setState(() {
      _localWorkoutState = {...original, 'club_workout_exercise_sets': newSets};
      // Não chamamos _resolveCurrentSet aqui. O foco permanece no set concluído.
    });

    _startRestFixed(); // Inicia o descanso. O avanço ocorrerá em _stopRest().

    try {
      await ClubWorkoutsService.instance.completeClubSet(setId: setIdStr);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Série concluída'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _log('ERRO ao concluir série: $e');

      // Em caso de erro, para o descanso e reverte o estado
      _stopRest();
      setState(() {
        _localWorkoutState = original;
        _resolveCurrentSet(_localWorkoutState); // Re-sincroniza para o estado correto
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Falha ao concluir série'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      _completingSet = false;
    }
  }

  Future<void> _undoSet(String setId) async {
    try {
      _log('Desfazer set id=$setId');
      await ClubWorkoutsService.instance.undoClubSet(setId: setId);
    } catch (e) {
      _log('ERRO ao desfazer set: $e');
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
          if (isCurrent && !done)
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
        final setsList =
        (_localWorkoutState!['club_workout_exercise_sets'] as List)
            .cast<Map<String, dynamic>>();
        final idx = setsList.indexWhere(
                (x) => x['id'].toString() == s['id'].toString());
        if (idx >= 0) {
          final clone = List<Map<String, dynamic>>.from(setsList);
          clone[idx] = {
            ...clone[idx],
            'is_completed': false,
            'completed_at': null,
          };
          setState(() {
            _localWorkoutState = {
              ..._localWorkoutState!,
              'club_workout_exercise_sets': clone
            };
            _resolveCurrentSet(_localWorkoutState);
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

    final stream = _activeStream;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          _log('Stream waiting...');
          return _loadingCard();
        }

        _isLoading = false;

        if (snapshot.hasError) {
          _log('STREAM ERROR: ${snapshot.error}');
        }

        final streamData = snapshot.data;
        if (_localWorkoutState == null || (_localWorkoutState?['id'] != streamData?['id'])) {
          _log('Stream forneceu novos dados de treino. Atualizando estado local.');
          _localWorkoutState = streamData;
          _resolveCurrentSet(_localWorkoutState);
        }

        if (streamData != null && streamData['is_completed'] == true) {
          return const SizedBox.shrink();
        }

        if (_localWorkoutState == null) {
          _scheduleProbeNoActive();
          return const SizedBox.shrink();
        }

        _elapsedSeconds = _computeElapsed(_localWorkoutState);

        final setsList =
            (_localWorkoutState!['club_workout_exercise_sets'] as List?)
                ?.cast<Map<String, dynamic>>() ??
                [];
        final totalSets = setsList.length;
        final doneSets = _countDone(setsList);
        final progress = totalSets == 0 ? 0.0 : (doneSets / totalSets);

        const canFinish = true;

        final hasOpen = _hasOpenSet(setsList);

        final curCounts = _currentExerciseName == null
            ? (0, 0)
            : _byNameCounts(_currentExerciseName!, setsList);

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
              // ======= HEADER =======
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: _isPaused
                            ? AppTheme.warningAmber
                            : AppTheme.accentGold,
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
                          'Treino Atual (CLUB)',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          _workoutName(_localWorkoutState),
                          style: AppTheme.darkTheme.textTheme.bodyMedium
                              ?.copyWith(
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
                              _plannedOrElapsedText(_localWorkoutState),
                              style: AppTheme.darkTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              style: AppTheme.darkTheme.textTheme.bodySmall
                                  ?.copyWith(
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
                                  style: AppTheme.darkTheme.textTheme.bodySmall
                                      ?.copyWith(
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
                      _currentExerciseName ?? 'Preparando exercício...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.darkTheme.textTheme.titleSmall
                          ?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  finalCounts(curCounts),
                ],
              ),
              SizedBox(height: 0.6.h),
              Container(
                width: double.infinity,
                height: 18.h,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerGray),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'play_circle',
                        color: AppTheme.textSecondary,
                        size: 10.w,
                      ),
                      SizedBox(height: 0.6.h),
                      Text(
                        'Vídeo do exercício',
                        style: AppTheme.darkTheme.textTheme.bodySmall
                            ?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 1.2.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: (!hasOpen || _isResting || _completingSet)
                          ? null
                          : _completeCurrentSet,
                      child: Opacity(
                        opacity:
                        (!hasOpen || _isResting || _completingSet) ? 0.5 : 1.0,
                        child: Container(
                          padding: EdgeInsets.all(2.6.w),
                          decoration: BoxDecoration(
                            color:
                            AppTheme.successGreen.withValues(alpha: 0.18),
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
                                style: AppTheme.darkTheme.textTheme.bodyMedium
                                    ?.copyWith(
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
                              style: AppTheme.darkTheme.textTheme.bodyMedium
                                  ?.copyWith(
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
      },
    );
  }

  Widget finalCounts((int, int) curCounts) {
    if (curCounts.$2 <= 0) return const SizedBox.shrink();
    return Text(
      'Série ${curCounts.$1}/${curCounts.$2}',
      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  (int, int) _byNameCounts(
      String exerciseName, List<Map<String, dynamic>> list) {
    final same = list.where((s) {
      final ex = (s['exercises'] as Map?) ?? {};
      final n = (ex['name'] as String?) ?? s['exercise_id']?.toString();
      return n == exerciseName;
      // Nota: Esta função não precisa de ordenação, pois apenas conta
      // os sets do exercício cujo nome já foi determinado por _resolveCurrentSet.
    }).toList();
    if (same.isEmpty) return (0, 0);
    final total = same.length;
    final done = same.where(_isSetDone).length;
    return (done, total);
  }

  // ---------------- UI SUBS ----------------

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
    final labelStyle = AppTheme.darkTheme.textTheme.bodySmall
        ?.copyWith(color: AppTheme.textSecondary);
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
            final gsets =
            List<Map<String, dynamic>>.from(groups[i]['sets'] as List);

            final first = gsets.isNotEmpty ? gsets.first : null;
            final reps = first?['reps'];
            final restSec = first?['rest_seconds'];
            final totalSeries = gsets.length;

            return Padding(
              padding:
              EdgeInsets.symmetric(horizontal: 1.2.w, vertical: 0.6.h),
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.dividerGray.withValues(alpha: 0.6)),
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
                      name,
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
                        _meta(
                          label: 'Séries:',
                          value: '$totalSeries',
                          labelStyle: labelStyle,
                          valueStyle: valueStyle,
                        ),
                        if (reps != null)
                          _meta(
                            label: 'Repetições:',
                            value: reps.toString(),
                            labelStyle: labelStyle,
                            valueStyle: valueStyle,
                          ),
                        if (restSec != null)
                          _meta(
                            label: 'Descanso:',
                            value: '${restSec} seg',
                            labelStyle: labelStyle,
                            valueStyle: valueStyle,
                          ),
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