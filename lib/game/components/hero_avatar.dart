import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../art/hero_art.dart';

// Re-export so existing imports of this file keep resolving HeroAnim.
export '../art/hero_art.dart' show HeroAnim;

/// In-world animated hero. All drawing lives in [HeroArt] so the avatar and the
/// UI portraits render the exact same class-specific sprite.
class HeroAvatar extends PositionComponent {
  HeroAvatar({
    required Vector2 position,
    required this.classId,
    this.anim = HeroAnim.idle,
    double scale = 1.0,
  }) : _scale = scale {
    this.position = position;
    priority = 10;
  }

  String classId;
  HeroAnim anim;
  final double _scale;

  double _t = 0;
  double _blink = 0;
  double _nextBlink = 2.5;
  final _rng = Random();

  bool get _isBlinking => _blink > _nextBlink;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _blink += dt;
    if (_blink > _nextBlink + 0.12) {
      _blink = 0;
      _nextBlink = 2 + _rng.nextDouble() * 3;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(_scale);
    HeroArt.drawBody(
      canvas,
      classId: classId,
      t: _t,
      anim: anim,
      blinking: _isBlinking,
    );
    canvas.restore();
  }
}
