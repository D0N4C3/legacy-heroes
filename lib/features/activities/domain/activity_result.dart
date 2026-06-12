import '../../equipment/domain/equipment.dart';

/// Outcome of a completed activity, shown on the Rewards screen (plan §6.3).
class ActivityResult {
  final int gold;
  final int xp;
  final List<EquipmentItem> loot;
  final bool survived;
  final bool leveledUp;
  final int newLevel;
  final String? storyEvent;
  final bool doubled;

  const ActivityResult({
    required this.gold,
    required this.xp,
    this.loot = const [],
    this.survived = true,
    this.leveledUp = false,
    this.newLevel = 0,
    this.storyEvent,
    this.doubled = false,
  });

  ActivityResult asDoubled() => ActivityResult(
        gold: gold * 2,
        xp: xp,
        loot: loot,
        survived: survived,
        leveledUp: leveledUp,
        newLevel: newLevel,
        storyEvent: storyEvent,
        doubled: true,
      );
}

/// Offline accrual summary shown on return (plan §3E / §4.1 "double rewards").
class OfflineReport {
  final int gold;
  final Duration awayFor;
  final bool capped;

  const OfflineReport({required this.gold, required this.awayFor, required this.capped});

  bool get hasReward => gold > 0;
}
