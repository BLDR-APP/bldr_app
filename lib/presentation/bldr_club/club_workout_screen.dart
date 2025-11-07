import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Service do CLUB para iniciar o treino
import '../../services/club_workouts_service.dart';

// ⬇️ IMPORTANTE: renderiza o banner do treino ativo
import '../bldr_club/widgets/active_workout_banner_club.dart';

class ClubWorkoutsScreen extends StatefulWidget {
  const ClubWorkoutsScreen({
    super.key,
    this.logoPath = 'assets/images/bldr_club_treinos.png',
    this.logoHeight = 160,
    this.categories,
    this.loadFeatured,
    this.loadRecent,
    this.onOpenWorkout,
    this.onSearch,
  });

  final String logoPath;
  final double logoHeight;
  final List<String>? categories;

  /// Carregadores opcionais; se nulos, usa loaders locais (exemplo)
  final Future<List<WorkoutCardData>> Function()? loadFeatured;
  final Future<List<WorkoutCardData>> Function()? loadRecent;

  /// Se fornecido, é chamado ao abrir um treino. Se não, abre um bottom sheet.
  final void Function(String workoutId)? onOpenWorkout;
  final void Function(String query)? onSearch;

  @override
  State<ClubWorkoutsScreen> createState() => _ClubWorkoutsScreenState();
}

class _ClubWorkoutsScreenState extends State<ClubWorkoutsScreen> {
  static const gold = Color(0xFFD4AF37);
  final _pageController = PageController(viewportFraction: 0.86);

  int _currentPage = 0;
  bool _loadingFeatured = true;
  bool _loadingRecent = true;
  String _errorFeatured = '';
  String _errorRecent = '';

  List<WorkoutCardData> _featured = const [];
  List<WorkoutCardData> _recent = const [];

  String _searchText = '';
  String _selectedCategory = 'Todos';

  // cache simples para exercícios por template
  final Map<String, List<TemplateExercise>> _exCache = {};
  bool _startingWorkout = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() => setState(() {
      final p = _pageController.page ?? 0;
      _currentPage = (p + 0.5).floor();
    }));
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    await Future.wait([_loadFeatured(), _loadRecent()]);
  }

  Future<void> _loadFeatured() async {
    setState(() {
      _loadingFeatured = true;
      _errorFeatured = '';
    });
    try {
      if (widget.loadFeatured != null) {
        _featured = await widget.loadFeatured!();
      } else {
        _featured = await _loadFeaturedFromSupabase();
      }
    } catch (e) {
      _errorFeatured = e.toString();
    } finally {
      if (mounted) setState(() => _loadingFeatured = false);
    }
  }

  Future<void> _loadRecent() async {
    setState(() {
      _loadingRecent = true;
      _errorRecent = '';
    });
    try {
      if (widget.loadRecent != null) {
        _recent = await widget.loadRecent!();
      } else {
        _recent = await _loadRecentFromSupabase();
      }
    } catch (e) {
      _errorRecent = e.toString();
    } finally {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  // ====== Loaders apontando para CLUB: public.club_workout_templates ======
  Future<List<WorkoutCardData>> _loadFeaturedFromSupabase() async {
    final client = Supabase.instance.client;

    final data = await client
        .from('club_workout_templates')
        .select(
      'id, name, description, workout_type, estimated_duration_minutes, difficulty_level, is_public',
    )
        .eq('is_public', true)
        .limit(5);

    return (data as List).map((m) {
      final minutes = (m['estimated_duration_minutes'] as int?) ?? 30;
      final type = (m['workout_type'] ?? '').toString().toLowerCase();
      final typeLabel = (type == 'hiit') ? 'HIIT' : 'Força';
      final subtitle = '$typeLabel • $minutes min';
      final badge = _levelLabel(m['difficulty_level']);

      return WorkoutCardData(
        id: (m['id'] ?? '').toString(),
        title: (m['name'] ?? '').toString(),
        subtitle: subtitle,
        badge: badge,
        imageUrl: '',
      );
    }).toList();
  }

  Future<List<WorkoutCardData>> _loadRecentFromSupabase() async {
    final client = Supabase.instance.client;

    final data = await client
        .from('club_workout_templates')
        .select(
      'id, name, description, workout_type, estimated_duration_minutes, difficulty_level, is_public',
    )
        .eq('is_public', true)
        .order('name', ascending: true)
        .limit(30);

    return (data as List).map((m) {
      final minutes = (m['estimated_duration_minutes'] as int?) ?? 30;
      final type = (m['workout_type'] ?? '').toString().toLowerCase();
      final typeLabel = (type == 'hiit') ? 'HIIT' : 'Força';
      final subtitle = '$typeLabel • $minutes min';
      final badge = _levelLabel(m['difficulty_level']);

      return WorkoutCardData(
        id: (m['id'] ?? '').toString(),
        title: (m['name'] ?? '').toString(),
        subtitle: subtitle,
        badge: badge,
        imageUrl: '',
      );
    }).toList();
  }

  // Aceita int (1..4) ou string; retorna rótulo amigável.
  String _levelLabel(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 1:
          return 'Iniciante';
        case 2:
          return 'Intermediário';
        case 3:
          return 'Avançado';
        case 4:
          return 'Experiente';
        default:
          return 'Nível $raw';
      }
    }
    final s = raw?.toString().toLowerCase() ?? '';
    if (s.contains('inic')) return 'Iniciante';
    if (s.contains('inter')) return 'Intermediário';
    if (s.contains('avan')) return 'Avançado';
    if (s.contains('exp')) return 'Experiente';
    return s.isEmpty ? 'Todos os níveis' : s;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<WorkoutCardData> _filteredRecent() {
    Iterable<WorkoutCardData> data = _recent;
    if (_selectedCategory != 'Todos') {
      data = data.where(
            (w) => w.badge.toLowerCase() == _selectedCategory.toLowerCase(),
      );
    }
    if (_searchText.trim().isNotEmpty) {
      final q = _searchText.trim().toLowerCase();
      data = data.where(
            (w) =>
        w.title.toLowerCase().contains(q) ||
            w.subtitle.toLowerCase().contains(q),
      );
    }
    return data.toList();
  }

  // ================== Abertura / início de treino ==================

  void _handleOpenWorkout(WorkoutCardData data) {
    if (widget.onOpenWorkout != null) {
      widget.onOpenWorkout!(data.id);
      return;
    }
    _openWorkoutBottomSheet(data);
  }

  // Recebe o card inteiro para usar o title como "name" no service
  Future<void> _startWorkout(WorkoutCardData data) async {
    if (_startingWorkout) return;
    setState(() => _startingWorkout = true);
    try {
      await ClubWorkoutsService.instance.startClubWorkout(
        name: data.title,
        clubWorkoutTemplateId: data.id,
      );

      if (!mounted) return;
      Navigator.pop(context); // fecha o bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino iniciado! O banner foi ativado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao iniciar treino'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _startingWorkout = false);
    }
  }

  Future<void> _openWorkoutBottomSheet(WorkoutCardData data) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<TemplateExercise>>(
                    future: _fetchExercisesForTemplate(data.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Erro ao carregar exercícios',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      final list = snapshot.data ?? const <TemplateExercise>[];
                      if (list.isEmpty) {
                        return const Center(
                          child: Text(
                            'Sem exercícios para este treino.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 18),
                        itemBuilder: (_, i) {
                          final e = list[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: gold.withOpacity(0.14),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              e.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              _exerciseSubtitle(e),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.white38),
                          );
                        },
                      );
                    },
                  ),
                ),

                // CTA para iniciar o treino (ativa o banner)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                      _startingWorkout ? null : () => _startWorkout(data),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _startingWorkout ? 'Iniciando...' : 'Iniciar treino',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _exerciseSubtitle(TemplateExercise e) {
    final parts = <String>[];
    if (e.sets != null) {
      if (e.reps != null) {
        parts.add('${e.sets} x ${e.reps}');
      } else {
        parts.add('${e.sets} séries');
      }
    } else if (e.reps != null) {
      parts.add('${e.reps} reps');
    }
    if (e.durationSeconds != null && e.durationSeconds! > 0) {
      parts.add('${e.durationSeconds}s');
    }
    if (e.restSeconds != null && e.restSeconds! > 0) {
      parts.add('descanso ${e.restSeconds}s');
    }
    return parts.isEmpty ? '—' : parts.join(' • ');
  }

  Future<List<TemplateExercise>> _fetchExercisesForTemplate(
      String templateId) async {
    if (_exCache.containsKey(templateId)) return _exCache[templateId]!;

    final client = Supabase.instance.client;

    // 1) pega as linhas da tabela de exercícios do template (sem join)
    final res = await client
        .from('club_workout_template_exercises')
        .select(
        'id, exercise_id, order_index, sets, reps, duration_seconds, rest_seconds')
        .eq('workout_template_id', templateId) // <- CORRETO
        .order('order_index', ascending: true);

    final rawList = (res as List);

    // 2) IDs únicos de exercícios
    final ids = rawList
        .map((m) => (m['exercise_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    // 3) busca os nomes na tabela de exercícios
    final Map<String, String> namesById = {};
    if (ids.isNotEmpty) {
      final orCond = ids.map((id) => 'id.eq.$id').join(',');
      final exRes = await client
          .from('exercises')
          .select('id, name')
          .or(orCond); // ex.: id.eq.uuid1,id.eq.uuid2,...

      for (final m in (exRes as List)) {
        final id = (m['id'] ?? '').toString();
        final name = (m['name'] ?? 'Exercício').toString();
        namesById[id] = name;
      }
    }

    // 4) monta a lista final já com os nomes
    final list = rawList.map((m) {
      final exerciseId = (m['exercise_id'] ?? '').toString();
      final name = namesById[exerciseId] ?? 'Exercício';
      return TemplateExercise(
        id: (m['id'] ?? '').toString(),
        exerciseId: exerciseId,
        name: name,
        sets: (m['sets'] as int?),
        reps: (m['reps'] as int?),
        durationSeconds: (m['duration_seconds'] as int?),
        restSeconds: (m['rest_seconds'] as int?),
        orderIndex: (m['order_index'] as int?),
      );
    }).toList();

    _exCache[templateId] = list;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories ??
        const ['Todos', 'Iniciante', 'Intermediário', 'Avançado'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _GoldRadialBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _reloadAll,
              color: gold,
              backgroundColor: const Color(0xFF121212),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // LOGO
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _Header(
                        logoPath: widget.logoPath,
                        logoHeight: widget.logoHeight,
                      ),
                    ),
                  ),

                  // BUSCA
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _SearchBar(
                        hint: 'Buscar treinos',
                        onSubmit: (text) {
                          setState(() => _searchText = text);
                          widget.onSearch?.call(text);
                        },
                      ),
                    ),
                  ),

                  // ⬇️ BANNER DO TREINO ATIVO (aparece/ some conforme o stream)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: ActiveWorkoutBannerClubWidget(),
                    ),
                  ),

                  // CATEGORIAS
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final label = categories[i];
                          final selected = _selectedCategory == label;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = label),
                            labelStyle: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedColor: gold,
                            backgroundColor: const Color(0xFF1A1A1A),
                            shape: const StadiumBorder(
                              side: BorderSide(color: Color(0x22D4AF37)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // TÍTULO DESTAQUES
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        children: [
                          Text(
                            'Treinos em Destaque',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seleção feita para você',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // CARROSSEL DESTAQUES
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 210,
                      child: _loadingFeatured
                          ? const Center(child: CircularProgressIndicator())
                          : _errorFeatured.isNotEmpty
                          ? const _ErrorBoxCompact()
                          : PageView.builder(
                        controller: _pageController,
                        itemCount: _featured.length,
                        itemBuilder: (context, index) {
                          final data = _featured[index];
                          final isCurrent = index == _currentPage;
                          return AnimatedScale(
                            scale: isCurrent ? 1.0 : 0.96,
                            duration:
                            const Duration(milliseconds: 200),
                            child: _WorkoutCard(
                              data: data,
                              onOpen: () => _handleOpenWorkout(data),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // INDICADORES CARROSSEL
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _featured.length,
                              (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i ? gold : Colors.white24,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // TÍTULO RECENTES + CTA "VER TODOS"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Biblioteca de Treinos',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed('/bldr-club/treinos');
                            },
                            icon: const Icon(
                              Icons.grid_view_rounded,
                              size: 18,
                              color: Color(0xFFD4AF37),
                            ),
                            label: const Text(
                              'Ver todos',
                              style: TextStyle(color: Color(0xFFD4AF37)),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // GRADE RECENTES
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: _loadingRecent
                        ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                        : _errorRecent.isNotEmpty
                        ? const SliverToBoxAdapter(
                      child: _ErrorBoxCompact(),
                    )
                        : SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final items = _filteredRecent();
                        if (items.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Center(
                                child: Text(
                                  'Nenhum treino encontrado.',
                                  style: TextStyle(
                                      color: Colors.white70),
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final data = items[index];
                              return _WorkoutTile(
                                data: data,
                                onOpen: () =>
                                    _handleOpenWorkout(data),
                              );
                            },
                            childCount: items.length,
                          ),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
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
}

/* ====================== UI COMPONENTES ====================== */

class _Header extends StatelessWidget {
  const _Header({required this.logoPath, this.logoHeight = 56});
  final String logoPath;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: logoHeight + 28,
      child: Center(
        child: Image.asset(
          logoPath,
          height: logoHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.hint, this.onSubmit});
  final String hint;
  final void Function(String text)? onSubmit;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? const Color(0x55D4AF37) : const Color(0x22D4AF37),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                onSubmitted: widget.onSubmit,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _controller.clear();
                  widget.onSubmit?.call('');
                  setState(() {});
                },
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.data, required this.onOpen});
  final WorkoutCardData data;
  final VoidCallback onOpen;
  static const gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22D4AF37)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[400],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GoldBadge(data.badge),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: gold,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onPressed: onOpen,
                  child: const Text('Ver treino'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.data, required this.onOpen});
  final WorkoutCardData data;
  final VoidCallback onOpen;
  static const gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22D4AF37)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x11D4AF37)),
              ),
              child: const Center(
                child: Icon(Icons.fitness_center, color: Colors.white38, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _GoldBadge(data.badge),
                const Spacer(),
                IconButton(
                  onPressed: onOpen,
                  icon: const Icon(
                    Icons.arrow_outward_rounded,
                    color: gold,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Abrir treino',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutCardData {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;

  const WorkoutCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.imageUrl = '',
  });
}

class TemplateExercise {
  final String id;
  final String? exerciseId; // para mapear nome via tabela exercises
  final String name;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final int? restSeconds;
  final int? orderIndex;

  const TemplateExercise({
    required this.id,
    required this.name,
    this.exerciseId,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.restSeconds,
    this.orderIndex,
  });
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8D18F), Color(0xFFD4AF37), Color(0xFFA8872A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/* ============== FUNDO IGUAL AO BLDR CLUB ============== */

class _GoldRadialBackground extends StatelessWidget {
  const _GoldRadialBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: const [
            _RadialBlob(top: -180, opacity: 0.30, radiusFactor: 1.8),
            _RadialBlob(bottom: -140, opacity: 0.18, radiusFactor: 1.6),
            _RadialBlob(center: true, opacity: 0.32, radiusFactor: 1.2),
          ],
        ),
      ),
    );
  }
}

class _RadialBlob extends StatelessWidget {
  const _RadialBlob({
    this.top,
    this.bottom,
    this.center = false,
    required this.opacity,
    required this.radiusFactor,
  });

  final double? top;
  final double? bottom;
  final bool center;
  final double opacity;
  final double radiusFactor;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * radiusFactor;
    final c = const Color(0xFFD4AF37).withOpacity(opacity);
    final blob = Center(
      child: Container(
        width: w,
        height: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: RadialGradient(
            colors: [c, c.withOpacity(0)],
            radius: 0.75,
          ),
        ),
      ),
    );
    if (center) return Positioned.fill(child: blob);
    if (top != null) {
      return Positioned(top: top, left: 0, right: 0, child: blob);
    }
    if (bottom != null) {
      return Positioned(bottom: bottom, left: 0, right: 0, child: blob);
    }
    return Positioned.fill(child: blob);
  }
}

class _ErrorBoxCompact extends StatelessWidget {
  const _ErrorBoxCompact();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            SizedBox(height: 8),
            Text('Erro ao carregar', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
