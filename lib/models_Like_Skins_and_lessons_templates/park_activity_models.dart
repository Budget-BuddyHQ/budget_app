import 'dart:math';

import 'player_profile.dart';

/// What the park actually gives you to do.
///
/// # Why the park needed a mechanic at all
///
/// Every other building in town poses a question and takes an answer, and the
/// park was three sentences and three buttons. It is also the one place a
/// player walks to *for fun*, so a worksheet there would be the worst version
/// of this app. These are games first. The money idea is the rule of the game
/// rather than a lesson printed next to it.
///
///  * **Coin Rush** pays for noticing. Coins are worth collecting, fees are
///    not, and they arrive together and in a hurry.
///  * **Price Dash** is unit price under time pressure. The bigger box is
///    usually cheaper per unit and sometimes it is not, which is the trick
///    every shelf in a supermarket is running.
///
/// The rules live here, away from Flutter, so they can be tested as rules.
enum ParkActivity {
  coinRush('Coin Rush', 'Tap the coins. Leave the fees alone.'),
  priceDash('Price Dash', 'Which one is cheaper per unit?');

  const ParkActivity(this.title, this.blurb);

  final String title;
  final String blurb;
}

/// How long a round runs and how fast it moves, per age band.
///
/// Younger players get longer and slower, the same way `LeakRound.forBand`
/// handles Leak Patrol. A game that outruns a seven-year-old's reading is
/// testing eyesight rather than judgement.
class ParkPacing {
  const ParkPacing({
    required this.seconds,
    required this.spawnMillis,
    required this.fallSeconds,
    required this.questionSeconds,
    required this.rounds,
  });

  /// Length of a Coin Rush round.
  final int seconds;

  /// Gap between two things appearing in Coin Rush.
  final int spawnMillis;

  /// How long one item takes to cross the play area.
  final double fallSeconds;

  /// How long one Price Dash question stays answerable.
  final int questionSeconds;

  /// How many Price Dash questions make a round.
  final int rounds;

  factory ParkPacing.forBand(AgeBand band) => switch (band) {
    AgeBand.under9 => const ParkPacing(
      seconds: 25,
      spawnMillis: 900,
      fallSeconds: 4.4,
      questionSeconds: 12,
      rounds: 4,
    ),
    AgeBand.age9to12 => const ParkPacing(
      seconds: 25,
      spawnMillis: 750,
      fallSeconds: 3.6,
      questionSeconds: 10,
      rounds: 5,
    ),
    AgeBand.teen13to15 => const ParkPacing(
      seconds: 30,
      spawnMillis: 620,
      fallSeconds: 3.0,
      questionSeconds: 8,
      rounds: 5,
    ),
    AgeBand.teen16to17 => const ParkPacing(
      seconds: 30,
      spawnMillis: 560,
      fallSeconds: 2.7,
      questionSeconds: 7,
      rounds: 6,
    ),
    AgeBand.adult18plus => const ParkPacing(
      seconds: 30,
      spawnMillis: 520,
      fallSeconds: 2.5,
      questionSeconds: 7,
      rounds: 6,
    ),
    // Middle of the range, as everywhere else an undisclosed age is handled.
    AgeBand.undisclosed => const ParkPacing(
      seconds: 30,
      spawnMillis: 620,
      fallSeconds: 3.0,
      questionSeconds: 8,
      rounds: 5,
    ),
  };
}

/// One thing falling through a Coin Rush round.
enum FallingKind {
  /// Worth collecting.
  coin,

  /// A charge. Tapping it costs, leaving it costs nothing.
  fee,

  /// Worth more, and rarer.
  gem,
}

/// What one falling item is worth when tapped.
int valueOf(FallingKind kind) => switch (kind) {
  FallingKind.coin => 2,
  FallingKind.gem => 5,
  FallingKind.fee => -3,
};

/// Picks what falls next.
///
/// About a third are fees, so tapping everything loses. That ratio is the
/// whole game: a player who taps on reflex finishes below a player who looks,
/// which is the habit worth paying for.
FallingKind rollFalling(Random random) {
  final roll = random.nextInt(100);
  if (roll < 34) return FallingKind.fee;
  if (roll < 88) return FallingKind.coin;
  return FallingKind.gem;
}

/// One Price Dash question. Two real-shaped grocery options.
class PricePair {
  const PricePair({
    required this.item,
    required this.smallLabel,
    required this.smallPrice,
    required this.smallUnits,
    required this.bigLabel,
    required this.bigPrice,
    required this.bigUnits,
    required this.unit,
  });

  final String item;
  final String smallLabel;
  final double smallPrice;
  final double smallUnits;
  final String bigLabel;
  final double bigPrice;
  final double bigUnits;
  final String unit;

  double get smallPerUnit => smallPrice / smallUnits;
  double get bigPerUnit => bigPrice / bigUnits;

  /// Whether the larger pack is the better deal, which is usually but not
  /// always true. See [kPricePairs].
  bool get bigIsCheaper => bigPerUnit < smallPerUnit;

  String perUnitLabel(double perUnit) =>
      '\$${perUnit.toStringAsFixed(2)} per $unit';
}

/// The questions.
///
/// **Seven of the ten reward the bigger pack, and three do not.** That split
/// is deliberate and it is checked by a test. If the big pack always won, the
/// game would teach "buy the big one" rather than "check", and checking is
/// the part that transfers. If it usually lost, the game would be lying about
/// how shelves work. The three exceptions are the packs wearing the words
/// value, bonus and party box, because that is where the trick actually
/// lives.
const List<PricePair> kPricePairs = <PricePair>[
  PricePair(
    item: 'Rice',
    smallLabel: '500 g bag',
    smallPrice: 1.60,
    smallUnits: 500,
    bigLabel: '2 kg bag',
    bigPrice: 5.20,
    bigUnits: 2000,
    unit: '100 g',
  ),
  PricePair(
    item: 'Milk',
    smallLabel: '1 litre',
    smallPrice: 1.20,
    smallUnits: 1,
    bigLabel: '4 litres',
    bigPrice: 4.40,
    bigUnits: 4,
    unit: 'litre',
  ),
  PricePair(
    item: 'Cereal',
    smallLabel: '375 g box',
    smallPrice: 3.00,
    smallUnits: 375,
    bigLabel: '750 g box',
    bigPrice: 5.40,
    bigUnits: 750,
    unit: '100 g',
  ),
  PricePair(
    item: 'Washing powder',
    smallLabel: '1 kg',
    smallPrice: 4.00,
    smallUnits: 1000,
    bigLabel: '3 kg',
    bigPrice: 11.40,
    bigUnits: 3000,
    unit: '100 g',
  ),
  PricePair(
    item: 'Juice',
    smallLabel: '330 ml can',
    smallPrice: 0.90,
    smallUnits: 330,
    bigLabel: '1 litre carton',
    bigPrice: 2.40,
    bigUnits: 1000,
    unit: '100 ml',
  ),
  PricePair(
    item: 'Pasta',
    smallLabel: '500 g',
    smallPrice: 1.00,
    smallUnits: 500,
    bigLabel: '1 kg value pack',
    bigPrice: 2.30,
    bigUnits: 1000,
    unit: '100 g',
  ),
  PricePair(
    item: 'Shampoo',
    smallLabel: '250 ml',
    smallPrice: 2.50,
    smallUnits: 250,
    bigLabel: '400 ml bonus size',
    bigPrice: 4.40,
    bigUnits: 400,
    unit: '100 ml',
  ),
  PricePair(
    item: 'Batteries',
    smallLabel: '4 pack',
    smallPrice: 3.20,
    smallUnits: 4,
    bigLabel: '10 pack',
    bigPrice: 7.00,
    bigUnits: 10,
    unit: 'battery',
  ),
  PricePair(
    item: 'Crisps',
    smallLabel: '6 small bags',
    smallPrice: 2.40,
    smallUnits: 6,
    bigLabel: '12 bag party box',
    bigPrice: 5.40,
    bigUnits: 12,
    unit: 'bag',
  ),
  PricePair(
    item: 'Soap',
    smallLabel: '2 bars',
    smallPrice: 1.80,
    smallUnits: 2,
    bigLabel: '6 bar pack',
    bigPrice: 5.10,
    bigUnits: 6,
    unit: 'bar',
  ),
];

/// What a finished activity pays.
///
/// Gold is small on purpose. The town already pays for decisions, and a game
/// that out-earns the decisions would make the park the only place worth
/// walking to.
class ParkReward {
  const ParkReward({
    required this.gold,
    required this.literacy,
    required this.xp,
    required this.outcome,
  });

  final int gold;
  final int literacy;
  final int xp;

  /// What the player is told afterwards. Names the skill, not just the score.
  final String outcome;
}

/// Scores a Coin Rush round.
ParkReward scoreCoinRush({
  required int collected,
  required int feesTapped,
  required int coinsMissed,
}) {
  final gold = max(0, collected);
  final clean = feesTapped == 0;
  final outcome = clean
      ? 'Not one fee tapped. Noticing what not to grab is the whole skill, '
            'and it is the part people practice least.'
      : 'You caught $collected in coins and $feesTapped '
            '${feesTapped == 1 ? 'fee' : 'fees'}. Fees look like everything '
            'else at speed, which is exactly why they work.';
  return ParkReward(
    gold: gold,
    literacy: clean ? 4 : 2,
    xp: 6 + collected ~/ 4,
    outcome: outcome,
  );
}

/// Scores a Price Dash round.
ParkReward scorePriceDash({required int correct, required int total}) {
  final gold = correct * 3;
  final perfect = correct == total && total > 0;
  return ParkReward(
    gold: gold,
    literacy: perfect ? 5 : 3,
    xp: 5 + correct * 2,
    outcome: perfect
        ? 'All $total right. Price per unit is printed on most shelf labels, '
              'and it is the only number on there that compares two packs.'
        : 'You got $correct of $total. The bigger pack is usually cheaper per '
              'unit, and the times it is not are the ones with the word value '
              'or bonus on the front.',
  );
}
