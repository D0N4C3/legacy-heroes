import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/palette.dart';
import 'components/fx.dart';
import 'components/hero_avatar.dart';
import 'scene_type.dart';
import 'scenes/boss_scene.dart';
import 'scenes/dungeon_scene.dart';
import 'scenes/game_scene.dart';
import 'scenes/legacy_scene.dart';
import 'scenes/training_scene.dart';
import 'scenes/village_scene.dart';

/// The living fantasy world (Visual Plan §3, §9). Flame owns the animated
/// scene; Flutter overlays sit on top via the [GameWidget] overlay map.
///
/// State flows one way: the Flutter layer watches Riverpod and calls [sync] to
/// tell the world which scene to show and how the hero looks. Reward "juice"
/// (gold bursts, damage numbers, legacy transition) is triggered by method
/// calls from the overlays.
class LegacyGame extends FlameGame {
  SceneType _type = SceneType.village;
  Color _heroColor = Palette.gold;
  HeroAnim _anim = HeroAnim.idle;
  GameScene? _scene;
  bool _ready = false;

  @override
  Color backgroundColor() => const Color(0xFF120A1E);

  @override
  Future<void> onLoad() async {
    _scene = _buildScene(_type);
    await add(_scene!);
    _ready = true;
  }

  /// Push the latest desired visual state from the Flutter/Riverpod layer.
  void sync({
    required SceneType scene,
    required Color heroColor,
    required HeroAnim anim,
  }) {
    _heroColor = heroColor;
    _anim = anim;
    if (!_ready) return;
    if (scene != _type || _scene == null) {
      _type = scene;
      _swapScene();
    } else {
      _scene!.applyHero(heroColor, anim);
    }
  }

  void _swapScene() {
    _scene?.removeFromParent();
    final s = _buildScene(_type);
    _scene = s;
    add(s);
  }

  GameScene _buildScene(SceneType type) {
    switch (type) {
      case SceneType.village:
        return VillageScene(heroColor: _heroColor, heroAnim: _anim);
      case SceneType.training:
        return TrainingScene(heroColor: _heroColor, heroAnim: _anim);
      case SceneType.dungeon:
        return DungeonScene(heroColor: _heroColor, heroAnim: _anim);
      case SceneType.boss:
        return BossScene(heroColor: _heroColor, heroAnim: _anim);
      case SceneType.legacy:
        return LegacyScene(heroColor: _heroColor, heroAnim: _anim);
    }
  }

  // ── Signature FX hooks (Visual Plan §9 LegacyGame API) ───────────────────
  void showGoldBurst() {
    if (!_ready) return;
    add(GoldBurst(position: size / 2));
  }

  void showDamageNumber(int amount, {Color? color}) {
    if (!_ready) return;
    add(DamageNumber(
      position: Vector2(size.x * 0.55, size.y * 0.5),
      text: '$amount',
      color: color ?? const Color(0xFFFFE08A),
    ));
  }

  void playLegacyTransition() => sync(
        scene: SceneType.legacy,
        heroColor: _heroColor,
        anim: HeroAnim.idle,
      );
}
