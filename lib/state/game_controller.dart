import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../core/services/ad_service.dart';
import '../core/services/analytics_service.dart';
import '../core/services/catalog_service.dart';
import '../core/services/save_service.dart';
import '../core/utils/rng.dart';
import '../features/activities/data/activity_repository.dart';
import '../features/activities/domain/activity.dart';
import '../features/activities/domain/activity_result.dart';
import '../features/equipment/data/loot_factory.dart';
import '../features/equipment/domain/equipment.dart';
import '../features/hero/data/hero_factory.dart';
import '../features/hero/domain/hero.dart';
import '../features/hero/domain/life_stage.dart';
import 'game_state.dart';

/// Drives the entire game loop: activities, offline rewards, leveling, aging,
/// and the generational legacy transition (plan §2, §3, §7).
class GameController extends StateNotifier<GameState> {
  GameController({
    required this.save,
    required this.ads,
    required this.analytics,
  }) : super(GameState(
          gold: 0,
          gems: 0,
          generation: 0,
          lastSavedAt: DateTime.now(),
        ));

  final SaveService save;
  final AdService ads;
  final AnalyticsService analytics;

  final _repo = ActivityRepository.instance;
  Timer? _ticker;
  double _goldAccumulator = 0;
  int _sinceSave = 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────
  Future<void> init() async {
    final raw = await save.load();
    if (raw == null) {
      _startNewGame();
    } else {
      try {
        state = GameState.decode(raw);
        _applyOfflineProgress();
      } catch (_) {
        _startNewGame();
      }
    }
    _startTicker();
  }

  void _startNewGame() {
    final founder = HeroFactory.createFounder();
    state = GameState(
      gold: GameConstants.startingGold,
      gems: GameConstants.startingGems,
      generation: 1,
      hero: founder,
      lastSavedAt: DateTime.now(),
    );
    analytics.tutorialComplete();
    _persist();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Per-second tick ──────────────────────────────────────────────────────
  void _tick() {
    final hero = state.hero;
    if (hero == null || state.awaitingHeir) return;

    var next = state;

    // Aging is derived from real wall-clock time since birth (plan §3B).
    final newAge = _computeAge(hero);
    if (newAge != hero.age) {
      next = next.copyWith(
        hero: hero.copyWith(age: newAge, stage: LifeStage.fromAge(newAge)),
      );
    }

    // Passive idle gold while resting in the village.
    if (next.isResting && next.pendingResult == null) {
      _goldAccumulator += next.hero!.idleGoldPerMinute / 60.0;
      if (_goldAccumulator >= 1) {
        final add = _goldAccumulator.floor();
        _goldAccumulator -= add;
        next = next.copyWith(gold: next.gold + add);
      }
    }

    // Activity completion.
    if (next.currentActivity != null && next.pendingResult == null) {
      final def = _repo.byId(next.currentActivity!.activityId);
      if (next.currentActivity!.isComplete(def, DateTime.now())) {
        next = _resolveActivity(next, def);
      }
    }

    state = next;

    // Peaceful retirement once a hero grows old enough (plan §3B / §7).
    if (state.hero!.age >= GameConstants.retirementAge &&
        state.isResting &&
        state.pendingResult == null &&
        !state.awaitingHeir) {
      _beginLegacyTransition(retired: true, cause: 'Retired with honor');
      return;
    }

    // Lightweight autosave so accrued gold / aging survive an app kill, and the
    // offline baseline stays fresh.
    if (++_sinceSave >= 30) {
      _sinceSave = 0;
      _persist();
    }
  }

  int _computeAge(HeroData hero) {
    final secs = DateTime.now().difference(hero.bornAt).inSeconds;
    final years =
        GameConstants.heroStartAge + secs ~/ GameConstants.realSecondsPerGameYear;
    return min(years, GameConstants.maxAge);
  }

  // ── Activities (plan §3D) ────────────────────────────────────────────────
  void startActivity(String activityId) {
    if (!state.hasHero || state.awaitingHeir) return;
    state = state.copyWith(
      currentActivity:
          ActivityInstance(activityId: activityId, startedAt: DateTime.now()),
      pendingResult: null,
    );
    analytics.activityStart(activityId);
    _persist();
  }

  /// Compute the outcome of a finished activity and stage it for collection.
  GameState _resolveActivity(GameState s, ActivityDef def) {
    final hero = s.hero!;
    final bonuses = hero.classData.bonuses;
    final rewardMult = Catalog.instance.traitRewardMult(hero.traitIds);

    // Success chance = power / recommended (plan §3D), nudged by class & traits.
    final successChance = (hero.power / def.recommendedPower +
            bonuses.expeditionSuccess)
        .clamp(GameConstants.minSuccessChance, GameConstants.maxSuccessChance);
    final success = chance(successChance.toDouble());

    // Death risk only bites older heroes on dangerous runs (plan §7).
    final ageMod = hero.age >= 45 ? (hero.age - 45) * 0.01 : 0.0;
    final survivalBonus =
        bonuses.survival + Catalog.instance.traitSurvivalBonus(hero.traitIds);
    final deathChance =
        ((GameConstants.riskBaseDeath[def.risk.name] ?? 0) + ageMod - survivalBonus)
            .clamp(0.0, 0.6);
    final died = hero.age >= 40 && chance(deathChance.toDouble());

    // Rewards.
    final dungeonMult = 1 + bonuses.dungeonReward;
    var gold = (def.goldPerMinute * def.durationMinutes * rewardMult * dungeonMult)
        .round();
    var xp = (def.xpReward * rewardMult).round();
    final loot = <EquipmentItem>[];
    String? story;

    if (!success) {
      gold = (gold * 0.4).round();
      xp = (xp * 0.5).round();
      story = '${hero.name} was overwhelmed but escaped with their life.';
    } else {
      if (chance(def.lootChance)) {
        loot.add(LootFactory.roll(def.lootTier, classId: hero.classId));
      }
      // Boss / ruins can yield a passdown heirloom.
      if (def.lootTier >= 3 && chance(0.18)) {
        loot.add(LootFactory.heirloom(hero.generation));
        story = '${hero.name} recovered a relic worthy of the bloodline!';
      }
      story ??= '${hero.name} returned victorious from ${def.name}.';
    }

    final result = ActivityResult(
      gold: gold,
      xp: xp,
      loot: loot,
      survived: !died,
      storyEvent: died
          ? '${hero.name} fell at ${def.name}. Their legacy must continue.'
          : story,
    );

    return s.copyWith(currentActivity: null, pendingResult: result);
  }

  /// Apply the staged rewards to the hero (plan §6.3 Rewards screen).
  Future<void> collectRewards({bool useAd = false}) async {
    var result = state.pendingResult;
    if (result == null) return;

    if (useAd && result.survived) {
      analytics.adImpression('bonus_double');
      final watched = await ads.showRewarded(RewardPlacement.doubleOfflineRewards);
      if (watched) {
        analytics.adComplete('bonus_double');
        result = result.asDoubled();
      }
    }

    final hero = state.hero!;
    var gold = state.gold + result.gold;
    final inventory = [...state.inventory, ...result.loot];

    final (leveledHero, levelAchievements) = _applyXp(hero, result.xp);
    final achievements = [...hero.achievements, ...levelAchievements];
    if (result.loot.any((e) => e.isHeirloom)) {
      achievements.add('Recovered a family heirloom');
    }

    final updatedHero = leveledHero.copyWith(achievements: achievements);

    state = state.copyWith(
      gold: gold,
      hero: updatedHero,
      inventory: inventory,
      pendingResult: null,
    );

    // A fallen hero ends the generation after rewards are collected.
    if (!result.survived) {
      _beginLegacyTransition(retired: false, cause: 'Fell in battle');
    }
    _persist();
  }

  /// Apply XP to [hero], rolling level-ups (plan §7: XP required = level²×100).
  /// Returns the updated hero plus any milestone achievements earned.
  (HeroData, List<String>) _applyXp(HeroData hero, int xp) {
    var level = hero.level;
    var remaining = hero.xp + xp;
    final achievements = <String>[];
    while (level < GameConstants.maxLevel &&
        remaining >= GameConstants.xpForLevel(level)) {
      remaining -= GameConstants.xpForLevel(level);
      level++;
    }
    if (level > hero.level && level % 5 == 0) {
      achievements.add('Reached level $level');
    }
    return (hero.copyWith(level: level, xp: remaining), achievements);
  }

  /// Small immediate gold/XP trickle from the real-time combat mini-game
  /// (Phase 2). Purely additive — does not touch [_resolveActivity]'s
  /// success/loot roll or the staged [ActivityResult].
  void addCombatReward({required int gold, required int xp}) {
    final hero = state.hero;
    if (hero == null) return;
    final (leveledHero, levelAchievements) = _applyXp(hero, xp);
    final achievements = [...hero.achievements, ...levelAchievements];
    state = state.copyWith(
      gold: state.gold + gold,
      hero: leveledHero.copyWith(achievements: achievements),
    );
    _persist();
  }

  // ── Offline rewards (plan §3E, §12 anti-cheat caps) ──────────────────────
  void _applyOfflineProgress() {
    final hero = state.hero;
    if (hero == null) return;

    // Re-derive age for the time spent away.
    final age = _computeAge(hero);
    var working = state.copyWith(
      hero: hero.copyWith(age: age, stage: LifeStage.fromAge(age)),
    );

    final now = DateTime.now();
    final away = now.difference(working.lastSavedAt);
    final cap = working.premium
        ? GameConstants.premiumOfflineCap
        : GameConstants.freeOfflineCap;
    final capped = away > cap;
    final effective = capped ? cap : away;
    final minutes = effective.inSeconds / 60.0;

    // Rate follows the current activity, else passive idle (plan §3E).
    double ratePerMin;
    if (working.currentActivity != null) {
      ratePerMin = _repo.byId(working.currentActivity!.activityId).goldPerMinute;
    } else {
      ratePerMin = working.hero!.idleGoldPerMinute;
    }
    final offlineGold = (ratePerMin * minutes).round();

    // If the activity finished while away, stage its rewards too.
    if (working.currentActivity != null) {
      final def = _repo.byId(working.currentActivity!.activityId);
      if (working.currentActivity!.isComplete(def, now)) {
        working = _resolveActivity(working, def);
      }
    }

    if (offlineGold > 0) {
      analytics.offlineClaim(offlineGold);
      working = working.copyWith(
        gold: working.gold + offlineGold,
        offlineReport: OfflineReport(
            gold: offlineGold, awayFor: away, capped: capped),
      );
    }

    state = working;
    _persist();
  }

  /// "Watch ad to double your offline reward" (plan §4.1 — strongest placement).
  Future<void> claimDoubleOffline() async {
    final report = state.offlineReport;
    if (report == null || !report.hasReward) return;
    analytics.adImpression('double_offline');
    final watched = await ads.showRewarded(RewardPlacement.doubleOfflineRewards);
    if (watched) analytics.adComplete('double_offline');
    // Always clear the report so the welcome-back modal closes; only credit the
    // bonus gold if the ad was actually watched.
    state = state.copyWith(
      gold: state.gold + (watched ? report.gold : 0),
      offlineReport: null,
    );
    _persist();
  }

  void dismissOfflineReport() =>
      state = state.copyWith(offlineReport: null);

  // ── Equipment (plan §6.5) ────────────────────────────────────────────────
  void equip(EquipmentItem item) {
    final hero = state.hero!;
    final equip = Map<EquipSlot, EquipmentItem>.from(hero.equipment);
    final inventory = [...state.inventory]..removeWhere((e) => e.id == item.id);
    final previous = equip[item.slot];
    if (previous != null) inventory.add(previous);
    equip[item.slot] = item;
    state = state.copyWith(
      hero: hero.copyWith(equipment: equip),
      inventory: inventory,
    );
    _persist();
  }

  void unequip(EquipSlot slot) {
    final hero = state.hero!;
    final equip = Map<EquipSlot, EquipmentItem>.from(hero.equipment);
    final removed = equip.remove(slot);
    if (removed == null) return;
    state = state.copyWith(
      hero: hero.copyWith(equipment: equip),
      inventory: [...state.inventory, removed],
    );
    _persist();
  }

  // ── Legacy / generations (plan §3B, §6.7) ────────────────────────────────
  void _beginLegacyTransition({required bool retired, required String cause}) {
    final hero = state.hero!;
    final ancestor =
        HeroFactory.toAncestor(hero, retired: retired, cause: cause);
    final heirs = HeroFactory.generateHeirs(hero);
    state = state.copyWith(
      hero: hero.copyWith(
          stage: retired ? LifeStage.retired : LifeStage.fallen),
      familyTree: [...state.familyTree, ancestor],
      heirCandidates: heirs,
      currentActivity: null,
      pendingResult: null,
    );
    _persist();
  }

  /// Choose the heir and begin the next generation (plan §6.7).
  /// [bless] watches a rewarded ad for +inheritance (plan §4.5).
  Future<void> selectHeir(String candidateId, {bool bless = false}) async {
    final candidate =
        state.heirCandidates.firstWhere((c) => c.id == candidateId);
    final parent = state.hero!;

    double blessing = 0;
    if (bless) {
      analytics.adImpression('heir_blessing');
      final watched = await ads.showRewarded(RewardPlacement.heirBlessing);
      if (watched) {
        analytics.adComplete('heir_blessing');
        blessing = GameConstants.adBlessingInheritance;
      }
    }

    // Carry the heirloom forward if the chosen heir was set to inherit it.
    EquipmentItem? heirloom;
    if (candidate.heirloomName != null) {
      heirloom = parent.equipment[EquipSlot.heirloom] ??
          LootFactory.heirloom(parent.generation);
    }

    final newGen = state.generation + 1;
    final heir = HeroFactory.materializeHeir(
      candidate: candidate,
      parent: parent,
      generation: newGen,
      heirloom: heirloom,
      blessingBonus: blessing,
    );

    analytics.generationTransition(newGen);
    state = state.copyWith(
      hero: heir,
      generation: newGen,
      heirCandidates: [],
      inventory: const [],
      currentActivity: null,
      pendingResult: null,
    );
    _persist();
  }

  // ── Daily reward (plan §6.9) ─────────────────────────────────────────────
  bool get canClaimDaily {
    final last = state.lastDailyClaim;
    if (last == null) return true;
    final today = DateTime.now();
    return last.year != today.year ||
        last.month != today.month ||
        last.day != today.day;
  }

  void claimDaily() {
    if (!canClaimDaily) return;
    final streak = (state.dailyStreak % GameConstants.dailyRewards.length);
    final reward = GameConstants.dailyRewards[streak];
    analytics.dailyReturn(state.dailyStreak + 1);
    state = state.copyWith(
      gold: state.gold + (reward['gold'] ?? 0),
      gems: state.gems + (reward['gems'] ?? 0),
      dailyStreak: state.dailyStreak + 1,
      lastDailyClaim: DateTime.now(),
    );
    _persist();
  }

  // ── Debug / shop helpers ─────────────────────────────────────────────────
  void addGold(int n) {
    state = state.copyWith(gold: state.gold + n);
    _persist();
  }

  void resetGame() {
    save.clear();
    _goldAccumulator = 0;
    _startNewGame();
  }

  // ── Persistence ──────────────────────────────────────────────────────────
  void _persist() {
    state = state.copyWith(lastSavedAt: DateTime.now());
    save.save(state.encode());
  }
}
