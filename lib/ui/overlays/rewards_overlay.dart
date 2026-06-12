import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/utils/formatters.dart';
import '../../game/legacy_game.dart';
import '../../state/providers.dart';
import '../widgets/fantasy_button.dart';
import '../widgets/fantasy_modal.dart';
import '../widgets/item_frame.dart';

/// The reward reveal after an activity (Visual Plan §6 Rewards / plan §4.1
/// "watch ad to double"). Satisfying: chest, gold burst, loot cards.
Future<void> showRewards(BuildContext context, WidgetRef ref, LegacyGame game) {
  final result = ref.read(gameControllerProvider).pendingResult;
  if (result == null) return Future.value();
  final controller = ref.read(gameControllerProvider.notifier);
  final survived = result.survived;

  return showFantasyDialog(
    context,
    title: survived ? 'Spoils of the Journey' : 'A Hero Falls',
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                survived ? Icons.inventory_2 : Icons.local_florist,
                size: 54,
                color: survived ? Palette.gold : Palette.danger,
              ),
              const SizedBox(height: 10),
              if (result.storyEvent != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(result.storyEvent!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Palette.ink, fontStyle: FontStyle.italic, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              _RewardRow(icon: Icons.monetization_on, color: Palette.gold, label: 'Gold', value: '+${formatCompact(result.gold)}'),
              _RewardRow(icon: Icons.star, color: Palette.xp, label: 'XP', value: '+${formatCompact(result.xp)}'),
              if (result.loot.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Loot found',
                    style: TextStyle(color: Palette.inkSoft, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: result.loot.map((e) => ItemFrame(item: e, size: 48)).toList(),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FantasyButton(
                      label: 'Collect',
                      icon: Icons.check,
                      onTap: () {
                        game.showGoldBurst();
                        controller.collectRewards();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                  if (survived) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FantasyButton(
                        label: 'Double (Ad)',
                        icon: Icons.play_circle_fill,
                        primary: true,
                        onTap: () async {
                          game.showGoldBurst();
                          await controller.collectRewards(useAd: true);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Palette.ink, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}
