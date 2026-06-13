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
        color: color.withValues(alpha: fade),
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
    final gold = Paint()..color = const Color(0xFFE7B53C).withValues(alpha: fade);
    final shine = Paint()..color = const Color(0xFFFBE08A).withValues(alpha: fade);
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

/// How a class delivers a blow (Visual Plan §7 "attack effects"). Mapped from
/// the hero's weapon so a Mage casts, a Ranger looses an arrow, and the melee
/// classes swing a slash.
enum AttackStyle { melee, arrow, magic }

/// A class-flavoured attack effect. Ranged styles fly from the hero to the foe
/// and burst on arrival; melee draws a quick slash arc over the foe.
class AttackEffect extends PositionComponent {
  AttackEffect({
    required Vector2 from,
    required this.to,
    required this.style,
    this.color = const Color(0xFF8FE3FF),
  }) : _from = from.clone() {
    position = (style == AttackStyle.melee ? to : from).clone();
    priority = 48;
  }

  final Vector2 _from;
  final Vector2 to;
  final AttackStyle style;
  final Color color;

  double _life = 0;
  bool _impacted = false;
  double get _dur => style == AttackStyle.melee ? 0.26 : 0.20;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (style != AttackStyle.melee) {
      final p = (_life / _dur).clamp(0.0, 1.0);
      position = _from + (to - _from) * p;
      if (p >= 1 && !_impacted) {
        _impacted = true;
        parent?.add(ImpactBurst(position: to.clone(), color: color));
      }
    }
    if (_life >= _dur) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_life / _dur).clamp(0.0, 1.0).toDouble();
    switch (style) {
      case AttackStyle.magic:
        final glow = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset.zero, 10, glow);
        canvas.drawCircle(Offset.zero, 5.5, Paint()..color = color);
        canvas.drawCircle(const Offset(-1.6, -1.6), 2, Paint()..color = Colors.white);
        // sparkly trail
        final dir = (to - _from)..normalize();
        for (var i = 1; i <= 3; i++) {
          canvas.drawCircle(Offset(-dir.x * i * 6, -dir.y * i * 6), 3.0 - i * 0.6,
              Paint()..color = color.withValues(alpha: 0.4 - i * 0.1));
        }
        break;
      case AttackStyle.arrow:
        final dir = to - _from;
        canvas.save();
        canvas.rotate(atan2(dir.y, dir.x));
        canvas.drawRect(const Rect.fromLTWH(-13, -1, 26, 2),
            Paint()..color = const Color(0xFF6E4A2A));
        canvas.drawPath(
            Path()
              ..moveTo(13, 0)
              ..lineTo(6, -4)
              ..lineTo(6, 4)
              ..close(),
            Paint()..color = const Color(0xFFCBD2DA));
        canvas.drawPath(
            Path()
              ..moveTo(-13, 0)
              ..lineTo(-18, -4)
              ..lineTo(-12, 0)
              ..lineTo(-18, 4)
              ..close(),
            Paint()..color = const Color(0xFFE7D7A0));
        canvas.restore();
        break;
      case AttackStyle.melee:
        final fade = (1 - p);
        final arc = Paint()
          ..color = Colors.white.withValues(alpha: 0.9 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
        // A crescent that sweeps downward through the strike.
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: 30),
            -1.1 + p * 1.4,
            1.3,
            false,
            arc);
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: 30),
            -1.1 + p * 1.4,
            1.3,
            false,
            Paint()
              ..color = color.withValues(alpha: 0.5 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        break;
    }
  }
}

/// A short-lived spark pop where a blow or projectile lands.
class ImpactBurst extends PositionComponent {
  ImpactBurst({
    required Vector2 position,
    this.color = const Color(0xFFFFE08A),
    this.count = 9,
  }) {
    this.position = position;
    priority = 49;
  }

  final Color color;
  final int count;
  final _rng = Random();
  final List<_Coin> _bits = [];
  double _life = 0;
  static const _maxLife = 0.4;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final sp = 60 + _rng.nextDouble() * 130;
      _bits.add(_Coin(Vector2.zero(),
          Vector2(cos(a) * sp, sin(a) * sp), 1.5 + _rng.nextDouble() * 2.5));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    for (final b in _bits) {
      b.pos += b.vel * dt;
      b.vel *= 0.9;
    }
    if (_life >= _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - _life / _maxLife).clamp(0.0, 1.0).toDouble();
    final p = Paint()
      ..color = color.withValues(alpha: fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    for (final b in _bits) {
      canvas.drawCircle(Offset(b.pos.x, b.pos.y), b.size, p);
    }
  }
}
