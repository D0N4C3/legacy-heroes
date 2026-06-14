import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'game_sized.dart';

/// A band of small repeating ground motifs (rubble, cracks, tufts...) that
/// glides sideways as the hero advances through an encounter (see
/// [GameScene.applyCombat]'s `advanceTick` handling). The world itself never
/// moves — this just gives static dungeon/boss backdrops a "marching
/// forward" feel each time a foe is cleared.
class GroundDetails extends PositionComponent with GameSized {
  GroundDetails({
    required this.colors,
    this.groundLevel = 0.62,
    this.tileWidth = 160,
    int priority = 1,
  }) {
    this.priority = priority;
  }

  /// Palette the motifs are drawn from, cycled across tiles for variety.
  final List<Color> colors;

  /// Fraction of screen height the motifs sit on (matches the scene's
  /// [SkyBackground.groundLevel]).
  final double groundLevel;

  /// Width of one repeating motif tile, in pixels.
  final double tileWidth;

  double _scrollX = 0;
  double _targetScrollX = 0;

  /// Glide the band forward by [amount] pixels — eased, not instant, so the
  /// ground sweeps past rather than jumping.
  void advance(double amount) => _targetScrollX += amount;

  /// A handful of small patches per tile, given as fractions of [tileWidth]
  /// (dx) and pixel offsets/sizes (dy, w, h). Repeating this fixed layout
  /// every tile keeps the band seamless while still reading as terrain.
  static const List<_Patch> _motifs = [
    _Patch(0.10, 8, 30, 10),
    _Patch(0.34, -6, 18, 7),
    _Patch(0.58, 14, 36, 12),
    _Patch(0.82, -2, 22, 8),
  ];

  @override
  void update(double dt) {
    super.update(dt);
    _scrollX += (_targetScrollX - _scrollX) * min(1.0, dt * 3);
  }

  @override
  void render(Canvas canvas) {
    if (w <= 0 || colors.isEmpty) return;
    final groundY = h * groundLevel;
    final paint = Paint();
    final offset = _scrollX % tileWidth;
    final firstTile = -(offset / tileWidth).ceil() - 1;
    final lastTile = ((w - offset) / tileWidth).ceil() + 1;

    for (var i = firstTile; i <= lastTile; i++) {
      final tileX = i * tileWidth + offset;
      for (var m = 0; m < _motifs.length; m++) {
        final patch = _motifs[m];
        paint.color = colors[(i + m).abs() % colors.length];
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(tileX + patch.dx * tileWidth, groundY + patch.dy),
            width: patch.w,
            height: patch.h,
          ),
          paint,
        );
      }
    }
  }
}

class _Patch {
  const _Patch(this.dx, this.dy, this.w, this.h);
  final double dx;
  final double dy;
  final double w;
  final double h;
}
