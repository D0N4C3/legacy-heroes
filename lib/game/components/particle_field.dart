import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'game_sized.dart';

enum ParticleMode { fireflies, embers, dust, sparks }

class _P {
  double x, y, vx, vy, life, maxLife, size, phase;
  _P(this.x, this.y, this.vx, this.vy, this.life, this.maxLife, this.size, this.phase);
}

/// Ambient particle layer — fireflies, embers, drifting dust, combat sparks
/// (Visual Plan §7). Every main scene gets motion so it never feels like an app.
class ParticleField extends PositionComponent with GameSized {
  ParticleField({
    required this.mode,
    required this.color,
    this.count = 26,
    int priority = 5,
  }) {
    this.priority = priority;
  }

  final ParticleMode mode;
  final Color color;
  final int count;
  final _rng = Random();
  final List<_P> _particles = [];
  bool _seeded = false;

  void _seed() {
    _particles.clear();
    for (var i = 0; i < count; i++) {
      _particles.add(_spawn(initial: true));
    }
    _seeded = true;
  }

  _P _spawn({bool initial = false}) {
    final maxLife = 2.5 + _rng.nextDouble() * 4;
    switch (mode) {
      case ParticleMode.fireflies:
        return _P(_rng.nextDouble() * w, h * (0.4 + _rng.nextDouble() * 0.5),
            (_rng.nextDouble() - 0.5) * 14, (_rng.nextDouble() - 0.5) * 14,
            initial ? _rng.nextDouble() * maxLife : 0, maxLife,
            1.5 + _rng.nextDouble() * 2, _rng.nextDouble() * pi * 2);
      case ParticleMode.embers:
        return _P(w * 0.5 + (_rng.nextDouble() - 0.5) * 60, h * 0.78,
            (_rng.nextDouble() - 0.5) * 10, -20 - _rng.nextDouble() * 30,
            initial ? _rng.nextDouble() * maxLife : 0, maxLife,
            1 + _rng.nextDouble() * 2, 0);
      case ParticleMode.dust:
        return _P(_rng.nextDouble() * w, _rng.nextDouble() * h,
            8 + _rng.nextDouble() * 10, (_rng.nextDouble() - 0.5) * 4,
            initial ? _rng.nextDouble() * maxLife : 0, maxLife,
            1 + _rng.nextDouble() * 1.5, _rng.nextDouble() * pi * 2);
      case ParticleMode.sparks:
        return _P(w * 0.5, h * 0.55,
            (_rng.nextDouble() - 0.5) * 120, -40 - _rng.nextDouble() * 80,
            0, 0.6 + _rng.nextDouble() * 0.5,
            1 + _rng.nextDouble() * 2, 0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_seeded && w > 0) _seed();
    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.life += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (mode == ParticleMode.embers) p.vy *= 0.99;
      if (mode == ParticleMode.dust && p.x > w) p.x = 0;
      if (p.life >= p.maxLife) _particles[i] = _spawn();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_seeded) return;
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final p in _particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final fade = sin(t * pi); // fade in & out
      final twinkle = mode == ParticleMode.fireflies
          ? (0.5 + 0.5 * sin(p.life * 6 + p.phase))
          : 1.0;
      paint.color = color.withOpacity((fade * twinkle).clamp(0.0, 1.0).toDouble() * 0.9);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }
}
