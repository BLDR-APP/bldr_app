// lib/presentation/bldr_club/comunidade_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- para abrir link_url

import '../../services/community_service.dart';

class ComunidadeScreen extends StatefulWidget {
  const ComunidadeScreen({super.key});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> with TickerProviderStateMixin {
  static const gold = Color(0xFFD4AF37);

  final _svc = CommunityService.instance;

  // DATA
  String? _gender; // 'female'|'male'|'other'|null
  List<Map<String, dynamic>> _ann = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _feed = [];
  String? _feedCursor;

  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';

  // --- Anúncios texto: rolagem contínua (como você tinha)
  final _annScrollCtrl = ScrollController();
  Timer? _annTicker;

  // --- Billboard (imagens Canva): auto page
  final PageController _billboardCtrl = PageController(viewportFraction: 0.92);
  Timer? _billboardTimer;
  int _billboardIndex = 0;

  List<Map<String, dynamic>> get _annWithImages {
    return _ann.where((a) {
      final url = (a['image_url'] ?? '').toString().trim();
      return url.isNotEmpty;
    }).toList();
  }

  List<Map<String, dynamic>> get _annTextOnly {
    return _ann.where((a) {
      final url = (a['image_url'] ?? '').toString().trim();
      return url.isEmpty;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _stopTextTicker();
    _stopBillboard();
    _annScrollCtrl.dispose();
    _billboardCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final g = await _svc.getMyGender();
      final ann = await _svc.fetchAnnouncements();
      final evs = await _svc.fetchEvents(limit: 10);
      final rms = await _svc.fetchRooms();
      final feed = await _svc.fetchFeed(limit: 10);

      // Controla autoplay conforme o tipo de anúncio disponível
      _stopTextTicker();
      _stopBillboard();
      if (ann.isNotEmpty) {
        if (ann.any((a) => ((a['image_url'] ?? '').toString().trim().isNotEmpty))) {
          _startBillboard(); // tem imagens -> carrossel
        } else if (ann.length > 1) {
          _startTextTicker(); // só texto -> marquee
        }
      }

      setState(() {
        _gender = g;
        _ann = ann;
        _events = evs;
        _rooms = rms;
        _feed = feed;
        _feedCursor = feed.isEmpty ? null : feed.last['created_at']?.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ======== FEED PAGINAÇÃO =========
  Future<void> _loadMore() async {
    if (_loadingMore || _feedCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _svc.fetchFeed(cursorIso: _feedCursor, limit: 10);
      setState(() {
        _feed.addAll(more);
        _feedCursor = more.isEmpty ? null : more.last['created_at']?.toString();
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // ======== ROOMS ACCESS =========
  void _openRoom(Map<String, dynamic> room) {
    final womenOnly =
        room['women_only'] == true || room['is_female_only'] == true;
    final canEnter = !womenOnly || _gender == 'female';

    if (!canEnter) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Acesso restrito',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Esta sala é exclusiva para mulheres.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      '/bldr-club/chat',
      arguments: {'room': room},
    );
  }

  // ======== TEXT TICKER (marquee) =========
  void _startTextTicker() {
    _annTicker?.cancel();
    _annTicker = Timer.periodic(const Duration(milliseconds: 18), (_) {
      if (!mounted || !_annScrollCtrl.hasClients) return;
      final pos = _annScrollCtrl.offset;
      final max = _annScrollCtrl.position.maxScrollExtent;
      final next = pos + 0.8; // velocidade mais suave
      if (next >= max) {
        _annScrollCtrl.jumpTo(0);
      } else {
        _annScrollCtrl.jumpTo(next);
      }
    });
  }

  void _stopTextTicker() {
    _annTicker?.cancel();
    _annTicker = null;
  }

  // ======== BILLBOARD (PageView autoplay) =========
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const _GoldRadialBackground(),
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor:
                const AlwaysStoppedAnimation<Color>(_ComunidadeScreenState.gold),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _GoldRadialBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: gold,
              onRefresh: _bootstrap,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Logo e botão de voltar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _Header(
                        logoPath: 'assets/images/bldr_club_comunidade.png',
                        logoHeight: 160,
                      ),
                    ),
                  ),

                  // Contexto
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ContextCard(gender: _gender),
                    ),
                  ),

                  // ======== Anúncios ========
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Column(
                        children: [
                          _sectionTitle(context, 'Anúncios'),
                          const SizedBox(height: 10),

                          // 1) Billboard (imagens do Canva)
                          if (_annWithImages.isNotEmpty)
                            SizedBox(
                              // 💡 AUMENTADO: de 142 para 200
                              height: 200,
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

                          // 2) Fallback: Marquee de texto (como estava)
                          if (_annWithImages.isEmpty)
                            (_annTextOnly.isEmpty)
                                ? const _EmptyStrip(
                                icon: Icons.campaign_outlined,
                                text: 'Sem anúncios no momento')
                                : SizedBox(
                              // 💡 AUMENTADO: de 120 para 180
                              height: 180,
                              child: ListView.builder(
                                controller: _annScrollCtrl,
                                scrollDirection: Axis.horizontal,
                                itemCount: _annTextOnly.length * 1000,
                                itemBuilder: (context, i) {
                                  final ann = _annTextOnly[i % _annTextOnly.length];
                                  return _AnnouncementCard(data: ann);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Eventos
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          _sectionTitle(context, 'Eventos'),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: _events.isEmpty
                                ? const _EmptyStrip(
                              icon: Icons.event_outlined,
                              text: 'Nenhum evento futuro',
                            )
                                : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(right: 8),
                              itemCount: _events.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                              itemBuilder: (_, i) =>
                                  _EventCard(data: _events[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Salas de Chat (todas visíveis; bloqueio no onTap)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        children: [
                          _sectionTitle(context, 'Salas de Chat'),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 92,
                            child: _rooms.isEmpty
                                ? const _EmptyStrip(
                              icon: Icons.forum_outlined,
                              text: 'Nenhuma sala disponível',
                            )
                                : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _rooms.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final room = _rooms[i];
                                final womenOnly = room['women_only'] == true ||
                                    room['is_female_only'] == true;
                                final canEnter =
                                !(womenOnly && _gender != 'female');
                                return _RoomPill(
                                  data: room,
                                  canEnter: canEnter,
                                  onTap: () => _openRoom(room),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Feed
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: _sectionTitle(context, 'Feed da Comunidade'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) {
                          // sentinela de "carregar mais"
                          if (i == _feed.length) {
                            if (_feedCursor == null) {
                              return const SizedBox.shrink();
                            }
                            _loadMore();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    const AlwaysStoppedAnimation<Color>(_ComunidadeScreenState.gold),
                                  ),
                                ),
                              ),
                            );
                          }
                          return _PostCard(data: _feed[i]);
                        },
                        childCount: _feed.length + 1,
                      ),
                    ),
                  ),

                  if (_error.isNotEmpty)
                    const SliverToBoxAdapter(child: _ErrorBoxCompact()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) {
    return Column(
      children: [
        Text(
          t,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 44,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Image.asset(logoPath, height: logoHeight, fit: BoxFit.contain),
          ),
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.gender});
  final String? gender;

  @override
  Widget build(BuildContext context) {
    final female = gender == 'female';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: Row(
        children: [
          Icon(
            female ? Icons.lock : Icons.public,
            color: female ? Colors.amberAccent : _ComunidadeScreenState.gold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              female ? 'Acesso Feminino Ativo' : 'Acesso Geral',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de anúncio de texto (fallback)
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? '').toString();
    final body = (data['body'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22D4AF37)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: Colors.amberAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    // 💡 AUMENTADO: de maxLines: 2 para maxLines: 4
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Billboard de imagem (Canva)
class _BillboardItem extends StatelessWidget {
  const _BillboardItem({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final img = (data['image_url'] ?? '').toString();
    final link = (data['link_url'] ?? '').toString();

    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22D4AF37)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 6, // formato “banner” wide; ajusta como preferir
          child: Image.network(
            img,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              alignment: Alignment.center,
              color: const Color(0xFF1E1E1E),
              child: const Icon(Icons.image, color: Colors.white38),
            ),
          ),
        ),
      ),
    );

    if (link.isNotEmpty) {
      card = InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final uri = Uri.tryParse(link);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: card,
      );
    }

    return card;
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
      width: 260,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            maxLines: 7,
            overflow: TextOverflow.ellipsis,
            style:
            Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.watch_later_outlined,
                  size: 14, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Text(
                when,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomPill extends StatelessWidget {
  const _RoomPill(
      {required this.data, required this.canEnter, required this.onTap});

  final Map<String, dynamic> data;
  final bool canEnter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final womenOnly =
        data['women_only'] == true || data['is_female_only'] == true;

    return Opacity(
      opacity: canEnter ? 1.0 : 0.65,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x22D4AF37)),
          ),
          child: Row(
            children: [
              Icon(
                womenOnly ? Icons.lock : Icons.forum_outlined,
                color: womenOnly ? Colors.amberAccent : _ComunidadeScreenState.gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              if (womenOnly)
                Text(
                  'Mulheres',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white54),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final profile = (data['user_profiles'] as Map?) ?? {};
    final name = (profile['full_name'] ?? 'Membro').toString();
    final createdAt =
    DateTime.tryParse((data['created_at'] ?? '').toString())?.toLocal();
    final when = createdAt == null
        ? ''
        : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    final body = (data['body'] ?? '').toString();
    final img = (data['image_url'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22D4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1E1E1E),
                child: Icon(Icons.person, size: 16, color: Colors.white54),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                when,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white54),
              )
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ],
          if (img.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1E1E1E),
                    child: const Icon(Icons.image, color: Colors.white38),
                  ),
                ),
              ),
            ),
          ],
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
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white38),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _ErrorBoxCompact extends StatelessWidget {
  const _ErrorBoxCompact();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(height: 6),
            Text('Erro ao carregar', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _GoldRadialBackground extends StatelessWidget {
  const _GoldRadialBackground();
  @override
  Widget build(BuildContext context) {
    return const PositionedFill();
  }
}

class PositionedFill extends StatelessWidget {
  const PositionedFill({super.key});
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
          gradient:
          RadialGradient(colors: [c, c.withOpacity(0)], radius: 0.75),
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