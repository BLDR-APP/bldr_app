import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/payment_service.dart';
import '../../widgets/custom_error_widget.dart';

import './widgets/daily_nutrition_overview_widget.dart';
import './widgets/meal_timeline_widget.dart';
import './widgets/water_intake_widget.dart';

import './widgets/Firebase/firebase_add_food_modal_widget.dart';
import '../../services/firebase_nutrition_service.dart';
import '../../services/firebase_auth_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<Map<String, dynamic>> _meals = [];
  Map<String, dynamic> _nutritionSummary = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _hasError = false;
  int _waterIntake = 0;
  bool _isClubMember = false;
  Map<String, dynamic>? _userProfile;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // >>> FUNÇÃO _loadData: UNIFICADA E CORRIGIDA <<<
  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        try {
          // 1. O serviço tenta obter o token customizado. Retorna String?
          final String? firebaseToken = await FirebaseAuthService().getFirebaseCustomToken();

          // 2. Só faz login se um token for retornado (ou seja, se o usuário não estava no cache)
          if (firebaseToken != null) {
            await FirebaseAuthService().signInWithCustomToken(firebaseToken);
            print("Login no Firebase com sucesso! UID: ${FirebaseAuthService().currentFirebaseUser?.uid}");
          } else {
            print("Autenticação Firebase: Usuário já logado via cache.");
          }

        } catch (e) {
          print("Erro fatal de autenticação no Firebase: $e");
          if (mounted) setState(() { _hasError = true; _isLoading = false; });
          return;
        }
      }

      // 2. Busca Perfil (Metas - Supabase)
      if (userId != null) {
        final profileResponse = await Supabase.instance.client
            .from('user_profiles')
            .select('id, onboarding_data')
            .eq('id', userId)
            .maybeSingle();

        if (!mounted) return;
        _userProfile = profileResponse as Map<String, dynamic>?;

        if (_userProfile == null) {
          print("Aviso: Perfil do usuário ID $userId não encontrado no Supabase.");
        }
      } else {
        print("Aviso: Usuário não autenticado em _loadData.");
        _userProfile = null;
      }

      // 3. Checagem de Membro (Lógica Original)
      final subscription = await PaymentService.instance.getCurrentUserSubscription();
      if (!mounted) return;
      if (subscription != null && subscription.status == 'active' && subscription.planId == 'd082af8c-216a-4499-a1f6-1fb84ac08a5f') {
        _isClubMember = true;
      } else {
        _isClubMember = false;
      }

      // 4. Busca Dados de Nutrição (Totais Consumidos - Firebase)
      final results = await Future.wait<dynamic>([
        FirebaseNutritionService.instance.getUserMealsForDateFirebase(userId: userId, date: _selectedDate),
        FirebaseNutritionService.instance.getDailyNutritionSummaryFirebase(userId: userId, date: _selectedDate),
        // TODO: Adicionar busca do waterIntake
      ]);

      if (!mounted) return;

      final meals = results[0] as List<Map<String, dynamic>>;
      final summary = results[1] as Map<String, dynamic>;

      print('DADOS CARREGADOS PELA TELA: $meals');

      setState(() {
        _meals = meals;
        _nutritionSummary = summary;
        _isLoading = false;
      });

    } catch (error) {
      print("Erro em _loadData: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  // --- FIM DA FUNÇÃO DE CARREGAMENTO CENTRALIZADA ---

  // NOVO MÉTODO: Abre o modal para edição de um item existente
  void _showEditFoodModal(Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      // Chamamos o mesmo modal de adição, mas injetamos os dados de edição
      builder: (context) => FirebaseAddFoodModalWidget(
        mealType: meal['meal_type'] ?? 'lanche', // Reusa o tipo de refeição
        selectedDate: _selectedDate,
        onFoodAdded: _loadData, // Recarrega os dados após a atualização
        isClub: _isClubMember,

        // >>> NOVOS PARÂMETROS PARA EDIÇÃO (Usados no Modal) <<<
        itemToEdit: meal,
        isEditing: true,
      ),
    );
  }


  // >>> NOVO MÉTODO: LIDA COM A DELEÇÃO DE UM ITEM LOGADO <<<
  void _handleDeleteFoodLog(String foodLogId) async {
    try {
      setState(() {
        _isLoading = true; // Exibe o loading durante a deleção/recarga
      });

      await FirebaseNutritionService.instance.deleteFoodLogItem(foodLogId);

      // Notifica e recarrega os dados
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comida removida com sucesso!'), backgroundColor: AppTheme.successGreen));
      }
      await _loadData(); // Recarrega para atualizar a UI
    } catch (e) {
      debugPrint('Falha ao deletar log: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // Parar loading em caso de erro
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao remover item.'), backgroundColor: AppTheme.errorRed));
      }
    }
  }


  // Função _showAddFoodModal (Mantida para o botão de Adição)
  void _showAddFoodModal(String mealType) async {
    await showModalBottomSheet(
      context: context, backgroundColor: AppTheme.cardDark, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => FirebaseAddFoodModalWidget(
        mealType: mealType,
        onFoodAdded: _loadData, // Recarrega os dados após a adição
        selectedDate: _selectedDate,
        isClub: _isClubMember,
        // NENHUM PARÂMETRO DE EDIÇÃO AQUI
      ),
    );
  }


  // Funções Auxiliares (Não precisam de alteração)
  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });
    _loadData();
  }

  void _incrementWater() {
    setState(() {
      _waterIntake += 250;
      // TODO: Salvar _waterIntake
    });
  }

  // Função Auxiliar de Data (Corrigido o posicionamento no código)
  Widget _buildDateSelector() {
    return Row(children: [
      Text('Nutrição', style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      const Spacer(),
      GestureDetector(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 30)), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: AppTheme.accentGold, surface: AppTheme.cardDark)), child: child!));
            if (date != null) _onDateChanged(date);
          },
          child: Container( padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h), decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.dividerGray)), child: Row(mainAxisSize: MainAxisSize.min, children: [ Text( (_selectedDate.day == DateTime.now().day && _selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year) ? 'Hoje' : '${_selectedDate.day}/${_selectedDate.month}', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)), SizedBox(width: 1.w), CustomIconWidget(iconName: 'calendar_today', color: AppTheme.textSecondary, size: 4.w) ]))),
    ]);
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppTheme.primaryBlack, body: Center(child: CircularProgressIndicator(color: AppTheme.accentGold)));
    }

    if (_hasError) {
      return Scaffold(backgroundColor: AppTheme.primaryBlack, body: Center(child: CustomErrorWidget()));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.accentGold,
          backgroundColor: AppTheme.cardDark,
          child: CustomScrollView(slivers: [
            SliverAppBar(
                backgroundColor: AppTheme.primaryBlack,
                floating: true, snap: true, elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: Container(padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h), child: Column(children: [_buildDateSelector()])),
                expandedHeight: 10.h),
            SliverToBoxAdapter(
                child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    child: DailyNutritionOverviewWidget(
                      nutritionSummary: _nutritionSummary, // Totais Consumidos
                      selectedDate: _selectedDate,
                      userProfileData: _userProfile, // Metas Diárias
                    )
                )
            ),
            SliverToBoxAdapter(child: Container(margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h), child: WaterIntakeWidget(intake: _waterIntake.toDouble(), onIncrement: _incrementWater))),
            SliverToBoxAdapter(
                child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                    child: MealTimelineWidget(
                      meals: _meals,
                      onAddMeal: _showAddFoodModal,
                      onEditMeal: _showEditFoodModal, // <<< AGORA CONECTADO AO NOVO HANDLER
                      onDeleteFoodLog: _handleDeleteFoodLog,
                    )
                )
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ])),
    );
  }
}