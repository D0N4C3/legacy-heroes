import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../features/activities/domain/activity.dart';
import '../../core/utils/formatters.dart';

/// An illustrated quest-board card for an activity (Visual Plan §6 "fantasy
/// map / quest board"). Shows duration, risk skulls, reward hint and the
/// hero's success chance against the recommended power.
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.activity,
    required this.heroPower,
    required this.onTap,
    this.running = false,
    this.remaining,
  });

  final ActivityDef activity;
  final double heroPower;
  final VoidCallback onTap;
  final bool running;
  final Duration? remaining;

  double get _successChance =>
      (heroPower / activity.recommendedPower).clamp(0.15, 0.99).toDouble();

  @override
  Widget build(BuildContext context) {
    final chancePct = (_successChance * 100).round();
    final chanceColor = _successChance > 0.8
        ? Palette.success
        : _successChance > 0.5
            ? Palette.gold
            : Palette.danger;

    return GestureDetector(
      onTap: running ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: running
                ? [Palette.goldDark, Palette.wood]
                : [const Color(0xFF6B4A2C), Palette.woodDark],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: running ? Palette.goldLight : Palette.goldDark, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _SceneBadge(activity: activity),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.name,
                        style: const TextStyle(
                            color: Palette.parchment,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(activity.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Palette.parchment.withValues(alpha: 0.75), fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _chip(Icons.schedule, '${activity.durationMinutes}m'),
                        const SizedBox(width: 6),
                        _skulls(activity.risk),
                        const Spacer(),
                        if (running && remaining != null)
                          Text(formatDuration(remaining!),
                              style: const TextStyle(
                                  color: Palette.goldLight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13))
                        else
                          Text('$chancePct%',
                              style: TextStyle(
                                  color: chanceColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Palette.parchment.withValues(alpha: 0.8)),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(color: Palette.parchment.withValues(alpha: 0.85), fontSize: 11)),
        ],
      );

  Widget _skulls(RiskLevel risk) {
    if (risk.skulls == 0) {
      return Text('Safe',
          style: TextStyle(color: Palette.success.withValues(alpha: 0.9), fontSize: 11));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        risk.skulls,
        (_) => const Icon(Icons.dangerous, size: 13, color: Palette.danger),
      ),
    );
  }
}

class _SceneBadge extends StatelessWidget {
  const _SceneBadge({required this.activity});
  final ActivityDef activity;

  @override
  Widget build(BuildContext context) {
    final icon = switch (activity.scene.name) {
      'training' => Icons.fitness_center,
      'dungeon' => Icons.castle,
      'boss' => Icons.local_fire_department,
      _ => Icons.forest,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Palette.woodDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.gold, width: 1.5),
      ),
      child: Icon(icon, color: Palette.goldLight, size: 26),
    );
  }
}
