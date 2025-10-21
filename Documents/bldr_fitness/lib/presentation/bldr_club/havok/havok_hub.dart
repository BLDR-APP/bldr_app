import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// Imports para as novas telas
import 'workout_library_screen.dart';
import 'free_workout_screen.dart';
import 'recipe_results_screen.dart';
import 'recipe_library_screen.dart';

// Importe os mesmos serviços que o seu GreetingHeaderWidget usa
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';


// Definição das cores para fácil reutilização e consistência
const Color goldColor = Color(0xFFD4AF37); // Um tom de dourado clássico
const Color darkBackgroundColor = Color(0xFF121212); // Um preto profundo, não puro
const Color cardBackgroundColor = Color(0xFF1E1E1E); // Um cinza escuro para os cards

class HavokHubScreen extends StatefulWidget {
  const HavokHubScreen({super.key});

  @override
  State<HavokHubScreen> createState() => _HavokHubScreenState();
}

class _HavokHubScreenState extends State<HavokHubScreen> {
  String _userName = '';
  bool _isLoadingName = true;
  final ValueNotifier<bool> _showSpeechBubble = ValueNotifier(false);

  // ===============================================================
  // =========== ALTERAÇÃO APLICADA AQUI ===========
  // ===============================================================
  // 1. Nova variável para controlar a "prontidão" do modelo 3D.
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    // 2. Lógica de tempo ajustada e sincronizada.
    // Espera um tempo para o modelo carregar e então mostra tudo em cascata.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        // Marca que o modelo está pronto (isso inicia a transição do loading para o mascote)
        setState(() => _isModelReady = true);

        // Agenda o balão para aparecer logo após a animação de entrada do mascote...
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showSpeechBubble.value = true;
            // ...e desaparecer 6 segundos depois.
            Future.delayed(const Duration(seconds: 6), () {
              if (mounted) {
                _showSpeechBubble.value = false;
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _showSpeechBubble.dispose();
    super.dispose();
  }
  // ===============================================================
  // =========== FIM DA ALTERAÇÃO ===========
  // ===============================================================

  Future<void> _loadUserName() async {
    // Garante que o usuário está autenticado
    if (!AuthService.instance.isAuthenticated) {
      if (mounted) setState(() {
        _userName = 'Visitante';
        _isLoadingName = false;
      });
      return;
    }

    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      final fullName = profile?.fullName;

      if (mounted) {
        setState(() {
          // Se o nome não estiver vazio, use-o. Senão, use o email como fallback.
          if (fullName != null && fullName.isNotEmpty) {
            _userName = fullName;
          } else {
            _userName = AuthService.instance.getCurrentUserEmail()?.split('@')[0] ?? 'Usuário';
          }
          _isLoadingName = false;
        });
      }
    } catch (error) {
      debugPrint('Erro ao carregar o nome do usuário no Havok Hub: $error');
      if (mounted) {
        setState(() {
          // Fallback para o email em caso de erro
          _userName = AuthService.instance.getCurrentUserEmail()?.split('@')[0] ?? 'Usuário';
          _isLoadingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'HAVOK',
          style: TextStyle(
            color: goldColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // ===============================================================
                // =========== ALTERAÇÃO APLICADA AQUI ===========
                // ===============================================================
                // 3. Usamos um AnimatedSwitcher para a transição suave entre o loading e o mascote.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _isModelReady
                  // Se o modelo estiver "pronto", mostra o Stack com o mascote e o balão
                      ? Stack(
                    key: const ValueKey('model_ready'),
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: 250,
                        child: ModelViewer(
                          src: 'assets/models/Havok_Pantera.glb',
                          alt: "Mascote Pantera do Havok",
                          ar: false,
                          autoRotate: true,
                          disableZoom: true,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      Positioned(
                        top: 20, // Posição vertical
                        right: 0, // Posição horizontal (canto direito)
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _showSpeechBubble,
                          builder: (context, show, child) {
                            return AnimatedOpacity(
                              opacity: show ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              child: const SpeechBubble(
                                message: 'Olá! Eu sou o Havok, a IA do BLDR, feita para te atender exclusivamente.',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                  // Senão, mostra um placeholder com o indicador de carregamento
                      : Container(
                    key: const ValueKey('model_loading'),
                    height: 250,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: goldColor),
                  ),
                ),
                // ===============================================================
                // =========== FIM DA ALTERAÇÃO ===========
                // ===============================================================
                const SizedBox(height: 20),
                Text(
                  _isLoadingName ? 'Carregando...' : 'Olá, $_userName',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pronto para superar seus limites?',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 30),
                _TrainingModule(),
                const SizedBox(height: 24),
                _NutritionModule(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _TrainingModule extends StatefulWidget {
  @override
  State<_TrainingModule> createState() => _TrainingModuleState();
}

class _TrainingModuleState extends State<_TrainingModule> {
  bool _isLoading = false;

  Future<void> _gerarTreinoHavok() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke('gerar-treino-havok');
      if (response.status == 200) {
        // MANTIDO EXATAMENTE COMO NO SEU CÓDIGO ORIGINAL
        print('Sucesso! Resposta da IA: ${response.data}');
      } else {
        print('Erro na execução da função. Status: ${response.status}');
      }
    } catch (error) {
      print('Um erro inesperado ocorreu ao chamar a função: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: goldColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GERAÇÃO DE TREINO',
            textAlign: TextAlign.center,
            style: TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.1),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              disabledBackgroundColor: goldColor.withOpacity(0.5),
            ),
            onPressed: _isLoading ? null : _gerarTreinoHavok,
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            )
                : const Text(
                'GERAR TREINO HAVOK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutLibraryScreen()));
                },
                child: const Text('Acessar Biblioteca', style: TextStyle(color: goldColor)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FreeWorkoutScreen()));
                },
                child: const Text('Criar Treino Livre', style: TextStyle(color: goldColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionModule extends StatefulWidget {
  @override
  State<_NutritionModule> createState() => _NutritionModuleState();
}

class _NutritionModuleState extends State<_NutritionModule> {
  bool _isLoading = false;
  final _textController = TextEditingController();

  Future<void> _generateRecipe(String userQuery) async {
    if (userQuery.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'gerar-receita-havok',
        body: {'userQuery': userQuery},
      );

      if (response.status == 200 && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeResultsScreen(recipeData: response.data),
          ),
        );
      } else {
        throw 'A IA não conseguiu gerar a receita. Tente novamente.';
      }
    } catch (e) {
      print('Erro ao gerar receita: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: goldColor.withOpacity(0.5), width: 1),
      ),
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: Opacity(
          opacity: _isLoading ? 0.5 : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('NUTRIÇÃO INTELIGENTE', textAlign: TextAlign.center, style: TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Quais ingredientes você tem aí?',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, color: goldColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: goldColor),
                      ),
                    ),
                    onSubmitted: (query) => _generateRecipe(query),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CategoryIcon(icon: Icons.local_fire_department, label: 'Pós-treino', onTap: () => _generateRecipe('Pós-treino')),
                      _CategoryIcon(icon: Icons.breakfast_dining, label: 'Café da manhã', onTap: () => _generateRecipe('Café da manhã')),
                      _CategoryIcon(icon: Icons.lunch_dining, label: 'Almoço', onTap: () => _generateRecipe('Almoço')),
                      _CategoryIcon(icon: Icons.dinner_dining, label: 'Jantar', onTap: () => _generateRecipe('Jantar')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeLibraryScreen()));
                      },
                      child: const Text('Acessar Biblioteca de Receitas', style: TextStyle(color: goldColor)),
                    ),
                  ),
                ],
              ),
              if (_isLoading) const CircularProgressIndicator(color: goldColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: goldColor, size: 30), onPressed: onTap),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}

class SpeechBubble extends StatelessWidget {
  final String message;

  const SpeechBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220), // Limita a largura do balão
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor, // Fundo cinza escuro
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: goldColor.withOpacity(0.7)), // Borda dourada
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
      ),
    );
  }
}