import 'life_sim_models.dart';

/// The seed a life is rolled from.
///
/// # Why the family you are born into stopped being a choice
///
/// `LifeOrigin` supplies the starting money, and the spread is enormous:
/// **0 coins for Struggling against 2,500 for Wealthy**, plus smarts and
/// happiness. It was a free pick on the character sheet — the single largest
/// advantage in the game, handed over before the first year, with no cost and
/// no reason.
///
/// That is the wrong shape for this app twice over. As a game it means the
/// leaderboard compares people who started 2,500 coins apart. As a *lesson*
/// it is worse: nobody chooses the family they are born into, and an app about
/// money that lets you pick a rich one is teaching the opposite of the thing
/// it exists to teach.
///
/// So the origin is rolled. What stays yours is who you are — your **name**
/// and your **gender** — which are the two things a person actually does own.
///
/// # Why a visible seed rather than a hidden roll
///
/// A hidden roll is indistinguishable from the game cheating when a run goes
/// badly. A seed you can read, copy and type back in makes the randomness
/// *checkable*: the same seed always produces the same life, so a player can
/// replay the exact start they just had, or hand it to a friend and compare
/// what each of them did with it. Same idea as a Minecraft seed, and it turns
/// "I got unlucky" into a thing you can prove or disprove.
///
/// It also gives ranked runs the fair start `ranked_run.dart` already claimed
/// to have and never enforced.
///
/// # Why the odds are not uniform
///
/// 35 / 35 / 22 / 8. A uniform roll would make Wealthy a 1-in-4 start, which
/// quietly teaches that being born comfortable is the normal case. Most lives
/// begin without a cushion, which is both closer to true and the version of
/// this game that has anything to say.
class LifeSeed {
  const LifeSeed(this.value);

  /// Turns typed text into a seed.
  ///
  /// Accepts anything. A player typing "hello" gets a real, reproducible seed
  /// rather than an error — the point is that the same input gives the same
  /// life, not that the input looks like a number.
  factory LifeSeed.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return LifeSeed(DateTime.now().microsecondsSinceEpoch);

    final asNumber = int.tryParse(trimmed);
    if (asNumber != null) return LifeSeed(asNumber.abs());

    // FNV-1a, not `hashCode`: Dart seeds string hashing per isolate, so a
    // seed built on it would produce a different life every time the app
    // restarted — which would make a "seed" that does not reproduce anything.
    var hash = 0x811c9dc5;
    for (final unit in trimmed.toLowerCase().codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return LifeSeed(hash);
  }

  /// A fresh, unpredictable seed.
  factory LifeSeed.fresh() =>
      LifeSeed(DateTime.now().microsecondsSinceEpoch & 0x7fffffff);

  final int value;

  /// Short, readable, and easy to read aloud or type back in.
  String get display => value.toRadixString(36).toUpperCase().padLeft(6, '0');

  /// Deterministic 0..max-1 from this seed and a channel name.
  ///
  /// The channel keeps the draws independent: rolling the origin must not
  /// change what the map roll returns, or a seed's parts would shift against
  /// each other whenever one of them was reordered.
  int _roll(String channel, int max) {
    var hash = 0x811c9dc5;
    for (final unit in '$value|$channel'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return max <= 0 ? 0 : hash % max;
  }

  /// The family this seed is born into.
  ///
  /// Weighted 35/35/22/8. See the class comment for why it is not uniform.
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

  /// A suggested name, which the player is free to replace.
  String suggestedName(List<String> firstNames, List<String> lastNames) {
    if (firstNames.isEmpty || lastNames.isEmpty) return 'Casey Reyes';
    return '${firstNames[_roll('first', firstNames.length)]} '
        '${lastNames[_roll('last', lastNames.length)]}';
  }

  /// Which of the two towns this life lives in.
  int townIndex(int mapCount) => _roll('town', mapCount);

  @override
  bool operator ==(Object other) =>
      other is LifeSeed && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'LifeSeed($display)';
}
