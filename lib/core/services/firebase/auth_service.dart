import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Anonymous-first auth (plan §9). Google / Apple sign-in can be layered on
/// later by upgrading the anonymous credential.
class AuthService {
  String? get uid =>
      FirebaseService.instance.ready ? FirebaseAuth.instance.currentUser?.uid : null;

  Future<String?> signInAnonymously() async {
    if (!FirebaseService.instance.ready) return null;
    try {
      final existing = FirebaseAuth.instance.currentUser;
      if (existing != null) return existing.uid;
      final cred = await FirebaseAuth.instance.signInAnonymously();
      return cred.user?.uid;
    } catch (e) {
      if (kDebugMode) debugPrint('[auth] anonymous sign-in failed: $e');
      return null;
    }
  }
}
