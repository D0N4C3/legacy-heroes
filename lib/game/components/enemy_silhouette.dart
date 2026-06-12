import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// A menacing dark enemy with glowing eyes (Visual Plan §4 Dungeon/Boss).
/// [boss] makes it larger and adds a heavier sway for dramatic encounters.
class EnemySilhouette extends PositionComponent {
  EnemySilhouette({
    required Vector2 position,
    this.boss = false,
    this.tint = const Color(0xFF1B1026),
    this.eyeColor = const Color(0xFFFF5252),
  }) {
    this.position = position;
    priority = 9;
  }

  final bool boss;
  final Color tint;
  final Color eyeColor;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final s = boss ? 1.8 : 1.0;
    final sway = sin(_t * (boss ? 1.2 : 2)) * (boss ? 6 : 3);
    canvas.save();
    canvas.translate(sway, 0);
    canvas.scale(s);

    final body = Paint()..color = tint;
    // Hunched body blob.
    final path = Path()
      ..moveTo(-26, 0)
      ..quadraticBezierTo(-34, -46, 0, -54)
      ..quadraticBezierTo(34, -46, 26, 0)
      ..close();
    canvas.drawPath(path, body);
    // Horns.
    canvas.drawPath(
        Path()
          ..moveTo(-18, -48)
          ..lineTo(-30, -70)
          ..lineTo(-10, -52)
          ..close(),
        body);
    canvas.drawPath(
        Path()
          ..moveTo(18, -48)
          ..lineTo(30, -70)
          ..lineTo(10, -52)
          ..close(),
        body);

    // Glowing eyes.
    final glow = Paint()
      ..color = eyeColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final pulse = 0.6 + 0.4 * sin(_t * 4);
    glow.color = eyeColor.withOpacity(pulse);
    canvas.drawCircle(const Offset(-9, -40), 3.5, glow);
    canvas.drawCircle(const Offset(9, -40), 3.5, glow);
    canvas.drawCircle(const Offset(-9, -40), 2, Paint()..color = const Color(0xFFFFE08A));
    canvas.drawCircle(const Offset(9, -40), 2, Paint()..color = const Color(0xFFFFE08A));

    canvas.restore();
  }
}
