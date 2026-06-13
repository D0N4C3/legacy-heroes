import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_sized.dart';

/// The dynasty's **Legacy Tree** — the emotional centerpiece of the home scene
/// (Visual Plan: "the most important visual feature should be the dynasty").
///
/// It grows grander every generation: a slender sapling at Gen 1 swelling into
/// an ancient, glowing world-tree over a hundred generations. One warm
/// ancestor-spirit light drifts in its canopy for each forebear, so the player
/// literally watches their bloodline accumulate in the branches.
///
/// Drawn with its base at the local origin and the canopy reaching up into
/// negative Y, like the hero avatar — so a scene just positions it on the
/// ground line.
class LegacyTree extends PositionComponent with GameSized {
  LegacyTree({required this.generation, required this.ancestorCount}) {
    priority = 2;
  }

  int generation;
  int ancestorCount;
  double _t = 0;

  /// Maturity 0..1 — fast early growth, then a long slow march to grandeur.
  double get _growth {
    final g = generation.clamp(1, 300);
    return (1 - 1 / (1 + g / 22)).clamp(0.0, 1.0).toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final grow = _growth;
    final height = h * (0.22 + 0.34 * grow);
    final trunkW = 10 + 46 * grow;
    final canopyR = h * (0.10 + 0.20 * grow);
    final canopyCy = -height + canopyR * 0.4;
    final sway = sin(_t * 0.8) * 4;

    // Soft golden halo behind the canopy — brighter as the dynasty ages.
    canvas.drawCircle(
      Offset(0, canopyCy),
      canopyR * 1.35,
      Paint()
        ..color = const Color(0xFFFFE9A8).withValues(alpha: 0.10 + 0.14 * grow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 + 34 * grow),
    );

    // Roots flaring into the earth.
    final rootPaint = Paint()..color = const Color(0xFF3A2A1C);
    for (final dir in [-1.0, 1.0]) {
      final rp = Path()
        ..moveTo(-trunkW * 0.4, 0)
        ..quadraticBezierTo(
            dir * trunkW * 1.3, -3, dir * (trunkW * 1.7 + 18), 9)
        ..quadraticBezierTo(dir * trunkW * 1.1, -1, trunkW * 0.4, 0)
        ..close();
      canvas.drawPath(rp, rootPaint);
    }

    // Tapered trunk with a barky gradient.
    final trunk = Path()
      ..moveTo(-trunkW * 0.5, 0)
      ..quadraticBezierTo(
          -trunkW * 0.34, -height * 0.5, -trunkW * 0.18, -height * 0.82)
      ..lineTo(trunkW * 0.18, -height * 0.82)
      ..quadraticBezierTo(trunkW * 0.34, -height * 0.5, trunkW * 0.5, 0)
      ..close();
    canvas.drawPath(
      trunk,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF6B4A2E), Color(0xFF45301A)],
        ).createShader(Rect.fromLTWH(-trunkW, -height, trunkW * 2, height)),
    );

    // Branches reaching up into the foliage.
    final branch = Paint()
      ..color = const Color(0xFF54381F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + 6 * grow
      ..strokeCap = StrokeCap.round;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(0, -height * 0.72),
        Offset(dir * canopyR * 0.55, canopyCy + canopyR * 0.25),
        branch,
      );
    }

    // Layered foliage blobs.
    final leaves = <(Offset, double, Color)>[
      (Offset(sway, canopyCy), canopyR, const Color(0xFF2F6B3A)),
      (
        Offset(-canopyR * 0.5 + sway, canopyCy + canopyR * 0.2),
        canopyR * 0.7,
        const Color(0xFF367B42)
      ),
      (
        Offset(canopyR * 0.5 + sway, canopyCy + canopyR * 0.15),
        canopyR * 0.72,
        const Color(0xFF2A6035)
      ),
      (
        Offset(sway, canopyCy - canopyR * 0.5),
        canopyR * 0.7,
        const Color(0xFF3C8C4A)
      ),
    ];
    for (final (c, r, col) in leaves) {
      canvas.drawCircle(c, r, Paint()..color = col);
    }

    // Sun-dappled leaf speckle — denser on an older, fuller tree.
    final rng = Random(7);
    final hi = Paint()..color = const Color(0xFF6FBF66).withValues(alpha: 0.5);
    final speckles = (30 + 70 * grow).round();
    for (var i = 0; i < speckles; i++) {
      final a = rng.nextDouble() * pi * 2;
      final rr = rng.nextDouble() * canopyR;
      canvas.drawCircle(
        Offset(sway + cos(a) * rr, canopyCy + sin(a) * rr * 0.9),
        1.4 + rng.nextDouble() * 2,
        hi,
      );
    }

    // Ancestor spirits — one warm light per forebear, drifting and pulsing.
    final spirits = ancestorCount.clamp(0, 14);
    for (var i = 0; i < spirits; i++) {
      final a = (i / max(1, spirits)) * pi * 2 + _t * 0.3;
      final rr = canopyR * (0.45 + 0.4 * (((i * 37) % 100) / 100));
      final px = sway + cos(a) * rr;
      final py = canopyCy + sin(a) * rr * 0.85;
      final pulse = 0.5 + 0.5 * sin(_t * 2 + i);
      canvas.drawCircle(
        Offset(px, py),
        7,
        Paint()
          ..color = const Color(0xFFFFE9A8).withValues(alpha: 0.25 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
          Offset(px, py), 2.6, Paint()..color = const Color(0xFFFFF6D8));
    }

    // Once a dynasty is established, hang the family banner from the trunk.
    if (generation >= 2) {
      final by = -height * 0.46;
      const bw = 22.0, bh = 30.0;
      final bx = trunkW * 0.5 + 2;
      final banner = Path()
        ..moveTo(bx, by)
        ..lineTo(bx + bw, by)
        ..lineTo(bx + bw, by + bh)
        ..lineTo(bx + bw / 2, by + bh - 8)
        ..lineTo(bx, by + bh)
        ..close();
      canvas.drawPath(banner, Paint()..color = const Color(0xFFC4452F));
      canvas.drawCircle(Offset(bx + bw / 2, by + bh * 0.4), 4,
          Paint()..color = const Color(0xFFE7B53C));
    }
  }
}
