/// A permanent record in the dynasty history (plan §3C Family Tree).
/// Heroes are never deleted — they become memorial portraits on the tree.
class AncestorRecord {
  final String id;
  final String name;
  final String classId;
  final int generation;
  final int level;
  final int bornAtAge; // 18
  final int diedAtAge;
  final bool retired; // true = retired peacefully, false = fell in battle
  final String causeOfEnd;
  final String biggestAchievement;
  final List<String> traitIds;
  final List<String> childrenIds;
  final String? parentId;
  final String? heirloomName;

  const AncestorRecord({
    required this.id,
    required this.name,
    required this.classId,
    required this.generation,
    required this.level,
    required this.bornAtAge,
    required this.diedAtAge,
    required this.retired,
    required this.causeOfEnd,
    required this.biggestAchievement,
    required this.traitIds,
    required this.childrenIds,
    this.parentId,
    this.heirloomName,
  });

  String get lifespan => 'Age $bornAtAge–$diedAtAge';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'classId': classId,
        'generation': generation,
        'level': level,
        'bornAtAge': bornAtAge,
        'diedAtAge': diedAtAge,
        'retired': retired,
        'causeOfEnd': causeOfEnd,
        'biggestAchievement': biggestAchievement,
        'traitIds': traitIds,
        'childrenIds': childrenIds,
        'parentId': parentId,
        'heirloomName': heirloomName,
      };

  factory AncestorRecord.fromJson(Map<String, dynamic> j) => AncestorRecord(
        id: j['id'],
        name: j['name'],
        classId: j['classId'],
        generation: j['generation'],
        level: j['level'],
        bornAtAge: j['bornAtAge'],
        diedAtAge: j['diedAtAge'],
        retired: j['retired'],
        causeOfEnd: j['causeOfEnd'],
        biggestAchievement: j['biggestAchievement'],
        traitIds: (j['traitIds'] as List).cast<String>(),
        childrenIds: (j['childrenIds'] as List).cast<String>(),
        parentId: j['parentId'],
        heirloomName: j['heirloomName'],
      );
}

/// A candidate heir presented on the Heir Selection screen (plan §6.7).
class HeirCandidate {
  final String id;
  final String name;
  final String classId;
  final double inheritedPower;
  final List<String> traitIds;
  final String? heirloomName;

  const HeirCandidate({
    required this.id,
    required this.name,
    required this.classId,
    required this.inheritedPower,
    required this.traitIds,
    this.heirloomName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'classId': classId,
        'inheritedPower': inheritedPower,
        'traitIds': traitIds,
        'heirloomName': heirloomName,
      };

  factory HeirCandidate.fromJson(Map<String, dynamic> j) => HeirCandidate(
        id: j['id'],
        name: j['name'],
        classId: j['classId'],
        inheritedPower: (j['inheritedPower']).toDouble(),
        traitIds: (j['traitIds'] as List).cast<String>(),
        heirloomName: j['heirloomName'],
      );
}
