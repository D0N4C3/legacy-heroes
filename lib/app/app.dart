import 'package:flutter/material.dart';

import '../ui/screens/home_screen.dart';
import 'theme.dart';

/// Root widget. The home screen is the full-screen Flame world; other screens
/// are reached via Navigator routes pushed from the HUD.
class LegacyHeroesApp extends StatelessWidget {
  const LegacyHeroesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legacy Heroes',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
