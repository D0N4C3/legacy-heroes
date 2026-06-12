import '../../../game/scene_type.dart';

enum RiskLevel {
  none('Safe', 0),
  low('Low Risk', 1),
  medium('Risky', 2),
  high('Dangerous', 3),
  deadly('Deadly', 4);

  const RiskLevel(this.label, this.skulls);
  final String label;
  final int skulls;

  static RiskLevel fromId(String id) =>
      RiskLevel.values.firstWhere((r) => r.name == id, orElse: () => RiskLevel.none);
}

/// Static activity definition (plan §3D), loaded from activities.json.
class ActivityDef {
  final String id;
  final String name;
  final String description;
  final SceneType scene;
  final int recommendedPower;
  final int durationMinutes;
  final RiskLevel risk;
  final double goldPerMinute;
  final int xpReward;
  final double lootChance;
  final int lootTier;

  const ActivityDef({
    required this.id,
    required this.name,
    required this.description,
    required this.scene,
    required this.recommendedPower,
    required this.durationMinutes,
    required this.risk,
    required this.goldPerMinute,
    required this.xpReward,
    required this.lootChance,
    required this.lootTier,
  });

  factory ActivityDef.fromJson(Map<String, dynamic> j) => ActivityDef(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        scene: SceneTypeX.fromId(j['scene']),
        recommendedPower: j['recommendedPower'],
        durationMinutes: j['durationMinutes'],
        risk: RiskLevel.fromId(j['risk']),
        goldPerMinute: (j['goldPerMinute']).toDouble(),
        xpReward: j['xpReward'],
        lootChance: (j['lootChance']).toDouble(),
        lootTier: j['lootTier'],
      );

  Duration get duration => Duration(minutes: durationMinutes);
}

/// A running activity bound to a start time (plan §10 activities collection).
class ActivityInstance {
  final String activityId;
  final DateTime startedAt;

  const ActivityInstance({required this.activityId, required this.startedAt});

  DateTime endAt(ActivityDef def) => startedAt.add(def.duration);
  bool isComplete(ActivityDef def, DateTime now) => !now.isBefore(endAt(def));

  Map<String, dynamic> toJson() =>
      {'activityId': activityId, 'startedAt': startedAt.toIso8601String()};

  factory ActivityInstance.fromJson(Map<String, dynamic> j) => ActivityInstance(
        activityId: j['activityId'],
        startedAt: DateTime.parse(j['startedAt']),
      );
}
