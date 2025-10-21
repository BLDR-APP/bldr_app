import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/user_service.dart';

class GoalTrackingWidget extends StatefulWidget {
  final int selectedPeriod;

  const GoalTrackingWidget({
    Key? key,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<GoalTrackingWidget> createState() => _GoalTrackingWidgetState();
}

class _GoalTrackingWidgetState extends State<GoalTrackingWidget> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _goals = [];
          _isLoading = false;
        });
        return;
      }

      // ⬇️ Removido o genérico de select<List<Map<String, dynamic>>>()
      final result = await _client
          .from('user_goals')
          .select() // sem tipo aqui
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // result vem como List<dynamic>; normalizamos abaixo
      final rows = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final list = rows.map<Map<String, dynamic>>((r) => _mapRow(r)).toList();

      if (mounted) {
        setState(() {
          _goals = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapRow(Map<String, dynamic> r) {
    final colorStr = (r['color'] as String?) ?? '';
    final color = _parseColorOr(colorStr, AppTheme.accentGold);

    return {
      'id': r['id'],
      'title': r['title'] ?? 'Objetivo',
      'description': r['description'] ?? '',
      'target_value': (r['target_value'] as num?)?.toDouble() ?? 0.0,
      'current_value': (r['current_value'] as num?)?.toDouble() ?? 0.0,
      'unit': r['unit'] ?? '',
      'category': r['category'] ?? 'general',
      'color': color,
      'icon': r['icon'] ?? 'track_changes',
      'deadline': r['deadline']?.toString(),
      'is_active': r['is_active'] ?? true,
      'created_at': r['created_at'],
    };
  }

  Color _parseColorOr(String hex, Color fallback) {
    try {
      if (hex.isEmpty) return fallback;
      var v = hex.replaceAll('#', '');
      if (v.length == 6) v = 'FF$v';
      final value = int.parse(v, radix: 16);
      return Color(value);
    } catch (_) {
      return fallback;
    }
  }

  String _colorToHex(Color c) {
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  Future<void> _createGoal({
    required String title,
    required String description,
    required double target,
    required String unit,
    required String category,
    Color? color,
    String icon = 'track_changes',
    DateTime? deadline,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final payload = {
      'user_id': userId,
      'title': title,
      'description': description,
      'target_value': target,
      'current_value': 0,
      'unit': unit,
      'category': category,
      'color': _colorToHex(color ?? AppTheme.accentGold),
      'icon': icon,
      'deadline': deadline?.toIso8601String(),
      'is_active': true,
    };

    await _client.from('user_goals').insert(payload);
    await _loadGoals();
  }

  Future<void> _updateProgress(Map<String, dynamic> goal, double newValue) async {
    final id = goal['id'];
    if (id == null) return;

    await _client.from('user_goals').update({
      'current_value': newValue,
    }).eq('id', id);

    await _loadGoals();
  }

  Future<void> _pauseGoal(Map<String, dynamic> goal) async {
    final id = goal['id'];
    if (id == null) return;

    await _client.from('user_goals').update({
      'is_active': false,
    }).eq('id', id);

    await _loadGoals();
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final id = goal['id'];
    if (id == null) return;

    await _client.from('user_goals').delete().eq('id', id);
    await _loadGoals();
  }

  void _showCreateGoalDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController targetController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    String selectedCategory = 'weight';
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.dialogDark,
          title: Text(
            'Criar novo objetivo',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Título do objetivo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: targetController,
                        style: TextStyle(color: AppTheme.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Objetivo (valor alvo)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Unidade',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                  dropdownColor: AppTheme.surfaceDark,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'weight', child: Text('Peso')),
                    DropdownMenuItem(value: 'workout', child: Text('Treino')),
                    DropdownMenuItem(value: 'strength', child: Text('Força')),
                    DropdownMenuItem(value: 'endurance', child: Text('Resistência')),
                    DropdownMenuItem(value: 'general', child: Text('Geral')),
                  ],
                ),
                SizedBox(height: 2.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
                        setDialogState(() => selectedDeadline = date);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                      selectedDeadline == null
                          ? 'Definir prazo (opcional)'
                          : 'Prazo: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}',
                    ),
                  ),
                ),
              ],
            ),
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
                final title = titleController.text.trim();
                final desc = descriptionController.text.trim();
                final unit = unitController.text.trim();
                final target = double.tryParse(targetController.text.trim()) ?? 0;

                if (title.isEmpty || target <= 0 || unit.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Preencha título, objetivo e unidade'),
                      backgroundColor: AppTheme.warningAmber,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _createGoal(
                  title: title,
                  description: desc,
                  target: target,
                  unit: unit,
                  category: selectedCategory,
                  deadline: selectedDeadline,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Objetivo criado com sucesso!'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Criar objetivo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'track_changes',
                  color: AppTheme.accentGold,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Objetivos',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showCreateGoalDialog,
                icon: Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'add',
                    color: AppTheme.accentGold,
                    size: 4.w,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            )
          else if (_goals.isEmpty)
            _buildEmptyState()
          else
            ..._goals
                .where((goal) => goal['is_active'] == true)
                .map((goal) => _buildGoalCard(goal)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 2.h),
          CustomIconWidget(
            iconName: 'track_changes',
            color: AppTheme.inactiveGray,
            size: 12.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Sem objetivos ativos',
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Crie objetivos SMART para acompanhar sua jornada',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _showCreateGoalDialog,
            icon: Icon(Icons.add, size: 5.w),
            label: const Text('Criar primeiro objetivo'),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final title = goal['title'] ?? 'Objetivo';
    final description = goal['description'] ?? '';
    final targetValue = (goal['target_value'] as num?)?.toDouble() ?? 0.0;
    final currentValue = (goal['current_value'] as num?)?.toDouble() ?? 0.0;
    final unit = goal['unit'] ?? '';
    final category = goal['category'] ?? 'general';
    final color = goal['color'] as Color? ?? AppTheme.accentGold;
    final iconName = goal['icon'] ?? 'track_changes';
    final deadline = goal['deadline'];

    final progress =
    targetValue != 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    final progressPercentage = (progress * 100).round();

    String deadlineText = '';
    if (deadline != null) {
      final deadlineDate = DateTime.tryParse(deadline) ?? DateTime.now();
      final now = DateTime.now();
      final daysLeft = deadlineDate.difference(now).inDays;

      if (daysLeft < 0) {
        deadlineText = 'Atrasado';
      } else if (daysLeft == 0) {
        deadlineText = 'Vence hoje';
      } else {
        deadlineText = '${daysLeft}d restantes';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: color,
                  size: 4.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        description,
                        style:
                        AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (category != 'general') ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        'Categoria: $category',
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: _getProgressColor(progress).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$progressPercentage%',
                      style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                        color: _getProgressColor(progress),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (deadlineText.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      deadlineText,
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentValue.toStringAsFixed(1)} $unit',
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${targetValue.toStringAsFixed(1)} $unit',
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.dividerGray,
              valueColor:
              AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
              minHeight: 1.h,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUpdateProgressDialog(goal),
                  icon: Icon(Icons.edit, size: 4.w),
                  label: const Text('Atualizar Progresso'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color),
                    foregroundColor: color,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: () => _showGoalOptions(goal),
                icon: CustomIconWidget(
                  iconName: 'more_vert',
                  color: AppTheme.textSecondary,
                  size: 5.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppTheme.successGreen;
    if (progress >= 0.5) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }

  void _showUpdateProgressDialog(Map<String, dynamic> goal) {
    final TextEditingController progressController = TextEditingController();
    progressController.text = (goal['current_value'] ?? 0).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        title: Text(
          'Atualizar Progresso',
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              goal['title'] ?? '',
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: progressController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Valor atual (${goal['unit'] ?? ''})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.accentGold, width: 2),
                ),
              ),
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
              final newValue = double.tryParse(progressController.text);
              if (newValue != null) {
                Navigator.pop(context);
                await _updateProgress(goal, newValue);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Progresso atualizado com sucesso!'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  void _showGoalOptions(Map<String, dynamic> goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.dividerGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              goal['title'] ?? '',
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'pause',
                color: AppTheme.warningAmber,
                size: 6.w,
              ),
              title: Text(
                'Pausar objetivo',
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pauseGoal(goal);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Objetivo pausado'),
                      backgroundColor: AppTheme.warningAmber,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.errorRed,
                size: 6.w,
              ),
              title: Text(
                'Deletar objetivo',
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _deleteGoal(goal);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Objetivo deletado'),
                      backgroundColor: AppTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
