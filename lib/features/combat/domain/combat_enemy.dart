import 'dart:math';

import '../../../core/constants/game_constants.dart';
import '../../../core/utils/rng.dart';
import '../../../game/art/enemy_art.dart';
import '../../../game/scene_type.dart';
import '../../activities/domain/activity.dart';
import '../../hero/domain/hero.dart';

/// A single foe in the real-time combat mini-game's encounter queue
/// (Phase 2 — additive bonus layer on top of the existing activity economy).
class CombatEnemy {
  CombatEnemy({
    required this.type,
    required this.name,
    required this.maxHealth,
    required this.attack,
    required this.goldReward,
    required this.xpReward,
    int? health,
  }) : health = health ?? maxHealth;

  final EnemyType type;
  final String name;
  final int maxHealth;
  int health;
  final int attack;
  final int goldReward;
  final int xpReward;

  bool get isDefeated => health <= 0;

  /// Derive a foe from the activity being run and the hero's current power,
  /// so combat difficulty tracks the existing recommended-power tuning.
  factory CombatEnemy.forActivity(ActivityDef def, HeroData hero) {
    final tier = def.lootTier;
    final isBoss = def.scene == SceneType.boss;
    final type = isBoss
        ? EnemyType.demon
        : pick([EnemyType.goblin, EnemyType.wolf, EnemyType.skeleton]);

    final maxHealth = max(
        8,
        (hero.power *
                GameConstants.combatEnemyHealthFactor *
                (1 + tier * GameConstants.combatEnemyHealthTierBonus))
            .round());
    final attack = max(
        1,
        (hero.power *
                GameConstants.combatEnemyAttackFactor *
                (1 + tier * GameConstants.combatEnemyAttackTierBonus))
            .round());
    final goldReward =
        max(1, (def.goldPerMinute * GameConstants.combatGoldRewardFraction).round());
    final xpReward =
        max(1, (def.xpReward * GameConstants.combatXpRewardFraction).round());

    return CombatEnemy(
      type: type,
      name: _nameFor(type, isBoss),
      maxHealth: maxHealth,
      attack: attack,
      goldReward: goldReward,
      xpReward: xpReward,
    );
  }

  static String _nameFor(EnemyType type, bool boss) {
    if (boss) return 'Demon Overlord';
    return switch (type) {
      EnemyType.goblin => 'Goblin Raider',
      EnemyType.wolf => 'Dire Wolf',
      EnemyType.skeleton => 'Bone Warrior',
      EnemyType.demon => 'Lesser Demon',
    };
  }
}
