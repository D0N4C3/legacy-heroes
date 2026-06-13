import 'package:flutter/material.dart';

import '../../app/palette.dart';

/// A parchment panel with a gold border — the standard fantasy surface for
/// modals, sheets and info blocks (Visual Plan §8). Never a plain white card.
class ParchmentPanel extends StatelessWidget {
  const ParchmentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.title,
  });

  final Widget child;
  final EdgeInsets padding;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.parchment, Palette.parchmentDark],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.goldDark, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) _Banner(title!),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14, left: 24, right: 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Palette.goldDark, Palette.gold, Palette.goldDark]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.woodDark, width: 1.5),
      ),
      child: Text(
        title.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Palette.woodDark,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 15,
        ),
      ),
    );
  }
}
