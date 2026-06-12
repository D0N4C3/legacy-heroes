import 'dart:async';

/// Rewarded-ad abstraction (plan §4). Rewarded ads are the primary
/// monetization and must feel optional/helpful, never forced.
///
/// The default [SimulatedAdService] lets the full reward loop run in
/// development without AdMob platform setup. To ship real ads, add the
/// `google_mobile_ads` dependency wiring (see README "Enabling AdMob") and
/// provide a real implementation overriding [adServiceProvider].
abstract class AdService {
  /// Returns true if the user "watched" the ad and earned the reward.
  Future<bool> showRewarded(RewardPlacement placement);

  bool get isRealAdProvider;
}

/// Where a rewarded ad is offered (plan §4 placements). Useful for analytics.
enum RewardPlacement {
  doubleOfflineRewards,
  rescueFailedExpedition,
  bonusChest,
  speedUpTraining,
  heirBlessing,
  rareEventReroll,
  dailyBonus,
}

/// Dev/default: simulates a watched ad after a short delay.
class SimulatedAdService implements AdService {
  @override
  bool get isRealAdProvider => false;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async {
    // The UI shows a "watching ad…" overlay; we resolve after a beat.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return true;
  }
}
