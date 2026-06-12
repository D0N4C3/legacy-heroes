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

  /// Roll a random item at the given rarity [tier] (1..4).
  static EquipmentItem roll(int tier) {
    final pools = Catalog.instance.itemPools;
    final slot = pick(_slotPools.keys.toList());
    final base = pick((pools[_slotPools[slot]] as List).cast<String>());
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

  /// Starter weapon for a brand-new hero so they aren't naked.
  static EquipmentItem starterWeapon() => EquipmentItem(
        id: genId('item'),
        name: 'Rusty Sword',
        slot: EquipSlot.weapon,
        tier: 1,
        power: 5,
      );
}
