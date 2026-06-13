import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../features/combat/domain/combat_state.dart';
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
  String _heroClassId = 'warrior';
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
    required String classId,
    required HeroAnim anim,
  }) {
    _heroClassId = classId;
    _anim = anim;
    if (!_ready) return;
    if (scene != _type || _scene == null) {
      _type = scene;
      _swapScene();
    } else {
      _scene!.applyHero(classId, anim);
    }
  }

  /// Push the combat mini-game's latest live state (Phase 2) onto the active
  /// scene's hero/enemy. Mirrors [sync]'s one-way data flow.
  void syncCombat(CombatState combat) {
    if (!_ready) return;
    _scene?.applyCombat(combat);
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
        return VillageScene(heroClassId: _heroClassId, heroAnim: _anim);
      case SceneType.training:
        return TrainingScene(heroClassId: _heroClassId, heroAnim: _anim);
      case SceneType.dungeon:
        return DungeonScene(heroClassId: _heroClassId, heroAnim: _anim);
      case SceneType.boss:
        return BossScene(heroClassId: _heroClassId, heroAnim: _anim);
      case SceneType.legacy:
        return LegacyScene(heroClassId: _heroClassId, heroAnim: _anim);
    }
  }

  // ── Signature FX hooks (Visual Plan §9 LegacyGame API) ───────────────────
  void showGoldBurst({Vector2? position}) {
    if (!_ready) return;
    add(GoldBurst(position: position ?? size / 2));
  }

  void showDamageNumber(int amount, {Vector2? position, Color? color}) {
    if (!_ready) return;
    add(DamageNumber(
      position: position ?? Vector2(size.x * 0.55, size.y * 0.5),
      text: '$amount',
      color: color ?? const Color(0xFFFFE08A),
    ));
  }

  void playLegacyTransition() => sync(
        scene: SceneType.legacy,
        classId: _heroClassId,
        anim: HeroAnim.idle,
      );
}
