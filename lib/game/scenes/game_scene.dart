import 'package:flame/components.dart';

import '../components/game_sized.dart';
import '../components/hero_avatar.dart';

/// Base class for every Flame scene (Visual Plan §4 "Scene System").
///
/// A scene owns a slice of the world's set dressing and (optionally) the live
/// hero avatar. [LegacyGame] swaps scenes in and out as the player's activity
/// changes, and pushes hero appearance updates through [applyHero].
abstract class GameScene extends Component with GameSized {
  GameScene({required this.heroClassId, required this.heroAnim});

  String heroClassId;
  HeroAnim heroAnim;
  HeroAvatar? heroAvatar;

  /// Build the scene's components (background, props, particles, hero/enemy).
  void build();

  /// (Re)position size-dependent children. Called on load and on resize.
  void layout(Vector2 size);

  @override
  Future<void> onLoad() async {
    build();
    if (w > 0) layout(gameSize);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded && size.x > 0) layout(size);
  }

  /// Update the live hero's class / animation without rebuilding.
  void applyHero(String classId, HeroAnim anim) {
    heroClassId = classId;
    heroAnim = anim;
    final h = heroAvatar;
    if (h != null) {
      h.classId = classId;
      h.anim = anim;
    }
  }
}
