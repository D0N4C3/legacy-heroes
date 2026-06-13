import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../features/activities/domain/activity.dart';
import '../features/combat/domain/combat_enemy.dart';
import '../features/combat/domain/combat_state.dart';
import '../features/hero/domain/hero.dart';
import 'providers.dart';

/// Drives the real-time idle-combat mini-game (Phase 2): the hero marches
/// through an endless stream of foes — walking forward, engaging, slaying, and
/// pressing on automatically. The player can drop to Manual to tap each blow,
/// or tap Charge to skip the walk-up.
///
/// The loop runs on its own heartbeat ([GameConstants.combatLoopTick]) so foes
/// keep coming with no input (fixing "a new enemy only spawns when I tap Run").
///
/// This is a session-only "feel" layer — kills grant a small immediate
/// gold/XP trickle via [GameController.addCombatReward], but never touch the
/// activity's existing end-of-run success/loot roll.
class CombatController extends StateNotifier<CombatState> {
  CombatController(this._ref) : super(const CombatState());

  final Ref _ref;

  Timer? _loop;
  ActivityDef? _def;
  HeroData? _hero;

  /// Wall-clock the current phase began — drives approach / defeat pacing.
  DateTime _phaseSince = DateTime.now();

  /// Wall-clock of the last automatic attack (Auto mode cadence).
  DateTime _lastAutoAttack = DateTime.now();

  /// Begin (or restart) an encounter for the given dungeon/boss activity.
  void startEncounter(ActivityDef def, HeroData hero) {
    _def = def;
    _hero = hero;
    final maxHealth = (GameConstants.combatHeroHealthBase +
            hero.stats.vitality * GameConstants.combatHeroHealthPerVitality)
        .round();
    state = CombatState(
      active: true,
      queue: _freshQueue(),
      heroHealth: maxHealth,
      heroMaxHealth: maxHealth,
      autoMode: state.autoMode,
      phase: CombatPhase.approaching,
      advanceTick: state.advanceTick + 1,
    );
    _phaseSince = DateTime.now();
    _startLoop();
  }

  /// Stop the encounter (e.g. the player left the dungeon/boss scene).
  void reset() {
    _loop?.cancel();
    _loop = null;
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

  // ── Continuous loop ───────────────────────────────────────────────────────
  void _startLoop() {
    _loop?.cancel();
    _loop = Timer.periodic(GameConstants.combatLoopTick, (_) => _loopTick());
  }

  void _loopTick() {
    if (!state.active) return;
    final now = DateTime.now();
    switch (state.phase) {
      case CombatPhase.approaching:
        // The hero walks up to the foe; engage once they've closed the gap.
        if (now.difference(_phaseSince) >= GameConstants.combatApproachTime) {
          _setPhase(CombatPhase.engaged);
        }
        break;
      case CombatPhase.engaged:
        if (state.autoMode &&
            now.difference(_lastAutoAttack) >=
                GameConstants.combatAttackInterval) {
          _lastAutoAttack = now;
          attack();
        }
        break;
      case CombatPhase.enemyDefeated:
        // Hold a beat on the kill, then march on to the next foe.
        if (now.difference(_phaseSince) >= GameConstants.combatDefeatPause) {
          _advanceToNext();
        }
        break;
      case CombatPhase.idle:
        break;
    }
  }

  void _setPhase(CombatPhase phase) {
    _phaseSince = DateTime.now();
    state = state.copyWith(phase: phase);
  }

  /// Drop the slain foe, top the queue back up, and start walking to the next.
  void _advanceToNext() {
    var queue = state.queue;
    if (queue.isNotEmpty) queue = queue.skip(1).toList();
    final def = _def, hero = _hero;
    if (def != null &&
        hero != null &&
        queue.length < GameConstants.combatQueueSize) {
      queue = [...queue, CombatEnemy.forActivity(def, hero)];
    }
    _phaseSince = DateTime.now();
    state = state.copyWith(
      queue: queue,
      phase: CombatPhase.approaching,
      advanceTick: state.advanceTick + 1,
    );
  }

  /// Charge: skip the walk-up and engage the foe right now (or, if one was just
  /// slain, immediately march to the next). The idle loop still drives spawns,
  /// so this is purely an impatience button.
  void runForward() {
    if (!state.active) return;
    if (state.phase == CombatPhase.approaching) {
      _setPhase(CombatPhase.engaged);
    } else if (state.phase == CombatPhase.enemyDefeated) {
      _advanceToNext();
    }
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
      _phaseSince = DateTime.now();
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

  /// Toggle hands-off play. Auto mode lands blows automatically; Manual hands
  /// the timing to the player's Attack taps. Either way foes keep marching in.
  void toggleAuto() {
    final next = !state.autoMode;
    _lastAutoAttack = DateTime.now();
    state = state.copyWith(autoMode: next);
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }
}
