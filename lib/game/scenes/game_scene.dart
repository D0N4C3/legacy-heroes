import 'package:flame/components.dart';

import '../../app/palette.dart';
import '../../features/combat/domain/combat_enemy.dart';
import '../../features/combat/domain/combat_state.dart';
import '../components/enemy_silhouette.dart';
import '../components/fx.dart';
import '../components/game_sized.dart';
import '../components/hero_avatar.dart';

/// Base class for every Flame scene (Visual Plan §4 "Scene System").
///
/// A scene owns a slice of the world's set dressing and (optionally) the live
/// hero avatar. [LegacyGame] swaps scenes in and out as the player's activity
/// changes, and pushes hero appearance updates through [applyHero] and the
/// Phase 2 combat mini-game's live state through [applyCombat].
abstract class GameScene extends Component with GameSized {
  GameScene({required this.heroClassId, required this.heroAnim});

  String heroClassId;
  HeroAnim heroAnim;
  HeroAvatar? heroAvatar;

  /// Fractional X (of screen width) the hero stands at while approaching a
  /// foe in the combat mini-game. Dungeon/boss scenes may override this to
  /// match their hero's resting position.
  double get combatBaseX => 0.34;

  /// Fractional X (of screen width) the hero advances to once engaged with
  /// the current foe.
  double get combatEngageX => 0.50;

  CombatEnemy? _lastEnemy;
  int _lastHitTick = 0;
  int _lastEnemyHitTick = 0;

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

  /// Push the Phase 2 combat mini-game's live state onto this scene's hero
  /// and enemy. No-op outside dungeon/boss scenes (no [EnemyComponent]
  /// present), so this can be called unconditionally from [LegacyGame].
  void applyCombat(CombatState combat) {
    final hero = heroAvatar;
    final enemies = children.whereType<EnemyComponent>();
    if (hero == null || enemies.isEmpty || w <= 0) return;
    final enemy = enemies.first;

    if (!combat.active) {
      hero.maxHealth = 0;
      enemy.maxHealth = 0;
      hero.targetX = w * combatBaseX;
      _lastEnemy = null;
      _lastHitTick = 0;
      _lastEnemyHitTick = 0;
      return;
    }

    hero.health = combat.heroHealth;
    hero.maxHealth = combat.heroMaxHealth;

    final current = combat.current;
    if (!identical(current, _lastEnemy)) {
      if (current != null) {
        enemy.spawn(current.type, current.health, current.maxHealth);
      }
      _lastEnemy = current;
    } else if (current != null) {
      enemy.setHealth(current.health);
    }

    if (combat.hitTick != _lastHitTick) {
      _lastHitTick = combat.hitTick;
      hero.pulseAttack();
      enemy.flashHit();
      add(DamageNumber(
        position: enemy.position + Vector2(0, -100),
        text: '${combat.lastDamageToEnemy}',
      ));
      if (current == null || current.isDefeated) {
        enemy.startDefeat();
        add(GoldBurst(position: enemy.position.clone()));
        add(DamageNumber(
          position: enemy.position + Vector2(-20, -130),
          text: '+${combat.lastGoldReward}g',
          color: Palette.gold,
        ));
        add(DamageNumber(
          position: enemy.position + Vector2(20, -130),
          text: '+${combat.lastXpReward}xp',
          color: Palette.xp,
        ));
      }
    }

    if (combat.enemyHitTick != _lastEnemyHitTick) {
      _lastEnemyHitTick = combat.enemyHitTick;
      hero.flashHit();
      add(DamageNumber(
        position: hero.position + Vector2(0, -110),
        text: '${combat.lastDamageToHero}',
        color: Palette.hp,
      ));
    }

    hero.targetX = switch (combat.phase) {
      CombatPhase.engaged || CombatPhase.enemyDefeated => w * combatEngageX,
      CombatPhase.approaching || CombatPhase.idle => w * combatBaseX,
    };
  }
}
