import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_sim_models.dart';
import 'town_spot_models.dart';

/// What a player can choose to do with a year, beyond the big decisions.
///
/// **Asked for as:** *"the options are so simple, it's so boring"* and *"the late
/// game is so repetitive."* The Activities menu was eight rows, and by forty a
/// player had pressed every one of them and had nothing left to try. This is
/// the BitLife Activities screen, in this game's terms: a grid of categories,
/// each opening onto a list of things to do, each with a price, an age it opens
/// at, and a limit on how often it pays.
///
/// What is deliberately *not* here: crime, drugs, gambling and fighting. Life
/// is for ages nine and up and stays family friendly, and none of those teach
/// anything about money that the rest of the game does not teach better.
///
/// Pure data. The controller checks age, price and yearly limit, and applies it.

enum ActivityCategory {
  mindBody(
    'Mind and body',
    Icons.self_improvement_rounded,
    Color(0xFF4BD2A3),
    'Look after yourself. It pays back in everything else.',
  ),
  social(
    'Friends and community',
    Icons.groups_rounded,
    Color(0xFFFF8FB1),
    'Be around people. Clubs, parties and getting out.',
  ),
  love(
    'Love and dating',
    Icons.favorite_rounded,
    Color(0xFFFF6B9D),
    'Meet people who could matter.',
  ),
  travel(
    'Travel and fun',
    Icons.beach_access_rounded,
    Color(0xFFFFC857),
    'Trips cost money and give you something to remember.',
  ),
  learning(
    'Learning',
    Icons.school_rounded,
    Color(0xFFB388FF),
    'Get better at something.',
  ),
  money(
    'Earn on the side',
    Icons.savings_rounded,
    Color(0xFF85EFAC),
    'Small ways to make a little money.',
  ),
  sport(
    'Sport',
    Icons.sports_soccer_rounded,
    Color(0xFF58C7FF),
    'Join a team, train, and see how far it goes.',
  ),
  special(
    'Special careers',
    Icons.workspace_premium_rounded,
    Color(0xFFE9C46A),
    'Paths that are not on the job board.',
  );

  const ActivityCategory(this.label, this.icon, this.accent, this.blurb);

  final String label;
  final IconData icon;
  final Color accent;
  final String blurb;
}

/// One thing to do.
@immutable
class ActivityDef {
  const ActivityDef({
    required this.id,
    required this.category,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.outcome,
    this.cost = 0,
    this.minAge = 8,
    this.tiers = const <double>[1.0, 0.5, 0.25],
    this.happiness = 0,
    this.health = 0,
    this.smarts = 0,
    this.looks = 0,
    this.skill,
    this.skillGain = 0,
    this.friendsBoost = 0,
    this.meetsFriend = false,
    this.earnsMin = 0,
    this.earnsMax = 0,
    this.partnerChance = 0,
    this.teaches,
    this.place,
  });

  final String id;
  final ActivityCategory category;
  final String title;

  /// One line for the row, before it is done.
  final String blurb;
  final IconData icon;

  /// What happened, in one sentence, for the feed.
  final String outcome;

  /// Coins. A dependent's family pays it, which is why a child can go on a trip.
  final int cost;
  final int minAge;

  /// What each use pays, in order. The length is the yearly limit.
  final List<double> tiers;

  final int happiness;
  final int health;
  final int smarts;
  final int looks;
  final LifeSkill? skill;
  final int skillGain;

  /// Closeness added to every friend, for activities that are about friends.
  final int friendsBoost;

  /// Whether it can introduce you to somebody new.
  final bool meetsFriend;

  /// For earning activities: the range in coins. The result can be a loss.
  final int earnsMin;
  final int earnsMax;

  /// Percent chance of meeting a partner, for the dating activities.
  final int partnerChance;

  final FinanceConcept? teaches;

  /// The building in town where this is done, or null when it is done from the
  /// menu.
  ///
  /// **Asked for as:** *"you're still able to do hiking in the menu, where I want
  /// the user to do it in the open world."* A walk in the park is not a button.
  /// An activity with a place is left out of the Activities menu and offered
  /// inside that building on the town map, through the same yearly limits and
  /// the same effects, so nothing about how much it gives has changed, only
  /// where you go to do it.
  final TownSpotKind? place;

  int get cap => tiers.length;
  bool get earns => earnsMax != 0 || earnsMin != 0;
}

/// Every activity.
const List<ActivityDef> kActivities = <ActivityDef>[
  // ---- Mind and body --------------------------------------------------------
  ActivityDef(
    id: 'run',
    category: ActivityCategory.mindBody,
    title: 'Go for a run',
    blurb: 'Free, and your lungs will thank you.',
    icon: Icons.directions_run_rounded,
    outcome: 'You went for a run and felt better for it.',
    minAge: 8,
    health: 5,
    happiness: 1,
    place: TownSpotKind.park,
  ),
  ActivityDef(
    id: 'hike',
    category: ActivityCategory.mindBody,
    title: 'Go for a hike',
    blurb: 'Fresh air, nothing to buy.',
    icon: Icons.hiking_rounded,
    outcome: 'A long walk with a good view at the end.',
    minAge: 6,
    tiers: <double>[1.0, 0.5],
    health: 4,
    happiness: 3,
    place: TownSpotKind.park,
  ),
  ActivityDef(
    id: 'meditate',
    category: ActivityCategory.mindBody,
    title: 'Meditate',
    blurb: 'Ten quiet minutes, more or less every day.',
    icon: Icons.spa_rounded,
    outcome: 'You sat quietly and let your head settle.',
    minAge: 12,
    happiness: 5,
    smarts: 1,
    place: TownSpotKind.park,
  ),
  ActivityDef(
    id: 'stretch',
    category: ActivityCategory.mindBody,
    title: 'Stretch and breathe',
    blurb: 'A gentle way to feel looser.',
    icon: Icons.accessibility_new_rounded,
    outcome: 'You stretched out, and your back stopped complaining.',
    minAge: 10,
    health: 3,
    happiness: 3,
    place: TownSpotKind.park,
  ),
  ActivityDef(
    id: 'eat_well',
    category: ActivityCategory.mindBody,
    title: 'Eat well for a while',
    blurb: 'Better food costs a little more. It shows.',
    icon: Icons.restaurant_rounded,
    outcome: 'You cooked properly for a few weeks and felt the difference.',
    minAge: 12,
    cost: 25,
    tiers: <double>[1.0, 0.5],
    health: 5,
    teaches: FinanceConcept.needsVsWants,
  ),
  ActivityDef(
    id: 'read_book',
    category: ActivityCategory.mindBody,
    title: 'Read a good book',
    blurb: 'Free from the library, and it stays with you.',
    icon: Icons.auto_stories_rounded,
    outcome: 'You lost an afternoon in a book and came out cleverer.',
    minAge: 7,
    smarts: 3,
    happiness: 2,
    place: TownSpotKind.library,
  ),
  ActivityDef(
    id: 'haircut',
    category: ActivityCategory.mindBody,
    title: 'Get a haircut',
    blurb: 'A small change that people notice.',
    icon: Icons.content_cut_rounded,
    outcome: 'A fresh cut. You caught yourself smiling at a mirror.',
    minAge: 10,
    cost: 20,
    tiers: <double>[1.0, 0.5],
    looks: 4,
    happiness: 1,
  ),
  ActivityDef(
    id: 'clothes',
    category: ActivityCategory.mindBody,
    title: 'Buy new clothes',
    blurb: 'Feels great. Is it a need, or a want?',
    icon: Icons.checkroom_rounded,
    outcome: 'You bought something new and wore it the same day.',
    minAge: 12,
    cost: 60,
    tiers: <double>[1.0, 0.5],
    looks: 5,
    happiness: 3,
    teaches: FinanceConcept.needsVsWants,
  ),
  ActivityDef(
    id: 'foster_pet',
    category: ActivityCategory.mindBody,
    title: 'Foster a shelter pet for the week',
    blurb: 'Food, a leash, and a temporary roommate who sheds.',
    icon: Icons.cruelty_free_rounded,
    outcome: 'One chewed shoe, paw prints on everything, and a very good dog.',
    minAge: 10,
    cost: 15,
    tiers: <double>[1.0, 0.5],
    happiness: 6,
    teaches: FinanceConcept.needsVsWants,
    place: TownSpotKind.petShop,
  ),

  // ---- Friends and community ------------------------------------------------
  ActivityDef(
    id: 'hang_out',
    category: ActivityCategory.social,
    title: 'Hang out with friends',
    blurb: 'Nothing planned. Everyone you know a little closer.',
    icon: Icons.emoji_people_rounded,
    outcome: 'An easy day with the people who know you.',
    minAge: 8,
    happiness: 4,
    friendsBoost: 3,
    place: TownSpotKind.park,
  ),
  ActivityDef(
    id: 'party',
    category: ActivityCategory.social,
    title: 'Throw a party',
    blurb: 'Costs more than you think, and people talk about it for years.',
    icon: Icons.celebration_rounded,
    outcome: 'The house was full and loud, and it was a great night.',
    minAge: 14,
    cost: 90,
    tiers: <double>[1.0, 0.5],
    happiness: 8,
    friendsBoost: 5,
    teaches: FinanceConcept.impulseSpending,
  ),
  ActivityDef(
    id: 'concert',
    category: ActivityCategory.social,
    title: 'Go to a concert',
    blurb: 'Loud, crowded and worth it.',
    icon: Icons.music_note_rounded,
    outcome: 'You sang along to every song and lost your voice.',
    minAge: 12,
    cost: 50,
    tiers: <double>[1.0, 0.5],
    happiness: 7,
  ),
  ActivityDef(
    id: 'dinner_out',
    category: ActivityCategory.social,
    title: 'Dinner with friends',
    blurb: 'A long table and a shared bill.',
    icon: Icons.local_dining_rounded,
    outcome: 'Good food, long stories and a bill split five ways.',
    minAge: 14,
    cost: 45,
    tiers: <double>[1.0, 0.5],
    happiness: 5,
    friendsBoost: 3,
    place: TownSpotKind.cafe,
  ),
  ActivityDef(
    id: 'fair',
    category: ActivityCategory.social,
    title: 'Go to the community fair',
    blurb: 'Free, and you might meet someone.',
    icon: Icons.festival_rounded,
    outcome: 'Stalls, music and a lot of people you half know.',
    minAge: 6,
    tiers: <double>[1.0, 0.5],
    happiness: 3,
    meetsFriend: true,
    place: TownSpotKind.market,
  ),
  ActivityDef(
    id: 'club_chess',
    category: ActivityCategory.social,
    title: 'Join the chess club',
    blurb: 'Quiet, clever and surprisingly friendly.',
    icon: Icons.extension_rounded,
    outcome: 'You joined the chess club, lost four games, and made a friend.',
    minAge: 8,
    tiers: <double>[1.0],
    smarts: 4,
    meetsFriend: true,
  ),
  ActivityDef(
    id: 'club_drama',
    category: ActivityCategory.social,
    title: 'Join the drama club',
    blurb: 'Standing up in front of people gets easier.',
    icon: Icons.theater_comedy_rounded,
    outcome: 'You got a small part and forgot your line once.',
    minAge: 8,
    tiers: <double>[1.0],
    skill: LifeSkill.charisma,
    skillGain: 6,
    happiness: 3,
    meetsFriend: true,
  ),
  ActivityDef(
    id: 'club_coding',
    category: ActivityCategory.social,
    title: 'Join the coding club',
    blurb: 'Build things with people who like building things.',
    icon: Icons.code_rounded,
    outcome: 'You built a small game with two other people.',
    minAge: 9,
    tiers: <double>[1.0],
    smarts: 4,
    skill: LifeSkill.business,
    skillGain: 2,
    meetsFriend: true,
  ),
  ActivityDef(
    id: 'club_debate',
    category: ActivityCategory.social,
    title: 'Join the debate team',
    blurb: 'Learn to argue well and listen better.',
    icon: Icons.record_voice_over_rounded,
    outcome: 'You argued the other side on purpose, and it was good for you.',
    minAge: 11,
    tiers: <double>[1.0],
    smarts: 2,
    skill: LifeSkill.charisma,
    skillGain: 5,
    meetsFriend: true,
  ),
  ActivityDef(
    id: 'club_garden',
    category: ActivityCategory.social,
    title: 'Join the community garden',
    blurb: 'Dirty hands, fresh vegetables, easy company.',
    icon: Icons.yard_rounded,
    outcome: 'You grew something edible, which felt like a small miracle.',
    minAge: 8,
    tiers: <double>[1.0],
    health: 2,
    happiness: 4,
    meetsFriend: true,
  ),

  // ---- Love and dating -------------------------------------------------------
  ActivityDef(
    id: 'meet_new',
    category: ActivityCategory.love,
    title: 'Get to know somebody new',
    blurb: 'A new friend, if you make the effort.',
    icon: Icons.person_add_alt_1_rounded,
    outcome: 'You started a conversation instead of waiting for one.',
    minAge: 8,
    tiers: <double>[1.0, 0.5],
    happiness: 2,
    meetsFriend: true,
  ),
  ActivityDef(
    id: 'set_up',
    category: ActivityCategory.love,
    title: 'Ask a friend to set you up',
    blurb: 'Free, and people who know you choose better than an app.',
    icon: Icons.diversity_1_rounded,
    outcome: 'A friend said they knew just the person.',
    minAge: 18,
    tiers: <double>[1.0],
    partnerChance: 35,
  ),
  ActivityDef(
    id: 'dating_app',
    category: ActivityCategory.love,
    title: 'Try online dating',
    blurb: 'A small monthly fee and a lot of awkward messages.',
    icon: Icons.phone_iphone_rounded,
    outcome: 'You spent an evening swiping and sending messages.',
    minAge: 18,
    cost: 20,
    tiers: <double>[1.0, 0.5],
    partnerChance: 40,
  ),
  ActivityDef(
    id: 'speed_dating',
    category: ActivityCategory.love,
    title: 'Go speed dating',
    blurb: 'Twelve conversations in one evening.',
    icon: Icons.timer_rounded,
    outcome: 'Twelve short conversations and one long one.',
    minAge: 21,
    cost: 40,
    tiers: <double>[1.0],
    partnerChance: 50,
  ),
  ActivityDef(
    id: 'hobby_group',
    category: ActivityCategory.love,
    title: 'Join a hobby group to meet people',
    blurb: 'Free, and you show up already having something to talk about.',
    icon: Icons.diversity_3_rounded,
    outcome: 'Nobody there was trying to date anybody, which helped.',
    minAge: 18,
    tiers: <double>[1.0, 0.5],
    happiness: 2,
    partnerChance: 20,
  ),
  ActivityDef(
    id: 'ask_out',
    category: ActivityCategory.love,
    title: 'Ask somebody out directly',
    blurb: 'No app, no middleman. Free, and it can go either way fast.',
    icon: Icons.chat_bubble_outline_rounded,
    outcome: 'You just asked. However it went, you did not wonder.',
    minAge: 18,
    tiers: <double>[1.0, 0.5],
    partnerChance: 30,
  ),

  // ---- Travel and fun --------------------------------------------------------
  ActivityDef(
    id: 'amusement',
    category: ActivityCategory.travel,
    title: 'Visit the amusement park',
    blurb: 'Rides, snacks and one very long queue.',
    icon: Icons.attractions_rounded,
    outcome: 'You screamed on a rollercoaster and got sick on the second.',
    minAge: 6,
    cost: 30,
    tiers: <double>[1.0, 0.5],
    happiness: 6,
    place: TownSpotKind.park,
  ),
  ActivityDef(
    id: 'day_trip',
    category: ActivityCategory.travel,
    title: 'Take a day trip',
    blurb: 'Somewhere you have never been, home by dark.',
    icon: Icons.directions_bus_rounded,
    outcome: 'A day somewhere new, and a photo you actually like.',
    minAge: 10,
    cost: 50,
    tiers: <double>[1.0, 0.5],
    happiness: 6,
    smarts: 1,
    place: TownSpotKind.park,
  ),
  ActivityDef(
    id: 'weekend',
    category: ActivityCategory.travel,
    title: 'A weekend away',
    blurb: 'Two nights, one small suitcase.',
    icon: Icons.luggage_rounded,
    outcome: 'Two nights somewhere else made everything at home feel lighter.',
    minAge: 16,
    cost: 150,
    tiers: <double>[1.0],
    happiness: 10,
    smarts: 1,
  ),
  ActivityDef(
    id: 'holiday',
    category: ActivityCategory.travel,
    title: 'A proper holiday',
    blurb: 'Two weeks away. Best paid for from money you set aside.',
    icon: Icons.flight_takeoff_rounded,
    outcome: 'Two weeks away. You came back tanned, rested and a bit poorer.',
    minAge: 18,
    cost: 450,
    tiers: <double>[1.0],
    happiness: 16,
    smarts: 3,
    health: 2,
    teaches: FinanceConcept.payYourselfFirst,
  ),
  ActivityDef(
    id: 'camping',
    category: ActivityCategory.travel,
    title: 'Go camping',
    blurb: 'A tent, a fire and the cheapest trip that still counts as one.',
    icon: Icons.forest_rounded,
    outcome: 'No signal for two days, and nobody missed it after the first.',
    minAge: 8,
    cost: 20,
    tiers: <double>[1.0, 0.5],
    happiness: 7,
    health: 2,
    teaches: FinanceConcept.needsVsWants,
  ),
  ActivityDef(
    id: 'visit_relatives',
    category: ActivityCategory.travel,
    title: 'Visit family out of town',
    blurb: 'A long drive, a full table, and a spare room that smells like it.',
    icon: Icons.family_restroom_rounded,
    outcome: 'The drive was long. The welcome made up for it.',
    minAge: 6,
    cost: 35,
    tiers: <double>[1.0, 0.5],
    happiness: 5,
  ),

  // ---- Learning ---------------------------------------------------------------
  ActivityDef(
    id: 'museum',
    category: ActivityCategory.learning,
    title: 'Visit a museum',
    blurb: 'Cheap, quiet and full of surprises.',
    icon: Icons.museum_rounded,
    outcome: 'You read every label, which nobody does.',
    minAge: 6,
    cost: 10,
    tiers: <double>[1.0, 0.5],
    smarts: 2,
    happiness: 2,
    place: TownSpotKind.library,
  ),
  ActivityDef(
    id: 'language',
    category: ActivityCategory.learning,
    title: 'Learn a language',
    blurb: 'A few months of lessons and a lot of embarrassment.',
    icon: Icons.translate_rounded,
    outcome: 'You ordered lunch in a new language and it worked.',
    minAge: 12,
    cost: 40,
    tiers: <double>[1.0, 0.5],
    smarts: 5,
  ),
  ActivityDef(
    id: 'online_course',
    category: ActivityCategory.learning,
    title: 'Take an online course',
    blurb: 'Learn at night, in your own time.',
    icon: Icons.laptop_chromebook_rounded,
    outcome: 'Six weeks of evenings, and a certificate at the end.',
    minAge: 16,
    cost: 60,
    tiers: <double>[1.0, 0.5],
    smarts: 6,
    skill: LifeSkill.business,
    skillGain: 3,
  ),
  ActivityDef(
    id: 'science_center',
    category: ActivityCategory.learning,
    title: 'Visit a science center',
    blurb: 'Buttons to press and things that actually happen.',
    icon: Icons.science_rounded,
    outcome: 'You pressed every button labelled "do not press."',
    minAge: 6,
    cost: 12,
    tiers: <double>[1.0, 0.5],
    smarts: 3,
    happiness: 3,
    place: TownSpotKind.library,
  ),
  ActivityDef(
    id: 'public_speaking',
    category: ActivityCategory.learning,
    title: 'Take a public speaking class',
    blurb: 'Six sessions, and less shaking by the last one.',
    icon: Icons.record_voice_over_rounded,
    outcome: 'Your voice only shook for the first two minutes this time.',
    minAge: 13,
    cost: 35,
    tiers: <double>[1.0, 0.5],
    smarts: 3,
    skill: LifeSkill.charisma,
    skillGain: 4,
    teaches: FinanceConcept.opportunityCost,
  ),

  // ---- Earn on the side --------------------------------------------------------
  ActivityDef(
    id: 'yard_sale',
    category: ActivityCategory.money,
    title: 'Have a yard sale',
    blurb: 'Sell what you no longer use. Free to try.',
    icon: Icons.sell_rounded,
    outcome: 'You sold things you had forgotten you owned.',
    minAge: 8,
    tiers: <double>[1.0],
    earnsMin: 15,
    earnsMax: 45,
    teaches: FinanceConcept.incomeVsWealth,
  ),
  ActivityDef(
    id: 'market_stand',
    category: ActivityCategory.money,
    title: 'Sell at the weekend market',
    blurb: 'You pay for a stall and hope people come. Some days they do not.',
    icon: Icons.storefront_rounded,
    outcome: 'You paid for the stall, set up and waited.',
    minAge: 10,
    cost: 20,
    tiers: <double>[1.0, 0.5],
    earnsMin: -10,
    earnsMax: 70,
    teaches: FinanceConcept.incomeVsWealth,
  ),
  ActivityDef(
    id: 'tutor',
    category: ActivityCategory.money,
    title: 'Tutor a younger student',
    blurb: 'Steady money for your hours, and you learn it twice.',
    icon: Icons.cast_for_education_rounded,
    outcome: 'Two afternoons of homework help.',
    minAge: 14,
    tiers: <double>[1.0, 0.5],
    smarts: 1,
    earnsMin: 25,
    earnsMax: 60,
  ),
  ActivityDef(
    id: 'dog_walking',
    category: ActivityCategory.money,
    title: 'Walk dogs for the neighbors',
    blurb: 'No cost to start, and every dog is a different client.',
    icon: Icons.pets_rounded,
    outcome: 'Three dogs, two leashes tangled, one grateful neighbor.',
    minAge: 9,
    tiers: <double>[1.0, 0.5, 0.25],
    happiness: 2,
    earnsMin: 10,
    earnsMax: 30,
    teaches: FinanceConcept.incomeVsWealth,
  ),
  ActivityDef(
    id: 'freelance_gig',
    category: ActivityCategory.money,
    title: 'Freelance a small project online',
    blurb: 'Paid by the job, not by the hour. The client picks which.',
    icon: Icons.laptop_mac_rounded,
    outcome: 'The brief changed twice, and you still delivered on time.',
    minAge: 16,
    tiers: <double>[1.0, 0.5],
    skill: LifeSkill.business,
    skillGain: 2,
    earnsMin: 20,
    earnsMax: 90,
    teaches: FinanceConcept.incomeVsWealth,
  ),
  ActivityDef(
    id: 'check_credit_report',
    category: ActivityCategory.money,
    title: 'Check your credit report',
    blurb: 'Free once a year — the one report nobody checks until they need it.',
    icon: Icons.fact_check_rounded,
    outcome: 'On-time bills built it up. The one you missed is still on there too.',
    minAge: 16,
    tiers: <double>[1.0, 0.5],
    smarts: 2,
    teaches: FinanceConcept.creditScore,
  ),
];

ActivityDef? activityById(String id) {
  for (final a in kActivities) {
    if (a.id == id) return a;
  }
  return null;
}

/// What the Activities menu lists: everything that is not done at a place in
/// town.
List<ActivityDef> activitiesIn(ActivityCategory category) => [
  for (final a in kActivities)
    if (a.category == category && a.place == null) a,
];

/// The activities done at [kind] in town.
List<ActivityDef> activitiesAt(TownSpotKind kind) => [
  for (final a in kActivities)
    if (a.place == kind) a,
];

// ---------------------------------------------------------------------------
// Sport
// ---------------------------------------------------------------------------

/// A sport a player can join a team in.
enum LifeSport {
  soccer('Soccer', Icons.sports_soccer_rounded, 'The world game.'),
  basketball('Basketball', Icons.sports_basketball_rounded, 'Fast and tall.'),
  track(
    'Track and field',
    Icons.directions_run_rounded,
    'You against a clock.',
  ),
  swimming('Swimming', Icons.pool_rounded, 'Early mornings and long lengths.'),
  tennis('Tennis', Icons.sports_tennis_rounded, 'One on one, with rackets.'),
  volleyball(
    'Volleyball',
    Icons.sports_volleyball_rounded,
    'Teamwork over a net.',
  );

  const LifeSport(this.label, this.icon, this.blurb);

  final String label;
  final IconData icon;
  final String blurb;
}

/// The chance of making the team, 0 to 100.
///
/// A mix of skill already built (`LifeSkill.sports`) and being physically well.
/// It is never 0 and never certain, so trying is always worth it and practice
/// always matters.
int tryoutChance({required int skill, required int health}) =>
    (35 + skill * 0.55 + (health - 50) * 0.3).round().clamp(10, 95);

/// How the team's year went, from the player's standing on it.
String seasonSummary(LifeSport sport, int standing) {
  if (standing >= 88) return 'a superb season, and you were the star';
  if (standing >= 72) return 'a strong season, and you were a key player';
  if (standing >= 55) return 'a decent season, and you held your place';
  if (standing >= 38) {
    return 'a hard season, and you spent a lot of it on the bench';
  }
  return 'a poor season, and the coach said you needed to train more';
}

/// The next year's standing on a team.
///
/// Skill and being well set the level; training moves it; a bit of luck.
/// Standing drifts back a little each year, so it has to be kept up.
int nextStanding({
  required int standing,
  required int skill,
  required int health,
  required int trainingUses,
  required int luck,
}) {
  final target = 40 + skill * 0.45 + (health - 50) * 0.25 + trainingUses * 6;
  return (standing * 0.55 + target * 0.45 + luck).round().clamp(0, 100);
}
