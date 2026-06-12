import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/ad_service.dart';
import '../core/services/analytics_service.dart';
import '../core/services/save_service.dart';
import '../features/activities/data/activity_repository.dart';
import '../features/activities/domain/activity.dart';
import '../game/scene_type.dart';
import 'game_controller.dart';

// ── Services ───────────────────────────────────────────────────────────────
final saveServiceProvider = Provider<SaveService>((ref) => SaveService());
final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

/// Swap [SimulatedAdService] for a real AdMob implementation here to ship ads.
final adServiceProvider = Provider<AdService>((ref) => SimulatedAdService());

// ── Game controller ─────────────────────────────────────────────────────────
final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  // StateNotifierProvider disposes the notifier (and its ticker) automatically.
  return GameController(
    save: ref.watch(saveServiceProvider),
    ads: ref.watch(adServiceProvider),
    analytics: ref.watch(analyticsProvider),
  );
});

// ── Derived selectors ───────────────────────────────────────────────────────
final activitiesProvider = Provider<List<ActivityDef>>(
    (ref) => ActivityRepository.instance.all);

/// The definition of the currently-running activity (null while resting).
final activeActivityDefProvider = Provider<ActivityDef?>((ref) {
  final state = ref.watch(gameControllerProvider);
  final inst = state.currentActivity;
  if (inst == null) return null;
  return ActivityRepository.instance.byId(inst.activityId);
});

/// Which Flame scene the world should display right now.
final currentSceneProvider = Provider<SceneType>((ref) {
  final state = ref.watch(gameControllerProvider);
  final def = ref.watch(activeActivityDefProvider);
  return state.sceneFor(def);
});
