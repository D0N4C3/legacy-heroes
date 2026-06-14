import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

/// Animation clips available for the goblin enemy sprite sheets.
enum GoblinAnim { running, attack, dying }

/// Loads the hand-drawn pixel-art Goblin sprite sheets (run / sword attack /
/// death) and slices them into [SpriteAnimation]s keyed by [GoblinAnim].
///
/// Frame layout (matches [MageSprites]): each frame is 256×256 with a 1px
/// margin, so frames sit at x = 1 + i·257, y = 1. Running has 8 frames; the
/// sword attack and the death animation each have 9.
class GoblinSprites {
  GoblinSprites._();

  static const String runningPath = 'heroes/goblin-running-sprite-sheet.webp';
  static const String attackPath = 'heroes/goblin-attack-sprite-sheet.webp';
  static const String dyingPath = 'heroes/goblin-dying-sprite-sheet.webp';

  /// Content sits roughly centered with feet ≈ y182 inside each 256px frame.
  /// Source art already faces left, toward the hero — no flip needed.
  static const Anchor footAnchor = Anchor(0.49, 0.71);

  /// Total runtime of the death clip, matched to [EnemyComponent]'s defeat
  /// fade-out window so the collapse and the fade finish together.
  static const double defeatDuration = 0.4;

  static const double _frame = 256;
  static const double _stride = 257; // 256 + 1px margin

  static SpriteAnimation _strip(
    Image img,
    int count,
    double step, {
    bool loop = true,
  }) {
    final frames = <SpriteAnimationFrame>[
      for (var i = 0; i < count; i++)
        SpriteAnimationFrame(
          Sprite(
            img,
            srcPosition: Vector2(1 + i * _stride, 1),
            srcSize: Vector2(_frame, _frame),
          ),
          step,
        ),
    ];
    return SpriteAnimation(frames, loop: loop);
  }

  /// Load all three sheets and map every [GoblinAnim] to its clip.
  static Future<Map<GoblinAnim, SpriteAnimation>> load(Images images) async {
    final running = await images.load(runningPath);
    final attack = await images.load(attackPath);
    final dying = await images.load(dyingPath);

    return {
      GoblinAnim.running: _strip(running, 8, 0.09),
      GoblinAnim.attack: _strip(attack, 9, 0.07, loop: false),
      GoblinAnim.dying: _strip(dying, 9, defeatDuration / 9, loop: false),
    };
  }
}
