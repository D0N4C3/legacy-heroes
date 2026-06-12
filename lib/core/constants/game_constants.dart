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
