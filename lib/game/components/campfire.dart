import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A flickering campfire (Visual Plan §4 Village Scene). Code-drawn flame with
/// a warm glow that breathes — anchors the cozy "home" feeling.
class Campfire extends PositionComponent {
  Campfire({required Vector2 position}) {
    this.position = position;
    priority = 8;
  }

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final flicker = 0.85 + 0.15 * sin(_t * 12) + 0.05 * sin(_t * 23);

    // Warm ground glow.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB347).withValues(alpha: 0.5 * flicker),
          const Color(0xFFFFB347).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 70 * flicker));
    canvas.drawCircle(Offset.zero, 70 * flicker, glow);

    // Logs.
    final log = Paint()..color = const Color(0xFF4A2E18);
    canvas.save();
    canvas.translate(0, 6);
    for (final a in [-0.5, 0.0, 0.5]) {
      canvas.save();
      canvas.rotate(a);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-16, -3, 32, 6), const Radius.circular(3)),
          log);
      canvas.restore();
    }
    canvas.restore();

    // Flame (layered teardrops).
    void flame(Color c, double scale) {
      final path = Path();
      final hgt = 34 * scale * flicker;
      path.moveTo(0, -hgt);
      path.quadraticBezierTo(13 * scale, -hgt * 0.4, 0, 4);
      path.quadraticBezierTo(-13 * scale, -hgt * 0.4, 0, -hgt);
      path.close();
      canvas.drawPath(path, Paint()..color = c);
    }

    flame(const Color(0xFFE2502B), 1.0);
    flame(const Color(0xFFF7A23B), 0.7);
    flame(const Color(0xFFFFE08A), 0.4);
  }
}
