// lib/presentation/bldr_club/havok/recipe_library_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'havok_hub.dart'; // Para as cores
import 'recipe_results_screen.dart'; // Para a tela de detalhes

// Modelo de dados para a receita salva
class SavedRecipe {
  final String id;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> recipeData;

  SavedRecipe({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.recipeData,
  });

  factory SavedRecipe.fromMap(Map<String, dynamic> map) {
    return SavedRecipe(
      id: map['id'],
      name: map['recipe_name'],
      createdAt: DateTime.parse(map['created_at']),
      recipeData: map['recipe_data'],
    );
  }
}

class RecipeLibraryScreen extends StatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  State<RecipeLibraryScreen> createState() => _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends State<RecipeLibraryScreen> {
  bool _isLoading = true;
  List<SavedRecipe> _recipes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSavedRecipes();
  }

  Future<void> _fetchSavedRecipes() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) throw 'Usuário não autenticado.';

      final response = await supabase
          .schema('bldr_club')
          .from('havok_recipes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final recipes = response.map((map) => SavedRecipe.fromMap(map)).toList();

      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocorreu um erro ao buscar suas receitas.';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: goldColor));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_recipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, color: Colors.white38, size: 50),
            SizedBox(height: 16),
            Text(
              'Sua biblioteca de receitas está vazia.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Salve as receitas geradas pela IA para vê-las aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return Card(
          color: cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: goldColor.withOpacity(0.3)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            title: Text(recipe.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Salva em: ${DateFormat('dd/MM/yyyy \'às\' HH:mm').format(recipe.createdAt)}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: goldColor, size: 16),
            onTap: () {
              // Navega para a tela de detalhes, reutilizando-a
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeResultsScreen(recipeData: recipe.recipeData),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: const Text('BIBLIOTECA DE RECEITAS', style: TextStyle(color: goldColor)),
        backgroundColor: cardBackgroundColor,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: _buildBody(),
    );
  }
}