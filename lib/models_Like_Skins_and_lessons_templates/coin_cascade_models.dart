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

  /// Arrives on its own. Clearing it is defence, not progress.
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

enum CascadeStatus { playing, won, lost }

/// The board and the run state.
///
/// Deliberately not a `ChangeNotifier`: the screen owns the animation and
/// wants to drive each cascade step itself, so this exposes explicit
/// [trySwap] / [step] calls and stays a plain object the tests can drive.
class CoinCascadeGame {
  CoinCascadeGame({
    Random? random,
    this.columns = 7,
    this.rows = 8,
    this.moves = 25,
    this.savingsGoal = 24,
    this.billCapacity = 12,
  }) : _random = random ?? Random() {
    _fillBoardWithoutMatches();
  }

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

  /// How often bills arrive. Every fourth move: often enough that ignoring
  /// them loses, rare enough that a player who covers needs stays ahead.
  static const int billInterval = 4;

  bool get isSettled => _findMatches().isEmpty;

  CascadeStatus get status {
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
      // The avoid-a-match spawn can, rarely, paint itself into a corner where
      // no swap helps. Redealing is simpler and faster than trying to repair
      // it, and 40 attempts has never been reached in testing.
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

    // Merge overlapping runs into single groups.
    final merged = <Set<Point<int>>>[];
    for (final run in runs) {
      final touching = merged.where((m) => m.intersection(run).isNotEmpty)
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

    movesLeft--;
    _sinceBill++;
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
          gainedCoins += size;
        case TileKind.save:
          gainedSavings += size;
        case TileKind.need:
          // Needs pay bills down. Covering what you must comes before
          // anything else, and the board rewards it that way.
          paid += size;
        case TileKind.want:
          // Wants score best and cost you. One added bill per three tiles —
          // enough to feel, not enough to make wants a trap.
          gainedScore += size * 6;
          added += size ~/ 3;
        case TileKind.bill:
          paid += size;
      }

      clears.add(
        Clear(kind: kind, cells: group.toList(), cascade: cascade),
      );
      for (final cell in group) {
        _grid[cell.y][cell.x] = null;
      }
    }

    score += gainedScore;
    coins += gainedCoins;
    savings += gainedSavings;
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
    if (_sinceBill >= billInterval) {
      _sinceBill = 0;
      _dropBill();
    }
    if (!hasLegalMove()) {
      _reshuffle();
    }
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

  bool get canBuyMoves =>
      coins >= extraMoveCost && status != CascadeStatus.won;

  bool buyMoves() {
    if (!canBuyMoves) return false;
    coins -= extraMoveCost;
    movesLeft += extraMovesPerPurchase;
    return true;
  }

  /// Places a specific tile. **Tests only.**
  ///
  /// The engine's interesting behaviour — an L clearing as one group, wants
  /// pushing bills up, a dead board reshuffling — depends on exact
  /// arrangements that are impractical to reach by seeding a random deal and
  /// hoping. A seam is the honest way to reach them; the alternative is tests
  /// that assert only what a random board happens to do.
  @visibleForTesting
  void debugSet(int col, int row, TileKind kind, int id) {
    if (!inBounds(col, row)) return;
    _grid[row][col] = Tile(kind, id);
  }

  /// Gold awarded for the run, for `recordArcadeRun`.
  ///
  /// Savings dominate on purpose: the score rewards playing well, but the
  /// payout rewards playing *toward the goal*, and those are the same thing
  /// only if the payout says so.
  int get goldEarned => (savings * 4) + (score ~/ 40) + (coins ~/ 2);
}
