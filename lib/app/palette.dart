import 'package:flutter/material.dart';

/// Warm, premium, storybook-fantasy palette (plan §15 / Visual Plan §1).
/// No plain whites — every surface is parchment, wood, or twilight.
class Palette {
  Palette._();

  // Parchment & wood (diegetic UI surfaces)
  static const Color parchment = Color(0xFFEAD7AE);
  static const Color parchmentDark = Color(0xFFD8BE86);
  static const Color parchmentShadow = Color(0xFF8A6B3B);
  static const Color wood = Color(0xFF5A3D24);
  static const Color woodDark = Color(0xFF3A2615);

  // Gold / accents
  static const Color gold = Color(0xFFE7B53C);
  static const Color goldLight = Color(0xFFFBE08A);
  static const Color goldDark = Color(0xFFB07E1E);

  // Twilight sky (village scene)
  static const Color skyTop = Color(0xFF3A2A5A);
  static const Color skyMid = Color(0xFF8A4E6E);
  static const Color skyHorizon = Color(0xFFE9925A);

  // Ink / text
  static const Color ink = Color(0xFF3A2615);
  static const Color inkSoft = Color(0xFF5C4530);

  // Status
  static const Color hp = Color(0xFFC0492B);
  static const Color xp = Color(0xFF3FA7D6);
  static const Color gem = Color(0xFF7E5BD8);
  static const Color success = Color(0xFF4E944F);
  static const Color danger = Color(0xFFB23A3A);

  // Rarity tints (items / traits)
  static const List<Color> rarity = [
    Color(0xFF9E9E9E), // common  (tier 1)
    Color(0xFF4E944F), // uncommon(tier 2)
    Color(0xFF3FA7D6), // rare    (tier 3)
    Color(0xFF9B59B6), // epic    (tier 4)
    Color(0xFFE7B53C), // legendary/heirloom
  ];

  static Color rarityColor(int tier) =>
      rarity[tier.clamp(1, rarity.length).toInt() - 1];
}
