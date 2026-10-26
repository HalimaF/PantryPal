import 'package:flutter/material.dart';

import 'app_button.dart';
import 'context_ext.dart';
import 'tokens.dart';

/// Shown when there is nothing yet: a picture, one plain sentence, and one clear next step.
/// (Help users recover; minimalist design: never a blank screen.)
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Illustration(icon: icon),
              const SizedBox(height: Space.l),
              Text(message, textAlign: TextAlign.center, style: context.text.bodyLarge),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Space.l),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: Space.s),
                AppButton(label: secondaryLabel!, onPressed: onSecondary, kind: AppButtonKind.text),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Something went wrong: what happened in plain words, and a way to fix it.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Illustration(icon: Icons.cloud_off_rounded, tone: context.colors.errorContainer, ink: context.colors.onErrorContainer),
                const SizedBox(height: Space.l),
                Text(message, textAlign: TextAlign.center, style: context.text.bodyLarge),
                const SizedBox(height: Space.l),
                AppButton(label: retryLabel, onPressed: onRetry, icon: Icons.refresh_rounded),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: Space.s),
                  AppButton(label: secondaryLabel!, onPressed: onSecondary, kind: AppButtonKind.text),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft circle with a big icon and two small dots, drawn in code so no image files are needed.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, this.tone, this.ink});

  final IconData icon;
  final Color? tone;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: tone ?? colors.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 52, color: ink ?? colors.onPrimaryContainer),
            ),
            Positioned(
              top: 6,
              right: 12,
              child: _dot(colors.secondaryContainer, 18),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: _dot(colors.surfaceContainerHighest, 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, double size) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
