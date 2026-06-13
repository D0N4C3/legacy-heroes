import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../features/activities/domain/activity.dart';
import '../features/combat/domain/combat_enemy.dart';
import '../features/combat/domain/combat_state.dart';
import '../features/hero/domain/hero.dart';
import 'providers.dart';

/// Drives the real-time combat mini-game (Phase 2): the hero fights through a
/// queue of foes via manual taps (Attack / Run Forward) or an Auto toggle.
///
/// This is a session-only "feel" layer — kills grant a small immediate
/// gold/XP trickle via [GameController.addCombatReward], but never touch the
/// activity's existing end-of-run success/loot roll.
class CombatController extends StateNotifier<CombatState> {
  CombatController(this._ref) : super(const CombatState());

  final Ref _ref;

  Timer? _autoTimer;
  ActivityDef? _def;
  HeroData? _hero;

  /// Begin (or restart) an encounter for the given dungeon/boss activity.
  void startEncounter(ActivityDef def, HeroData hero) {
    _def = def;
    _hero = hero;
    final maxHealth = (GameConstants.combatHeroHealthBase +
            hero.stats.vitality * GameConstants.combatHeroHealthPerVitality)
        .round();
    final autoMode = state.autoMode;
    state = CombatState(
      active: true,
      queue: _freshQueue(),
      heroHealth: maxHealth,
      heroMaxHealth: maxHealth,
      autoMode: autoMode,
      phase: CombatPhase.approaching,
    );
    if (autoMode) _startAutoTimer();
  }

  /// Stop the encounter (e.g. the player left the dungeon/boss scene).
  void reset() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _def = null;
    _hero = null;
    state = const CombatState();
  }

  List<CombatEnemy> _freshQueue() {
    final def = _def, hero = _hero;
    if (def == null || hero == null) return const [];
    return List.generate(GameConstants.combatQueueSize,
        (_) => CombatEnemy.forActivity(def, hero));
  }

  /// Close the distance with the current foe (or the next one, after a kill).
  void runForward() {
    if (!state.active) return;
    if (state.phase != CombatPhase.approaching &&
        state.phase != CombatPhase.enemyDefeated) {
      return;
    }
    var queue = state.queue;
    if (state.phase == CombatPhase.enemyDefeated && queue.isNotEmpty) {
      queue = queue.skip(1).toList();
      final def = _def, hero = _hero;
      if (def != null && hero != null && queue.length < GameConstants.combatQueueSize) {
        queue = [...queue, CombatEnemy.forActivity(def, hero)];
      }
    }
    state = state.copyWith(queue: queue, phase: CombatPhase.engaged);
  }

  /// Land a hit on the current foe; it counters back if it survives.
  void attack() {
    if (!state.active || state.phase != CombatPhase.engaged) return;
    final hero = _hero;
    final enemy = state.current;
    if (hero == null || enemy == null) return;

    final dmg = max(1, (hero.power * GameConstants.combatHeroAttackFactor).round());
    enemy.health = max(0, enemy.health - dmg);

    if (enemy.isDefeated) {
      _ref.read(gameControllerProvider.notifier)
          .addCombatReward(gold: enemy.goldReward, xp: enemy.xpReward);
      state = state.copyWith(
        phase: CombatPhase.enemyDefeated,
        hitTick: state.hitTick + 1,
        lastDamageToEnemy: dmg,
        lastGoldReward: enemy.goldReward,
        lastXpReward: enemy.xpReward,
      );
      return;
    }

    // The foe counters while still standing. A "defeated" hero simply
    // staggers back to full health — combat never ends the activity.
    final remaining = state.heroHealth - enemy.attack;
    state = state.copyWith(
      heroHealth: remaining <= 0 ? state.heroMaxHealth : remaining,
      hitTick: state.hitTick + 1,
      enemyHitTick: state.enemyHitTick + 1,
      lastDamageToEnemy: dmg,
      lastDamageToHero: enemy.attack,
    );
  }

  /// Toggle hands-off play: Auto mode loops run-forward → attack on a timer.
  void toggleAuto() {
    final next = !state.autoMode;
    state = state.copyWith(autoMode: next);
    if (next) {
      _startAutoTimer();
    } else {
      _autoTimer?.cancel();
      _autoTimer = null;
    }
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(GameConstants.combatAutoInterval, (_) {
      if (!state.active || !state.autoMode) return;
      if (state.phase == CombatPhase.engaged) {
        attack();
      } else {
        runForward();
      }
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}
