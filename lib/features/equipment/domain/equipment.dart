/// Equipment slots (plan §6.5).
enum EquipSlot {
  weapon('Weapon'),
  armor('Armor'),
  helmet('Helmet'),
  ring('Ring'),
  amulet('Amulet'),
  boots('Boots'),
  heirloom('Heirloom');

  const EquipSlot(this.label);
  final String label;
}

/// A concrete equipment instance owned by the player.
class EquipmentItem {
  final String id;
  final String name;
  final EquipSlot slot;
  final int tier; // 1..5 rarity (see Palette.rarityColor)
  final int power;
  final bool isHeirloom;

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.tier,
    required this.power,
    this.isHeirloom = false,
  });

  EquipmentItem copyWith({bool? isHeirloom}) => EquipmentItem(
        id: id,
        name: name,
        slot: slot,
        tier: tier,
        power: power,
        isHeirloom: isHeirloom ?? this.isHeirloom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slot': slot.name,
        'tier': tier,
        'power': power,
        'isHeirloom': isHeirloom,
      };

  factory EquipmentItem.fromJson(Map<String, dynamic> j) => EquipmentItem(
        id: j['id'],
        name: j['name'],
        slot: EquipSlot.values.byName(j['slot']),
        tier: j['tier'],
        power: j['power'],
        isHeirloom: j['isHeirloom'] ?? false,
      );
}
