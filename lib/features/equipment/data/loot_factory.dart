import '../../../core/services/catalog_service.dart';
import '../../../core/utils/rng.dart';
import '../domain/equipment.dart';

/// Generates equipment drops and heirlooms from the item name pools.
class LootFactory {
  LootFactory._();

  static const _slotPools = {
    EquipSlot.weapon: 'weapons',
    EquipSlot.armor: 'armor',
    EquipSlot.helmet: 'helmets',
    EquipSlot.ring: 'rings',
    EquipSlot.amulet: 'amulets',
    EquipSlot.boots: 'boots',
  };

  static const _classFallbackWeapon = {
    'warrior': 'Longsword',
    'ranger': 'Hunting Bow',
    'mage': 'Oak Staff',
    'paladin': 'Holy Mace',
    'blacksmith': 'Forge Hammer',
  };

  /// Pull a class-flavoured name list out of [items.json] (e.g. classWeapons),
  /// falling back gracefully if the pool is missing.
  static List<String> _classPool(String poolKey, String classId) {
    final pools = Catalog.instance.itemPools;
    final group = pools[poolKey];
    if (group is Map && group[classId] is List) {
      return (group[classId] as List).cast<String>();
    }
    return const [];
  }

  /// Roll a random item at the given rarity [tier] (1..4). When [classId] is
  /// given, weapons and armor are biased toward that class's gear so loot feels
  /// like it belongs to the hero (plan §3A class identity, §6.5 equipment).
  static EquipmentItem roll(int tier, {String? classId}) {
    final pools = Catalog.instance.itemPools;
    final slot = pick(_slotPools.keys.toList());

    String base;
    if (slot == EquipSlot.weapon && classId != null) {
      final cw = _classPool('classWeapons', classId);
      base = (cw.isNotEmpty && chance(0.75))
          ? pick(cw)
          : pick((pools['weapons'] as List).cast<String>());
    } else if (slot == EquipSlot.armor && classId != null) {
      final ca = _classPool('classArmor', classId);
      base = (ca.isNotEmpty && chance(0.5))
          ? pick(ca)
          : pick((pools['armor'] as List).cast<String>());
    } else {
      base = pick((pools[_slotPools[slot]] as List).cast<String>());
    }

    final prefixes = (pools['prefixes'] as List).cast<String>();
    // Higher tiers pull from stronger prefixes.
    final pIndex = (randInt(0, prefixes.length - 1) + tier)
        .clamp(0, prefixes.length - 1)
        .toInt();
    final prefix = prefixes[pIndex];
    final power = tier * randInt(6, 12) + randInt(0, 4);
    return EquipmentItem(
      id: genId('item'),
      name: '$prefix $base',
      slot: slot,
      tier: tier,
      power: power,
    );
  }

  /// Forge a unique heirloom that can be passed down the bloodline (§3B).
  static EquipmentItem heirloom(int generation) {
    final pools = Catalog.instance.itemPools;
    final name = pick((pools['heirlooms'] as List).cast<String>());
    return EquipmentItem(
      id: genId('heir'),
      name: name,
      slot: EquipSlot.heirloom,
      tier: 5,
      power: 25 + generation * 8 + randInt(0, 15),
      isHeirloom: true,
    );
  }

  /// Starter weapon for a brand-new hero so they aren't naked. Matches the
  /// hero's class so a Mage opens with a staff, a Ranger with a bow, etc.
  static EquipmentItem starterWeapon([String? classId]) {
    final base = _classFallbackWeapon[classId] ?? 'Sword';
    return EquipmentItem(
      id: genId('item'),
      name: 'Worn $base',
      slot: EquipSlot.weapon,
      tier: 1,
      power: 5,
    );
  }
}
