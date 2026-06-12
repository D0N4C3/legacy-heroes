import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Boots Firebase, tolerating the "not configured yet" state.
///
/// [Firebase.initializeApp] needs platform config (google-services.json /
/// GoogleService-Info.plist, or a generated `firebase_options.dart`). Until you
/// run `flutterfire configure`, init throws — we swallow it and run the game
/// fully local-only. Once configured, Auth / Firestore / Analytics / Crashlytics
/// light up automatically (plan §9).
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool ready = false;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      ready = true;
      if (kDebugMode) debugPrint('[firebase] initialized');
    } catch (e) {
      ready = false;
      if (kDebugMode) {
        debugPrint('[firebase] not configured — running local-only. ($e)');
      }
    }
  }
}
