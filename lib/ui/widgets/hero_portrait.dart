import 'package:flutter/material.dart';

import '../../app/palette.dart';

/// Paints a small chibi hero face in the class color — shared by the live
/// hero portrait and the family-tree memorial portraits.
class HeroFacePainter extends CustomPainter {
  HeroFacePainter({required this.color, this.memorial = false});

  final Color color;
  final bool memorial; // greyed/golden for fallen ancestors

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final faceColor = memorial ? const Color(0xFFD8C8A8) : const Color(0xFFF1C7A0);

    // Shoulders (class color).
    final shoulder = Paint()..color = memorial ? Palette.parchmentShadow : color;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(c.dx, c.dy + r * 1.1), radius: r * 1.2),
      3.4, 2.5, true, shoulder,
    );

    // Head.
    canvas.drawCircle(c.translate(0, -r * 0.1), r * 0.7, Paint()..color = faceColor);

    // Hair.
    final hair = Paint()..color = memorial ? const Color(0xFF8A7A5A) : const Color(0xFF3A2A1A);
    final hp = Path()
      ..moveTo(c.dx - r * 0.7, c.dy - r * 0.1)
      ..quadraticBezierTo(c.dx, c.dy - r * 1.1, c.dx + r * 0.7, c.dy - r * 0.1)
      ..quadraticBezierTo(c.dx, c.dy - r * 0.5, c.dx - r * 0.7, c.dy - r * 0.1)
      ..close();
    canvas.drawPath(hp, hair);

    // Eyes.
    final eye = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(c.translate(-r * 0.25, -r * 0.05), r * 0.08, eye);
    canvas.drawCircle(c.translate(r * 0.25, -r * 0.05), r * 0.08, eye);
  }

  @override
  bool shouldRepaint(covariant HeroFacePainter old) =>
      old.color != color || old.memorial != memorial;
}

/// A framed, circular hero portrait (Visual Plan §6 Home / §3C Family Tree).
class HeroPortrait extends StatelessWidget {
  const HeroPortrait({
    super.key,
    required this.color,
    this.size = 72,
    this.memorial = false,
    this.highlighted = false,
  });

  final Color color;
  final double size;
  final bool memorial;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withOpacity(0.35),
          Palette.woodDark,
        ]),
        border: Border.all(
          color: highlighted ? Palette.goldLight : (memorial ? Palette.gold : Palette.goldDark),
          width: highlighted ? 4 : 3,
        ),
        boxShadow: highlighted
            ? [BoxShadow(color: Palette.goldLight.withOpacity(0.6), blurRadius: 14)]
            : null,
      ),
      child: ClipOval(
        child: CustomPaint(painter: HeroFacePainter(color: color, memorial: memorial)),
      ),
    );
  }
}
