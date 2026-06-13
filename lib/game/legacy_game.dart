import 'dart:math';

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
  int _generation = 1;
  GameScene? _scene;
  bool _ready = false;

  // ── Screen shake (combat juice) ──────────────────────────────────────────
  double _shake = 0;
  final Random _rng = Random();

  /// Kick a brief camera shake of [amount] pixels. Scenes call this on impacts.
  void shake([double amount = 6]) {
    if (amount > _shake) _shake = amount;
  }

  @override
  Color backgroundColor() => const Color(0xFF120A1E);

  @override
  Future<void> onLoad() async {
    _scene = _buildScene(_type);
    await add(_scene!);
    _ready = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shake > 0) _shake = (_shake - dt * 45).clamp(0, 100);
  }

  @override
  void render(Canvas canvas) {
    if (_shake > 0.1) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * _shake * 2,
        (_rng.nextDouble() - 0.5) * _shake * 2,
      );
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  /// Push the latest desired visual state from the Flutter/Riverpod layer.
  void sync({
    required SceneType scene,
    required String classId,
    required HeroAnim anim,
    int generation = 1,
  }) {
    _heroClassId = classId;
    _anim = anim;
    final genChanged = generation != _generation;
    _generation = generation;
    if (!_ready) return;
    if (scene != _type || _scene == null || (genChanged && scene == SceneType.village)) {
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
    final scene = switch (type) {
      SceneType.village => VillageScene(
          heroClassId: _heroClassId, heroAnim: _anim, generation: _generation),
      SceneType.training =>
        TrainingScene(heroClassId: _heroClassId, heroAnim: _anim),
      SceneType.dungeon =>
        DungeonScene(heroClassId: _heroClassId, heroAnim: _anim),
      SceneType.boss => BossScene(heroClassId: _heroClassId, heroAnim: _anim),
      SceneType.legacy =>
        LegacyScene(heroClassId: _heroClassId, heroAnim: _anim),
    };
    scene.onShake = shake;
    return scene;
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
