import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// A floating damage / value number that rises and fades (Visual Plan §7).
/// Flame applies the component's position transform before [render], so we
/// draw in local space around the origin.
class DamageNumber extends PositionComponent {
  DamageNumber({
    required Vector2 position,
    required this.text,
    this.color = const Color(0xFFFFE08A),
  }) {
    this.position = position;
    priority = 50;
  }

  final String text;
  final Color color;
  double _life = 0;
  static const _maxLife = 1.1;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 40 * dt;
    if (_life >= _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - _life / _maxLife).clamp(0.0, 1.0).toDouble();
    final paint = TextPaint(
      style: TextStyle(
        color: color.withOpacity(fade),
        fontSize: 26,
        fontWeight: FontWeight.w800,
        shadows: const [
          Shadow(color: Color(0xAA000000), blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
    );
    paint.render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}

/// A celebratory burst of coins flying outward (Visual Plan §7 reward moments).
class GoldBurst extends PositionComponent {
  GoldBurst({required Vector2 position, this.count = 16}) {
    this.position = position;
    priority = 49;
  }

  final int count;
  final _rng = Random();
  final List<_Coin> _coins = [];
  double _life = 0;
  static const _maxLife = 1.0;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final sp = 90 + _rng.nextDouble() * 160;
      _coins.add(_Coin(
        Vector2.zero(),
        Vector2(cos(a) * sp, sin(a) * sp - 120),
        3 + _rng.nextDouble() * 3,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    for (final c in _coins) {
      c.vel.y += 420 * dt; // gravity
      c.pos += c.vel * dt;
    }
    if (_life >= _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - _life / _maxLife).clamp(0.0, 1.0).toDouble();
    final gold = Paint()..color = const Color(0xFFE7B53C).withOpacity(fade);
    final shine = Paint()..color = const Color(0xFFFBE08A).withOpacity(fade);
    for (final c in _coins) {
      canvas.drawCircle(Offset(c.pos.x, c.pos.y), c.size, gold);
      canvas.drawCircle(
          Offset(c.pos.x - c.size * 0.3, c.pos.y - c.size * 0.3), c.size * 0.4, shine);
    }
  }
}

class _Coin {
  Vector2 pos;
  Vector2 vel;
  double size;
  _Coin(this.pos, this.vel, this.size);
}
