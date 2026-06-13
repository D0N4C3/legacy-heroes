import 'package:flutter/material.dart';

import 'parchment_panel.dart';

/// Presents [builder] inside a parchment sheet sliding up over the world.
/// Standard scroll-style modal (Visual Plan §8). Returns the popped value.
Future<T?> showFantasySheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
        top: 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.82),
        child: SingleChildScrollView(
          child: ParchmentPanel(title: title, child: builder(ctx)),
        ),
      ),
    ),
  );
}

/// A centered, non-dismissible ceremony dialog (e.g. reward reveal).
Future<T?> showFantasyDialog<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  bool dismissible = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, a1, a2) => Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Material(
          color: Colors.transparent,
          child: ParchmentPanel(title: title, child: builder(ctx)),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}
