import 'package:firebase_ai/firebase_ai.dart' show ServerException;
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/dish.dart';
import 'package:what_can_i_cook/screens/dish_suggestion_screen.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';

const _request = SuggestRequest(
  meal: 'Dinner',
  weight: 'Light',
  base: 'Rice',
  ingredients: ['chicken', 'onion', 'rice'],
);

void main() {
  fallbackTests();
  test('parseDishes reads a good reply', () {
    final dishes = parseDishes(
      '{"dishes":[{"name":"Chicken pulao","why":"Light and filling.","mainIngredients":["chicken","rice"]}]}',
    );
    expect(dishes.single.name, 'Chicken pulao');
    expect(dishes.single.mainIngredients, ['chicken', 'rice']);
  });

  test('parseDishes rejects malformed and empty replies with a kind message', () {
    expect(() => parseDishes('not json'), throwsA(isA<GeminiException>()));
    expect(() => parseDishes('{"dishes":[]}'), throwsA(isA<GeminiException>()));
    expect(() => parseDishes('{"dishes":[{"name":"x"}]}'), throwsA(isA<GeminiException>()));
  });

  test('parseRecipe reads a good reply and rejects one with no steps', () {
    final recipe = parseRecipe('{"ingredients":["1 kg chicken"],"steps":["Wash","Cook"]}');
    expect(recipe.steps.length, 2);
    expect(() => parseRecipe('{"ingredients":["x"],"steps":[]}'), throwsA(isA<GeminiException>()));
  });

  test('the dish prompt carries the answers and the ingredients', () {
    final prompt = buildSuggestPrompt(_request);
    expect(prompt, contains('dinner'));
    expect(prompt, contains('light'));
    expect(prompt, contains('rice'));
    expect(prompt, contains('chicken, onion, rice'));
  });

  test('suggestDishes sends the prompt and parses the answer', () async {
    String? seenPrompt;
    final service = GeminiService(generate: (prompt, schema) async {
      seenPrompt = prompt;
      return '{"dishes":[{"name":"Egg curry","why":"Quick.","mainIngredients":["egg"]}]}';
    });
    final dishes = await service.suggestDishes(_request);
    expect(dishes.single.name, 'Egg curry');
    expect(seenPrompt, contains('chicken, onion, rice'));
  });

  test('splitIngredients handles commas, new lines and blanks', () {
    expect(splitIngredients('chicken, onion\nrice,, '), ['chicken', 'onion', 'rice']);
    expect(splitIngredients('   '), isEmpty);
  });
}

void fallbackTests() {
  test('a busy first model falls back to the next one', () async {
    final tried = <String>[];
    final text = await generateWithFallback(['big', 'small'], (m) async {
      tried.add(m);
      if (m == 'big') throw ServerException('high demand');
      return 'ok';
    });
    expect(text, 'ok');
    expect(tried, ['big', 'small']);
  });

  test('when every model is busy mum gets one short message', () async {
    expect(
      () => generateWithFallback(['a', 'b'], (m) async => throw ServerException('busy')),
      throwsA(isA<GeminiException>().having((e) => e.message, 'message', contains('very busy'))),
    );
  });
}
