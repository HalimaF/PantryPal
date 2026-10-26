import 'package:flutter/material.dart';

import 'context_ext.dart';
import 'tokens.dart';

enum AppButtonKind { primary, secondary, text }

/// The one button used everywhere. Always has a text label (icons never stand alone for a main
/// action). While [loading] it says what is happening, and when it cannot be pressed it can say why.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = AppButtonKind.primary,
    this.loading = false,
    this.loadingLabel,
    this.expand = true,
    this.disabledReason,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;

  /// Shows a small spinner and [loadingLabel] (or [label]), and ignores presses.
  final bool loading;
  final String? loadingLabel;

  /// Full width (the default) or only as wide as its text.
  final bool expand;

  /// Shown under the button when it is disabled: "Add at least one item first".
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final shownLabel = loading ? (loadingLabel ?? label) : label;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        else if (icon != null)
          Icon(icon, size: 22),
        if (loading || icon != null) const SizedBox(width: Space.s),
        Flexible(child: Text(shownLabel, textAlign: TextAlign.center)),
      ],
    );

    final button = switch (kind) {
      AppButtonKind.primary => FilledButton(onPressed: enabled ? onPressed : null, child: child),
      AppButtonKind.secondary => OutlinedButton(onPressed: enabled ? onPressed : null, child: child),
      AppButtonKind.text => TextButton(onPressed: enabled ? onPressed : null, child: child),
    };

    final sized = expand ? SizedBox(width: double.infinity, child: button) : button;
    final reason = (!enabled && !loading) ? disabledReason : null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: shownLabel,
      hint: reason,
      excludeSemantics: true,
      onTap: enabled ? onPressed : null,
      child: reason == null
          ? sized
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                sized,
                const SizedBox(height: Space.xs),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}
