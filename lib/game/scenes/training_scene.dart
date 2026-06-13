import 'dart:ui';

import 'package:flame/components.dart';

import '../components/hero_avatar.dart';
import '../components/particle_field.dart';
import '../components/prop_component.dart';
import '../components/sky_background.dart';
import 'game_scene.dart';

/// Daytime training yard — hero swings at a dummy, dust kicks up
/// (Visual Plan §4 Training Scene).
class TrainingScene extends GameScene {
  TrainingScene({required super.heroClassId, required super.heroAnim});

  @override
  void build() {
    add(SkyBackground(
      topColor: const Color(0xFF5FA8D6),
      midColor: const Color(0xFF9FD0E6),
      horizonColor: const Color(0xFFE7D89A),
      groundColor: const Color(0xFF7A8B3A),
      hillColor: const Color(0xFF6FA05A),
      groundLevel: 0.62,
      priority: 0,
    ));
    add(PropComponent(_drawDummy, priority: 3));
    add(ParticleField(mode: ParticleMode.dust, color: const Color(0x88E9D9A0), count: 18, priority: 11));

    heroAvatar = HeroAvatar(
        position: Vector2.zero(), classId: heroClassId, anim: HeroAnim.train);
    add(heroAvatar!);
  }

  @override
  void layout(Vector2 size) {
    final groundY = size.y * 0.62;
    heroAvatar?.position = Vector2(size.x * 0.42, groundY);
  }

  void _drawDummy(Canvas canvas, Vector2 size) {
    final groundY = size.y * 0.62;
    final x = size.x * 0.62;
    final post = Paint()..color = const Color(0xFF6E4A2A);
    canvas.drawRect(Rect.fromLTWH(x - 4, groundY - 70, 8, 70), post);
    canvas.drawRect(Rect.fromLTWH(x - 30, groundY - 56, 60, 8), post);
    // Straw body.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, groundY - 40), width: 34, height: 46),
      Paint()..color = const Color(0xFFCBA24A),
    );
    canvas.drawCircle(Offset(x, groundY - 66), 12, Paint()..color = const Color(0xFFB98E3C));
    // Target mark.
    canvas.drawCircle(Offset(x, groundY - 40), 8, Paint()..color = const Color(0xFFB23A3A));
    canvas.drawCircle(Offset(x, groundY - 40), 4, Paint()..color = const Color(0xFFEAD7AE));
  }
}
