import 'package:flutter/material.dart';

import 'context_ext.dart';
import 'tokens.dart';

/// A heading for a group of things, with an optional action on the right ("See all").
/// Marked as a heading so a screen reader can jump between sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.titleLarge),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: Space.s),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}
