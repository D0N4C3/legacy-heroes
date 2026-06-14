import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/catalog_service.dart';
import 'core/services/firebase/auth_service.dart';
import 'core/services/firebase/cloud_save_service.dart';
import 'core/services/firebase/firebase_service.dart';

/// Legacy Heroes — a semi-AFK generational idle RPG (Flutter + Flame).
///
/// Boot order:
///   1. Bind the engine.
///   2. Lock to portrait (mobile-first idle game).
///   3. Init Firebase (no-op until configured), wire Crashlytics + cloud save.
///   4. Load static game data (classes, traits, activities, item pools).
///   5. Run the app inside a Riverpod scope.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  await FirebaseService.instance.init();
  if (FirebaseService.instance.ready) {
    // Send uncaught Flutter errors to Crashlytics (plan §9).
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    // Also catch errors outside the Flutter framework (async callbacks, zones).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Anonymous sign-in, then enable cloud-save mirroring (plan §9 / §10).
    final uid = await AuthService().signInAnonymously();
    if (uid != null) {
      CloudSync.instance
        ..uid = uid
        ..service = CloudSaveService();
    }
  }

  // AdMob note: to enable real rewarded ads, uncomment google_mobile_ads in
  // pubspec, initialize MobileAds here, and swap adServiceProvider (see README).

  await Catalog.instance.load();

  runApp(const ProviderScope(child: LegacyHeroesApp()));
}
