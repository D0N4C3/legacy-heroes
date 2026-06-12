/// Compact number formatting for resource counters (e.g. 12.4K, 3.1M).
String formatCompact(num value) {
  final v = value.abs();
  String sign = value < 0 ? '-' : '';
  if (v < 1000) return '$sign${value.toInt()}';
  if (v < 1000000) return '$sign${_trim(v / 1000)}K';
  if (v < 1000000000) return '$sign${_trim(v / 1000000)}M';
  return '$sign${_trim(v / 1000000000)}B';
}

String _trim(double d) {
  final s = d.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// "2h 14m", "47m", "31s" — friendly durations for activity timers.
String formatDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}
