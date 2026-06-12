import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/utils/formatters.dart';
import '../../game/legacy_game.dart';
import '../../state/providers.dart';
import '../widgets/fantasy_button.dart';
import '../widgets/fantasy_modal.dart';

/// "You earned X while away — watch to double?" (plan §4.1, the strongest
/// rewarded-ad placement). Gold is already credited; the ad adds the same again.
Future<void> showOfflineReport(BuildContext context, WidgetRef ref, LegacyGame game) {
  final report = ref.read(gameControllerProvider).offlineReport;
  if (report == null) return Future.value();
  final controller = ref.read(gameControllerProvider.notifier);

  return showFantasyDialog(
    context,
    title: 'Welcome Back',
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wb_twilight, size: 50, color: Palette.gold),
        const SizedBox(height: 8),
        Text(
          'Your family kept working while you were away for '
          '${formatDuration(report.awayFor)}'
          '${report.capped ? ' (reward capped)' : ''}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Palette.ink, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Text('+${formatCompact(report.gold)}',
            style: const TextStyle(
                color: Palette.goldDark, fontWeight: FontWeight.w900, fontSize: 30)),
        const Text('gold', style: TextStyle(color: Palette.inkSoft)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FantasyButton(
                label: 'Claim',
                icon: Icons.check,
                onTap: () {
                  controller.dismissOfflineReport();
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FantasyButton(
                label: 'Double (Ad)',
                icon: Icons.play_circle_fill,
                primary: true,
                onTap: () async {
                  game.showGoldBurst();
                  await controller.claimDoubleOffline();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
