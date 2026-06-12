import 'package:flutter/material.dart';

import 'palette.dart';

/// App-wide theme. The game screens use bespoke fantasy widgets, so this mainly
/// styles incidental Material chrome (snackbars, dialogs, app bars) to match
/// the warm storybook palette (plan §15).
ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF120A1E),
    colorScheme: base.colorScheme.copyWith(
      primary: Palette.gold,
      secondary: Palette.gem,
      surface: Palette.wood,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.woodDark,
      contentTextStyle: TextStyle(color: Palette.parchment, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Palette.parchment,
      displayColor: Palette.parchment,
    ),
  );
}
