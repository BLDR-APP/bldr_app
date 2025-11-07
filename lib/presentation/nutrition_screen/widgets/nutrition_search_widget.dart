// lib/presentation/nutrition_screen/widgets/nutrition_search_widget.dart

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/nutrition_service.dart'; // Assume-se que esta classe usa o Supabase.
import './barcode_scanner_page.dart';

class NutritionSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodSelected;
  final String? initialQuery;

  const NutritionSearchWidget({
    Key? key,
    required this.onFoodSelected,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<NutritionSearchWidget> createState() => _NutritionSearchWidgetState();
}

class _NutritionSearchWidgetState extends State<NutritionSearchWidget> {
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchFoods(widget.initialQuery!);
    } else {
      _loadPopularFoods();
    }
  }

  // MÉTODO PARA CARREGAR ALIMENTOS POPULARES (VIA DATABASE)
  Future<void> _loadPopularFoods() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Busca na tabela food_items (filtrando por verifiedOnly e limitando a 20)
      final foods = await NutritionService.instance.searchFoodItems(
        verifiedOnly: true,
        limit: 20,
      );

      setState(() {
        _searchResults = foods;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // MÉTODO PARA BUSCAR ALIMENTOS (VIA DATABASE)
  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      _loadPopularFoods();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _searchQuery = query;
      });

      // Busca na tabela food_items (por nome)
      final foods = await NutritionService.instance.searchFoodItems(
        search: query,
        limit: 50,
      );

      setState(() {
        _searchResults = foods;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // MÉTODO PARA ABRIR SCANNER DE BARCODE (BUSCA VIA DATABASE NA COLUNA 'barcode')
  Future<void> _openBarcodeScan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (code == null) return;

    setState(() => _isLoading = true);
    try {
      // a chamada searchByBarcode deve ser implementada para buscar na coluna 'barcode' da table food_items
      final foods = await NutritionService.instance.searchByBarcode(code);
      setState(() {
        _searchQuery = code;
        _searchResults = foods;
      });

      // se só tem 1 resultado, já abre direto
      if (foods.length == 1 && mounted) {
        widget.onFoodSelected(foods.first);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // opcional placeholder (visão por imagem, não implementado agora)
  void _openCameraScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reconhecimento por imagem ainda não implementado'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
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
              'Buscar Alimento', // TRADUZIDO
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerGray),
              ),
              child: TextField(
                onChanged: _searchFoods,
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar alimentos...', // TRADUZIDO
                  hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  prefixIcon: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.textSecondary,
                    size: 5.w,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed:
                        _openCameraScan, // você pode implementar depois
                        icon: CustomIconWidget(
                          iconName: 'camera_alt',
                          color: AppTheme.textSecondary,
                          size: 5.w,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      IconButton(
                        onPressed: _openBarcodeScan, // chama o scanner
                        icon: CustomIconWidget(
                          iconName: 'qr_code_scanner',
                          color: AppTheme.textSecondary,
                          size: 5.w,
                        ),
                      ),
                      SizedBox(width: 2.w),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                ),
              ),
            ),
            SizedBox(height: 3.h),
            if (_searchQuery.isEmpty)
              Text(
                'Alimentos Populares', // TRADUZIDO
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_searchQuery.isNotEmpty)
              Text(
                'Resultados da Busca (${_searchResults.length})', // TRADUZIDO
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            SizedBox(height: 2.h),
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentGold,
                ),
              )
                  : ListView.separated(
                controller: scrollController,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: 2.h),
                itemBuilder: (context, index) {
                  final food = _searchResults[index];
                  return _buildFoodItem(food);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    // ... (Método _buildFoodItem e _buildNutritionInfo permanecem inalterados)
    return GestureDetector(
      onTap: () => widget.onFoodSelected(food),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'restaurant',
                color: AppTheme.accentGold,
                size: 6.w,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] ?? 'Unknown Food',
                    style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (food['brand'] != null)
                    Text(
                      food['brand'],
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      _buildNutritionInfo(
                        '${food['calories_per_100g']?.toInt() ?? 0}',
                        'cal',
                        AppTheme.accentGold,
                      ),
                      SizedBox(width: 3.w),
                      _buildNutritionInfo(
                        '${food['protein_per_100g']?.toInt() ?? 0}',
                        'P',
                        AppTheme.errorRed,
                      ),
                      SizedBox(width: 3.w),
                      _buildNutritionInfo(
                        '${food['carbs_per_100g']?.toInt() ?? 0}',
                        'C',
                        AppTheme.warningAmber,
                      ),
                      SizedBox(width: 3.w),
                      _buildNutritionInfo(
                        '${food['fat_per_100g']?.toInt() ?? 0}',
                        'F',
                        AppTheme.successGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'add_circle_outline',
              color: AppTheme.accentGold,
              size: 6.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$value$label',
        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}