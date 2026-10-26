import 'package:flutter/material.dart';

import 'context_ext.dart';
import 'haptics.dart';
import 'tokens.dart';

/// A big minus / value / plus control for amounts, so she taps instead of typing.
/// Each button is 48dp. The value is announced to screen readers as "Milk, 2 litres".
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.unitLabel,
    required this.itemName,
    this.min = 0,
    this.max,
    this.step = 1,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String unitLabel;
  final String itemName;
  final double min;
  final double? max;
  final double step;

  String get _shown => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canLess = value - step >= min;
    final canMore = max == null || value + step <= max!;
    return Semantics(
      container: true,
      label: l10n.amountOf(itemName, '$_shown $unitLabel'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: l10n.lessOf(itemName),
            onPressed: canLess ? () => _go(value - step) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: ExcludeSemantics(
              child: Text(
                '$_shown $unitLabel',
                textAlign: TextAlign.center,
                style: context.text.titleMedium,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: l10n.moreOf(itemName),
            onPressed: canMore ? () => _go(value + step) : null,
          ),
        ],
      ),
    );
  }

  void _go(double next) {
    Haptics.tick();
    onChanged(next);
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: minTouchTarget, minHeight: minTouchTarget),
    );
  }
}
