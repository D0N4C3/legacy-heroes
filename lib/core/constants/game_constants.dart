/// Central balance & tuning constants for Legacy Heroes.
///
/// Keeping every magic number here makes the game easy to balance later
/// (plan §7 "Important Game Logic" and §16 roadmap).
class GameConstants {
  GameConstants._();

  // ── Economy ────────────────────────────────────────────────────────────
  static const int startingGold = 100;
  static const int startingGems = 25;

  // ── Leveling (plan §7: XP required = level * level * 100) ───────────────
  static int xpForLevel(int level) => level * level * 100;
  static const int maxLevel = 20; // MVP cap (plan §17: "20 levels")

  // ── Offline rewards (plan §3E / §12 anti-cheat caps) ────────────────────
  static const Duration freeOfflineCap = Duration(hours: 4);
  static const Duration premiumOfflineCap = Duration(hours: 12);
  static const double rewardedAdMultiplier = 2.0;

  // ── Aging & generations (plan §3B) ──────────────────────────────────────
  /// Real seconds that equal one in-game year.
  ///
  /// The plan suggests 24h (86400). For the MVP we use a faster value so the
  /// signature generational loop is reachable inside a single play session.
  /// Set to 86400 for production pacing.
  static const int realSecondsPerGameYear = 600; // DEV pacing
  static const int heroStartAge = 18;
  static const int heirEligibleAge = 22;
  static const int retirementAge = 55;
  static const int maxAge = 70;

  // Life-stage thresholds (in-game years)
  static const int stageExperiencedAge = 26;
  static const int stageVeteranAge = 40;
  static const int stageElderAge = 55;

  // ── Inheritance (plan §7) ───────────────────────────────────────────────
  static const double baseInheritance = 0.10; // 10% of parent power
  static const double rareBloodInheritance = 0.05; // Strong Blood trait
  static const double adBlessingInheritance = 0.10; // rewarded ad
  static const double premiumAltarInheritance = 0.15;

  // ── Risk / death (plan §7) ──────────────────────────────────────────────
  static const Map<String, double> riskBaseDeath = {
    'none': 0.0,
    'low': 0.0,
    'medium': 0.0, // early generations retire peacefully, not die (plan §7)
    'high': 0.04,
    'deadly': 0.12,
  };

  // ── Combat / success (plan §3D) ─────────────────────────────────────────
  static const double minSuccessChance = 0.15;
  static const double maxSuccessChance = 0.99;

  // ── Combat mini-game (Phase 2 — additive bonus layer) ───────────────────
  /// Enemy max HP ≈ hero.power * factor, scaled up for higher loot tiers.
  static const double combatEnemyHealthFactor = 0.35;
  static const double combatEnemyHealthTierBonus = 0.15;

  /// Enemy attack per counter-hit ≈ hero.power * factor, scaled by tier.
  static const double combatEnemyAttackFactor = 0.04;
  static const double combatEnemyAttackTierBonus = 0.1;

  /// Hero damage per attack ≈ hero.power * factor.
  static const double combatHeroAttackFactor = 0.12;

  /// Hero combat max HP = base + vitality * perVitality.
  static const double combatHeroHealthBase = 50;
  static const double combatHeroHealthPerVitality = 5;

  /// Bonus gold/XP per kill, as a fraction of the activity's normal rewards —
  /// on top of, not instead of, the end-of-activity success/loot roll.
  static const double combatGoldRewardFraction = 0.2; // of goldPerMinute
  static const double combatXpRewardFraction = 0.03; // of xpReward

  /// How often Auto mode advances the encounter (run forward + attack).
  static const Duration combatAutoInterval = Duration(milliseconds: 1100);

  /// The internal heartbeat that drives the continuous idle-combat loop
  /// (approach → engage → defeat → next). Fine-grained so phase transitions
  /// feel responsive.
  static const Duration combatLoopTick = Duration(milliseconds: 120);

  /// How long the hero "walks forward" toward the next foe before engaging —
  /// the world scrolls and the next enemy strides in during this window.
  static const Duration combatApproachTime = Duration(milliseconds: 1400);

  /// Beat held on a slain foe before the hero marches on to the next.
  static const Duration combatDefeatPause = Duration(milliseconds: 650);

  /// Cadence of automatic attacks while engaged (Auto mode / idle combat).
  static const Duration combatAttackInterval = Duration(milliseconds: 850);

  /// Number of foes kept queued during an encounter.
  static const int combatQueueSize = 3;

  // ── Daily rewards (plan §6.9) ───────────────────────────────────────────
  static const List<Map<String, int>> dailyRewards = [
    {'gold': 150, 'gems': 0},
    {'gold': 250, 'gems': 0},
    {'gold': 0, 'gems': 15},
    {'gold': 400, 'gems': 0},
    {'gold': 600, 'gems': 0},
    {'gold': 0, 'gems': 30},
    {'gold': 1000, 'gems': 50},
  ];
}
