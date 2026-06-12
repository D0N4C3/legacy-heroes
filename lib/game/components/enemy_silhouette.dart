import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../art/enemy_art.dart';

export '../art/enemy_art.dart' show EnemyType;

/// In-world enemy. All drawing lives in [EnemyArt]; this component just tracks
/// time and position. [boss] enlarges the demon for the Demon Gate encounter.
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
  final bool boss;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) => EnemyArt.draw(canvas, type, _t, boss: boss);
}
