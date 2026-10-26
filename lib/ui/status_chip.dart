import 'package:flutter/material.dart';

import 'context_ext.dart';
import 'tokens.dart';

enum StatusTone { neutral, success, warning, error, info }

/// A small label with an icon: "Low", "Have", "From your recipe book". Meaning is never carried by
/// colour alone: there is always an icon and words (accessibility).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.icon, this.tone = StatusTone.neutral});

  final String label;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final app = context.appColors;
    final (Color back, Color ink) = switch (tone) {
      StatusTone.success => (app.successContainer, app.onSuccessContainer),
      StatusTone.warning => (app.warningContainer, app.onWarningContainer),
      StatusTone.error => (colors.errorContainer, colors.onErrorContainer),
      StatusTone.info => (colors.primaryContainer, colors.onPrimaryContainer),
      StatusTone.neutral => (colors.surfaceContainerHigh, colors.onSurface),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs),
        decoration: BoxDecoration(color: back, borderRadius: Corner.smallRadius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ink),
            const SizedBox(width: Space.xs),
            Flexible(
              child: Text(
                label,
                style: context.text.labelMedium?.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
