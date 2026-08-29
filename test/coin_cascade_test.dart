import 'dart:math';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/coin_cascade_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coin Cascade is the arcade's game for everybody — a seven-year-old, a
/// parent with two minutes, a teenager waiting for a bus. That audience makes
/// the failure modes specific: a board that is unwinnable through no fault of
/// the player, or a move that silently costs a turn, reads as the game being
/// broken and there is no second chance to explain otherwise.
///
/// The engine is pure Dart with an injectable `Random`, so all of that is
/// checkable here rather than by playing it.
void main() {
  CoinCascadeGame game(int seed) => CoinCascadeGame(random: Random(seed));

  group('the board a player is handed', () {
    test('never starts mid-cascade', () {
      // A board with matches already on it resolves itself before the player
      // touches anything, so their first move is spent watching.
      for (var seed = 0; seed < 60; seed++) {
        expect(
          game(seed).isSettled,
          isTrue,
          reason: 'seed $seed dealt a board that was already matching',
        );
      }
    });

    test('always has a move available', () {
      // Losing on the deal is the worst possible first impression.
      for (var seed = 0; seed < 60; seed++) {
        expect(
          game(seed).hasLegalMove(),
          isTrue,
          reason: 'seed $seed dealt a dead board',
        );
      }
    });

    test('every square is filled', () {
      final board = game(3);
      for (var row = 0; row < board.rows; row++) {
        for (var col = 0; col < board.columns; col++) {
          expect(board.tileAt(col, row), isNotNull);
        }
      }
    });

    test('bills are never dealt at the start', () {
      // Bills are scheduled, not random — see [TileKind.spawnable]. A player
      // who opens on a board of bills has been handed a deficit they did not
      // create.
      for (var seed = 0; seed < 30; seed++) {
        final board = game(seed);
        for (var row = 0; row < board.rows; row++) {
          for (var col = 0; col < board.columns; col++) {
            expect(board.tileAt(col, row)!.kind, isNot(TileKind.bill));
          }
        }
      }
    });
  });

  group('swapping', () {
    test('a swap that matches nothing costs nothing', () {
      // Players try things. Charging a move for an experiment teaches
      // caution, which is the opposite of what a game for four-year-olds
      // should be doing.
      final board = game(11);

      // The baseline has to be read immediately *before* the refused swap:
      // earlier swaps in the sweep may well have succeeded, and comparing
      // against the start of the run would be measuring those instead.
      var refused = 0;
      for (var row = 0; row < board.rows && refused == 0; row++) {
        for (var col = 0; col < board.columns - 1; col++) {
          final before = board.movesLeft;
          if (board.trySwap(col, row, col + 1, row)) {
            board.resolveAll();
            continue;
          }
          refused++;
          expect(board.movesLeft, before, reason: 'a refused swap cost a move');
          expect(
            board.isSettled,
            isTrue,
            reason: 'a refused swap left the board mid-match',
          );
          break;
        }
      }

      expect(refused, greaterThan(0), reason: 'no swap was ever refused');
    });

    test('non-adjacent and out-of-bounds swaps are refused', () {
      final board = game(5);
      expect(board.trySwap(0, 0, 2, 0), isFalse);
      expect(board.trySwap(0, 0, 1, 1), isFalse);
      expect(board.trySwap(0, 0, -1, 0), isFalse);
      expect(board.trySwap(0, 0, 0, board.rows), isFalse);
      expect(board.movesLeft, board.moves);
    });

    test('a swap that matches costs exactly one move', () {
      final board = game(7);
      final before = board.movesLeft;
      expect(_makeAnyMove(board), isTrue);
      expect(board.movesLeft, before - 1);
    });
  });

  group('resolving', () {
    test('a match clears, drops and refills to a full settled board', () {
      final board = game(9);
      expect(_makeAnyMove(board), isTrue);
      board.resolveAll();

      expect(board.isSettled, isTrue);
      for (var row = 0; row < board.rows; row++) {
        for (var col = 0; col < board.columns; col++) {
          expect(
            board.tileAt(col, row),
            isNotNull,
            reason: 'a hole survived the refill at ($col, $row)',
          );
        }
      }
    });

    test('an L or T clears as one group, not two', () {
      // Overlapping runs merged naively would double-count the shared tile,
      // and a five-tile L would score less than two separate threes — which
      // is backwards, since the L is the harder shape to build.
      final board = CoinCascadeGame(random: Random(1), columns: 5, rows: 5);
      _paint(board, [
        'nnn..',
        'n....',
        'n....',
        '.....',
        '.....',
      ]);
      // Column 0 rows 0-2 and row 0 columns 0-2 share (0,0), so this is one
      // L of five cells, not a three plus a three.
      final outcome = board.step();
      expect(outcome.clears.length, 1);
      expect(outcome.clears.single.size, 5);
    });

    test('a cascade scores more than the same tiles cleared flat', () {
      // The same shape scored twice: once as the player's own move, once as
      // if it had fallen into place three links into a chain. Repainting
      // between the two is the point — stepping a settled board returns
      // nothing, which is what made the first version of this test pass a
      // zero against a zero.
      CascadeOutcome scoreAt(int cascade) {
        final board = CoinCascadeGame(random: Random(2), columns: 5, rows: 5);
        _paint(board, [
          'nnn..',
          '.....',
          '.....',
          '.....',
          '.....',
        ]);
        return board.step(cascade: cascade);
      }

      final flat = scoreAt(0);
      final chained = scoreAt(3);
      expect(flat.clears, isNotEmpty);
      expect(
        chained.score,
        greaterThan(flat.score),
        reason:
            'a chain scores the same as a first move, so there is no reason '
            'to set one up',
      );
    });
  });

  group('the budget is the mechanic', () {
    test('needs pay bills down and wants push them up', () {
      final board = CoinCascadeGame(random: Random(4), columns: 5, rows: 5);

      _paint(board, [
        'nnn..',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      final needs = board.step();
      expect(needs.clears.length, 1);
      expect(needs.billsPaid, greaterThan(0));
      expect(needs.billsAdded, 0);

      _paint(board, [
        'www..',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      final wants = board.step();
      expect(wants.clears.length, 1);
      expect(wants.billsAdded, greaterThan(0));
      expect(
        wants.score,
        greaterThan(needs.score),
        reason: 'wants should be the tempting option, or the choice is fake',
      );
    });

    test('saving is the only thing that reaches the goal', () {
      final board = CoinCascadeGame(random: Random(6), columns: 5, rows: 5);
      _paint(board, [
        'sss..',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      final before = board.savings;
      board.step();
      expect(board.savings, greaterThan(before));

      _paint(board, [
        'ccc..',
        'nnn..',
        '.....',
        'www..',
        '.....',
      ]);
      final savingsBefore = board.savings;
      board.step();
      expect(
        board.savings,
        savingsBefore,
        reason: 'coins, needs and wants must not move the savings goal',
      );
    });

    test('bills are capped, not allowed to go negative', () {
      final board = CoinCascadeGame(random: Random(8), columns: 5, rows: 5);
      _paint(board, [
        'nnn..',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      board.step(); // pays bills while none are owed
      expect(board.bills, 0);
    });
  });

  group('the run cannot dead-end', () {
    test('a playable board is always left behind', () {
      // Ending a run on a board the player did nothing wrong to reach reads
      // as the game breaking, which is the one thing a game for young players
      // cannot afford. `_afterCascade` reshuffles rather than letting that
      // happen, and this is the invariant that guards it.
      //
      // Stated as a property over real play rather than by constructing a
      // dead board: a two-colour checkerboard *looks* dead and is not — a
      // vertical swap in one turns a row into three of a kind — and a test
      // built on that premise passes for the wrong reason.
      for (var seed = 0; seed < 30; seed++) {
        final board = game(seed);
        var guard = 0;
        while (board.status == CascadeStatus.playing && guard < 200) {
          expect(
            board.hasLegalMove(),
            isTrue,
            reason: 'seed $seed reached a dead board mid-run',
          );
          if (!_makeAnyMove(board)) break;
          board.resolveAll();
          guard++;
        }
      }
    });

    test('playing a whole run always terminates', () {
      // A cascade loop that cannot settle would hang the UI thread rather
      // than fail visibly.
      for (var seed = 0; seed < 25; seed++) {
        final board = game(seed);
        var guard = 0;
        while (board.status == CascadeStatus.playing && guard < 400) {
          if (!_makeAnyMove(board)) break;
          board.resolveAll();
          guard++;
        }
        expect(guard, lessThan(400), reason: 'seed $seed never finished');
        expect(board.isSettled, isTrue);
      }
    });

    test('a run always ends in a real result', () {
      for (final level in kCascadeLevels) {
        for (var seed = 0; seed < 12; seed++) {
          final board = CoinCascadeGame(random: Random(seed), level: level);
          while (board.status == CascadeStatus.playing) {
            if (!_makeAnyMove(board)) break;
            board.resolveAll();
          }
          expect(
            board.status,
            isNot(CascadeStatus.playing),
            reason: '${level.name} seed $seed never resolved',
          );
        }
      }
    });

    test('level 1 is winnable by a beginner, level 7 is not', () {
      // Played by a bot taking the first legal swap it finds — the weakest
      // strategy there is. The two ends of the ladder should answer it
      // differently, or the levels are decoration.
      //
      // This is what caught level 1 being *too* easy when the ladder landed:
      // the original single-tuning test asserted the bot must sometimes lose,
      // and level 1 is deliberately a walkover, so the property had to be
      // restated across the ladder rather than relaxed.
      int lossesOn(CascadeLevel level) {
        var losses = 0;
        for (var seed = 0; seed < 25; seed++) {
          final board = CoinCascadeGame(random: Random(seed), level: level);
          while (board.status == CascadeStatus.playing) {
            if (!_makeAnyMove(board)) break;
            board.resolveAll();
          }
          if (board.status == CascadeStatus.lost) losses++;
        }
        return losses;
      }

      final first = lossesOn(kCascadeLevels.first);
      final last = lossesOn(kCascadeLevels.last);
      expect(
        first,
        lessThan(10),
        reason: 'level 1 beats a beginner $first times in 25 — too harsh for '
            'the first thing a player meets',
      );
      expect(
        last,
        greaterThan(first),
        reason: 'the last level is no harder than the first for a random '
            'player, so the ladder is not a ladder',
      );
    });
  });

  group('coins buy moves', () {
    test('buying is refused when you cannot afford it', () {
      final board = game(15);
      board.coins = CoinCascadeGame.extraMoveCost - 1;
      expect(board.canBuyMoves, isFalse);
      expect(board.buyMoves(), isFalse);
    });

    test('buying spends the coins and adds the moves', () {
      final board = game(15);
      board.coins = CoinCascadeGame.extraMoveCost + 3;
      final moves = board.movesLeft;
      expect(board.buyMoves(), isTrue);
      expect(board.coins, 3);
      expect(board.movesLeft, moves + CoinCascadeGame.extraMovesPerPurchase);
    });
  });

  group('the level ladder', () {
    // A single tuning is one puzzle. Once a player has solved it there is
    // nothing left to find out, which is why each level changes *what you have
    // to think about* rather than just how much of it there is.
    test('every level is reachable and numbered in order', () {
      for (var i = 0; i < kCascadeLevels.length; i++) {
        expect(kCascadeLevels[i].number, i + 1);
        expect(cascadeLevelFor(i + 1), kCascadeLevels[i]);
      }
    });

    test('the ladder is long enough to be a ladder', () {
      // It stopped at 7 -- about twenty minutes -- and then repeated its
      // hardest level for ever, because `cascadeLevelFor` falls back to the
      // last one. A game whose progression ends silently is a game that
      // teaches you it has nothing left.
      expect(kCascadeLevels.length, greaterThanOrEqualTo(13));
    });

    test('each level changes what you have to think about', () {
      // Not just bigger numbers: every level has to differ from the one
      // before it on at least one *rule* dial, or the ladder is a grind
      // wearing a progression's clothes.
      for (var i = 1; i < kCascadeLevels.length; i++) {
        final a = kCascadeLevels[i - 1];
        final b = kCascadeLevels[i];
        final changed =
            a.billInterval != b.billInterval ||
            a.wantsCostMultiplier != b.wantsCostMultiplier ||
            a.coinValue != b.coinValue ||
            a.billCapacity != b.billCapacity ||
            a.moves != b.moves;
        expect(
          changed,
          isTrue,
          reason: 'level ${b.number} plays identically to ${a.number}',
        );
      }
    });

    test('an unknown level falls back rather than throwing', () {
      // Reached by "Next" on the last level if that guard ever regresses. A
      // crash there would end a winning run on an error screen.
      expect(cascadeLevelFor(999), kCascadeLevels.last);
      expect(cascadeLevelFor(0), kCascadeLevels.last);
    });

    test('every level states its rule in one line', () {
      // A rule that needs two lines is too complicated for a game a
      // seven-year-old plays.
      for (final level in kCascadeLevels) {
        expect(level.name, isNotEmpty);
        expect(level.rule.length, greaterThan(20), reason: level.name);
        expect(level.rule.length, lessThan(90), reason: level.name);
      }
    });

    test('the ladder gets harder', () {
      // Not monotonic in any single number — level 3 lowers the goal and
      // halves the moves — so this checks the *combination*: goal per move
      // available, which is the thing a player actually feels.
      double pressure(CascadeLevel l) => l.savingsGoal / l.moves;
      expect(
        pressure(kCascadeLevels.last),
        greaterThan(pressure(kCascadeLevels.first)),
        reason: 'the last level asks less per move than the first',
      );
    });

    test('the rule twists actually change play', () {
      // Guards the twists being data that nothing reads — the failure mode
      // where a level says "wants cost double" and plays identically.
      final doubled = kCascadeLevels.firstWhere(
        (l) => l.wantsCostMultiplier > 1,
      );
      final board = CoinCascadeGame(
        random: Random(3),
        level: doubled,
        columns: 5,
        rows: 5,
      );
      _paint(board, [
        'www..',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      final doubledCost = board.step().billsAdded;

      final plain = CoinCascadeGame(
        random: Random(3),
        level: kCascadeLevels.first,
        columns: 5,
        rows: 5,
      );
      _paint(plain, [
        'www..',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      final plainCost = plain.step().billsAdded;

      expect(
        doubledCost,
        greaterThan(plainCost),
        reason: 'the "wants cost double" level charges the same as level 1',
      );
    });

    test('a level with richer coins pays more per match', () {
      final rich = kCascadeLevels.firstWhere((l) => l.coinValue > 1);
      final board = CoinCascadeGame(
        random: Random(5),
        level: rich,
        columns: 5,
        rows: 5,
      );
      _paint(board, [
        'ccc..',
        '.....',
        '.....',
        '.....',
        '.....',
      ]);
      expect(board.step().coins, greaterThan(3));
    });

    test('bills arrive on the level schedule', () {
      for (final level in kCascadeLevels) {
        expect(
          level.billInterval,
          inInclusiveRange(2, 6),
          reason: '${level.name} schedules bills every ${level.billInterval}',
        );
      }
    });
  });

  group('the payout rewards the goal', () {
    test('savings are worth more than raw score', () {
      final saver = game(20)
        ..savings = 20
        ..score = 0
        ..coins = 0;
      final scorer = game(20)
        ..savings = 0
        ..score = 1000
        ..coins = 0;
      expect(
        saver.goldEarned,
        greaterThan(scorer.goldEarned),
        reason:
            'a player who chased score out-earned one who reached the goal, '
            'so the payout is teaching the opposite of the game',
      );
    });
  });
}

/// Makes the first legal swap found, or returns false if none exists.
bool _makeAnyMove(CoinCascadeGame board) {
  for (var row = 0; row < board.rows; row++) {
    for (var col = 0; col < board.columns; col++) {
      if (col + 1 < board.columns && board.trySwap(col, row, col + 1, row)) {
        return true;
      }
      if (row + 1 < board.rows && board.trySwap(col, row, col, row + 1)) {
        return true;
      }
    }
  }
  return false;
}

/// Writes a board from a picture, so the mechanics tests read as the shapes
/// they are checking rather than as a list of coordinates.
///
/// `.` means "background": a repeating four-kind pattern chosen so that **no
/// two neighbouring cells are ever the same kind**, in either direction. That
/// property is what makes these pictures trustworthy — a background with an
/// accidental pair in it could turn a stamped three into a four, or produce a
/// second match the test was not asking about, and the assertion that failed
/// would look like an engine bug.
///
/// Stamped letters: `n` need, `w` want, `s` save, `c` coin, `b` bill.
void _paint(CoinCascadeGame board, List<String> rows) {
  const legend = <String, TileKind>{
    'n': TileKind.need,
    'w': TileKind.want,
    's': TileKind.save,
    'c': TileKind.coin,
    'b': TileKind.bill,
  };
  var id = 100000;
  for (var row = 0; row < board.rows; row++) {
    for (var col = 0; col < board.columns; col++) {
      final ch = row < rows.length && col < rows[row].length
          ? rows[row][col]
          : '.';
      // (col + 2 * row) % 4 steps by 1 across and by 2 down, so neither a
      // horizontal nor a vertical neighbour can repeat.
      final kind = ch == '.'
          ? TileKind.spawnable[(col + 2 * row) % TileKind.spawnable.length]
          : legend[ch]!;
      board.debugSet(col, row, kind, id++);
    }
  }
}
