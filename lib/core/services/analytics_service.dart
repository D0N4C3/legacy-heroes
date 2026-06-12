import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase/firebase_service.dart';

/// Analytics seam (plan §9). Logs to the console in debug and forwards to
/// Firebase Analytics when configured. Call sites never change.
class AnalyticsService {
  void log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${params.isEmpty ? '' : params}');
    }
    if (FirebaseService.instance.ready) {
      try {
        // Firebase only accepts non-null String/num values.
        final clean = <String, Object>{};
        params.forEach((k, v) {
          if (v != null) clean[k] = v;
        });
        FirebaseAnalytics.instance.logEvent(
          name: event,
          parameters: clean.isEmpty ? null : clean,
        );
      } catch (_) {/* analytics must never break gameplay */}
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
