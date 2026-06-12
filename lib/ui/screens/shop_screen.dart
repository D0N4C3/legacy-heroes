import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/services/ad_service.dart';
import '../../state/providers.dart';
import '../widgets/fantasy_button.dart';
import '../widgets/fantasy_modal.dart';

/// Merchant stall (Visual Plan §6 Shop / plan §13 Monetization). Rewarded ads
/// are live; IAP products are stubbed until billing is wired up.
Future<void> showShop(BuildContext context) {
  return showFantasySheet(
    context,
    title: "Merchant's Stall",
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final controller = ref.read(gameControllerProvider.notifier);
        final ads = ref.read(adServiceProvider);

        Future<void> watchForGold() async {
          final ok = await ads.showRewarded(RewardPlacement.dailyBonus);
          if (ok) controller.addGold(500);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('+500 gold from the road merchant!')),
            );
          }
        }

        void comingSoon(String what) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('$what — store billing not configured yet.')),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShopRow(
              icon: Icons.play_circle_fill,
              color: Palette.success,
              title: 'Traveling Merchant',
              subtitle: 'Watch an ad for +500 gold',
              action: FantasyButton(label: 'Watch', compact: true, primary: true, onTap: watchForGold),
            ),
            _ShopRow(
              icon: Icons.diamond,
              color: Palette.gem,
              title: 'Pouch of Gems',
              subtitle: '160 gems',
              action: FantasyButton(label: '\$1.99', compact: true, onTap: () => comingSoon('Gems')),
            ),
            _ShopRow(
              icon: Icons.workspace_premium,
              color: Palette.gold,
              title: 'Royal Dynasty Pass',
              subtitle: 'Bonus rewards & exclusive cosmetics',
              action: FantasyButton(label: '\$4.99', compact: true, onTap: () => comingSoon('Dynasty Pass')),
            ),
            _ShopRow(
              icon: Icons.verified_user,
              color: Palette.danger,
              title: 'Royal Patron Seal',
              subtitle: 'Remove forced ads forever',
              action: FantasyButton(label: '\$2.99', compact: true, onTap: () => comingSoon('Remove Ads')),
            ),
            _ShopRow(
              icon: Icons.hourglass_bottom,
              color: Palette.xp,
              title: 'Offline Extension',
              subtitle: 'Raise offline cap to 12 hours',
              action: FantasyButton(label: '\$1.99', compact: true, onTap: () => comingSoon('Offline Extension')),
            ),
          ],
        );
      },
    ),
  );
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Palette.parchment, Palette.parchmentDark]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.goldDark, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Palette.ink, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Palette.inkSoft, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}
