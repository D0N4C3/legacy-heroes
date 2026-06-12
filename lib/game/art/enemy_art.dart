import 'dart:math';

import 'package:flutter/material.dart';

/// Distinct code-drawn enemies (Visual Plan §4 Dungeon/Boss). Each is drawn
/// with feet at the local origin (0,0), facing left toward the hero.
enum EnemyType { goblin, wolf, skeleton, demon }

class EnemyArt {
  EnemyArt._();

  static void draw(Canvas canvas, EnemyType type, double t, {bool boss = false}) {
    switch (type) {
      case EnemyType.goblin:
        _goblin(canvas, t);
        break;
      case EnemyType.wolf:
        _wolf(canvas, t);
        break;
      case EnemyType.skeleton:
        _skeleton(canvas, t);
        break;
      case EnemyType.demon:
        _demon(canvas, t, boss);
        break;
    }
  }

  static void _shadow(Canvas canvas, double w) {
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 2), width: w, height: 12),
        Paint()..color = const Color(0x55000000));
  }

  static void _eyes(Canvas canvas, Offset l, Offset r, Color color, double t, double rad) {
    final pulse = 0.6 + 0.4 * sin(t * 5);
    final glow = Paint()
      ..color = color.withOpacity(pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(l, rad + 1.5, glow);
    canvas.drawCircle(r, rad + 1.5, glow);
    canvas.drawCircle(l, rad, Paint()..color = const Color(0xFFFFF1A8));
    canvas.drawCircle(r, rad, Paint()..color = const Color(0xFFFFF1A8));
  }

  // ── Goblin ────────────────────────────────────────────────────────────────
  static void _goblin(Canvas canvas, double t) {
    _shadow(canvas, 46);
    final bob = sin(t * 3) * 1.5;
    canvas.save();
    canvas.translate(0, bob);

    final skin = const Color(0xFF5E8C3A);
    final skinDark = const Color(0xFF3F6125);

    // Legs.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -16, 8, 16), const Radius.circular(3)), Paint()..color = skinDark);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, -16, 8, 16), const Radius.circular(3)), Paint()..color = skinDark);

    // Hunched body.
    final body = Path()
      ..moveTo(-16, -14)
      ..quadraticBezierTo(-22, -44, 4, -46)
      ..quadraticBezierTo(22, -42, 16, -14)
      ..close();
    canvas.drawPath(body, Paint()..color = skin);
    // Loincloth.
    canvas.drawRect(const Rect.fromLTWH(-14, -18, 28, 8), Paint()..color = const Color(0xFF6E4A2A));

    // Head with big ears.
    canvas.save();
    canvas.translate(2, -52);
    canvas.drawPath(
        Path()..moveTo(-12, 0)..lineTo(-26, -6)..lineTo(-12, -10)..close(), Paint()..color = skin);
    canvas.drawPath(
        Path()..moveTo(12, 0)..lineTo(26, -6)..lineTo(12, -10)..close(), Paint()..color = skin);
    canvas.drawCircle(Offset.zero, 13, Paint()..color = skin);
    canvas.drawCircle(const Offset(0, 4), 11, Paint()..color = skinDark.withOpacity(0.25));
    // Nose + grin.
    canvas.drawCircle(const Offset(-2, 4), 3, Paint()..color = skinDark);
    canvas.drawLine(const Offset(-6, 9), const Offset(6, 9),
        Paint()..color = const Color(0xFF2A2A2A)..strokeWidth = 1.5);
    _eyes(canvas, const Offset(-5, -2), const Offset(6, -2), const Color(0xFFE23A2B), t, 2.2);
    canvas.restore();

    // Club.
    canvas.save();
    canvas.translate(-16, -30);
    canvas.rotate(-0.5 + sin(t * 4) * 0.1);
    canvas.drawRect(const Rect.fromLTWH(-3, -2, 6, 26), Paint()..color = const Color(0xFF5A3D24));
    canvas.drawCircle(const Offset(0, -6), 8, Paint()..color = const Color(0xFF6E4A2A));
    canvas.restore();

    canvas.restore();
  }

  // ── Wolf ────────────────────────────────────────────────────────────────
  static void _wolf(Canvas canvas, double t) {
    _shadow(canvas, 60);
    final bob = sin(t * 4) * 1.0;
    canvas.save();
    canvas.translate(0, bob);
    final fur = const Color(0xFF6B6F78);
    final furDark = const Color(0xFF474A52);

    // Legs.
    for (final x in [-22.0, -6.0, 10.0, 24.0]) {
      canvas.drawRect(Rect.fromLTWH(x, -16, 6, 16), Paint()..color = furDark);
    }
    // Body.
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-26, -36, 50, 24), const Radius.circular(12)),
        Paint()..color = fur);
    // Tail.
    canvas.drawPath(
        Path()
          ..moveTo(24, -30)
          ..quadraticBezierTo(44, -38, 40 + sin(t * 4) * 3, -52)
          ..quadraticBezierTo(34, -36, 24, -24)
          ..close(),
        Paint()..color = fur);
    // Head + snout (facing left).
    canvas.save();
    canvas.translate(-24, -34);
    canvas.drawCircle(Offset.zero, 13, Paint()..color = fur);
    canvas.drawPath(
        Path()..moveTo(-6, 2)..lineTo(-22, 6)..lineTo(-6, 12)..close(), Paint()..color = furDark);
    // Ears.
    canvas.drawPath(Path()..moveTo(2, -10)..lineTo(6, -22)..lineTo(10, -10)..close(), Paint()..color = fur);
    canvas.drawPath(Path()..moveTo(-8, -10)..lineTo(-6, -22)..lineTo(-2, -10)..close(), Paint()..color = fur);
    _eyes(canvas, const Offset(-6, -1), const Offset(2, -1), const Color(0xFFFFC53A), t, 2);
    canvas.restore();
    canvas.restore();
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  static void _skeleton(Canvas canvas, double t) {
    _shadow(canvas, 40);
    final bob = sin(t * 2.5) * 1.2;
    canvas.save();
    canvas.translate(0, bob);
    final bone = const Color(0xFFE8E4D4);
    final boneShade = const Color(0xFFB9B3A0);

    // Legs.
    canvas.drawRect(const Rect.fromLTWH(-7, -22, 4, 22), Paint()..color = bone);
    canvas.drawRect(const Rect.fromLTWH(3, -22, 4, 22), Paint()..color = bone);
    // Spine + ribs.
    canvas.drawRect(const Rect.fromLTWH(-2, -50, 4, 30), Paint()..color = bone);
    for (var i = 0; i < 4; i++) {
      final y = -46 + i * 7.0;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-11, y, 22, 4), const Radius.circular(2)),
          Paint()..color = boneShade);
    }
    // Shoulders + arms.
    canvas.drawRect(const Rect.fromLTWH(-14, -50, 28, 4), Paint()..color = bone);
    canvas.drawRect(const Rect.fromLTWH(-15, -50, 4, 24), Paint()..color = bone);
    canvas.save();
    canvas.translate(13, -48);
    canvas.rotate(sin(t * 4) * 0.2);
    canvas.drawRect(const Rect.fromLTWH(-2, 0, 4, 24), Paint()..color = bone);
    // Rusty sword.
    canvas.drawRect(const Rect.fromLTWH(-2, -22, 4, 24), Paint()..color = const Color(0xFF8A7B5A));
    canvas.restore();
    // Skull.
    canvas.save();
    canvas.translate(0, -58);
    canvas.drawCircle(Offset.zero, 10, Paint()..color = bone);
    canvas.drawRect(const Rect.fromLTWH(-4, 8, 8, 5), Paint()..color = bone); // jaw
    _eyes(canvas, const Offset(-4, 0), const Offset(4, 0), const Color(0xFF49E0C0), t, 2);
    canvas.restore();
    canvas.restore();
  }

  // ── Demon (boss) ──────────────────────────────────────────────────────────
  static void _demon(Canvas canvas, double t, bool boss) {
    final s = boss ? 1.7 : 1.0;
    _shadow(canvas, 70 * s);
    final sway = sin(t * 1.4) * 4;
    canvas.save();
    canvas.translate(sway, 0);
    canvas.scale(s);

    final body = const Color(0xFF6E1B22);
    final bodyDark = const Color(0xFF3E0E12);

    // Wings.
    final wing = Paint()..color = bodyDark;
    for (final dir in [-1.0, 1.0]) {
      final wp = Path()
        ..moveTo(0, -48)
        ..quadraticBezierTo(dir * 60, -70, dir * 52, -30)
        ..quadraticBezierTo(dir * 46, -36, dir * 30, -34)
        ..quadraticBezierTo(dir * 40, -22, dir * 20, -28)
        ..close();
      canvas.drawPath(wp, wing);
    }

    // Legs + body.
    canvas.drawRect(const Rect.fromLTWH(-12, -18, 9, 18), Paint()..color = bodyDark);
    canvas.drawRect(const Rect.fromLTWH(3, -18, 9, 18), Paint()..color = bodyDark);
    final torso = Path()
      ..moveTo(-20, -16)
      ..quadraticBezierTo(-26, -52, 0, -56)
      ..quadraticBezierTo(26, -52, 20, -16)
      ..close();
    canvas.drawPath(torso,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E2630), Color(0xFF4E1018)]).createShader(const Rect.fromLTWH(-26, -56, 52, 56)));
    // Abs detail.
    canvas.drawLine(const Offset(0, -50), const Offset(0, -22), Paint()..color = bodyDark..strokeWidth = 2);

    // Head with horns.
    canvas.save();
    canvas.translate(0, -64);
    canvas.drawCircle(Offset.zero, 14, Paint()..color = body);
    canvas.drawPath(Path()..moveTo(-10, -8)..lineTo(-22, -28)..lineTo(-4, -12)..close(), Paint()..color = bodyDark);
    canvas.drawPath(Path()..moveTo(10, -8)..lineTo(22, -28)..lineTo(4, -12)..close(), Paint()..color = bodyDark);
    // Mouth.
    canvas.drawArc(Rect.fromCenter(center: const Offset(0, 6), width: 16, height: 10), 0, pi,
        false, Paint()..color = const Color(0xFF2A0608));
    _eyes(canvas, const Offset(-6, 0), const Offset(6, 0), const Color(0xFFFF3020), t, 2.6);
    canvas.restore();

    // Fiery aura.
    canvas.drawCircle(const Offset(0, -34), 40,
        Paint()
          ..color = const Color(0xFFFF3A1A).withOpacity(0.12 + 0.05 * sin(t * 6))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.restore();
  }
}
