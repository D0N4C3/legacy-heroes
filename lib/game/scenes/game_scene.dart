import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../features/combat/domain/combat_enemy.dart';
import '../../features/combat/domain/combat_state.dart';
import '../art/hero_art.dart';
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

  /// Hook the game wires up so a scene can shake the whole frame on impact
  /// (Visual Plan combat juice). No-op until set.
  void Function(double amount)? onShake;

  /// Fractional X (of screen width) the hero plants at during combat. The hero
  /// no longer drifts back and forth — foes march in from the right instead, so
  /// the world reads as scrolling forward. Dungeon/boss scenes may override.
  double get combatBaseX => 0.30;

  /// Fractional X (of screen width) a foe walks up to before engaging.
  double get combatEngageX => 0.66;

  CombatEnemy? _lastEnemy;
  int _lastHitTick = 0;
  int _lastEnemyHitTick = 0;
  int _lastAdvanceTick = 0;

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
      _lastEnemy = null;
      _lastHitTick = 0;
      _lastEnemyHitTick = 0;
      _lastAdvanceTick = 0;
      return;
    }

    hero.health = combat.heroHealth;
    hero.maxHealth = combat.heroMaxHealth;

    // The hero is planted; foes march in. Animation tracks the combat phase so
    // the hero walks in place while approaching, then swings while engaged.
    hero.anim = switch (combat.phase) {
      CombatPhase.approaching => HeroAnim.walk,
      CombatPhase.engaged => HeroAnim.attack,
      CombatPhase.enemyDefeated => HeroAnim.victory,
      CombatPhase.idle => HeroAnim.idle,
    };

    final current = combat.current;
    final freshFoe = !identical(current, _lastEnemy);
    if (freshFoe) {
      if (current != null) {
        enemy.spawn(current.type, current.health, current.maxHealth);
      }
      _lastEnemy = current;
    } else if (current != null) {
      enemy.setHealth(current.health);
    }

    // Stride the new foe in from off-screen right on each advance.
    if (combat.advanceTick != _lastAdvanceTick || freshFoe) {
      _lastAdvanceTick = combat.advanceTick;
      if (current != null) enemy.walkIn(w + 120);
    }

    if (combat.hitTick != _lastHitTick) {
      _lastHitTick = combat.hitTick;
      hero.pulseAttack();
      enemy.flashHit();
      _spawnAttackEffect(hero, enemy);
      onShake?.call(5);
      add(DamageNumber(
        position: enemy.position + Vector2(0, enemy.boss ? -170 : -100),
        text: '${combat.lastDamageToEnemy}',
      ));
      if (current == null || current.isDefeated) {
        enemy.startDefeat();
        onShake?.call(9);
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
      enemy.playAttack();
      add(SwordSlash(position: hero.position + Vector2(10, -90)));
      onShake?.call(7);
      add(DamageNumber(
        position: hero.position + Vector2(0, -110),
        text: '${combat.lastDamageToHero}',
        color: Palette.hp,
      ));
    }

    // Keep the hero rooted at its combat mark — never step backward.
    hero.targetX = w * combatBaseX;
  }

  /// Launch the hero's class-specific strike toward the foe.
  void _spawnAttackEffect(HeroAvatar hero, EnemyComponent enemy) {
    final to = enemy.position + Vector2(0, enemy.boss ? -90 : -46);

    // The Mage hurls a real SVG fireball from its (taller sprite) staff hand.
    if (heroClassId == 'mage') {
      add(FireballProjectile(
        from: hero.position + Vector2(24, -96),
        to: to,
      ));
      return;
    }

    final weapon = HeroArt.visualFor(heroClassId).weapon;
    final accent = HeroArt.visualFor(heroClassId).accent;
    final style = switch (weapon) {
      Weapon.staff => AttackStyle.magic,
      Weapon.bow => AttackStyle.arrow,
      _ => AttackStyle.melee,
    };
    final from = hero.position + Vector2(20, -60);
    final color = switch (style) {
      AttackStyle.magic => accent,
      AttackStyle.arrow => const Color(0xFFEAD7AE),
      AttackStyle.melee => const Color(0xFFFFF1C4),
    };
    add(AttackEffect(from: from, to: to, style: style, color: color));
  }
}
