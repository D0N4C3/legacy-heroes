import 'package:flutter/material.dart';

import '../../app/palette.dart';

/// A diegetic wood-and-gold button with a press bounce (Visual Plan §8).
/// Replaces Material buttons everywhere in the game screens.
class FantasyButton extends StatefulWidget {
  const FantasyButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.compact = false,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary; // gold accent vs wood
  final bool compact;
  final bool enabled;

  @override
  State<FantasyButton> createState() => _FantasyButtonState();
}

class _FantasyButtonState extends State<FantasyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final base = widget.primary ? Palette.gold : Palette.wood;
    final top = widget.primary ? Palette.goldLight : const Color(0xFF7A5230);
    final textColor = widget.primary ? Palette.woodDark : Palette.parchment;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 14 : 22,
                vertical: widget.compact ? 9 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, base],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Palette.goldDark, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: widget.compact ? 16 : 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: widget.compact ? 13 : 16,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
