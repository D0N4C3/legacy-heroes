import 'dart:math';

/// Shared random source + small helpers used across game logic.
final Random rng = Random();

/// Unique-enough id for heroes / items without extra deps.
String genId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${rng.nextInt(99999)}';

/// Inclusive integer in [min, max].
int randInt(int min, int max) => min + rng.nextInt(max - min + 1);

/// Pick a random element.
T pick<T>(List<T> items) => items[rng.nextInt(items.length)];

/// True with probability [p] (0..1).
bool chance(double p) => rng.nextDouble() < p;
