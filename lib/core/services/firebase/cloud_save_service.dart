import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Firestore-backed cloud save (plan §9–§10). Stores the serialized game state
/// under `users/{uid}`. Best-effort: all calls no-op/return null when Firebase
/// isn't configured, so the local save (plan §11) stays the source of truth.
class CloudSaveService {
  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  Future<void> save(String uid, String json) async {
    if (!FirebaseService.instance.ready) return;
    try {
      await _users.doc(uid).set({
        'save': json,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('[cloud] save failed: $e');
    }
  }

  Future<String?> load(String uid) async {
    if (!FirebaseService.instance.ready) return null;
    try {
      final doc = await _users.doc(uid).get();
      return doc.data()?['save'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('[cloud] load failed: $e');
      return null;
    }
  }
}

/// Lightweight bridge so the local [SaveService] can mirror writes to the cloud
/// without the game controller needing to know about Firebase. Wired up in
/// `main()` after anonymous sign-in.
class CloudSync {
  CloudSync._();
  static final CloudSync instance = CloudSync._();

  String? uid;
  CloudSaveService? service;

  bool get enabled => uid != null && service != null;

  void push(String json) {
    if (!enabled) return;
    // Fire-and-forget; failures are swallowed inside the service.
    service!.save(uid!, json);
  }
}
