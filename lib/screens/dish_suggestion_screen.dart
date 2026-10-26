import 'package:flutter/material.dart';

import '../models/dish.dart';
import '../models/family_profile.dart';
import '../models/inventory_item.dart';
import '../services/data_service.dart';
import '../services/dish_database.dart';
import '../services/gemini_service.dart';
import '../services/ingredient_matcher.dart';
import '../state/cook_choices.dart';
import '../ui/app_button.dart';
import '../ui/app_card.dart';
import '../ui/context_ext.dart';
import '../ui/segmented_choice.dart';
import '../ui/skeleton.dart';
import '../ui/states.dart';
import '../ui/status_chip.dart';
import '../ui/tokens.dart';
import 'recipe_screen.dart';

/// Splits "chicken, onion\nrice" into items; also accepts the Urdu comma.
List<String> splitIngredients(String raw) => raw
    .split(RegExp(r'[,\n،;]'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// Cook tab: three filters that remember her last picks, and the dishes right under them.
/// Best match first, from her own recipe book. Implements prd.md > Features and Behavior > Dish suggestion.
class DishSuggestionScreen extends StatefulWidget {
  const DishSuggestionScreen({
    super.key,
    this.gemini,
    this.database,
    this.stock,
    this.recentMeals,
    this.profile,
    this.data,
  });

  final GeminiService? gemini;
  final DishDatabase? database;

  /// Her groceries. When there are some, the screen uses them instead of asking what she has.
  final Future<List<InventoryItem>>? stock;

  /// Dishes cooked in the last week; they are not suggested again.
  final Future<Set<String>>? recentMeals;

  /// Who she cooks for; spice, kids and favourite cuisines shape which dishes come first.
  final Future<FamilyProfile>? profile;

  /// Lets the recipe page log a cooked dish. Also supplies [stock] and [recentMeals] when not given.
  final DataService? data;

  @override
  State<DishSuggestionScreen> createState() => _DishSuggestionScreenState();
}

class _DishSuggestionScreenState extends State<DishSuggestionScreen> {
  late final GeminiService _gemini = widget.gemini ?? GeminiService();
  final _ingredients = TextEditingController();

  CookChoices _choices = const CookChoices();

  bool _loading = false;
  String? _error;
  SuggestRequest? _request;
  List<Dish>? _dishes;
  final Set<String> _shown = {};

  List<InventoryItem> _stock = const [];
  Set<String> _recent = const {};
  FamilyProfile _profile = FamilyProfile.empty;
  bool _stockLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads her last choices, groceries and last week's meals. Any of them failing, or taking too
  /// long, just means it is left out: she can always still type what she has.
  Future<void> _load() async {
    final choicesLoading = CookChoices.load();
    final stockLoading = widget.stock ?? widget.data?.inventoryOnce();
    final recentLoading = widget.recentMeals ?? widget.data?.recentMealNames();
    final profileLoading = widget.profile ?? widget.data?.profileOnce();
    Future<T> safely<T>(Future<T>? loading, T fallback) {
      if (loading == null) return Future.value(fallback);
      return loading
          .timeout(const Duration(seconds: 8))
          .then<T>((value) => value, onError: (_) => fallback);
    }

    final choices = await choicesLoading;
    final stock = await safely<List<InventoryItem>>(stockLoading, const []);
    final recent = await safely<Set<String>>(recentLoading, const {});
    final profile = await safely<FamilyProfile>(profileLoading, FamilyProfile.empty);
    if (!mounted) return;
    setState(() {
      _choices = choices;
      _stock = stock;
      _recent = recent;
      _profile = profile;
      _stockLoaded = true;
    });
    if (stock.isNotEmpty) _ask();
  }

  @override
  void dispose() {
    _ingredients.dispose();
    super.dispose();
  }

  void _choose(CookChoices next) {
    setState(() => _choices = next);
    next.save();
    if (_stock.isNotEmpty || _dishes != null) _ask();
  }

  /// Your recipe book first (instant); Gemini only when it has nothing that fits.
  /// [more] asks for different dishes than the ones already shown.
  Future<void> _ask({bool more = false}) async {
    final usingStock = _stock.isNotEmpty;
    final items = usingStock ? [for (final i in _stock) i.name] : splitIngredients(_ingredients.text);
    if (items.isEmpty) {
      setState(() => _error = 'Please type a few things you have at home.');
      return;
    }
    final request = SuggestRequest(
      meal: _choices.meal,
      weight: _choices.weight,
      base: _choices.base,
      ingredients: items,
      stockDetails: usingStock
          ? [for (final i in _stock) '${i.name} ${formatAmount(i.amount)} ${i.unit}']
          : const [],
      recentMeals: _recent.toList(),
      profile: _profile,
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

  void _openRecipe(Dish dish) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeScreen(dish: dish, request: _request!, gemini: _gemini, data: widget.data),
        ),
      );

  Set<String> get _have => typedIngredients(
        _stock.isNotEmpty ? [for (final i in _stock) i.name] : splitIngredients(_ingredients.text),
      );

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.xl),
            children: [
              Text('What to cook', style: text.headlineMedium),
              const SizedBox(height: Space.xs),
              Text('Best match first, using what is in your kitchen',
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: Space.m),
              AppCard(
                child: Column(
                  children: [
                    SegmentedChoice(
                      label: 'Meal',
                      options: CookChoices.meals,
                      selected: _choices.meal,
                      onSelected: (v) => _choose(_choices.copyWith(meal: v)),
                    ),
                    const SizedBox(height: Space.s),
                    SegmentedChoice(
                      label: 'Weight',
                      options: CookChoices.weights,
                      selected: _choices.weight,
                      onSelected: (v) => _choose(_choices.copyWith(weight: v)),
                    ),
                    const SizedBox(height: Space.s),
                    SegmentedChoice(
                      label: 'With',
                      options: CookChoices.bases,
                      selected: _choices.base,
                      onSelected: (v) => _choose(_choices.copyWith(base: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text('Dishes cooked in the last 7 days are hidden.',
                        style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ),
                ],
              ),
              const SizedBox(height: Space.m),
              ..._body(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    final text = context.text;
    if (!_stockLoaded) return [SkeletonLoader.list(count: 3, itemHeight: 168)];

    final asking = <Widget>[
      if (_stock.isEmpty) ...[
        Text('What do you have at home?', style: text.titleMedium),
        const SizedBox(height: Space.s),
        TextField(
          controller: _ingredients,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'For example: chicken, onion, rice, yogurt',
            helperText: 'Separate with commas',
          ),
        ),
        const SizedBox(height: Space.m),
        AppButton(label: 'Show me dishes', icon: Icons.restaurant_menu_rounded, onPressed: _loading ? null : _ask),
        const SizedBox(height: Space.m),
      ],
    ];

    if (_loading) return [...asking, SkeletonLoader.list(count: 3, itemHeight: 168)];
    if (_error != null) {
      if (_stock.isEmpty) {
        return [
          ...asking,
          AppCard(
            color: context.colors.errorContainer,
            borderColor: context.colors.errorContainer,
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: context.colors.onErrorContainer),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Text(_error!, style: text.bodyMedium?.copyWith(color: context.colors.onErrorContainer)),
                ),
              ],
            ),
          ),
        ];
      }
      return [
        ErrorState(message: _error!, retryLabel: context.l10n.retry, onRetry: _ask),
      ];
    }
    final dishes = _dishes;
    if (dishes == null) return asking;

    final have = _have;
    return [
      ...asking,
      for (var i = 0; i < dishes.length; i++) ...[
        _DishCard(
          dish: dishes[i],
          best: i == 0,
          have: have,
          onOpen: () => _openRecipe(dishes[i]),
        ),
        const SizedBox(height: Space.m),
      ],
      AppButton(
        label: 'Show different dishes',
        icon: Icons.refresh_rounded,
        kind: AppButtonKind.secondary,
        onPressed: () => _ask(more: true),
      ),
    ];
  }
}

/// One suggestion: where it came from, how much of it she already has, and what to do next.
class _DishCard extends StatelessWidget {
  const _DishCard({required this.dish, required this.best, required this.have, required this.onOpen});

  final Dish dish;
  final bool best;
  final Set<String> have;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final main = dish.mainIngredients;
    final missing = [
      for (final m in main)
        if (!have.contains(canonicalIngredient(m))) m,
    ];
    final haveCount = main.length - missing.length;
    final all = main.isNotEmpty && missing.isEmpty;

    return AppCard(
      padding: const EdgeInsets.all(Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(fromBook: dish.fromDatabase),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dish.name, style: text.titleLarge),
                    const SizedBox(height: Space.xs),
                    Text(dish.why, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    if (main.isNotEmpty) ...[
                      const SizedBox(height: Space.s),
                      Row(
                        children: [
                          Icon(
                            all ? Icons.check_rounded : Icons.warning_amber_rounded,
                            size: 16,
                            color: all ? colors.secondary : context.appColors.warning,
                          ),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              all ? 'You have all ${main.length}' : 'You have $haveCount of ${main.length}',
                              style: text.labelMedium?.copyWith(
                                color: all ? colors.secondary : context.appColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: haveCount / main.length,
                          minHeight: 8,
                          color: all ? colors.secondary : context.appColors.warning,
                        ),
                      ),
                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: Space.s),
                        StatusChip(
                          label: 'Missing: ${missing.join(', ')}',
                          icon: Icons.warning_amber_rounded,
                          tone: StatusTone.warning,
                        ),
                      ],
                    ],
                    if (best) ...[
                      const SizedBox(height: Space.s),
                      const StatusChip(label: 'Best match', icon: Icons.star_rounded, tone: StatusTone.info),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          Row(
            children: [
              Expanded(
                child: AppButton(label: 'Recipe', kind: AppButtonKind.secondary, onPressed: onOpen),
              ),
              const SizedBox(width: Space.s),
              Expanded(child: AppButton(label: 'Cook this', onPressed: onOpen)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A soft square with a bowl and a small label saying where the dish came from. Honest: a recipe
/// from her own book and an AI idea are never made to look the same.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.fromBook});
  final bool fromBook;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: Corner.mediumRadius),
            child: Icon(Icons.rice_bowl_rounded, size: 44, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: Space.xs),
          StatusChip(
            label: fromBook ? 'Recipe book' : 'AI suggestion',
            icon: fromBook ? Icons.menu_book_rounded : Icons.auto_awesome_rounded,
            tone: fromBook ? StatusTone.info : StatusTone.neutral,
          ),
        ],
      ),
    );
  }
}
