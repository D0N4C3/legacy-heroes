import 'dart:ui';

import 'package:flame/components.dart';

import 'game_sized.dart';

/// A lightweight, declarative static prop drawn from a callback. Lets scenes
/// describe their set dressing (houses, banners, dummies, ruins) inline while
/// still participating in Flame's priority-ordered render tree.
class PropComponent extends PositionComponent with GameSized {
  PropComponent(this.draw, {int priority = 2}) {
    this.priority = priority;
  }

  final void Function(Canvas canvas, Vector2 size) draw;

  @override
  void render(Canvas canvas) => draw(canvas, gameSize);
}
