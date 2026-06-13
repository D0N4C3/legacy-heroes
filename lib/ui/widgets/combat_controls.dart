import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../features/combat/domain/combat_state.dart';
import '../../state/providers.dart';

/// Phase 2 combat mini-game controls: Run Forward / Attack / Auto toggle.
/// Rendered as a vertical cluster on the right edge of the screen, only while
/// [combatActiveProvider] is true (dungeon/boss scenes). The existing
/// timer-based activity economy is untouched — these just drive the
/// real-time mini-game layered on top.
class CombatControls extends ConsumerWidget {
  const CombatControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combat = ref.watch(combatControllerProvider);
    final controller = ref.read(combatControllerProvider.notifier);

    final canRunForward = !combat.autoMode &&
        (combat.phase == CombatPhase.approaching ||
            combat.phase == CombatPhase.enemyDefeated);
    final canAttack = !combat.autoMode && combat.phase == CombatPhase.engaged;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CombatButton(
          icon: Icons.directions_run,
          label: 'Run',
          enabled: canRunForward,
          onTap: controller.runForward,
        ),
        const SizedBox(height: 10),
        _CombatButton(
          icon: Icons.gavel,
          label: 'Attack',
          highlight: true,
          enabled: canAttack,
          onTap: controller.attack,
        ),
        const SizedBox(height: 10),
        _AutoToggle(active: combat.autoMode, onTap: controller.toggleAuto),
      ],
    );
  }
}

class _CombatButton extends StatelessWidget {
  const _CombatButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  (highlight ? Palette.gold : Palette.parchmentShadow).withValues(alpha: 0.9),
                  Palette.woodDark,
                ]),
                border: Border.all(
                    color: highlight ? Palette.goldLight : Palette.goldDark, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(icon, color: Palette.parchment, size: 26),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    color: Palette.parchment, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _AutoToggle extends StatelessWidget {
  const _AutoToggle({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (active ? Palette.success : Palette.woodDark).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Palette.success : Palette.goldDark, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? Icons.smart_toy : Icons.touch_app, color: Palette.parchment, size: 16),
            const SizedBox(width: 6),
            Text(active ? 'Auto' : 'Manual',
                style: const TextStyle(
                    color: Palette.parchment, fontWeight: FontWeight.w800, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
