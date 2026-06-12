import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/constants/game_constants.dart';
import '../../state/providers.dart';
import '../widgets/fantasy_button.dart';
import '../widgets/fantasy_modal.dart';

/// Daily reward calendar (plan §6.9) — a key retention loop.
Future<void> showDailyReward(BuildContext context) {
  return showFantasySheet(
    context,
    title: 'Daily Blessing',
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final state = ref.watch(gameControllerProvider);
        final controller = ref.read(gameControllerProvider.notifier);
        final canClaim = controller.canClaimDaily;
        final todayIndex = state.dailyStreak % GameConstants.dailyRewards.length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Return each day to grow your dynasty.',
                style: TextStyle(color: Palette.inkSoft, fontSize: 12)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(GameConstants.dailyRewards.length, (i) {
                final reward = GameConstants.dailyRewards[i];
                final claimed = i < todayIndex || (i == todayIndex && !canClaim);
                final isToday = i == todayIndex && canClaim;
                final gems = (reward['gems'] ?? 0) > 0;
                return Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: claimed ? Palette.parchmentShadow.withOpacity(0.4) : Palette.woodDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday ? Palette.goldLight : Palette.goldDark,
                      width: isToday ? 3 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('Day ${i + 1}',
                          style: const TextStyle(
                              color: Palette.parchment, fontWeight: FontWeight.w700, fontSize: 11)),
                      const SizedBox(height: 6),
                      Icon(gems ? Icons.diamond : Icons.monetization_on,
                          color: gems ? Palette.gem : Palette.gold, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        gems ? '${reward['gems']}' : '${reward['gold']}',
                        style: const TextStyle(
                            color: Palette.parchment, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      if (claimed)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle, color: Palette.success, size: 14),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            FantasyButton(
              label: canClaim ? 'Claim Daily Blessing' : 'Come Back Tomorrow',
              icon: Icons.card_giftcard,
              primary: true,
              enabled: canClaim,
              onTap: () {
                controller.claimDaily();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}
