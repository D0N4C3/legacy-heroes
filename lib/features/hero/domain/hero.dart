import '../../../core/constants/game_constants.dart';
import '../../../core/services/catalog_service.dart';
import '../../equipment/domain/equipment.dart';
import 'hero_class.dart';
import 'life_stage.dart';

/// The living hero the player currently controls (plan §3A).
class HeroData {
  final String id;
  final String name;
  final String classId;
  final int generation;
  final int level;
  final int xp;

  /// In-game age in years (derived from [bornAt] + play time; cached on save).
  final int age;
  final HeroStats stats;
  final List<String> traitIds;
  final Map<EquipSlot, EquipmentItem> equipment;
  final List<String> achievements;
  final String? parentId;
  final List<String> childrenIds;

  /// Real wall-clock time the hero was created — drives aging (§3B).
  final DateTime bornAt;
  final LifeStage stage;

  /// Flat power inherited from the family line (§7 "Legacy Bonus").
  final double legacyBonus;

  const HeroData({
    required this.id,
    required this.name,
    required this.classId,
    required this.generation,
    required this.level,
    required this.xp,
    required this.age,
    required this.stats,
    required this.traitIds,
    required this.equipment,
    required this.achievements,
    required this.bornAt,
    required this.stage,
    this.parentId,
    this.childrenIds = const [],
    this.legacyBonus = 0,
  });

  HeroClassData get classData => Catalog.instance.classOf(classId);

  int get equipmentPower =>
      equipment.values.fold(0, (sum, e) => sum + e.power);

  /// Hero Power = (stats + equipment) × trait multiplier × class combat bonus
  ///             + legacy bonus     (plan §3D / §7).
  double get power {
    final raw = stats.total + equipmentPower;
    final traitMult = Catalog.instance.traitPowerMult(traitIds);
    final classMult = 1 + classData.bonuses.combatPower;
    return raw * traitMult * classMult + legacyBonus;
  }

  int get xpForNext => GameConstants.xpForLevel(level);
  double get xpProgress => xp / xpForNext;

  /// Idle gold per minute while resting in the village (passive trickle).
  double get idleGoldPerMinute => 2.0 + level * 1.5;

  bool get canHaveHeir => age >= GameConstants.heirEligibleAge;

  HeroData copyWith({
    String? name,
    int? level,
    int? xp,
    int? age,
    HeroStats? stats,
    List<String>? traitIds,
    Map<EquipSlot, EquipmentItem>? equipment,
    List<String>? achievements,
    List<String>? childrenIds,
    LifeStage? stage,
    double? legacyBonus,
  }) =>
      HeroData(
        id: id,
        name: name ?? this.name,
        classId: classId,
        generation: generation,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        age: age ?? this.age,
        stats: stats ?? this.stats,
        traitIds: traitIds ?? this.traitIds,
        equipment: equipment ?? this.equipment,
        achievements: achievements ?? this.achievements,
        bornAt: bornAt,
        stage: stage ?? this.stage,
        parentId: parentId,
        childrenIds: childrenIds ?? this.childrenIds,
        legacyBonus: legacyBonus ?? this.legacyBonus,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'classId': classId,
        'generation': generation,
        'level': level,
        'xp': xp,
        'age': age,
        'stats': stats.toJson(),
        'traitIds': traitIds,
        'equipment':
            equipment.map((k, v) => MapEntry(k.name, v.toJson())),
        'achievements': achievements,
        'parentId': parentId,
        'childrenIds': childrenIds,
        'bornAt': bornAt.toIso8601String(),
        'stage': stage.name,
        'legacyBonus': legacyBonus,
      };

  factory HeroData.fromJson(Map<String, dynamic> j) {
    final equip = <EquipSlot, EquipmentItem>{};
    (j['equipment'] as Map<String, dynamic>).forEach((k, v) {
      equip[EquipSlot.values.byName(k)] = EquipmentItem.fromJson(v);
    });
    return HeroData(
      id: j['id'],
      name: j['name'],
      classId: j['classId'],
      generation: j['generation'],
      level: j['level'],
      xp: j['xp'],
      age: j['age'],
      stats: HeroStats.fromJson(j['stats']),
      traitIds: (j['traitIds'] as List).cast<String>(),
      equipment: equip,
      achievements: (j['achievements'] as List).cast<String>(),
      parentId: j['parentId'],
      childrenIds: (j['childrenIds'] as List?)?.cast<String>() ?? const [],
      bornAt: DateTime.parse(j['bornAt']),
      stage: LifeStage.values.byName(j['stage']),
      legacyBonus: (j['legacyBonus'] ?? 0).toDouble(),
    );
  }
}
