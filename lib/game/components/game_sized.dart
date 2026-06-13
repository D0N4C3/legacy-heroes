import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Mixin giving a component the current game canvas size, so scene elements
/// can lay themselves out responsively in screen space.
mixin GameSized on Component {
  Vector2 get gameSize => (findGame() as FlameGame).size;
  double get w => gameSize.x;
  double get h => gameSize.y;
}
