import '../../../core/constants/game_constants.dart';

/// A hero's life stage, derived from in-game age (plan §3B).
enum LifeStage {
  young('Young Hero'),
  experienced('Experienced'),
  veteran('Veteran'),
  elder('Elder'),
  retired('Retired'),
  fallen('Fallen');

  const LifeStage(this.label);
  final String label;

  static LifeStage fromAge(int age) {
    if (age >= GameConstants.stageElderAge) return LifeStage.elder;
    if (age >= GameConstants.stageVeteranAge) return LifeStage.veteran;
    if (age >= GameConstants.stageExperiencedAge) return LifeStage.experienced;
    return LifeStage.young;
  }

  bool get isActive => this != LifeStage.retired && this != LifeStage.fallen;
}
