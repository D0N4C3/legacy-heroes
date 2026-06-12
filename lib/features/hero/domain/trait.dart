/// Static trait definition (plan §7 "Trait System"). Traits give emotional
/// identity and small mechanical bonuses; some are inheritable.
class TraitData {
  final String id;
  final String name;
  final bool positive;
  final bool inheritable;
  final double power; // multiplier added to hero power (can be negative)
  final double reward; // multiplier on gold/xp rewards
  final double loot; // additive loot chance
  final double survival; // additive survival on risky runs
  final double inherit; // bonus to inheritance % passed to heirs
  final String desc;

  const TraitData({
    required this.id,
    required this.name,
    required this.positive,
    required this.inheritable,
    this.power = 0,
    this.reward = 0,
    this.loot = 0,
    this.survival = 0,
    this.inherit = 0,
    required this.desc,
  });

  factory TraitData.fromJson(Map<String, dynamic> j) => TraitData(
        id: j['id'],
        name: j['name'],
        positive: j['positive'] ?? true,
        inheritable: j['inheritable'] ?? false,
        power: (j['power'] ?? 0).toDouble(),
        reward: (j['reward'] ?? 0).toDouble(),
        loot: (j['loot'] ?? 0).toDouble(),
        survival: (j['survival'] ?? 0).toDouble(),
        inherit: (j['inherit'] ?? 0).toDouble(),
        desc: j['desc'] ?? '',
      );
}
