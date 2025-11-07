// esportes_screen.dart (Atualizado para consumir a Edge Function)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===================================================================
// MODELO ATUALIZADO
// ===================================================================
class PerformancePlan {
  final String id;
  final String sport;
  final String title;
  final String subtitle;
  final String sportContextTag;
  // MODIFICADO: Campo para o JSON do plano agora está ativo
  final Map<String, dynamic> planJson;

  PerformancePlan({
    required this.id,
    required this.sport,
    required this.title,
    required this.subtitle,
    required this.sportContextTag,
    // MODIFICADO: Adicionado ao construtor
    required this.planJson,
  });

  // MODIFICADO: Método para serializar para o Supabase (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sport': sport,
      'title': title,
      'subtitle': subtitle,
      'sportContextTag': sportContextTag,
      // MODIFICADO: Serializa o plano
      'planJson': planJson,
    };
  }

  // MODIFICADO: Método para desserializar do Supabase (JSON)
  factory PerformancePlan.fromJson(Map<String, dynamic> json) {
    return PerformancePlan(
      id: json['id'],
      sport: json['sport'],
      title: json['title'],
      subtitle: json['subtitle'],
      sportContextTag: json['sportContextTag'],
      // MODIFICADO: Desserializa o plano
      planJson: json['planJson'] as Map<String, dynamic>,
    );
  }
}

class EsportesScreen extends StatefulWidget {
  const EsportesScreen({super.key});

  @override
  State<EsportesScreen> createState() => _EsportesScreenState();
}

class _EsportesScreenState extends State<EsportesScreen> {
  // Estados da tela
  bool _isLoading = true;
  bool _isGeneratingPlan = false;

  List<String> _userSports = [];
  List<PerformancePlan> _generatedPlans = [];

  final TextEditingController _otherSportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDataFromSupabase(); // Carrega esportes E planos salvos
  }

  @override
  void dispose() {
    _otherSportController.dispose();
    super.dispose();
  }

  // ===================================================================
  // Lógica de Carregamento de Dados (SEM ALTERAÇÕES)
  // (Agora funciona com o 'planJson' graças ao modelo atualizado)
  // ===================================================================
  Future<void> _loadDataFromSupabase() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Nenhum usuário logado.');
      }
      final userId = user.id;

      final profileData = await Supabase.instance.client
          .from('user_profiles')
          .select('onboarding_data, performance_plans')
          .eq('id', userId)
          .single();

      // 1. Processa os Esportes (activity_details)
      List<String> sports = [];
      if (profileData.containsKey('onboarding_data') &&
          profileData['onboarding_data'] != null) {
        final onboardingData =
        profileData['onboarding_data'] as Map<String, dynamic>;

        if (onboardingData.containsKey('activity_details')) {
          final activityDetailsMap =
          onboardingData['activity_details'] as Map<String, dynamic>?;

          if (activityDetailsMap != null) {
            final allSportKeys = activityDetailsMap.keys.toList();
            sports = allSportKeys
                .where((sportName) => sportName.toLowerCase() != 'musculação')
                .toList();
          }
        }
      }

      // 2. Processa os Planos de Performance Salvos
      List<PerformancePlan> savedPlans = [];
      if (profileData.containsKey('performance_plans') &&
          profileData['performance_plans'] != null) {
        final plansData = profileData['performance_plans'] as List;

        savedPlans = plansData
            .map((planJson) =>
            PerformancePlan.fromJson(planJson as Map<String, dynamic>))
            .toList();
      }

      // 3. Atualiza o estado da tela com os dados carregados
      if (mounted) {
        setState(() {
          _userSports = sports;
          _generatedPlans = savedPlans;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar perfil do usuário: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao carregar dados: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ===================================================================
  // FLUXO 1: Gerar Plano de Performance (MODIFICADO)
  // ===================================================================
  Future<void> _handleGeneratePerformancePlan(String sport) async {
    final sportName = sport.trim();
    if (sportName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite o nome do esporte.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPlan = true;
    });

    // =============================================================
    // NOVO BLOCO: Chamada real à Edge Function
    // =============================================================
    try {
      // 1. Chama a Edge Function 'gerar-plano-performance'
      final response = await Supabase.instance.client.functions.invoke(
        'gerar-plano-performance',
        body: {'sport': sportName},
      );

      // Trata se a função Supabase deu erro (ex: 500, 401)
      if (response.status != 200 || response.data == null) {
        final errorMsg =
            response.data?['error'] ?? 'Erro desconhecido ao chamar a função.';
        throw Exception('Falha da API: $errorMsg');
      }

      // 2. Converte a resposta JSON em um objeto PerformancePlan
      // O 'response.data' é o JSON completo que a sua função retorna
      final newPlan =
      PerformancePlan.fromJson(response.data as Map<String, dynamic>);

      // 3. Salva o novo plano no Supabase (na coluna 'performance_plans')
      await _savePlanToSupabase(newPlan);

      // 4. Atualiza a UI (adiciona o card e para o loading)
      if (mounted) {
        setState(() {
          _generatedPlans.add(newPlan); // Adiciona na lista local
          _isGeneratingPlan = false;
        });
      }
      _otherSportController.clear();

    } catch (e) {
      // Trata erros de rede, timeout, ou o 'throw' acima
      debugPrint('Erro ao chamar Edge Function ou salvar: $e');
      if (mounted) {
        setState(() {
          _isGeneratingPlan = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao gerar plano: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    // =============================================================
    // FIM DO NOVO BLOCO
    // =============================================================
  }

  // ===================================================================
  // Função para salvar o plano no Supabase (SEM ALTERAÇÕES)
  // (Agora funciona com o 'planJson' graças ao modelo atualizado)
  // ===================================================================
  Future<void> _savePlanToSupabase(PerformancePlan newPlan) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuário não logado.');

      // Pega a lista atual e adiciona o novo plano
      final List<PerformancePlan> currentPlans = List.from(_generatedPlans);
      if (!currentPlans.any((plan) => plan.id == newPlan.id)) {
        currentPlans.add(newPlan);
      }

      // Converte a lista de objetos para uma lista de JSONs
      final List<Map<String, dynamic>> jsonData =
      currentPlans.map((plan) => plan.toJson()).toList();

      // Atualiza a coluna 'performance_plans' no perfil do usuário
      await Supabase.instance.client
          .from('user_profiles')
          .update({'performance_plans': jsonData}).eq('id', user.id);

    } catch (e) {
      debugPrint('Erro ao salvar plano: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar o plano: $e'),
              backgroundColor: Colors.red),
        );
      }
      // Se deu erro ao salvar, remove o plano que foi adicionado localmente
      if (mounted) {
        setState(() {
          _generatedPlans.removeWhere((plan) => plan.id == newPlan.id);
        });
      }
    }
  }

  // ===================================================================
  // FLUXO 2: Gerar Plano de Hipertrofia (COMENTADO)
  // ===================================================================
  /*
  Future<void> _handleGenerateHypertrophyPlan() async {
    setState(() {
      _isGeneratingPlan = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    // ... (lógica de salvar na biblioteca) ...
    setState(() {
      _isGeneratingPlan = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Seu treino foi salvo na Biblioteca de Treinos do hub do HAVOK.'),
        action: SnackBarAction(
          label: 'VER',
          onPressed: () { ...Navegar... },
        ),
      ),
    );
  }
  */

  // ===================================================================
  // Ação para o Cenário C
  // ===================================================================
  void _handleAddSport() async {
    // TODO: Navegar para a tela de Perfil
    // bool? userUpdatedSports = await Navigator.push(context, ...);

    // if (userUpdatedSports == true) {
    //   _loadDataFromSupabase(); // Recarrega esportes E planos
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegando para o Perfil para adicionar esportes...'),
      ),
    );
  }

  // ===================================================================
  // Build (SEM ALTERAÇÕES)
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _GoldRadialBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            )
                : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _Header(
                      logoPath: 'assets/images/bldr_club_esportes.png',
                      logoHeight: 160,
                      showBackButton: true,
                    ),
                  ),
                ),
                // Conteúdo Principal
                ..._buildContentSlivers(_userSports),
              ],
            ),
          ),
          if (_isGeneratingPlan) _buildLoadingModal(),
        ],
      ),
    );
  }

  // ===================================================================
  // Métodos de Build da UI (SEM ALTERAÇÕES)
  // ===================================================================

  List<Widget> _buildContentSlivers(List<String> userSports) {
    final List<Widget> slivers = [];

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Esportes & Performance',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    // Seção "Meus Planos de Performance"
    slivers.add(_buildMyPlansSectionSliver());

    // Seção "Gerar Novo Plano"
    if (userSports.isEmpty) {
      slivers.add(_buildScenarioCSliver(context));
    } else if (userSports.length == 1) {
      slivers.add(_buildScenarioBSliver(context, userSports));
    } else {
      slivers.add(_buildScenarioASliver(context, userSports));
    }

    return slivers;
  }

  Widget _buildMyPlansSectionSliver() {
    if (_generatedPlans.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Text(
              'Nenhum plano de performance gerado ainda.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Text(
              'Meus Planos de Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._generatedPlans
                .map((plan) => _buildPerformanceCard(context, plan))
                .toList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, PerformancePlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFD4AF37).withOpacity(0.15),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          // AGORA FUNCIONA: Você pode passar o plano detalhado
          // para a próxima tela.
          debugPrint('Navegando com o plano: ${plan.planJson}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando para detalhes do ${plan.title}')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioASliver(
      BuildContext context, List<String> userSports) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Text(
              'Vimos que você pratica múltiplos esportes. Para qual deles a IA HAVOK deve gerar um plano de performance agora?',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 24),
            ...userSports.map((sport) {
              if (sport == 'Outro') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildOtherSportInputWidget(context),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildSportButton(context, sport, isPrimary: true),
                );
              }
            }).toList(),
            // const SizedBox(height: 8), // COMENTADO
            // _buildHypertrophyButton(context), // COMENTADO
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioBSliver(
      BuildContext context, List<String> userSports) {
    final sport = userSports.first;

    if (sport == 'Outro') {
      return _buildScenarioB_OtherSliver(context);
    } else {
      return _buildScenarioB_DefinedSliver(context, sport);
    }
  }

  Widget _buildScenarioB_OtherSliver(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Text(
              'Vimos que você pratica outro esporte. Para a IA HAVOK gerar um plano de performance, digite qual é:',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 24),
            _buildOtherSportInputWidget(context),
            // const SizedBox(height: 12), // COMENTADO
            // _buildHypertrophyButton(context), // COMENTADO
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioB_DefinedSliver(BuildContext context, String sport) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Text(
              'Detectamos que você pratica $sport. A IA HAVOK pode criar um plano de performance especializado para aumentar sua explosão e agilidade.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 24),
            _buildSportButton(context, sport, isPrimary: true),
            // const SizedBox(height: 12), // COMENTADO
            // _buildHypertrophyButton(context), // COMENTADO
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCSliver(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Text(
              'Você pratica algum esporte? Deixe a IA HAVOK criar um plano de performance para te ajudar a evoluir.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 24),
            _buildAddSportButton(context),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // Componentes de UI (Botões e Modal) (SEM ALTERAÇÕES)
  // ===================================================================

  Widget _buildOtherSportInputWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual é o outro esporte?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otherSportController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ex: Crossfit, Natação...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
              ),
            ),
            onSubmitted: (value) {
              _handleGeneratePerformancePlan(value);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37), // Dourado
                foregroundColor: Colors.black, // Texto preto
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _handleGeneratePerformancePlan(_otherSportController.text);
              },
              child: const Text('Gerar Plano para este Esporte'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportButton(BuildContext context, String sport,
      {bool isPrimary = false}) {
    final style = isPrimary
        ? FilledButton.styleFrom(
      backgroundColor: const Color(0xFFD4AF37), // Dourado
      foregroundColor: Colors.black, // Texto preto
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    )
        : ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD4AF37), // Dourado
      foregroundColor: Colors.black, // Texto preto
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: style,
        onPressed: () => _handleGeneratePerformancePlan(sport),
        child: Text('Gerar Plano para $sport'),
      ),
    );
  }

  // Botão "Plano de hipertrofia" (COMENTADO)
  /*
  Widget _buildHypertrophyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: _handleGenerateHypertrophyPlan,
        child: const Text('Não, prefiro um plano de hipertrofia'),
      ),
    );
  }
  */

  Widget _buildAddSportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37), // Dourado
          foregroundColor: Colors.black, // Texto preto
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _handleAddSport,
        child: const Text('Adicionar meu Esporte'),
      ),
    );
  }

  Widget _buildLoadingModal() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(height: 24),
            Text(
              'Aguarde, a IA HAVOK está criando seu plano...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ====================== UI COMPONENTES REUTILIZADOS ====================== */
// (Componentes _Header e _GoldRadialBackground permanecem inalterados)
/* ======================================================================= */

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
          if (showBackButton)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          Center(
            child:
            Image.asset(logoPath, height: logoHeight, fit: BoxFit.contain),
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