import 'finance_concepts.dart';
import 'town_spot_models.dart';

/// Playable money puzzles for the town's buildings.
///
/// # Why this exists
///
/// Walking into the library produced a dialogue: *"You need somewhere quiet
/// for three hours."* — Book the room / Go to the cafe / Work at home. Three
/// buttons, no wrong answer, and the Life menu already had a "Visit the
/// library" row doing the same job. Every building was the same shape, so the
/// map was a second menu with a longer walk, and the reason to visit it was
/// nothing more than "the numbers are different here".
///
/// **A challenge has a right answer.** That is the whole distinction. You can
/// be wrong, you find out immediately, and you are shown the arithmetic that
/// decided it. A dialogue asks what you would like; a challenge asks whether
/// you can work it out — and only the second one can teach.
///
/// # Why the numbers are generated rather than written
///
/// Every challenge here is *computed*: the options carry real prices and
/// sizes, and the correct index is derived by doing the maths, never by an
/// author deciding which button is best. Three consequences, and they are the
/// reason it is built this way:
///
/// * It cannot be wrong. A hand-authored "best value" answer is one typo away
///   from teaching a child the opposite of the truth, on the one screen that
///   claims to be checking their arithmetic.
/// * It cannot be memorised. The prices move with the seed, so a player who
///   returns has to actually compare again — which is the skill.
/// * It is effectively unlimited content from a small amount of code, which
///   matters for a town somebody is meant to revisit for years of in-game
///   time.
///
/// # Why these five skills
///
/// Each one is a decision an adult makes badly and often, and each is small
/// enough to state in a sentence:
///
/// * **Unit price** — the supermarket's oldest trick. The bigger box is
///   usually cheaper per unit, and *sometimes deliberately is not*.
/// * **Percent versus amount** — "30% off" against "$10 off" cannot be
///   compared without knowing the price, and most people compare them anyway.
/// * **Compound growth** — the difference between saving early and saving
///   more, which is the single most valuable idea in the whole app.
/// * **Subscription true cost** — a monthly price is designed to be compared
///   with nothing. Multiplied out, it is a number people would refuse.
/// * **Tip and total** — arithmetic under mild social pressure, which is when
///   people are worst at it.
///
/// The seed is FNV-1a rather than `Object.hash`, which Dart seeds *per
/// isolate* — so a hash-based rotation changes every time the app restarts.
/// That bug has been fixed once already in `town_scenarios.dart`; it is not
/// being reintroduced here.

/// One selectable answer.
class ChallengeOption {
  const ChallengeOption({
    required this.label,
    required this.detail,
    required this.score,
  });

  /// What the player reads, e.g. "2 litre bottle — 180 coins".
  final String label;

  /// The working, revealed **after** answering: "90 coins per litre".
  ///
  /// Deliberately hidden until then. Showing the unit price up front turns
  /// the puzzle into a reading exercise, which is the mistake most "teaching"
  /// apps make — the arithmetic is the lesson, so the player has to do it.
  final String detail;

  /// The number the grading compares. Lower is better for costs, higher for
  /// growth — [TownChallenge.lowerIsBetter] says which.
  final double score;
}

/// A gradeable money puzzle attached to a building.
class TownChallenge {
  const TownChallenge({
    required this.id,
    required this.title,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.concept,
    required this.lowerIsBetter,
    required this.reward,
  });

  final String id;
  final String title;
  final String prompt;
  final List<ChallengeOption> options;

  /// Derived by comparing [ChallengeOption.score], never authored.
  final int correctIndex;

  /// The rule in one sentence, shown after answering either way.
  ///
  /// Shown on a correct answer too. Getting it right by instinct and getting
  /// it right by understanding look identical from outside, and only one of
  /// them survives a harder question later.
  final String explanation;

  final FinanceConcept concept;
  final bool lowerIsBetter;

  /// Literacy points for a correct answer.
  final int reward;

  ChallengeOption get best => options[correctIndex];
}

/// Deterministic across processes, machines and restarts.
///
/// `Object.hash` and `String.hashCode` are seeded per isolate in Dart, so a
/// rotation built on them silently re-deals every time the app is restarted.
int stableChallengeHash(String value) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < value.length; i++) {
    hash ^= value.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// A tiny deterministic generator.
///
/// Not `dart:math`'s `Random`: this has to produce the same town for the same
/// player on the same day on any device, and be reproducible in a test from
/// its seed alone.
class _Rolls {
  _Rolls(this._seed);
  int _seed;

  int next(int maxExclusive) {
    // Lehmer / Park-Miller. Small, well understood, and enough for choosing
    // prices — this is not cryptography and does not pretend to be.
    _seed = (_seed * 48271) % 0x7fffffff;
    if (_seed == 0) _seed = 1;
    return _seed % maxExclusive;
  }

  int between(int lo, int hi) => lo + next(hi - lo + 1);
}

/// Which challenges suit which building.
///
/// A bank asking about unit pricing would be the same "any content anywhere"
/// mistake the dialogues made. The building is a promise about the kind of
/// decision inside it.
const Map<TownSpotKind, List<String>> kChallengesByKind =
    <TownSpotKind, List<String>>{
      TownSpotKind.market: ['unit_price', 'percent_off'],
      TownSpotKind.store: ['unit_price', 'percent_off'],
      TownSpotKind.bank: ['compound', 'subscription'],
      TownSpotKind.cafe: ['tip', 'subscription'],
      TownSpotKind.pawnShop: ['percent_off'],
      TownSpotKind.library: ['subscription', 'compound'],
      TownSpotKind.school: ['compound'],
      TownSpotKind.clinic: ['percent_off'],
      TownSpotKind.noticeBoard: ['subscription'],
    };

/// The challenge for a building, on a given day, at a given age.
///
/// Returns null for buildings with no challenge — the park and your own house
/// are places to *be*, and putting arithmetic in them would make the whole
/// town feel like a worksheet.
///
/// [age] gates difficulty rather than availability: a six-year-old gets unit
/// pricing with small round numbers, a teenager gets compounding. Nothing is
/// hidden from a younger player that they could actually do.
TownChallenge? townChallengeFor(
  TownSpotKind kind, {
  required int age,
  required int daySeed,
}) {
  final pool = kChallengesByKind[kind];
  if (pool == null || pool.isEmpty) return null;

  final seed = stableChallengeHash('$kind:$daySeed:${age ~/ 3}');
  final rolls = _Rolls(seed == 0 ? 1 : seed);

  // Under about nine, compounding and subscriptions are arithmetic a player
  // has not met yet. They fall back to unit price, which is the same skill
  // at a size that fits.
  final young = age < 9;
  var type = pool[rolls.next(pool.length)];
  if (young && type != 'unit_price' && type != 'percent_off') {
    type = 'unit_price';
  }

  return switch (type) {
    'unit_price' => _unitPrice(rolls, young: young),
    'percent_off' => _percentOff(rolls, young: young),
    'compound' => _compound(rolls),
    'subscription' => _subscription(rolls),
    'tip' => _tip(rolls),
    _ => _unitPrice(rolls, young: young),
  };
}

/// Picks the index of the best score, and asserts it is unambiguous.
///
/// A puzzle with two equally-correct answers is a puzzle that marks a right
/// answer wrong, which is worse than no puzzle at all. Every generator below
/// is built so ties cannot happen; this is the guard that says so out loud.
int _bestIndex(List<ChallengeOption> options, {required bool lowerIsBetter}) {
  var bestAt = 0;
  for (var i = 1; i < options.length; i++) {
    final better = lowerIsBetter
        ? options[i].score < options[bestAt].score
        : options[i].score > options[bestAt].score;
    if (better) bestAt = i;
  }
  assert(
    options.where((o) => o.score == options[bestAt].score).length == 1,
    'town challenge has a tie for the correct answer',
  );
  return bestAt;
}

TownChallenge _unitPrice(_Rolls rolls, {required bool young}) {
  const goods = <List<String>>[
    ['rice', 'kg'],
    ['juice', 'litre'],
    ['soap', 'bar'],
    ['pasta', 'kg'],
    ['milk', 'litre'],
  ];
  final good = goods[rolls.next(goods.length)];
  final name = good[0];
  final unit = good[1];

  // Per-unit prices that are distinct by construction, so no tie is possible.
  final base = young ? rolls.between(4, 9) : rolls.between(11, 26);
  final perUnit = <int>[base, base + rolls.between(1, 4), base - 1];
  final sizes = <int>[1, 2, 4];

  final options = <ChallengeOption>[
    for (var i = 0; i < 3; i++)
      ChallengeOption(
        label: '$name — ${sizes[i]} $unit for '
            '${perUnit[i] * sizes[i]} coins',
        detail: '${perUnit[i]} coins per $unit',
        score: perUnit[i].toDouble(),
      ),
  ];

  return TownChallenge(
    id: 'unit_price',
    title: 'Best value',
    prompt: 'Three sizes of $name. Which one costs least per $unit?',
    options: options,
    correctIndex: _bestIndex(options, lowerIsBetter: true),
    explanation:
        'Divide the price by the size. The biggest box is usually cheapest '
        'per $unit — and shops know you assume that, so sometimes it is not.',
    concept: FinanceConcept.opportunityCost,
    lowerIsBetter: true,
    reward: 2,
  );
}

TownChallenge _percentOff(_Rolls rolls, {required bool young}) {
  final price = young ? rolls.between(20, 40) : rolls.between(60, 200);
  final pct = <int>[10, 20, 25, 30, 40][rolls.next(5)];
  final flat = rolls.between(8, 30);

  // Two ways of saying "cheaper", which cannot be compared by eye.
  final afterPct = price * (100 - pct) / 100;
  final afterFlat = (price - flat).toDouble();

  final options = <ChallengeOption>[
    ChallengeOption(
      label: '$pct% off $price coins',
      detail: 'You pay ${afterPct.toStringAsFixed(0)} coins',
      score: afterPct,
    ),
    ChallengeOption(
      label: '$flat coins off $price coins',
      detail: 'You pay ${afterFlat.toStringAsFixed(0)} coins',
      score: afterFlat,
    ),
  ];

  // A tie is possible here from the arithmetic, unlike the other generators,
  // so it is nudged rather than asserted away — silently marking a correct
  // answer wrong is the one outcome this must never produce.
  if (afterPct == afterFlat) {
    return _percentOff(_Rolls(rolls.next(99991) + 7), young: young);
  }

  return TownChallenge(
    id: 'percent_off',
    title: 'Which deal is bigger?',
    prompt: 'The same item, two offers. Which leaves you paying less?',
    options: options,
    correctIndex: _bestIndex(options, lowerIsBetter: true),
    explanation:
        'A percentage is meaningless until you know what it is a percentage '
        'of. $pct% of $price is ${(price * pct / 100).toStringAsFixed(0)} '
        'coins — compare that with the $flat off, not with the number itself.',
    concept: FinanceConcept.opportunityCost,
    lowerIsBetter: true,
    reward: 3,
  );
}

TownChallenge _compound(_Rolls rolls) {
  final amount = rolls.between(2, 9) * 100;
  final rate = <int>[4, 5, 6, 8][rolls.next(4)];
  final years = <int>[5, 10, 20][rolls.next(3)];

  double grow(int a, int r, int y) {
    var total = a.toDouble();
    for (var i = 0; i < y; i++) {
      total *= 1 + r / 100;
    }
    return total;
  }

  final real = grow(amount, rate, years);
  // The classic wrong answer: simple interest, which is what people expect
  // and is always too low. Naming it as the plausible distractor is the
  // point of the question.
  final simple = amount + amount * rate / 100 * years;
  final tooHigh = real * 1.6;

  final options = <ChallengeOption>[
    ChallengeOption(
      label: '${simple.round()} coins',
      detail: 'That is simple interest — the same amount added each year',
      score: (simple - real).abs(),
    ),
    ChallengeOption(
      label: '${real.round()} coins',
      detail: 'Correct. Each year earns interest on the interest',
      score: 0,
    ),
    ChallengeOption(
      label: '${tooHigh.round()} coins',
      detail: 'Higher than compounding at this rate actually reaches',
      score: (tooHigh - real).abs(),
    ),
  ];

  return TownChallenge(
    id: 'compound',
    title: 'What it grows to',
    prompt:
        'You put $amount coins away at $rate% a year and leave it for '
        '$years years. Closest to what you end up with?',
    options: options,
    correctIndex: _bestIndex(options, lowerIsBetter: true),
    explanation:
        'Interest earns interest. Adding $rate% $years times is not the same '
        'as $rate% x $years — that gap is the whole reason to start early '
        'rather than to start big.',
    concept: FinanceConcept.compoundGrowth,
    lowerIsBetter: true,
    reward: 4,
  );
}

TownChallenge _subscription(_Rolls rolls) {
  final monthly = rolls.between(3, 15);
  final annual = monthly * 12 - rolls.between(4, 20);

  final options = <ChallengeOption>[
    ChallengeOption(
      label: '$monthly coins a month',
      detail: '${monthly * 12} coins over a year',
      score: (monthly * 12).toDouble(),
    ),
    ChallengeOption(
      label: '$annual coins once a year',
      detail: '$annual coins over a year',
      score: annual.toDouble(),
    ),
  ];

  return TownChallenge(
    id: 'subscription',
    title: 'The real price',
    prompt:
        'The same service, billed two ways. Which costs less over a whole '
        'year?',
    options: options,
    correctIndex: _bestIndex(options, lowerIsBetter: true),
    explanation:
        'A monthly price is designed to be compared with nothing. '
        '$monthly a month is ${monthly * 12} a year — multiply it out before '
        'you decide, every time.',
    concept: FinanceConcept.impulseSpending,
    lowerIsBetter: true,
    reward: 3,
  );
}

TownChallenge _tip(_Rolls rolls) {
  final bill = rolls.between(12, 60);
  final pct = <int>[10, 15, 20][rolls.next(3)];
  final correct = bill + bill * pct / 100;

  final options = <ChallengeOption>[
    ChallengeOption(
      label: '${correct.toStringAsFixed(0)} coins',
      detail: 'Correct: $bill plus $pct% of $bill',
      score: 0,
    ),
    ChallengeOption(
      label: '${(bill + pct).toStringAsFixed(0)} coins',
      detail: 'That adds $pct coins, not $pct percent',
      score: (bill + pct - correct).abs(),
    ),
    ChallengeOption(
      label: '${(bill * pct / 100).toStringAsFixed(0)} coins',
      detail: 'That is the tip on its own, without the bill',
      score: (bill * pct / 100 - correct).abs(),
    ),
  ];

  return TownChallenge(
    id: 'tip',
    title: 'What you actually hand over',
    prompt: 'The bill is $bill coins and you want to leave $pct%. What is '
        'the total?',
    options: options,
    correctIndex: _bestIndex(options, lowerIsBetter: true),
    explanation:
        'A percentage of the bill, added to the bill. The two common slips '
        'are adding the number instead of the percentage, and paying the tip '
        'without the meal.',
    concept: FinanceConcept.needsVsWants,
    lowerIsBetter: true,
    reward: 2,
  );
}
