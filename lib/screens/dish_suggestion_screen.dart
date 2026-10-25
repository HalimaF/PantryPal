import 'package:flutter/material.dart';

import '../models/dish.dart';
import '../models/inventory_item.dart';
import '../services/data_service.dart';
import '../services/dish_database.dart';
import '../services/gemini_service.dart';
import '../theme.dart';
import 'recipe_screen.dart';

/// Splits "chicken, onion\nrice" into items; also accepts the Urdu comma.
List<String> splitIngredients(String raw) => raw
    .split(RegExp(r'[,\n،;]'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// Questions, then dishes. Implements prd.md > Features and Behavior > Dish suggestion.
class DishSuggestionScreen extends StatefulWidget {
  const DishSuggestionScreen({
    super.key,
    this.gemini,
    this.database,
    this.stock,
    this.recentMeals,
    this.data,
  });

  final GeminiService? gemini;
  final DishDatabase? database;

  /// Her groceries. When there are some, the screen uses them instead of asking what she has.
  final Future<List<InventoryItem>>? stock;

  /// Dishes cooked in the last week; they are not suggested again.
  final Future<Set<String>>? recentMeals;

  /// Lets the recipe page log a cooked dish. Also supplies [stock] and [recentMeals] when not given.
  final DataService? data;

  @override
  State<DishSuggestionScreen> createState() => _DishSuggestionScreenState();
}

class _DishSuggestionScreenState extends State<DishSuggestionScreen> {
  late final GeminiService _gemini = widget.gemini ?? GeminiService();
  final _ingredients = TextEditingController();

  String _meal = 'Dinner';
  String _weight = 'Light';
  String _base = 'Rice';

  bool _loading = false;
  String? _error;
  SuggestRequest? _request;
  List<Dish>? _dishes;
  final Set<String> _shown = {};

  List<InventoryItem> _stock = const [];
  Set<String> _recent = const {};
  bool _stockLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads her groceries and last week's meals. Either one failing, or taking too long,
  /// just means it is left out: she can always still type what she has.
  Future<void> _load() async {
    final stockLoading = widget.stock ?? widget.data?.inventoryOnce();
    final recentLoading = widget.recentMeals ?? widget.data?.recentMealNames();
    if (stockLoading == null && recentLoading == null) {
      _stockLoaded = true;
      return;
    }
    Future<T> safely<T>(Future<T>? loading, T fallback) {
      if (loading == null) return Future.value(fallback);
      return loading
          .timeout(const Duration(seconds: 8))
          .then<T>((value) => value, onError: (_) => fallback);
    }

    final stock = await safely<List<InventoryItem>>(stockLoading, const []);
    final recent = await safely<Set<String>>(recentLoading, const {});
    if (!mounted) return;
    setState(() {
      _stock = stock;
      _recent = recent;
      _stockLoaded = true;
    });
  }

  @override
  void dispose() {
    _ingredients.dispose();
    super.dispose();
  }

  /// Your recipe book first (instant); Gemini only when it has nothing that fits.
  /// [more] asks for different dishes than the ones already shown.
  Future<void> _ask({bool more = false}) async {
    final usingStock = _stock.isNotEmpty;
    final items = usingStock
        ? [for (final i in _stock) i.name]
        : splitIngredients(_ingredients.text);
    if (items.isEmpty) {
      setState(() => _error = 'Please type a few things you have at home.');
      return;
    }
    final request = SuggestRequest(
      meal: _meal,
      weight: _weight,
      base: _base,
      ingredients: items,
      stockDetails: usingStock
          ? [
              for (final i in _stock)
                '${i.name} ${formatAmount(i.amount)} ${i.unit}',
            ]
          : const [],
      recentMeals: _recent.toList(),
    );
    if (!more) _shown.clear();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final book = widget.database ?? await DishDatabase.load();
      var dishes = book.suggest(request, exclude: {..._shown, ..._recent});
      if (dishes.isEmpty) dishes = await _gemini.suggestDishes(request);
      _shown.addAll(dishes.map((d) => d.name));
      if (!mounted) return;
      setState(() {
        _request = request;
        _dishes = dishes;
      });
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showingResults = _dishes != null && !_loading;
    return Scaffold(
      appBar: AppBar(
        title: Text(showingResults ? 'Dish ideas' : 'What can I cook?'),
        leading: showingResults
            ? IconButton(
                tooltip: 'Change answers',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _dishes = null),
              )
            : null,
      ),
      body: SafeArea(
        child: _loading
            ? const _Thinking()
            : showingResults
            ? _Results(
                dishes: _dishes!,
                request: _request!,
                gemini: _gemini,
                data: widget.data,
                onRefresh: () => _ask(more: true),
              )
            : _Questions(
                meal: _meal,
                weight: _weight,
                base: _base,
                ingredients: _ingredients,
                stock: _stock,
                stockLoaded: _stockLoaded,
                error: _error,
                onMeal: (v) => setState(() => _meal = v),
                onWeight: (v) => setState(() => _weight = v),
                onBase: (v) => setState(() => _base = v),
                onAsk: _ask,
              ),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Thinking of dishes…',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _Questions extends StatelessWidget {
  const _Questions({
    required this.meal,
    required this.weight,
    required this.base,
    required this.ingredients,
    required this.stock,
    required this.stockLoaded,
    required this.error,
    required this.onMeal,
    required this.onWeight,
    required this.onBase,
    required this.onAsk,
  });

  final String meal;
  final String weight;
  final String base;
  final TextEditingController ingredients;
  final List<InventoryItem> stock;
  final bool stockLoaded;
  final String? error;
  final ValueChanged<String> onMeal;
  final ValueChanged<String> onWeight;
  final ValueChanged<String> onBase;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('Tell me about today', style: text.headlineSmall),
        const SizedBox(height: 20),
        _Group(
          label: 'Which meal?',
          options: const ['Lunch', 'Dinner'],
          selected: meal,
          onSelected: onMeal,
        ),
        _Group(
          label: 'How heavy?',
          options: const ['Light', 'Heavy'],
          selected: weight,
          onSelected: onWeight,
        ),
        _Group(
          label: 'What with?',
          options: const ['Rice', 'Roti', 'Bread', 'Noodles', 'Any'],
          selected: base,
          onSelected: onBase,
        ),
        if (!stockLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (stock.isNotEmpty)
          _StockCard(items: stock)
        else ...[
          Text('What do you have at home?', style: text.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: ingredients,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'For example: chicken, onion, rice, yogurt',
              helperText: 'Separate with commas',
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 14),
          _ErrorBox(message: error!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: stockLoaded ? onAsk : null,
          icon: const Icon(Icons.restaurant_menu_rounded),
          label: const Text('Show me dishes'),
        ),
      ],
    );
  }
}

/// Shown instead of the "what do you have?" box when her groceries are already saved.
class _StockCard extends StatelessWidget {
  const _StockCard({required this.items});
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineTan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.kitchen_rounded, color: leafGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Using what is in your kitchen',
                  style: text.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            items.map((i) => i.name).join(', '),
            style: text.bodyLarge?.copyWith(color: mutedBrown, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(o),
                  selected: o == selected,
                  showCheckmark: false,
                  onSelected: (_) => onSelected(o),
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: o == selected ? Colors.white : inkBrown,
                  ),
                  selectedColor: terracotta,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: lineTan),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.dishes,
    required this.request,
    required this.gemini,
    required this.data,
    required this.onRefresh,
  });

  final List<Dish> dishes;
  final SuggestRequest request;
  final GeminiService gemini;
  final DataService? data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          '${request.meal}, ${request.weight.toLowerCase()}, with ${request.base.toLowerCase()}',
          style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          dishes.every((d) => d.fromDatabase)
              ? 'From your own recipe book'
              : 'Ideas from the cooking helper',
          style: text.bodyMedium?.copyWith(
            color: leafGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        for (final dish in dishes) ...[
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeScreen(
                    dish: dish,
                    request: request,
                    gemini: gemini,
                    data: data,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lineTan),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dish.name, style: text.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            dish.why,
                            style: text.bodyMedium?.copyWith(
                              color: mutedBrown,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dish.mainIngredients.join(' · '),
                            style: text.bodyMedium?.copyWith(
                              color: terracotta,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: mutedBrown),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: terracotta,
            side: const BorderSide(color: terracotta),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Show different dishes'),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE4E1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB3261E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7A1A14), fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
