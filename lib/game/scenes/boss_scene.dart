import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/enemy_silhouette.dart';
import '../components/hero_avatar.dart';
import '../components/particle_field.dart';
import '../components/prop_component.dart';
import '../components/sky_background.dart';
import 'game_scene.dart';

/// A dramatic boss encounter at the Demon Gate — a towering enemy, heavy
/// lighting, embers everywhere (Visual Plan §4 Boss Scene).
class BossScene extends GameScene {
  BossScene({required super.heroClassId, required super.heroAnim});

  @override
  double get combatBaseX => 0.28;

  @override
  double get combatEngageX => 0.46;

  @override
  void build() {
    add(SkyBackground(
      topColor: const Color(0xFF1A0608),
      midColor: const Color(0xFF3A0E12),
      horizonColor: const Color(0xFF7A1E16),
      groundColor: const Color(0xFF2A1012),
      hillColor: const Color(0xFF120406),
      groundLevel: 0.64,
      priority: 0,
    ));
    add(PropComponent(_drawGate, priority: 2));
    add(EnemyComponent(
        position: Vector2.zero(), type: EnemyType.demon, boss: true));
    add(ParticleField(mode: ParticleMode.embers, color: const Color(0xFFFF5A2B), count: 30, priority: 11));
    add(ParticleField(mode: ParticleMode.sparks, color: const Color(0xFFFFD27A), count: 18, priority: 12));

    heroAvatar = HeroAvatar(
        position: Vector2.zero(), classId: heroClassId, anim: HeroAnim.attack, scale: 0.95);
    add(heroAvatar!);
  }

  @override
  void layout(Vector2 size) {
    final groundY = size.y * 0.64;
    heroAvatar?.position = Vector2(size.x * 0.28, groundY);
    children.whereType<EnemyComponent>().forEach((e) {
      e.position = Vector2(size.x * 0.70, groundY);
    });
  }

  void _drawGate(Canvas canvas, Vector2 size) {
    final cx = size.x * 0.70;
    final groundY = size.y * 0.64;
    // Ominous archway behind the boss.
    final arch = Paint()..color = const Color(0xFF0A0204);
    final path = Path()
      ..moveTo(cx - 90, groundY)
      ..lineTo(cx - 90, groundY - 150)
      ..quadraticBezierTo(cx, groundY - 230, cx + 90, groundY - 150)
      ..lineTo(cx + 90, groundY)
      ..close();
    canvas.drawPath(path, arch);
    // Hellish inner glow.
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFF3A1A).withValues(alpha: 0.5),
        const Color(0x00FF3A1A),
      ]).createShader(Rect.fromCircle(center: Offset(cx, groundY - 110), radius: 110));
    canvas.drawPath(path, glow);
  }
}
