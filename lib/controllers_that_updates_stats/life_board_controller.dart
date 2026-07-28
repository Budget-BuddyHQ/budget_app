import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models_Like_Skins_and_lessons_templates/life_board_models.dart';

/// The rules engine for the Life Board main game.
///
/// Deliberately self-contained: it holds its own in-memory `cash` and stats and
/// depends on nothing (no Supabase, no providers), so the whole game is unit
/// testable and can't corrupt the player's real gold. The screen turns a
/// finished session into a gold/XP reward through [goldReward], the same way
/// the arcade minigames hand back a payload.
class LifeBoardController extends ChangeNotifier {
  LifeBoardController({Random? random, int startingCash = 500})
    : _random = random ?? Random(),
      _cash = startingCash;

  final Random _random;

  final List<LifeTile> tiles = kLifeBoard;

  int _position = 0;
  int _cash;
  int _energy = 60;
  int _knowledge = 40;
  int _reputation = 40;
  int _laps = 0;
  int _lastRoll = 0;
  int _turns = 0;
  String _eventMessage = 'Roll the dice to live out your week.';
  final Set<String> _ownedAssetIds = <String>{};

  /// Set when the token lands on an opportunity tile — the screen shows a
  /// buy/skip prompt while this is non-null.
  TycoonAsset? _pendingOffer;

  int get position => _position;
  int get cash => _cash;
  int get energy => _energy;
  int get knowledge => _knowledge;
  int get reputation => _reputation;
  int get laps => _laps;
  int get lastRoll => _lastRoll;
  int get turns => _turns;
  String get eventMessage => _eventMessage;
  TycoonAsset? get pendingOffer => _pendingOffer;

  LifeTile get currentTile => tiles[_position];

  List<TycoonAsset> get ownedAssets => kTycoonAssets
      .where((asset) => _ownedAssetIds.contains(asset.id))
      .toList(growable: false);

  int get passiveIncome =>
      ownedAssets.fold(0, (sum, asset) => sum + asset.incomePerLap);

  /// Cash plus everything owned — the score the game is really about.
  int get netWorth =>
      _cash + ownedAssets.fold(0, (sum, asset) => sum + asset.cost);

  /// Gold handed back to the real economy when the session ends. Modest and
  /// tied to progress so the board can't mint unlimited gold.
  int get goldReward => (_laps * 15) + (netWorth ~/ 200);

  /// Rolls a die and moves the token, collecting lap income on the way past
  /// Start and then resolving whatever tile it lands on. No-op while an
  /// opportunity is still awaiting a decision.
  void roll() {
    if (_pendingOffer != null) {
      return;
    }
    final steps = _random.nextInt(6) + 1;
    _lastRoll = steps;
    _turns++;

    final previous = _position;
    _position = (_position + steps) % tiles.length;
    // Wrapped past index 0 → completed a lap.
    if (previous + steps >= tiles.length) {
      _laps++;
      _collectLap();
    }

    _resolveTile(tiles[_position]);
    notifyListeners();
  }

  void _collectLap() {
    final salary = 200 + passiveIncome;
    _cash += salary;
  }

  void _resolveTile(LifeTile tile) {
    switch (tile.type) {
      case LifeTileType.start:
        _eventMessage = 'Back to Start — collected your salary and income.';
      case LifeTileType.payday:
        // Skills pay off: knowledge and reputation each add a bonus.
        final bonus = (_knowledge ~/ 4) + (_reputation ~/ 4);
        final pay = tile.amount + bonus;
        _cash += pay;
        _eventMessage = 'Payday! +$pay coins (skills added $bonus).';
      case LifeTileType.expense:
        final paid = min(_cash, tile.amount);
        _cash -= paid;
        _eventMessage = '${tile.label}: paid $paid coins.';
      case LifeTileType.study:
        _knowledge = min(100, _knowledge + tile.amount);
        _energy = max(0, _energy - 8);
        _eventMessage = 'Studied hard: +${tile.amount} knowledge, -8 energy.';
      case LifeTileType.rest:
        _energy = min(100, _energy + tile.amount);
        _eventMessage = 'Rested up: +${tile.amount} energy.';
      case LifeTileType.social:
        final spent = min(_cash, 20);
        _cash -= spent;
        _reputation = min(100, _reputation + tile.amount);
        _eventMessage =
            '${tile.label}: +${tile.amount} reputation for $spent coins.';
      case LifeTileType.opportunity:
        _offerAsset(tile);
      case LifeTileType.chance:
        _resolveChance();
    }
  }

  /// Offers the best asset the player can afford and doesn't already own.
  void _offerAsset(LifeTile tile) {
    for (final asset in kTycoonAssets.reversed) {
      if (!_ownedAssetIds.contains(asset.id) && _cash >= asset.cost) {
        _pendingOffer = asset;
        _eventMessage =
            '${tile.label}: buy ${asset.name} for ${asset.cost} coins?';
        return;
      }
    }
    _eventMessage = '${tile.label}: nothing you can afford yet — keep earning.';
  }

  void _resolveChance() {
    // Small, bounded swings so a single tile can't wreck or win the game.
    final roll = _random.nextInt(4);
    switch (roll) {
      case 0:
        final windfall = 60 + _random.nextInt(80);
        _cash += windfall;
        _eventMessage = 'Lucky break: +$windfall coins.';
      case 1:
        final fee = min(_cash, 50 + _random.nextInt(60));
        _cash -= fee;
        _eventMessage = 'Surprise cost: -$fee coins.';
      case 2:
        _knowledge = min(100, _knowledge + 6);
        _eventMessage = 'Free workshop: +6 knowledge.';
      default:
        _reputation = min(100, _reputation + 6);
        _eventMessage = 'Good deed noticed: +6 reputation.';
    }
  }

  /// Confirms the pending purchase. Returns false if it can no longer be
  /// afforded (cash changed since the offer, in theory).
  bool acceptOffer() {
    final asset = _pendingOffer;
    if (asset == null) {
      return false;
    }
    if (_cash < asset.cost) {
      _eventMessage = 'Not enough cash for ${asset.name} anymore.';
      _pendingOffer = null;
      notifyListeners();
      return false;
    }
    _cash -= asset.cost;
    _ownedAssetIds.add(asset.id);
    _eventMessage =
        'Bought ${asset.name}! It now pays ${asset.incomePerLap} coins a lap.';
    _pendingOffer = null;
    notifyListeners();
    return true;
  }

  void declineOffer() {
    _pendingOffer = null;
    _eventMessage = 'Passed on the deal. Maybe next lap.';
    notifyListeners();
  }
}
