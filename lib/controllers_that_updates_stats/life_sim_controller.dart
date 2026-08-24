import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
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
    // Start already employed. Sits alongside `initialAge`/`startMoney` as
    // another "begin partway through a life" hook — used by tests to reach
    // the budgeting path (which needs income) without simulating twenty
    // years first, and available to any future "quick start" mode.
    String? startJob,
    int startSalary = 0,
    this.name = 'Alex Morgan',
    this.gender = Gender.nonBinary,
    this.origin = LifeOrigin.workingClass,
  }) : _random = random ?? Random(),
       startAge = initialAge,
       _age = initialAge,
       _money = startMoney,
       _job = startJob ?? 'Newborn',
       _salary = startSalary {
    _happiness = origin.startingHappiness;
    _smarts = origin.startingSmarts;
    _looks = 40 + _random.nextInt(35);
    // Two traits rolled at birth. These are the hidden-modifier layer: they
    // gate which events can fire, so two runs with identical stats still
    // diverge.
    final pool = List<LifeTrait>.from(LifeTrait.values)..shuffle(_random);
    _traits.addAll(pool.take(2));
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
  String _job;
  int _salary;
  bool _retired = false;
  bool _dead = false;
  int _fame = 0;

  final Map<LifeSkill, int> _skills = <LifeSkill, int>{};
  final Set<LifeTrait> _traits = <LifeTrait>{};

  // ---- Budgeting -------------------------------------------------------
  //
  // The app was full of money *outcomes* but had nowhere the player
  // actually practised budgeting — the core skill it claims to teach. This
  // is that: each year with income, the player splits take-home pay across
  // needs / wants / savings, and the split has real consequences below in
  // [_applyBudget]. Defaults are the textbook 50/30/20 so an untouched
  // budget is sensible rather than punishing.
  int _needsPct = 50;
  int _wantsPct = 30;
  int _savingsPct = 20;
  bool _budgetSet = false;

  /// Savings the budget has actually banked, kept separate from [_money] so
  /// the player can see the fund they built rather than one blended number.
  /// This is what an emergency event draws down first.
  int _emergencyFund = 0;

  /// Owed money, from covering a shock with no fund. Accrues interest each
  /// year — the borrowing-costs-extra lesson, made mechanical.
  int _debt = 0;

  /// Concepts this life has surfaced, in order first met.
  final List<FinanceConcept> _conceptsMet = <FinanceConcept>[];

  /// A lesson waiting to be shown by the UI, consumed via [takeLesson].
  FinanceConcept? _pendingLesson;

  /// Whether [_pendingLesson] was met for the first time. The UI uses this
  /// to decide whether the moment is a celebration — confetti reads as
  /// "you unlocked a new idea", which is true the first time and just noisy
  /// on a repeat, and is actively the wrong tone when the concept behind it
  /// is bad news (e.g. `interestCost` from carrying debt).
  bool _pendingLessonIsNew = false;

  int get needsPct => _needsPct;
  int get wantsPct => _wantsPct;
  int get savingsPct => _savingsPct;
  bool get budgetSet => _budgetSet;
  int get emergencyFund => _emergencyFund;
  int get debt => _debt;
  List<FinanceConcept> get conceptsMet => List.unmodifiable(_conceptsMet);

  /// True once the character earns — budgeting is meaningless before that,
  /// so the UI only offers it from here.
  bool get canBudget => !isDependent && _salary > 0 && !finished;

  /// Months of essential spending the fund covers. The standard yardstick
  /// for "is my emergency fund big enough" is 3-6 months, so expressing it
  /// this way teaches the measure, not just the balance.
  double get emergencyMonths {
    final monthlyNeeds = (_salary * _needsPct / 100) / 12;
    if (monthlyNeeds <= 0) return 0;
    return _emergencyFund / monthlyNeeds;
  }

  /// Sets the split. Rejects anything that doesn't total 100 — the point of
  /// the exercise is that a budget has to add up.
  bool setBudget({required int needs, required int wants, required int savings}) {
    if (needs < 0 || wants < 0 || savings < 0) return false;
    if (needs + wants + savings != 100) return false;
    _needsPct = needs;
    _wantsPct = wants;
    _savingsPct = savings;
    _budgetSet = true;
    _teach(FinanceConcept.budgetRule);
    _setLog(
      'Budget set: $needs% needs, $wants% wants, $savings% savings.',
    );
    notifyListeners();
    return true;
  }

  /// Records a concept as met and queues it for the UI to explain.
  /// Re-meeting a concept still surfaces the reminder but doesn't duplicate
  /// the list entry.
  void _teach(FinanceConcept concept) {
    final isNew = !_conceptsMet.contains(concept);
    if (isNew) {
      _conceptsMet.add(concept);
    }
    _pendingLesson = concept;
    _pendingLessonIsNew = isNew;
  }

  /// Hands the queued lesson to the UI exactly once.
  FinanceConcept? takeLesson() {
    final lesson = _pendingLesson;
    _pendingLesson = null;
    return lesson;
  }

  /// Whether the lesson [takeLesson] is about to return (or just returned)
  /// is being met for the first time this life. Read this *before*
  /// `takeLesson()` clears the concept, since it describes the same pending
  /// lesson rather than tracking its own state.
  bool get pendingLessonIsNew => _pendingLessonIsNew;

  /// Applies one year of the budget: funds needs, spends wants, banks
  /// savings, then charges interest on any debt.
  ///
  /// The consequences are the teaching. Underfunding needs costs health and
  /// happiness (you cannot cut rent and food without it hurting); starving
  /// wants costs happiness too (an unlivable budget gets abandoned in real
  /// life, which is why 100% austerity is not the "right answer" here);
  /// savings build the fund that makes the next shock survivable.
  void _applyBudget() {
    final income = _salary;
    if (income <= 0) return;

    final needsBudget = (income * _needsPct / 100).round();
    final wantsBudget = (income * _wantsPct / 100).round();
    final savingsBudget = (income * _savingsPct / 100).round();
    final actualNeeds = _livingCost();

    _money += income;
    _money -= needsBudget + wantsBudget;

    if (needsBudget < actualNeeds) {
      // Needs are not optional; the shortfall comes out of you.
      final shortfall = actualNeeds - needsBudget;
      _money -= shortfall;
      _health = _clamp(_health - 4);
      _happiness = _clamp(_happiness - 6);
      _setLog(
        'Your needs budget did not cover the essentials — you went short by '
        '$shortfall this year.',
      );
      _teach(FinanceConcept.needsVsWants);
    }

    if (_wantsPct <= 5) {
      // A budget with no room to live in is one you abandon.
      _happiness = _clamp(_happiness - 4);
    }

    _emergencyFund += savingsBudget;
    _money -= savingsBudget;
    if (_money < 0) {
      _money = 0;
    }

    if (_debt > 0) {
      // 18% a year, roughly a credit card. Deliberately visible in the feed
      // so the cost of carrying it is felt, not hidden.
      final interest = (_debt * 0.18).round();
      _debt += interest;
      final payment = (_money * 0.3).round();
      final paid = payment.clamp(0, _debt);
      _money -= paid;
      _debt -= paid;
      _setLog(
        'Debt cost you $interest in interest this year. '
        '${_debt > 0 ? 'Still owing $_debt.' : 'Finally paid off.'}',
      );
      _teach(FinanceConcept.interestCost);
    }
  }

  /// An unavoidable expense. Draws the emergency fund first, then cash, then
  /// borrows — which is precisely the ladder a real household walks down,
  /// and the moment the fund either proves its worth or is conspicuously
  /// missing.
  void applyShock(int amount, String reason) {
    var remaining = amount;
    final fromFund = remaining.clamp(0, _emergencyFund);
    _emergencyFund -= fromFund;
    remaining -= fromFund;

    final fromCash = remaining.clamp(0, _money);
    _money -= fromCash;
    remaining -= fromCash;

    if (remaining > 0) {
      _debt += remaining;
      _happiness = _clamp(_happiness - 8);
      _setLog(
        '$reason cost $amount. With nothing saved you had to borrow '
        '$remaining of it.',
      );
      _teach(FinanceConcept.emergencyFund);
    } else {
      _setLog(
        '$reason cost $amount — covered from savings without borrowing.',
      );
      _teach(FinanceConcept.emergencyFund);
    }
    notifyListeners();
  }

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
  int get fame => _fame;

  Map<LifeSkill, int> get skills => Map.unmodifiable(_skills);
  Set<LifeTrait> get traits => Set.unmodifiable(_traits);

  int skillLevel(LifeSkill skill) => _skills[skill] ?? 0;

  /// Everything the event engine needs to decide what can fire this year.
  LifeContext get context => LifeContext(
    age: _age,
    money: _money,
    happiness: _happiness,
    health: _health,
    smarts: _smarts,
    fame: _fame,
    skills: _skills,
    traits: _traits,
    hasJob: _salary > 0,
  );

  /// True when the run is over for any reason — retired or died.
  bool get finished => _retired || _dead;

  List<String> get relationships => List.unmodifiable(_relationships);
  LifeEvent? get currentEvent => _currentEvent;
  String get log => _log;
  int get yearsLived => _age - startAge;

  LifeStage get stage => LifeStageInfo.forAge(_age);

  /// Everything you own minus everything you owe — the "earning vs keeping"
  /// distinction made literal. The emergency fund counts (it is yours);
  /// debt subtracts, so a high salary financed by borrowing does not read
  /// as wealth.
  int get netWorth => _money + _investments + _emergencyFund - _debt;

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
      if (_salary > 0) {
        // Earning years run through the budget, so the split the player
        // chose is what actually governs the year.
        _applyBudget();
      } else {
        _money -= _livingCost();
        if (_money < 0) {
          // No debt spiral — the shortfall costs happiness instead.
          _happiness = _clamp(_happiness - 8);
          _money = 0;
        }
      }
      // Investments compound ~7% a year.
      _investments = (_investments * 1.07).round();
    }

    _applyAgeing();
    if (_dead) {
      notifyListeners();
      return;
    }

    _maybeFinancialShock();

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

  /// Real life bills you at the worst time. Roughly a 1-in-7 chance each
  /// earning year of an unavoidable expense.
  ///
  /// This exists to give the emergency fund something to be *for*. Without
  /// it, saving is an abstract number that only ever goes up, and the
  /// player never finds out why anyone bothers. With it, the same shock is
  /// a shrug for a player who budgeted savings and a debt spiral for one
  /// who did not — the lesson lands as an experience rather than a tip.
  static const List<({String reason, int min, int max})> _shocks = [
    (reason: 'Your car broke down', min: 300, max: 900),
    (reason: 'A trip to the dentist', min: 150, max: 500),
    (reason: 'The boiler gave out', min: 400, max: 1100),
    (reason: 'Your phone was stolen', min: 200, max: 600),
    (reason: 'An unexpected vet bill', min: 180, max: 700),
    (reason: 'A leak damaged the floor', min: 350, max: 1000),
  ];

  void _maybeFinancialShock() {
    if (isDependent || _salary <= 0 || finished) return;
    if (_random.nextInt(7) != 0) return;
    final shock = _shocks[_random.nextInt(_shocks.length)];
    final amount = shock.min + _random.nextInt(shock.max - shock.min + 1);
    applyShock(amount, shock.reason);
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

  /// Picks this year's event.
  ///
  /// Every candidate declares its own requirements (age, skill, trait, fame,
  /// money, employment) and a relative [LifeEvent.weight]; this filters by
  /// those, then does a weighted roll. Previously it was a uniform pick over
  /// an age-only filter, which meant a rare dramatic beat was exactly as
  /// likely as a routine one and nothing could ever depend on who the
  /// character had become.
  /// Ids already used this life, so the draw doesn't serve the same beat twice.
  final Set<String> _seen = <String>{};

  /// Age at which each repeatable event last fired, for the cooldown.
  final Map<String, int> _lastFiredAge = <String, int>{};

  /// Years a repeatable event must sit out before it can come round again.
  static const int _repeatCooldownYears = 6;

  LifeEvent? _drawEvent() {
    final ctx = context;

    // ~25% of years are quiet, so events feel like events.
    if (_random.nextInt(4) == 0) {
      return null;
    }

    bool fresh(LifeEvent e) {
      if (!e.matches(ctx)) return false;
      if (!_seen.contains(e.id)) return true;
      if (!e.repeatable) return false;
      final last = _lastFiredAge[e.id];
      return last == null || _age - last >= _repeatCooldownYears;
    }

    var eligible = kLifeEvents.where(fresh).toList(growable: false);

    // Late in a long life the unseen pool can genuinely run dry. Rather than
    // going silent for twenty years, fall back to anything repeatable that has
    // served its cooldown — and only then to the raw eligible set.
    if (eligible.isEmpty) {
      eligible = kLifeEvents
          .where((e) => e.matches(ctx) && e.repeatable)
          .toList(growable: false);
    }
    if (eligible.isEmpty) {
      return null;
    }

    final total = eligible.fold<double>(0, (sum, e) => sum + e.weight);
    final chosen = total <= 0
        ? eligible[_random.nextInt(eligible.length)]
        : _weightedPick(eligible, total);

    _seen.add(chosen.id);
    _lastFiredAge[chosen.id] = _age;
    return chosen;
  }

  LifeEvent _weightedPick(List<LifeEvent> eligible, double total) {
    var roll = _random.nextDouble() * total;
    for (final event in eligible) {
      roll -= event.weight;
      if (roll <= 0) {
        return event;
      }
    }
    return eligible.last;
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
    _fame = (_fame + choice.fame).clamp(0, 100);
    final gained = choice.skill;
    if (gained != null && choice.skillGain != 0) {
      _skills[gained] = ((_skills[gained] ?? 0) + choice.skillGain).clamp(
        0,
        100,
      );
    }
    final revealed = choice.addTrait;
    if (revealed != null) {
      _traits.add(revealed);
    }
    final person = choice.addRelationship;
    if (person != null && !_relationships.contains(person)) {
      _relationships.add(person);
    }
    _setLog(choice.outcome);
    // The teaching moment: if this choice was about a money idea, name it
    // now — right after the consequence lands, while the player still has
    // the decision in mind.
    final lesson = choice.teaches;
    if (lesson != null) {
      _teach(lesson);
    }
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

  /// Practise a skill. This is the player-driven half of the career loop:
  /// skills gate which career events can fire at all, so a music contract
  /// only becomes reachable after actually putting the hours in.
  void practise(LifeSkill skill) {
    if (finished) return;
    final gain = 4 + (_smarts ~/ 25);
    _skills[skill] = ((_skills[skill] ?? 0) + gain).clamp(0, 100);
    _happiness = _clamp(_happiness - 2);
    if (!isDependent) {
      _money = max(0, _money - 20);
    }
    _setLog(
      'Practised ${skill.label.toLowerCase()}: +$gain ${skill.label} '
      '(now ${_skills[skill]}).',
    );
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

  // ---------------------------------------------------------------------
  // On-demand actions
  //
  // The sim used to be almost entirely reactive: age up, answer whatever
  // event fired. These are the things a player can choose to *do* on a
  // given turn, which is what makes the menus worth opening — the same
  // reason BitLife has Occupation/Relationships/Activities menus rather
  // than only a big "age" button.
  // ---------------------------------------------------------------------

  /// Put in extra effort at work. Costs happiness now for a shot at a
  /// raise — the trade being taught is that effort is spent, not free.
  void workHarder() {
    if (finished) return;
    if (!hasJob) {
      _setLog('You need a job first.');
      notifyListeners();
      return;
    }
    _happiness = _clamp(_happiness - 5);
    _health = _clamp(_health - 2);
    // Smarter characters convert effort into money more reliably.
    final succeeded = _random.nextInt(100) < 35 + (_smarts ~/ 4);
    if (succeeded) {
      final bump = 200 + _random.nextInt(400);
      _salary += bump;
      _setLog('Put in the extra hours — your salary went up by $bump.');
    } else {
      _setLog('Put in the extra hours. Nobody noticed. It happens.');
    }
    notifyListeners();
  }

  /// Ask outright. Higher chance than [workHarder] pays off, but a failed
  /// ask costs more happiness — asking has a real downside.
  void askForRaise() {
    if (finished) return;
    if (!hasJob) {
      _setLog('You need a job before you can ask for a raise.');
      notifyListeners();
      return;
    }
    final succeeded = _random.nextInt(100) < 30 + (_smarts ~/ 5);
    if (succeeded) {
      final bump = 400 + _random.nextInt(600);
      _salary += bump;
      _happiness = _clamp(_happiness + 6);
      _setLog('You asked, and got it: salary up $bump. Asking is free.');
    } else {
      _happiness = _clamp(_happiness - 8);
      _setLog('They said no. Worth asking — it only cost you a bad day.');
    }
    notifyListeners();
  }

  /// Walk away from a job. Salary goes to zero immediately.
  void quitJob() {
    if (finished || !hasJob) return;
    _job = 'Unemployed';
    _salary = 0;
    _happiness = _clamp(_happiness + 4);
    _setLog('You quit. Freedom now, no paycheck next year.');
    notifyListeners();
  }

  /// A check-up. Costs money, buys health back — the cheapest healthcare
  /// is the kind you get before you need it.
  void visitDoctor() {
    if (finished) return;
    const cost = 60;
    if (!isDependent && _money < cost) {
      _setLog('Not enough coins for a check-up.');
      notifyListeners();
      return;
    }
    if (!isDependent) {
      _money -= cost;
    }
    _health = _clamp(_health + 12);
    _setLog(
      isDependent
          ? 'A parent took you for a check-up: +12 Health.'
          : 'Check-up done: +12 Health, -$cost coins.',
    );
    notifyListeners();
  }

  /// Free smarts. Deliberately free — the library being the one action
  /// that costs nothing is itself a small lesson.
  void visitLibrary() {
    if (finished) return;
    _smarts = _clamp(_smarts + 4);
    _setLog('Spent an afternoon at the library: +4 Smarts. Cost: nothing.');
    notifyListeners();
  }

  /// Time with someone you know. Free, and the happiest thing in the game
  /// per coin spent — which is the point.
  void spendTimeWith(String person) {
    if (finished) return;
    _happiness = _clamp(_happiness + 8);
    _setLog('Spent the day with $person: +8 Happiness. Cost: nothing.');
    notifyListeners();
  }

  /// A gift. Costs real money and gives less happiness than [spendTimeWith]
  /// — an intentional comparison the player can notice on their own.
  void giveGift(String person) {
    if (finished) return;
    const cost = 50;
    if (_money < cost) {
      _setLog('Not enough coins for a gift.');
      notifyListeners();
      return;
    }
    _money -= cost;
    _happiness = _clamp(_happiness + 5);
    _setLog('Bought $person a gift: +5 Happiness, -$cost coins.');
    notifyListeners();
  }

  /// True once the character actually holds a paying job.
  bool get hasJob =>
      _salary > 0 && _job != 'Newborn' && _job != 'Unemployed';

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
