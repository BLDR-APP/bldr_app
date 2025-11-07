import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/features/club/program_detail_page.dart';
import 'package:bldr_fitness/features/club/programs_page.dart';
import 'package:bldr_fitness/features/club/widgets.dart' as clubw
    show BldrGoldBadge, levelLabel;
import '../../services/community_service.dart';
import 'havok/widgets/panther_fab.dart'; // <-- LINHA 1 ADICIONADA AQUI

class BldrClubScreen extends StatefulWidget {
  const BldrClubScreen({
    super.key,
    this.xpPerLevel = 1000,
    this.programs,
  });

  final int xpPerLevel;
  final List<ProgramCardData>? programs;

  @override
  State<BldrClubScreen> createState() => _BldrClubScreenState();
}

class _BldrClubScreenState extends State<BldrClubScreen> {
  static const gold = Color(0xFFD4AF37);
  final _pageController = PageController(viewportFraction: 0.86);
  int _currentPage = 0;

  List<ProgramCardData> _items = const [];
  bool _loading = true;
  String _error = '';

  String? _userId;
  RealtimeChannel? _xpChannel;
  int _totalXpState = 0;
  bool _gamificationLoading = true;

  final _svc = CommunityService.instance;
  List<Map<String, dynamic>> _ann = [];
  List<Map<String, dynamic>> _events = [];
  final PageController _billboardCtrl = PageController(viewportFraction: 1.0);
  Timer? _billboardTimer;
  int _billboardIndex = 0;
  bool _communityDataLoading = true;

  List<Map<String, dynamic>> get _annWithImages {
    return _ann.where((a) {
      final url = (a['image_url'] ?? '').toString().trim();
      return url.isNotEmpty;
    }).toList();
  }


  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final p = _pageController.page ?? 0;
      final i = (p + 0.5).floor();
      if (i != _currentPage) setState(() => _currentPage = i);
    });
    _init();
  }

  Future<void> _init() async {
    await _initGamification();
    _loadCommunitySectionData();
    if (widget.programs != null) {
      setState(() {
        _items = widget.programs!;
        _loading = false;
      });
    } else {
      await _loadFromSupabase();
    }
  }

  Future<void> _loadCommunitySectionData() async {
    setState(() => _communityDataLoading = true);
    try {
      final ann = await _svc.fetchAnnouncements();
      final evs = await _svc.fetchEvents(limit: 5);

      _stopBillboard();
      if (ann.any((a) => ((a['image_url'] ?? '').toString().trim().isNotEmpty))) {
        _startBillboard();
      }

      if (mounted) {
        setState(() {
          _ann = ann;
          _events = evs;
        });
      }
    } catch (e) {
      print('[BLDR CLUB] Erro ao carregar dados da comunidade: $e');
    } finally {
      if (mounted) setState(() => _communityDataLoading = false);
    }
  }

  void _startBillboard() {
    if (_annWithImages.isEmpty) return;
    _billboardTimer?.cancel();
    _billboardTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_billboardCtrl.hasClients) return;
      final count = _annWithImages.length;
      _billboardIndex = (_billboardIndex + 1) % count;
      _billboardCtrl.animateToPage(
        _billboardIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopBillboard() {
    _billboardTimer?.cancel();
    _billboardTimer = null;
  }

  Widget _sectionTitle(BuildContext context, String t) {
    return Column(
      children: [
        Text(
          t,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 38,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }

  Future<void> _initGamification() async {
    try {
      final client = Supabase.instance.client;
      _userId = client.auth.currentUser?.id;

      if (_userId == null) {
        print('[BLDR CLUB] Gamificação: usuário não autenticado.');
        setState(() => _gamificationLoading = false);
        return;
      }

      await _fetchTotalXpForUser();
      _subscribeToXpChanges();
    } catch (e, st) {
      print('[BLDR CLUB] Erro init gamificação: $e\n$st');
    } finally {
      if (mounted) setState(() => _gamificationLoading = false);
    }
  }

  Future<void> _fetchTotalXpForUser() async {
    final client = Supabase.instance.client;
    final uid = _userId;
    if (uid == null) return;

    try {
      print('[BLDR CLUB] Buscando XP do usuário $uid da tabela club_ranking...');
      final response = await client
          .schema('bldr_club')
          .from('club_ranking')
          .select('xp_total')
          .eq('user_id', uid)
          .maybeSingle();

      final total = (response?['xp_total'] as int?) ?? 0;
      print('[BLDR CLUB] XP encontrado na tabela club_ranking: $total');
      if (mounted) setState(() => _totalXpState = total);

    } catch (e) {
      print('[BLDR CLUB] Erro ao buscar club_ranking: $e. Definindo XP como 0.');
      if (mounted) setState(() => _totalXpState = 0);
    }
  }

  void _subscribeToXpChanges() {
    final client = Supabase.instance.client;
    final uid = _userId;
    if (uid == null) return;

    _xpChannel?.unsubscribe();

    _xpChannel = client.channel('realtime_bldr_ranking_$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'bldr_club',
        table: 'club_ranking',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (payload) {
          print('[BLDR CLUB] Realtime: Mudança detectada em club_ranking.');
          final newRecord = payload.newRecord;
          if (newRecord != null && newRecord['xp_total'] != null) {
            final total = (newRecord['xp_total'] as num).toInt();
            print('[BLDR CLUB] Novo XP total via realtime: $total');
            if (mounted) setState(() => _totalXpState = total);
          } else {
            _fetchTotalXpForUser();
          }
        },
      )
      ..subscribe((status, err) {
        print('[BLDR CLUB] Canal Ranking status=$status err=$err');
      });
  }

  Future<void> _loadFromSupabase() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final client = Supabase.instance.client;

      final data = await client
          .schema('bldr_club')
          .from('programs')
          .select(
          'id, name, tagline, level, minutes_per_day, duration_weeks, cover_image, equipment')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(5);

      final items = (data as List).map((m) {
        final minutes = (m['minutes_per_day'] as int?) ?? 30;
        final levelText = clubw.levelLabel(m['level']);
        final hasEquip = ((m['equipment'] as List?) ?? const []).isNotEmpty;
        final equipText = hasEquip ? 'Com equipamentos' : 'Sem equipamentos';
        final subtitle = '$equipText • $minutes min';
        return ProgramCardData(
          id: m['id'] as String,
          title: (m['name'] ?? '').toString(),
          subtitle: subtitle,
          badge: levelText,
          imageUrl: (m['cover_image'] ?? '').toString(),
        );
      }).toList();

      if (mounted) setState(() => _items = items);
    } catch (e, st) {
      print('[BLDR CLUB] Erro ao carregar programas: $e\n$st');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _xpChannel?.unsubscribe();
    _xpChannel = null;
    _stopBillboard();
    _billboardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalXp = _totalXpState;
    final xpPerLevel = widget.xpPerLevel;

    final level = (totalXp ~/ xpPerLevel) + 1;
    final currentXP = (totalXp % xpPerLevel).toDouble();
    final progress = (currentXP / xpPerLevel).clamp(0.0, 1.0);
    final programs = _items;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: const PantherFab(), // <-- LINHA 2 ADICIONADA AQUI
      body: Stack(
        children: [
          const _GoldRadialBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _Header(
                      logoPath:
                      'assets/images/bldr_club_logo_semfundo copy.png',
                      logoHeight: 200,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _LevelProgressCard(
                      level: level,
                      currentXP: currentXP.toInt(),
                      xpPerLevel: xpPerLevel,
                      progress: progress,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PrimaryAction(
                            icon: Icons.emoji_events_outlined,
                            label: 'Ranking',
                            onTap: () => Navigator.of(context)
                                .pushNamed('/bldr-club/ranking'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PrimaryAction(
                            icon: Icons.fitness_center_outlined,
                            label: 'Treinos',
                            onTap: () => Navigator.of(context)
                                .pushNamed('/bldr-club/treinos'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PrimaryAction(
                            icon: Icons.sports_soccer_outlined,
                            label: 'Esportes',
                            onTap: () => Navigator.of(context)
                                .pushNamed('/bldr-club/esportes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PrimaryAction(
                            icon: Icons.groups_2_outlined,
                            label: 'Comunidade',
                            onTap: () => Navigator.of(context)
                                .pushNamed('/bldr-club/comunidade'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: _communityDataLoading
                        ? const SizedBox(height: 200)
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _sectionTitle(context, 'Anúncios'),
                              const SizedBox(height: 10),
                              if (_annWithImages.isNotEmpty)
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF121212),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0x22D4AF37)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Listener(
                                      onPointerDown: (_) => _stopBillboard(),
                                      onPointerUp: (_) => _startBillboard(),
                                      child: PageView.builder(
                                        controller: _billboardCtrl,
                                        onPageChanged: (i) => _billboardIndex = i,
                                        itemCount: _annWithImages.length,
                                        itemBuilder: (_, i) => _BillboardItem(
                                          data: _annWithImages[i],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const _EmptyStrip(
                                  icon: Icons.campaign_outlined,
                                  text: 'Sem anúncios',
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _sectionTitle(context, 'Eventos'),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 200,
                                child: _events.isEmpty
                                    ? const _EmptyStrip(
                                  icon: Icons.event_outlined,
                                  text: 'Nenhum evento',
                                )
                                    : ListView.separated(
                                  scrollDirection: Axis.vertical,
                                  padding: EdgeInsets.zero,
                                  itemCount: _events.length > 2 ? 2 : _events.length,
                                  separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                                  itemBuilder: (_, i) =>
                                      _EventCard(data: _events[i]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                    child: Column(
                      children: [
                        Text('Programas de Treino',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 4),
                        Text('Exclusivo BLDR CLUB',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: Colors.grey[400],
                            )),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error.isNotEmpty
                        ? const _ErrorBoxCompact()
                        : PageView.builder(
                      controller: _pageController,
                      itemCount: programs.length,
                      itemBuilder: (context, index) {
                        final data = programs[index];
                        final isCurrent = index == _currentPage;
                        return AnimatedScale(
                          scale: isCurrent ? 1.0 : 0.96,
                          duration:
                          const Duration(milliseconds: 200),
                          child: _ProgramCard(
                            data: data,
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProgramDetailPage(
                                    programId: data.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        programs.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? gold
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 28),
                    child: Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text('Ver todos os programas'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ClubProgramsPage()),
                        ),
                      ),
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.logoPath, this.logoHeight = 56});
  final String logoPath;
  final double logoHeight;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: logoHeight + 28,
      child: Center(
        child:
        Image.asset(logoPath, height: logoHeight, fit: BoxFit.contain),
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({
    required this.level,
    required this.currentXP,
    required this.xpPerLevel,
    required this.progress,
  });
  final int level;
  final int currentXP;
  final int xpPerLevel;
  final double progress;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nível $level',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFF1E1E1E),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
            ),
          ),
          const SizedBox(height: 8),
          Text('$currentXP / $xpPerLevel XP',
              style:
              theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400])),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x22D4AF37)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.amberAccent, size: 26),
              const SizedBox(height: 8),
              Text(widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.data, required this.onOpen});
  final ProgramCardData data;
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
                color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[400])),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                clubw.BldrGoldBadge(data.badge),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: gold,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onPressed: onOpen,
                  child: const Text('Ver programa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProgramCardData {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  const ProgramCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.imageUrl = '',
  });
}

class _GoldRadialBackground extends StatelessWidget {
  const _GoldRadialBackground();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(children: const [
          _RadialBlob(top: -180, opacity: 0.30, radiusFactor: 1.8),
          _RadialBlob(bottom: -140, opacity: 0.18, radiusFactor: 1.6),
          _RadialBlob(center: true, opacity: 0.32, radiusFactor: 1.2),
        ]),
      ),
    );
  }
}

class _RadialBlob extends StatelessWidget {
  const _RadialBlob(
      {this.top,
        this.bottom,
        this.center = false,
        required this.opacity,
        required this.radiusFactor});
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
          SizedBox(height: 8),
          Text('Erro ao carregar', style: TextStyle(color: Colors.white70)),
        ]),
      ),
    );
  }
}


// ===============================================================
// =========== WIDGETS COPIADOS DE comunidade_screen.dart ==========
// ===============================================================

class _BillboardItem extends StatelessWidget {
  const _BillboardItem({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final img = (data['image_url_main'] ?? data['image_url'] ?? '').toString().trim();
    final link = (data['link_url'] ?? '').toString();

    Widget imageContent = SizedBox.expand( // Adicionei SizedBox.expand para preencher o pai
      child: Image.network(
        img,
        fit: BoxFit.cover, // Garante que a imagem cobre todo o espaço, cortando se necessário
        errorBuilder: (_, __, ___) => Container(
          alignment: Alignment.center,
          color: const Color(0xFF1E1E1E),
          child: const Icon(Icons.image, color: Colors.white38),
        ),
      ),
    );

    if (link.isNotEmpty) {
      return InkWell(
        onTap: () async {
          final uri = Uri.tryParse(link);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: imageContent,
      );
    }

    return imageContent;
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? '').toString();
    final desc = (data['description'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final createdAt =
    DateTime.tryParse((data['created_at'] ?? '').toString())?.toLocal();
    final when = createdAt == null
        ? ''
        : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22D4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 4),
          // ===============================================================
          // =========== CORREÇÃO DEFINITIVA: Expanded removido ===========
          // ===============================================================
          // O Texto agora ocupa apenas o espaço que precisa, sem expandir.
          Text(
            desc,
            overflow: TextOverflow.ellipsis,
            maxLines: 4,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 8), // Aumentei o espaço para compensar a falta do Spacer/Expanded
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: Colors.amberAccent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.watch_later_outlined,
                  size: 14, color: Colors.amberAccent),
              const SizedBox(width: 4),
              Text(
                when,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStrip extends StatelessWidget {
  const _EmptyStrip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center,),
        ],
      ),
    );
  }
}