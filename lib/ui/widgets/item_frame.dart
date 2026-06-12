import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../features/equipment/domain/equipment.dart';

/// A rarity-framed equipment icon (Visual Plan §6 Equipment / §8). Heirlooms
/// get a glowing legendary frame.
class ItemFrame extends StatelessWidget {
  const ItemFrame({
    super.key,
    this.item,
    this.slot,
    this.size = 56,
    this.onTap,
    this.selected = false,
  });

  final EquipmentItem? item;
  final EquipSlot? slot; // shown when empty
  final double size;
  final VoidCallback? onTap;
  final bool selected;

  static const _slotIcons = {
    EquipSlot.weapon: Icons.gavel,
    EquipSlot.armor: Icons.shield,
    EquipSlot.helmet: Icons.sports_motorsports,
    EquipSlot.ring: Icons.circle_outlined,
    EquipSlot.amulet: Icons.diamond,
    EquipSlot.boots: Icons.ice_skating,
    EquipSlot.heirloom: Icons.auto_awesome,
  };

  @override
  Widget build(BuildContext context) {
    final rarity = item != null ? Palette.rarityColor(item!.tier) : Palette.parchmentShadow;
    final glow = item?.isHeirloom ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [rarity.withOpacity(0.4), Palette.woodDark]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Palette.goldLight : rarity,
            width: selected ? 3 : 2,
          ),
          boxShadow: glow
              ? [BoxShadow(color: rarity.withOpacity(0.7), blurRadius: 10)]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _slotIcons[item?.slot ?? slot] ?? Icons.help_outline,
              color: item != null ? Palette.parchment : Palette.parchmentShadow,
              size: size * 0.42,
            ),
            if (item != null)
              Positioned(
                bottom: 2,
                right: 4,
                child: Text(
                  '+${item!.power}',
                  style: TextStyle(
                    color: rarity == Palette.gold ? Palette.goldLight : Palette.parchment,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.18,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
