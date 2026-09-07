import 'finance_concepts.dart';

/// Things the townspeople actually want you to do.
///
/// # Why
///
/// Reported as: *"Make the NPCs do more — they all just give quotes right
/// now. Make them give like a mission or some consequences or something."*
///
/// That is exactly right, and the reason is not that quotes are boring. A
/// line of dialogue cannot be *acted on*, so an NPC delivering one is set
/// dressing that happens to be shaped like a person. Seven of them saying
/// sensible things about money is seven posters you have to walk up to.
///
/// A mission changes what the town is for. It gives you a reason to go to a
/// specific building rather than the nearest one, a reason to come back
/// tomorrow, and — the part that matters here — a **consequence**, so that
/// ignoring it costs something and finishing it pays.
///
/// # The rule these are written to
///
/// Every mission is completable by *playing the game as it already exists*.
/// Nothing here asks for a new verb. They are goals expressed in things the
/// town can already observe: money saved, buildings visited, challenges
/// answered correctly, a life reaching an age. That is deliberate — a quest
/// system that needs its own mechanics is a second game bolted to the side of
/// this one, and it would rot the moment either half changed.
///
/// # Why the consequence is small
///
/// A mission that fails loudly, takes your money, or blocks progress would
/// turn a town for four-to-twenty-one-year-olds into something with a fail
/// state attached to a stranger's opinion. What expiring costs you here is
/// the *reward* and the person's regard — the mission simply lapses and the
/// NPC says so. That is a real consequence without being a punishment, and it
/// is the same principle the rest of the app follows: never grade the player,
/// show them what happened.

/// What the town can watch for.
///
/// Each of these maps to a number the app already keeps, which is what makes
/// missions verifiable without new bookkeeping.
enum MissionGoal {
  /// Save a given number of coins beyond what you had when it was offered.
  saveCoins,

  /// Visit N distinct buildings.
  visitPlaces,

  /// Answer N building challenges correctly.
  solveChallenges,

  /// Reach a given age in the current life.
  reachAge,

  /// Finish N lessons in the Academy.
  finishLessons,
}

/// A job from somebody in the town.
class TownMission {
  const TownMission({
    required this.id,
    required this.npcId,
    required this.title,
    required this.brief,
    required this.goal,
    required this.target,
    required this.rewardGold,
    required this.rewardLiteracy,
    required this.onSuccess,
    required this.onLapse,
    required this.concept,
    this.minAge = 0,
    this.expiresInYears = 5,
  });

  final String id;
  final String npcId;
  final String title;

  /// What they ask, in their own voice.
  final String brief;

  final MissionGoal goal;
  final int target;

  final int rewardGold;
  final int rewardLiteracy;

  /// What they say when you come back having done it.
  final String onSuccess;

  /// What they say when it runs out. **Not a telling-off.**
  ///
  /// The consequence is losing the reward and hearing that it lapsed. An NPC
  /// who is disappointed in a nine-year-old about money is a design mistake
  /// dressed as depth.
  final String onLapse;

  final FinanceConcept concept;

  /// Below this age the mission is not offered at all.
  ///
  /// Not greyed out — omitted. A locked row that names a number is still an
  /// advertisement, which is the lesson the wagering gate taught.
  final int minAge;

  /// In-game years before it lapses.
  final int expiresInYears;
}

/// Every mission in the town.
///
/// Deliberately more than one per person: an NPC with a single job becomes a
/// dead end the moment it is done, and the whole point is that walking past
/// somebody is worth doing again next year.
const List<TownMission> kTownMissions = <TownMission>[
  // --- the shopper: value, not price ----------------------------------
  TownMission(
    id: 'mission_unit_price',
    npcId: 'npc_shopper',
    title: 'Prove you can spot value',
    brief:
        'Anyone can find the cheap one. Come back when you have worked out '
        'the best *value* three times — the price on the label is not the '
        'number that matters.',
    goal: MissionGoal.solveChallenges,
    target: 3,
    rewardGold: 40,
    rewardLiteracy: 3,
    onSuccess:
        'Three for three. Most grown-ups in this town buy the small box '
        'because the number on it is smaller.',
    onLapse:
        'You never came back for that one. The offer is gone, but the skill '
        'is still worth having.',
    concept: FinanceConcept.opportunityCost,
  ),
  TownMission(
    id: 'mission_walk_town',
    npcId: 'npc_shopper',
    title: 'Learn the town',
    brief:
        'You cannot know where the good prices are if you only ever come '
        'here. Go and look inside five different places.',
    goal: MissionGoal.visitPlaces,
    target: 5,
    rewardGold: 30,
    rewardLiteracy: 2,
    onSuccess:
        'Now you know what things cost in more than one shop. That is most '
        'of what shopping around is.',
    onLapse: 'You stopped exploring. Nothing lost but the reward.',
    concept: FinanceConcept.opportunityCost,
  ),

  // --- the saver: the long game ----------------------------------------
  TownMission(
    id: 'mission_first_hundred',
    npcId: 'npc_saver',
    title: 'The first hundred',
    brief:
        'Put a hundred coins away and leave them there. The first hundred is '
        'the hardest — every one after it is easier, and I will tell you why '
        'when you have done it.',
    goal: MissionGoal.saveCoins,
    target: 100,
    rewardGold: 60,
    rewardLiteracy: 4,
    onSuccess:
        'Here is why: that hundred now earns on its own. You will never again '
        'be starting from nothing, and that is a different thing to be.',
    onLapse:
        'The hundred never landed. It is not a race — the offer expires, the '
        'idea does not.',
    concept: FinanceConcept.payYourselfFirst,
    minAge: 8,
  ),
  TownMission(
    id: 'mission_read_up',
    npcId: 'npc_saver',
    title: 'Read before you sign',
    brief:
        'People lose more money to things they did not read than to things '
        'they did not know. Finish four lessons and come back.',
    goal: MissionGoal.finishLessons,
    target: 4,
    rewardGold: 45,
    rewardLiteracy: 5,
    onSuccess:
        'Good. You are now harder to sell something bad to, which is worth '
        'more than any interest rate I can offer you.',
    onLapse: 'The lessons are still there whenever you want them.',
    concept: FinanceConcept.creditScore,
    minAge: 10,
  ),

  // --- the student: growing up -----------------------------------------
  TownMission(
    id: 'mission_reach_sixteen',
    npcId: 'npc_student',
    title: 'Get to sixteen with something saved',
    brief:
        'Most people arrive at sixteen with nothing put by and think that is '
        'normal. Get there having saved anything at all and you are already '
        'ahead.',
    goal: MissionGoal.reachAge,
    target: 16,
    rewardGold: 80,
    rewardLiteracy: 5,
    onSuccess:
        'You made it with money in hand. The habit is the point — the amount '
        'grows on its own from here.',
    onLapse: 'That life is over. The next one starts at zero, same as this.',
    concept: FinanceConcept.compoundGrowth,
    expiresInYears: 20,
  ),

  // --- the neighbour: patience -----------------------------------------
  TownMission(
    id: 'mission_slow_money',
    npcId: 'npc_neighbour',
    title: 'Something that takes time',
    brief:
        'Nothing worth having arrives in a week. Save two hundred without '
        'spending it on the way and I will show you what patience is worth.',
    goal: MissionGoal.saveCoins,
    target: 200,
    rewardGold: 100,
    rewardLiteracy: 6,
    onSuccess:
        'Two hundred, kept. Everyone can earn money — keeping it is the rare '
        'part, and you have just proved you can.',
    onLapse:
        'It got spent. That happens, and it is worth noticing what on.',
    concept: FinanceConcept.emergencyFund,
    minAge: 12,
  ),

  // --- the worker: earning ---------------------------------------------
  TownMission(
    id: 'mission_solve_five',
    npcId: 'npc_worker',
    title: 'Work out five before I finish this song',
    brief:
        'Five money puzzles, anywhere in town, all correct. Nobody pays you '
        'for turning up — they pay you for getting them right.',
    goal: MissionGoal.solveChallenges,
    target: 5,
    rewardGold: 70,
    rewardLiteracy: 5,
    onSuccess:
        'Five out of five. That is not luck any more, that is arithmetic.',
    onLapse: 'The offer ran out. Come and find me again.',
    concept: FinanceConcept.needsVsWants,
  ),

  // --- the tax collector: the money you never see ----------------------
  //
  // The one adult subject children are told nothing about until it is
  // already happening to them. Framed as a thing to understand rather than a
  // thing to fear, because the alternative is teaching dread.
  TownMission(
    id: 'mission_understand_tax',
    npcId: 'npc_taxer',
    title: 'Find out where it goes',
    brief:
        'Most people meet me for the first time on their first payslip and '
        'get a shock. Finish six lessons and you will know what the gap '
        'between earned and paid actually is.',
    goal: MissionGoal.finishLessons,
    target: 6,
    rewardGold: 55,
    rewardLiteracy: 5,
    onSuccess:
        'Now the number on your payslip will not surprise you. That is the '
        'whole trick — none of it is hidden, most people just never look.',
    onLapse: 'You will meet me again either way. Better to have looked.',
    concept: FinanceConcept.taxes,
    minAge: 12,
  ),
];

/// Missions offered by one NPC, filtered by age.
List<TownMission> missionsFor(String npcId, {required int age}) => [
  for (final m in kTownMissions)
    if (m.npcId == npcId && age >= m.minAge) m,
];

/// The mission an NPC should offer next.
///
/// Returns null when everything they have is finished or out of reach for
/// this age. An NPC with nothing to give falls back to their lines, which is
/// what those were always for — flavour between jobs rather than instead of
/// them.
TownMission? nextMissionFor(
  String npcId, {
  required int age,
  required Set<String> completed,
}) {
  for (final m in missionsFor(npcId, age: age)) {
    if (!completed.contains(m.id)) return m;
  }
  return null;
}

/// Whether a mission's goal has been met.
///
/// Pure, and taking plain numbers rather than a controller, so the rules can
/// be tested against a player who has saved 99 coins and visited four places
/// without building one.
bool missionComplete(
  TownMission mission, {
  required int coinsSaved,
  required int placesVisited,
  required int challengesSolved,
  required int age,
  required int lessonsFinished,
}) => switch (mission.goal) {
  MissionGoal.saveCoins => coinsSaved >= mission.target,
  MissionGoal.visitPlaces => placesVisited >= mission.target,
  MissionGoal.solveChallenges => challengesSolved >= mission.target,
  MissionGoal.reachAge => age >= mission.target,
  MissionGoal.finishLessons => lessonsFinished >= mission.target,
};

/// How far along, 0..1, for a progress bar.
double missionProgress(
  TownMission mission, {
  required int coinsSaved,
  required int placesVisited,
  required int challengesSolved,
  required int age,
  required int lessonsFinished,
}) {
  if (mission.target <= 0) return 1;
  final current = switch (mission.goal) {
    MissionGoal.saveCoins => coinsSaved,
    MissionGoal.visitPlaces => placesVisited,
    MissionGoal.solveChallenges => challengesSolved,
    MissionGoal.reachAge => age,
    MissionGoal.finishLessons => lessonsFinished,
  };
  return (current / mission.target).clamp(0.0, 1.0);
}
