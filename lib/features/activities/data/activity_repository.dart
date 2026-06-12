import '../../../core/services/catalog_service.dart';
import '../domain/activity.dart';

/// Parses [ActivityDef]s from the loaded catalog (plan §3D / §17: 5 activities).
class ActivityRepository {
  ActivityRepository._();
  static final ActivityRepository instance = ActivityRepository._();

  late final List<ActivityDef> all =
      Catalog.instance.activitiesRaw.map(ActivityDef.fromJson).toList();

  ActivityDef byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
