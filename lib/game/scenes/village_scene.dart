import 'dart:ui';

import 'package:flame/components.dart';

import '../../app/palette.dart';
import '../components/campfire.dart';
import '../components/hero_avatar.dart';
import '../components/particle_field.dart';
import '../components/prop_component.dart';
import '../components/sky_background.dart';
import 'game_scene.dart';

/// The cozy home base at twilight — hero by the campfire, family banner behind
/// (Visual Plan §4 Village Scene). The most polished, "living world" screen.
class VillageScene extends GameScene {
  VillageScene({required super.heroClassId, required super.heroAnim});

  late final Campfire _fire;

  @override
  void build() {
    add(SkyBackground(
      topColor: Palette.skyTop,
      midColor: Palette.skyMid,
      horizonColor: Palette.skyHorizon,
      groundColor: const Color(0xFF4A6B3A),
      hillColor: const Color(0xFF5A3D6E),
      priority: 0,
    ));

    // Home + family banner behind the hero.
    add(PropComponent(_drawHome, priority: 3));

    // Drifting dust far back, fireflies + embers up front.
    add(ParticleField(mode: ParticleMode.dust, color: const Color(0x66FFFFFF), count: 14, priority: 2));
    add(ParticleField(mode: ParticleMode.fireflies, color: const Color(0xFFFFE9A0), count: 22, priority: 12));

    _fire = Campfire(position: Vector2.zero());
    add(_fire);

    heroAvatar = HeroAvatar(position: Vector2.zero(), classId: heroClassId, anim: heroAnim);
    add(heroAvatar!);
  }

  @override
  void layout(Vector2 size) {
    final groundY = size.y * 0.80;
    heroAvatar?.position = Vector2(size.x * 0.42, groundY);
    _fire.position = Vector2(size.x * 0.66, groundY - 4);
  }

  void _drawHome(Canvas canvas, Vector2 size) {
    final baseY = size.y * 0.80;
    final hx = size.x * 0.30;

    // Cottage body.
    final wall = Paint()..color = const Color(0xFF8A6A45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(hx - 70, baseY - 90, 120, 90), const Radius.circular(6)),
      wall,
    );
    // Roof.
    final roof = Paint()..color = const Color(0xFF6E3F2E);
    final roofPath = Path()
      ..moveTo(hx - 82, baseY - 86)
      ..lineTo(hx - 10, baseY - 130)
      ..lineTo(hx + 62, baseY - 86)
      ..close();
    canvas.drawPath(roofPath, roof);
    // Window glow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(hx - 50, baseY - 62, 26, 26), const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFC65A),
    );
    // Door.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(hx + 6, baseY - 50, 24, 50), const Radius.circular(3)),
      Paint()..color = const Color(0xFF4A2E18),
    );

    // Family banner on a pole.
    final poleX = hx + 70;
    canvas.drawRect(Rect.fromLTWH(poleX, baseY - 120, 4, 120),
        Paint()..color = const Color(0xFF3A2615));
    final bannerPath = Path()
      ..moveTo(poleX + 4, baseY - 118)
      ..lineTo(poleX + 44, baseY - 118)
      ..lineTo(poleX + 44, baseY - 74)
      ..lineTo(poleX + 24, baseY - 84)
      ..lineTo(poleX + 4, baseY - 74)
      ..close();
    canvas.drawPath(bannerPath, Paint()..color = Palette.gold);
    canvas.drawPath(
        bannerPath,
        Paint()
          ..color = Palette.goldDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}
