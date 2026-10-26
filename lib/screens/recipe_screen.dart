import 'package:flutter/material.dart';

import '../models/dish.dart';
import '../services/data_service.dart';
import '../services/gemini_service.dart';
import 'log_dish_screen.dart';
import '../theme.dart';

/// Full recipe for one dish. Implements prd.md > Dish suggestion (full recipe with the making process).
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({
    super.key,
    required this.dish,
    required this.request,
    required this.gemini,
    this.data,
  });

  final Dish dish;
  final SuggestRequest request;
  final GeminiService gemini;

  /// When set, the page offers "I cooked this" so the dish can be logged.
  final DataService? data;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late Future<Recipe> _recipe = _load();

  void _logCooked() {
    final data = widget.data;
    if (data == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LogDishScreen(
        stock: data.inventoryOnce(),
        onSave: data.logMeal,
        dishName: widget.dish.name,
        dishIngredients: widget.dish.mainIngredients,
        slot: widget.request.meal,
      ),
    ));
  }

  /// Dishes from the recipe book already carry their recipe; only Gemini ideas need a request.
  Future<Recipe> _load() => widget.dish.recipe != null
      ? Future.value(widget.dish.recipe!)
      : widget.gemini.getRecipe(widget.dish.name, widget.request.ingredients);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: FutureBuilder<Recipe>(
          initialData: widget.dish.recipe,
          future: _recipe,
          builder: (context, snapshot) {
            if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text('Writing the recipe…', style: text.titleLarge),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              final message = snapshot.error is GeminiException
                  ? (snapshot.error as GeminiException).message
                  : 'Something went wrong. Please try again.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center, style: text.bodyLarge),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _recipe = _load(); // a block, so setState is not handed a Future
                        }),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final recipe = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                Text(widget.dish.name, style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(widget.dish.why,
                    style: text.bodyLarge?.copyWith(color: mutedBrown, fontSize: 17)),
                const SizedBox(height: 28),
                Text('Ingredients', style: text.titleLarge),
                const SizedBox(height: 12),
                for (final i in recipe.ingredients)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 8, right: 12),
                          child: Icon(Icons.circle, size: 7, color: terracotta),
                        ),
                        Expanded(child: Text(i, style: text.bodyLarge)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text('How to make it', style: text.titleLarge),
                const SizedBox(height: 12),
                for (var n = 0; n < recipe.steps.length; n++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                              color: terracottaSoft, shape: BoxShape.circle),
                          child: Text('${n + 1}',
                              style: const TextStyle(
                                  color: terracotta, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(recipe.steps[n],
                              style: text.bodyLarge?.copyWith(height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                if (widget.data != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _logCooked,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('I cooked this'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
