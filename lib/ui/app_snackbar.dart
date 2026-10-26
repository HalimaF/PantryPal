import 'package:flutter/material.dart';

import 'context_ext.dart';

/// One way to tell her something happened. With [onUndo] it offers "Undo" for a few seconds, which
/// is kinder than a "Are you sure?" box for things that are easy to reverse.
abstract final class AppSnackbar {
  static void show(BuildContext context, String message, {VoidCallback? onUndo, bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.errorContainer : null,
          duration: Duration(seconds: onUndo == null ? 4 : 6),
          action: onUndo == null ? null : SnackBarAction(label: context.l10n.undo, onPressed: onUndo),
        ),
      );
  }
}
