import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'club_service.dart';
import 'models.dart';
import 'widgets.dart' as clubw show BldrGoldBadge, BldrBadgeRow, levelLabel; // <- inclui BldrBadgeRow

class ProgramDetailPage extends StatefulWidget {
  const ProgramDetailPage({super.key, required this.programId});
  final String programId;

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  late final BldrClubProgramsService _svc;

  bool _loading = true;
  String _error = '';
  ClubProgram? _program;
  List<(ClubSession, List<ClubExercise>)> _blocks = const [];

  @override
  void initState() {
    super.initState();
    _svc = BldrClubProgramsService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final (p, blocks) = await _svc.getProgramDetail(widget.programId);
      if (!mounted) return;
      setState(() {
        _program = p;
        _blocks = blocks;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _program;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E11),
        title: Text(p?.name ?? 'Programa'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _ErrorState(msg: _error, onRetry: _load)
          : p == null
          ? const _ErrorState(msg: 'Programa não encontrado.')
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Capa
          SliverToBoxAdapter(
            child: _CoverHeader(
              imageUrl: (p.coverImage ?? '').toString(),
              title: p.name.toString(),
              subtitle: (p.tagline ?? '').toString(),
            ),
          ),

          // ✅ Badges na horizontal (alinhadas)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: clubw.BldrBadgeRow(
                spacing: 8,
                runSpacing: 8,
                children: [
                  clubw.BldrGoldBadge(
                    clubw.levelLabel(p.level),
                    icon: Icons.fitness_center,
                  ),
                  clubw.BldrGoldBadge(
                    '${p.durationWeeks ?? 0} semanas',
                    icon: Icons.calendar_today_rounded,
                  ),
                  clubw.BldrGoldBadge(
                    '${p.minutesPerDay ?? 30} min/dia',
                    icon: Icons.timer_outlined,
                  ),
                  if ((p.equipment as List? ?? const []).isEmpty)
                    const clubw.BldrGoldBadge(
                      'Sem equipamentos',
                      icon: Icons.check_circle_outline,
                    )
                  else
                    clubw.BldrGoldBadge(
                      (p.equipment as List).join(', '),
                      icon: Icons.handyman_outlined,
                    ),
                ],
              ),
            ),
          ),

          // Descrição
          if (((p.description ?? '') as Object)
              .toString()
              .isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  (p.description ?? '').toString(),
                  style: const TextStyle(
                      color: Colors.white70, height: 1.35),
                ),
              ),
            ),

          // Título Sessões
          if (_blocks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Sessões',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          // Lista de sessões
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                final (session, exercises) = _blocks[i];
                return Padding(
                  padding:
                  const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: _SessionCard(
                    session: session,
                    exercises: exercises,
                  ),
                );
              },
              childCount: _blocks.length,
            ),
          ),

          if (_blocks.isEmpty &&
              (p.description ?? '').toString().isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Conteúdo em breve.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/* ---------- UI auxiliares ---------- */

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.msg, this.onRetry});
  final String msg;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 36),
            const SizedBox(height: 8),
            Text(
              'Erro ao carregar:\n$msg',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente')),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoverHeader extends StatelessWidget {
  const _CoverHeader(
      {required this.imageUrl,
        required this.title,
        required this.subtitle});
  final String imageUrl;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius:
      const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: const Color(0xFF171717),
            child: hasImage
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : const SizedBox.shrink(),
          ),
          // Gradiente overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0, 0.6, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.80),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
          // Título e subtítulo
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.exercises});
  final ClubSession session;
  final List<ClubExercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF121212),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((session.focus ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                session.focus!,
                style:
                const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            for (final ex in exercises) _ExerciseRow(ex: ex),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.ex});
  final ClubExercise ex;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (ex.sets != null) '${ex.sets}x',
      if ((ex.reps ?? '').toString().isNotEmpty) '${ex.reps}',
      if (ex.seconds != null) '${ex.seconds}s',
      if ((ex.tempo ?? '').toString().isNotEmpty) 'T:${ex.tempo}',
      if (ex.restSec != null) 'Desc:${ex.restSec}s',
    ].where((e) => e.isNotEmpty).join('  ·  ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(ex.name,
                  style: const TextStyle(color: Colors.white))),
          if (detail.isNotEmpty)
            Text(detail,
                style:
                const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}
