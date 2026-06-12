import '../../../core/constants/game_constants.dart';
import '../../../core/services/catalog_service.dart';
import '../../../core/utils/rng.dart';
import '../../equipment/data/loot_factory.dart';
import '../../equipment/domain/equipment.dart';
import '../../family/domain/ancestor.dart';
import '../domain/hero.dart';
import '../domain/hero_class.dart';
import '../domain/life_stage.dart';
import 'name_pools.dart';

/// Creates heroes: the founding hero and heirs of later generations (plan §3).
class HeroFactory {
  HeroFactory._();

  static String _fullName() =>
      '${pick(NamePools.firstNames)} ${pick(NamePools.epithets)}';

  /// The very first hero of a new dynasty (Generation 1).
  static HeroData createFounder({String? familyName}) {
    final cls = pick(Catalog.instance.classList);
    final positiveTraits =
        Catalog.instance.traitList.where((t) => t.positive).toList();
    final starterTrait = pick(positiveTraits).id;

    return HeroData(
      id: genId('hero'),
      name: _fullName(),
      classId: cls.id,
      generation: 1,
      level: 1,
      xp: 0,
      age: GameConstants.heroStartAge,
      stats: cls.base,
      traitIds: [starterTrait],
      equipment: {EquipSlot.weapon: LootFactory.starterWeapon()},
      achievements: const [],
      bornAt: DateTime.now(),
      stage: LifeStage.young,
    );
  }

  /// Produce 2–3 heir candidates from the retiring/fallen parent (plan §6.7).
  static List<HeirCandidate> generateHeirs(HeroData parent) {
    final count = randInt(2, 3);
    final inheritPct = GameConstants.baseInheritance +
        Catalog.instance.traitInheritBonus(parent.traitIds);
    final inheritablePool =
        parent.traitIds.where((id) => Catalog.instance.traitOf(id)?.inheritable ?? false);

    // Does an heirloom get passed down this generation?
    final heirloom = parent.equipment[EquipSlot.heirloom];

    return List.generate(count, (i) {
      final cls = pick(Catalog.instance.classList);
      // Each heir inherits a subset of inheritable traits, sometimes a new one.
      final traits = <String>{...inheritablePool.where((_) => chance(0.7))};
      if (chance(0.5) || traits.isEmpty) {
        traits.add(pick(Catalog.instance.traitList.where((t) => t.positive).toList()).id);
      }
      final inheritedPower = parent.power * inheritPct;
      return HeirCandidate(
        id: genId('hero'),
        name: _fullName(),
        classId: cls.id,
        inheritedPower: inheritedPower,
        traitIds: traits.toList(),
        // Eldest candidate carries the heirloom forward.
        heirloomName: (i == 0) ? heirloom?.name : null,
      );
    });
  }

  /// Turn the chosen candidate into the next playable hero.
  ///
  /// [blessingBonus] is an additive inheritance multiplier from a rewarded ad
  /// or premium altar (plan §4.5 / §7).
  static HeroData materializeHeir({
    required HeirCandidate candidate,
    required HeroData parent,
    required int generation,
    EquipmentItem? heirloom,
    double blessingBonus = 0,
  }) {
    final cls = Catalog.instance.classOf(candidate.classId);
    final legacy = candidate.inheritedPower + parent.power * blessingBonus;

    final equip = <EquipSlot, EquipmentItem>{
      EquipSlot.weapon: LootFactory.starterWeapon(),
    };
    if (heirloom != null) equip[EquipSlot.heirloom] = heirloom;

    return HeroData(
      id: candidate.id,
      name: candidate.name,
      classId: cls.id,
      generation: generation,
      level: 1,
      xp: 0,
      age: GameConstants.heroStartAge,
      stats: cls.base,
      traitIds: candidate.traitIds,
      equipment: equip,
      achievements: const [],
      bornAt: DateTime.now(),
      stage: LifeStage.young,
      parentId: parent.id,
      legacyBonus: legacy,
    );
  }

  /// Snapshot the outgoing hero as a permanent dynasty record (§3C).
  static AncestorRecord toAncestor(
    HeroData hero, {
    required bool retired,
    required String cause,
  }) {
    final achievement = hero.achievements.isNotEmpty
        ? hero.achievements.last
        : 'Began the family legacy';
    final heirloom = hero.equipment[EquipSlot.heirloom];
    return AncestorRecord(
      id: hero.id,
      name: hero.name,
      classId: hero.classId,
      generation: hero.generation,
      level: hero.level,
      bornAtAge: GameConstants.heroStartAge,
      diedAtAge: hero.age,
      retired: retired,
      causeOfEnd: cause,
      biggestAchievement: achievement,
      traitIds: hero.traitIds,
      childrenIds: hero.childrenIds,
      parentId: hero.parentId,
      heirloomName: heirloom?.name,
    );
  }
}
