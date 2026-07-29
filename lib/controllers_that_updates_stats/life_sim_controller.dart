import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models_Like_Skins_and_lessons_templates/life_sim_models.dart';

/// The rules engine for **Life**, the main game.
///
/// Self-contained on purpose: it holds its own in-memory money and stats and
/// depends on nothing (no Supabase, no providers), so the whole game is unit
/// testable and can't corrupt the player's real gold. The screen turns a
/// finished life into a gold/XP reward through [goldReward].
class LifeSimController extends ChangeNotifier {
  LifeSimController({
    Random? random,
    int initialAge = 15,
    int startMoney = 200,
  }) : _random = random ?? Random(),
       startAge = initialAge,
       _age = initialAge,
       _money = startMoney;

  final Random _random;
  final int startAge;

  int _age;
  int _money;
  int _investments = 0;
  int _happiness = 65;
  int _health = 80;
  int _smarts = 45;
  String _job = 'Student';
  int _salary = 0;
  bool _retired = false;

  LifeEvent? _currentEvent;
  String _log = 'Your story is just beginning. Age up to live it out.';

  /// The scrolling life feed (BitLife-style), oldest first.
  final List<LifeLogEntry> history = <LifeLogEntry>[];

  void _setLog(String text) {
    _log = text;
    history.add(LifeLogEntry(age: _age, text: text));
  }

  int get age => _age;
  int get money => _money;
  int get investments => _investments;
  int get happiness => _happiness;
  int get health => _health;
  int get smarts => _smarts;
  String get job => _job;
  int get salary => _salary;
  bool get retired => _retired;
  LifeEvent? get currentEvent => _currentEvent;
  String get log => _log;
  int get yearsLived => _age - startAge;

  LifeStage get stage => LifeStageInfo.forAge(_age);
  int get netWorth => _money + _investments;

  /// Gold banked into the real economy when the player retires/cashes out.
  /// Tied to how well the life went so it can't mint unlimited gold.
  int get goldReward =>
      (yearsLived * 5) + (netWorth ~/ 100) + (_happiness ~/ 5);

  /// Advances one year: applies salary and living costs, grows investments,
  /// then draws a life event to resolve. No-op while an event is still
  /// awaiting a choice, or once retired.
  void ageUp() {
    if (_retired || _currentEvent != null) {
      return;
    }
    _age++;

    // Yearly finances.
    _money += _salary;
    _money -= _livingCost();
    if (_money < 0) {
      // Can't go below zero — the shortfall hurts happiness instead of debt.
      _happiness = _clamp(_happiness - 8);
      _money = 0;
    }
    // Investments compound ~7% a year.
    _investments = (_investments * 1.07).round();

    // Health drifts down slowly with age; happiness drifts toward the middle.
    if (_age > 40) {
      _health = _clamp(_health - 1);
    }

    _currentEvent = _drawEvent();
    _setLog(
      'Turned $_age.${_currentEvent == null ? ' A quiet year — life ticks along.' : ''}',
    );
    notifyListeners();
  }

  int _livingCost() {
    return switch (stage) {
      LifeStage.teen => 40,
      LifeStage.youngAdult => 110,
      LifeStage.adult => 180,
      LifeStage.senior => 140,
    };
  }

  LifeEvent? _drawEvent() {
    final eligible = kLifeEvents
        .where((e) => e.eligibleAt(_age))
        .toList(growable: false);
    if (eligible.isEmpty) {
      return null;
    }
    // ~25% of years are quiet, so events feel like events.
    if (_random.nextInt(4) == 0) {
      return null;
    }
    return eligible[_random.nextInt(eligible.length)];
  }

  /// Resolves the current event with the chosen option's effects.
  void chooseOption(int index) {
    final event = _currentEvent;
    if (event == null || index < 0 || index >= event.choices.length) {
      return;
    }
    final choice = event.choices[index];
    _money = max(0, _money + choice.money);
    _happiness = _clamp(_happiness + choice.happiness);
    _health = _clamp(_health + choice.health);
    _smarts = _clamp(_smarts + choice.smarts);
    if (choice.setJob != null) {
      _job = choice.setJob!;
      _salary = choice.setSalary ?? _salary;
    }
    _setLog(choice.outcome);
    _currentEvent = null;
    notifyListeners();
  }

  // --- Always-available quick actions (BitLife "activities") ---

  /// Study to raise Smarts; costs a little money and energy (happiness).
  void study() {
    if (_retired) return;
    _smarts = _clamp(_smarts + 6);
    _money = max(0, _money - 30);
    _happiness = _clamp(_happiness - 2);
    _setLog('Hit the books: +6 Smarts.');
    notifyListeners();
  }

  /// Spend on fun to raise Happiness.
  void haveFun() {
    if (_retired) return;
    if (_money < 40) {
      _log = 'Not enough coins for a night out.';
      notifyListeners();
      return;
    }
    _money -= 40;
    _happiness = _clamp(_happiness + 10);
    _setLog('Treated yourself: +10 Happiness.');
    notifyListeners();
  }

  /// Move cash into investments, which compound each year.
  void invest(int amount) {
    if (_retired || amount <= 0 || _money < amount) {
      return;
    }
    _money -= amount;
    _investments += amount;
    _smarts = _clamp(_smarts + 2);
    _setLog('Invested $amount coins. It now compounds every year.');
    notifyListeners();
  }

  /// End the run and bank the reward.
  void retire() {
    _retired = true;
    _currentEvent = null;
    notifyListeners();
  }

  int _clamp(int value) => value.clamp(0, 100);
}
