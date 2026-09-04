import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models_Like_Skins_and_lessons_templates/concept_powers.dart';
import '../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../models_Like_Skins_and_lessons_templates/relationship.dart';
import '../models_Like_Skins_and_lessons_templates/volunteer_places.dart';
import '../models_Like_Skins_and_lessons_templates/outing_rules.dart';
import '../models_Like_Skins_and_lessons_templates/ranked_run.dart';

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
    this.allowWagering = true,
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

  // ---- Powers -----------------------------------------------------------
  //
  // Money ideas, armed. See `concept_powers.dart` for why these exist at all;
  // the short version is that meeting sixteen ideas used to change nothing
  // about the simulation, which quietly contradicted every lesson in the app.
  final List<ActivePower> _powers = <ActivePower>[];

  /// How many can run at once. Two, so arming one is a choice about which --
  /// with room for all sixteen there is no decision, and a power that costs
  /// nothing to hold teaches nothing about opportunity cost.
  static const int maxActivePowers = 2;

  // ---- Hazards ----------------------------------------------------------
  //
  // Hunger is a counter, not a flag: one bad year is a bad year, four in a row
  // is what kills you. Tracking it as a number is what makes the difference
  // between "you were briefly broke" and "you have not eaten properly since
  // you were thirty" something the simulation can tell apart.
  int _hunger = 0;

  /// Years of illness left to run. Illness is a state you are *in*, not an
  /// event that happens once -- an illness that resolves the same turn it
  /// arrives is a bill with a costume on.
  int _illnessYears = 0;
  String _illnessName = '';

  /// The point at which not eating starts killing you.
  ///
  /// Four consecutive bad years, and any year you can feed yourself takes one
  /// back off. Nobody starves from a single unlucky turn.
  static const int starvationThreshold = 4;

  /// How much of the basics an out-of-work adult scrapes together, rolled
  /// fresh each year between these two.
  ///
  /// Not 100%: being out of work has to cost something or the job is
  /// pointless. Not 0% either, for the reason in [ageUp] -- a world with no
  /// floor under it killed 86% of runs before sixty.
  ///
  /// And *rolled*, not fixed. A flat 82% made hunger unreachable: the gap was
  /// the same every year, always under the quarter-of-a-year threshold, so
  /// the counter could never start. Some years you find work and some you do
  /// not, and it is the bad ones in a row that matter.
  static const double _scrapedMin = 0.62;
  static const double _scrapedMax = 0.98;

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

  /// Powers currently running.
  List<ActivePower> get activePowers => List.unmodifiable(_powers);

  /// Ideas met this run that are not already armed and could be.
  List<ConceptPower> get armablePowers => [
    for (final concept in _conceptsMet)
      if (powerFor(concept) case final power?)
        if (!_powers.any((active) => active.power.concept == concept)) power,
  ];

  bool get canArmPower => _powers.length < maxActivePowers;

  /// 0 = fed, [starvationThreshold] = starving.
  int get hunger => _hunger;
  bool get isStarving => _hunger >= starvationThreshold;
  bool get isIll => _illnessYears > 0;
  String get illnessName => _illnessName;

  /// The combined strength of every armed power with this effect.
  ///
  /// Summed rather than taking the best, so stacking two cost-cutters is
  /// worth doing -- but clamped, because a player who arms two big ones
  /// should not end up with free living.
  double powerStrength(PowerEffect effect) {
    var total = 0.0;
    for (final active in _powers) {
      if (active.effect == effect) total += active.magnitude;
    }
    return total > 0.8 ? 0.8 : total;
  }

  /// Arms the power for [concept], if it has been met and there is room.
  ///
  /// Returns false rather than throwing: the UI offers only valid choices,
  /// and a race between two taps should do nothing rather than crash a run.
  /// Test seam: meet a concept without having to engineer the event that
  /// teaches it. Mirrors `debugSet` on the cascade engine.
  @visibleForTesting
  void debugTeach(FinanceConcept concept) => _teach(concept);

  /// Adds somebody to this life, for tests.
  ///
  /// Events add people as a side effect of a choice, which makes reaching a
  /// specific relationship state from a test a matter of replaying a run until
  /// the right event happens to fire. This is the seam that avoids that, in
  /// the same spirit as [debugTeach].
  @visibleForTesting
  void debugAddPerson(
    String name, {
    RelationshipKind kind = RelationshipKind.friend,
    int? closeness,
  }) {
    if (_personNamed(name) != null) return;
    _people.add(
      Relationship(
        name: name,
        kind: kind,
        closeness: closeness ?? kStartingCloseness,
        metAtAge: _age,
        lastSeenAge: _age,
      ),
    );
  }

  /// Test seam: start partway into a hungry stretch.
  @visibleForTesting
  void debugSetHunger(int years) {
    _hunger = years;
    notifyListeners();
  }

  bool armPower(FinanceConcept concept) {
    if (finished || !canArmPower) return false;
    if (!_conceptsMet.contains(concept)) return false;
    if (_powers.any((active) => active.power.concept == concept)) return false;
    final power = powerFor(concept);
    if (power == null) return false;
    _powers.add(ActivePower(power: power, expiresAtAge: _age + power.years));
    _setLog(
      '${power.name} is active for ${power.years} years. ${power.blurb}',
      kind: LifeLogKind.learning,
    );
    notifyListeners();
    return true;
  }

  void _expirePowers() {
    final gone = _powers.where((a) => a.expiresAtAge <= _age).toList();
    if (gone.isEmpty) return;
    _powers.removeWhere((a) => a.expiresAtAge <= _age);
    for (final active in gone) {
      _setLog('${active.power.name} has run out.', kind: LifeLogKind.learning);
    }
  }

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
    // Worth Asking and Read The Slip both land here -- one because you found
    // out what the job pays, one because the slip was wrong. Same lever.
    final income = (_salary * (1 + powerStrength(PowerEffect.betterPay)))
        .round();
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
    // The numbers stay identical every year -- that is the point of a
    // routine -- but the sentence around them does not.
    //
    // Measured over forty runs, the default-split line alone accounted for
    // 15% of every line in the feed, word for word. A budget the player has
    // not set still needs nagging about once a year; it does not need nagging
    // about in exactly the same words forty times, which is how a routine
    // turns into wallpaper and stops being read at all.
    _setLog(
      _budgetSet
          ? '${_paycheckOpener(income)} Needs $needsBudget, wants '
                '$wantsBudget, savings $savingsBudget.'
          : '${_paycheckOpener(income)} Split on the default 50/30/20 — '
                'open Money to choose your own.',
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
      // Underfunding needs is not just a happiness hit any more. If there is
      // no cash left to make it up out of, that is a year you did not eat
      // properly, and hunger is what carries it forward.
      if (_money < 0) {
        _goHungry(shortfall: shortfall);
      }
    } else {
      _eatWell();
    }

    // Automatic: a slice off the top, before anything can be spent. The whole
    // point of pay-yourself-first is that it happens without a decision, so
    // it happens here rather than being offered as one.
    final autoRate = powerStrength(PowerEffect.autoSave);
    if (autoRate > 0) {
      final moved = (income * autoRate).round();
      if (moved > 0) {
        _emergencyFund += moved;
        _money -= moved;
        _setLog(
          'Automatic moved $moved into savings before you saw it.',
          kind: LifeLogKind.money,
        );
      }
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
      // so the cost of carrying it is felt, not hidden. Debt Brake and Good
      // Standing cut the rate rather than the balance -- understanding what
      // interest is does not make what you borrowed go away.
      final rate = 0.18 * (1 - powerStrength(PowerEffect.slowerDebt));
      final interest = (_debt * rate).round();
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
  void applyShock(int rawAmount, String reason) {
    // Cushion and The Other Thing come off the top, before the fund is
    // touched -- an idea you understood is cheaper than an idea you paid for.
    final softened = powerStrength(PowerEffect.softenShocks);
    final amount = (rawAmount * (1 - softened)).round();
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

  final List<Relationship> _people = <Relationship>[];

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

  /// Names only, for the epilogue and anything else that just wants a list.
  List<String> get relationships =>
      _people.where((p) => p.isPresent).map((p) => p.name).toList();

  /// The people themselves, closest first, including anyone drifted away —
  /// losing touch is a thing that happened in this life, and hiding the row
  /// would hide it.
  List<Relationship> get people {
    final sorted = [..._people]
      ..sort((a, b) => b.closeness.compareTo(a.closeness));
    return List.unmodifiable(sorted);
  }

  /// Average closeness across everybody still present, 0 when nobody is.
  ///
  /// This is what makes "Rich but Lonely" mean something. The ending used to
  /// fire on a happiness threshold alone, which made it reachable by
  /// overworking and gave it nothing to do with people.
  int get connection {
    final present = _people.where((p) => p.isPresent).toList();
    if (present.isEmpty) return 0;
    final total = present.fold<int>(0, (sum, p) => sum + p.closeness);
    return (total / present.length).round();
  }

  Relationship? _personNamed(String name) {
    for (final person in _people) {
      if (person.name == name) return person;
    }
    return null;
  }

  void _updatePerson(String name, Relationship updated) {
    final index = _people.indexWhere((p) => p.name == name);
    if (index >= 0) _people[index] = updated;
  }

  /// Which kind of relationship a newly-met name is.
  ///
  /// Guessed from the name itself, because events add people as bare strings
  /// and rewriting all 196 of them to carry a kind would be a large change
  /// for a small gain. "Grandma Lucille" is family; anybody else met before
  /// you can walk to school is family too; the rest are friends.
  RelationshipKind _kindFor(String name) {
    const familyWords = <String>[
      'mum',
      'mom',
      'dad',
      'gran',
      'grandma',
      'grandad',
      'grandpa',
      'nan',
      'aunt',
      'uncle',
      'sister',
      'brother',
      'cousin',
    ];
    final lower = name.toLowerCase();
    if (familyWords.any(lower.contains)) return RelationshipKind.family;
    if (_age <= 5) return RelationshipKind.family;
    return RelationshipKind.friend;
  }

  LifeEvent? get currentEvent => _currentEvent;
  String get log => _log;
  int get yearsLived => _age - startAge;

  /// Whether this run may offer staked wagers.
  ///
  /// Comes from the signed-in player's `AgeBand`, not from [age]. The
  /// in-game gates are all keyed on the character, which is right for the
  /// fiction and no protection at all: a four-year-old taps Age eighteen
  /// times and the gambling row unlocks. Defaults true so tests and the
  /// standalone town keep their existing behaviour; the real screen passes
  /// the account's answer.
  final bool allowWagering;

  LifeStage get stage => LifeStageInfo.forAge(_age);

  /// Everything you own minus everything you owe — the "earning vs keeping"
  /// distinction made literal. The emergency fund counts (it is yours);
  /// debt subtracts, so a high salary financed by borrowing does not read
  /// as wealth.
  int get netWorth => _money + _investments + _emergencyFund - _debt;

  /// Whether this run ever reached the starvation threshold.
  ///
  /// Kept separately from [hunger], which recovers. Ranked scoring needs to
  /// know that a run once got that close even if it climbed back out — a plan
  /// that nearly killed you is not a plan that worked.
  bool get everStarved => _everStarved;
  bool _everStarved = false;

  /// The finished run, as the ranked scorer takes it.
  RankedResult get rankedResult => RankedResult(
    netWorth: netWorth,
    ageReached: _age,
    conceptsMet: _conceptsMet.length,
    died: _dead,
    everStarved: _everStarved,
  );

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

    _expirePowers();

    if (!isDependent) {
      if (_salary > 0) {
        // Earning years run through the budget, so the split the player
        // chose is what actually governs the year.
        _applyBudget();
      } else {
        // Out of work, but not out of options. Odd jobs, family, whatever
        // support exists -- something covers most of the basics.
        //
        // Without this the first version of hunger killed 86% of runs before
        // sixty and dropped the average life to 35, because taking the first
        // option every year often means never getting a job, and every one of
        // those years was a starving year. That is not a simulation of being
        // poor, it is a simulation of having no world around you.
        final share =
            _scrapedMin + _random.nextDouble() * (_scrapedMax - _scrapedMin);
        final scraped = (_livingCost() * share).round();
        _money += scraped;
        _money -= _livingCost();
        if (_money < 0) {
          // Savings are what stands between a bad year and a hungry one --
          // which is the entire argument for having any.
          final fromFund = (-_money).clamp(0, _emergencyFund);
          _emergencyFund -= fromFund;
          _money += fromFund;
        }
        if (_money < 0) {
          _happiness = _clamp(_happiness - 8);
          final shortfall = -_money;
          _money = 0;
          _goHungry(shortfall: shortfall);
        } else {
          _eatWell();
        }
      }
      // Investments compound ~7% a year, plus whatever Snowball or Spread Out
      // are adding.
      final rate = 1.07 + powerStrength(PowerEffect.fasterGrowth);
      _investments = (_investments * rate).round();
    } else {
      // Somebody else is feeding you.
      _eatWell();
    }

    _applyIllness();
    if (_dead) {
      notifyListeners();
      return;
    }

    _applyAgeing();
    if (_dead) {
      notifyListeners();
      return;
    }

    _driftRelationships();
    _maybeFinancialShock();

    // Milestones give the feed texture on years with no event.
    final milestone = _milestoneFor(_age);
    _currentEvent = _drawEvent();

    // **No filler line when something actually happened this year.**
    //
    // This used to print `'Turned $_age.'` on every year that drew an event,
    // which is about three quarters of them — directly underneath a feed
    // header that already reads "Age 12". So the single most common line in
    // the whole log was a restatement of the line above it, and scrolling
    // back through a life looked repetitive even though the events in it were
    // not: measured across sixty runs, two lives share only 2-12% of their
    // events, and every one of them shared "Turned 12."
    //
    // A real milestone still prints — "You started school" is content. So
    // does a quiet year, which is the one case where the feed genuinely has
    // nothing else to say and [_quietYearLine] gives it something.
    final line = milestone ?? (_currentEvent == null ? _quietYearLine() : null);
    if (line != null) {
      _setLog(line, kind: LifeLogKind.milestone);
    } else {
      // The banner under the stats still needs a current line even when the
      // feed does not get one, or it would keep showing last year's.
      _log = 'Age $_age.';
    }
    notifyListeners();
  }

  /// How this year's pay gets announced.
  ///
  /// Rotated so the money line reads as a year passing rather than as the
  /// same notification printed on a loop. The figure is always in it, because
  /// the figure is the content.
  String _paycheckOpener(int income) {
    final lines = <String>[
      'Paycheck $income.',
      'Earned $income this year.',
      '$income came in over the year.',
      'A year of work: $income.',
      'Pay for the year, $income.',
    ];
    return lines[_random.nextInt(lines.length)];
  }

  /// A year passing on every relationship you did not maintain.
  ///
  /// **Why this exists.** Without it, people were a list of names that never
  /// changed, and the game had no way to make a run feel lonely — which left
  /// the "Rich but Lonely" ending firing on a happiness threshold and having
  /// nothing to do with anybody.
  ///
  /// Drift is deliberately slow: three points a year, scaled by how much
  /// maintaining that kind of relationship really takes. A run has to neglect
  /// somebody for most of a decade to lose them, which is about right — and
  /// a sixty-year life spent entirely on work can still end alone, which is
  /// the point.
  ///
  /// A visit does not freeze the year it happens in — `_age` has already
  /// advanced by the time this runs — it buys a *buffer*. Time together is
  /// worth +12 against a friend's 3-a-year drift, so seeing somebody roughly
  /// every four years holds the relationship steady. That rhythm is
  /// deliberate: with several people and sixty years to fill, demanding an
  /// action every single year for each of them would be book-keeping rather
  /// than a decision.
  void _driftRelationships() {
    if (_people.isEmpty) return;
    for (var i = 0; i < _people.length; i++) {
      final person = _people[i];
      if (person.lastSeenAge == _age) continue;
      final loss = (kBaseYearlyDrift * person.kind.driftRate).round();
      _people[i] = person.copyWith(
        closeness: (person.closeness - loss).clamp(0, 100),
      );
    }

    // Loneliness is felt, not just recorded. A small yearly cost once the
    // people around you have faded, so the stat and the story agree.
    final present = _people.where((p) => p.isPresent).length;
    if (present == 0 && _people.isNotEmpty) {
      _happiness = _clamp(_happiness - 2);
    }
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
    final base = switch (stage) {
      LifeStage.baby || LifeStage.child || LifeStage.teen => 0,
      LifeStage.youngAdult => 110,
      LifeStage.adult => 180,
      LifeStage.senior => 140,
    };
    // Clear Eyes, The Split, Second Thought and the rest all pull this lever.
    // Understanding what you actually need is, mechanically, a discount.
    return (base * (1 - powerStrength(PowerEffect.cheaperLiving))).round();
  }

  // ---- Hunger -----------------------------------------------------------
  //
  // The point of this is not to be cruel. It is that an emergency fund, a
  // budget and a job are all abstractions until the thing they are protecting
  // is something you can lose. A run where being broke costs you 8 happiness
  // and nothing else has no floor, and a simulation with no floor cannot
  // teach anybody why the floor matters.
  //
  // It is deliberately slow: four consecutive bad years before it is fatal,
  // and any year you can feed yourself resets it. Nobody starves by accident
  // in one unlucky turn.

  void _eatWell() {
    if (_hunger == 0) return;
    _hunger--;
    // Recovery has to be real, or hunger is a one-way ratchet: every bad year
    // costs health permanently and the good years in between buy nothing. A
    // simulation you cannot climb back out of does not teach that the way
    // out exists.
    _health = _clamp(_health + 4);
    if (_hunger == 0) {
      _setLog(
        'Eating properly again. That was closer than it looked.',
        kind: LifeLogKind.life,
      );
    }
  }

  /// A year that was short but not hungry.
  ///
  /// Six ways of saying it rather than one. This fired on 6% of all log lines
  /// with identical wording, and a line that common has to carry its weight —
  /// a player who reads "A tight year. You made it work." for the fifth time
  /// stops reading the feed, which is where every other lesson lives.
  String _tightYearLine() {
    const lines = <String>[
      'A tight year. You made it work.',
      'Money was short. Nothing broke.',
      'A lean year — you got to the end of it.',
      'Everything cost a little more than there was.',
      'You went without a few things and did not mention it.',
      'Close to the line all year, and never over it.',
    ];
    return lines[_random.nextInt(lines.length)];
  }

  void _goHungry({required int shortfall}) {
    // Being a little short is a tight year, not a hungry one. Only a gap big
    // enough to matter against what a year actually costs starts the counter.
    final threshold = (_livingCost() * 0.25).round();
    if (shortfall <= threshold) {
      _happiness = _clamp(_happiness - 3);
      _setLog(_tightYearLine(), kind: LifeLogKind.money);
      return;
    }

    // Walk Away stretches what little there is.
    final stretched =
        _random.nextDouble() < powerStrength(PowerEffect.stretchFood);
    if (stretched) {
      _setLog(
        'Money ran out, but you made it stretch.',
        kind: LifeLogKind.life,
      );
      return;
    }

    _hunger++;
    _health = _clamp(_health - (2 + _hunger));
    _happiness = _clamp(_happiness - 5);

    if (_hunger >= starvationThreshold) {
      _everStarved = true;
      _health = _clamp(_health - 7);
      _setLog(
        'A fourth year without enough to eat. Your health is going.',
        kind: LifeLogKind.shock,
      );
      _teach(FinanceConcept.emergencyFund);
      if (_health <= 4) {
        _dead = true;
        _currentEvent = null;
        _setLog(
          'You did not survive the winter. There was nothing left to sell '
          'and nothing coming in.',
          kind: LifeLogKind.milestone,
        );
      }
      return;
    }

    _setLog(
      'You could not cover the basics this year. Meals got smaller.',
      kind: LifeLogKind.shock,
    );
    _teach(FinanceConcept.emergencyFund);
  }

  // ---- Illness ----------------------------------------------------------
  //
  // A state you are in for a while, not a one-off bill. An illness that
  // resolves the turn it arrives is an expense shock wearing a costume, and
  // the app already has expense shocks.
  /// Deliberately cheap next to [_shocks].
  ///
  /// The app already has one system that empties your wallet at random, and
  /// two of them is not twice the lesson -- it is a game where saving cannot
  /// keep up. The first pass priced illness like a car repair and six years of
  /// disciplined 20% saving came out at a fund of zero, which is precisely the
  /// opposite of what the emergency fund is there to demonstrate.
  ///
  /// So the two hazards have different jobs: an expense shock takes your
  /// money, an illness takes your *health* and lingers for years. Where they
  /// overlap, illness is the smaller number.
  static const List<({String name, int minCost, int maxCost, int years})>
  _illnesses = [
    (name: 'a bad chest infection', minCost: 15, maxCost: 60, years: 1),
    (name: 'a broken ankle', minCost: 40, maxCost: 130, years: 1),
    (
      name: 'something that needed surgery',
      minCost: 90,
      maxCost: 240,
      years: 2,
    ),
    (name: 'a long illness', minCost: 45, maxCost: 160, years: 3),
    (name: 'burnout', minCost: 0, maxCost: 30, years: 2),
  ];

  void _applyIllness() {
    if (finished) return;

    if (_illnessYears > 0) {
      _illnessYears--;
      _health = _clamp(_health - 3);
      if (_illnessYears == 0) {
        _setLog('Over the worst of $_illnessName.', kind: LifeLogKind.life);
        _illnessName = '';
      }
      return;
    }

    // Odds climb with age and fall with health -- so the same run is riskier
    // at seventy than at twenty, and riskier still if you have been hungry.
    var chance = 2 + (_age ~/ 20) + ((100 - _health) ~/ 20) + _hunger * 2;
    if (chance > 22) chance = 22;
    if (_random.nextInt(100) >= chance) return;

    final illness = _illnesses[_random.nextInt(_illnesses.length)];
    final guard = powerStrength(PowerEffect.healthGuard);
    final rawCost =
        illness.minCost +
        _random.nextInt(illness.maxCost - illness.minCost + 1);
    final cost = (rawCost * (1 - guard)).round();

    _illnessYears = illness.years;
    _illnessName = illness.name;
    _health = _clamp(
      _health - ((10 + illness.years * 4) * (1 - guard)).round(),
    );

    // A dependent does not pay their own medical bills. The same rule that
    // makes childhood free of living costs has to cover this too, or the
    // simulation is charging an eight-year-old for a broken ankle -- which is
    // both wrong and the first thing `life_sim_test` noticed.
    if (cost > 0 && !isDependent) {
      applyShock(cost, 'Being treated for ${illness.name}');
    } else {
      _setLog(
        isDependent
            ? 'You came down with ${illness.name}. Your family sorted the '
                  'bill.'
            : 'You came down with ${illness.name}.',
        kind: LifeLogKind.shock,
      );
    }
    if (guard > 0) _teach(FinanceConcept.insurance);
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
      if (e.isWager && !allowWagering) return false;
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
          .where(
            (e) =>
                (!e.isWager || allowWagering) && e.matches(ctx) && e.repeatable,
          )
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
    if (person != null && _personNamed(person) == null) {
      _people.add(
        Relationship(
          name: person,
          kind: _kindFor(person),
          closeness: kStartingCloseness,
          metAtAge: _age,
          lastSeenAge: _age,
        ),
      );
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

  /// Why [action] is unavailable, or null when it is allowed.
  ///
  /// Returns copy aimed at the player rather than a boolean, because "You
  /// are too little for that" *is* the content at age three — being told what
  /// you cannot do yet is how the early years teach that a life has stages.
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
  /// **Two channels, and they are not the same.** [viaJobBoard] is the town's
  /// notice board: you walked there, the cards are pinned up, and somebody is
  /// standing behind the counter. Without it this is the version you do from
  /// the sofa — a search, a form, and a wait.
  ///
  /// Both are real ways people find work and the app should not pretend
  /// otherwise, so neither is blocked. But turning up in person is better,
  /// which is also true, and here it is worth one extra roll on the job
  /// market: the pick keeps the best of three instead of the best of two. On
  /// a table where Smarts widens what is open to you, that is a meaningful
  /// nudge without being a different mechanic.
  ///
  /// Returns false when the character cannot look for work right now.
  bool findJob({bool viaJobBoard = false}) {
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
    // rather than merely permitted: keep the best of several rolls. A third
    // roll for turning up in person -- see [viaJobBoard].
    var pick = 0;
    for (var i = 0; i < (viaJobBoard ? 3 : 2); i++) {
      final roll = _random.nextInt(open.length);
      if (roll > pick) pick = roll;
    }
    final job = open[pick];

    _job = job.title;
    _salary = job.salary;
    _happiness = _clamp(_happiness + 6);
    _setLog(
      viaJobBoard
          ? 'Saw the card on the board in town and asked. Hired as a '
                '${job.title} on ${job.salary} a year. Open Money to split '
                'that before it splits itself.'
          : 'Applied online and got it. Hired as a ${job.title} on '
                '${job.salary} a year. Open Money to split that before it '
                'splits itself.',
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
    bool hires = false,
  }) {
    if (finished) return;
    // The job board actually employing you is the point of it being a job
    // board. Silently ignored when the character is too young or already
    // working — `findJob` checks both and returns false, and the town's own
    // outcome text still lands, so nothing looks broken.
    if (hires) findJob(viaJobBoard: true);
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
  /// Give your time somewhere specific.
  ///
  /// [place] null keeps the old behaviour — the first option open at this
  /// age — so callers that have not been updated, and tests written against
  /// the single-button version, still work.
  ///
  /// **Why this stopped being one button.** It used to pay a flat +9
  /// Happiness and +2 Smarts for nothing, every time, forever: the most
  /// efficient action in the game, involving no decision at all, quietly
  /// teaching that good things are free. Now each place costs real hours and
  /// pays differently — see [VolunteerPlace] for what each one is arguing.
  void volunteer([VolunteerPlace? place]) {
    if (!allows(LifeAction.volunteer)) return;
    final open = volunteerPlacesFor(_age);
    if (open.isEmpty) return;
    final chosen = place != null && open.contains(place) ? place : open.first;

    _happiness = _clamp(_happiness + chosen.happiness);
    _smarts = _clamp(_smarts + chosen.smarts);
    _health = _clamp(_health + chosen.health);
    if (chosen.teaches != null) _teach(chosen.teaches!);
    _setLog(chosen.outcome, kind: LifeLogKind.life);
    notifyListeners();
  }

  /// A calculated risk with real downside. Gambling is in here precisely
  /// so it can lose — the log names the odds afterwards, which is the
  /// lesson.
  void takeARisk() {
    // Belt and braces with the menu, which hides the row entirely. A gate
    // that only exists in the widget is one refactor away from not existing.
    if (!allowWagering) return;
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
    final existing = _personNamed(person);
    _happiness = _clamp(_happiness + 8);
    if (existing != null) {
      // Time is the thing that actually repairs a relationship, and it moves
      // closeness more than twice as far as a gift does. That comparison is
      // the whole reason both actions are in the menu.
      _updatePerson(
        person,
        existing.copyWith(
          closeness: (existing.closeness + 12).clamp(0, 100),
          lastSeenAge: _age,
        ),
      );
    }
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
    final existing = _personNamed(person);
    if (existing != null) {
      _updatePerson(
        person,
        existing.copyWith(
          closeness: (existing.closeness + 5).clamp(0, 100),
          lastSeenAge: _age,
        ),
      );
    }
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
