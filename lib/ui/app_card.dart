import 'package:flutter/material.dart';

import 'context_ext.dart';
import 'tokens.dart';

/// A rounded box that groups related things together (Gestalt: proximity). Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.m),
    this.color,
    this.semanticsLabel,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final String? semanticsLabel;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: Corner.mediumRadius,
      side: BorderSide(color: borderColor ?? context.colors.outlineVariant),
    );
    final box = Material(
      color: color ?? context.colors.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: minTouchTarget),
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
    if (semanticsLabel == null) return box;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticsLabel,
      excludeSemantics: onTap != null,
      onTap: onTap,
      child: box,
    );
  }
}
