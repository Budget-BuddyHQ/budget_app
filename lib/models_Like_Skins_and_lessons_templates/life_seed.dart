import 'life_sim_models.dart';

// the seed a life gets rolled from. origin (rich/poor family etc) is
// randomized, not picked, cause letting ppl choose rich family kinda
// defeats the point of a money-lessons game. name/gender stay yours tho.
// seed is visible/typeable so you can replay the same life or share it,
// like a minecraft seed. odds arent even 25/25/25/25 either, see origin getter
class LifeSeed {
  const LifeSeed(this.value);

  // turns typed text into a seed. "hello" still works, doesnt need to look
  // like a number, same input = same life every time
  factory LifeSeed.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return LifeSeed(DateTime.now().microsecondsSinceEpoch);

    final asNumber = int.tryParse(trimmed);
    if (asNumber != null) return LifeSeed(asNumber.abs());

    // fnv-1a, NOT dart's hashCode, that ones randomized per app restart
    // which wouldve made the seed useless
    var hash = 0x811c9dc5;
    for (final unit in trimmed.toLowerCase().codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return LifeSeed(hash);
  }

  // random fresh seed
  factory LifeSeed.fresh() =>
      LifeSeed(DateTime.now().microsecondsSinceEpoch & 0x7fffffff);

  final int value;

  // short readable version, easy to say out loud or type back in
  String get display => value.toRadixString(36).toUpperCase().padLeft(6, '0');

  // deterministic 0..max-1 for this seed + a channel name, so rolling
  // origin doesnt mess with what the map roll gives you
  int _roll(String channel, int max) {
    var hash = 0x811c9dc5;
    for (final unit in '$value|$channel'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return max <= 0 ? 0 : hash % max;
  }

  // family this seed is born into. weighted 35/35/22/8, not even odds,
  // most lives shouldnt start rich
  LifeOrigin get origin {
    const weights = <LifeOrigin, int>{
      LifeOrigin.struggling: 35,
      LifeOrigin.workingClass: 35,
      LifeOrigin.comfortable: 22,
      LifeOrigin.wealthy: 8,
    };
    final total = weights.values.reduce((a, b) => a + b);
    var roll = _roll('origin', total);
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return LifeOrigin.workingClass;
  }

  // suggested name, player can change it
  String suggestedName(List<String> firstNames, List<String> lastNames) {
    if (firstNames.isEmpty || lastNames.isEmpty) return 'Casey Reyes';
    return '${firstNames[_roll('first', firstNames.length)]} '
        '${lastNames[_roll('last', lastNames.length)]}';
  }

  // which town this life ends up in
  int townIndex(int mapCount) => _roll('town', mapCount);

  @override
  bool operator ==(Object other) =>
      other is LifeSeed && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'LifeSeed($display)';
}
