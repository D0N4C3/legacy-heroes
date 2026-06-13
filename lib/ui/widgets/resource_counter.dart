import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../core/utils/formatters.dart';

/// A floating, magical resource counter pill (Visual Plan §6 Home Screen).
class ResourceCounter extends StatelessWidget {
  const ResourceCounter({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.onTapAdd,
  });

  final IconData icon;
  final int value;
  final Color color;
  final VoidCallback? onTapAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Palette.woodDark.withValues(alpha: 0.92), Palette.wood.withValues(alpha: 0.92)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.goldDark, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            formatCompact(value),
            style: const TextStyle(
              color: Palette.parchment,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          if (onTapAdd != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTapAdd,
              child: const Icon(Icons.add_circle, size: 18, color: Palette.goldLight),
            ),
          ],
        ],
      ),
    );
  }
}
