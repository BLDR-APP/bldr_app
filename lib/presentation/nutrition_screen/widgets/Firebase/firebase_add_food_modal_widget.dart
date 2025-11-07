// firebase_add_food_modal_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

// Caminhos Corrigidos:
import '../../../../../core/app_export.dart';
import '../../../../services/firebase_nutrition_service.dart';
import '../firebase_nutrition_search_widget.dart';
// import '../../../services/nutrition_service.dart'; // Mantido, mas não usado
// import './barcode_scanner_page.dart'; // Redundante
// import './nutrition_search_widget.dart'; // Redundante

// === INÍCIO: _FormInputWidget (Mantido) ===
class _FormInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isOptional;
  final VoidCallback? onEditComplete;
  final FocusNode? focusNode;

  const _FormInputWidget({
    Key? key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.isOptional = false,
    this.onEditComplete,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext buildContext) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.text
          ? []
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
      decoration: InputDecoration(
        labelText: isOptional ? '$label (Opcional)' : label,
        labelStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        suffixText: suffix,
        suffixStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
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
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Campo obrigatório';
        }
        if (keyboardType != TextInputType.text &&
            value != null &&
            value.isNotEmpty &&
            double.tryParse(value) == null) {
          return 'Valor inválido';
        }
        return null;
      },
      onEditingComplete: onEditComplete,
      textInputAction: TextInputAction.next,
    );
  }
}
// === FIM: _FormInputWidget ===


class FirebaseAddFoodModalWidget extends StatefulWidget {
  final String mealType;
  final VoidCallback onFoodAdded;
  final DateTime selectedDate;
  final bool isClub;
  // >>> NOVOS PARÂMETROS PARA EDIÇÃO <<<
  final Map<String, dynamic>? itemToEdit;
  final bool isEditing;

  const FirebaseAddFoodModalWidget({
    Key? key,
    required this.mealType,
    required this.onFoodAdded,
    required this.selectedDate,
    this.isClub = false,
    // NOVOS PARÂMETROS COM VALORES PADRÃO
    this.itemToEdit,
    this.isEditing = false,
  }) : super(key: key);
  // >>> FIM DOS NOVOS PARÂMETROS <<<

  @override
  State<FirebaseAddFoodModalWidget> createState() => _AddFoodModalWidgetState();
}

class _AddFoodModalWidgetState extends State<FirebaseAddFoodModalWidget> with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _portionController = TextEditingController();
  bool _saveToFavorites = false;
  bool _isSavingManual = false;
  bool _manualCalories = false;

  final _caloriesFocus = FocusNode();
  final _proteinFocus = FocusNode();
  final _carbsFocus = FocusNode();
  final _fatFocus = FocusNode();
  final _portionFocus = FocusNode();

  late TabController _tabController;
  List<Map<String, dynamic>> _favoriteFoods = [];
  bool _isLoadingFavorites = true;

  List<Map<String, dynamic>> _recentFoods = [];
  bool _isLoading = true;
  final _imagePicker = ImagePicker();
  stt.SpeechToText? _speech;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRecentFoods();
    _loadFavoriteFoods();

    _proteinController.addListener(_calculateCalories);
    _carbsController.addListener(_calculateCalories);
    _fatController.addListener(_calculateCalories);
    _caloriesController.addListener(_checkManualCalories);

    // CORREÇÃO: Se estiver editando, abre o seletor de porção imediatamente
    if (widget.isEditing && widget.itemToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPortionSelector(widget.itemToEdit!, isEditingFlow: true);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _caloriesController.removeListener(_checkManualCalories); _caloriesController.dispose();
    _proteinController.removeListener(_calculateCalories); _proteinController.dispose();
    _carbsController.removeListener(_calculateCalories); _carbsController.dispose();
    _fatController.removeListener(_calculateCalories); _fatController.dispose();
    _portionController.dispose();
    _caloriesFocus.dispose(); _proteinFocus.dispose(); _carbsFocus.dispose(); _fatFocus.dispose(); _portionFocus.dispose();
    super.dispose();
  }

  void _checkManualCalories() {
    if (_caloriesFocus.hasFocus && _caloriesController.text.isNotEmpty) _manualCalories = true;
    if (_caloriesController.text.isEmpty) _manualCalories = false;
  }

  void _calculateCalories() {
    if (_manualCalories && !_caloriesFocus.hasFocus) return;

    final p = double.tryParse(_proteinController.text) ?? 0.0;
    final c = double.tryParse(_carbsController.text) ?? 0.0;
    final f = double.tryParse(_fatController.text) ?? 0.0;

    if ((p > 0 || c > 0 || f > 0) && !_manualCalories) {
      final calcCals = (p * 4) + (c * 4) + (f * 9);
      _caloriesController.removeListener(_checkManualCalories);
      _caloriesController.text = calcCals.toStringAsFixed(0);
      _caloriesController.addListener(_checkManualCalories);
    } else if (p == 0 && c == 0 && f == 0 && !_manualCalories) {
      _caloriesController.removeListener(_checkManualCalories);
      _caloriesController.text = '';
      _caloriesController.addListener(_checkManualCalories);
    }
  }

  String _getDatabaseMealType(String displayMealType) {
    switch (displayMealType.toLowerCase()) {
      case 'café da manhã': return 'breakfast';
      case 'almoço': return 'lunch';
      case 'jantar': return 'dinner';
      case 'lanche': case 'snack': return 'snack';
      default: return 'snack';
    }
  }

  // FUNÇÕES DE DADOS MIGRARAS PARA FIREBASE
  Future<void> _loadRecentFoods() async {
    try {
      if(mounted) setState(() => _isLoading = true);
      final foods = await FirebaseNutritionService.instance.searchFoodItemsFirebase(query: '', limit: 10);
      if(mounted) setState(() { _recentFoods = foods; _isLoading = false; });
    } catch (error) {
      debugPrint('Erro ao carregar comidas recentes: $error');
      if(mounted) setState(() { _recentFoods = []; _isLoading = false; });
    }
  }

  Future<void> _loadFavoriteFoods() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { if(mounted) setState(() => _isLoadingFavorites = false); return; }
    try {
      if(mounted) setState(() => _isLoadingFavorites = true);
      final favorites = await FirebaseNutritionService.instance.getFavoriteFoodItemsFirebase(userId);
      if (mounted) setState(() { _favoriteFoods = favorites; _isLoadingFavorites = false; });
    } catch (error) {
      debugPrint('Erro ao carregar comidas favoritas: $error');
      if (mounted) { setState(() { _favoriteFoods = []; _isLoadingFavorites = false; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Não foi possível carregar os favoritos.'), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating)); }
    }
  }


  // =================== GATING / UPSELL (Lógica original mantida) ===================
  void _requireClubOr(VoidCallback action) {
    if (widget.isClub) { action(); }
    else { _showClubUpsell(); }
  }
  void _showClubUpsell() { /* ... Lógica original do Upsell ... */ }
  Widget _upsellLine(String text, String iconName) { /* ... Lógica original ... */ return Row(); }
  // =================== FIM ===================

  // 1) Buscar alimento (Lógica original mantida)
  void _openSearch({String? hint}) {
    if (hint != null && hint.isNotEmpty) { /* ... */ }
    showModalBottomSheet(
      context: context, backgroundColor: AppTheme.cardDark, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => FirebaseNutritionSearchWidget(
        onFoodSelected: (foodItem) {
          if (mounted) Navigator.pop(context);
          _showPortionSelector(foodItem); // Chama _showPortionSelector "inteligente"
        },
      ),
    );
  }

  // 2) Scanner / 3) Foto / 4) Voz (Lógica original mantida)
  void _scanBarcode() async { /* ... Lógica original ... */ }
  Future<void> _useCamera() async { /* ... Lógica original ... */ }
  Future<ImageSource?> _askPhotoSource() { /* ... Lógica original ... */ return Future.value(null); }
  Widget _photoAction(String label, String icon, VoidCallback onTap, {bool isDestructive = false}) { /* ... Lógica original ... */ return Container(); }
  Future<void> _useVoiceInput() async { /* ... Lógica original ... */ }

  // --- Lógica para salvar a comida manual (MIGRADO PARA FIREBASE) ---
  Future<void> _saveManualFood() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_proteinController.text.isEmpty && _carbsController.text.isEmpty && _fatController.text.isEmpty && _caloriesController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Preencha pelo menos um valor nutricional.'), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating)); return; }
    setState(() => _isSavingManual = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { /* ... handle error ... */ return; }

    try {
      final name = _nameController.text.trim();
      final calories = double.tryParse(_caloriesController.text) ?? 0.0;
      final protein = double.tryParse(_proteinController.text) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text) ?? 0.0;
      final fat = double.tryParse(_fatController.text) ?? 0.0;

      Map<String, dynamic> foodItem;

      if (_saveToFavorites) {
        foodItem = await FirebaseNutritionService.instance.saveFoodItemToFavorites(
          name: name,
          caloriesPer100g: calories,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
          userId: userId,
        );
        await _loadFavoriteFoods();
      } else {
        // Item manual temporário
        foodItem = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': name,
          'calories_per_100g': calories,
          'protein_per_100g': protein,
          'carbs_per_100g': carbs,
          'fat_per_100g': fat,
          'created_by': userId,
        };
      }

      if (mounted) Navigator.pop(context); // Fecha modal principal
      _showPortionSelector(foodItem); // Chama seletor

    } catch (e) {
      debugPrint('Falha ao salvar comida manual: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating));
      if(mounted) setState(() => _isSavingManual = false);
    }
  }
  // --- FIM ---


  // ============== UI ==============

  @override
  Widget build(BuildContext context) {
    // Se estiver editando, não exibe o TabBar, pois o _showPortionSelector
    // será chamado diretamente pelo initState.
    if (widget.isEditing) {
      return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          color: AppTheme.cardDark,
          child: Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
      );
    }

    // UI Padrão para Adicionar
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Scaffold(
        backgroundColor: AppTheme.cardDark,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Container(
            width: 12.w, height: 0.5.h,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(color: AppTheme.dividerGray, borderRadius: BorderRadius.circular(2)),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.accentGold,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.accentGold,
            indicatorWeight: 3,
            isScrollable: false,
            labelStyle: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(fontSize: 8.sp),
            tabs: const [
              Tab(icon: Icon(Icons.edit_note), text: 'Manual'),
              Tab(icon: Icon(Icons.search), text: 'Buscar'),
              Tab(icon: Icon(Icons.star), text: 'Favoritos'),
              Tab(icon: Icon(Icons.history), text: 'Recentes'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Aba 1: Manual
            SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: _buildManualForm(),
            ),
            // Aba 2: Buscar (com botões comentados)
            SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: _buildSearchSection(),
            ),
            // Aba 3: Favoritos
            _buildFavoritesList(),
            // Aba 4: Recentes (da lógica original)
            _buildRecentFoodsList(),
          ],
        ),
      ),
    );
  }


  // --- Widget do Formulário Manual ---
  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormInputWidget(controller: _nameController, label: 'Nome da Comida', suffix: '', icon: Icons.label_outline, keyboardType: TextInputType.text, isOptional: false, onEditComplete: () => FocusScope.of(context).requestFocus(_caloriesFocus)),
          SizedBox(height: 2.h),
          Text("Insira os valores nutricionais:", style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          SizedBox(height: 2.h),
          _FormInputWidget(controller: _caloriesController, focusNode: _caloriesFocus, label: 'Calorias', suffix: 'kcal', icon: Icons.local_fire_department_outlined, isOptional: true, onEditComplete: () { _manualCalories = _caloriesController.text.isNotEmpty; FocusScope.of(context).requestFocus(_proteinFocus); }),
          SizedBox(height: 2.h),
          Row(children: [
            Expanded(child: _FormInputWidget(controller: _proteinController, focusNode: _proteinFocus, label: 'Proteína', suffix: 'g', icon: Icons.fitness_center, isOptional: true, onEditComplete: () => FocusScope.of(context).requestFocus(_carbsFocus))),
            SizedBox(width: 2.w),
            Expanded(child: _FormInputWidget(controller: _carbsController, focusNode: _carbsFocus, label: 'Carboidratos', suffix: 'g', icon: Icons.rice_bowl_outlined, isOptional: true, onEditComplete: () => FocusScope.of(context).requestFocus(_fatFocus))),
          ]),
          SizedBox(height: 2.h),
          _FormInputWidget(controller: _fatController, focusNode: _fatFocus, label: 'Gordura', suffix: 'g', icon: Icons.oil_barrel_outlined, isOptional: true, onEditComplete: () => FocusScope.of(context).unfocus()),
          SizedBox(height: 2.h),
          //_FormInputWidget(controller: _portionController, focusNode: _portionFocus, label: 'Tamanho da Porção', suffix: '', icon: Icons.pie_chart_outline, keyboardType: TextInputType.text, isOptional: true, onEditComplete: () => FocusScope.of(context).unfocus()),
          //SizedBox(height: 2.h),
          CheckboxListTile(
            value: _saveToFavorites, onChanged: (bool? newValue) => setState(() => _saveToFavorites = newValue ?? false),
            title: Text('Salvar nos Favoritos', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary)),
            activeColor: AppTheme.accentGold, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), side: BorderSide(color: AppTheme.accentGold),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _isSavingManual ? null : _saveManualFood,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryBlack, padding: EdgeInsets.symmetric(vertical: 2.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: SizedBox(width: double.infinity, child: _isSavingManual ? SizedBox(height: 3.h, width: 3.h, child: CircularProgressIndicator(color: AppTheme.primaryBlack, strokeWidth: 2.5)) : Text('Adicionar ${_formatMealType(widget.mealType)}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp))),
          ),
        ],
      ),
    );
  }
  // --- FIM ---

  // --- Widget da Seção de Busca (com botões comentados) ---
  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão Buscar (Ativo)
        _buildActionButton(label: 'Buscar comida na Base', icon: 'search', color: AppTheme.accentGold, locked: false, onTap: () => _openSearch()),
        SizedBox(height: 2.h),

        // --- BOTÕES COMENTADOS (Como no seu original) ---
        // _buildActionButton(label: 'Escanear código de barras', icon: 'qr_code_scanner', color: AppTheme.successGreen, locked: !widget.isClub, onTap: () => _requireClubOr(_scanBarcode)),
        // SizedBox(height: 2.h),
        // _buildActionButton(label: 'Câmera', icon: 'camera_alt', color: AppTheme.errorRed, locked: !widget.isClub, onTap: () => _requireClubOr(_useCamera)),
        // SizedBox(height: 2.h),
        // _buildActionButton(label: 'Voz', icon: 'mic', color: Colors.purple, locked: !widget.isClub, onTap: () => _requireClubOr(_useVoiceInput)),
        // --- FIM ---
      ],
    );
  }
  // --- FIM ---

  // --- Widget da Lista de Favoritos ---
  Widget _buildFavoritesList([ScrollController? scrollController]) {
    if (_isLoadingFavorites) {
      return Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
    }
    if (_favoriteFoods.isEmpty) {
      return Center(child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.star_outline, size: 15.w, color: AppTheme.textSecondary), SizedBox(height: 2.h), Text('Você ainda não salvou favoritos.', textAlign: TextAlign.center, style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)), SizedBox(height: 1.h), Text('Use a aba "Manual" e marque a opção para salvar.', textAlign: TextAlign.center, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)) ]));
    }
    return ListView.separated(
      controller: scrollController,
      itemCount: _favoriteFoods.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final food = _favoriteFoods[index];
        return GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
            _showPortionSelector(food); // Chama o _showPortionSelector "inteligente"
          },
          child: Container( padding: EdgeInsets.all(3.w), decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.dividerGray)),
            child: Row(children: [
              Container(padding: EdgeInsets.all(2.w), decoration: BoxDecoration(color: AppTheme.accentGold.withAlpha(50), borderRadius: BorderRadius.circular(6)), child: Icon(Icons.star, color: AppTheme.accentGold, size: 4.w)),
              SizedBox(width: 3.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(food['name'] ?? 'Favorito sem nome', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                if (food['serving_description'] != null && (food['serving_description'] as String).isNotEmpty) Text(food['serving_description'], style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
              ])),
              Text('${(food['calories_per_100g'] as num?)?.toInt() ?? 0} cal', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.accentGold, fontWeight: FontWeight.w600)),
              SizedBox(width: 2.w), Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 5.w),
            ]),
          ),
        );
      },
    );
  }
  // --- FIM ===

  // --- Widget da Lista de Recentes (da UI original) ---
  Widget _buildRecentFoodsList([ScrollController? scrollController]) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
    }
    if (_recentFoods.isEmpty) {
      return Center(child: Text('Nenhum alimento recente encontrado.', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)));
    }
    return ListView.separated(
      controller: scrollController,
      itemCount: _recentFoods.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final food = _recentFoods[index];
        if (food == null || food['name'] == null) return const SizedBox.shrink();
        return _buildRecentFoodItem(food); // Chama a função original
      },
    );
  }
  // --- FIM ---


  // _buildActionButton (Original mantido)
  Widget _buildActionButton({
    required String label, required String icon, required Color color,
    required VoidCallback onTap, required bool locked,
  }) {
    // ... (Código original do _buildActionButton) ...
    return GestureDetector(onTap: locked ? _showClubUpsell : onTap, child: Stack(children: [ Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 2.5.h), decoration: BoxDecoration(color: locked ? AppTheme.surfaceDark : color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: locked ? AppTheme.dividerGray : color.withValues(alpha: 0.30))), child: Column(children: [ CustomIconWidget(iconName: icon, color: locked ? AppTheme.textSecondary : color, size: 8.w), SizedBox(height: 1.h), Text(label, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.center) ])), if (locked) Positioned(top: 8, right: 8, child: Container(padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h), decoration: BoxDecoration(color: AppTheme.primaryBlack, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppTheme.dividerGray)), child: Row(children: [ const Icon(Icons.lock, size: 14, color: Colors.white70), SizedBox(width: 1.w), Text('CLUBE', style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5)) ]))) ]));
  }

  // _buildRecentFoodItem (Original mantido)
  Widget _buildRecentFoodItem(Map<String, dynamic> food) {
    return GestureDetector(
      onTap: () {
        if (mounted) Navigator.pop(context);
        _showPortionSelector(food); // Chama o _showPortionSelector "inteligente"
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.dividerGray)),
        child: Row(children: [
          Container(padding: EdgeInsets.all(2.w), decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: CustomIconWidget(iconName: 'restaurant', color: AppTheme.accentGold, size: 4.w),
          ),
          SizedBox(width: 3.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(food['name'] ?? 'Unknown Food', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            if (food['brand'] != null && (food['brand'] as String).isNotEmpty)
              Text(food['brand'], style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ])),
          Text('${(food['calories_per_100g'] as num?)?.toInt() ?? 0} cal', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.accentGold, fontWeight: FontWeight.w600)),
          SizedBox(width: 2.w),
          CustomIconWidget(iconName: 'add_circle_outline', color: AppTheme.textSecondary, size: 5.w),
        ]),
      ),
    );
  }

  // _formatMealType (Original mantido)
  String _formatMealType(String mealType) {
    if (mealType.isEmpty) return '';
    return mealType[0].toUpperCase() + mealType.substring(1).toLowerCase();
  }

  // ====== AJUSTADO: _showPortionSelector (Adiciona 'isEditingFlow' e lógica de UPDATE) ======
  void _showPortionSelector(Map<String, dynamic> foodItem, {bool isEditingFlow = false}) {

    if (!isEditingFlow) {
      if (mounted && _isSavingManual) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted) setState(() => _isSavingManual = false);
        });
      }
    }

    // Se for edição, pré-carrega a quantidade atual. Se for adição, usa 100.
    double initialQuantity = isEditingFlow
        ? (foodItem['quantity_grams'] as num?)?.toDouble() ?? 100.0
        : 100.0;

    double quantity = initialQuantity;
    double minQty = 10.0;
    double maxQty = 500.0;
    int divisions = 49;
    int decimals = 0;

    // NOVO ESTADO: Unidade (true = Gramas, false = Mililitros)
    bool isGrams = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (modalBuilderContext) => StatefulBuilder(
        builder: (context, setModalState) {
          // NOVO: Define o rótulo da unidade
          final String unitLabel = isGrams ? 'gramas (g)' : 'mililitros (mL)';

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 4.h, left: 4.w, right: 4.w, top: 2.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container( width: 12.w, height: 0.5.h, margin: EdgeInsets.only(bottom: 3.h), decoration: BoxDecoration( color: AppTheme.dividerGray, borderRadius: BorderRadius.circular(2)))),
                Text(isEditingFlow ? 'Editar Quantidade' : 'Definir porção', style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text(foodItem['food_name'] ?? foodItem['name'] ?? 'Alimento', style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary)),

                // >>> NOVO: Toggle para a Unidade <<<
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Usar mL',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                          color: isGrams ? AppTheme.textSecondary : AppTheme.accentGold
                      ),
                    ),
                    Switch(
                      value: !isGrams, // Inverte para que 'true' signifique 'usando mL'
                      onChanged: (newValue) {
                        setModalState(() {
                          isGrams = !newValue; // Atualiza a unidade (g/mL)
                        });
                      },
                      activeColor: AppTheme.accentGold,
                      inactiveTrackColor: AppTheme.dividerGray,
                    ),
                  ],
                ),
                // >>> FIM DO NOVO TOGGLE <<<

                SizedBox(height: 1.h),
                Row(children: [
                  Text(
                    'Quantidade ($unitLabel):',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${quantity.toStringAsFixed(decimals)}${isGrams ? 'g' : 'mL'}',
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(color: AppTheme.accentGold, fontWeight: FontWeight.w600),
                  ),
                ]),
                SizedBox(height: 2.h),
                Slider(
                  value: quantity, min: minQty, max: maxQty, divisions: divisions,
                  activeColor: AppTheme.accentGold, inactiveColor: AppTheme.dividerGray,
                  label: quantity.toStringAsFixed(decimals),
                  onChanged: (value) { setModalState(() { quantity = value; }); },
                ),
                SizedBox(height: 3.h),
                ElevatedButton(
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final onFoodAddedCallback = widget.onFoodAdded;
                    final mealType = widget.mealType;
                    final selectedDate = widget.selectedDate;

                    try {
                      final dbMealType = _getDatabaseMealType(mealType);

                      if (isEditingFlow) {
                        // LÓGICA DE UPDATE
                        await FirebaseNutritionService.instance.updateFoodLogItem(
                          foodLogId: foodItem['id'],
                          foodItem: foodItem, // CORREÇÃO: Passa 'foodItem'
                          newQuantityGrams: quantity,
                        );
                      } else {
                        // LÓGICA DE ADD
                        await FirebaseNutritionService.instance.addFoodToMealFirebase(
                          mealType: dbMealType,
                          mealDate: selectedDate,
                          foodItem: foodItem, // CORREÇÃO: Passa 'foodItem'
                          quantityGrams: quantity,
                        );
                      }

                      // --- ORDEM CORRIGIDA (Previne crash) ---
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text(isEditingFlow ? 'Item atualizado com sucesso!' : 'Comida adicionada com sucesso!'), backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating));
                      if (Navigator.canPop(modalBuilderContext)) Navigator.pop(modalBuilderContext);

                      // Se for edição, também fecha o modal principal
                      if (isEditingFlow && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      onFoodAddedCallback(); // Chama callback (recarrega)
                    } catch (e) {
                      debugPrint('Falha ao adicionar/atualizar comida: $e');
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(SnackBar(
                          content: Text('Falha: ${e.toString().replaceFirst("Exception: ", "")}'),
                          backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating,
                        ));
                      }
                      if(Navigator.canPop(modalBuilderContext)) Navigator.pop(modalBuilderContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryBlack, padding: EdgeInsets.symmetric(vertical: 2.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: SizedBox(width: double.infinity, child: Text(isEditingFlow ? 'Atualizar Quantidade' : 'Adicionar Comida', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp))),
                ),
                // SizedBox(height: 4.h), // Original
              ],
            ),
          );
        },
      ),
    );
  }
// ====== FIM DA MODIFICAÇÃO ======

} // Fim da classe _AddFoodModalWidgetState

// ========== (Opcional) Tela de Scanner simples ==========
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _handled = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(backgroundColor: AppTheme.primaryBlack, title: const Text('Escanear código')),
      body: Stack(children: [
        MobileScanner(onDetect: (capture) {
          if (_handled) return;
          final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
          if (code != null && code.isNotEmpty) {
            _handled = true;
            if (mounted) Navigator.pop(context, code);
          }
        },
        ),
        Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.all(4.w), child: Text('Aponte para o código de barras/QR do alimento', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)))),
      ]),
    );
  }
}