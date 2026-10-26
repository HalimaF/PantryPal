import 'package:flutter/material.dart';

import 'context_ext.dart';
import 'haptics.dart';
import 'tokens.dart';

/// A row of 2 to 4 choices with a small label on the left ("Meal", "Weight", "With"). The chosen one
/// is lifted and ticked, so it is never shown by colour alone. Replaces dropdowns (Hick's law).
class SegmentedChoice extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelOf,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Words to show for a stored value (translation). Defaults to the value itself.
  final String Function(String value)? labelOf;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: Corner.mediumRadius),
            child: Row(
              children: [
                for (final o in options)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: o == selected,
                      label: labelOf?.call(o) ?? o,
                      excludeSemantics: true,
                      onTap: () => onSelected(o),
                      child: InkWell(
                        borderRadius: Corner.smallRadius,
                        onTap: () {
                          Haptics.tick();
                          onSelected(o);
                        },
                        child: AnimatedContainer(
                          duration: context.motion(150),
                          constraints: const BoxConstraints(minHeight: 44),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                          decoration: BoxDecoration(
                            color: o == selected ? colors.surfaceContainerLowest : Colors.transparent,
                            borderRadius: Corner.smallRadius,
                            border: o == selected ? Border.all(color: colors.outlineVariant) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (o == selected) ...[
                                Icon(Icons.check_rounded, size: 16, color: colors.primary),
                                const SizedBox(width: 2),
                              ],
                              Flexible(
                                child: Text(
                                  labelOf?.call(o) ?? o,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelMedium?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: o == selected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
