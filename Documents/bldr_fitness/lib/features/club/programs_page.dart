import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'club_service.dart';
import 'models.dart';
import 'program_detail_page.dart';
import 'widgets.dart' as clubw show BldrGoldBadge, BldrBadgeRow, levelLabel;

class ClubProgramsPage extends StatefulWidget {
  const ClubProgramsPage({super.key});

  @override
  State<ClubProgramsPage> createState() => _ClubProgramsPageState();
}

class _ClubProgramsPageState extends State<ClubProgramsPage> {
  late final BldrClubProgramsService _svc;

  bool _loading = true;
  String _error = '';
  List<ClubProgram> _items = const [];

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
      // ATENÇÃO: listPrograms precisa retornar a URL da imagem no ClubProgram
      final list = await _svc.listPrograms(from: 0, to: 99);
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E11),
        title: const Text('Programas'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _ErrorStateCompact(msg: _error, onRetry: _load)
          : _items.isEmpty
          ? const _EmptyState()
          : Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final p = _items[i];
            return _ProgramGridCard(
              program: p,
              // ✅ CORREÇÃO 1: Usando o nome correto do parâmetro na chamada: coverImage
              coverImage: p.coverImage,
              onOpen: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ProgramDetailPage(programId: p.id),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProgramGridCard extends StatelessWidget {
  const _ProgramGridCard({
    required this.program,
    required this.onOpen,
    // ✅ CAMPO CONSOLIDADO
    required this.coverImage,
  });

  final ClubProgram program;
  final VoidCallback onOpen;
  final String? coverImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(20);

    return InkWell(
      borderRadius: borderRadius,
      onTap: onOpen,
      child: Container(
        // Aplica a borda e o arredondamento ao container externo
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: const Color(0x22D4AF37)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.hardEdge, // Importante para cortar a imagem nas bordas
        child: Stack( // Usamos Stack para sobrepor a imagem e o conteúdo
          children: [
            // 1. IMAGEM DE FUNDO
            Positioned.fill(
              child: (coverImage != null && coverImage!.isNotEmpty)
                  ? Image.network(
                coverImage!,
                fit: BoxFit.cover, // Cobrirá toda a área do card
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF121212));
                },
              )
                  : Container(
                color: const Color(0xFF121212), // Cor de fundo se não houver imagem
              ),
            ),

            // 2. GRADIENTE DE CONTRASTE (Overlay)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54, // Escurece o topo
                      Colors.black87, // Fundo bem escuro para o botão
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // 3. CONTEÚDO (Texto e Botão)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.15),
                  ),

                  // O restante do espaço é preenchido pelo Spacer
                  const Spacer(),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      onPressed: onOpen,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD4AF37),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Ver programa'),
                    ),
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

class _ErrorStateCompact extends StatelessWidget {
  const _ErrorStateCompact({required this.msg, this.onRetry});
  final String msg;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 36),
          const SizedBox(height: 10),
          Text('Erro ao carregar:\n$msg',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente')),
          ],
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Nenhum programa encontrado.',
          style: TextStyle(color: Colors.white70)),
    );
  }
}
