import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../core/services/catalog_service.dart';

/// A magical wax-seal chip representing a hero trait (Visual Plan §8 / §6.7).
class TraitSeal extends StatelessWidget {
  const TraitSeal({super.key, required this.traitId, this.large = false});

  final String traitId;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final trait = Catalog.instance.traitOf(traitId);
    if (trait == null) return const SizedBox.shrink();
    final positive = trait.positive;
    final seal = positive ? Palette.gem : Palette.danger;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 9, vertical: large ? 7 : 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [seal.withValues(alpha: 0.9), seal.withValues(alpha: 0.6)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: positive ? Palette.goldLight : Palette.parchment, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.auto_awesome : Icons.dangerous,
              size: large ? 16 : 13, color: Palette.parchment),
          const SizedBox(width: 5),
          Text(
            trait.name,
            style: TextStyle(
              color: Palette.parchment,
              fontWeight: FontWeight.w700,
              fontSize: large ? 13 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
