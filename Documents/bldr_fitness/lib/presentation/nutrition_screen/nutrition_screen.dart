import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/user_profile.dart'; // <<< ADIÇÃO 1
import '../../services/nutrition_service.dart';
import '../../services/payment_service.dart'; // <<< ADIÇÃO 2
import '../../widgets/custom_error_widget.dart';
import './widgets/add_food_modal_widget.dart';
import './widgets/daily_nutrition_overview_widget.dart';
import './widgets/meal_timeline_widget.dart';
import './widgets/nutrition_search_widget.dart';
import './widgets/water_intake_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // ====================================================================
      // <<< ADIÇÃO 3: Lógica de verificação replicada do ProfileDrawer >>>
      // ====================================================================
      final subscription =
      await PaymentService.instance.getCurrentUserSubscription();

      // A lógica exata que você usa no ProfileDrawer
      if (subscription != null &&
          subscription.status == 'active' &&
          subscription.planId == 'd082af8c-216a-4499-a1f6-1fb84ac08a5f') {
        _isClubMember = true;
      } else {
        _isClubMember = false;
      }
      // ====================================================================

      final meals = await NutritionService.instance
          .getUserMealsForDate(date: _selectedDate);
      final summary = await NutritionService.instance
          .getDailyNutritionSummary(date: _selectedDate);

      print('DADOS CARREGADOS PELA TELA: $meals');

      setState(() {
        _meals = meals;
        _nutritionSummary = summary;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _showAddFoodModal(String mealType) async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => AddFoodModalWidget(
        mealType: mealType,
        onFoodAdded: () {
          Navigator.pop(context);
          _loadData();
        },
        selectedDate: _selectedDate,
        // <<< ALTERAÇÃO FINAL: Passa o status da assinatura para o modal
        isClub: _isClubMember,
      ),
    );

    if (result is String) {
      _showFoodSearch(initialQuery: result);
    }
  }

  void _showFoodSearch({String? initialQuery}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => NutritionSearchWidget(
        initialQuery: initialQuery,
        onFoodSelected: (foodItem) {
          Navigator.pop(context);
          _showPortionSelector(foodItem);
        },
      ),
    );
  }

  void _showPortionSelector(Map<String, dynamic> foodItem) {
    double quantity = 100;

    showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.cardDark,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => StatefulBuilder(
            builder: (context, setModalState) => Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 12.w,
                          height: 0.5.h,
                          margin: EdgeInsets.only(left: 38.w, bottom: 3.h),
                          decoration: BoxDecoration(
                              color: AppTheme.dividerGray,
                              borderRadius: BorderRadius.circular(2))),
                      Text('Definir porção',
                          style: AppTheme.darkTheme.textTheme.titleLarge
                              ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2.h),
                      Text(foodItem['name'] ?? 'Alimento',
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondary)),
                      SizedBox(height: 3.h),
                      Row(children: [
                        Text('Quantidade (gramas):',
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textPrimary)),
                        const Spacer(),
                        Text('${quantity.round()}g',
                            style: AppTheme.darkTheme.textTheme.titleMedium
                                ?.copyWith(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w600)),
                      ]),
                      SizedBox(height: 2.h),
                      Slider(
                          value: quantity,
                          min: 10,
                          max: 500,
                          divisions: 49,
                          activeColor: AppTheme.accentGold,
                          inactiveColor: AppTheme.dividerGray,
                          onChanged: (value) {
                            setModalState(() {
                              quantity = value;
                            });
                          }),
                      SizedBox(height: 3.h),
                      ElevatedButton(
                          onPressed: () async {
                            try {
                              final meal =
                              await NutritionService.instance.createMeal(
                                  mealType: 'snack',
                                  mealDate: _selectedDate);

                              await NutritionService.instance.addFoodToMeal(
                                  mealId: meal['id'],
                                  foodItemId: foodItem['id'],
                                  quantityGrams: quantity);

                              if (mounted) Navigator.pop(context);
                              _loadData();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                        const Text('Comida adicionada com sucesso!'),
                                        backgroundColor: AppTheme.successGreen,
                                        behavior: SnackBarBehavior.floating));
                              }
                            } catch (error) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                        const Text('Falha ao adicionar comida'),
                                        backgroundColor: AppTheme.errorRed,
                                        behavior: SnackBarBehavior.floating));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGold,
                              foregroundColor: AppTheme.primaryBlack,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: SizedBox(
                              width: double.infinity,
                              child: Text('Adicionar comida',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp)))),
                      SizedBox(height: 4.h),
                    ]))));
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadData();
  }

  void _incrementWater() {
    setState(() {
      _waterIntake += 250;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          backgroundColor: AppTheme.primaryBlack,
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold)));
    }

    if (_hasError) {
      return Scaffold(
          backgroundColor: AppTheme.primaryBlack,
          body: Center(child: CustomErrorWidget()));
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
                  floating: true,
                  snap: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      child: Column(children: [
                        _buildDateSelector(),
                      ])),
                  expandedHeight: 10.h),
              SliverToBoxAdapter(
                  child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      child: DailyNutritionOverviewWidget(
                          nutritionSummary: _nutritionSummary,
                          selectedDate: _selectedDate))),
              SliverToBoxAdapter(
                  child: Container(
                      margin:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                      child: WaterIntakeWidget(
                          intake: _waterIntake.toDouble(), onIncrement: _incrementWater))),
              SliverToBoxAdapter(
                  child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                      child: MealTimelineWidget(
                          meals: _meals,
                          onAddMeal: _showAddFoodModal,
                          onEditMeal: (meal) {
                            // Edit meal functionality
                          }))),
              SliverToBoxAdapter(child: SizedBox(height: 10.h)),
            ])),
        floatingActionButton: FloatingActionButton(
            onPressed: _showFoodSearch,
            backgroundColor: AppTheme.accentGold,
            foregroundColor: AppTheme.primaryBlack,
            child: CustomIconWidget(
                iconName: 'search', color: AppTheme.primaryBlack, size: 6.w)));
  }

  Widget _buildDateSelector() {
    return Row(children: [
      Text('Nutrição',
          style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      const Spacer(),
      GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                      data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                              primary: AppTheme.accentGold,
                              surface: AppTheme.cardDark)),
                      child: child!);
                });
            if (date != null) {
              _onDateChanged(date);
            }
          },
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerGray)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    _selectedDate.day == DateTime.now().day &&
                        _selectedDate.month == DateTime.now().month &&
                        _selectedDate.year == DateTime.now().year
                        ? 'Hoje'
                        : '${_selectedDate.day}/${_selectedDate.month}',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500)),
                SizedBox(width: 1.w),
                CustomIconWidget(
                    iconName: 'calendar_today',
                    color: AppTheme.textSecondary,
                    size: 4.w),
              ]))),
    ]);
  }
}