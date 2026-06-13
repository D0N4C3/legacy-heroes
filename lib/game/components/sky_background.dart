import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_sized.dart';

/// A layered, code-drawn parallax background (Visual Plan §5 "Environments").
/// Far sky gradient → hills → ground, with gentle drift for depth.
/// Designed so painted PNG layers can replace each band later.
class SkyBackground extends PositionComponent with GameSized {
  SkyBackground({
    required this.topColor,
    required this.midColor,
    required this.horizonColor,
    required this.groundColor,
    this.hillColor,
    this.stars = false,
    this.groundLevel = 0.74,
    int priority = 0,
  }) {
    this.priority = priority;
  }

  Color topColor;
  Color midColor;
  Color horizonColor;
  Color groundColor;
  Color? hillColor;
  bool stars;

  /// Fraction of screen height where the ground band begins. Hill layers are
  /// derived just above it so scenes can raise/lower the horizon to keep the
  /// hero clear of HUD overlays.
  double groundLevel;

  double _t = 0;
  final List<Offset> _starField =
      List.generate(60, (_) => Offset(_rng.nextDouble(), _rng.nextDouble() * 0.5));
  static final _rng = Random();

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Sky gradient.
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, midColor, horizonColor],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    // Stars (twinkle) for dungeon/boss/night moods.
    if (stars) {
      final p = Paint()..color = const Color(0xFFFFFFFF);
      for (var i = 0; i < _starField.length; i++) {
        final s = _starField[i];
        final tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(_t * 2 + i));
        p.color = Color.fromRGBO(255, 255, 245, tw * 0.8);
        canvas.drawCircle(Offset(s.dx * w, s.dy * h), 1.2 + tw, p);
      }
    }

    // Distant moon / sun glow.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [horizonColor.withValues(alpha: 0.55), horizonColor.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.78, h * 0.30), radius: w * 0.4));
    canvas.drawRect(rect, glow);

    // Rolling hills (two parallax layers), derived from groundLevel so the
    // horizon stays just above the ground band.
    final drift = sin(_t * 0.15) * 12;
    _drawHills(canvas, h * (groundLevel - 0.12), (hillColor ?? horizonColor).withValues(alpha: 0.55),
        drift * 0.5, 0.9);
    _drawHills(canvas, h * (groundLevel - 0.04), (hillColor ?? horizonColor).withValues(alpha: 0.85),
        drift, 1.3);

    // Ground.
    final groundRect = Rect.fromLTWH(0, h * groundLevel, w, h * (1 - groundLevel));
    final ground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [groundColor, _darken(groundColor, 0.25)],
      ).createShader(groundRect);
    canvas.drawRect(groundRect, ground);
  }

  void _drawHills(Canvas canvas, double baseY, Color color, double dx, double freq) {
    final path = Path()..moveTo(0, h);
    path.lineTo(0, baseY);
    for (double x = 0; x <= w; x += 8) {
      final y = baseY - sin((x / w * pi * freq) + dx * 0.05) * 26 - 26;
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  Color _darken(Color c, double amount) {
    final f = 1 - amount;
    return Color.fromARGB(
      (c.a * 255.0).round().clamp(0, 255).toInt(),
      (c.r * 255.0 * f).round().clamp(0, 255).toInt(),
      (c.g * 255.0 * f).round().clamp(0, 255).toInt(),
      (c.b * 255.0 * f).round().clamp(0, 255).toInt(),
    );
  }
}
