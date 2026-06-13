import 'dart:ui';

import 'package:flame/components.dart';

import '../../app/palette.dart';
import '../components/campfire.dart';
import '../components/hero_avatar.dart';
import '../components/legacy_tree.dart';
import '../components/particle_field.dart';
import '../components/prop_component.dart';
import '../components/sky_background.dart';
import 'game_scene.dart';

/// The dynasty's home at twilight, built around the great **Legacy Tree** that
/// grows with every generation (Visual Plan: "the most important visual feature
/// should be the dynasty"). The family dwelling evolves from a humble hut into
/// a castle as the bloodline endures, so the player sees their progress in the
/// world itself — no menus required.
class VillageScene extends GameScene {
  VillageScene({
    required super.heroClassId,
    required super.heroAnim,
    this.generation = 1,
  });

  final int generation;

  late final Campfire _fire;
  late final LegacyTree _tree;

  @override
  void build() {
    add(SkyBackground(
      topColor: Palette.skyTop,
      midColor: Palette.skyMid,
      horizonColor: Palette.skyHorizon,
      groundColor: const Color(0xFF42632F),
      hillColor: const Color(0xFF5A3D6E),
      groundLevel: 0.68,
      priority: 0,
    ));

    // The great tree sits behind the hero as the scene's anchor.
    _tree = LegacyTree(
        generation: generation, ancestorCount: (generation - 1).clamp(0, 99));
    add(_tree);

    // The evolving family dwelling.
    add(PropComponent((c, s) => _drawDwelling(c, s, generation), priority: 3));

    // Atmosphere: far dust, drifting leaves from the canopy, fireflies & embers.
    add(ParticleField(mode: ParticleMode.dust, color: const Color(0x55FFFFFF), count: 12, priority: 1));
    add(ParticleField(mode: ParticleMode.leaves, color: const Color(0xCF6FBF66), count: 12, priority: 4));
    add(ParticleField(mode: ParticleMode.fireflies, color: const Color(0xFFFFE9A0), count: 22, priority: 12));
    add(ParticleField(mode: ParticleMode.embers, color: const Color(0xFFFFB066), count: 8, priority: 12));

    _fire = Campfire(position: Vector2.zero());
    add(_fire);

    heroAvatar = HeroAvatar(position: Vector2.zero(), classId: heroClassId, anim: heroAnim);
    add(heroAvatar!);
  }

  @override
  void layout(Vector2 size) {
    final groundY = size.y * 0.68;
    _tree.position = Vector2(size.x * 0.52, groundY);
    heroAvatar?.position = Vector2(size.x * 0.40, groundY);
    _fire.position = Vector2(size.x * 0.62, groundY - 2);
  }

  /// Draws the family home at a tier set by [generation]:
  /// hut → cottage → manor → castle. Always to the left, on the ground line.
  void _drawDwelling(Canvas canvas, Vector2 size, int gen) {
    final baseY = size.y * 0.68;
    final hx = size.x * 0.16;
    final tier = gen < 5 ? 0 : (gen < 20 ? 1 : (gen < 60 ? 2 : 3));

    final wall = Paint()..color = const Color(0xFF8A6A45);
    final wallDark = Paint()..color = const Color(0xFF6E5236);
    final roof = Paint()..color = const Color(0xFF6E3F2E);
    final stone = Paint()..color = const Color(0xFF8C8378);
    final stoneDark = Paint()..color = const Color(0xFF6C6359);
    final glow = Paint()..color = const Color(0xFFFFC65A);
    final door = Paint()..color = const Color(0xFF4A2E18);

    void window(double x, double y, [double s = 1]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, 22 * s, 22 * s), const Radius.circular(3)),
          glow);
    }

    switch (tier) {
      case 0: // Humble hut.
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx - 46, baseY - 64, 92, 64), const Radius.circular(5)),
            wall);
        canvas.drawPath(
            Path()
              ..moveTo(hx - 56, baseY - 60)
              ..lineTo(hx, baseY - 96)
              ..lineTo(hx + 56, baseY - 60)
              ..close(),
            roof);
        window(hx - 34, baseY - 44, 0.8);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx + 6, baseY - 38, 22, 38), const Radius.circular(3)),
            door);
        break;
      case 1: // Cottage with a chimney.
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx - 64, baseY - 84, 128, 84), const Radius.circular(6)),
            wall);
        canvas.drawRect(Rect.fromLTWH(hx + 34, baseY - 116, 14, 36), wallDark);
        canvas.drawPath(
            Path()
              ..moveTo(hx - 78, baseY - 80)
              ..lineTo(hx - 6, baseY - 126)
              ..lineTo(hx + 66, baseY - 80)
              ..close(),
            roof);
        window(hx - 46, baseY - 58);
        window(hx + 8, baseY - 58);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx - 18, baseY - 48, 26, 48), const Radius.circular(3)),
            door);
        break;
      case 2: // Two-storey manor.
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx - 74, baseY - 132, 150, 132), const Radius.circular(6)),
            wall);
        canvas.drawPath(
            Path()
              ..moveTo(hx - 88, baseY - 128)
              ..lineTo(hx + 1, baseY - 178)
              ..lineTo(hx + 90, baseY - 128)
              ..close(),
            roof);
        window(hx - 52, baseY - 110);
        window(hx + 26, baseY - 110);
        window(hx - 52, baseY - 64);
        window(hx + 26, baseY - 64);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx - 14, baseY - 56, 30, 56), const Radius.circular(4)),
            door);
        break;
      default: // Castle keep with flanking towers.
        // Towers.
        for (final tx in [hx - 96.0, hx + 84.0]) {
          canvas.drawRect(Rect.fromLTWH(tx, baseY - 188, 40, 188), stone);
          // Battlements.
          for (var i = 0; i < 3; i++) {
            canvas.drawRect(Rect.fromLTWH(tx + i * 14.0, baseY - 200, 10, 14), stoneDark);
          }
          window(tx + 9, baseY - 150, 0.9);
        }
        // Central keep.
        canvas.drawRect(Rect.fromLTWH(hx - 60, baseY - 150, 124, 150), stone);
        for (var i = 0; i < 5; i++) {
          canvas.drawRect(Rect.fromLTWH(hx - 60 + i * 26.0, baseY - 162, 16, 14), stoneDark);
        }
        window(hx - 40, baseY - 120);
        window(hx + 18, baseY - 120);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(hx - 16, baseY - 60, 34, 60), const Radius.circular(4)),
            door);
        // A proud banner over the gate.
        canvas.drawRect(Rect.fromLTWH(hx - 2, baseY - 92, 6, 30), Paint()..color = Palette.gold);
        break;
    }
  }
}
