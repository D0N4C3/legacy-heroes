import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Hero animation states the game can request (Visual Plan §5).
enum HeroAnim { idle, train, attack, victory, hurt }

/// A code-drawn, animated chibi hero. Placeholder visuals built to be swapped
/// for layered sprite sheets later (Visual Plan §5 "layer system"): the body,
/// head, weapon and accents are drawn as separate pieces.
///
/// Animations: idle breathing + bob + blink, training/attack weapon swing,
/// victory arms-up. Class identity comes through [heroColor].
class HeroAvatar extends PositionComponent {
  HeroAvatar({
    required Vector2 position,
    required this.heroColor,
    this.anim = HeroAnim.idle,
    double scale = 1.0,
  }) : _scale = scale {
    this.position = position;
    priority = 10;
  }

  Color heroColor;
  HeroAnim anim;
  final double _scale;

  double _t = 0;
  double _blink = 0;
  final _rng = Random();
  double _nextBlink = 2.5;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _blink += dt;
    if (_blink > _nextBlink) {
      if (_blink > _nextBlink + 0.12) {
        _blink = 0;
        _nextBlink = 2 + _rng.nextDouble() * 3;
      }
    }
  }

  bool get _isBlinking => _blink > _nextBlink;

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(_scale);

    final bob = sin(_t * 2) * 2;
    final breathe = 1 + sin(_t * 3) * 0.03;
    final lean = anim == HeroAnim.attack ? sin(_t * 10).abs() * 0.18 : 0.0;

    // Feet are at local origin (0,0); we draw upward.
    canvas.translate(0, bob);

    // Soft shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 46, height: 12),
      Paint()..color = const Color(0x55000000),
    );

    canvas.save();
    canvas.rotate(lean);

    final skin = const Color(0xFFF1C7A0);
    final dark = _darken(heroColor, 0.3);

    // Legs.
    final legPaint = Paint()..color = dark;
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -22, 9, 24), const Radius.circular(4)),
        legPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(3, -22, 9, 24), const Radius.circular(4)),
        legPaint);

    // Body (breathes).
    canvas.save();
    canvas.translate(0, -40);
    canvas.scale(1, breathe);
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_lighten(heroColor, 0.12), heroColor],
      ).createShader(const Rect.fromLTWH(-18, -22, 36, 40));
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -22, 36, 42), const Radius.circular(12)),
        body);
    // Belt.
    canvas.drawRect(const Rect.fromLTWH(-18, 8, 36, 5), Paint()..color = dark);
    canvas.restore();

    // Arms.
    final armPaint = Paint()..color = _lighten(heroColor, 0.05);
    final armSwing =
        (anim == HeroAnim.attack || anim == HeroAnim.train) ? sin(_t * 10) * 0.6 : 0.0;
    final armUp = anim == HeroAnim.victory ? -1.1 : 0.0;

    // Left arm.
    canvas.save();
    canvas.translate(-16, -52);
    canvas.rotate(armUp);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 8, 22), const Radius.circular(4)),
        armPaint);
    canvas.restore();

    // Right arm (holds weapon).
    canvas.save();
    canvas.translate(16, -52);
    canvas.rotate(armSwing + armUp);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 0, 8, 22), const Radius.circular(4)),
        armPaint);
    _drawWeapon(canvas);
    canvas.restore();

    // Head.
    canvas.save();
    canvas.translate(0, -66);
    canvas.drawCircle(Offset.zero, 15, Paint()..color = skin);
    // Hair.
    final hair = Paint()..color = const Color(0xFF3A2A1A);
    final hairPath = Path()
      ..moveTo(-15, -2)
      ..quadraticBezierTo(-16, -20, 0, -18)
      ..quadraticBezierTo(16, -20, 15, -2)
      ..quadraticBezierTo(8, -10, 0, -9)
      ..quadraticBezierTo(-8, -10, -15, -2)
      ..close();
    canvas.drawPath(hairPath, hair);
    // Eyes.
    final eye = Paint()..color = const Color(0xFF2A2A2A);
    if (_isBlinking) {
      final p = Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(-7, 2), const Offset(-3, 2), p);
      canvas.drawLine(const Offset(3, 2), const Offset(7, 2), p);
    } else {
      canvas.drawCircle(const Offset(-5, 2), 2, eye);
      canvas.drawCircle(const Offset(5, 2), 2, eye);
    }
    canvas.restore();

    canvas.restore(); // lean
    canvas.restore(); // scale
  }

  void _drawWeapon(Canvas canvas) {
    // A simple sword extending from the hand; swap per class later.
    final blade = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8EEF5), Color(0xFFAFC0D0)],
      ).createShader(const Rect.fromLTWH(-2, -34, 6, 34));
    canvas.save();
    canvas.translate(0, 18);
    // Guard.
    canvas.drawRect(const Rect.fromLTWH(-7, -2, 14, 4), Paint()..color = const Color(0xFF9A7B3B));
    // Blade.
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -34, 4, 32), const Radius.circular(2)),
        blade);
    canvas.restore();
  }

  Color _darken(Color c, double a) => Color.fromARGB(c.alpha,
      (c.red * (1 - a)).round(), (c.green * (1 - a)).round(), (c.blue * (1 - a)).round());
  Color _lighten(Color c, double a) => Color.fromARGB(c.alpha,
      (c.red + (255 - c.red) * a).round(),
      (c.green + (255 - c.green) * a).round(),
      (c.blue + (255 - c.blue) * a).round());
}
