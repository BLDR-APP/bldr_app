// lib/presentation/bldr_club/esportes_screen.dart

import 'package:flutter/material.dart';

class EsportesScreen extends StatelessWidget {
  const EsportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fundo com gradiente radial dourado
          const _GoldRadialBackground(),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header com a imagem do esporte
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _Header(
                      logoPath: 'assets/images/bldr_club_esportes.png', // Substitua este caminho
                      logoHeight: 160,
                      showBackButton: true, // Adiciona o botão de voltar
                    ),
                  ),
                ),

                // Conteúdo Principal: Apenas a mensagem de "Em breve"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(
                        'Em breve no BLDR CLUB....⏳🔥',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.normal, // Alterado
                          fontStyle: FontStyle.italic, // Adicionado
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                // O código para a lista de esportes ficará aqui,
                // mas está comentado por enquanto.
                //
                // /*
                // SliverToBoxAdapter(
                //   child: Container(
                //     padding: const EdgeInsets.all(16),
                //     child: Column(
                //       children: [
                //         const SizedBox(height: 40),
                //
                //         // Exemplo de como a lista de esportes será implementada futuramente.
                //         final List<String> sports = [
                //           'Tenis',
                //           'Beach Tenis',
                //           'Corrida',
                //           'Yoga',
                //           'Pilates',
                //           'Padel',
                //         ];
                //
                //         ListView.builder(
                //           shrinkWrap: true,
                //           physics: const NeverScrollableScrollPhysics(),
                //           itemCount: sports.length,
                //           itemBuilder: (context, index) {
                //             final sport = sports[index];
                //             return Card(
                //               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                //               child: ListTile(
                //                 title: Text(sport),
                //                 // onTap: () {
                //                 //   // Lógica para navegação para a tela do esporte específico
                //                 // },
                //               ),
                //             );
                //           },
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // */
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ====================== UI COMPONENTES REUTILIZADOS ====================== */

class _Header extends StatelessWidget {
  const _Header({
    required this.logoPath,
    this.logoHeight = 56,
    this.showBackButton = false,
  });
  final String logoPath;
  final double logoHeight;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: logoHeight + 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ícone de voltar, se ativado
          if (showBackButton)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          // Logo do esporte
          Center(
            child: Image.asset(logoPath, height: logoHeight, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
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
          gradient: RadialGradient(colors: [c, c.withOpacity(0)], radius: 0.75),
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