import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:muscle_selector/muscle_selector.dart'; // PACOTE CORRETO

import '../../core/app_export.dart';
import './widgets/card_selection_widget.dart';
import './widgets/multiple_choice_widget.dart';
import './widgets/navigation_buttons_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/question_card_widget.dart';
import './widgets/single_choice_widget.dart';
import './widgets/slider_widget.dart';
import './widgets/summary_widget.dart';

// ADICIONADO: Um widget simples para inputs de formulário
class _FormInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;

  const _FormInputWidget({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext buildContext) {
    return TextFormField(
      controller: controller,
      style: AppTheme.darkTheme.textTheme.bodyLarge
          ?.copyWith(color: AppTheme.textPrimary),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.darkTheme.textTheme.bodyMedium
            ?.copyWith(color: AppTheme.textSecondary),
        suffixText: suffix,
        suffixStyle: AppTheme.darkTheme.textTheme.bodyMedium
            ?.copyWith(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.accentGold, size: 5.w),
        filled: true,
        fillColor: AppTheme.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentGold, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }
        if (double.tryParse(value) == null) {
          return 'Valor inválido';
        }
        return null;
      },
    );
  }
}

// ADICIONADO: Extensão para formatar o texto do Chip
extension StringExtension on String {
  String? get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 15;
  bool _isCompleting = false;

  final Map<String, dynamic> _responses = {
    // Parte 1: Nutrição
    'gender': '', // Tela 2
    'age': 0.0, // Tela 2
    'height': 0.0, // Tela 2
    'weight': 0.0, // Tela 2
    'activity_level': '', // Tela 3
    'regular_activities': <String>[], // Tela 4
    'activity_details': <String, Map<String, int>>{}, // Tela 5
    'body_fat_image': '', // Tela 6 (Salva o 'title', ex: '10-15%')
    'main_goal': '', // Tela 7
    'goal_pace': '', // Tela 8
    // Parte 2: Treino (HAVOK)
    'experience_level': '', // Tela 10
    'workout_frequency_days': 2, // Tela 11 (Slider)
    'workout_duration_range': '', // Tela 11 (Opções)
    'workout_environment': '', // Tela 12
    'home_equipment': <String>[], // Tela 12b (Condicional)
    'muscle_focus': <String>[], // Tela 13 (Usa strings, ex: 'chest')
    'split_preference': '', // Tela 14
    // Identificador de versão e metas serão adicionados em _completeOnboarding
  };

  final _formKeyTela2 = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Map<String, Map<String, TextEditingController>> _activityDetailControllers = {};

  final List<String> _genderOptions = ['Masculino', 'Feminino'];
  final List<Map<String, String>> _activityLevelOptions = [
    {'title': 'Sedentário', 'subtitle': 'Trabalho de escritório, maior parte do tempo sentado.'},
    {'title': 'Levemente Ativo', 'subtitle': 'Fica de pé ou caminha um pouco (ex: professor).'},
    {'title': 'Ativo', 'subtitle': 'Caminha bastante durante o dia (ex: garçom).'},
    {'title': 'Muito Ativo', 'subtitle': 'Trabalho físico intenso (ex: construção).'},
  ];
  final List<String> _regularActivitiesOptions = ['Musculação', 'Crossfit', 'Corrida', 'Ciclismo', 'Futebol', 'Outro'];

  // --- Listas de Imagens de Gordura Corporal ---
  final List<Map<String, dynamic>> _maleBodyFatImages = [
    {'title': '10-15%', 'imagePath': 'assets/images/male_10-15%.png'},
    {'title': '15-20%', 'imagePath': 'assets/images/male_15-20%.png'},
    {'title': '20-25%', 'imagePath': 'assets/images/male_20-25%.png'},
    {'title': '25-30%', 'imagePath': 'assets/images/male_25-30%.png'},
  ];
  final List<Map<String, dynamic>> _femaleBodyFatImages = [
    {'title': '10-15%', 'imagePath': 'assets/images/female_10-15%.png'},
    {'title': '15-20%', 'imagePath': 'assets/images/female_15-20%.png'},
    {'title': '20-25%', 'imagePath': 'assets/images/female_20-25%.png'},
    {'title': '25-30%', 'imagePath': 'assets/images/female_25-30%.png'},
  ];
  // --- FIM ---

  final List<String> _mainGoalOptions = ['Perder Gordura', 'Manter o Peso', 'Ganhar Massa Muscular'];

  final List<String> _paceOptionsLoss = ['Leve', 'Moderado', 'Agressivo'];
  final List<String> _paceOptionsGain = ['Leve', 'Moderado', 'Agressivo'];

  final List<String> _experienceLevels = ['Iniciante (0-6 meses)', 'Intermediário (6 meses - 2 anos)', 'Avançado (Mais de 2 anos)'];
  final List<String> _workoutDurationOptions = ['30-45 min', '45-60 min', '60-90 min', '90+ min'];
  final List<Map<String, dynamic>> _workoutEnvironmentOptions = [
    {'title': 'Academia Completa', 'icon': 'fitness_center'},
    {'title': 'Casa com Equipamentos', 'icon': 'home'},
    {'title': 'Apenas Peso Corporal', 'icon': 'accessibility_new'},
  ];
  final List<String> _homeEquipmentOptions = ['Halteres', 'Kettlebell', 'Elásticos', 'Barra de Pull-up', 'Banco', 'Outro'];
  final List<String> _splitPreferenceOptions = ['Deixe a HAVOK decidir (Recomendado)', 'Full Body (Corpo inteiro)', 'Upper/Lower (Superior/Inferior)', 'Push/Pull/Legs (Empurrar/Puxar/Pernas)', 'ABCDE (Um grupo muscular por dia)'];

  // ADICIONADO: Mapa de tradução para os músculos
  final Map<String, String> _muscleTranslation = {
    'neck': 'Pescoço', 'traps': 'Trapézio', 'shoulders': 'Ombros', 'chest': 'Peito', 'lats': 'Dorsais',
    'triceps': 'Tríceps', 'biceps': 'Bíceps', 'forearm': 'Antebraço', 'abs': 'Abdômen', 'obliques': 'Oblíquos',
    'glutes': 'Glúteos', 'quads': 'Quadríceps', 'hamstrings': 'Posteriores', 'calves': 'Panturrilhas',
    'upper_back': 'Costas (Superiores)', 'lower_back': 'Lombar',
  };

  @override
  void initState() {
    super.initState();
    _ageController.text = _responses['age'] > 0 ? _responses['age'].toString() : '';
    _heightController.text = _responses['height'] > 0 ? _responses['height'].toString() : '';
    _weightController.text = _responses['weight'] > 0 ? _responses['weight'].toString() : '';
  }

  // ... (build, _buildStepPage, _nextStep, _previousStep, _goToStep, _canProceedToNextStep, dispose permanecem iguais) ...
  @override
  Widget build(BuildContext context) {
    bool showNavigationButtons = _currentStep != 8; // Não mostra botões na Tela 9 (Resumo Nutrição)

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: ProgressIndicatorWidget(currentStep: _currentStep, totalSteps: _totalSteps),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepPage(_buildWelcomeStep()),          // Tela 1
                    _buildStepPage(_buildBasicDataStep()),        // Tela 2
                    _buildStepPage(_buildActivityLevelStep()),    // Tela 3
                    _buildStepPage(_buildRegularActivitiesStep()),// Tela 4
                    _buildStepPage(_buildActivityDetailsStep()),  // Tela 5
                    _buildStepPage(_buildBodyFatStep()),          // Tela 6
                    _buildStepPage(_buildMainGoalStep()),         // Tela 7
                    _buildStepPage(_buildGoalPaceStep()),         // Tela 8
                    _buildStepPage(_buildNutritionSummaryStep()), // Tela 9
                    _buildStepPage(_buildExperienceLevelStep()),  // Tela 10
                    _buildStepPage(_buildAvailabilityStep()),     // Tela 11
                    _buildStepPage(_buildEnvironmentStep()),      // Tela 12
                    _buildStepPage(_buildHomeEquipmentStep()),    // Tela 12b
                    _buildStepPage(_buildMuscleFocusStep()),      // Tela 13
                    _buildStepPage(_buildSplitPreferenceStep()),  // Tela 14
                    _buildStepPage(_buildTrainingSummaryStep()),  // Tela 15
                  ],
                ),
              ),
              if (showNavigationButtons)
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: NavigationButtonsWidget(
                    canGoBack: _currentStep > 0,
                    canGoNext: _canProceedToNextStep(),
                    isLastStep: _currentStep == _totalSteps - 1,
                    isLoading: _isCompleting,
                    onBack: _previousStep,
                    onNext: _currentStep == _totalSteps - 1 ? _completeOnboarding : _nextStep,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPage(Widget child) {
    if (_currentStep == 1 || _currentStep == 4 || _currentStep == 8 || _currentStep == 13 || _currentStep == 5) {
      return SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: 4.w), child: child);
    }
    return SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: 4.w), child: child);
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_formKeyTela2.currentState?.validate() ?? false) {
        setState(() {
          _responses['age'] = double.tryParse(_ageController.text) ?? 0.0;
          _responses['height'] = double.tryParse(_heightController.text) ?? 0.0;
          _responses['weight'] = double.tryParse(_weightController.text) ?? 0.0;
        });
      } else { return; }
    }
    if (_currentStep == 4) {
      _activityDetailControllers.forEach((activity, controllers) { _responses['activity_details'][activity] = { 'frequency': int.tryParse(controllers['frequency']!.text) ?? 0, 'duration': int.tryParse(controllers['duration']!.text) ?? 0, }; });
      bool allFilled = true;
      (_responses['activity_details'] as Map<String, Map<String, int>>).forEach((key, value) { if (value['frequency'] == 0 || value['duration'] == 0) allFilled = false; });
      if (!allFilled) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, preencha todos os detalhes dos seus treinos.'), backgroundColor: AppTheme.errorRed)); return; }
    }
    if (_currentStep < _totalSteps - 1) {
      int nextStepIndex = _currentStep + 1;
      if (_currentStep == 11 && _responses['workout_environment'] != 'Casa com Equipamentos') nextStepIndex = 13;
      setState(() => _currentStep = nextStepIndex);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      int prevStepIndex = _currentStep - 1;
      if (_currentStep == 13 && _responses['workout_environment'] != 'Casa com Equipamentos') prevStepIndex = 11;
      setState(() => _currentStep = prevStepIndex);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _goToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _totalSteps) {
      setState(() => _currentStep = stepIndex);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: return true;
      case 1: return (_responses['gender'] as String).isNotEmpty && (_formKeyTela2.currentState?.validate() ?? false);
      case 2: return (_responses['activity_level'] as String).isNotEmpty;
      case 3: return (_responses['regular_activities'] as List<String>).isNotEmpty;
      case 4: return true;
      case 5: return (_responses['body_fat_image'] as String).isNotEmpty;
      case 6: return (_responses['main_goal'] as String).isNotEmpty;
      case 7: return (_responses['main_goal'] == 'Manter o Peso') || (_responses['goal_pace'] as String).isNotEmpty;
      case 8: return true;
      case 9: return (_responses['experience_level'] as String).isNotEmpty;
      case 10: return (_responses['workout_duration_range'] as String).isNotEmpty;
      case 11: return (_responses['workout_environment'] as String).isNotEmpty;
      case 12: return (_responses['workout_environment'] != 'Casa com Equipamentos') || (_responses['home_equipment'] as List<String>).isNotEmpty;
      case 13: return (_responses['muscle_focus'] as List<String>).isNotEmpty;
      case 14: return true;
      default: return true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _activityDetailControllers.forEach((key, value) { value['frequency']?.dispose(); value['duration']?.dispose(); });
    super.dispose();
  }


  // --- MODIFICADO: _completeOnboarding (Função Inteira Substituída) ---
  void _completeOnboarding() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final sb = Supabase.instance.client;
      final user = sb.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      if (user.email == null) throw Exception('Email do usuário não disponível.');

      // --- ADIÇÃO 1: Calcula as metas ANTES ---
      final Map<String, String> nutritionPlan = _calculateNutritionPlan();
      // Verifica se houve erro no cálculo (ex: dados insuficientes)
      if (nutritionPlan.containsKey('error')) {
        // Decide como tratar: mostrar erro ao usuário ou salvar sem as metas?
        // Por segurança, vamos lançar o erro para o usuário tentar novamente.
        throw Exception('Erro ao calcular o plano nutricional final: ${nutritionPlan['error']}');
      }

      // --- ADIÇÃO 2: Adiciona versão e metas calculadas ao mapa _responses ---
      // Cria uma cópia MUTÁVEL para poder adicionar chaves
      Map<String, dynamic> finalResponses = Map<String, dynamic>.from(_responses);

      finalResponses['onboarding_version'] = '2.0'; // Identificador da versão atual do onboarding

      // Adiciona as metas calculadas (convertendo para tipos numéricos corretos)
      finalResponses['target_calories'] = int.tryParse(nutritionPlan['targetCalories'] ?? '0') ?? 0;
      finalResponses['target_protein'] = int.tryParse(nutritionPlan['protein'] ?? '0') ?? 0;
      finalResponses['target_carbs'] = int.tryParse(nutritionPlan['carbs'] ?? '0') ?? 0;
      finalResponses['target_fat'] = int.tryParse(nutritionPlan['fat'] ?? '0') ?? 0;
      finalResponses['target_hydration_liters'] = double.tryParse(nutritionPlan['hydration'] ?? '0.0') ?? 0.0;
      finalResponses['calculated_tdee'] = int.tryParse(nutritionPlan['tdee'] ?? '0') ?? 0; // TDEE calculado
      // --- FIM DAS ADIÇÕES ---


      final payload = {
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'Usuário',
        // --- MODIFICADO: Salva o mapa finalResponses (com metas e versão) ---
        'onboarding_data': finalResponses,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Realiza o upsert no Supabase
      await sb.from('user_profiles').upsert(payload, onConflict: 'id');

      // Feedback de sucesso e navegação (código existente)
      if (mounted) {
        showDialog(
          context: context, barrierDismissible: false, builder: (context) => AlertDialog(
          backgroundColor: AppTheme.dialogDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [ Icon(Icons.check_circle, color: AppTheme.accentGold, size: 6.w), SizedBox(width: 3.w), Expanded(child: Text('Tudo Pronto!', style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary), softWrap: true))]),
          content: Text('Recebemos suas informações, seu plano de treino será gerado com base nesses dados.', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          actions: [ ElevatedButton(onPressed: () { Navigator.of(context).pop(); Navigator.pushReplacementNamed(context, AppRoutes.dashboard); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryBlack), child: const Text('Concluir'))],
        ),
        );
      }
    } catch (error) {
      // Tratamento de erro (código existente)
      print("Erro em _completeOnboarding: $error"); // Adiciona log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao concluir configuração: ${error.toString()}'), backgroundColor: AppTheme.errorRed, action: SnackBarAction(label: 'Tentar Novamente', textColor: AppTheme.accentGold, onPressed: _completeOnboarding)));
      }
    } finally {
      // Finalização do estado de loading (código existente)
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
  // --- FIM DA MODIFICAÇÃO ---


  Future<bool> _onWillPop() async {
    if (_currentStep > 0) { _previousStep(); return false; }
    return await showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: AppTheme.dialogDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Text('Sair da Configuração?', style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary)), content: Text('Seu progresso será perdido. Deseja realmente sair?', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)), actions: [ TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Continuar', style: TextStyle(color: AppTheme.accentGold))), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sair', style: TextStyle(color: AppTheme.errorRed))) ])) ?? false;
  }

  // --- WIDGETS DE ETAPA (TELA 1-15) ---
  // (As funções _build...Step(), _calculateNutritionPlan(), etc., permanecem as mesmas)
  // Tela 1: Boas-vindas
  Widget _buildWelcomeStep() => QuestionCardWidget(title: 'Bem-vindo ao BLDR.', subtitle: 'Vamos configurar seu plano 100% personalizado.', child: Column(children: [ Icon(Icons.rocket_launch_outlined, size: 20.w, color: AppTheme.accentGold), SizedBox(height: 2.h), Text('Isso levará apenas minutos e fará toda a diferença na sua jornada.', textAlign: TextAlign.center, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)) ]));
  // Tela 2: Dados Básicos
  Widget _buildBasicDataStep() => QuestionCardWidget(title: 'Para começar, precisamos saber um pouco sobre você.', subtitle: 'Isso é essencial para calcularmos suas metas de nutrição (TMB).', child: Form(key: _formKeyTela2, child: Column(children: [ SingleChoiceWidget(options: _genderOptions, selectedOption: _responses['gender'] as String?, onOptionSelected: (option) => setState(() => _responses['gender'] = option)), SizedBox(height: 3.h), _FormInputWidget(controller: _ageController, label: 'Idade', suffix: 'anos', icon: Icons.calendar_today_outlined), SizedBox(height: 2.h), _FormInputWidget(controller: _heightController, label: 'Altura', suffix: 'cm', icon: Icons.height_outlined), SizedBox(height: 2.h), _FormInputWidget(controller: _weightController, label: 'Peso Atual', suffix: 'kg', icon: Icons.monitor_weight_outlined) ])));
  // Tela 3: Rotina Diária
  Widget _buildActivityLevelStep() => QuestionCardWidget(title: 'Como é o seu dia-a-dia?', subtitle: 'Excluindo treinos e esportes, isso define seu nível de atividade (NEAT).', child: SingleChoiceWidget(options: _activityLevelOptions.map((opt) => opt['title']!).toList(), selectedOption: _responses['activity_level'] as String?, onOptionSelected: (option) => setState(() => _responses['activity_level'] = option)));
  // Tela 4: Atividades Físicas
  Widget _buildRegularActivitiesStep() => QuestionCardWidget(title: 'Quais atividades físicas ou esportes você pratica?', subtitle: 'Selecione todas que você pratica regularmente.', child: MultipleChoiceWidget(options: _regularActivitiesOptions, selectedOptions: _responses['regular_activities'] as List<String>, onOptionsChanged: (options) => setState(() { _responses['regular_activities'] = options; _activityDetailControllers = {}; _responses['activity_details'] = <String, Map<String, int>>{}; for (var act in options) { _activityDetailControllers[act] = {'frequency': TextEditingController(), 'duration': TextEditingController()}; _responses['activity_details'][act] = {'frequency': 0, 'duration': 0}; } })));
  // Tela 5: Detalhes dos Treinos
  Widget _buildActivityDetailsStep() { List<String> selActs = _responses['regular_activities'] as List<String>; if (selActs.isEmpty) return QuestionCardWidget(title: 'Detalhes dos Treinos', subtitle: 'Volte e selecione uma atividade.', child: Center(child: Text('Nenhuma atividade selecionada.'))); return QuestionCardWidget(title: 'Nos diga mais sobre suas atividades', subtitle: 'Preencha os detalhes para cada atividade.', child: Column(children: selActs.map((act) => Container(margin: EdgeInsets.only(bottom: 3.h), padding: EdgeInsets.all(4.w), decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dividerGray)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(act, style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.accentGold)), SizedBox(height: 2.h), _FormInputWidget(controller: _activityDetailControllers[act]!['frequency']!, label: 'Quantas vezes/semana?', suffix: 'x', icon: Icons.repeat_outlined), SizedBox(height: 2.h), _FormInputWidget(controller: _activityDetailControllers[act]!['duration']!, label: 'Duração média?', suffix: 'min', icon: Icons.timer_outlined) ]))).toList())); }
  // Tela 6: Físico Atual
  Widget _buildBodyFatStep() { final List<Map<String, dynamic>> imgOpts = (_responses['gender'] == 'Feminino') ? _femaleBodyFatImages : _maleBodyFatImages; final String? curSel = _responses['body_fat_image'] as String?; final List<String> selOptsList = (curSel != null && curSel.isNotEmpty) ? [curSel] : []; return QuestionCardWidget(title: 'Qual destas imagens melhor representa seu físico atual?', subtitle: 'Para definirmos sua meta de proteína.', child: CardSelectionWidget(options: imgOpts, selectedOptions: selOptsList, onOptionsChanged: (opts) => setState(() => _responses['body_fat_image'] = opts?.firstOrNull ?? ''), multiSelect: false)); }
  // Tela 7: Objetivo Principal
  Widget _buildMainGoalStep() => QuestionCardWidget(title: 'Qual é a sua meta principal neste momento?', subtitle: 'Isso definirá a direção do seu plano de nutrição.', child: SingleChoiceWidget(options: _mainGoalOptions, selectedOption: _responses['main_goal'] as String?, onOptionSelected: (opt) => setState(() { _responses['main_goal'] = opt; _responses['goal_pace'] = ''; })));
  // Tela 8: Ritmo da Meta
  Widget _buildGoalPaceStep() { String goal = _responses['main_goal'] as String; List<String> opts = []; if (goal == 'Perder Gordura') opts = _paceOptionsLoss; else if (goal == 'Ganhar Massa Muscular') opts = _paceOptionsGain; if (goal == 'Manter o Peso') return QuestionCardWidget(title: 'Ritmo da Meta', subtitle: 'Seu objetivo é manter, não requer ritmo.', child: Container(padding: EdgeInsets.all(4.w), decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dividerGray)), child: Row(children: [ Icon(Icons.check_circle_outline, color: AppTheme.accentGold, size: 6.w), SizedBox(width: 3.w), Expanded(child: Text('Foco em manter. Pode avançar!', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))) ]))); return QuestionCardWidget(title: 'Em qual ritmo você prefere ir?', subtitle: 'Ritmo agressivo traz resultados mais rápidos, mas exige mais.', child: SingleChoiceWidget(options: opts, selectedOption: _responses['goal_pace'] as String?, onOptionSelected: (opt) => setState(() => _responses['goal_pace'] = opt))); }
  // Função _calculateNutritionPlan (permanece idêntica)
  Map<String, String> _calculateNutritionPlan() { try { double w = (_responses['weight'] as num?)?.toDouble() ?? 0.0, h = (_responses['height'] as num?)?.toDouble() ?? 0.0, a = (_responses['age'] as num?)?.toDouble() ?? 0.0; String g = _responses['gender'] as String? ?? '', al = _responses['activity_level'] as String? ?? '', mg = _responses['main_goal'] as String? ?? '', gp = _responses['goal_pace'] as String? ?? ''; if (w <= 0 || h <= 0 || a <= 0 || g.isEmpty || al.isEmpty || mg.isEmpty) return {'error': 'Dados insuficientes.'}; double bmr = (g == 'Masculino') ? (88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a)) : (447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a)); double neat = 1.2; if (al == 'Levemente Ativo') neat = 1.375; else if (al == 'Ativo') neat = 1.55; else if (al == 'Muito Ativo') neat = 1.725; double tdee = bmr * neat; double targetC = tdee; if (mg == 'Perder Gordura') { if (gp == 'Leve') targetC -= 250; else if (gp == 'Moderado') targetC -= 500; else if (gp == 'Agressivo') targetC -= 750; } else if (mg == 'Ganhar Massa Muscular') { if (gp == 'Leve') targetC += 200; else if (gp == 'Moderado') targetC += 350; else if (gp == 'Agressivo') targetC += 500; } double pG = w * 2.0, pK = pG * 4; double fG = w * 0.8, fK = fG * 9; double cK = targetC - pK - fK; double cG = (cK / 4).clamp(0, double.infinity); double hL = (w * 40) / 1000; return {'tdee': tdee.round().toString(), 'targetCalories': targetC.round().toString(), 'hydration': hL.toStringAsFixed(1), 'protein': pG.round().toString(), 'carbs': cG.round().toString(), 'fat': fG.round().toString()}; } catch (e) { print("Erro _calculateNutritionPlan: $e"); return {'error': 'Erro ao calcular.'}; } }
  // Tela 9: Resumo Nutrição (permanece idêntica)
  Widget _buildNutritionSummaryStep() { final plan = _calculateNutritionPlan(); if (plan.containsKey('error')) return QuestionCardWidget(title: 'Erro', subtitle: plan['error']!, child: Container()); String goalDesc = _responses['main_goal'] as String; if ((_responses['goal_pace'] as String).isNotEmpty) goalDesc += ' (${_responses['goal_pace']})'; return QuestionCardWidget(title: 'Tudo pronto! Seu plano de nutrição está calculado.', subtitle: 'Manutenção: ${plan['tdee']} kcal.', child: Column(children: [ Text('Metas para $goalDesc:', textAlign: TextAlign.center, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)), SizedBox(height: 3.h), _buildNutritionSummaryCard(title: 'Calorias', value: plan['targetCalories']!, unit: 'kcal', icon: Icons.local_fire_department_outlined), SizedBox(height: 2.h), _buildNutritionSummaryCard(title: 'Hidratação', value: plan['hydration']!, unit: 'Litros', icon: Icons.water_drop_outlined), SizedBox(height: 3.h), Text('Macros Sugeridos', style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary)), SizedBox(height: 2.h), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildMacroCard('Proteína', plan['protein']!, AppTheme.accentGold), _buildMacroCard('Carboidrato', plan['carbs']!, Colors.blue.shade300), _buildMacroCard('Gordura', plan['fat']!, Colors.orange.shade300)]), SizedBox(height: 4.h), ElevatedButton(onPressed: _nextStep, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryBlack, minimumSize: Size(double.infinity, 6.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('Continuar para Treino', style: AppTheme.darkTheme.textTheme.labelLarge)) ])); }
  Widget _buildNutritionSummaryCard({required String title, required String value, required String unit, required IconData icon}) => Container(padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w), decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dividerGray)), child: Row(children: [ Icon(icon, color: AppTheme.accentGold, size: 7.w), SizedBox(width: 4.w), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)), Text('$value $unit', style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)) ]) ]));
  Widget _buildMacroCard(String title, String value, Color color) => Expanded(child: Container(margin: EdgeInsets.symmetric(horizontal: 1.w), padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w), decoration: BoxDecoration(color: AppTheme.cardDark.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: color)), child: Column(children: [ Text(title, style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: color)), SizedBox(height: 0.5.h), Text('${value}g', style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis) ])));
  // Tela 10: Nível de Experiência
  Widget _buildExperienceLevelStep() => QuestionCardWidget(title: 'Configurando seu treino com a IA HAVOK.', subtitle: 'Qual é o seu nível de experiência?', child: SingleChoiceWidget(options: _experienceLevels, selectedOption: _responses['experience_level'] as String?, onOptionSelected: (option) => setState(() => _responses['experience_level'] = option)));
  // Tela 11: Disponibilidade
  Widget _buildAvailabilityStep() => QuestionCardWidget(title: 'Qual será sua rotina de treino?', subtitle: 'Selecione dias/semana e tempo/sessão.', child: Column(children: [ Text('Quantos dias/semana?', style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary)), SliderWidget(value: (_responses['workout_frequency_days'] as int).toDouble(), min: 2, max: 6, divisions: 4, label: 'dias', onChanged: (val) => setState(() => _responses['workout_frequency_days'] = val.round())), SizedBox(height: 4.h), Text('Tempo médio por sessão?', style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary)), SizedBox(height: 2.h), SingleChoiceWidget(options: _workoutDurationOptions, selectedOption: _responses['workout_duration_range'] as String?, onOptionSelected: (opt) => setState(() => _responses['workout_duration_range'] = opt)) ]));
  // Tela 12: Ambiente
  Widget _buildEnvironmentStep() => QuestionCardWidget(title: 'Onde você vai treinar?', subtitle: 'Isso dirá à HAVOK quais exercícios incluir.', child: CardSelectionWidget(options: _workoutEnvironmentOptions, selectedOptions: (_responses['workout_environment'] as String).isNotEmpty ? [_responses['workout_environment'] as String] : [], onOptionsChanged: (opts) => setState(() { _responses['workout_environment'] = opts.firstOrNull ?? ''; _responses['home_equipment'] = <String>[]; }), multiSelect: false));
  // Tela 12b: Equipamentos em Casa
  Widget _buildHomeEquipmentStep() { if (_responses['workout_environment'] != 'Casa com Equipamentos') return Container(); return QuestionCardWidget(title: 'Quais equipamentos você tem em casa?', subtitle: 'Selecione todos que se aplicam.', child: MultipleChoiceWidget(options: _homeEquipmentOptions, selectedOptions: _responses['home_equipment'] as List<String>, onOptionsChanged: (opts) => setState(() => _responses['home_equipment'] = opts))); }
  // Tela 13: Foco Muscular
  Widget _buildMuscleFocusStep() { List<String> selNames = _responses['muscle_focus'] as List<String>; return QuestionCardWidget(title: 'Quais grupos musculares priorizar?', subtitle: 'Selecione as áreas no mapa corporal.', child: Column(children: [ InteractiveViewer(constrained: true, child: MusclePickerMap(initialSelectedGroups: selNames, map: Maps.BODY, actAsToggle: true, selectedColor: AppTheme.accentGold, strokeColor: AppTheme.dividerGray.withOpacity(0.5), dotColor: AppTheme.accentGold.withOpacity(0.7), onChanged: (Set<Muscle>? newSel) { if (newSel == null) { setState(() => _responses['muscle_focus'] = <String>[]); return; } final List<String> curNames = newSel.map((m) => m.toString().split('.').last).toList(); setState(() => _responses['muscle_focus'] = curNames); })), SizedBox(height: 3.h), Text('Focos selecionados:', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)), SizedBox(height: 1.h), Wrap(spacing: 8.0, runSpacing: 4.0, alignment: WrapAlignment.center, children: (_responses['muscle_focus'] as List<String>).isEmpty ? [Text('Nenhum', style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary))] : (_responses['muscle_focus'] as List<String>).map((name) { final transName = _muscleTranslation[name] ?? (name.replaceAll('_', ' ').capitalizeFirst ?? name); return Chip(label: Text(transName), backgroundColor: AppTheme.cardDark, labelStyle: TextStyle(color: AppTheme.accentGold), side: BorderSide(color: AppTheme.accentGold)); }).toList()) ])); }
  // Tela 14: Preferência de Split
  Widget _buildSplitPreferenceStep() => QuestionCardWidget(title: 'Prefere alguma "divisão" (split) de treino?', subtitle: 'Se não souber, deixe a HAVOK decidir.', child: SingleChoiceWidget(options: _splitPreferenceOptions, selectedOption: _responses['split_preference'] as String?, onOptionSelected: (opt) => setState(() => _responses['split_preference'] = opt)));
  // Tela 15: Resumo Treino
  Widget _buildTrainingSummaryStep() { final Map<String, dynamic> trResp = {'experience_level': _responses['experience_level'], 'workout_frequency_days': '${_responses['workout_frequency_days']} dias/semana', 'workout_duration_range': _responses['workout_duration_range'], 'workout_environment': _responses['workout_environment'], 'muscle_focus': _responses['muscle_focus'], 'split_preference': _responses['split_preference']}; if (_responses['workout_environment'] == 'Casa com Equipamentos') trResp['home_equipment'] = _responses['home_equipment']; return QuestionCardWidget(title: 'Pronto! Já sabemos como você treina.', subtitle: 'Seu plano será gerado com base nesses dados.', child: SummaryWidget(responses: trResp, onEdit: (key) { int step = 0; switch (key) { case 'experience_level': step = 9; break; case 'workout_frequency_days': case 'workout_duration_range': step = 10; break; case 'workout_environment': step = 11; break; case 'home_equipment': step = 12; break; case 'muscle_focus': step = 13; break; case 'split_preference': step = 14; break; } _goToStep(step); })); }

} // Fim da classe _OnboardingFlowState