import 'package:flutter/services.dart';

/// A small buzz that confirms a key action. Never throws: some devices have no vibration.
abstract final class Haptics {
  /// A light tick for choices and steppers.
  static void tick() => _run(HapticFeedback.selectionClick);

  /// A firmer tap when something is saved or added.
  static void success() => _run(HapticFeedback.mediumImpact);

  /// For something she should notice: a delete, an error.
  static void warn() => _run(HapticFeedback.heavyImpact);

  static void _run(Future<void> Function() buzz) {
    try {
      buzz().catchError((Object _) {});
    } catch (_) {
      // no vibration available: nothing to do
    }
  }
}
