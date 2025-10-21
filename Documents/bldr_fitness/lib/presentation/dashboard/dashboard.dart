import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/subscription_plan.dart'; // Importe o modelo da assinatura
import '../../models/user_profile.dart';
import '../../services/payment_service.dart'; // Importe o serviço de pagamento
import '../../services/user_service.dart';
import '../../services/workout_service.dart';
import '../bldr_club/bldr_club_screen.dart';
import '../nutrition_screen/nutrition_screen.dart';
import '../profile_drawer/profile_drawer.dart';
import '../progress_screen/progress_screen.dart';
import '../workouts_screen/workouts_screen.dart';
import './widgets/achievements_widget.dart';
import './widgets/active_workout_card_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/nutrition_progress_widget.dart';
import './widgets/partnership_widget.dart';
import './widgets/quick_actions_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late TabController _tabController;

  UserProfile? _userProfile;
  UserSubscription? _userSubscription; // VARIÁVEL ADICIONADA
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // FUNÇÃO ATUALIZADA PARA BUSCAR PERFIL E ASSINATURA
  Future<void> _loadUserData() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      // Busca o perfil e a assinatura em paralelo para mais performance
      final results = await Future.wait([
        UserService.instance.getCurrentUserProfile(),
        PaymentService.instance.getCurrentUserSubscription(),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as UserProfile?;
          _userSubscription = results[1] as UserSubscription?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Opcional: mostrar um SnackBar em caso de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados do usuário: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  // NOVO GETTER PARA VERIFICAR SE O USUÁRIO É PREMIUM
  bool get _isPremium {
    if (_userSubscription == null) return false;
    return _userSubscription!.status == 'active';
  }

  // FUNÇÃO ATUALIZADA PARA BLOQUEAR A ABA BLDR CLUB
  void _onTabSelected(int index) {
    // O índice da aba 'BLDR CLUB' é 2
    if (index == 2 && !_isPremium) {
      // Se o usuário não for premium e clicar na aba 2, mostre o pop-up
      _showUpgradePopup();
      return; // Impede a troca de aba
    }

    setState(() {
      _selectedIndex = index;
    });
    _tabController.animateTo(index);
  }

  // NOVA FUNÇÃO PARA MOSTRAR O POP-UP DE UPGRADE
  void _showUpgradePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.stars, color: AppTheme.accentGold, size: 28),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Exclusivo para Membros',
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          'O BLDR CLUB é uma área exclusiva para assinantes. Faça o upgrade para ter acesso a conteúdos, treinos e desafios especiais!',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.checkoutScreen);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
            child: Text('Fazer Upgrade', style: TextStyle(color: AppTheme.primaryBlack)),
          ),
        ],
      ),
    );
  }


  // --- O RESTO DO SEU CÓDIGO PERMANECE IGUAL ---

  void _openProfileDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _startWorkout() async {
    try {
      final workouts = await WorkoutService.instance.getWorkoutTemplates(publicOnly: true);
      if (workouts.isNotEmpty) {
        Navigator.pushNamed(context, AppRoutes.workoutsScreen);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum treino disponível no momento'),
            backgroundColor: AppTheme.warningAmber,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar treinos: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _logMeal() {
    Navigator.pushNamed(context, AppRoutes.nutritionScreen);
  }

  void _viewProgress() {
    Navigator.pushNamed(context, AppRoutes.progressScreen);
  }

  void _quickLog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.dividerGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Registro Rápido',
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(child: _buildQuickLogOption('Registrar Refeição', 'restaurant', AppTheme.successGreen, _logMeal)),
                SizedBox(width: 3.w),
                Expanded(child: _buildQuickLogOption('Registrar Exercício', 'fitness_center', AppTheme.accentGold, _startWorkout)),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildQuickLogOption('Registrar Peso', 'monitor_weight', AppTheme.warningAmber, () async {
                    Navigator.pop(context);
                    try {
                      Navigator.pushNamed(context, AppRoutes.progressScreen);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir registro de peso: $e'), backgroundColor: AppTheme.errorRed));
                    }
                  }),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildQuickLogOption('Registrar Água', 'local_drink', Colors.blue, () async {
                    Navigator.pop(context);
                    try {
                      Navigator.pushNamed(context, AppRoutes.nutritionScreen);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir registro de água: $e'), backgroundColor: AppTheme.errorRed));
                    }
                  }),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogOption(
      String title, String icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(iconName: icon, color: color, size: 6.w),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.primaryBlack,
      endDrawer: const ProfileDrawer(),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildDashboardTab(),      // 0
            const WorkoutsScreen(),    // 1
            const BldrClubScreen(),    // 2
            const NutritionScreen(),   // 3
            const ProgressScreen(),    // 4
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(top: BorderSide(color: AppTheme.dividerGray, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.accentGold,
          unselectedItemColor: AppTheme.inactiveGray,
          elevation: 0,
          selectedLabelStyle: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.darkTheme.textTheme.labelMedium,
          items: [
            BottomNavigationBarItem(
              icon: CustomIconWidget(iconName: 'dashboard', color: _selectedIndex == 0 ? AppTheme.accentGold : AppTheme.inactiveGray, size: 6.w),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(iconName: 'fitness_center', color: _selectedIndex == 1 ? AppTheme.accentGold : AppTheme.inactiveGray, size: 6.w),
              label: 'Treinos',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(iconName: 'stars', color: _selectedIndex == 2 ? AppTheme.accentGold : AppTheme.inactiveGray, size: 6.w),
              label: 'BLDR CLUB',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(iconName: 'restaurant', color: _selectedIndex == 3 ? AppTheme.accentGold : AppTheme.inactiveGray, size: 6.w),
              label: 'Nutrição',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(iconName: 'trending_up', color: _selectedIndex == 4 ? AppTheme.accentGold : AppTheme.inactiveGray, size: 6.w),
              label: 'Progresso',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: _quickLog,
        backgroundColor: AppTheme.accentGold,
        foregroundColor: AppTheme.primaryBlack,
        child: CustomIconWidget(iconName: 'add', color: AppTheme.primaryBlack, size: 7.w),
      )
          : null,
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: AppTheme.accentGold,
      backgroundColor: AppTheme.cardDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingHeaderWidget(onSettingsPressed: _openProfileDrawer),
            SizedBox(height: 2.h),
            ActiveWorkoutCardWidget(onStartPressed: _startWorkout),
            SizedBox(height: 3.h),
            const NutritionProgressWidget(),
            SizedBox(height: 3.h),
            const PartnershipWidget(),
            SizedBox(height: 3.h),
            //const AchievementsWidget(),
            SizedBox(height: 3.h),
            QuickActionsWidget(
              onLogMealPressed: _logMeal,
              onStartWorkoutPressed: _startWorkout,
              onViewProgressPressed: _viewProgress,
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}