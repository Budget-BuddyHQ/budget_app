import 'dart:math';

import 'package:flutter/material.dart';

/// The engine behind Coin Cascade — a match-3 whose pieces are a budget.
///
/// **Why a match-3, and why this one.** The arcade had two hard games and
/// nothing for a seven-year-old or for a parent with two minutes. Match-3 is
/// the most broadly playable format there is: the rule fits in one sentence,
/// nobody has to read, and it survives being played badly.
///
/// The budgeting is in the **mechanics**, not in a quiz bolted to the side:
///
/// * [TileKind.need] clears your bills. Needs are what you have to cover.
/// * [TileKind.want] scores well and *raises* your bills. Wants are fun and
///   they cost.
/// * [TileKind.save] is the only thing that moves you toward the goal.
/// * [TileKind.coin] is money in hand — it buys the extra moves.
/// * [TileKind.bill] arrives whether you like it or not, and clearing it
///   costs you a match you would rather have spent on savings.
///
/// A player who chases the biggest matches loses; a player who covers needs,
/// keeps wants in check and puts the rest into savings wins. That is 50/30/20
/// with the numbers taken out, and it is learnable at four and still true at
/// twenty-one.
///
/// All of this is pure Dart with an injectable [Random], so the whole game is
/// testable without pumping a single widget.

enum TileKind {
  /// Money in hand. Matching these funds extra moves.
  coin('Coin', '🪙', Color(0xFFFFD45C)),

  /// Rent, food, transport. Matching these pays bills down.
  need('Need', '🥫', Color(0xFF85EFAC)),

  /// Treats. Big score, but they add to what you owe.
  want('Want', '🎮', Color(0xFFFF8FB1)),

  /// The goal.
  save('Save', '🐷', Color(0xFF69C6FF)),

  /// Arrives on its own. Clearing it is defense, not progress.
  bill('Bill', '🧾', Color(0xFFFF8474));

  const TileKind(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;

  /// The kinds that can be spawned when the board refills.
  ///
  /// [bill] is excluded on purpose — bills are *scheduled*, not random, so a
  /// player can never be buried by luck alone. Being handed an unwinnable
  /// board is the fastest way to lose a young player, and "the game was
  /// unfair" is the one lesson this must not teach.
  static const List<TileKind> spawnable = [coin, need, want, save];
}

/// One square.
@immutable
class Tile {
  const Tile(this.kind, this.id);

  final TileKind kind;

  /// Stable across gravity, so the UI can animate a tile *falling* rather
  /// than cross-fading one square into another.
  final int id;

  @override
  bool operator ==(Object other) =>
      other is Tile && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// A cleared group, reported so the UI can score and animate it.
@immutable
class Clear {
  const Clear({required this.kind, required this.cells, required this.cascade});

  final TileKind kind;
  final List<Point<int>> cells;

  /// 0 for the match the player made, 1+ for matches that fell into place on
  /// their own. Cascades score more — they are the payoff for setting a board
  /// up rather than taking the first swap you see.
  final int cascade;

  int get size => cells.length;
}

/// What one settled swap did to the run.
@immutable
class CascadeOutcome {
  const CascadeOutcome({
    required this.clears,
    required this.score,
    required this.coins,
    required this.savings,
    required this.billsPaid,
    required this.billsAdded,
  });

  static const CascadeOutcome none = CascadeOutcome(
    clears: [],
    score: 0,
    coins: 0,
    savings: 0,
    billsPaid: 0,
    billsAdded: 0,
  );

  final List<Clear> clears;
  final int score;
  final int coins;
  final int savings;
  final int billsPaid;
  final int billsAdded;

  bool get isEmpty => clears.isEmpty;

  /// How deep the chain went. Shown as "3x chain!" — the thing that makes a
  /// good move feel good.
  int get maxCascade =>
      clears.isEmpty ? 0 : clears.map((c) => c.cascade).reduce(max) + 1;
}

/// How a run is shaped.
///
/// **Why a second mode at all.** The ladder is thirteen levels of "spend a
/// fixed budget of moves well", which is the right shape for the lesson and
/// the wrong shape for somebody who has ten spare minutes and has already
/// beaten it. Reported as: *"sure it's satisfying but I don't even know what
/// to work for in that game."*
///
/// [rush] answers that without touching the ladder, and it changes the
/// *pressure* rather than the numbers. In the ladder your scarce resource is
/// moves, so the game rewards looking at the board; in Payday Rush your
/// scarce resource is time and bills arrive on a clock whether you are ready
/// or not, so it rewards covering needs fast. Those are two genuinely
/// different money skills — planning a budget, and dealing with a month that
/// does not wait for you.
enum CascadeMode {
  /// The level ladder. A fixed move budget, a savings goal, no clock.
  ladder,

  /// Payday Rush. A clock, unlimited moves, and bills that arrive on time
  /// rather than on turns. Ends when the clock does; savings are the score.
  rush,
}

/// What a finished run actually did, in budget terms.
///
/// **This is the answer to "how is this teaching them financial literacy".**
/// The mechanics have always encoded 50/30/20 — needs clear your bills, wants
/// score well and raise them, savings are the only thing that wins — but the
/// game never *said so*, at any point, to anybody. A player could beat all
/// thirteen levels and never learn that the thing they had got good at had a
/// name, which makes the teaching entirely dependent on somebody happening to
/// notice it.
///
/// So this reads the player's own run back to them as an allocation. The rule
/// the app follows everywhere else applies here too: **never say a number is
/// good or bad, show what it did.** No grade, no score out of ten. What you
/// spent your board on, what that split is called, and what it cost you —
/// which is a fact about their own game rather than a claim about budgeting
/// they have to take on trust.
@immutable
class CascadeReport {
  const CascadeReport({
    required this.needs,
    required this.wants,
    required this.saves,
    required this.coins,
    required this.billsPaid,
    required this.billsTaken,
  });

  /// Tiles cleared of each kind across the whole run.
  final int needs;
  final int wants;
  final int saves;

  /// Coins are **not** part of the split below.
  ///
  /// A coin is income, not an allocation — in this game it buys extra moves,
  /// which is the board's version of money you have not decided about yet.
  /// Folding it into the percentages would make a lucky coin run look like a
  /// budgeting choice.
  final int coins;

  final int billsPaid;
  final int billsTaken;

  /// The three things a budget is actually divided between.
  int get allocated => needs + wants + saves;

  double get needsShare => allocated == 0 ? 0 : needs / allocated;
  double get wantsShare => allocated == 0 ? 0 : wants / allocated;
  double get savesShare => allocated == 0 ? 0 : saves / allocated;

  int get needsPercent => (needsShare * 100).round();
  int get wantsPercent => (wantsShare * 100).round();
  int get savesPercent => (savesShare * 100).round();

  /// One sentence naming the shape of the run.
  ///
  /// Ordered by which observation is most worth making, not by severity —
  /// there is nothing here to be severe about. A run close to 50/30/20 is
  /// told so, because the whole point is that the player arrived there by
  /// playing rather than by being taught the numbers.
  String get headline {
    if (allocated == 0) return 'Not enough of a run to read.';
    if (savesPercent >= 20 && wantsPercent <= 30) {
      return 'That is roughly a 50/30/20 budget, and you played it '
          'rather than read it.';
    }
    if (savesPercent < 10) return 'Almost nothing went to savings this run.';
    if (wantsPercent > 40) return 'Wants took $wantsPercent% of your board.';
    if (needsPercent > 60) return 'Most of your run went on covering needs.';
    // No adjective on the fallback. Every other branch names something
    // specific that happened; this one has nothing to point at, and reaching
    // for a word like "cautious" would be the app grading a run it has
    // nothing to say about.
    return 'You put $savesPercent% away and spent $wantsPercent% on wants.';
  }

  /// The consequence, in the run's own numbers.
  ///
  /// Every sentence points at something that happened on the board the player
  /// just watched, because that is the difference between a lesson and a
  /// slogan. "Wants raise your bills" is a rule; "your wants added 7 bills and
  /// your needs cleared 11" is what happened.
  List<String> get detail {
    if (allocated == 0) {
      return const <String>[
        'Play a few more moves and this will have something to say.',
      ];
    }
    final parts = <String>[
      'The 50/30/20 rule splits money the same way: about half on things you '
          'have to pay for, a third on things you want, a fifth put away.',
    ];
    if (billsTaken > 0) {
      parts.add(
        'Your wants added $billsTaken ${billsTaken == 1 ? 'bill' : 'bills'}. '
        'Clearing needs paid off $billsPaid. That gap is the reason a budget '
        'has a wants column rather than no wants at all.',
      );
    }
    if (coins > 0) {
      parts.add(
        'You also matched $coins in coins — income, which buys moves rather '
        'than counting as a choice.',
      );
    }
    return parts;
  }
}

/// One stage of the run.
///
/// **Why levels rather than one endless board.** A single tuning — 25 moves,
/// 24 savings, 12 bills — is one puzzle, and once a player has solved it there
/// is nothing left to find out. Each level here changes *what you have to
/// think about*, not just how much of it there is: the bills arrive faster, or
/// wants cost double, or the move budget is short enough that coins stop being
/// optional. That is the difference between a game with more content and a
/// game with a longer number.
///
/// The rules are also the curriculum, in order. Level 1 teaches "savings win".
/// Level 2 teaches "cover your needs first" by making bills arrive faster.
/// Level 4 teaches the actual 50/30/20 lesson — wants are affordable until
/// they are not — by doubling what they cost you.
@immutable
class CascadeLevel {
  const CascadeLevel({
    required this.number,
    required this.name,
    required this.rule,
    required this.savingsGoal,
    required this.moves,
    required this.billCapacity,
    this.billInterval = 4,
    this.wantsCostMultiplier = 1,
    this.coinValue = 1,
    this.mode = CascadeMode.ladder,
    this.seconds = 0,
    this.shockAtMove = 0,
    this.shockBills = 0,
  });

  final int number;
  final String name;

  /// Turn-based ladder, or the timed Payday Rush. See [CascadeMode].
  final CascadeMode mode;

  /// Clock length for [CascadeMode.rush]. Zero for every ladder level.
  final int seconds;

  /// One line, shown before the level starts. If a rule cannot be stated in
  /// one line it is too complicated for a game a seven-year-old plays.
  final String rule;

  final int savingsGoal;
  final int moves;
  final int billCapacity;

  /// Moves between scheduled bills. Lower is harder.
  final int billInterval;

  /// How many bills a three-tile want match adds.
  final int wantsCostMultiplier;

  /// Coins earned per matched coin tile.
  final int coinValue;

  /// The move a surprise expense lands on. Zero for levels that have none.
  ///
  /// # Why the game needed one
  ///
  /// The ladder taught allocation under a *predictable* squeeze: bills every
  /// three moves, every four moves, always on schedule. Thirteen levels of
  /// it, and the only thing that ever changed was the rate.
  ///
  /// Real money does not fail that way. It fails on the month the boiler
  /// goes, and the whole reason an emergency fund exists is that the timing
  /// is the part you cannot plan for. The life sim has expense shocks and
  /// teaches exactly this; the allocation game had no version of it.
  ///
  /// # Why a fixed move rather than a random one
  ///
  /// A random shock is a random loss, and a player who lost to one learns
  /// "this game is unfair" rather than anything about money. On a fixed move
  /// the level is *solvable* — and the second time through, a player who
  /// keeps headroom before move twelve survives it. That is the emergency
  /// fund, discovered rather than explained.
  ///
  /// The rule line says a shock is coming without saying when, which is the
  /// honest amount of warning: you know these happen, you do not know the
  /// date.
  final int shockAtMove;

  /// How many bills the shock drops at once. This is what makes it a shock
  /// rather than an early bill.
  final int shockBills;

  bool get hasShock => shockAtMove > 0 && shockBills > 0;
}

/// The ladder. Beat one, the next unlocks.
const List<CascadeLevel> kCascadeLevels = <CascadeLevel>[
  CascadeLevel(
    number: 1,
    name: 'First Jar',
    rule: 'Match savings to fill the goal. Needs pay your bills down.',
    savingsGoal: 18,
    moves: 28,
    billCapacity: 14,
    billInterval: 5,
  ),
  CascadeLevel(
    number: 2,
    name: 'Bills Come Faster',
    rule: 'A bill arrives every 3 moves. Cover your needs first.',
    savingsGoal: 22,
    moves: 28,
    billCapacity: 12,
    billInterval: 3,
  ),
  CascadeLevel(
    number: 3,
    name: 'Tight Month',
    rule: 'Only 20 moves. Coins buy more — spend them early.',
    savingsGoal: 20,
    moves: 20,
    billCapacity: 12,
    billInterval: 4,
    coinValue: 2,
  ),
  CascadeLevel(
    number: 4,
    name: 'Wants Cost Double',
    rule: 'Every want match adds twice the bills. Worth it? Sometimes.',
    savingsGoal: 24,
    moves: 26,
    billCapacity: 12,
    billInterval: 4,
    wantsCostMultiplier: 2,
  ),
  CascadeLevel(
    number: 5,
    name: 'Thin Margin',
    rule: 'Bills every 3 moves and only 10 before you are under.',
    savingsGoal: 24,
    moves: 26,
    billCapacity: 10,
    billInterval: 3,
  ),
  CascadeLevel(
    number: 6,
    name: 'Big Goal',
    rule: 'Save 30. You will need a chain or two.',
    savingsGoal: 30,
    moves: 30,
    billCapacity: 12,
    billInterval: 4,
  ),
  CascadeLevel(
    number: 7,
    name: 'Everything At Once',
    rule: 'Fast bills, double wants, short budget. The full test.',
    savingsGoal: 28,
    moves: 24,
    billCapacity: 10,
    billInterval: 3,
    wantsCostMultiplier: 2,
  ),

  // --- Past the first seven -------------------------------------------
  //
  // ladder used to stop at 7 which is like twenty minutes of play, then it
  // just repeated the hardest level forever (cascadeLevelFor falls back to
  // the last one). these six dont just crank the numbers up — each one turns
  // a dial the earlier levels left alone, so what youre thinking about keeps
  // changing instead of what youre grinding
  CascadeLevel(
    number: 8,
    name: 'Payday',
    rule: 'Coins are worth 3. A windfall is only useful if you aim it.',
    savingsGoal: 30,
    moves: 26,
    billCapacity: 12,
    billInterval: 4,
    coinValue: 3,
  ),
  CascadeLevel(
    number: 9,
    name: 'Rent Week',
    rule: 'A bill every 2 moves. Needs are not optional this week.',
    savingsGoal: 26,
    moves: 30,
    billCapacity: 14,
    billInterval: 2,
  ),
  CascadeLevel(
    number: 10,
    name: 'Cheap Thrills',
    rule: 'Wants cost triple. Almost never worth it — almost.',
    savingsGoal: 28,
    moves: 28,
    billCapacity: 12,
    billInterval: 4,
    wantsCostMultiplier: 3,
  ),
  CascadeLevel(
    number: 11,
    name: 'Living On The Edge',
    rule: 'Eight bills and you are under. No room for a mistake.',
    savingsGoal: 26,
    moves: 28,
    billCapacity: 8,
    billInterval: 3,
  ),
  CascadeLevel(
    number: 12,
    name: 'The Long Save',
    rule: 'Save 40. Nothing here is hard except keeping it up.',
    savingsGoal: 40,
    moves: 38,
    billCapacity: 14,
    billInterval: 4,
  ),
  CascadeLevel(
    number: 13,
    name: 'Everything, Faster',
    rule: 'Bills every 2, wants cost triple, 22 moves. Good luck.',
    savingsGoal: 30,
    moves: 22,
    billCapacity: 10,
    billInterval: 2,
    wantsCostMultiplier: 3,
    coinValue: 2,
  ),

  // --- 14 onward: the month something breaks --------------------------
  //
  // Thirteen levels taught allocation under a **predictable** squeeze. Bills
  // every three moves, every four moves, always on schedule — and the only
  // thing that ever changed across the whole ladder was the rate.
  //
  // Real money does not fail on a schedule. It fails on the month the boiler
  // goes, and the reason an emergency fund exists at all is that the timing
  // is the part you cannot plan for. The life sim has expense shocks and
  // teaches exactly this; the allocation game had no version of it.
  //
  // These five are built on `shockAtMove`. The shock is on a fixed move, so
  // the level is solvable and a second attempt rewards keeping headroom —
  // which is the emergency fund, discovered rather than explained. See
  // `CascadeLevel.shockAtMove` for why fixed rather than random.
  CascadeLevel(
    number: 14,
    name: 'Something Breaks',
    rule: 'A surprise bill lands partway through. Keep room for it.',
    savingsGoal: 26,
    moves: 30,
    billCapacity: 13,
    billInterval: 4,
    shockAtMove: 12,
    shockBills: 3,
  ),
  CascadeLevel(
    number: 15,
    name: 'Full Capacity',
    // The lesson stated as a mechanic: the same shock is survivable or fatal
    // depending on how much room you were carrying when it arrived. Nothing
    // about the shock changes between attempts. What changes is you.
    rule: 'Bills every 3, and a bigger surprise. Room matters more than speed.',
    savingsGoal: 30,
    moves: 30,
    billCapacity: 12,
    billInterval: 3,
    shockAtMove: 14,
    shockBills: 4,
  ),
  CascadeLevel(
    number: 16,
    name: 'Twice in One Month',
    // Two shocks cannot both be planned around, which is the point: past a
    // certain frequency the answer stops being "budget better" and starts
    // being "this is why the fund is separate money".
    rule: 'It happens again. One buffer has to cover both.',
    savingsGoal: 28,
    moves: 32,
    billCapacity: 14,
    billInterval: 4,
    shockAtMove: 10,
    shockBills: 5,
    coinValue: 2,
  ),
  CascadeLevel(
    number: 17,
    name: 'Expensive Taste',
    // Wants at quadruple cost against a shock. The temptation is the enemy
    // here rather than the schedule: every want cleared is capacity you do
    // not have on move sixteen.
    rule: 'Wants cost four bills now, and a surprise is coming.',
    savingsGoal: 32,
    moves: 30,
    billCapacity: 13,
    billInterval: 4,
    wantsCostMultiplier: 4,
    shockAtMove: 16,
    shockBills: 3,
    coinValue: 2,
  ),
  CascadeLevel(
    number: 18,
    name: 'The Whole Year',
    // The finale, and deliberately generous on capacity. A last level that
    // is lost to arithmetic nobody could have done is a last level nobody
    // finishes.
    rule: 'Everything at once. Bills every 2, wants cost triple, one shock.',
    savingsGoal: 36,
    moves: 34,
    billCapacity: 15,
    billInterval: 2,
    wantsCostMultiplier: 3,
    shockAtMove: 18,
    shockBills: 4,
    coinValue: 3,
  ),
];

/// Payday Rush.
///
/// Ninety seconds, deliberately. It has to be something somebody does while
/// waiting for a bus, and a five-minute timed mode is the ladder with anxiety
/// added rather than a different game.
///
/// `billCapacity` is generous next to the ladder levels, because losing a
/// timed run early is a far worse experience than losing a turn-based one:
/// there is no move you could have thought harder about, and the clock is
/// still going.
const CascadeLevel kCascadeRush = CascadeLevel(
  number: 0,
  name: 'Payday Rush',
  rule: '90 seconds. Bills land on the clock. Save everything you can.',
  mode: CascadeMode.rush,
  seconds: 90,
  // Unreachable on purpose: there is no winning a Rush, only a score. The
  // engine's win check compares against this and never fires.
  savingsGoal: 1 << 30,
  moves: 1 << 30,
  billCapacity: 16,
  // Bills are delivered by the clock here, so the move-based interval is
  // never consulted — see `CoinCascadeGame._afterCascade`.
  billInterval: 1 << 30,
  coinValue: 2,
);

/// Seconds between scheduled bills in [CascadeMode.rush].
///
/// Four gives roughly 22 bills across a 90-second run against a capacity of
/// 16, so a player who never clears a need is out at about the two-thirds
/// mark — late enough to have had a game, early enough that ignoring bills is
/// unmistakably the thing that ended it.
const Duration kRushBillInterval = Duration(seconds: 4);

CascadeLevel cascadeLevelFor(int number) => kCascadeLevels.firstWhere(
  (level) => level.number == number,
  orElse: () => kCascadeLevels.last,
);

enum CascadeStatus { playing, won, lost }

/// The board and the run state.
///
/// Deliberately not a `ChangeNotifier`: the screen owns the animation and
/// wants to drive each cascade step itself, so this exposes explicit
/// [trySwap] / [step] calls and stays a plain object the tests can drive.
class CoinCascadeGame {
  CoinCascadeGame({
    Random? random,
    CascadeLevel? level,
    this.columns = 7,
    this.rows = 8,
    int? moves,
    int? savingsGoal,
    int? billCapacity,
  }) : _random = random ?? Random(),
       level = level ?? kCascadeLevels.first,
       moves = moves ?? (level ?? kCascadeLevels.first).moves,
       savingsGoal = savingsGoal ?? (level ?? kCascadeLevels.first).savingsGoal,
       billCapacity =
           billCapacity ?? (level ?? kCascadeLevels.first).billCapacity {
    _fillBoardWithoutMatches();
  }

  /// Which stage this run is. Supplies the goal, the move budget and the
  /// rule twists; the explicit overrides above exist for tests that want a
  /// specific shape without inventing a level for it.
  final CascadeLevel level;

  final Random _random;
  final int columns;
  final int rows;

  /// Moves in a run. A fixed budget of turns is what turns "match things"
  /// into "spend your turns well", which is the same shape as the lesson.
  final int moves;

  final int savingsGoal;

  /// How many bills you can owe before the run ends.
  final int billCapacity;

  late List<List<Tile?>> _grid;
  int _nextId = 0;

  int movesLeft = 0;
  int score = 0;
  int coins = 0;
  int savings = 0;
  int bills = 0;

  /// Moves since a bill was last dropped in.
  int _sinceBill = 0;

  /// Whether this run's surprise expense has already landed. Once only — a
  /// shock that repeats is just a shorter bill interval wearing a costume.
  bool _shockFired = false;

  /// Tiles cleared across the whole run, by kind.
  ///
  /// The engine already knew all of this a swap at a time — `CascadeOutcome`
  /// reports it and the screen throws it away after drawing a banner. Keeping
  /// the totals is what lets [report] tell a player what their run was
  /// *shaped* like, which is the thing the game had never once said out loud.
  int needsCleared = 0;
  int wantsCleared = 0;
  int savesCleared = 0;
  int coinsCleared = 0;
  int billsClearedTotal = 0;
  int billsAddedTotal = 0;

  /// The run, read back as a budget. See [CascadeReport].
  CascadeReport get report => CascadeReport(
    needs: needsCleared,
    wants: wantsCleared,
    saves: savesCleared,
    coins: coinsCleared,
    billsPaid: billsClearedTotal,
    billsTaken: billsAddedTotal,
  );

  /// True in Payday Rush, where the clock ends the run rather than the moves.
  bool get isTimed => level.mode == CascadeMode.rush;

  /// How often bills arrive, from the level. Frequent enough that ignoring
  /// them loses, rare enough that a player who covers needs stays ahead.
  int get billInterval => level.billInterval;

  bool get isSettled => _findMatches().isEmpty;

  CascadeStatus get status {
    // A Rush is never won and never runs out of moves — it runs out of
    // *time*, which only the screen knows about, and it is scored on savings
    // rather than passed or failed. Going under on bills still ends it: the
    // one way to lose a timed run is to let the bills win, which is the
    // lesson the clock exists to teach.
    if (isTimed) {
      return bills >= billCapacity
          ? CascadeStatus.lost
          : CascadeStatus.playing;
    }
    if (savings >= savingsGoal) return CascadeStatus.won;
    if (bills >= billCapacity) return CascadeStatus.lost;
    if (movesLeft <= 0) return CascadeStatus.lost;
    return CascadeStatus.playing;
  }

  Tile? tileAt(int col, int row) => _grid[row][col];

  bool inBounds(int col, int row) =>
      col >= 0 && col < columns && row >= 0 && row < rows;

  /// Starts (or restarts) a run.
  void reset() {
    movesLeft = moves;
    score = 0;
    coins = 0;
    savings = 0;
    bills = 0;
    _sinceBill = 0;
    _shockFired = false;
    needsCleared = 0;
    wantsCleared = 0;
    savesCleared = 0;
    coinsCleared = 0;
    billsClearedTotal = 0;
    billsAddedTotal = 0;
    _fillBoardWithoutMatches();
  }

  // ------------------------------------------------------------------
  // Board setup
  // ------------------------------------------------------------------

  /// Deals a board that has no matches already on it and at least one legal
  /// move available.
  ///
  /// Both halves matter. A board that starts mid-cascade robs the player of
  /// the first move; a board with no legal move is a loss before anyone has
  /// touched it.
  void _fillBoardWithoutMatches() {
    movesLeft = movesLeft == 0 ? moves : movesLeft;
    var attempts = 0;
    do {
      _grid = List.generate(
        rows,
        (_) => List<Tile?>.filled(columns, null, growable: false),
      );
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < columns; col++) {
          _grid[row][col] = _spawnAvoidingMatch(col, row);
        }
      }
      attempts++;
      // the avoid-a-match spawn can very occasionally paint itself into a
      // corner where no swap helps. easier + faster to just redeal than try
      // and repair it. never seen it get anywhere near 40 attempts
    } while (!hasLegalMove() && attempts < 40);
  }

  /// A tile that does not complete a line of three where it is placed.
  Tile _spawnAvoidingMatch(int col, int row) {
    final banned = <TileKind>{};
    if (col >= 2 &&
        _grid[row][col - 1]?.kind == _grid[row][col - 2]?.kind &&
        _grid[row][col - 1] != null) {
      banned.add(_grid[row][col - 1]!.kind);
    }
    if (row >= 2 &&
        _grid[row - 1][col]?.kind == _grid[row - 2][col]?.kind &&
        _grid[row - 1][col] != null) {
      banned.add(_grid[row - 1][col]!.kind);
    }
    final choices = TileKind.spawnable
        .where((k) => !banned.contains(k))
        .toList();
    final kind = choices.isEmpty
        ? TileKind.spawnable[_random.nextInt(TileKind.spawnable.length)]
        : choices[_random.nextInt(choices.length)];
    return Tile(kind, _nextId++);
  }

  // ------------------------------------------------------------------
  // Matching
  // ------------------------------------------------------------------

  /// Every group of three or more in a line, as sets of cells.
  ///
  /// Horizontal and vertical runs are found separately and then merged where
  /// they overlap, so an L or a T clears as **one** group. Reporting it as
  /// two overlapping groups would double-count the shared tile, and an L of
  /// five would score less than two separate threes — backwards, given it is
  /// the harder shape to set up.
  List<Set<Point<int>>> _findMatches() {
    final runs = <Set<Point<int>>>[];

    void scan(bool horizontal) {
      final outer = horizontal ? rows : columns;
      final inner = horizontal ? columns : rows;
      for (var a = 0; a < outer; a++) {
        var start = 0;
        while (start < inner) {
          final first = horizontal ? _grid[a][start] : _grid[start][a];
          var end = start + 1;
          while (end < inner) {
            final next = horizontal ? _grid[a][end] : _grid[end][a];
            if (first == null || next == null || next.kind != first.kind) break;
            end++;
          }
          if (first != null && end - start >= 3) {
            runs.add({
              for (var i = start; i < end; i++)
                horizontal ? Point(i, a) : Point(a, i),
            });
          }
          start = end;
        }
      }
    }

    scan(true);
    scan(false);

    // merge overlapping runs into one group
    final merged = <Set<Point<int>>>[];
    for (final run in runs) {
      final touching = merged
          .where((m) => m.intersection(run).isNotEmpty)
          .toList();
      if (touching.isEmpty) {
        merged.add({...run});
      } else {
        final combined = <Point<int>>{...run};
        for (final t in touching) {
          combined.addAll(t);
          merged.remove(t);
        }
        merged.add(combined);
      }
    }
    return merged;
  }

  /// Whether any adjacent swap would produce a match.
  ///
  /// Checked by actually performing each swap and looking, rather than by
  /// pattern-matching shapes. Slower, and correct — the shape-table approach
  /// is where "no more moves" bugs come from, and telling a player the board
  /// is dead when it is not is worse than a frame of work.
  bool hasLegalMove() {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        for (final delta in const [Point(1, 0), Point(0, 1)]) {
          final c2 = col + delta.x;
          final r2 = row + delta.y;
          if (!inBounds(c2, r2)) continue;
          _swapCells(col, row, c2, r2);
          final found = _findMatches().isNotEmpty;
          _swapCells(col, row, c2, r2);
          if (found) return true;
        }
      }
    }
    return false;
  }

  void _swapCells(int c1, int r1, int c2, int r2) {
    final tmp = _grid[r1][c1];
    _grid[r1][c1] = _grid[r2][c2];
    _grid[r2][c2] = tmp;
  }

  // ------------------------------------------------------------------
  // Playing
  // ------------------------------------------------------------------

  /// Swaps two adjacent cells if that creates a match.
  ///
  /// Returns false and leaves the board untouched otherwise — a swap that
  /// achieves nothing should not cost a move. Players try things; charging
  /// them for an experiment teaches caution rather than budgeting.
  bool trySwap(int c1, int r1, int c2, int r2) {
    if (status != CascadeStatus.playing) return false;
    if (!inBounds(c1, r1) || !inBounds(c2, r2)) return false;
    if ((c1 - c2).abs() + (r1 - r2).abs() != 1) return false;

    _swapCells(c1, r1, c2, r2);
    if (_findMatches().isEmpty) {
      _swapCells(c1, r1, c2, r2);
      return false;
    }

    // A Rush has no move budget — its cost is the second that just passed —
    // so decrementing here would tick a counter nothing reads and, worse,
    // would eventually underflow past the 1<<30 the level declares.
    if (!isTimed) {
      movesLeft--;
      _sinceBill++;
    }
    return true;
  }

  /// Resolves one round of matching: clears what is on the board, drops the
  /// survivors, refills the gaps.
  ///
  /// Returns [CascadeOutcome.none] once nothing is left to clear. The caller
  /// loops on it, which lets the UI animate each step instead of watching the
  /// board teleport to its final state.
  CascadeOutcome step({int cascade = 0}) {
    final matches = _findMatches();
    if (matches.isEmpty) {
      if (cascade > 0) _afterCascade();
      return CascadeOutcome.none;
    }

    final clears = <Clear>[];
    var gainedScore = 0;
    var gainedCoins = 0;
    var gainedSavings = 0;
    var paid = 0;
    var added = 0;

    for (final group in matches) {
      final first = group.first;
      final kind = _grid[first.y][first.x]!.kind;
      final size = group.length;

      // Bigger groups and deeper cascades are worth disproportionately more,
      // so there is always a reason to look for the better move rather than
      // the first one.
      final base = size * 10;
      final sizeBonus = (size - 3) * 15;
      final chainBonus = cascade * 25;
      gainedScore += base + sizeBonus + chainBonus;

      switch (kind) {
        case TileKind.coin:
          gainedCoins += size * level.coinValue;
          coinsCleared += size;
        case TileKind.save:
          gainedSavings += size;
          savesCleared += size;
        case TileKind.need:
          // Needs pay bills down. Covering what you must comes before
          // anything else, and the board rewards it that way.
          paid += size;
          needsCleared += size;
        case TileKind.want:
          // Wants score best and cost you. One added bill per three tiles —
          // enough to feel, not enough to make wants a trap.
          gainedScore += size * 6;
          added += (size ~/ 3) * level.wantsCostMultiplier;
          wantsCleared += size;
        case TileKind.bill:
          // Cleared bills are defense, not an allocation, so they count
          // towards what was paid off and not towards the 50/30/20 split.
          paid += size;
      }

      clears.add(Clear(kind: kind, cells: group.toList(), cascade: cascade));
      for (final cell in group) {
        _grid[cell.y][cell.x] = null;
      }
    }

    score += gainedScore;
    coins += gainedCoins;
    savings += gainedSavings;
    billsClearedTotal += paid;
    billsAddedTotal += added;
    bills = (bills - paid + added).clamp(0, billCapacity);

    _applyGravity();
    _refill();

    return CascadeOutcome(
      clears: clears,
      score: gainedScore,
      coins: gainedCoins,
      savings: gainedSavings,
      billsPaid: paid,
      billsAdded: added,
    );
  }

  /// Runs the whole chain at once. Used by tests and by the "no legal moves"
  /// reshuffle; the screen steps manually so it can animate.
  CascadeOutcome resolveAll() {
    var total = CascadeOutcome.none;
    var cascade = 0;
    while (true) {
      final outcome = step(cascade: cascade);
      if (outcome.isEmpty) break;
      total = CascadeOutcome(
        clears: [...total.clears, ...outcome.clears],
        score: total.score + outcome.score,
        coins: total.coins + outcome.coins,
        savings: total.savings + outcome.savings,
        billsPaid: total.billsPaid + outcome.billsPaid,
        billsAdded: total.billsAdded + outcome.billsAdded,
      );
      cascade++;
    }
    return total;
  }

  /// Bill delivery and the dead-board check, once a chain has finished.
  void _afterCascade() {
    // In a Rush the clock delivers bills (see [dropScheduledBill]); leaving
    // the move-based path on as well would double the rate and make the mode
    // unwinnable for reasons no player could see.
    if (!isTimed && _sinceBill >= billInterval) {
      _sinceBill = 0;
      _dropBill();
    }
    // The surprise expense. Fires once, on its move — see
    // [CascadeLevel.shockAtMove].
    //
    // **It raises the bill meter rather than dropping bill tiles**, and the
    // first version got that backwards. `_dropBill` places a *bill tile* on
    // the board, and clearing a bill tile **pays the meter down** — so a
    // shock built out of them handed the player four extra ways to reduce
    // their bills. It made the level easier. Nothing failed; the level was
    // simply not doing what its name said.
    //
    // Raising `bills` is what a surprise expense actually is: your load
    // jumps, and whether you survive depends on the headroom you were
    // carrying. That headroom is the emergency fund, and this is the only
    // place in the ladder where it is worth anything.
    if (!isTimed &&
        !_shockFired &&
        level.hasShock &&
        (moves - movesLeft) >= level.shockAtMove) {
      _shockFired = true;
      billsAddedTotal += level.shockBills;
      bills = (bills + level.shockBills).clamp(0, billCapacity);
    }
    if (!hasLegalMove()) {
      _reshuffle();
    }
  }

  /// Delivers a bill because time passed rather than because a move did.
  ///
  /// Payday Rush's whole point: the month arrives whether or not you were
  /// ready, and the board keeps filling while you are still deciding. Driven
  /// by the screen's timer, because the engine has no clock of its own and
  /// should not grow one — a model that reads `DateTime.now()` is a model
  /// that cannot be tested.
  ///
  /// No-op outside [CascadeMode.rush] and once the run is over, so a timer
  /// that fires one last tick during the closing animation cannot end a run
  /// the player had already survived.
  void dropScheduledBill() {
    if (!isTimed || status != CascadeStatus.playing) return;
    _dropBill();
    if (!hasLegalMove()) _reshuffle();
  }

  /// Turns one random non-bill tile into a bill.
  ///
  /// Placed rather than dropped from the top so it cannot immediately form a
  /// three and clear itself, which would make the whole mechanic invisible.
  void _dropBill() {
    final candidates = <Point<int>>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        if (_grid[row][col]?.kind != TileKind.bill) {
          candidates.add(Point(col, row));
        }
      }
    }
    if (candidates.isEmpty) return;

    // Try a few spots and take the first that does not instantly match.
    for (var attempt = 0; attempt < 12; attempt++) {
      final at = candidates[_random.nextInt(candidates.length)];
      final previous = _grid[at.y][at.x];
      _grid[at.y][at.x] = Tile(TileKind.bill, _nextId++);
      if (_findMatches().isEmpty) return;
      _grid[at.y][at.x] = previous;
    }
  }

  /// Rearranges the board when no swap can produce a match.
  ///
  /// The alternative is ending the run on a board the player did nothing
  /// wrong to reach, which reads as the game breaking.
  void _reshuffle() {
    final kinds = <TileKind>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final tile = _grid[row][col];
        if (tile != null) kinds.add(tile.kind);
      }
    }
    for (var attempt = 0; attempt < 60; attempt++) {
      kinds.shuffle(_random);
      var i = 0;
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < columns; col++) {
          _grid[row][col] = Tile(kinds[i++], _nextId++);
        }
      }
      if (_findMatches().isEmpty && hasLegalMove()) return;
    }
    // Nothing shuffled into a playable arrangement — deal a fresh board
    // rather than leave a dead one on screen.
    _fillBoardWithoutMatches();
  }

  /// Everything falls into the holes under it.
  void _applyGravity() {
    for (var col = 0; col < columns; col++) {
      var writeRow = rows - 1;
      for (var row = rows - 1; row >= 0; row--) {
        final tile = _grid[row][col];
        if (tile != null) {
          _grid[writeRow][col] = tile;
          if (writeRow != row) _grid[row][col] = null;
          writeRow--;
        }
      }
      for (var row = writeRow; row >= 0; row--) {
        _grid[row][col] = null;
      }
    }
  }

  /// New tiles for the holes gravity left at the top.
  void _refill() {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        _grid[row][col] ??= Tile(
          TileKind.spawnable[_random.nextInt(TileKind.spawnable.length)],
          _nextId++,
        );
      }
    }
  }

  /// Spends coins on extra moves — the one place the wallet is useful, and
  /// the reason matching coins is worth a turn.
  static const int extraMoveCost = 12;
  static const int extraMovesPerPurchase = 5;

  bool get canBuyMoves => coins >= extraMoveCost && status != CascadeStatus.won;

  bool buyMoves() {
    if (!canBuyMoves) return false;
    coins -= extraMoveCost;
    movesLeft += extraMovesPerPurchase;
    return true;
  }

  /// Places a specific tile. **Tests only.**
  ///
  /// The engine's interesting behavior — an L clearing as one group, wants
  /// pushing bills up, a dead board reshuffling — depends on exact
  /// arrangements that are impractical to reach by seeding a random deal and
  /// hoping. A seam is the honest way to reach them; the alternative is tests
  /// that assert only what a random board happens to do.
  @visibleForTesting
  void debugSet(int col, int row, TileKind kind, int id) {
    if (!inBounds(col, row)) return;
    _grid[row][col] = Tile(kind, id);
  }

}

/// What a finished run pays.
@immutable
class CascadePayout {
  const CascadePayout({
    required this.gold,
    required this.xp,
    required this.literacy,
  });

  final int gold;
  final int xp;

  /// Literacy points — the app's measure of *what you have learned*.
  ///
  /// Zero for anything repeatable, and that is the whole design of this
  /// field. Each ladder level teaches one specific twist (bills arriving
  /// faster, wants costing double); replaying a level you have already
  /// cleared does not teach you its rule a second time, so it does not pay
  /// the currency that means "learned something". Gold and XP still come, at
  /// a lower rate, because the game should still be worth playing for fun.
  ///
  /// It is the same rule the Adventure town uses for encounters that have
  /// already been resolved: reward the progress, not the repetition.
  final int literacy;
}

/// What [game] is worth, given what the player had already done.
///
/// **Why this is a function here and not a few lines in the screen.** The
/// payout used to be `CoinCascadeGame.goldEarned` — a getter on the engine
/// that computed a number the result card printed, the arcade toast printed
/// again, and nothing ever credited to anybody. The only call either screen
/// made was `recordArcadeRun`, which is a scoreboard write and is documented
/// as not touching gold or XP.
///
/// Putting the rules back in the model, as a pure function over the run plus
/// the two facts the engine cannot know, means they can be *tested* — and the
/// thing that went wrong was not the arithmetic, it was that nothing
/// connected the arithmetic to an account. A tested formula in one place is
/// harder to leave unwired than a getter that reads like it is already doing
/// the job.
///
/// [firstClear] — a win on a level higher than any cleared before.
/// [newRushBest] — a Payday Rush that beat the player's saved best.
CascadePayout cascadePayoutFor(
  CoinCascadeGame game, {
  bool firstClear = false,
  bool newRushBest = false,
}) {
  if (game.isTimed) {
    // Savings are the Rush score, so savings are what it pays. Score barely
    // contributes: chasing points instead of the piggy bank is precisely the
    // habit the mode exists to punish.
    return CascadePayout(
      gold: game.savings * 3 + game.score ~/ 60,
      xp: 4 + game.savings ~/ 2,
      literacy: newRushBest ? 6 : 0,
    );
  }

  final level = game.level;
  if (game.status != CascadeStatus.won) {
    // A lost run still pays for what it managed, at a low rate. Nothing at
    // all would make a near-miss on level 12 worth less than walking away
    // from level 1, which is the wrong lesson about trying something hard.
    return CascadePayout(gold: game.savings, xp: 2, literacy: 0);
  }
  if (!firstClear) {
    return CascadePayout(gold: 8 + level.number * 2, xp: 3, literacy: 0);
  }

  // Moves left over and savings past the goal both mean "you had room to
  // spare", which is the thing worth paying for in a game about budgeting.
  final spare = game.movesLeft.clamp(0, 20);
  final overshoot = (game.savings - level.savingsGoal).clamp(0, 40);
  return CascadePayout(
    gold: 40 + level.number * 10 + spare * 2 + overshoot,
    xp: 10 + level.number * 3,
    literacy: 8 + level.number,
  );
}
