/// The set of Flame scenes the world can display (Visual Plan §4).
enum SceneType { village, training, dungeon, boss, legacy }

extension SceneTypeX on SceneType {
  static SceneType fromId(String id) {
    switch (id) {
      case 'training':
        return SceneType.training;
      case 'dungeon':
        return SceneType.dungeon;
      case 'boss':
        return SceneType.boss;
      case 'legacy':
        return SceneType.legacy;
      default:
        return SceneType.village;
    }
  }
}
