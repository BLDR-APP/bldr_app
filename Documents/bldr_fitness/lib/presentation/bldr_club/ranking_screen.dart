import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFD4AF37);

/// Modelo mínimo para uma linha do ranking.
class RankingEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int xp;        // XP total
  final int position;  // posição 1..N

  const RankingEntry({
    required this.userId,
    required this.displayName,
    required this.xp,
    required this.position,
    this.avatarUrl,
  });
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({
    super.key,
    this.title = 'Ranking BLDR CLUB',
    required this.loadRanking,
    this.rankingStream,
    this.onTapUser,
    this.logoPath = 'assets/images/bldr_club_ranking.png',
    this.logoHeight = 200,
  });

  /// Somente usado no header
  final String title;
  final String logoPath;
  final double logoHeight;

  /// Loader “one-shot”
  final Future<List<RankingEntry>> Function() loadRanking;

  /// Stream “ao vivo” (opcional)
  final Stream<List<RankingEntry>>? rankingStream;

  /// Callback quando toca num usuário
  final void Function(RankingEntry entry)? onTapUser;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<RankingEntry>> _future;
  List<RankingEntry>? _cache;

  @override
  void initState() {
    super.initState();
    _future = widget.loadRanking().then((v) {
      _cache = v;
      return v;
    }).catchError((e) {
      // mantém o Future com erro para cair no _ErrorView e também loga
      print('[RANKING][INIT ERRO] $e');
      throw e;
    });
  }

  Future<void> _refresh() async {
    try {
      final v = await widget.loadRanking();
      if (mounted) {
        setState(() {
          _cache = v;
          _future = Future.value(v);
        });
      }
    } catch (e, st) {
      print('[RANKING][REFRESH ERRO] $e\n$st');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.rankingStream != null
        ? StreamBuilder<List<RankingEntry>>(
      stream: widget.rankingStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && _cache == null) {
          return const _LoadingView();
        }
        if (snap.hasError) {
          print('[RANKING][UI STREAM ERRO] ${snap.error}');
          return _ErrorView(
            message: 'Não foi possível carregar o ranking.',
            onRetry: _refresh,
          );
        }
        final data = snap.data ?? _cache ?? const <RankingEntry>[];
        if (data.isEmpty) return const _EmptyView(message: 'Nenhum usuário no ranking ainda.');
        return _RankingList(data: data, onTapUser: widget.onTapUser);
      },
    )
        : FutureBuilder<List<RankingEntry>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && _cache == null) {
          return const _LoadingView();
        }
        if (snap.hasError) {
          print('[RANKING][UI FUTURE ERRO] ${snap.error}');
          return _ErrorView(
            message: 'Não foi possível carregar o ranking.',
            onRetry: _refresh,
          );
        }
        final data = snap.data ?? _cache ?? const <RankingEntry>[];
        if (data.isEmpty) return const _EmptyView(message: 'Nenhum usuário no ranking ainda.');
        return _RankingList(data: data, onTapUser: widget.onTapUser);
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _GoldRadialBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _HeaderGoldBack(
                  logoPath: widget.logoPath,
                  logoHeight: widget.logoHeight,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: _gold,
                    backgroundColor: const Color(0xFF121212),
                    onRefresh: _refresh,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------- Header (igual ao Treinos + back) --------------------- */

class _HeaderGoldBack extends StatelessWidget {
  const _HeaderGoldBack({
    required this.logoPath,
    this.logoHeight = 200,
    this.onBack,
  });

  final String logoPath;
  final double logoHeight;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: logoHeight + 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(logoPath, height: logoHeight, fit: BoxFit.contain),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Voltar',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                color: _gold,
                splashRadius: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------- Views auxiliares --------------------- */

class _RankingList extends StatelessWidget {
  const _RankingList({required this.data, this.onTapUser});

  final List<RankingEntry> data;
  final void Function(RankingEntry entry)? onTapUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = data[i];
        final isPodium = e.position <= 3;
        final accent = isPodium ? _gold : Colors.white24;

        return InkWell(
          onTap: onTapUser == null ? null : () => onTapUser!(e),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF101011),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                _PositionBadge(position: e.position),
                const SizedBox(width: 12),
                _Avatar(url: e.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text('${e.xp} XP',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position});
  final int position;

  @override
  Widget build(BuildContext context) {
    final bool podium = position <= 3;
    final Color border = podium ? _gold.withOpacity(0.5) : Colors.white24;
    final Color bg = podium ? _gold.withOpacity(0.12) : Colors.white10;
    final TextStyle style = TextStyle(
      color: podium ? _gold : Colors.white70,
      fontWeight: FontWeight.w800,
    );

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text('$position', style: style),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, color: Colors.white70),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(url!),
      backgroundColor: Colors.white24,
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: const [
        SizedBox(height: 140),
        Center(child: CircularProgressIndicator(color: _gold)),
        SizedBox(height: 140),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 48),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline, color: Colors.red[300], size: 48),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: _gold)),
            child: const Text('Tentar novamente', style: TextStyle(color: _gold)),
          ),
        ),
      ],
    );
  }
}

/* ============================================================
 * ✅ FUNDO IGUAL AO DA TELA DE TREINOS (reutilizado aqui)
 * ============================================================ */

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

/* ============================================================
 * 🔌 LOADERS SUPABASE – versão robusta
 *  -> Usa SELECT na (schema).club_ranking
 *  -> Stream só funciona se club_ranking for TABELA com Realtime ligado
 *  -> Se for VIEW, deixe [kClubRankingIsTable] = false
 * ============================================================ */

const bool kClubRankingIsTable = true; // ajuste para false se "club_ranking" for VIEW

Future<List<RankingEntry>> loadRankingFromClub({int limit = 100}) async {
  final client = Supabase.instance.client;
  try {
    print('[RANKING] Fetch inicial...');
    final rows = await client
        .schema('bldr_club')
        .from('club_ranking')
        .select('user_id, display_name, avatar_url, xp_total')
        .order('xp_total', ascending: false)
        .limit(limit);

    final list = (rows as List).cast<Map<String, dynamic>>();

    // segurança: ordena no cliente também
    list.sort((a, b) => ((b['xp_total'] ?? 0) as num).compareTo((a['xp_total'] ?? 0) as num));

    final result = <RankingEntry>[];
    for (int i = 0; i < list.length; i++) {
      final m = list[i];
      result.add(
        RankingEntry(
          userId: (m['user_id'] ?? '').toString(),
          displayName: (m['display_name'] ?? 'Usuário').toString(),
          avatarUrl: m['avatar_url'] as String?,
          xp: ((m['xp_total'] ?? 0) as num).toInt(),
          position: i + 1,
        ),
      );
    }
    print('[RANKING] OK ${result.length} registros');
    return result;
  } catch (e, st) {
    print('[RANKING][ERRO] $e\n$st');
    rethrow;
  }
}

Stream<List<RankingEntry>>? rankingStreamFromClub({int limit = 100}) {
  if (!kClubRankingIsTable) {
    print('[RANKING] club_ranking é VIEW -> sem Realtime (retornando null)');
    return null;
  }

  final client = Supabase.instance.client;
  print('[RANKING] Iniciando stream...');
  return client
      .schema('bldr_club')
      .from('club_ranking')
      .stream(primaryKey: ['user_id'])
      .limit(limit)
      .map((rows) {
    final list = rows.cast<Map<String, dynamic>>();

    // segurança: ordena no cliente
    list.sort((a, b) => ((b['xp_total'] ?? 0) as num).compareTo((a['xp_total'] ?? 0) as num));

    final result = <RankingEntry>[];
    for (int i = 0; i < list.length; i++) {
      final m = list[i];
      result.add(
        RankingEntry(
          userId: (m['user_id'] ?? '').toString(),
          displayName: (m['display_name'] ?? 'Usuário').toString(),
          avatarUrl: m['avatar_url'] as String?,
          xp: ((m['xp_total'] ?? 0) as num).toInt(),
          position: i + 1,
        ),
      );
    }
    print('[RANKING] stream tick: ${result.length} registros');
    return result;
  }).handleError((e, st) {
    print('[RANKING][STREAM ERRO] $e\n$st');
  });
}
