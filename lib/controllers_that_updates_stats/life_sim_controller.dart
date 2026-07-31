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
    int initialAge = 0,
    int startMoney = 0,
    this.name = 'Alex Morgan',
    this.gender = Gender.nonBinary,
    this.origin = LifeOrigin.workingClass,
  }) : _random = random ?? Random(),
       startAge = initialAge,
       _age = initialAge,
       _money = startMoney {
    _happiness = origin.startingHappiness;
    _smarts = origin.startingSmarts;
    _looks = 40 + _random.nextInt(35);
    _setLog(
      'Born into a ${origin.label.toLowerCase()} family. '
      'Tap Age to live your first year.',
    );
  }

  final Random _random;
  final int startAge;

  /// Who this life belongs to — set during character creation.
  final String name;
  final Gender gender;
  final LifeOrigin origin;

  int _age;
  int _money;
  int _investments = 0;
  int _happiness = 65;
  int _health = 85;
  int _smarts = 45;
  int _looks = 50;
  String _job = 'Newborn';
  int _salary = 0;
  bool _retired = false;
  bool _dead = false;

  final List<String> _relationships = <String>[];

  LifeEvent? _currentEvent;
  String _log = '';

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
  int get looks => _looks;
  String get job => _job;
  int get salary => _salary;
  bool get retired => _retired;
  bool get dead => _dead;

  /// True when the run is over for any reason — retired or died.
  bool get finished => _retired || _dead;

  List<String> get relationships => List.unmodifiable(_relationships);
  LifeEvent? get currentEvent => _currentEvent;
  String get log => _log;
  int get yearsLived => _age - startAge;

  LifeStage get stage => LifeStageInfo.forAge(_age);
  int get netWorth => _money + _investments;

  /// Under 18 the family covers everything, so the money layer stays dormant
  /// while childhood events play out.
  bool get isDependent => _age < 18;

  /// Gold banked into the real economy when the run ends. Tied to how well the
  /// life went so it can't mint unlimited gold.
  int get goldReward =>
      (yearsLived * 4) +
      (netWorth ~/ 100) +
      (_happiness ~/ 5) +
      (_smarts ~/ 10);

  /// Advances one year: applies income and living costs, grows investments,
  /// ages the body, then draws a life event. No-op while an event awaits a
  /// choice, or once the run has ended.
  void ageUp() {
    if (finished || _currentEvent != null) {
      return;
    }
    _age++;

    if (!isDependent) {
      _money += _salary;
      _money -= _livingCost();
      if (_money < 0) {
        // No debt spiral — the shortfall costs happiness instead.
        _happiness = _clamp(_happiness - 8);
        _money = 0;
      }
      // Investments compound ~7% a year.
      _investments = (_investments * 1.07).round();
    }

    _applyAgeing();
    if (_dead) {
      notifyListeners();
      return;
    }

    // Milestones give the feed texture on years with no event.
    final milestone = _milestoneFor(_age);
    _currentEvent = _drawEvent();
    _setLog(
      milestone ??
          'Turned $_age.'
              '${_currentEvent == null ? ' A quiet year.' : ''}',
    );
    notifyListeners();
  }

  /// Health decline with age, and the chance the life ends.
  void _applyAgeing() {
    if (_age > 45) {
      _health = _clamp(_health - 1);
    }
    if (_age > 65) {
      _health = _clamp(_health - 2);
    }

    // Death risk climbs with age and poor health. Deliberately gentle so a run
    // usually reaches old age.
    if (_age >= 60 || _health <= 5) {
      final risk = ((_age - 55) * 2) + (100 - _health) ~/ 4;
      if (risk > 0 && _random.nextInt(260) < risk) {
        _dead = true;
        _currentEvent = null;
        _setLog(
          _health <= 5
              ? 'You passed away at $_age after your health gave out.'
              : 'You passed away peacefully at $_age.',
        );
      }
    }
  }

  String? _milestoneFor(int age) => switch (age) {
    1 => 'Your first birthday. You mostly ate the cake.',
    5 => 'You started school.',
    13 => 'You are officially a teenager.',
    16 => 'Sweet sixteen.',
    18 => 'You are an adult now — bills are yours from here.',
    21 => 'Twenty-one. The world feels wide open.',
    30 => 'Thirty. Time moves faster than it used to.',
    50 => 'Fifty. Half a century.',
    65 => 'Retirement age. Where did it all go?',
    _ => null,
  };

  int _livingCost() {
    return switch (stage) {
      LifeStage.baby || LifeStage.child || LifeStage.teen => 0,
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
    _looks = _clamp(_looks + choice.looks);
    if (choice.setJob != null) {
      _job = choice.setJob!;
      _salary = choice.setSalary ?? _salary;
    }
    final person = choice.addRelationship;
    if (person != null && !_relationships.contains(person)) {
      _relationships.add(person);
    }
    _setLog(choice.outcome);
    _currentEvent = null;
    notifyListeners();
  }

  // --- Always-available activities ---

  /// Study to raise Smarts.
  void study() {
    if (finished) return;
    _smarts = _clamp(_smarts + 6);
    _happiness = _clamp(_happiness - 2);
    if (!isDependent) {
      _money = max(0, _money - 30);
    }
    _setLog(
      isDependent
          ? 'Hit the books after school: +6 Smarts.'
          : 'Took a course: +6 Smarts, -30 coins.',
    );
    notifyListeners();
  }

  /// Spend time (and money, once independent) on fun.
  void haveFun() {
    if (finished) return;
    if (!isDependent && _money < 40) {
      _log = 'Not enough coins for a night out.';
      notifyListeners();
      return;
    }
    if (!isDependent) {
      _money -= 40;
    }
    _happiness = _clamp(_happiness + 10);
    _setLog('Had a great time: +10 Happiness.');
    notifyListeners();
  }

  /// Work out — better health and looks, a little tiring.
  void exercise() {
    if (finished) return;
    _health = _clamp(_health + 8);
    _looks = _clamp(_looks + 3);
    _happiness = _clamp(_happiness - 1);
    _setLog('Worked out: +8 Health, +3 Looks.');
    notifyListeners();
  }

  /// Move cash into investments, which compound each year.
  void invest(int amount) {
    if (finished || amount <= 0 || _money < amount) {
      return;
    }
    _money -= amount;
    _investments += amount;
    _smarts = _clamp(_smarts + 2);
    _setLog('Invested $amount coins. It compounds every year.');
    notifyListeners();
  }

  /// End the run early and bank the reward.
  void retire() {
    if (_dead) return;
    _retired = true;
    _currentEvent = null;
    notifyListeners();
  }

  int _clamp(int value) => value.clamp(0, 100);
}
