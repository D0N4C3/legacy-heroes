import 'dart:convert';
import 'package:flutter/services.dart';

import '../../features/hero/domain/hero_class.dart';
import '../../features/hero/domain/trait.dart';

/// Loads and holds all static game data (classes, traits, item name pools).
///
/// Exposed as a loaded singleton so domain models can resolve bonuses without
/// dependency plumbing. Call [Catalog.load] once at startup before runApp.
class Catalog {
  Catalog._();
  static final Catalog instance = Catalog._();

  final Map<String, HeroClassData> classes = {};
  final Map<String, TraitData> traits = {};
  Map<String, dynamic> itemPools = {};
  List<Map<String, dynamic>> activitiesRaw = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  List<HeroClassData> get classList => classes.values.toList();
  List<TraitData> get traitList => traits.values.toList();

  Future<void> load() async {
    if (_loaded) return;

    final heroesJson = jsonDecode(
        await rootBundle.loadString('assets/data/heroes.json'));
    for (final c in (heroesJson['classes'] as List)) {
      final data = HeroClassData.fromJson(c);
      classes[data.id] = data;
    }

    final traitsJson = jsonDecode(
        await rootBundle.loadString('assets/data/traits.json'));
    for (final t in (traitsJson['traits'] as List)) {
      final data = TraitData.fromJson(t);
      traits[data.id] = data;
    }

    itemPools = jsonDecode(await rootBundle.loadString('assets/data/items.json'));

    final activitiesJson = jsonDecode(
        await rootBundle.loadString('assets/data/activities.json'));
    activitiesRaw =
        (activitiesJson['activities'] as List).cast<Map<String, dynamic>>();

    _loaded = true;
  }

  HeroClassData classOf(String id) => classes[id] ?? classList.first;
  TraitData? traitOf(String id) => traits[id];

  /// Combined power multiplier from a set of trait ids (e.g. 1.18 = +18%).
  double traitPowerMult(Iterable<String> ids) {
    double sum = 0;
    for (final id in ids) {
      sum += traits[id]?.power ?? 0;
    }
    return 1 + sum;
  }

  /// Combined reward multiplier from traits.
  double traitRewardMult(Iterable<String> ids) {
    double sum = 0;
    for (final id in ids) {
      sum += traits[id]?.reward ?? 0;
    }
    return 1 + sum;
  }

  double traitSurvivalBonus(Iterable<String> ids) {
    double sum = 0;
    for (final id in ids) {
      sum += traits[id]?.survival ?? 0;
    }
    return sum;
  }

  double traitInheritBonus(Iterable<String> ids) {
    double sum = 0;
    for (final id in ids) {
      sum += traits[id]?.inherit ?? 0;
    }
    return sum;
  }
}
