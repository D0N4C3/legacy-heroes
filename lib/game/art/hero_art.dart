import 'dart:math';

import 'package:flutter/material.dart';

/// Animation states a hero can be drawn in.
enum HeroAnim { idle, train, attack, victory, hurt }

enum Weapon { sword, bow, staff, mace, hammer }

enum Head { hair, hood, wizardHat, halo, bandana }

/// A per-class visual recipe — palette + gear. Hand-tuned so each class reads
/// instantly even at small sizes (Visual Plan §5 "layer system").
class HeroVisual {
  final Color primary; // main outfit
  final Color primaryLight; // outfit highlight
  final Color secondary; // trim / leggings
  final Color accent; // metal / magic glow
  final Color cloak; // cape (null-ish = none)
  final bool hasCloak;
  final bool hasShield;
  final bool beard;
  final Weapon weapon;
  final Head head;

  const HeroVisual({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.cloak,
    required this.hasCloak,
    required this.hasShield,
    required this.beard,
    required this.weapon,
    required this.head,
  });
}

/// Draws hero sprites entirely in code. Shared by the in-world Flame avatar and
/// the Flutter portrait widgets so a hero looks identical everywhere.
class HeroArt {
  HeroArt._();

  static const _skin = Color(0xFFF1C7A0);
  static const _skinShade = Color(0xFFD9A87C);
  static const _hair = Color(0xFF3A2A1A);

  static const Map<String, HeroVisual> _visuals = {
    'warrior': HeroVisual(
      primary: Color(0xFFB23A2B),
      primaryLight: Color(0xFFD9583F),
      secondary: Color(0xFF6E2018),
      accent: Color(0xFFD9C26A),
      cloak: Color(0xFF7A1F16),
      hasCloak: true,
      hasShield: false,
      beard: false,
      weapon: Weapon.sword,
      head: Head.hair,
    ),
    'ranger': HeroVisual(
      primary: Color(0xFF2E7D4F),
      primaryLight: Color(0xFF45A56C),
      secondary: Color(0xFF26543A),
      accent: Color(0xFFB6884A),
      cloak: Color(0xFF1F5E3A),
      hasCloak: true,
      hasShield: false,
      beard: false,
      weapon: Weapon.bow,
      head: Head.hood,
    ),
    'mage': HeroVisual(
      primary: Color(0xFF5B4BC4),
      primaryLight: Color(0xFF7C6BE0),
      secondary: Color(0xFF38307E),
      accent: Color(0xFF7CE0FF),
      cloak: Color(0xFF463AA0),
      hasCloak: false,
      hasShield: false,
      beard: true,
      weapon: Weapon.staff,
      head: Head.wizardHat,
    ),
    'paladin': HeroVisual(
      primary: Color(0xFFE9E2D0),
      primaryLight: Color(0xFFFFFFFF),
      secondary: Color(0xFFB9A24A),
      accent: Color(0xFFE7B53C),
      cloak: Color(0xFFC9A227),
      hasCloak: true,
      hasShield: true,
      beard: false,
      weapon: Weapon.mace,
      head: Head.halo,
    ),
    'blacksmith': HeroVisual(
      primary: Color(0xFF7A5230),
      primaryLight: Color(0xFF9A6B40),
      secondary: Color(0xFF4A2E18),
      accent: Color(0xFFE08A3C),
      cloak: Color(0xFF4A2E18),
      hasCloak: false,
      hasShield: false,
      beard: true,
      weapon: Weapon.hammer,
      head: Head.bandana,
    ),
  };

  static HeroVisual visualFor(String classId) =>
      _visuals[classId] ?? _visuals['warrior']!;

  /// Draw a full-body hero with feet at the local origin (0,0), facing right.
  ///
  /// [attackPulse] (0–1) exaggerates the arm swing for a one-shot "hit" on
  /// tap; [hitFlash] (0–1) briefly tints the hero on taking a counter-hit.
  /// Both are additive and default to 0 — existing idle/train rendering is
  /// unchanged.
  static void drawBody(
    Canvas canvas, {
    required String classId,
    required double t,
    required HeroAnim anim,
    required bool blinking,
    double attackPulse = 0,
    double hitFlash = 0,
  }) {
    final v = visualFor(classId);

    final bob = sin(t * 2) * 1.6;
    final breathe = 1 + sin(t * 3) * 0.03;
    var lean = anim == HeroAnim.attack ? sin(t * 9).abs() * 0.16 : 0.0;
    var armSwing = (anim == HeroAnim.attack || anim == HeroAnim.train)
        ? sin(t * 9) * 0.7
        : sin(t * 2) * 0.06;
    final armsUp = anim == HeroAnim.victory;

    if (attackPulse > 0) {
      lean += attackPulse * 0.18;
      armSwing += attackPulse * 1.1;
    }

    canvas.save();
    canvas.translate(0, bob);

    if (hitFlash > 0) {
      canvas.saveLayer(
          null,
          Paint()
            ..colorFilter = ColorFilter.mode(
                Color.fromRGBO(255, 70, 70, hitFlash.clamp(0.0, 1.0)),
                BlendMode.srcATop));
    }

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 50, height: 12),
      Paint()..color = const Color(0x55000000),
    );

    // Cloak behind the body.
    if (v.hasCloak) _drawCloak(canvas, v, t);

    canvas.save();
    canvas.rotate(lean);

    _drawLegs(canvas, v);
    _drawTorso(canvas, v, breathe);
    _drawBackArm(canvas, v, armsUp);
    _drawHead(canvas, v, blinking);
    _drawFrontArmAndWeapon(canvas, v, armSwing, armsUp, t);
    if (v.hasShield) _drawShield(canvas, v);

    canvas.restore(); // lean

    if (hitFlash > 0) canvas.restore(); // flash layer

    canvas.restore(); // bob
  }

  /// Draw a head-and-shoulders bust filling [size], for portraits.
  static void drawBust(Canvas canvas, Size size, String classId,
      {bool memorial = false}) {
    final v = visualFor(classId);
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.width / 90; // body is ~90 units tall

    canvas.save();
    canvas.translate(c.dx, c.dy + 52 * s);
    canvas.scale(s);

    if (memorial) {
      canvas.saveLayer(
        Rect.fromCenter(center: const Offset(0, -60), width: 200, height: 200),
        Paint()..colorFilter = const ColorFilter.mode(Color(0xFFB59A6A), BlendMode.modulate),
      );
    }

    _drawTorso(canvas, v, 1.0);
    _drawBackArm(canvas, v, false);
    _drawHead(canvas, v, false);

    if (memorial) canvas.restore();
    canvas.restore();
  }

  // ── Parts ─────────────────────────────────────────────────────────────────
  static void _drawLegs(Canvas canvas, HeroVisual v) {
    final leg = Paint()..color = v.secondary;
    final boot = Paint()..color = _darken(v.secondary, 0.25);
    for (final x in [-11.0, 3.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, -22, 9, 20), const Radius.circular(4)), leg);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 1, -6, 11, 7), const Radius.circular(3)), boot);
    }
  }

  static void _drawTorso(Canvas canvas, HeroVisual v, double breathe) {
    canvas.save();
    canvas.translate(0, -40);
    canvas.scale(1, breathe);

    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [v.primaryLight, v.primary],
      ).createShader(const Rect.fromLTWH(-19, -24, 38, 46));

    // Robe flares for the mage; armor is boxier.
    if (v.head == Head.wizardHat) {
      final robe = Path()
        ..moveTo(-15, -22)
        ..lineTo(15, -22)
        ..lineTo(22, 24)
        ..lineTo(-22, 24)
        ..close();
      canvas.drawPath(robe, body);
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-19, -22, 38, 44), const Radius.circular(11)),
          body);
    }

    // Class-specific torso detail.
    switch (v.head) {
      case Head.bandana: // blacksmith apron
        final apron = Path()
          ..moveTo(-12, -18)
          ..lineTo(12, -18)
          ..lineTo(9, 20)
          ..lineTo(-9, 20)
          ..close();
        canvas.drawPath(apron, Paint()..color = _darken(v.secondary, 0.1));
        break;
      case Head.halo: // paladin chest cross
        canvas.drawRect(const Rect.fromLTWH(-2, -16, 4, 28), Paint()..color = v.accent);
        canvas.drawRect(const Rect.fromLTWH(-9, -6, 18, 4), Paint()..color = v.accent);
        break;
      case Head.wizardHat: // mage sash
        canvas.drawRect(const Rect.fromLTWH(-19, 4, 38, 5), Paint()..color = v.accent.withValues(alpha: 0.6));
        break;
      default:
        canvas.drawRect(const Rect.fromLTWH(-19, 6, 38, 5), Paint()..color = const Color(0x66000000));
    }

    // Pauldrons (warrior/paladin) for a heavier silhouette.
    if (v.weapon == Weapon.sword || v.hasShield) {
      final metal = Paint()..color = v.accent;
      canvas.drawCircle(const Offset(-19, -18), 7, metal);
      canvas.drawCircle(const Offset(19, -18), 7, metal);
      canvas.drawCircle(const Offset(-19, -18), 7,
          Paint()..color = _darken(v.accent, 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
    canvas.restore();
  }

  static void _drawCloak(Canvas canvas, HeroVisual v, double t) {
    final sway = sin(t * 1.5) * 3;
    final path = Path()
      ..moveTo(-14, -60)
      ..quadraticBezierTo(-26 + sway, -20, -16 + sway, 0)
      ..lineTo(14 + sway, 0)
      ..quadraticBezierTo(24 + sway, -22, 14, -60)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [v.cloak, _darken(v.cloak, 0.3)],
          ).createShader(const Rect.fromLTWH(-26, -60, 52, 60)));
  }

  static void _drawShield(Canvas canvas, HeroVisual v) {
    canvas.save();
    canvas.translate(-20, -42);
    final shield = Path()
      ..moveTo(0, -12)
      ..lineTo(11, -7)
      ..lineTo(9, 10)
      ..lineTo(0, 16)
      ..lineTo(-9, 10)
      ..lineTo(-11, -7)
      ..close();
    canvas.drawPath(shield, Paint()..color = v.secondary);
    canvas.drawPath(shield,
        Paint()..color = v.accent..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRect(const Rect.fromLTWH(-1.5, -8, 3, 18), Paint()..color = v.accent);
    canvas.drawRect(const Rect.fromLTWH(-7, -1, 14, 3), Paint()..color = v.accent);
    canvas.restore();
  }

  static void _drawBackArm(Canvas canvas, HeroVisual v, bool up) {
    canvas.save();
    canvas.translate(-15, -52);
    canvas.rotate(up ? -1.0 : 0.1);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 8, 22), const Radius.circular(4)),
        Paint()..color = _darken(v.primary, 0.08));
    canvas.drawCircle(const Offset(-1, 22), 3.5, Paint()..color = _skinShade);
    canvas.restore();
  }

  static void _drawFrontArmAndWeapon(
      Canvas canvas, HeroVisual v, double swing, bool up, double t) {
    canvas.save();
    canvas.translate(16, -52);
    canvas.rotate(swing + (up ? -1.0 : 0.0));
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 0, 8, 22), const Radius.circular(4)),
        Paint()..color = v.primaryLight);
    canvas.drawCircle(const Offset(1, 22), 3.5, Paint()..color = _skin);
    canvas.save();
    canvas.translate(1, 22);
    _drawWeapon(canvas, v, t);
    canvas.restore();
    canvas.restore();
  }

  static void _drawWeapon(Canvas canvas, HeroVisual v, double t) {
    switch (v.weapon) {
      case Weapon.sword:
        canvas.drawRect(const Rect.fromLTWH(-7, -2, 14, 4), Paint()..color = v.accent);
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-2.5, -40, 5, 40), const Radius.circular(2)),
            Paint()
              ..shader = const LinearGradient(colors: [Color(0xFFF2F6FA), Color(0xFFAFC0D0)])
                  .createShader(const Rect.fromLTWH(-2.5, -40, 5, 40)));
        canvas.drawCircle(const Offset(0, 2), 3, Paint()..color = _darken(v.accent, 0.2));
        break;
      case Weapon.hammer:
        canvas.drawRect(const Rect.fromLTWH(-2, -34, 4, 36), Paint()..color = const Color(0xFF5A3D24));
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -42, 22, 16), const Radius.circular(3)),
            Paint()..color = const Color(0xFF6B7077));
        canvas.drawRect(const Rect.fromLTWH(-11, -42, 4, 16), Paint()..color = const Color(0xFF4A4F55));
        break;
      case Weapon.mace:
        canvas.drawRect(const Rect.fromLTWH(-2, -30, 4, 32), Paint()..color = const Color(0xFF5A3D24));
        canvas.drawCircle(const Offset(0, -34), 8, Paint()..color = v.accent);
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3;
          canvas.drawCircle(Offset(cos(a) * 9, -34 + sin(a) * 9), 2.2, Paint()..color = v.accent);
        }
        break;
      case Weapon.staff:
        canvas.drawRect(const Rect.fromLTWH(-2, -44, 4, 46), Paint()..color = const Color(0xFF6E4A2A));
        final pulse = 0.7 + 0.3 * sin(t * 4);
        canvas.drawCircle(const Offset(0, -48), 9,
            Paint()..color = v.accent.withValues(alpha: 0.35 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(const Offset(0, -48), 5, Paint()..color = v.accent);
        canvas.drawCircle(const Offset(-1.5, -49.5), 2, Paint()..color = Colors.white);
        break;
      case Weapon.bow:
        final bow = Paint()
          ..color = const Color(0xFF6E4A2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(0, -26)
          ..quadraticBezierTo(16, 0, 0, 26);
        canvas.drawPath(path, bow);
        canvas.drawLine(const Offset(0, -26), const Offset(0, 26),
            Paint()..color = const Color(0xFFEAD7AE)..strokeWidth = 1);
        break;
    }
  }

  static void _drawHead(Canvas canvas, HeroVisual v, bool blinking) {
    canvas.save();
    canvas.translate(0, -66);

    // Face.
    canvas.drawCircle(const Offset(0, 1), 15, Paint()..color = _skinShade);
    canvas.drawCircle(Offset.zero, 14.5, Paint()..color = _skin);

    // Hair / headgear base.
    switch (v.head) {
      case Head.hood:
        final hood = Path()
          ..moveTo(-16, 2)
          ..quadraticBezierTo(-18, -20, 0, -19)
          ..quadraticBezierTo(18, -20, 16, 2)
          ..quadraticBezierTo(10, -6, 0, -6)
          ..quadraticBezierTo(-10, -6, -16, 2)
          ..close();
        canvas.drawPath(hood, Paint()..color = v.cloak);
        break;
      case Head.wizardHat:
        _drawHair(canvas, const Color(0xFFDDDDDD));
        final brim = Paint()..color = v.primary;
        canvas.drawOval(const Rect.fromLTWH(-20, -8, 40, 9), brim);
        final hat = Path()
          ..moveTo(-15, -5)
          ..quadraticBezierTo(2, -10, 6, -40)
          ..quadraticBezierTo(-2, -16, 15, -5)
          ..close();
        canvas.drawPath(hat, Paint()..color = v.primaryLight);
        canvas.drawCircle(const Offset(6, -40), 3, Paint()..color = v.accent);
        break;
      case Head.bandana:
        _drawHair(canvas, _hair);
        canvas.drawRect(const Rect.fromLTWH(-15, -8, 30, 7), Paint()..color = v.accent);
        break;
      case Head.halo:
        _drawHair(canvas, const Color(0xFFE7C96A));
        canvas.drawCircle(const Offset(0, -20), 12,
            Paint()
              ..color = v.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
        break;
      case Head.hair:
        _drawHair(canvas, _hair);
        break;
    }

    // Eyes.
    final eye = Paint()..color = const Color(0xFF2A2A2A);
    if (blinking) {
      final p = Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(-7, 3), const Offset(-3, 3), p);
      canvas.drawLine(const Offset(3, 3), const Offset(7, 3), p);
    } else {
      canvas.drawCircle(const Offset(-5, 3), 2, eye);
      canvas.drawCircle(const Offset(5, 3), 2, eye);
    }

    // Beard (mage/blacksmith).
    if (v.beard) {
      final beard = Path()
        ..moveTo(-9, 6)
        ..quadraticBezierTo(0, 26, 9, 6)
        ..quadraticBezierTo(0, 14, -9, 6)
        ..close();
      canvas.drawPath(beard, Paint()..color = v.head == Head.wizardHat ? const Color(0xFFE8E8E8) : const Color(0xFF6E4A2A));
    }
    canvas.restore();
  }

  static void _drawHair(Canvas canvas, Color color) {
    final hp = Path()
      ..moveTo(-15, 2)
      ..quadraticBezierTo(-16, -18, 0, -16)
      ..quadraticBezierTo(16, -18, 15, 2)
      ..quadraticBezierTo(8, -8, 0, -7)
      ..quadraticBezierTo(-8, -8, -15, 2)
      ..close();
    canvas.drawPath(hp, Paint()..color = color);
  }

  // ── Color helpers ───────────────────────────────────────────────────────
  static Color _darken(Color c, double a) {
    final f = 1 - a;
    return Color.fromARGB(
      (c.a * 255.0).round().clamp(0, 255).toInt(),
      (c.r * 255.0 * f).round().clamp(0, 255).toInt(),
      (c.g * 255.0 * f).round().clamp(0, 255).toInt(),
      (c.b * 255.0 * f).round().clamp(0, 255).toInt(),
    );
  }
}
