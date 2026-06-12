import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../components/particle_field.dart';
import '../components/prop_component.dart';
import '../components/sky_background.dart';
import 'game_scene.dart';

/// The ceremonial generation-transition backdrop — a glowing ancestral tree
/// bathed in golden light (Visual Plan §4 Legacy Scene). The heir cards and
/// "Continue the Legacy" UI are drawn as a Flutter overlay on top of this.
class LegacyScene extends GameScene {
  LegacyScene({required super.heroColor, required super.heroAnim});

  @override
  void build() {
    add(SkyBackground(
      topColor: const Color(0xFF2A1E12),
      midColor: const Color(0xFF5A3E1E),
      horizonColor: const Color(0xFFB07E1E),
      groundColor: const Color(0xFF3A2A18),
      hillColor: const Color(0xFF4A341C),
      priority: 0,
    ));
    add(PropComponent(_drawTree, priority: 2));
    add(PropComponent(_drawLightShaft, priority: 3));
    add(ParticleField(mode: ParticleMode.fireflies, color: Palette.goldLight, count: 36, priority: 11));
    add(ParticleField(mode: ParticleMode.embers, color: const Color(0xFFFFD27A), count: 16, priority: 12));
  }

  @override
  void layout(Vector2 size) {}

  void _drawTree(Canvas canvas, Vector2 size) {
    final baseX = size.x * 0.5;
    final groundY = size.y * 0.84;
    final trunk = Paint()..color = const Color(0xFF3A2615);

    // Trunk.
    final trunkPath = Path()
      ..moveTo(baseX - 22, groundY)
      ..quadraticBezierTo(baseX - 14, groundY - 120, baseX - 8, groundY - 170)
      ..lineTo(baseX + 8, groundY - 170)
      ..quadraticBezierTo(baseX + 14, groundY - 120, baseX + 22, groundY)
      ..close();
    canvas.drawPath(trunkPath, trunk);

    // Branches.
    final branch = Paint()
      ..color = const Color(0xFF3A2615)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(Offset(baseX, groundY - 150),
          Offset(baseX + 70 * s, groundY - 210), branch);
      canvas.drawLine(Offset(baseX, groundY - 120),
          Offset(baseX + 100 * s, groundY - 150), branch);
    }

    // Glowing canopy.
    final canopy = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF6FA05A).withOpacity(0.9),
        const Color(0xFF3A5A2A).withOpacity(0.6),
      ]).createShader(Rect.fromCircle(
          center: Offset(baseX, groundY - 220), radius: size.x * 0.4));
    canvas.drawCircle(Offset(baseX, groundY - 220), size.x * 0.34, canopy);
  }

  void _drawLightShaft(Canvas canvas, Vector2 size) {
    final cx = size.x * 0.5;
    final shaft = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.goldLight.withOpacity(0.28), Palette.goldLight.withOpacity(0)],
      ).createShader(Rect.fromLTWH(cx - 80, 0, 160, size.y));
    final path = Path()
      ..moveTo(cx - 40, 0)
      ..lineTo(cx + 40, 0)
      ..lineTo(cx + 90, size.y)
      ..lineTo(cx - 90, size.y)
      ..close();
    canvas.drawPath(path, shaft);
  }
}
