import 'package:flutter/foundation.dart';

/// Lightweight analytics seam (plan §9 Firebase Analytics events).
/// Currently logs to the console; swap for FirebaseAnalytics later without
/// touching call sites.
class AnalyticsService {
  void log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${params.isEmpty ? '' : params}');
    }
  }

  // Named helpers for the key funnels in plan §9.
  void tutorialComplete() => log('tutorial_complete');
  void dailyReturn(int streak) => log('daily_return', {'streak': streak});
  void adImpression(String placement) => log('ad_impression', {'placement': placement});
  void adComplete(String placement) => log('ad_complete', {'placement': placement});
  void offlineClaim(int gold) => log('offline_reward_claim', {'gold': gold});
  void generationTransition(int gen) => log('generation_transition', {'generation': gen});
  void activityStart(String id) => log('activity_start', {'activity': id});
}
