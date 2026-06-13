import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/utils/formatters.dart';
import '../../features/hero/domain/hero.dart';
import '../../state/providers.dart';
import '../screens/equipment_screen.dart';
import '../screens/family_tree_screen.dart';
import '../screens/shop_screen.dart';
import '../widgets/combat_controls.dart';
import '../widgets/hero_portrait.dart';
import '../widgets/resource_counter.dart';
import 'activity_overlay.dart';
import 'daily_overlay.dart';

/// The Flutter HUD layered over the Flame world (Visual Plan §6 Home Screen):
/// floating resources, a hero panel, the current activity status, and a
/// bottom bar of fantasy action icons.
class HomeHud extends ConsumerWidget {
  const HomeHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final hero = state.hero!;
    final controller = ref.read(gameControllerProvider.notifier);
    final canDaily = controller.canClaimDaily;
    final combatActive = ref.watch(combatActiveProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Stack(
        children: [
          // Top cluster: resources + hero panel. Left free so the world
          // (and hero standing in it) stays visible below.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ResourceCounter(icon: Icons.monetization_on, value: state.gold, color: Palette.gold),
                    const SizedBox(width: 8),
                    ResourceCounter(icon: Icons.diamond, value: state.gems, color: Palette.gem),
                    const Spacer(),
                    _PillButton(
                      icon: Icons.menu_book,
                      badge: 'Gen ${state.generation}',
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const FamilyTreeScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _HeroPanel(hero: hero),
              ],
            ),
          ),
          // Bottom dock: activity status + action bar, slimmed down so the
          // hero standing on the new ground line is never covered.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _ActivityStatus(),
                const SizedBox(height: 6),
                _ActionBar(canDaily: canDaily),
              ],
            ),
          ),
          // Combat cluster: floats in the freed-up middle band, only while a
          // dungeon/boss encounter is running (Phase 2).
          if (combatActive)
            const Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(child: CombatControls()),
            ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.hero});
  final HeroData hero;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Palette.woodDark.withValues(alpha: 0.86),
          Palette.wood.withValues(alpha: 0.7),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.goldDark, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroPortrait(classId: hero.classId, size: 58),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hero.name,
                    style: const TextStyle(
                        color: Palette.parchment, fontWeight: FontWeight.w900, fontSize: 15)),
                Text(
                  '${hero.classData.name} · Lv ${hero.level} · Age ${hero.age} · ${hero.stage.label}',
                  style: TextStyle(color: Palette.parchment.withValues(alpha: 0.8), fontSize: 11),
                ),
                const SizedBox(height: 6),
                _XpBar(progress: hero.xpProgress),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flash_on, size: 14, color: Palette.goldLight),
                    const SizedBox(width: 3),
                    Text('Power ${hero.power.round()}',
                        style: const TextStyle(
                            color: Palette.goldLight, fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(height: 9, color: Palette.woodDark),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0).toDouble(),
            child: Container(
              height: 9,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Palette.xp, Color(0xFF8FD3F0)]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStatus extends ConsumerWidget {
  const _ActivityStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final def = ref.watch(activeActivityDefProvider);

    if (def == null || state.currentActivity == null) {
      return const _StatusPill(
        icon: Icons.local_fire_department,
        text: 'Resting at home — gold trickles in',
        color: Palette.gold,
      );
    }

    final endAt = state.currentActivity!.endAt(def);
    final remaining = endAt.difference(DateTime.now());
    final total = def.duration.inSeconds;
    final progress = total == 0 ? 1.0 : 1 - remaining.inSeconds / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Palette.woodDark.withValues(alpha: 0.9), Palette.wood.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(def.name,
                  style: const TextStyle(
                      color: Palette.parchment, fontWeight: FontWeight.w800, fontSize: 12)),
              const Spacer(),
              Text(
                remaining.isNegative ? 'Returning…' : formatDuration(remaining),
                style: const TextStyle(
                    color: Palette.goldLight, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: Palette.woodDark,
              valueColor: const AlwaysStoppedAnimation(Palette.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Palette.woodDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.goldDark, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: TextStyle(color: Palette.parchment.withValues(alpha: 0.9), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.canDaily});
  final bool canDaily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Palette.wood, Palette.woodDark]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.goldDark, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionIcon(
            icon: Icons.explore,
            label: 'Quest',
            highlight: true,
            onTap: () => showActivityBoard(context),
          ),
          _ActionIcon(
            icon: Icons.shield,
            label: 'Gear',
            onTap: () => showEquipment(context),
          ),
          _ActionIcon(
            icon: Icons.account_tree,
            label: 'Family',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FamilyTreeScreen())),
          ),
          _ActionIcon(
            icon: Icons.storefront,
            label: 'Shop',
            onTap: () => showShop(context),
          ),
          _ActionIcon(
            icon: Icons.card_giftcard,
            label: 'Daily',
            badge: canDaily,
            onTap: () => showDailyReward(context),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    (highlight ? Palette.gold : Palette.parchmentShadow).withValues(alpha: 0.9),
                    Palette.woodDark,
                  ]),
                  border: Border.all(
                      color: highlight ? Palette.goldLight : Palette.goldDark, width: 1.5),
                ),
                child: Icon(icon, color: Palette.parchment, size: 20),
              ),
              if (badge)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Palette.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Palette.parchment, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Palette.parchment, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.badge, required this.onTap});
  final IconData icon;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.woodDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.goldDark, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Palette.goldLight),
            const SizedBox(width: 6),
            Text(badge,
                style: const TextStyle(
                    color: Palette.parchment, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
