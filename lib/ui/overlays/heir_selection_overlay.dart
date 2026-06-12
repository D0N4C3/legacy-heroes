import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/services/catalog_service.dart';
import '../../features/family/domain/ancestor.dart';
import '../../game/legacy_game.dart';
import '../../state/providers.dart';
import '../widgets/fantasy_button.dart';
import '../widgets/fantasy_modal.dart';
import '../widgets/hero_portrait.dart';
import '../widgets/trait_seal.dart';

/// The Heir Selection ceremony (plan §6.7 / Visual Plan §6 "Hall of Legacy").
/// Shown over the golden Legacy scene; the player chooses who continues the
/// bloodline. A rewarded ad can bless the heir with extra inherited power.
Future<void> showHeirSelection(BuildContext context, WidgetRef ref, LegacyGame game) {
  game.playLegacyTransition();
  return showFantasySheet(
    context,
    title: 'Continue the Legacy',
    dismissible: false,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final state = ref.watch(gameControllerProvider);
        final controller = ref.read(gameControllerProvider.notifier);
        final parent = state.hero!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${parent.name} has passed on. Choose the heir to carry the family name into Generation ${state.generation + 1}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.ink, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ...state.heirCandidates.map((c) => _HeirCard(
                  candidate: c,
                  onChoose: (bless) async {
                    await controller.selectHeir(c.id, bless: bless);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                )),
          ],
        );
      },
    ),
  );
}

class _HeirCard extends StatelessWidget {
  const _HeirCard({required this.candidate, required this.onChoose});
  final HeirCandidate candidate;
  final Future<void> Function(bool bless) onChoose;

  @override
  Widget build(BuildContext context) {
    final cls = Catalog.instance.classOf(candidate.classId);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Palette.parchment, Palette.parchmentDark]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.goldDark, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              HeroPortrait(color: cls.color, size: 56, highlighted: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate.name,
                        style: const TextStyle(
                            color: Palette.ink, fontWeight: FontWeight.w900, fontSize: 15)),
                    Text('${cls.name} · Inherited Power ${candidate.inheritedPower.round()}',
                        style: TextStyle(color: Palette.inkSoft, fontSize: 12)),
                    if (candidate.heirloomName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 14, color: Palette.goldDark),
                            const SizedBox(width: 4),
                            Text('Inherits ${candidate.heirloomName}',
                                style: const TextStyle(
                                    color: Palette.goldDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (candidate.traitIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: candidate.traitIds.map((t) => TraitSeal(traitId: t)).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FantasyButton(
                  label: 'Choose',
                  compact: true,
                  onTap: () => onChoose(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FantasyButton(
                  label: 'Bless +10% (Ad)',
                  compact: true,
                  primary: true,
                  onTap: () => onChoose(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
