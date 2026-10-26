import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart' show InvalidApiKey, QuotaExceeded, ServerException, ServiceApiNotEnabled;
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';

/// Runs [generateWithFallback] with models "a", "b", "c" where each model's outcome is given.
/// Returns what was tried, in order.
Future<({List<String> tried, Object? outcome})> _run(
  Map<String, Object Function()> behaviour, {
  List<String>? models,
}) async {
  final tried = <String>[];
  Object? outcome;
  try {
    outcome = await generateWithFallback(models ?? behaviour.keys.toList(), (model) async {
      tried.add(model);
      final result = behaviour[model]!();
      if (result is String) return result;
      throw result;
    });
  } catch (e) {
    outcome = e;
  }
  return (tried: tried, outcome: outcome);
}

String _message(Object? outcome) => (outcome as GeminiException).message;

void main() {
  group('trying one model after another', () {
    test('the first model answering is enough', () async {
      final r = await _run({'a': () => 'from a', 'b': () => 'from b'});
      expect(r.outcome, 'from a');
      expect(r.tried, ['a']);
    });

    test('a busy model (server error) moves on to the next', () async {
      final r = await _run({'a': () => ServerException('high demand'), 'b': () => 'from b'});
      expect(r.outcome, 'from b');
      expect(r.tried, ['a', 'b']);
    });

    test('running out of free requests moves on to the next', () async {
      final r = await _run({'a': () => QuotaExceeded('quota'), 'b': () => 'from b'});
      expect(r.outcome, 'from b');
    });

    test('a slow model moves on to the next', () async {
      final r = await _run({'a': () => TimeoutException('slow'), 'b': () => 'from b'});
      expect(r.outcome, 'from b');
    });

    test('an empty answer moves on to the next', () async {
      final r = await _run({'a': () => StateError('empty answer'), 'b': () => 'from b'});
      expect(r.outcome, 'from b');
    });

    test('it keeps going to the third model', () async {
      final r = await _run({
        'a': () => ServerException('1'),
        'b': () => QuotaExceeded('2'),
        'c': () => 'from c',
      });
      expect(r.outcome, 'from c');
      expect(r.tried, ['a', 'b', 'c']);
    });
  });

  group('when every model fails', () {
    test('she is told the helper is busy, in one short message', () async {
      final r = await _run({'a': () => ServerException('1'), 'b': () => ServerException('2')});
      expect(_message(r.outcome), contains('very busy'));
      expect(_message(r.outcome), isNot(contains('1')));
    });

    test('no models at all gives a plain message, not a crash', () async {
      final r = await _run({}, models: const []);
      expect(_message(r.outcome), contains('could not answer'));
    });
  });

  group('problems another model would not fix stop straight away', () {
    test('Gemini not switched on in Firebase: tells her where to switch it on', () async {
      final r = await _run({'a': () => ServiceApiNotEnabled('my-project'), 'b': () => 'from b'});
      expect(_message(r.outcome), contains('AI Logic'));
      expect(r.tried, ['a'], reason: 'the second model cannot fix this');
    });

    test('the app is not allowed to use Gemini', () async {
      final r = await _run({'a': () => InvalidApiKey('bad key'), 'b': () => 'from b'});
      expect(_message(r.outcome), contains('not allowed'));
      expect(r.tried, ['a']);
    });

    test('no internet: tells her to check it, and does not keep trying', () async {
      final r = await _run({'a': () => Exception('SocketException'), 'b': () => 'from b'});
      expect(_message(r.outcome), contains('check your internet'));
      expect(r.tried, ['a']);
    });
  });

  group('the messages never show technical detail', () {
    test('no model names, codes or project ids', () async {
      for (final failure in [
        ServiceApiNotEnabled('secret-project-123'),
        InvalidApiKey('AIzaSecretKey'),
        ServerException('INTERNAL 500 gemini-3.8-flash'),
        Exception('java.net.UnknownHostException'),
      ]) {
        final r = await _run({'a': () => failure});
        final text = _message(r.outcome);
        for (final secret in ['secret-project-123', 'AIzaSecretKey', 'gemini-3', 'INTERNAL', 'java.net']) {
          expect(text, isNot(contains(secret)), reason: '$failure leaked $secret');
        }
      }
    });
  });

  group('the model lists', () {
    test('every list has a backup', () {
      expect(geminiModels.length, greaterThan(1));
      expect(geminiImageModels.length, greaterThan(1));
    });

    test('no model is listed twice', () {
      expect(geminiModels.toSet().length, geminiModels.length);
      expect(geminiImageModels.toSet().length, geminiImageModels.length);
    });
  });
}
