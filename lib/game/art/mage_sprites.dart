import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import 'hero_art.dart' show HeroAnim;

/// Loads the hand-drawn pixel-art Mage sprite sheets (idle / walk / fireball
/// cast) and slices them into [SpriteAnimation]s keyed by [HeroAnim].
///
/// Frame layout (from the supplied metadata): each frame is 256×256 with a 1px
/// margin, so frames sit at x = 1 + i·257, y = 1. Idle has 4 frames; walk and
/// the fireball cast have 6 each. All frames run at ~100ms (we nudge per-anim).
class MageSprites {
  MageSprites._();

  static const String idlePath = 'heroes/mage_idle.png';
  static const String walkPath = 'heroes/mage_walk.png';
  static const String attackPath = 'heroes/mage_attack.png';

  /// Content sits at x≈[73..178], feet ≈ y190 inside each 256px frame, so this
  /// anchor drops the character's feet exactly on a host component's origin.
  static const Anchor footAnchor = Anchor(0.477, 0.742);

  static const double _frame = 256;
  static const double _stride = 257; // 256 + 1px margin

  static SpriteAnimation _strip(Image img, int count, double step) {
    final frames = <SpriteAnimationFrame>[
      for (var i = 0; i < count; i++)
        SpriteAnimationFrame(
          Sprite(img,
              srcPosition: Vector2(1 + i * _stride, 1),
              srcSize: Vector2(_frame, _frame)),
          step,
        ),
    ];
    return SpriteAnimation(frames);
  }

  /// Load all three sheets and map every [HeroAnim] to a sensible clip.
  static Future<Map<HeroAnim, SpriteAnimation>> load(Images images) async {
    final idle = await images.load(idlePath);
    final walk = await images.load(walkPath);
    final attack = await images.load(attackPath);

    final idleA = _strip(idle, 4, 0.14);
    final walkA = _strip(walk, 6, 0.10);
    final attackA = _strip(attack, 6, 0.09);

    return {
      HeroAnim.idle: idleA,
      HeroAnim.walk: walkA,
      HeroAnim.attack: attackA,
      HeroAnim.train: attackA, // training reads as repeated casting
      HeroAnim.victory: idleA,
      HeroAnim.hurt: idleA,
    };
  }
}
