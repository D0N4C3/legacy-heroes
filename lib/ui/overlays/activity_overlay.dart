import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../state/providers.dart';
import '../widgets/fantasy_modal.dart';
import '../widgets/quest_card.dart';

/// The quest board (Visual Plan §6 "fantasy map / quest board"). Picking a
/// quest sends the hero off and the world swaps to that scene.
Future<void> showActivityBoard(BuildContext context) {
  return showFantasySheet(
    context,
    title: 'Quest Board',
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final activities = ref.watch(activitiesProvider);
        final state = ref.watch(gameControllerProvider);
        final hero = state.hero!;
        final controller = ref.read(gameControllerProvider.notifier);
        final runningId = state.currentActivity?.activityId;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Send ${hero.name.split(' ').first} on an adventure. Rewards arrive even while you are away.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.inkSoft, fontSize: 12),
              ),
            ),
            ...activities.map((a) {
              final running = a.id == runningId;
              Duration? remaining;
              if (running && state.currentActivity != null) {
                remaining = state.currentActivity!.endAt(a).difference(DateTime.now());
              }
              return QuestCard(
                activity: a,
                heroPower: hero.power,
                running: running,
                remaining: remaining,
                onTap: () {
                  controller.startActivity(a.id);
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        );
      },
    ),
  );
}
