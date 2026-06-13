import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../art/enemy_art.dart';

export '../art/enemy_art.dart' show EnemyType;

/// In-world enemy. All drawing lives in [EnemyArt]; this component tracks
/// time, position, and the combat mini-game's live HP/flash/defeat state
/// (pushed in from `GameScene.applyCombat`). [boss] enlarges the demon for
/// the Demon Gate encounter.
class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required Vector2 position,
    this.type = EnemyType.goblin,
    this.boss = false,
  }) {
    this.position = position;
    priority = 9;
  }

  EnemyType type;
  bool boss;

  /// Current/max HP for the combat HP bar. [maxHealth] of 0 hides the bar
  /// (decorative enemy, outside an active encounter).
  int health = 0;
  int maxHealth = 0;

  /// The engage position the foe walks up to. Scenes set this in layout().
  double homeX = 0;

  double _t = 0;
  double _hitFlash = 0;
  double _defeat = 0;
  bool _walkingIn = false;

  /// Whether the foe is currently striding in (used for a walk wobble).
  bool get isWalkingIn => _walkingIn;

  /// Swap in a fresh foe (new type/HP), clearing any in-progress defeat fx.
  void spawn(EnemyType newType, int newHealth, int newMaxHealth) {
    type = newType;
    health = newHealth;
    maxHealth = newMaxHealth;
    _hitFlash = 0;
    _defeat = 0;
  }

  /// Make the foe stride in from off-screen ([fromX]) to its [homeX].
  void walkIn(double fromX) {
    position.x = fromX;
    _walkingIn = true;
  }

  /// Update HP without resetting the visual state (e.g. after a hit).
  void setHealth(int newHealth) => health = newHealth;

  /// Briefly tint the creature on a landed hit.
  void flashHit() => _hitFlash = 1.0;

  /// Start the shrink/fade-out animation once the foe is defeated.
  void startDefeat() {
    if (_defeat == 0) _defeat = 0.001;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_hitFlash > 0) _hitFlash = (_hitFlash - dt * 4).clamp(0.0, 1.0);
    if (_defeat > 0) _defeat = (_defeat + dt * 2.5).clamp(0.0, 1.0);
    if (_walkingIn) {
      position.x += (homeX - position.x) * (dt * 3.4).clamp(0.0, 1.0);
      if ((homeX - position.x).abs() < 1.5) {
        position.x = homeX;
        _walkingIn = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    EnemyArt.draw(canvas, type, _t,
        boss: boss, hitFlash: _hitFlash, defeatProgress: _defeat);
    // Hide the HP bar until the foe has marched into engage range.
    if (maxHealth > 0 && _defeat == 0 && !_walkingIn) _drawHealthBar(canvas);
  }

  void _drawHealthBar(Canvas canvas) {
    const width = 56.0;
    const barHeight = 6.0;
    final y = boss ? -164.0 : -78.0;
    final rect = Rect.fromCenter(center: Offset(0, y), width: width, height: barHeight);
    const radius = Radius.circular(3);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius),
        Paint()..color = const Color(0xFF1A1018));

    final pct = maxHealth == 0 ? 0.0 : (health / maxHealth).clamp(0.0, 1.0);
    if (pct > 0) {
      final fill = Rect.fromLTWH(rect.left, rect.top, width * pct, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(fill, radius), Paint()..color = Palette.hp);
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
