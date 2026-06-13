import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../features/equipment/domain/equipment.dart';
import '../../state/game_controller.dart';
import '../../state/providers.dart';
import '../widgets/fantasy_modal.dart';
import '../widgets/hero_portrait.dart';
import '../widgets/item_frame.dart';

/// The armory (Visual Plan §6 Equipment): hero preview ringed by slots, with a
/// leather-bag inventory grid below. Tap to equip / unequip.
Future<void> showEquipment(BuildContext context) {
  return showFantasySheet(
    context,
    title: 'Armory',
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final state = ref.watch(gameControllerProvider);
        final hero = state.hero!;
        final controller = ref.read(gameControllerProvider.notifier);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero + equipped slots.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  _slot(hero.equipment[EquipSlot.weapon], EquipSlot.weapon, controller),
                  const SizedBox(height: 8),
                  _slot(hero.equipment[EquipSlot.armor], EquipSlot.armor, controller),
                  const SizedBox(height: 8),
                  _slot(hero.equipment[EquipSlot.boots], EquipSlot.boots, controller),
                ]),
                const SizedBox(width: 16),
                Column(children: [
                  HeroPortrait(classId: hero.classId, size: 96),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Palette.woodDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Palette.gold, width: 1.5),
                    ),
                    child: Text('Power ${hero.power.round()}',
                        style: const TextStyle(
                            color: Palette.goldLight, fontWeight: FontWeight.w900)),
                  ),
                ]),
                const SizedBox(width: 16),
                Column(children: [
                  _slot(hero.equipment[EquipSlot.helmet], EquipSlot.helmet, controller),
                  const SizedBox(height: 8),
                  _slot(hero.equipment[EquipSlot.amulet], EquipSlot.amulet, controller),
                  const SizedBox(height: 8),
                  _slot(hero.equipment[EquipSlot.ring], EquipSlot.ring, controller),
                ]),
              ],
            ),
            const SizedBox(height: 6),
            _slot(hero.equipment[EquipSlot.heirloom], EquipSlot.heirloom, controller),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Inventory',
                  style: TextStyle(
                      color: Palette.inkSoft, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Palette.wood.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.parchmentShadow, width: 1.5),
              ),
              child: state.inventory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('No loose gear. Send your hero questing!',
                          style: TextStyle(color: Palette.inkSoft, fontSize: 12)),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.inventory
                          .map((e) => ItemFrame(
                                item: e,
                                size: 50,
                                onTap: () => controller.equip(e),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 4),
            Text('Tap a slot to unequip · tap inventory to equip',
                style: TextStyle(color: Palette.inkSoft.withValues(alpha: 0.7), fontSize: 10)),
          ],
        );
      },
    ),
  );
}

Widget _slot(EquipmentItem? item, EquipSlot slot, GameController controller) {
  return ItemFrame(
    item: item,
    slot: slot,
    size: 52,
    onTap: item == null ? null : () => controller.unequip(slot),
  );
}
