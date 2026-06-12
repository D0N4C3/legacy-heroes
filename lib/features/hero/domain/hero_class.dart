import 'dart:ui';

/// Idle-reward multipliers granted by a class (plan §3A).
class ClassBonuses {
  final double combatPower;
  final double dungeonReward;
  final double expeditionSuccess;
  final double craftQuality;
  final double survival;

  const ClassBonuses({
    this.combatPower = 0,
    this.dungeonReward = 0,
    this.expeditionSuccess = 0,
    this.craftQuality = 0,
    this.survival = 0,
  });

  factory ClassBonuses.fromJson(Map<String, dynamic> j) => ClassBonuses(
        combatPower: (j['combatPower'] ?? 0).toDouble(),
        dungeonReward: (j['dungeonReward'] ?? 0).toDouble(),
        expeditionSuccess: (j['expeditionSuccess'] ?? 0).toDouble(),
        craftQuality: (j['craftQuality'] ?? 0).toDouble(),
        survival: (j['survival'] ?? 0).toDouble(),
      );
}

class HeroStats {
  final int strength, agility, intelligence, vitality;
  const HeroStats(this.strength, this.agility, this.intelligence, this.vitality);

  int get total => strength + agility + intelligence + vitality;

  factory HeroStats.fromJson(Map<String, dynamic> j) => HeroStats(
        j['strength'], j['agility'], j['intelligence'], j['vitality']);

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'agility': agility,
        'intelligence': intelligence,
        'vitality': vitality,
      };

  HeroStats operator +(HeroStats o) => HeroStats(strength + o.strength,
      agility + o.agility, intelligence + o.intelligence, vitality + o.vitality);
}

/// Static definition of a playable class, loaded from assets/data/heroes.json.
class HeroClassData {
  final String id;
  final String name;
  final String description;
  final Color color;
  final HeroStats base;
  final ClassBonuses bonuses;

  const HeroClassData({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.base,
    required this.bonuses,
  });

  factory HeroClassData.fromJson(Map<String, dynamic> j) => HeroClassData(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        color: _hex(j['color']),
        base: HeroStats.fromJson(j['base']),
        bonuses: ClassBonuses.fromJson(j['bonuses']),
      );

  static Color _hex(String h) =>
      Color(int.parse(h.replaceFirst('#', '0xFF')));
}
