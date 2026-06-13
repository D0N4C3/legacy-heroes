import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/services/catalog_service.dart';
import '../../features/family/domain/ancestor.dart';
import '../../features/hero/domain/hero.dart';
import '../../state/providers.dart';
import '../widgets/hero_portrait.dart';
import '../widgets/trait_seal.dart';

/// The Family Tree (plan §3C / Visual Plan §6) — the emotional heart. Ancestors
/// live forever as golden memorial portraits; the current hero glows at the top.
class FamilyTreeScreen extends ConsumerWidget {
  const FamilyTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final hero = state.hero!;
    final ancestors = [...state.familyTree]..sort((a, b) => b.generation.compareTo(a.generation));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1E12), Color(0xFF4A341C), Color(0xFF1A120A)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Palette.goldLight),
          title: const Text('The Bloodline',
              style: TextStyle(
                  color: Palette.goldLight, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _CurrentHeroCard(hero: hero),
            if (ancestors.isNotEmpty) ...[
              const SizedBox(height: 18),
              Center(
                child: Text('— Ancestors —',
                    style: TextStyle(
                        color: Palette.parchment.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ),
              const SizedBox(height: 12),
              ...ancestors.map((a) => _AncestorCard(record: a)),
            ] else ...[
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Your dynasty begins here.\nOne day, ${hero.name.split(' ').first}\nwill be remembered on this tree.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.parchment.withValues(alpha: 0.7), height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentHeroCard extends StatelessWidget {
  const _CurrentHeroCard({required this.hero});
  final HeroData hero;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Palette.gold.withValues(alpha: 0.25), Palette.woodDark]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.goldLight, width: 2.5),
        boxShadow: [BoxShadow(color: Palette.goldLight.withValues(alpha: 0.3), blurRadius: 16)],
      ),
      child: Row(
        children: [
          HeroPortrait(classId: hero.classId, size: 76, highlighted: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CURRENT HEAD OF FAMILY',
                    style: TextStyle(
                        color: Palette.goldLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text(hero.name,
                    style: const TextStyle(
                        color: Palette.parchment, fontWeight: FontWeight.w900, fontSize: 18)),
                Text('Generation ${hero.generation} ${hero.classData.name} · Lv ${hero.level} · Age ${hero.age}',
                    style: TextStyle(color: Palette.parchment.withValues(alpha: 0.8), fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: hero.traitIds.map((t) => TraitSeal(traitId: t)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AncestorCard extends StatelessWidget {
  const _AncestorCard({required this.record});
  final AncestorRecord record;

  @override
  Widget build(BuildContext context) {
    final cls = Catalog.instance.classOf(record.classId);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.woodDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.gold.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroPortrait(classId: record.classId, size: 60, memorial: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(record.name,
                          style: const TextStyle(
                              color: Palette.parchment, fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                    Icon(record.retired ? Icons.self_improvement : Icons.local_florist,
                        size: 16, color: Palette.gold),
                  ],
                ),
                Text('Generation ${record.generation} ${cls.name} · Lv ${record.level}',
                    style: TextStyle(color: Palette.parchment.withValues(alpha: 0.75), fontSize: 11)),
                Text('${record.lifespan} · ${record.causeOfEnd}',
                    style: TextStyle(color: Palette.parchment.withValues(alpha: 0.6), fontSize: 11)),
                const SizedBox(height: 4),
                Text('“${record.biggestAchievement}”',
                    style: const TextStyle(
                        color: Palette.goldLight, fontStyle: FontStyle.italic, fontSize: 12)),
                if (record.heirloomName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 13, color: Palette.goldLight),
                        const SizedBox(width: 4),
                        Text('Passed down: ${record.heirloomName}',
                            style: const TextStyle(
                                color: Palette.goldLight, fontWeight: FontWeight.w700, fontSize: 11)),
                      ],
                    ),
                  ),
                if (record.traitIds.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: record.traitIds.map((t) => TraitSeal(traitId: t)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
