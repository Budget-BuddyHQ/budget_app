import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../models_Like_Skins_and_lessons_templates/outing_rules.dart';

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
    // two traits rolled at birth. hidden modifier layer basically - they
    // gate which events can fire, so two runs with the same stats still
    // end up different
    final pool = List<LifeTrait>.from(LifeTrait.values)..shuffle(_random);
    _traits.addAll(pool.take(2));
    _strictness = HouseholdStrictness
        .values[_random.nextInt(HouseholdStrictness.values.length)];
    _setLog(
      'Born into a ${origin.label.toLowerCase()} family. '
      'Tap Age to live your first year.',
      kind: LifeLogKind.milestone,
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

  // ---- Going outside ---------------------------------------------------
  //
  // "Explore the town" used to be an always-on button — a newborn could
  // walk to the bank. These two fields are what make leaving the house a
  // *situation* instead of a menu item: one rolled once at birth, one
  // re-rolled every year. See `outing_rules.dart`.
  // assigned in the constructor body, NOT `late final` with a random
  // initializer!! a lazy random field eats its number the first time
  // something *reads* it, so the whole rng sequence (every later event draw,
  // every expense shock) would quietly depend on whether the UI happened to
  // check outingPermission that frame. took me ages to work out. same seed
  // same life every time is worth way more than the one saved line
  HouseholdStrictness _strictness = HouseholdStrictness.normal;
  HouseholdStrictness get strictness => _strictness;

  Weather _weather = Weather.clear;

  Weather get weather => _weather;

  /// Whether the character may leave the house right now, and why not.
  OutingPermission get outingPermission => OutingPermission.evaluate(
    age: _age,
    health: _health,
    strictness: strictness,
    weather: _weather,
  );

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
  bool setBudget({
    required int needs,
    required int wants,
    required int savings,
  }) {
    if (needs < 0 || wants < 0 || savings < 0) return false;
    if (needs + wants + savings != 100) return false;
    _needsPct = needs;
    _wantsPct = wants;
    _savingsPct = savings;
    _budgetSet = true;
    _teach(FinanceConcept.budgetRule);
    _setLog(
      'Budget set: $needs% needs, $wants% wants, $savings% savings.',
      kind: LifeLogKind.money,
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

    // paycheck line, every single year theres one.
    //
    // before this a year where the budget actually worked produced no money
    // line at all. the split ran silently and only ever spoke up to moan
    // about a shortfall or debt interest — so the one mechanic this whole
    // game exists to teach was invisible exactly on the years it went well.
    // feed was basically saying "budgeting only shows up when you mess it
    // up". naming the three numbers every year is what makes it a routine.
    _setLog(
      _budgetSet
          ? 'Paycheck $income. Needs $needsBudget, wants $wantsBudget, '
                'savings $savingsBudget.'
          : 'Paycheck $income, split on the default 50/30/20. '
                'Open Money to choose your own.',
      kind: LifeLogKind.money,
    );

    if (needsBudget < actualNeeds) {
      // needs arent optional, shortfall comes out of youp
      final shortfall = actualNeeds - needsBudget;
      _money -= shortfall;
      _health = _clamp(_health - 4);
      _happiness = _clamp(_happiness - 6);
      _setLog(
        'Your needs budget did not cover the essentials — you went short by '
        '$shortfall this year.',
        kind: LifeLogKind.shock,
      );
      _teach(FinanceConcept.needsVsWants);
    }

    if (_wantsPct <= 5) {
      // budget with no room to live in = one you abandon
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
        kind: LifeLogKind.money,
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
        kind: LifeLogKind.shock,
      );
      _teach(FinanceConcept.emergencyFund);
    } else {
      _setLog(
        '$reason cost $amount — covered from savings without borrowing.',
        kind: LifeLogKind.money,
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

  /// Categorises an event outcome by what it actually *did*, not by what it
  /// says. Money first, deliberately: if a choice moved coins or taught a
  /// money idea, that is the headline no matter what else it touched — the
  /// whole point of this game is that the money consequence is the one you
  /// notice.
  static LifeLogKind _kindOf(LifeChoice choice) {
    if (choice.teaches != null || choice.money != 0) return LifeLogKind.money;
    if (choice.setJob != null || choice.setSalary != null) {
      return LifeLogKind.career;
    }
    if (choice.addRelationship != null) return LifeLogKind.people;
    if (choice.skillGain > 0 || choice.smarts != 0) {
      return LifeLogKind.learning;
    }
    if (choice.health != 0) return LifeLogKind.health;
    return LifeLogKind.life;
  }

  void _setLog(String text, {LifeLogKind? kind}) {
    _log = text;
    history.add(LifeLogEntry(age: _age, text: text, kind: kind));
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
    flags: _flags,
  );

  /// What has happened to this character that a later event can be about.
  ///
  /// This is what lets the pool tell a story rather than deal a hand — see
  /// [LifeFlag]. Deliberately not persisted anywhere: a run is in-memory
  /// only, and a saved flag set without the saved narrative around it would
  /// be meaningless.
  final Set<LifeFlag> _flags = <LifeFlag>{};

  /// Read-only view, for the UI and for tests that assert a chain advanced.
  Set<LifeFlag> get flags => Set.unmodifiable(_flags);

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
    // re-rolled every year so whether the town is open changes as you go,
    // not fixed at birth
    _weather = WeatherInfo.roll(_random);

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
          (_currentEvent == null ? _quietYearLine() : 'Turned $_age.'),
      kind: LifeLogKind.milestone,
    );
    notifyListeners();
  }

  /// Filler for a year where nothing was drawn.
  ///
  /// About a quarter of years are deliberately quiet, so events feel like
  /// events. But every one of them used to print the identical sentence —
  /// "Turned 12. A quiet year." — which meant the *most common* line in the
  /// feed was also the only line that never varied. Scrolling back through
  /// a life, a run looked repetitive even when the events in it were not,
  /// because a quarter of it was one repeated string.
  ///
  /// These are age-banded rather than one shared list: "you learned to ride
  /// a bike" and "your knees have opinions about the weather" are both
  /// quiet years, and neither works at the other end of a life.
  String _quietYearLine() {
    final lines = switch (stage) {
      LifeStage.baby => const [
        'A year of naps, noise and being carried places.',
        'You learned to walk into furniture with real confidence.',
        'Mostly you shouted at a dog through a window.',
      ],
      LifeStage.child => const [
        'A quiet year of school, scraped knees and cartoons.',
        'You got very good at a game nobody else was playing.',
        'Nothing much happened, which at this age is a good year.',
        'You learned to ride a bike, badly, then well.',
      ],
      LifeStage.teen => const [
        'A quiet year. School, sleep, repeat.',
        'You spent most of it in your room and called it a phase.',
        'Nothing happened, and you were furious about it.',
        'A slow year of homework and borrowed money.',
      ],
      LifeStage.youngAdult => const [
        'A quiet year of work and rent.',
        'Nothing dramatic. The bills got paid, mostly on time.',
        'You said yes to less and slept more.',
        'A steady year — the kind that is only obvious later.',
      ],
      LifeStage.adult => const [
        'A steady year. Work, home, the usual.',
        'No surprises, which after last decade was welcome.',
        'A quiet year. You started cooking properly.',
        'Nothing happened worth writing down, and that was fine.',
      ],
      LifeStage.senior => const [
        'A slow, comfortable year.',
        'Your knees developed opinions about the weather.',
        'A quiet year of long walks and longer books.',
        'Not much happened. You had earned that.',
      ],
    };
    return lines[_random.nextInt(lines.length)];
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
          kind: LifeLogKind.milestone,
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

    final total = eligible.fold<double>(0, (sum, e) => sum + _drawWeight(e));
    final chosen = total <= 0
        ? eligible[_random.nextInt(eligible.length)]
        : _weightedPick(eligible, total);

    _seen.add(chosen.id);
    _lastFiredAge[chosen.id] = _age;
    return chosen;
  }

  /// How much a chain beat outweighs a standalone one once it is eligible.
  ///
  /// A chain is only worth having if it actually pays off. Left on its
  /// declared weight, the third beat of a four-step storyline has to win a
  /// weighted roll against 120-odd standalone events, three separate times,
  /// inside one life — which in practice means it never happens.
  /// `chain_index_payoff` was unreachable across 2,000 simulated lives
  /// before this existed, and it is the beat where twenty years of leaving
  /// an index fund alone finally shows the player what compounding did.
  ///
  /// So: once a thread is open, the game *wants* to close it. Applied in
  /// the draw rather than baked into each event's declared weight, so it
  /// stays one rule that every future chain inherits instead of a number
  /// to remember to tune.
  static const double _openChainBoost = 4.0;

  double _drawWeight(LifeEvent e) =>
      e.requiresFlag == null ? e.weight : e.weight * _openChainBoost;

  LifeEvent _weightedPick(List<LifeEvent> eligible, double total) {
    var roll = _random.nextDouble() * total;
    for (final event in eligible) {
      roll -= _drawWeight(event);
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
    // Cleared before set, so an ending that does both — pays off the card
    // *and* records that it was paid off — lands in the right order even if
    // the two flags are ever the same one.
    final cleared = choice.clearsFlag;
    if (cleared != null) {
      _flags.remove(cleared);
    }
    final raised = choice.setsFlag;
    if (raised != null) {
      _flags.add(raised);
    }
    _setLog(choice.outcome, kind: _kindOf(choice));
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

  // --- Age-gated activities ---
  //
  // These used to be labelled "always-available", and they were: a
  // three-year-old could hit the books, work out at the gym, take themselves
  // to the library and buy 100 coins of index funds. That is the single
  // biggest thing making the sim feel unreal — the menu offered a grown
  // adult's life to a toddler.
  //
  // The rules live here rather than in the menu because the menu is a
  // *view*: putting them there means the constraint is unenforced anywhere
  // else (an event, a future screen, a test) and cannot be unit-tested
  // without pumping a widget. [gateFor] is the one place that decides, and
  // the menu asks it what to grey out and why.

  /// Something the player can choose to do, and the age it becomes real.
  ///
  /// Ages are the ordinary ones a child actually reaches these at, which is
  /// what makes the early years feel like childhood instead of like an adult
  /// life with less money.
  static const Map<LifeAction, int> _minimumAge = <LifeAction, int>{
    LifeAction.study: 5, // school age
    LifeAction.library: 6,
    LifeAction.exercise: 12,
    LifeAction.goOut: 12, // out with friends, unsupervised
    LifeAction.buyGift: 6,
    LifeAction.volunteer: 10,
    LifeAction.sideJob: 14,
    LifeAction.findJob: jobHuntingAge, // 16
    LifeAction.invest: 16,
    LifeAction.gamble: 18,
    // A parent takes a small child to the doctor, so this one has no floor.
    LifeAction.doctor: 0,
    LifeAction.practise: 4,
    LifeAction.spendTime: 0,
  };

  /// Why [action] is unavailable, or null when it is allowed.
  ///
  /// Returns copy aimed at the player rather than a boolean, because "You
  /// are too little for that" *is* the content at age three — being told what
  /// you cannot do yet is how the early years teach that a life has stages.
  /// Actions the town has a building for.
  ///
  /// The library, the clinic and the park are places. So is a job board. The
  /// menu had a button for each of them, which meant the whole simulation
  /// could be played from a list without ever opening the map — and the map
  /// is where this game is supposed to happen.
  ///
  /// These are not removed, because the map is not always open to you: a
  /// seven-year-old, somebody ill, somebody whose family says no on a wet
  /// Tuesday. When you *can* go, the menu points at the door instead of
  /// duplicating what is behind it.
  /// Whether this is something the town has a building for.
  ///
  /// The library, the clinic, the park and the job board are all places, and
  /// the menu had a button for each — so the whole simulation could be played
  /// from a list without ever opening the map, which is where this game is
  /// meant to happen.
  ///
  /// **Blocking them was the wrong fix**, and the test suite said so within a
  /// minute: `life_age_gates_test` asserts that seeing a doctor is never
  /// blocked, `budget_teaching_test` asserts an adult with no job can always
  /// find one, and the library is the only way to raise Smarts on demand.
  /// Making somebody walk across a map to be treated, to look for work, or to
  /// get cleverer is a worse simulation, not a more realistic one — and the
  /// map is not always open to you anyway (see [outingPermission]).
  ///
  /// So the menu keeps every door and pays less for using them. Going in
  /// person is better; staying in is still allowed. That is also true.
  static bool hasTownEquivalent(LifeAction action) => const <LifeAction>{
    LifeAction.library,
    LifeAction.goOut,
    LifeAction.doctor,
    LifeAction.findJob,
  }.contains(action);

  String? gateFor(LifeAction action) {
    if (finished) return 'This life is over';
    final minAge = _minimumAge[action] ?? 0;
    if (_age < minAge) {
      return switch (action) {
        LifeAction.study => 'You are not old enough for school yet',
        LifeAction.library => 'You cannot read well enough yet',
        LifeAction.exercise => 'You are too little for the gym',
        LifeAction.goOut => 'Your family will not let you out alone yet',
        LifeAction.buyGift => 'You have no money of your own yet',
        LifeAction.volunteer => 'You are too young to volunteer',
        LifeAction.sideJob => 'You are too young to work',
        LifeAction.findJob => 'You are too young to work',
        LifeAction.invest => 'You need to be 16 to open an account',
        LifeAction.gamble => 'You have to be 18',
        LifeAction.practise => 'You are still a baby',
        _ => 'Not yet',
      };
    }
    return null;
  }

  bool allows(LifeAction action) => gateFor(action) == null;

  // --- Activities ---

  /// Study to raise Smarts.
  void study() {
    if (!allows(LifeAction.study)) return;
    _smarts = _clamp(_smarts + 6);
    _happiness = _clamp(_happiness - 2);
    if (!isDependent) {
      _money = max(0, _money - 30);
    }
    _setLog(
      isDependent
          ? 'Hit the books after school: +6 Smarts.'
          : 'Took a course: +6 Smarts, -30 coins.',
      kind: LifeLogKind.learning,
    );
    notifyListeners();
  }

  /// Spend time (and money, once independent) on fun.
  void haveFun() {
    if (!allows(LifeAction.goOut)) return;
    if (!isDependent && _money < 40) {
      _log = 'Not enough coins for a night out.';
      notifyListeners();
      return;
    }
    if (!isDependent) {
      _money -= 40;
    }
    // Six, not ten, for the same reason as the library: the park is a place
    // on the map, and an afternoon booked from a menu is the lesser version
    // of one you walked to.
    _happiness = _clamp(_happiness + 6);
    _setLog(
      'Had a good afternoon: +6 Happiness. The park in town is better, and '
      'free.',
      kind: LifeLogKind.life,
    );
    notifyListeners();
  }

  /// Practise a skill. This is the player-driven half of the career loop:
  /// skills gate which career events can fire at all, so a music contract
  /// only becomes reachable after actually putting the hours in.
  void practise(LifeSkill skill) {
    if (!allows(LifeAction.practise)) return;
    final gain = 4 + (_smarts ~/ 25);
    _skills[skill] = ((_skills[skill] ?? 0) + gain).clamp(0, 100);
    _happiness = _clamp(_happiness - 2);
    if (!isDependent) {
      _money = max(0, _money - 20);
    }
    _setLog(
      'Practised ${skill.label.toLowerCase()}: +$gain ${skill.label} '
      '(now ${_skills[skill]}).',
      kind: LifeLogKind.learning,
    );
    notifyListeners();
  }

  /// Work out — better health and looks, a little tiring.
  void exercise() {
    if (!allows(LifeAction.exercise)) return;
    _health = _clamp(_health + 8);
    _looks = _clamp(_looks + 3);
    _happiness = _clamp(_happiness - 1);
    _setLog('Worked out: +8 Health, +3 Looks.', kind: LifeLogKind.health);
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
      _setLog('You need a job first.', kind: LifeLogKind.career);
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
      _setLog(
        'Put in the extra hours — your salary went up by $bump.',
        kind: LifeLogKind.career,
      );
    } else {
      _setLog(
        'Put in the extra hours. Nobody noticed. It happens.',
        kind: LifeLogKind.career,
      );
    }
    notifyListeners();
  }

  /// Ask outright. Higher chance than [workHarder] pays off, but a failed
  /// ask costs more happiness — asking has a real downside.
  void askForRaise() {
    if (finished) return;
    if (!hasJob) {
      _setLog(
        'You need a job before you can ask for a raise.',
        kind: LifeLogKind.career,
      );
      notifyListeners();
      return;
    }
    final succeeded = _random.nextInt(100) < 30 + (_smarts ~/ 5);
    if (succeeded) {
      final bump = 400 + _random.nextInt(600);
      _salary += bump;
      _happiness = _clamp(_happiness + 6);
      _setLog(
        'You asked, and got it: salary up $bump. Asking is free.',
        kind: LifeLogKind.career,
      );
    } else {
      _happiness = _clamp(_happiness - 8);
      _setLog(
        'They said no. Worth asking — it only cost you a bad day.',
        kind: LifeLogKind.career,
      );
    }
    notifyListeners();
  }

  /// Entry-level jobs, cheapest first. Smarts decides how far up the list
  /// you can reach; the roll decides which of those you actually land.
  ///
  /// **These salaries are deliberately modest.** The economy this game runs
  /// on is small — the careers events hand out pay between 260 and 520 a
  /// year, and a year of essentials costs 110 to 180 — so a job market
  /// paying in the thousands would make every expense in the game
  /// irrelevant within a decade. A simulated run on the first draft of this
  /// table (900-3000) had banked a 6,378 emergency fund by thirty, which is
  /// a game with no tension and therefore no lesson.
  ///
  /// The ceiling here also sits at the *bottom* of what the career-ladder
  /// events pay, on purpose: walking into a job should always be worse than
  /// earning one through the music/sports/business ladders, or those
  /// ladders stop being worth climbing.
  static const List<({String title, int salary, int minSmarts})> _jobMarket = [
    (title: 'Supermarket Cashier', salary: 240, minSmarts: 0),
    (title: 'Warehouse Picker', salary: 260, minSmarts: 0),
    (title: 'Barista', salary: 275, minSmarts: 0),
    (title: 'Delivery Driver', salary: 310, minSmarts: 20),
    (title: 'Care Assistant', salary: 340, minSmarts: 30),
    (title: 'Office Administrator', salary: 380, minSmarts: 42),
    (title: 'Junior Technician', salary: 440, minSmarts: 56),
    (title: 'Trainee Accountant', salary: 500, minSmarts: 68),
    (title: 'Junior Developer', salary: 560, minSmarts: 80),
  ];

  /// The youngest age at which the job market will look at you.
  static const int jobHuntingAge = 16;

  /// Whether looking for work is currently possible at all.
  bool get canJobHunt => !finished && _age >= jobHuntingAge && !hasJob;

  /// Apply for work.
  ///
  /// **Why this exists.** Only eight of the ~130 events could hand out a
  /// job, each behind its own age/skill gate *and* behind the player
  /// picking that specific branch. Simulating lives showed most characters
  /// reaching forty still listed as "Newborn" on zero salary — which meant
  /// `canBudget` never became true, so the budget split, the emergency
  /// fund, the paycheck line and the debt model were all unreachable for
  /// the majority of players. The entire thing the app exists to teach was
  /// gated behind a lottery.
  ///
  /// So getting work is a *decision* now, not a draw. Smarts widens the
  /// list you can pick from, which is the one place in this game where
  /// studying visibly pays for itself.
  ///
  /// Returns false when the character cannot look for work right now.
  bool findJob() {
    if (!canJobHunt || !allows(LifeAction.findJob)) return false;

    final open = _jobMarket
        .where((j) => _smarts >= j.minSmarts)
        .toList(growable: false);
    // The floor entries have minSmarts 0, so this cannot be empty — but a
    // future edit to the table could make it so, and an empty pick would
    // throw in the player's face rather than just being a bad job market.
    if (open.isEmpty) {
      _setLog(
        'Nothing you are qualified for is going right now. Study and try '
        'again.',
        kind: LifeLogKind.career,
      );
      notifyListeners();
      return false;
    }

    // Bias toward the better end of what is open, so raising Smarts is felt
    // rather than merely permitted: two rolls, keep the higher.
    final first = _random.nextInt(open.length);
    final second = _random.nextInt(open.length);
    final job = open[first > second ? first : second];

    _job = job.title;
    _salary = job.salary;
    _happiness = _clamp(_happiness + 6);
    _setLog(
      'Hired as a ${job.title} on ${job.salary} a year. Open Money to split '
      'that before it splits itself.',
      kind: LifeLogKind.career,
    );
    _teach(FinanceConcept.budgetRule);
    notifyListeners();
    return true;
  }

  /// Walk away from a job. Salary goes to zero immediately.
  void quitJob() {
    if (finished || !hasJob) return;
    _job = 'Unemployed';
    _salary = 0;
    _happiness = _clamp(_happiness + 4);
    _setLog(
      'You quit. Freedom now, no paycheck next year.',
      kind: LifeLogKind.career,
    );
    notifyListeners();
  }

  /// A check-up. Costs money, buys health back — the cheapest healthcare
  /// is the kind you get before you need it.
  void visitDoctor() {
    if (!allows(LifeAction.doctor)) return;
    const cost = 60;
    if (!isDependent && _money < cost) {
      _setLog('Not enough coins for a check-up.', kind: LifeLogKind.money);
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
      kind: LifeLogKind.health,
    );
    notifyListeners();
  }

  /// Free smarts. Deliberately free — the library being the one action
  /// that costs nothing is itself a small lesson.
  void visitLibrary() {
    if (!allows(LifeAction.library)) return;
    // Two, not four. The library is a building in the town, and reading about
    // it from the menu is the version you do without leaving the house —
    // which is worth something and worth less. Walking there and picking the
    // free course pays the full amount through [applyTownOutcome].
    _smarts = _clamp(_smarts + 2);
    _setLog(
      'Read at home for the afternoon: +2 Smarts. The library in town is '
      'worth the walk.',
      kind: LifeLogKind.learning,
    );
    notifyListeners();
  }

  // --- More on-demand activities ---------------------------------------
  //
  // The Activities menu was five rows, three of them free stat bumps, and
  // it read as a stat vending machine rather than a life. These add the
  // three things a life sim actually needs from this menu: something that
  // *costs* time as well as money, something that can go wrong, and
  // something that only makes sense at a particular age.

  /// Applies a decision made out in the town to the life being lived.
  ///
  /// **Why this exists.** Walking into a building in the Adventure map and
  /// choosing something used to change the *account* — gold, XP, literacy
  /// points — and nothing about the character. So the one part of the app
  /// where you physically go somewhere to make a money decision had no
  /// bearing on the money simulation it was launched from, and the town read
  /// as a side attraction rather than as part of the life.
  ///
  /// The mapping is deliberately not one-to-one. Town gold is spending money,
  /// so it lands on cash. Literacy is what you understood, so it lands on
  /// smarts. XP is having done something at all, so it is a small lift in
  /// happiness — going out is good for you, and it is the smallest of the
  /// three because turning up is the easiest part.
  void applyTownOutcome({
    required int gold,
    required int xp,
    required int literacy,
  }) {
    if (finished) return;
    _money += gold;
    if (literacy > 0) _smarts = _clamp(_smarts + (literacy / 4).round());
    if (xp > 0) _happiness = _clamp(_happiness + (xp / 5).round());
    notifyListeners();
  }

  /// A side job. Real money for a real cost in time and energy — the only
  /// income source available before a career event fires.
  void workSideJob() {
    if (!allows(LifeAction.sideJob)) return;
    final earned = 40 + _random.nextInt(60);
    _money += earned;
    _happiness = _clamp(_happiness - 4);
    _health = _clamp(_health - 2);
    _setLog(
      'Picked up shifts and earned $earned coins. Tiring: -4 Happiness, '
      '-2 Health.',
      kind: LifeLogKind.money,
    );
    _teach(FinanceConcept.incomeVsWealth);
    notifyListeners();
  }

  /// Volunteering. No money at all, and deliberately the best happiness
  /// per coin in the game — the counterweight to a menu where every other
  /// good outcome has a price tag.
  void volunteer() {
    if (!allows(LifeAction.volunteer)) return;
    _happiness = _clamp(_happiness + 9);
    _smarts = _clamp(_smarts + 2);
    _setLog(
      'Volunteered locally: +9 Happiness, +2 Smarts. Cost: nothing.',
      kind: LifeLogKind.life,
    );
    notifyListeners();
  }

  /// A calculated risk with real downside. Gambling is in here precisely
  /// so it can lose — the log names the odds afterwards, which is the
  /// lesson.
  void takeARisk() {
    if (!allows(LifeAction.gamble)) return;
    const stake = 100;
    if (_money < stake) return;
    // Deliberately worse than even money, like every real version of this.
    final won = _random.nextInt(100) < 42;
    if (won) {
      _money += stake;
      _happiness = _clamp(_happiness + 6);
      _setLog(
        'You gambled $stake coins and won $stake. It will not always go '
        'this way — the odds were against you.',
        kind: LifeLogKind.money,
      );
    } else {
      _money -= stake;
      _happiness = _clamp(_happiness - 7);
      _setLog(
        'You gambled $stake coins and lost the lot. The odds were always '
        'against you.',
        kind: LifeLogKind.shock,
      );
    }
    _teach(FinanceConcept.opportunityCost);
    notifyListeners();
  }

  /// Time with someone you know. Free, and the happiest thing in the game
  /// per coin spent — which is the point.
  void spendTimeWith(String person) {
    if (finished) return;
    _happiness = _clamp(_happiness + 8);
    _setLog(
      'Spent the day with $person: +8 Happiness. Cost: nothing.',
      kind: LifeLogKind.people,
    );
    notifyListeners();
  }

  /// A gift. Costs real money and gives less happiness than [spendTimeWith]
  /// — an intentional comparison the player can notice on their own.
  void giveGift(String person) {
    if (!allows(LifeAction.buyGift)) return;
    const cost = 50;
    if (_money < cost) {
      _setLog('Not enough coins for a gift.', kind: LifeLogKind.money);
      notifyListeners();
      return;
    }
    _money -= cost;
    _happiness = _clamp(_happiness + 5);
    _setLog(
      'Bought $person a gift: +5 Happiness, -$cost coins.',
      kind: LifeLogKind.people,
    );
    notifyListeners();
  }

  /// True once the character actually holds a paying job.
  bool get hasJob => _salary > 0 && _job != 'Newborn' && _job != 'Unemployed';

  /// Move cash into investments, which compound each year.
  void invest(int amount) {
    if (!allows(LifeAction.invest) || amount <= 0 || _money < amount) {
      return;
    }
    _money -= amount;
    _investments += amount;
    _smarts = _clamp(_smarts + 2);
    _setLog(
      'Invested $amount coins. It compounds every year.',
      kind: LifeLogKind.money,
    );
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
