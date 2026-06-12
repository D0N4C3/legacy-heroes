import 'dart:convert';

import '../features/activities/domain/activity.dart';
import '../features/activities/domain/activity_result.dart';
import '../features/equipment/domain/equipment.dart';
import '../features/family/domain/ancestor.dart';
import '../features/hero/domain/hero.dart';
import '../game/scene_type.dart';

/// The complete, serializable snapshot of a player's dynasty.
class GameState {
  final int gold;
  final int gems;
  final int generation;
  final bool premium;

  final HeroData? hero;
  final List<EquipmentItem> inventory;
  final ActivityInstance? currentActivity;

  /// A finished activity awaiting the player's "collect" (plan §6.3).
  final ActivityResult? pendingResult;

  /// Offline accrual to surface once on return (plan §3E).
  final OfflineReport? offlineReport;

  /// Permanent dynasty history (plan §3C).
  final List<AncestorRecord> familyTree;

  /// When non-empty, the heir-selection ceremony is pending (plan §6.7).
  final List<HeirCandidate> heirCandidates;

  final int dailyStreak;
  final DateTime? lastDailyClaim;
  final DateTime lastSavedAt;

  const GameState({
    required this.gold,
    required this.gems,
    required this.generation,
    this.premium = false,
    this.hero,
    this.inventory = const [],
    this.currentActivity,
    this.pendingResult,
    this.offlineReport,
    this.familyTree = const [],
    this.heirCandidates = const [],
    this.dailyStreak = 0,
    this.lastDailyClaim,
    required this.lastSavedAt,
  });

  bool get hasHero => hero != null;
  bool get isResting => currentActivity == null;
  bool get awaitingHeir => heirCandidates.isNotEmpty;

  /// Which Flame scene should be on screen right now.
  SceneType sceneFor(ActivityDef? activeDef) {
    if (awaitingHeir) return SceneType.legacy;
    if (currentActivity != null && activeDef != null) return activeDef.scene;
    return SceneType.village;
  }

  GameState copyWith({
    int? gold,
    int? gems,
    int? generation,
    bool? premium,
    HeroData? hero,
    List<EquipmentItem>? inventory,
    Object? currentActivity = _sentinel,
    Object? pendingResult = _sentinel,
    Object? offlineReport = _sentinel,
    List<AncestorRecord>? familyTree,
    List<HeirCandidate>? heirCandidates,
    int? dailyStreak,
    Object? lastDailyClaim = _sentinel,
    DateTime? lastSavedAt,
  }) {
    return GameState(
      gold: gold ?? this.gold,
      gems: gems ?? this.gems,
      generation: generation ?? this.generation,
      premium: premium ?? this.premium,
      hero: hero ?? this.hero,
      inventory: inventory ?? this.inventory,
      currentActivity: currentActivity == _sentinel
          ? this.currentActivity
          : currentActivity as ActivityInstance?,
      pendingResult: pendingResult == _sentinel
          ? this.pendingResult
          : pendingResult as ActivityResult?,
      offlineReport: offlineReport == _sentinel
          ? this.offlineReport
          : offlineReport as OfflineReport?,
      familyTree: familyTree ?? this.familyTree,
      heirCandidates: heirCandidates ?? this.heirCandidates,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyClaim: lastDailyClaim == _sentinel
          ? this.lastDailyClaim
          : lastDailyClaim as DateTime?,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  // ── Persistence ─────────────────────────────────────────────────────────
  // Transient fields (pendingResult / offlineReport) are intentionally not
  // serialized — they are recomputed on launch.
  Map<String, dynamic> toJson() => {
        'gold': gold,
        'gems': gems,
        'generation': generation,
        'premium': premium,
        'hero': hero?.toJson(),
        'inventory': inventory.map((e) => e.toJson()).toList(),
        'currentActivity': currentActivity?.toJson(),
        'familyTree': familyTree.map((e) => e.toJson()).toList(),
        'heirCandidates': heirCandidates.map((e) => e.toJson()).toList(),
        'dailyStreak': dailyStreak,
        'lastDailyClaim': lastDailyClaim?.toIso8601String(),
        'lastSavedAt': lastSavedAt.toIso8601String(),
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        gold: j['gold'],
        gems: j['gems'],
        generation: j['generation'],
        premium: j['premium'] ?? false,
        hero: j['hero'] == null ? null : HeroData.fromJson(j['hero']),
        inventory: (j['inventory'] as List)
            .map((e) => EquipmentItem.fromJson(e))
            .toList(),
        currentActivity: j['currentActivity'] == null
            ? null
            : ActivityInstance.fromJson(j['currentActivity']),
        familyTree: (j['familyTree'] as List)
            .map((e) => AncestorRecord.fromJson(e))
            .toList(),
        heirCandidates: (j['heirCandidates'] as List)
            .map((e) => HeirCandidate.fromJson(e))
            .toList(),
        dailyStreak: j['dailyStreak'] ?? 0,
        lastDailyClaim: j['lastDailyClaim'] == null
            ? null
            : DateTime.parse(j['lastDailyClaim']),
        lastSavedAt: DateTime.parse(j['lastSavedAt']),
      );

  String encode() => jsonEncode(toJson());
  static GameState decode(String s) => GameState.fromJson(jsonDecode(s));

  static const _sentinel = Object();
}
