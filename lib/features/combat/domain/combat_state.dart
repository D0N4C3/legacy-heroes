import 'combat_enemy.dart';

/// Stages of the real-time combat mini-game's flow within a single encounter.
enum CombatPhase {
  /// No encounter running (resting, or outside a dungeon/boss activity).
  idle,

  /// An enemy is queued but the hero hasn't closed the distance yet.
  approaching,

  /// The hero is toe-to-toe with the current enemy and can attack.
  engaged,

  /// The current enemy just fell; the next one hasn't been engaged yet.
  enemyDefeated,
}

/// Live, session-only state for the Phase 2 combat mini-game.
///
/// This is purely an additive "feel" layer on top of the existing activity
/// economy — it is never persisted and never affects the success/loot roll
/// in `GameController._resolveActivity`. Kills here grant small immediate
/// bonus gold/XP via `GameController.addCombatReward`.
class CombatState {
  const CombatState({
    this.active = false,
    this.queue = const [],
    this.heroHealth = 0,
    this.heroMaxHealth = 0,
    this.autoMode = false,
    this.phase = CombatPhase.idle,
    this.hitTick = 0,
    this.enemyHitTick = 0,
    this.lastDamageToEnemy = 0,
    this.lastDamageToHero = 0,
    this.lastGoldReward = 0,
    this.lastXpReward = 0,
  });

  /// Whether a dungeon/boss encounter is currently running.
  final bool active;

  /// Upcoming foes; `queue.first` is the one the hero is facing.
  final List<CombatEnemy> queue;

  final int heroHealth;
  final int heroMaxHealth;
  final bool autoMode;
  final CombatPhase phase;

  /// Bumped whenever the hero lands a hit on the enemy — lets the Flame layer
  /// detect a fresh hit (vs. an unrelated rebuild) without consuming a flag.
  final int hitTick;

  /// Bumped whenever the enemy counters and hits the hero.
  final int enemyHitTick;

  final int lastDamageToEnemy;
  final int lastDamageToHero;
  final int lastGoldReward;
  final int lastXpReward;

  CombatEnemy? get current => queue.isEmpty ? null : queue.first;

  CombatState copyWith({
    bool? active,
    List<CombatEnemy>? queue,
    int? heroHealth,
    int? heroMaxHealth,
    bool? autoMode,
    CombatPhase? phase,
    int? hitTick,
    int? enemyHitTick,
    int? lastDamageToEnemy,
    int? lastDamageToHero,
    int? lastGoldReward,
    int? lastXpReward,
  }) =>
      CombatState(
        active: active ?? this.active,
        queue: queue ?? this.queue,
        heroHealth: heroHealth ?? this.heroHealth,
        heroMaxHealth: heroMaxHealth ?? this.heroMaxHealth,
        autoMode: autoMode ?? this.autoMode,
        phase: phase ?? this.phase,
        hitTick: hitTick ?? this.hitTick,
        enemyHitTick: enemyHitTick ?? this.enemyHitTick,
        lastDamageToEnemy: lastDamageToEnemy ?? this.lastDamageToEnemy,
        lastDamageToHero: lastDamageToHero ?? this.lastDamageToHero,
        lastGoldReward: lastGoldReward ?? this.lastGoldReward,
        lastXpReward: lastXpReward ?? this.lastXpReward,
      );
}
