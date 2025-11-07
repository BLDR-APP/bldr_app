// ARQUIVO NOVO: lib/widgets/nutrition_search_widget.dart (ou onde você o colocou)

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importe seu tema
import '../../../core/app_export.dart';

class FirebaseNutritionSearchWidget extends StatefulWidget {
  // O callback para devolver a comida selecionada
  final Function(Map<String, dynamic> foodItem) onFoodSelected;

  const FirebaseNutritionSearchWidget({
    Key? key,
    required this.onFoodSelected,
  }) : super(key: key);

  @override
  State<FirebaseNutritionSearchWidget> createState() =>
      _FirebaseNutritionSearchWidgetState();
}

class _FirebaseNutritionSearchWidgetState
    extends State<FirebaseNutritionSearchWidget> {
  final _searchController = TextEditingController();

  // Referência para o banco de dados do Projeto B (Alimentos)
  late FirebaseFirestore dbAlimentos;

  // Armazena os resultados da busca
  Stream<QuerySnapshot>? _searchResultsStream;

  @override
  void initState() {
    super.initState();
    // 1. Pega a instância do Firebase do seu app 'alimentosDB'
    FirebaseApp appAlimentos = Firebase.app('alimentosDB');
    // 2. Pega o Firestore *desse app específico*
    dbAlimentos = FirebaseFirestore.instanceFor(app: appAlimentos);

    // Inicia com um stream vazio
    _searchResultsStream = Stream.empty();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Executa a busca no Firebase
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResultsStream = Stream.empty();
      });
      return;
    }

    String startQuery = query;

    // Lógica de busca "começa com" (case-insensitive)
    // Nota: O Firebase Firestore é limitado para buscas de "contém".
    // Para buscas "começa com", esta é a abordagem padrão.
    String endQuery = query + '\uf8ff';

    setState(() {
      _searchResultsStream = dbAlimentos
          .collection('alimentos')

      // Buscando no campo original 'name' (que existe no seu DB)
      // Usando o filtro de prefixo que funciona com a indexação básica
          .where('name', isGreaterThanOrEqualTo: startQuery)
          .where('name', isLessThan: endQuery)
          .limit(20)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mesmo visual do seu modal
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Scaffold(
        backgroundColor: AppTheme.cardDark,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
                color: AppTheme.dividerGray,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: [
              // --- Campo de Busca ---
              TextFormField(
                controller: _searchController,
                autofocus: true,
                style: AppTheme.darkTheme.textTheme.bodyLarge
                    ?.copyWith(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Buscar na base de dados...',
                  labelStyle: AppTheme.darkTheme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                  prefixIcon:
                  Icon(Icons.search, color: AppTheme.accentGold, size: 5.w),
                  filled: true,
                  fillColor: AppTheme.surfaceDark, // Um pouco diferente do card
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
                onChanged: _performSearch, // Busca a cada letra digitada
              ),
              SizedBox(height: 3.h),

              // --- Resultados da Busca ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _searchResultsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro na busca: ${snapshot.error}', style: TextStyle(color: AppTheme.textSecondary)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      if (_searchController.text.isEmpty) {
                        return Center(child: Text('Digite para buscar alimentos.', style: TextStyle(color: AppTheme.textSecondary)));
                      }
                      return Center(child: Text('Nenhum resultado encontrado.', style: TextStyle(color: AppTheme.textSecondary)));
                    }

                    // Temos resultados!
                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.h),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        // Converte o documento do Firebase para um Map
                        final foodData = doc.data() as Map<String, dynamic>;
                        // Adiciona o ID do documento ao map, pode ser útil
                        foodData['id'] = doc.id;

                        return _buildFoodItem(foodData);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para exibir o item de comida (similar ao seu `_buildRecentFoodItem`)
  Widget _buildFoodItem(Map<String, dynamic> food) {
    return GestureDetector(
      onTap: () {
        // 3. Devolve o item selecionado para o modal anterior
        widget.onFoodSelected(food);
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dividerGray)),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
                color: AppTheme.accentGold.withAlpha(50),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(Icons.public, // Ícone de "público"
                color: AppTheme.accentGold,
                size: 4.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food['name'] ?? 'Alimento sem nome',
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                  // Você pode adicionar 'brand' ou 'category' se tiver no seu DB
                  Text('100g', // O banco de dados público é por 100g
                      style: AppTheme.darkTheme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary)),
                ]),
          ),
          Text(
              '${(food['calories_per_100g'] as num?)?.toInt() ?? 0} cal',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentGold, fontWeight: FontWeight.w600)),
          SizedBox(width: 2.w),
          Icon(Icons.add_circle_outline, color: AppTheme.textSecondary, size: 5.w),
        ]),
      ),
    );
  }
}