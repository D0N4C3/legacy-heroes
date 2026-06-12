import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/utils/rng.dart';
import '../components/enemy_silhouette.dart';
import '../components/hero_avatar.dart';
import '../components/particle_field.dart';
import '../components/prop_component.dart';
import '../components/sky_background.dart';
import 'game_scene.dart';

/// Dark cave / ruins with torchlight and a lurking enemy
/// (Visual Plan §4 Dungeon Scene). The enemy varies each visit.
class DungeonScene extends GameScene {
  DungeonScene({required super.heroClassId, required super.heroAnim});

  @override
  void build() {
    add(SkyBackground(
      topColor: const Color(0xFF120A1E),
      midColor: const Color(0xFF241634),
      horizonColor: const Color(0xFF3A2450),
      groundColor: const Color(0xFF241A2E),
      hillColor: const Color(0xFF1A1026),
      stars: true,
      priority: 0,
    ));
    add(PropComponent(_drawCave, priority: 2));
    add(EnemyComponent(
      position: Vector2.zero(),
      type: pick([EnemyType.goblin, EnemyType.wolf, EnemyType.skeleton]),
    ));
    add(ParticleField(mode: ParticleMode.sparks, color: const Color(0xFFFFC65A), count: 16, priority: 11));
    add(ParticleField(mode: ParticleMode.embers, color: const Color(0xFFFF7B3B), count: 14, priority: 12));

    heroAvatar = HeroAvatar(
        position: Vector2.zero(), classId: heroClassId, anim: HeroAnim.attack);
    add(heroAvatar!);
  }

  @override
  void layout(Vector2 size) {
    final groundY = size.y * 0.80;
    heroAvatar?.position = Vector2(size.x * 0.34, groundY);
    children.whereType<EnemyComponent>().forEach((e) {
      e.position = Vector2(size.x * 0.68, groundY);
    });
  }

  void _drawCave(Canvas canvas, Vector2 size) {
    // Cave mouth vignette.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x00000000), const Color(0xCC000000)],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(size.x * 0.5, size.y * 0.5), radius: size.x * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), vignette);

    // Two torches.
    void torch(double x) {
      final groundY = size.y * 0.80;
      canvas.drawRect(Rect.fromLTWH(x - 2, groundY - 80, 4, 50),
          Paint()..color = const Color(0xFF3A2615));
      final glow = Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFB347).withOpacity(0.6),
          const Color(0x00FFB347),
        ]).createShader(Rect.fromCircle(center: Offset(x, groundY - 84), radius: 36));
      canvas.drawCircle(Offset(x, groundY - 84), 36, glow);
      canvas.drawCircle(Offset(x, groundY - 84), 6, Paint()..color = const Color(0xFFFFD27A));
    }

    torch(size.x * 0.14);
    torch(size.x * 0.86);
  }
}
