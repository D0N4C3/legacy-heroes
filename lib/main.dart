import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/catalog_service.dart';

/// Legacy Heroes — a semi-AFK generational idle RPG (Flutter + Flame).
///
/// Boot order:
///   1. Bind the engine.
///   2. Lock to portrait (mobile-first idle game).
///   3. Load static game data (classes, traits, activities, item pools).
///   4. Run the app inside a Riverpod scope.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  // AdMob note: to enable real rewarded ads, initialize MobileAds here and
  // swap adServiceProvider for a real implementation (see README).

  await Catalog.instance.load();

  runApp(const ProviderScope(child: LegacyHeroesApp()));
}
