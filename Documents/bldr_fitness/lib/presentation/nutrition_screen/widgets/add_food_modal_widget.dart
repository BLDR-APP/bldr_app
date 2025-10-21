import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/app_export.dart';
import '../../../services/nutrition_service.dart';
import './barcode_scanner_page.dart'; // Mantido para referência
import './nutrition_search_widget.dart';

class AddFoodModalWidget extends StatefulWidget {
  final String mealType;
  final VoidCallback onFoodAdded;
  final DateTime selectedDate;
  final bool isClub;

  const AddFoodModalWidget({
    Key? key,
    required this.mealType,
    required this.onFoodAdded,
    required this.selectedDate,
    this.isClub = false,
  }) : super(key: key);

  @override
  State<AddFoodModalWidget> createState() => _AddFoodModalWidgetState();
}

class _AddFoodModalWidgetState extends State<AddFoodModalWidget> {
  List<Map<String, dynamic>> _recentFoods = [];
  bool _isLoading = true;

  final _imagePicker = ImagePicker();
  stt.SpeechToText? _speech;

  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
  }

  // 💡 MÉTODO PARA CONVERTER O NOME DE EXIBIÇÃO PARA A CHAVE DO DB (CORREÇÃO DE POSTGRES)
  String _getDatabaseMealType(String displayMealType) {
    switch (displayMealType.toLowerCase()) {
      case 'café da manhã':
        return 'breakfast';
      case 'almoço':
        return 'lunch';
      case 'jantar':
        return 'dinner';
      case 'lanche':
      case 'snack':
        return 'snack';
      default:
        return 'snack';
    }
  }

  Future<void> _loadRecentFoods() async {
    try {
      setState(() => _isLoading = true);
      // Assumindo que o searchFoodItems retorna os recentes se o query for nulo
      final foods = await NutritionService.instance.searchFoodItems(
        verifiedOnly: true,
        limit: 10,
      );
      setState(() {
        _recentFoods = foods;
        _isLoading = false;
      });
    } catch (error) {
      // Garantir que a lista esteja vazia, mas que o loading termine
      debugPrint('Erro ao carregar comidas recentes: $error');
      setState(() {
        _recentFoods = [];
        _isLoading = false;
      });
    }
  }

  // =================== GATING / UPSELL ===================

  void _requireClubOr(VoidCallback action) {
    if (widget.isClub) {
      action();
    } else {
      _showClubUpsell();
    }
  }

  void _showClubUpsell() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.only(left: 38.w, bottom: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.dividerGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Desbloqueie todos os modos de adicionar comida',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _upsellLine('Escanear código de barras', 'qr_code_scanner'),
              SizedBox(height: 1.h),
              _upsellLine('Adicionar por foto (câmera/galeria)', 'camera_alt'),
              SizedBox(height: 1.h),
              _upsellLine('Adicionar por voz (ditado)', 'mic'),
              SizedBox(height: 2.5.h),
              ElevatedButton(
                onPressed: () {
                  if (mounted) Navigator.pop(context);
                  // Leva ao fluxo de checkout/upgrade
                  if (mounted) Navigator.pushNamed(context, AppRoutes.checkoutScreen);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryBlack,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Tornar-se BLDR CLUB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              Center(
                child: Text(
                  'Você ainda pode usar a busca por alimento normalmente.',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upsellLine(String text, String iconName) {
    return Row(
      children: [
        CustomIconWidget(iconName: iconName, color: AppTheme.accentGold, size: 5.w),
        SizedBox(width: 2.5.w),
        Expanded(
          child: Text(
            text,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.dividerGray),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, size: 16, color: Colors.white70),
              SizedBox(width: 1.5.w),
              Text(
                'CLUB',
                style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============== AÇÕES ==============

  // 1) Buscar alimento — LIBERADO para todos
  void _openSearch({String? hint}) {
    if (hint != null && hint.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sugestão de busca: "$hint"'),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
      ));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NutritionSearchWidget(
        onFoodSelected: (foodItem) {
          if (mounted) Navigator.pop(context);
          _showPortionSelector(foodItem);
        },
      ),
    );
  }

  // 2) Scanner de código de barras — EXCLUSIVO CLUBE
  void _scanBarcode() async {
    final code = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (code == null) return;

    // Fecha o modal atual devolvendo o EAN para a tela que abriu
    if (mounted) Navigator.pop(context, code);
  }

  // 3) Foto (câmera/galeria) — EXCLUSIVO CLUBE
  Future<void> _useCamera() async {
    final source = await _askPhotoSource();
    if (source == null) return;

    final XFile? file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;

    // Futuro: OCR/IA -> sugerir alimento. Por ora, vai pra busca com hint.
    _openSearch(hint: 'foto do rótulo/prato');
  }

  Future<ImageSource?> _askPhotoSource() {
    return showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _photoAction('Tirar foto', 'photo_camera',
                      () => Navigator.pop(context, ImageSource.camera)),
              SizedBox(height: 1.2.h),
              _photoAction('Escolher da galeria', 'image',
                      () => Navigator.pop(context, ImageSource.gallery)),
              SizedBox(height: 1.2.h),
              _photoAction('Cancelar', 'close',
                      () => Navigator.pop(context, null),
                  isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoAction(String label, String icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Row(
          children: [
            CustomIconWidget(
                iconName: icon, color: AppTheme.accentGold, size: 6.w),
            SizedBox(width: 3.w),
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: isDestructive ? AppTheme.errorRed : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4) Voz — EXCLUSIVO CLUBE
  Future<void> _useVoiceInput() async {
    _speech ??= stt.SpeechToText();
    // Verifica permissão e inicializa o STT
    final ok = await _speech!.initialize(
      onStatus: (_) {},
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro no microfone: ${e.errorMsg}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
    );

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reconhecimento de voz indisponível'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    String spoken = '';
    // Começa a escutar
    await _speech!.listen(
      localeId: 'pt_BR',
      onResult: (res) => spoken = res.recognizedWords,
    );

    // Espera um tempo para o usuário falar
    await Future.delayed(const Duration(seconds: 3));

    // Para a escuta
    await _speech!.stop();

    if (spoken.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não entendi. Tente novamente.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    _openSearch(hint: spoken);
  }

  // ============== UI ==============

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.all(4.w),
        // 💡 CORREÇÃO DA TELA PRETA: Column é o pai do Expanded/ListView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Handle do Modal
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.only(left: 38.w, bottom: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.dividerGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Adicionar ${_formatMealType(widget.mealType)}',
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),

            // 2. Linhas de botões de ação (Conteúdo Fixo)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Buscar comida',
                    icon: 'search',
                    color: AppTheme.accentGold,
                    locked: false,
                    onTap: () => _openSearch(),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildActionButton(
                    label: 'Escanear código de barras',
                    icon: 'qr_code_scanner',
                    color: AppTheme.successGreen,
                    locked: !widget.isClub,
                    onTap: () => _requireClubOr(_scanBarcode),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Câmera',
                    icon: 'camera_alt',
                    color: AppTheme.errorRed,
                    locked: !widget.isClub,
                    onTap: () => _requireClubOr(_useCamera),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildActionButton(
                    label: 'Voz',
                    icon: 'mic',
                    color: Colors.purple,
                    locked: !widget.isClub,
                    onTap: () => _requireClubOr(_useVoiceInput),
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),
            Text(
              'Comidas recentes',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // 3. Área de Scroll (Expanded)
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentGold,
                ),
              )
              // 💡 Renderização segura da lista
                  : (_recentFoods.isEmpty
                  ? Center(
                  child: Text(
                    'Nenhum alimento recente encontrado.',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  )
              )
                  : ListView.separated(
                // CRÍTICO: Anexar o scrollController
                controller: scrollController,
                itemCount: _recentFoods.length,
                separatorBuilder: (_, __) => SizedBox(height: 1.h),
                itemBuilder: (context, index) {
                  final food = _recentFoods[index];
                  if (food == null || food['name'] == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildRecentFoodItem(food);
                },
              )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String icon,
    required Color color,
    required VoidCallback onTap,
    required bool locked,
  }) {
    return GestureDetector(
      onTap: locked ? _showClubUpsell : onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.5.h),
            decoration: BoxDecoration(
              color: locked
                  ? AppTheme.surfaceDark
                  : color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: locked
                    ? AppTheme.dividerGray
                    : color.withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: icon,
                  color: locked ? AppTheme.textSecondary : color,
                  size: 8.w,
                ),
                SizedBox(height: 1.h),
                Text(
                  label,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Faixa "CLUBE" com cadeado (quando bloqueado)
          if (locked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.dividerGray),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 14, color: Colors.white70),
                    SizedBox(width: 1.w),
                    Text(
                      'CLUBE',
                      style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentFoodItem(Map<String, dynamic> food) {
    return GestureDetector(
      onTap: () {
        if (mounted) Navigator.pop(context); // Fecha o modal de ações
        _showPortionSelector(food);
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomIconWidget(
                iconName: 'restaurant',
                color: AppTheme.accentGold,
                size: 4.w,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] ?? 'Unknown Food',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (food['brand'] != null && (food['brand'] as String).isNotEmpty)
                    Text(
                      food['brand'],
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${(food['calories_per_100g'] as num?)?.toInt() ?? 0} cal',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2.w),
            CustomIconWidget(
              iconName: 'add_circle_outline',
              color: AppTheme.textSecondary,
              size: 5.w,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMealType(String mealType) {
    // Garante que o display seja formatado (ex: "Café da manhã")
    return mealType[0].toUpperCase() + mealType.substring(1).toLowerCase();
  }

  // ====== Porção + adicionar no banco (reaproveita NutritionService) ======
  void _showPortionSelector(Map<String, dynamic> foodItem) {
    double quantity = 100;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Definir porção',
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                foodItem['name'] ?? 'Alimento',
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Text(
                    'Quantidade (gramas):',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${quantity.round()}g',
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Slider(
                value: quantity,
                min: 10,
                max: 500,
                divisions: 49,
                activeColor: AppTheme.accentGold,
                inactiveColor: AppTheme.dividerGray,
                onChanged: (v) => setModalState(() => quantity = v),
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Mapeia o nome de exibição para a chave de DB
                    final dbMealType = _getDatabaseMealType(widget.mealType);

                    final meal = await NutritionService.instance.createMeal(
                      mealType: dbMealType, // CHAVE CORRIGIDA
                      mealDate: widget.selectedDate,
                    );

                    await NutritionService.instance.addFoodToMeal(
                      mealId: meal['id'],
                      foodItemId: foodItem['id'],
                      quantityGrams: quantity,
                    );

                    if (mounted) Navigator.pop(context); // fecha porção
                    // Não precisa de segundo pop aqui, o onFoodAdded já trata o modal original
                    widget.onFoodAdded();

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Comida adicionada com sucesso!'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ));
                  } catch (e) {
                    debugPrint('Falha ao adicionar comida (Erro no NutritionService): $e');

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Falha ao adicionar comida'),
                        backgroundColor: AppTheme.errorRed,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryBlack,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Adicionar comida',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== (Opcional) Tela de Scanner simples ==========
// Esta classe deve ser definida em um arquivo separado chamado barcode_scanner_page.dart
// para que o import funcione corretamente.
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
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text('Escanear código'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final code = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue
                  : null;
              if (code != null && code.isNotEmpty) {
                _handled = true;
                if (mounted) Navigator.pop(context, code);
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Aponte para o código de barras/QR do alimento',
                style: AppTheme.darkTheme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}