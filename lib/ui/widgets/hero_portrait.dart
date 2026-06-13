import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../game/art/hero_art.dart';

/// Paints a class-specific hero bust — the same [HeroArt] used by the in-world
/// avatar, so portraits and the live hero always match.
class _BustPainter extends CustomPainter {
  _BustPainter({required this.classId, this.memorial = false});
  final String classId;
  final bool memorial;

  @override
  void paint(Canvas canvas, Size size) =>
      HeroArt.drawBust(canvas, size, classId, memorial: memorial);

  @override
  bool shouldRepaint(covariant _BustPainter old) =>
      old.classId != classId || old.memorial != memorial;
}

/// A framed, circular hero portrait (Visual Plan §6 Home / §3C Family Tree).
class HeroPortrait extends StatelessWidget {
  const HeroPortrait({
    super.key,
    required this.classId,
    this.size = 72,
    this.memorial = false,
    this.highlighted = false,
  });

  final String classId;
  final double size;
  final bool memorial;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tint = HeroArt.visualFor(classId).primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          (memorial ? Palette.parchmentShadow : tint).withValues(alpha: 0.4),
          Palette.woodDark,
        ]),
        border: Border.all(
          color: highlighted ? Palette.goldLight : (memorial ? Palette.gold : Palette.goldDark),
          width: highlighted ? 4 : 3,
        ),
        boxShadow: highlighted
            ? [BoxShadow(color: Palette.goldLight.withValues(alpha: 0.6), blurRadius: 14)]
            : null,
      ),
      child: ClipOval(
        child: CustomPaint(painter: _BustPainter(classId: classId, memorial: memorial)),
      ),
    );
  }
}
