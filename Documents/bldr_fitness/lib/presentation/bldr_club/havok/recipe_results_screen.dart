// lib/presentation/bldr_club/havok/recipe_results_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'havok_hub.dart'; // Importa para usar as cores consistentes

class RecipeResultsScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const RecipeResultsScreen({super.key, required this.recipeData});

  @override
  State<RecipeResultsScreen> createState() => _RecipeResultsScreenState();
}

class _RecipeResultsScreenState extends State<RecipeResultsScreen> {
  bool _isSaving = false;

  Future<void> _saveRecipe() async {
    setState(() => _isSaving = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Esconde avisos anteriores

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'salvar-receita-havok',
        body: {'recipeData': widget.recipeData},
      );

      if (response.status == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receita salva com sucesso na sua biblioteca!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Tenta extrair a mensagem de erro específica da função
        final errorMessage = response.data?['error'] ?? 'Não foi possível salvar a receita.';
        throw errorMessage;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.recipeData['nome'] ?? 'Receita HAVOK';
    final String description = widget.recipeData['descricao'] ?? 'Uma deliciosa receita gerada pela IA.';
    final List ingredients = widget.recipeData['ingredientes'] ?? [];
    final List preparation = widget.recipeData['preparo'] ?? [];
    final Map macros = widget.recipeData['macros'] ?? {};

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: Text(name.toUpperCase(), style: const TextStyle(color: goldColor, fontSize: 16)),
        backgroundColor: cardBackgroundColor,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      // BOTÃO DE SALVAR ADICIONADO AQUI
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _saveRecipe,
        backgroundColor: goldColor,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.black)
            : const Icon(Icons.bookmark_add, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding inferior para o FAB não cobrir
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: TextStyle(color: Colors.grey[300], fontSize: 16, fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            _MacrosCard(macros: macros),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Ingredientes'),
            ...ingredients.map((ingredient) => _ListItem(text: ingredient)).toList(),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Modo de Preparo'),
            ...preparation.asMap().entries.map((entry) {
              int idx = entry.key;
              String step = entry.value;
              return _ListItem(text: step, stepNumber: idx + 1);
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// O resto dos widgets de ajuda (_MacrosCard, _SectionTitle, etc.) permanecem os mesmos
// ... (copie e cole os widgets privados da resposta anterior aqui se necessário)
class _MacrosCard extends StatelessWidget {
  final Map macros;
  const _MacrosCard({required this.macros});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MacroItem(label: 'Calorias', value: macros['calorias_aprox']?.toString() ?? '-'),
          _MacroItem(label: 'Proteínas', value: '${macros['proteinas_g'] ?? '-'}g'),
          _MacroItem(label: 'Carbos', value: '${macros['carboidratos_g'] ?? '-'}g'),
          _MacroItem(label: 'Gorduras', value: '${macros['gorduras_g'] ?? '-'}g'),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  const _MacroItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(color: goldColor, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String text;
  final int? stepNumber;
  const _ListItem({required this.text, this.stepNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepNumber != null)
            Text('$stepNumber. ', style: const TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
          if (stepNumber == null)
            const Icon(Icons.check_box_outline_blank, color: goldColor, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4))),
        ],
      ),
    );
  }
}