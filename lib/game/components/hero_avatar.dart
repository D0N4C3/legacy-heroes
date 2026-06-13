import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../art/hero_art.dart';

// Re-export so existing imports of this file keep resolving HeroAnim.
export '../art/hero_art.dart' show HeroAnim;

/// In-world animated hero. All drawing lives in [HeroArt] so the avatar and the
/// UI portraits render the exact same class-specific sprite. Also carries the
/// combat mini-game's live HP/flash/pulse state and a smoothed "run forward"
/// target X, pushed in from `GameScene.applyCombat`.
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

  /// Current/max HP for the combat HP bar. [maxHealth] of 0 hides the bar
  /// (decorative hero, outside an active encounter).
  int health = 0;
  int maxHealth = 0;

  double _hitFlash = 0;
  double _attackPulse = 0;

  /// World-space X to smoothly drift toward (e.g. "run forward" to engage a
  /// foe). Null means stay put.
  double? targetX;

  bool get _isBlinking => _blink > _nextBlink;

  /// Briefly tint the hero on taking a counter-hit.
  void flashHit() => _hitFlash = 1.0;

  /// One-shot forward attack swing.
  void pulseAttack() => _attackPulse = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _blink += dt;
    if (_blink > _nextBlink + 0.12) {
      _blink = 0;
      _nextBlink = 2 + _rng.nextDouble() * 3;
    }
    if (_hitFlash > 0) _hitFlash = (_hitFlash - dt * 4).clamp(0.0, 1.0);
    if (_attackPulse > 0) _attackPulse = (_attackPulse - dt * 6).clamp(0.0, 1.0);

    final tx = targetX;
    if (tx != null) {
      position.x += (tx - position.x) * min(1.0, dt * 6);
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
      attackPulse: _attackPulse,
      hitFlash: _hitFlash,
    );
    if (maxHealth > 0) _drawHealthBar(canvas);
    canvas.restore();
  }

  void _drawHealthBar(Canvas canvas) {
    const width = 60.0;
    const barHeight = 6.0;
    const rect = Rect.fromLTWH(-width / 2, -98 - barHeight / 2, width, barHeight);
    const radius = Radius.circular(3);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius),
        Paint()..color = const Color(0xFF1A1018));

    final pct = maxHealth == 0 ? 0.0 : (health / maxHealth).clamp(0.0, 1.0);
    if (pct > 0) {
      final fill = Rect.fromLTWH(rect.left, rect.top, width * pct, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(fill, radius), Paint()..color = Palette.xp);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color = Palette.goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
