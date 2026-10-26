import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/theme.dart';
import 'package:what_can_i_cook/ui/app_button.dart';
import 'package:what_can_i_cook/ui/confirm_dialog.dart';
import 'package:what_can_i_cook/ui/quantity_stepper.dart';
import 'package:what_can_i_cook/ui/skeleton.dart';
import 'package:what_can_i_cook/ui/states.dart';
import 'package:what_can_i_cook/ui/status_chip.dart';

import '../helpers/test_app.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('contrast (WCAG AA 4.5:1 for text)', () {
    for (final dark in [false, true]) {
      final theme = dark ? buildDarkTheme(useWebFonts: false) : buildLightTheme(useWebFonts: false);
      final s = theme.colorScheme;
      final a = theme.extension<AppColors>()!;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onSecondary/secondary': (s.onSecondary, s.secondary),
        'onPrimaryContainer/primaryContainer': (s.onPrimaryContainer, s.primaryContainer),
        'onError/error': (s.onError, s.error),
        'onErrorContainer/errorContainer': (s.onErrorContainer, s.errorContainer),
        'primary/surface (links)': (s.primary, s.surface),
        'onSuccess/successContainer': (a.onSuccessContainer, a.successContainer),
        'onWarning/warningContainer': (a.onWarningContainer, a.warningContainer),
        'onSurface/surfaceContainerLow (cards)': (s.onSurface, s.surfaceContainerLow),
      };
      pairs.forEach((name, p) {
        test('${dark ? "dark" : "light"}: $name', () {
          expect(contrast(p.$1, p.$2), greaterThanOrEqualTo(4.5));
        });
      });
    }
  });

  group('type scale', () {
    test('uses only four sizes', () {
      final t = buildLightTheme(useWebFonts: false).textTheme;
      final sizes = {
        for (final s in [
          t.displayLarge, t.displayMedium, t.displaySmall, t.headlineLarge, t.headlineMedium,
          t.headlineSmall, t.titleLarge, t.titleMedium, t.titleSmall, t.bodyLarge, t.bodyMedium,
          t.bodySmall, t.labelLarge, t.labelMedium, t.labelSmall,
        ])
          if (s?.fontSize != null) s!.fontSize!,
      };
      expect(sizes, {28.0, 20.0, 16.0, 14.0});
    });
  });

  group('AppButton', () {
    testWidgets('fires onPressed and meets the 48dp touch target', (tester) async {
      var taps = 0;
      await tester.pumpWidget(testApp(AppButton(label: 'Save', onPressed: () => taps++)));
      await tester.tap(find.text('Save'));
      expect(taps, 1);
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(48));
    });

    testWidgets('loading shows its label and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(testApp(
        AppButton(label: 'Save', loadingLabel: 'Saving…', loading: true, onPressed: () => taps++),
      ));
      expect(find.text('Saving…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Saving…'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('disabled explains why', (tester) async {
      await tester.pumpWidget(testApp(
        const AppButton(label: 'Add', onPressed: null, disabledReason: 'Add an item first'),
      ));
      expect(find.text('Add an item first'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('EmptyState shows message and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testApp(EmptyState(
        icon: Icons.kitchen_rounded,
        message: 'Nothing here yet',
        actionLabel: 'Add groceries',
        onAction: () => tapped = true,
      )));
      expect(find.text('Nothing here yet'), findsOneWidget);
      await tester.tap(find.text('Add groceries'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorState retry works', (tester) async {
      var retried = false;
      await tester.pumpWidget(testApp(ErrorState(
        message: 'Could not load',
        retryLabel: 'Try again',
        onRetry: () => retried = true,
      )));
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    for (final reduce in [false, true]) {
      testWidgets('SkeletonLoader renders (reduce motion: $reduce)', (tester) async {
        await tester.pumpWidget(testApp(SkeletonLoader.list(), reduceMotion: reduce));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(SkeletonBox), findsWidgets);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('StatusChip', () {
    testWidgets('shows icon and words for every tone', (tester) async {
      await tester.pumpWidget(testApp(Column(children: [
        for (final t in StatusTone.values) StatusChip(label: t.name, icon: Icons.circle, tone: t),
      ])));
      for (final t in StatusTone.values) {
        expect(find.text(t.name), findsOneWidget);
      }
      expect(find.byIcon(Icons.circle), findsNWidgets(StatusTone.values.length));
    });
  });

  group('QuantityStepper', () {
    testWidgets('plus and minus change the value and stop at limits', (tester) async {
      var v = 1.0;
      late StateSetter set;
      await tester.pumpWidget(testApp(StatefulBuilder(builder: (c, s) {
        set = s;
        return QuantityStepper(
          value: v, onChanged: (n) => set(() => v = n), unitLabel: 'kg', itemName: 'Rice', max: 2,
        );
      })));
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(v, 2);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_rounded)).onPressed, isNull);
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(v, 0);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove_rounded)).onPressed, isNull);
    });
  });

  group('confirmAction', () {
    testWidgets('returns true on confirm and false on cancel', (tester) async {
      bool? result;
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await confirmAction(
            context, title: 'Remove milk?', message: 'This cannot be undone.', confirmLabel: 'Remove'),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(result, isTrue);

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
