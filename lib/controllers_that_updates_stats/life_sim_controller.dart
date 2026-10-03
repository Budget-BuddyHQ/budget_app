import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;

import '../models_Like_Skins_and_lessons_templates/concept_powers.dart';
import '../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../models_Like_Skins_and_lessons_templates/life_activities.dart';
import '../models_Like_Skins_and_lessons_templates/life_assets.dart';
import '../models_Like_Skins_and_lessons_templates/life_careers.dart';
import '../models_Like_Skins_and_lessons_templates/life_education.dart';
import '../models_Like_Skins_and_lessons_templates/life_people.dart';
import '../models_Like_Skins_and_lessons_templates/life_effort.dart';
import '../models_Like_Skins_and_lessons_templates/life_network.dart';
import '../models_Like_Skins_and_lessons_templates/life_events_shocks.dart';
import '../models_Like_Skins_and_lessons_templates/life_run_record.dart';
import '../models_Like_Skins_and_lessons_templates/life_town_income.dart';
import '../models_Like_Skins_and_lessons_templates/life_wellbeing.dart';
import '../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../models_Like_Skins_and_lessons_templates/relationship.dart';
import '../models_Like_Skins_and_lessons_templates/volunteer_places.dart';
import '../models_Like_Skins_and_lessons_templates/outing_rules.dart';
import '../models_Like_Skins_and_lessons_templates/ranked_run.dart';
import '../models_Like_Skins_and_lessons_templates/reading_grade.dart';

// The controller is one class, and it grew past what one file can be read as.
// These parts are extensions on it, so they share its private state and none of
// them is a second controller. Each is one part of a life: school, work,
// property, people, and the things you choose to do with a year.
part 'life_sim_school.dart';
part 'life_sim_work.dart';
part 'life_sim_assets.dart';
part 'life_sim_people.dart';
part 'life_sim_activities.dart';
part 'life_sim_money_flow.dart';

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
    bool allowWagering = true,
    this.plainWordsOnly = false,
    bool hideGamblingMechanics = false,
    // Start with a family already around you. Off by default so a test that
    // wants an empty list of people gets one; the real game turns it on.
    bool withFamily = false,
  }) : _allowWagering = allowWagering,
       _hideGamblingMechanics = hideGamblingMechanics,
       _random = random ?? Random(),
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
    _startEducation();
    if (withFamily) _seedFamily();
    _recordYear();
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
  // actually practiced budgeting — the core skill it claims to teach. This
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

  /// Test seam: put the character in a known state without playing there.
  ///
  /// **Why this exists.** Several tests reached a high Smarts or a low Health by
  /// tapping an action forty times in one year. That was reaching the state by
  /// the exact exploit `EffortRules` closes, so once the action fades, the test
  /// has to say what it means, which is "a character with 95 Smarts", instead
  /// of grinding for it.
  @visibleForTesting
  void debugSetStats({
    int? smarts,
    int? health,
    int? happiness,
    int? looks,
    int? money,
    int? salary,
    String? job,
  }) {
    if (smarts != null) _smarts = _clamp(smarts);
    if (health != null) _health = _clamp(health);
    if (happiness != null) _happiness = _clamp(happiness);
    if (looks != null) _looks = _clamp(looks);
    if (money != null) _money = money;
    if (salary != null) _salary = salary;
    if (job != null) _job = job;
    notifyListeners();
  }

  /// Test seam: put a specific event in front of the player.
  @visibleForTesting
  void debugSetEvent(LifeEvent event) {
    _currentEvent = event;
  }

  /// Test seam: drop whatever event the year drew without applying it.
  ///
  /// A test about money needs the only money to be the money it is about, and
  /// an event's first option can cost anything. Now that a cost is borrowed
  /// rather than erased, one stray event moves the debt.
  @visibleForTesting
  void debugClearEvent() {
    _currentEvent = null;
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
    final gross =
        (_salary * (1 + powerStrength(PowerEffect.betterPay)) * _payShare)
            .round();
    if (gross <= 0) {
      _settleLoans(0);
      return;
    }
    _incomeTotal += gross;
    // Loan payments come out of the pay before it is split, which is how a
    // mortgage or a student loan behaves. What is left is what the 50/30/20
    // divides.
    final income = gross - _settleLoans(gross);

    final needsBudget = (income * _needsPct / 100).round();
    final wantsBudget = (income * _wantsPct / 100).round();
    final savingsBudget = (income * _savingsPct / 100).round();
    final actualNeeds = _livingCost();
    final spareNeeds = needsBudget > actualNeeds
        ? needsBudget - actualNeeds
        : 0;

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
                '${spareNeeds > 0 ? ' Living cost $actualNeeds, so $spareNeeds stayed yours.' : ''}'
          : '${_paycheckOpener(income)} Split on the default 50/30/20 — '
                'open Money to choose your own.'
                '${spareNeeds > 0 ? ' Living cost $actualNeeds, so $spareNeeds stayed yours.' : ''}',
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
      // The part of the needs slice that living did not cost is still yours.
      //
      // It used to be deducted and never returned: on a 1,552 salary the 50%
      // needs slice was 776 against a real cost of 180, so about 600 a year
      // simply disappeared. Nothing in a paycheck ever reached spendable cash,
      // which is why a player could watch 4,000 in coins run down to 0 and be
      // unable to get it back up while earning more every year.
      if (spareNeeds > 0) _money += spareNeeds;
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
        _savedTotal += moved;
        _money -= moved;
        _setLog(
          'Automatic moved $moved into savings before you saw it.',
          kind: LifeLogKind.money,
        );
      }
    }

    // Wants buy happiness. They did not, and that was a real bug.
    //
    // `wantsBudget` was subtracted from cash and produced **nothing** —
    // no happiness, no stat, no line. The only other thing `_wantsPct` did
    // was *penalise* a player who set it at or below 5%. So there was no
    // winning move: spend 30% of every paycheck and watch it vanish for no
    // return, or spend nothing and be docked happiness for it.
    //
    // That is also why a tester asked "what is the 50/30/20 thing?" — the
    // wants third of it did not do anything, so there was nothing to learn
    // from it. A budget only teaches if each category visibly buys what it
    // is for: needs keep you well, savings build the fund, wants make the
    // life worth living.
    //
    // Scaled against 30 rather than flat, so choosing your own split is a
    // real trade rather than a cosmetic one — and capped, because you cannot
    // buy your way to a happy life at 90% wants and no savings.
    if (wantsBudget > 0) {
      final wantsShare = _wantsPct / 30.0;
      final joy = (3 * wantsShare).round().clamp(0, 6);
      if (joy > 0) _happiness = _clamp(_happiness + joy);
    }

    if (_wantsPct <= 5) {
      // budget with no room to live in = one you abandon
      _happiness = _clamp(_happiness - 4);
    }

    // Save only what there is left to save.
    //
    // This used to move the full `savingsBudget` and then clamp a negative
    // balance back to zero — which **destroys money**. A player who was
    // short that year had the shortfall silently deleted from their cash
    // instead of it becoming something they owed, so the ledger simply
    // stopped adding up. Reported as "he doesn't get all the money he gets
    // from the jobs he does", which is exactly what it looks like from
    // outside: numbers that do not reconcile.
    //
    // You cannot put aside money you do not have. Whatever is actually
    // there goes to savings; anything beyond it becomes debt, which the
    // game already models and already charges interest on.
    // The lender is paid before the fund is.
    //
    // Interest on what was already owed coming into the year comes out of
    // the pooled cash first, so the savings slice reaches the fund only
    // after it. This used to be the other way round: the 20% slice went into
    // an emergency fund earning nothing while the debt beside it compounded
    // at 18% with no way to pay it. A single 265 borrowed at 22 on a 380
    // salary became 1.3 million by seventy in about one life in ten, in a
    // 300-life simulation, even for a bot that budgeted and looked after
    // itself. That is the lesson turned into a caricature, and it left a
    // player with no move at all. What the lender takes now is interest
    // only, so the balance stops growing but does not shrink until the
    // player pays it down on purpose. Interest the pay cannot cover is
    // added to the balance, which is how a small income with a big debt
    // still gets worse.
    final owedComingIn = _debt;
    final debtRate = 0.18 * (1 - powerStrength(PowerEffect.slowerDebt));
    var paidLender = 0;
    if (owedComingIn > 0 && _money > 0) {
      final due = (owedComingIn * debtRate).round();
      paidLender = due.clamp(0, _money);
      _money -= paidLender;
    }

    final canSave = savingsBudget.clamp(0, _money < 0 ? 0 : _money);
    if (canSave > 0) {
      _emergencyFund += canSave;
      _savedTotal += canSave;
      _money -= canSave;
    }
    if (_money < 0) {
      // Owed, not vanished.
      _debt += -_money;
      _money = 0;
      _setLog(
        'You came up short this year, so ${_debt}g is now owed rather than '
        'quietly disappearing.',
        kind: LifeLogKind.shock,
      );
    }

    if (_debt > 0) {
      // 18% a year, roughly a credit card. Deliberately visible in the feed
      // so the cost of carrying it is felt, not hidden. Debt Brake and Good
      // Standing cut the rate rather than the balance -- understanding what
      // interest is does not make what you borrowed go away.
      final interest = (_debt * debtRate).round();
      // Whatever the lender already took out of this year's pay is not
      // added to what is owed.
      final unpaid = interest - paidLender;
      // Past ten years of pay the balance stops growing. A debt that size is
      // never coming out of that income, and letting it compound regardless
      // produced endings like owing 1,300,000 on a 380 salary, which is
      // arithmetic and not a lesson. Below the line it compounds exactly as
      // it always did, which is the part that teaches.
      final room = (_salary * 10 - _debt).clamp(0, unpaid);
      final capped = room < unpaid;
      final charged = paidLender + room;
      _interestPaid += charged;
      _debt += room;
      final payment = (_money * 0.3).round();
      final paid = payment.clamp(0, _debt);
      _money -= paid;
      _debt -= paid;
      _setLog(
        'Debt cost you $charged in interest this year'
        '${paidLender > 0 ? ', $paidLender of it taken from your pay' : ''}. '
        '${capped ? 'The balance has stopped growing because you already owe ten years of pay. ' : ''}'
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

    // Remembered, because how a shock was paid for is the whole point of an
    // emergency fund and the debrief should be able to say so.
    _shocksHit++;
    final covered = remaining <= 0;
    if (covered) _shocksCovered++;
    _moments.add(
      LifeMoment(
        age: _age,
        kind: LifeMomentKind.shock,
        title: reason,
        chose: covered ? 'Paid from savings' : 'Borrowed to pay',
        moneyDelta: -amount,
        covered: covered,
        concept: FinanceConcept.emergencyFund,
      ),
    );

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
    flags: _effectiveFlags(),
    education: _edu.level,
    inSchool: _edu.inSchool,
    owns: {for (final a in _assets) a.def.kind},
    hasPartner: _people.any(
      (p) =>
          p.isAlive &&
          (p.kind == RelationshipKind.partner ||
              p.kind == RelationshipKind.spouse),
    ),
    hasChild: _people.any((p) => p.kind == RelationshipKind.child && p.isAlive),
    hasLivingParent: _people.any(
      (p) => p.isAlive && (p.role == 'Mother' || p.role == 'Father'),
    ),
    debt: _debt + loanBalance,
    renting:
        _rentalId != 'family' &&
        !_assets.any((a) => a.def.kind == AssetKind.home),
    track: currentJob?.track,
    salary: _salary,
  );

  /// What has happened to this character that a later event can be about.
  ///
  /// This is what lets the pool tell a story rather than deal a hand — see
  /// [LifeFlag]. Deliberately not persisted anywhere: a run is in-memory
  /// only, and a saved flag set without the saved narrative around it would
  /// be meaningless.
  final Set<LifeFlag> _flags = <LifeFlag>{};

  // ---- School, work, property and people ------------------------------------
  //
  // The state for the parts in `life_sim_school.dart` and its siblings. It lives
  // here because a class cannot spread its fields across files, and because the
  // controller is the one thing that survives from one year to the next.

  final EducationState _edu = EducationState();

  /// The catalogue job held, when it came from the board or a promotion. Null
  /// for a job an event handed out, which has no ladder.
  String? _jobId;

  /// How well the job is going, 0 to 100. The bar on the Occupation screen.
  int _performance = 60;
  int _yearsInRole = 0;
  int _lowPerformanceYears = 0;

  /// Years worked in each line of work, which is what makes a higher rung
  /// appear on the board.
  final Map<CareerTrack, int> _experience = <CareerTrack, int>{};

  final List<Loan> _loans = <Loan>[];
  final List<OwnedAsset> _assets = <OwnedAsset>[];
  int _nextUid = 1;

  /// Where the character lives if they do not own the place. See `kRentals`.
  String _rentalId = 'family';
  bool _hasLicense = false;

  /// Uses so far this year of each catalogue activity, by id.
  final Map<String, int> _activityUses = <String, int>{};

  /// Times each person has been dealt with this year, so one friend cannot be
  /// farmed.
  final Map<String, int> _touchesThisYear = <String, int>{};

  /// Something for the screen to open after a decision card. See
  /// [LifeFollowUp].
  LifeFollowUp _pendingFollowUp = LifeFollowUp.none;

  /// Decision cards the controller made itself: a graduation, a move, a loss.
  /// Waiting to be put in front of the player, oldest first.
  final List<LifeEvent> _queuedEvents = <LifeEvent>[];

  // Sport, and the tallies the debrief reads.
  LifeSport? _sport;
  int _sportStanding = 0;
  int _seasons = 0;
  int _promotions = 0;
  int _degreesEarned = 0;
  int _studentBorrowed = 0;
  int _assetsBought = 0;
  int? _lastChildAge;

  /// What the screen should open now that a decision card has landed, then
  /// forgets it. Called once after each choice.
  LifeFollowUp takeFollowUp() {
    final next = _pendingFollowUp;
    _pendingFollowUp = LifeFollowUp.none;
    return next;
  }

  /// Notifies listeners. The part files are extensions, and `notifyListeners`
  /// is protected, so they go through this.
  void _changed() => notifyListeners();

  /// Read-only view, for the UI and for tests that assert a chain advanced.
  Set<LifeFlag> get flags => Set.unmodifiable(_effectiveFlags());

  /// The story flags, with the ones that stand for something the character
  /// *owns* read from what they own.
  ///
  /// **Reported as:** saying yes to a friend who wanted to share a flat, and then
  /// seeing on the Assets tab that the character still lived with their parents.
  /// The card set a flag and the screen read a different record. A 400-life audit
  /// found the same split for a dog, a car, a home and a student loan: hundreds of
  /// lives told a story about owning something that the Assets tab denied.
  ///
  /// So `hasPet` is "owns a dog", `hasCar` is "owns a car", `ownsHome` is "owns a
  /// home", `hasStudentLoan` is "owes one", and `rentsWithFriend` only lasts while
  /// the character still lives in the shared house. Cards that used to set these
  /// now change what is owned instead (see [LifeChoice.grantsAsset]), and a dog
  /// bought in the shop starts the same story as one adopted on a card.
  Set<LifeFlag> _effectiveFlags() {
    final f = <LifeFlag>{..._flags};
    void backed(LifeFlag flag, bool real) {
      if (real) {
        f.add(flag);
      } else {
        f.remove(flag);
      }
    }

    backed(LifeFlag.hasPet, _assets.any((a) => a.def.id == 'pet_dog'));
    backed(
      LifeFlag.hasCar,
      _assets.any(
        (a) => a.def.kind == AssetKind.vehicle && a.def.id != 'veh_bike',
      ),
    );
    backed(LifeFlag.ownsHome, ownsHome);
    backed(
      LifeFlag.hasStudentLoan,
      _loans.any((l) => l.kind == LoanKind.student && l.balance > 0),
    );
    backed(LifeFlag.gotDegree, _edu.level.atLeast(EducationLevel.bachelor));
    if (_rentalId != 'shared' || ownsHome) f.remove(LifeFlag.rentsWithFriend);
    return f;
  }

  /// True when the run is over for any reason — retired or died.
  bool get finished => _retired || _dead;

  /// Names only, for the epilogue and anything else that just wants a list.
  List<String> get relationships => _people
      .where((p) => p.isPresent && !p.kind.isProfessional)
      .map((p) => p.name)
      .toList();

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
    // Professional contacts are left out. A long list of people who know your
    // name is not the same as somebody who would turn up, and this number is
    // what the loneliness endings read.
    final present = _people
        .where((p) => p.isPresent && !p.kind.isProfessional)
        .toList();
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
  /// standalone town keep their existing behavior; the real screen passes
  /// the account's answer.
  bool get allowWagering => _allowWagering && kLifeGamblingEnabled;
  final bool _allowWagering;

  /// Whether this player needs grown-up financial vocabulary kept back.
  ///
  /// **The bug this closes.** Life events gate on `minAge`, which is the
  /// *character's* age — so a ten-year-old whose character reached thirty was
  /// being offered mortgages, down payments and vesting schedules. Reported
  /// exactly that way: *"my little brother is getting confused by the options
  /// in the main game as a 10 year old since we are talking about loans and
  /// down payments and he doesn't know what that is."*
  ///
  /// This is the same character-age-versus-account-age mistake the wagering
  /// gate was built to fix, arriving again through a different door. The
  /// character's age decides what is *plausible*; the player's age decides
  /// what is *readable*, and only one of those was being checked.
  ///
  /// Set from `AgeBand.prefersSimpleWording`, so it follows the account
  /// rather than the story.
  final bool plainWordsOnly;

  /// Whether loot boxes and skin-trading sites are kept off screen entirely.
  ///
  /// Set from `AgeBand.hidesGamblingMechanics`, so it follows the account and
  /// not the character's age. See [LifeEvent.showsGamblingMechanic].
  bool get hideGamblingMechanics =>
      _hideGamblingMechanics || !kLifeGamblingEnabled;
  final bool _hideGamblingMechanics;

  LifeStage get stage => LifeStageInfo.forAge(_age);

  /// Everything you own minus everything you owe — the "earning vs keeping"
  /// distinction made literal. The emergency fund counts (it is yours);
  /// debt subtracts, so a high salary financed by borrowing does not read
  /// as wealth.
  int get netWorth =>
      _money +
      _investments +
      _emergencyFund +
      assetsValue -
      _debt -
      loanBalance;

  /// Whether this run ever reached the starvation threshold.
  ///
  /// Kept separately from [hunger], which recovers. Ranked scoring needs to
  /// know that a run once got that close even if it climbed back out — a plan
  /// that nearly killed you is not a plan that worked.
  bool get everStarved => _everStarved;
  bool _everStarved = false;

  // --- Work, people and the town -----------------------------------------
  //
  // Three systems added together: neglect costs shifts (life_wellbeing),
  // people are a network that passes on leads (life_network), and the map is
  // a small income (life_town_income). Their state lives here because the
  // controller is the one thing that survives from year to year.

  /// Consecutive years that missed enough work to count. See
  /// [kYearsToLoseJob].
  int _strainYears = 0;

  /// The share of this year's pay still earned. 1.0 unless work was missed.
  double _payShare = 1.0;

  int _weeksMissedTotal = 0;
  int _yearsStrained = 0;
  int _timesLaidOff = 0;
  int _raisesEarned = 0;
  int _referrals = 0;
  int _contactsMade = 0;

  /// Townspeople already spoken to this year, so a chat warms a contact once a
  /// year and not once a tap.
  final Set<String> _townChatsThisYear = <String>{};

  /// Map coins picked up this year. Restocked every [ageUp].
  final Set<String> _townCoinsThisYear = <String>{};
  int _townEarnedThisYear = 0;
  int _townEarnedTotal = 0;

  /// How the character is holding up at work, from health and happiness.
  WorkStrain get workStrain =>
      assessWorkStrain(health: _health, happiness: _happiness);

  /// Whether another year like the last one loses the job.
  bool get jobAtRisk =>
      hasJob &&
      _strainYears >= 1 &&
      workStrain.missedShare >= kSeriousMissedShare;

  /// The line to show above the stats, or null. Only for a working adult: a
  /// child's low health is a school matter and is handled quietly.
  String? get strainNotice {
    if (isDependent || !hasJob || finished) return null;
    return strainWarning(workStrain, jobAtRisk: jobAtRisk);
  }

  /// Who you know and how warm it is. See `life_network.dart`.
  NetworkReading get networkReading => readNetwork(_people);

  /// Professional contacts, closest first.
  List<Relationship> get contacts => [
    for (final person in people)
      if (person.kind.isProfessional && person.isPresent) person,
  ];

  int get weeksMissedTotal => _weeksMissedTotal;
  int get yearsStrained => _yearsStrained;
  int get timesLaidOff => _timesLaidOff;
  int get raisesEarned => _raisesEarned;
  int get referrals => _referrals;
  int get contactsMade => _contactsMade;

  /// Life money the map paid this year, after the yearly allowance.
  int get townEarnedThisYear => _townEarnedThisYear;
  int get townEarnedTotal => _townEarnedTotal;

  /// Whether this year's town allowance is used up, for the map to say so.
  bool get townAllowanceSpent => TownIncome.isSpent(_townEarnedThisYear);

  /// Whether this coin has already been picked up this year.
  bool townCoinTaken(String id) => _townCoinsThisYear.contains(id);

  // --- What this life remembers about itself ------------------------------
  //
  // The controller used to hold only the present and throw the past away every
  // year, which is why the end of a run could say what a life *was* and never
  // what the player *did*. See life_run_record.dart.

  /// One point a year, keyed by age so a second write in the same year (a
  /// choice made after ageing up) replaces the first instead of adding a twin.
  final Map<int, LifeYearPoint> _curve = <int, LifeYearPoint>{};

  /// Decisions and shocks that moved real money.
  final List<LifeMoment> _moments = <LifeMoment>[];

  int _adultYears = 0;
  int _workYears = 0;
  int _yearsUnemployed = 0;
  int _studentYears = 0;
  int _incomeTotal = 0;
  int _savedTotal = 0;
  int _interestPaid = 0;
  int _debtRepaid = 0;
  int _shocksHit = 0;
  int _shocksCovered = 0;
  int _sideJobs = 0;
  int? _firstJobAge;

  void _recordYear() {
    _curve[_age] = LifeYearPoint(
      age: _age,
      netWorth: netWorth,
      happiness: _happiness,
      health: _health,
    );
  }

  /// The life's money, one point a year, oldest first.
  List<LifeYearPoint> get yearCurve {
    final points = _curve.values.toList()
      ..sort((a, b) => a.age.compareTo(b.age));
    return List<LifeYearPoint>.unmodifiable(points);
  }

  /// Everything that moved real money, in the order it happened.
  List<LifeMoment> get moments => List<LifeMoment>.unmodifiable(_moments);

  /// The running totals, with the peak and the low read off the curve.
  LifeRunTally get runTally {
    LifeYearPoint? peak;
    LifeYearPoint? low;
    for (final point in _curve.values) {
      if (peak == null || point.netWorth > peak.netWorth) peak = point;
      if (low == null || point.netWorth < low.netWorth) low = point;
    }
    return LifeRunTally(
      adultYears: _adultYears,
      workYears: _workYears,
      yearsUnemployed: _yearsUnemployed,
      studentYears: _studentYears,
      weeksMissed: _weeksMissedTotal,
      timesLaidOff: _timesLaidOff,
      raises: _raisesEarned,
      referrals: _referrals,
      contactsMade: _contactsMade,
      townEarned: _townEarnedTotal,
      sideJobs: _sideJobs,
      incomeTotal: _incomeTotal,
      savedTotal: _savedTotal,
      interestPaid: _interestPaid,
      debtRepaid: _debtRepaid,
      degreesEarned: _degreesEarned,
      studentBorrowed: _studentBorrowed,
      promotions: _promotions,
      assetsBought: _assetsBought,
      shocksHit: _shocksHit,
      shocksCovered: _shocksCovered,
      firstJobAge: _firstJobAge,
      peakNetWorth: peak?.netWorth ?? 0,
      peakAge: peak?.age,
      lowNetWorth: low?.netWorth ?? 0,
      lowAge: low?.age,
    );
  }

  /// The whole memory, for the debrief.
  LifeRunRecord get runRecord =>
      LifeRunRecord(curve: yearCurve, moments: moments, tally: runTally);

  /// Remembers a decision and what the options not taken would have done.
  ///
  /// Only what moved real money, or would have. A choice about nothing is not a
  /// moment, and the list is capped so a very long life cannot grow it without
  /// bound.
  void _rememberDecision(LifeEvent event, int index) {
    final choice = event.choices[index];
    LifeChoice? better;
    LifeChoice? worse;
    for (var i = 0; i < event.choices.length; i++) {
      if (i == index) continue;
      final other = event.choices[i];
      if (better == null || other.money > better.money) better = other;
      if (worse == null || other.money < worse.money) worse = other;
    }
    final regret = better == null ? 0 : better.money - choice.money;
    final edge = worse == null ? 0 : choice.money - worse.money;
    if (choice.money.abs() < 40 && regret < 40 && edge < 40) return;
    if (_moments.length >= 80) return;
    _moments.add(
      LifeMoment(
        age: _age,
        kind: LifeMomentKind.decision,
        title: event.prompt,
        chose: choice.label,
        moneyDelta: choice.money,
        betterDelta: better?.money,
        betterOption: better?.label,
        worseDelta: worse?.money,
        concept: choice.teaches,
      ),
    );
  }

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
    // What last year's effort was, read before the tallies are cleared. Grades,
    // performance and a team's standing all follow it.
    final studied = _takenThisYear[LifeAction.study] ?? 0;
    final workedHard = _takenThisYear[LifeAction.workHarder] ?? 0;
    final trained = _activityUses['train'] ?? 0;
    // A new year is a fresh allowance for every on-demand action. See
    // `_yield` — without this, the diminishing return would be permanent
    // rather than annual, and a long life would end with nothing left to do.
    _takenThisYear.clear();
    _activityUses.clear();
    _touchesThisYear.clear();
    // The town restocks and everybody you spoke to has forgotten you did.
    _townChatsThisYear.clear();
    _townCoinsThisYear.clear();
    _townEarnedThisYear = 0;
    if (!isDependent) {
      _adultYears++;
      if (_salary > 0) {
        _workYears++;
      } else if (_edu.inSchool) {
        // A student is not unemployed, and the debrief should not say so.
        _studentYears++;
      } else {
        _yearsUnemployed++;
      }
    }
    // re-rolled every year so whether the town is open changes as you go,
    // not fixed at birth
    _weather = WeatherInfo.roll(_random);

    _expirePowers();

    _payShare = 1.0;
    // School comes first in the year: tuition falls due before anything is
    // earned, and a graduation can change what the year's job hunt looks like.
    _advanceSchooling(studied);
    if (!isDependent) {
      // Running yourself down costs shifts, and shifts are pay. Read from the
      // stats as they stand *now*, so what the player did all year decides it.
      if (_salary > 0) _applyWorkStrain();
      if (_salary > 0) {
        // Earning years run through the budget, so the split the player
        // chose is what actually governs the year.
        _applyBudget();
      } else {
        // Loans keep asking whether or not there is a paycheck.
        _settleLoans(0);
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
      _applyWorkYear(workedHard);
      _ageAssets();
    } else {
      // Somebody else is feeding you.
      _eatWell();
      // A part-time job at sixteen is pay, and it is the young person's own.
      if (_salary > 0) {
        final earned = (_salary * _payShare).round();
        _money += earned;
        _incomeTotal += earned;
      }
      _applyWorkYear(workedHard);
      _ageAssets();
      // A child who is unwell misses school, which is the same lesson at a
      // smaller size. Gentle on purpose: a little behind, nothing worse.
      if (_health < 35) {
        _smarts = _clamp(_smarts - 2);
        _setLog(
          'You missed a lot of school being unwell and fell a little behind.',
          kind: LifeLogKind.learning,
        );
      }
    }

    _playSeason(trained);

    _applyIllness();
    if (_dead) {
      _recordYear();
      notifyListeners();
      return;
    }

    _applyAgeing();
    if (_dead) {
      _recordYear();
      notifyListeners();
      return;
    }

    _driftRelationships();
    _agePeople();
    _maybeReferral();
    _maybeFinancialShock();
    _queueAgeCards();

    // Milestones give the feed texture on years with no event.
    final milestone = _milestoneFor(_age);
    // A card the game made for this moment goes first: a graduation, a move, a
    // loss. Everything else is a draw from the pool.
    _currentEvent = _queuedEvents.isNotEmpty
        ? _queuedEvents.removeAt(0)
        : _drawEvent();

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
    _recordYear();
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
      if (!person.isAlive) continue;
      if (person.lastSeenAge == _age) continue;
      final loss = (kBaseYearlyDrift * person.kind.driftRate).round();
      _people[i] = person.copyWith(
        closeness: (person.closeness - loss).clamp(0, 100),
      );
    }

    // Loneliness is felt, not just recorded. A small yearly cost once the
    // people around you have faded, so the stat and the story agree. Contacts
    // do not count either way: having only colleagues is not company.
    final personal = _people.where((p) => !p.kind.isProfessional).toList();
    if (personal.isNotEmpty && personal.every((p) => !p.isPresent)) {
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
    final essentials = (base * (1 - powerStrength(PowerEffect.cheaperLiving)))
        .round();
    // Rent is a need, so it lives here and comes out of the needs slice of the
    // budget, which is where a person would put it. Owning a home replaces
    // rent with a mortgage and upkeep, which are paid separately.
    return essentials + housingCost + childCost;
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

  /// Years drawn since the last money shock, for the "one is due" rule in
  /// [_drawEvent]. Only counts years lived as an adult.
  int _yearsSinceShock = 0;

  LifeEvent? _drawEvent() {
    final ctx = context;

    // A shock is *due* once an adult has gone [kShockGraceYears] without one.
    // Asked for as "make sure disasters happen, like your boss cutting you from
    // your job": left to the weighted draw, 140 of 300 simulated working lives
    // never lost a job to a layoff card and most had no named disaster at all.
    // A child has nothing to lose, so the rule does not run for one.
    final adult = !isDependent && _age >= 20;
    final shockDue = adult && _yearsSinceShock >= kShockGraceYears;

    // ~25% of years are quiet, so events feel like events. Never the year a
    // shock is due: the point is that it arrives.
    if (!shockDue && _random.nextInt(4) == 0) {
      if (adult) _yearsSinceShock++;
      return null;
    }

    bool fresh(LifeEvent e) {
      if (e.isWager && !allowWagering) return false;
      if (e.showsGamblingMechanic && hideGamblingMechanics) return false;
      // Grown-up instruments, kept back from young *players* — not from
      // grown-up characters. See [plainWordsOnly].
      if (plainWordsOnly && mentionsAdultTopic(e.prompt)) return false;
      if (!e.matches(ctx)) return false;
      final topic = e.topic;
      if (topic != null) {
        final last = _topicLastFired(topic);
        if (last != null) {
          if (!e.repeatable) return false;
          if (_age - last < _repeatCooldownYears) return false;
        }
      }
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
                (!e.isWager || allowWagering) &&
                !(e.showsGamblingMechanic && hideGamblingMechanics) &&
                // The fallback has to apply the same filter. Without this a
                // long life exhausts the fresh pool and quietly reopens the
                // door that was just closed — which is how age gates leak.
                !(plainWordsOnly && mentionsAdultTopic(e.prompt)) &&
                e.matches(ctx) &&
                e.repeatable,
          )
          .toList(growable: false);
    }
    if (eligible.isEmpty) {
      if (adult) _yearsSinceShock++;
      return null;
    }

    if (shockDue) {
      final shocks = [
        for (final e in eligible)
          if (kShockEventIds.contains(e.id)) e,
      ];
      // Only when something is eligible. A shock that needs a job or a car does
      // not fire at somebody who has neither, and the draw carries on as usual.
      if (shocks.isNotEmpty) eligible = shocks;
    }

    final total = eligible.fold<double>(0, (sum, e) => sum + _drawWeight(e));
    final chosen = total <= 0
        ? eligible[_random.nextInt(eligible.length)]
        : _weightedPick(eligible, total);

    _seen.add(chosen.id);
    _lastFiredAge[chosen.id] = _age;
    if (adult) {
      _yearsSinceShock = kShockEventIds.contains(chosen.id)
          ? 0
          : _yearsSinceShock + 1;
    }
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

  /// The latest age any card on [topic] fired this life. See
  /// [LifeEvent.topic].
  int? _topicLastFired(String topic) {
    int? latest;
    for (final entry in _lastFiredAge.entries) {
      if (_topicOf[entry.key] != topic) continue;
      if (latest == null || entry.value > latest) latest = entry.value;
    }
    return latest;
  }

  static final Map<String, String> _topicOf = <String, String>{
    for (final e in kLifeEvents)
      if (e.topic != null) e.id: e.topic!,
  };

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

  /// Moves the money an event choice asks for.
  ///
  /// Gains land as cash. A cost used to be `max(0, cash + delta)`, which
  /// quietly destroys whatever the cash could not cover: a 900 bill against 400
  /// in cash left 0 and the other 500 simply vanished, so the numbers on screen
  /// stopped adding up and nothing ever said why. It is the same mistake the
  /// yearly budget made, and it read to a player as money that crashed to zero
  /// for no reason.
  ///
  /// A cost is now paid the way a person pays for something they chose: from
  /// cash first, then from savings, and only then borrowed. A child is the
  /// exception, because the family covers what a child cannot.
  void _applyEventMoney(int delta) {
    if (delta >= 0) {
      _money += delta;
      return;
    }
    final cost = -delta;
    if (isDependent) {
      _money = max(0, _money - cost);
      return;
    }
    final fromCash = cost.clamp(0, _money);
    _money -= fromCash;
    var left = cost - fromCash;
    final fromFund = left.clamp(0, _emergencyFund);
    _emergencyFund -= fromFund;
    left -= fromFund;
    if (left > 0) {
      _debt += left;
      _setLog(
        'That cost $cost and your cash could not cover it, so $left of it is '
        'now borrowed.',
        kind: LifeLogKind.shock,
      );
    } else if (fromFund > 0) {
      _setLog(
        'That cost $cost. Your cash ran out, so $fromFund came out of '
        'savings.',
        kind: LifeLogKind.money,
      );
    }
  }

  /// Resolves the current event with the chosen option's effects.
  void chooseOption(int index) {
    final event = _currentEvent;
    if (event == null || index < 0 || index >= event.choices.length) {
      return;
    }
    final choice = event.choices[index];
    _rememberDecision(event, index);
    _applyEventMoney(choice.money);
    if (choice.moveTo != null && !ownsHome) _moveIn(choice.moveTo!);
    _applyStoryState(choice);
    if (choice.followUp != LifeFollowUp.none) {
      _pendingFollowUp = choice.followUp;
    }
    _happiness = _clamp(_happiness + choice.happiness);
    _health = _clamp(_health + choice.health);
    _smarts = _clamp(_smarts + choice.smarts);
    _looks = _clamp(_looks + choice.looks);
    if (choice.setJob != null) {
      // An event can hand out a job, a better one, or take the job away. It
      // can never quietly demote: with pay now reaching the thousands, an
      // event that offers a 400 job must not replace a 2,000 one.
      final offered = choice.setSalary ?? _salary;
      final forced = choice.replacesJob;
      if (!hasJob || offered > _salary || offered == 0 || forced) {
        // A card that takes the job away is a layoff like any other, and the
        // debrief counts them.
        if (hasJob && (offered == 0 || choice.laidOff)) _timesLaidOff++;
        _job = choice.setJob!;
        _salary = offered;
        _jobId = null;
        _yearsInRole = 0;
        _performance = 60;
        if (_salary > 0) _firstJobAge ??= _age;
      }
    } else if (choice.setSalary != null && hasJob) {
      // Pay changes and the title does not: a promotion, a negotiated figure,
      // the next employer after a layoff. These used to be read only inside
      // the branch above, so ten choices across seven cards — "the pay rise
      // is real", royalties for life — moved nothing at all.
      final offered = choice.setSalary!;
      if (offered > _salary || choice.replacesJob) {
        if (choice.laidOff) _timesLaidOff++;
        _salary = offered;
        if (choice.replacesJob) {
          _jobId = null;
          _yearsInRole = 0;
          _performance = 60;
        }
      }
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
    _recordYear();
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
    LifeAction.practice: 4,
    LifeAction.spendTime: 0,
    LifeAction.workHarder: 14,
    LifeAction.askForRaise: 14,
    LifeAction.network: 16,
    LifeAction.payDownDebt: 16,
    LifeAction.applyJob: 16,
    LifeAction.applyPromotion: 16,
    LifeAction.applyCollege: 17,
    LifeAction.conversation: 4,
    LifeAction.compliment: 4,
    LifeAction.askMoney: 6,
    LifeAction.date: 18,
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
  ///
  /// **Since revised for the open-air ones.** Asked for as *"remove things that
  /// can be done in the open world from the menu, like hiking, meditation and
  /// going outside"*, the Activities menu no longer lists the gym, the library,
  /// going out, or anything with a `place` (see `ActivityDef.place`). Those are
  /// done inside the building (`life_town_things.dart`). The controller methods
  /// and [allows] are unchanged, so nothing is *blocked*, and the doctor stays
  /// in the menu for somebody who is too unwell to leave the house, because a
  /// clinic you are not allowed to walk to would be a trap.
  static bool hasTownEquivalent(LifeAction action) =>
      townBonusFor(action) != null;

  /// What walking there actually gets you, in the player's own terms.
  ///
  /// **Why this is a sentence and not just a badge.** The menu row and the
  /// town building do the same job with different numbers, and the difference
  /// lived only in prose inside the row's `detail` field and in the
  /// controller's feed lines. So the badge read "in town" and answered none
  /// of the questions a player actually has: is it better, by how much, and
  /// is it worth the walk?
  ///
  /// Reported three separate times as the menu and the map duplicating each
  /// other. They are not duplicates — one is the quick version and one pays
  /// more — but nothing on screen said so, which makes them duplicates as far
  /// as anybody using the app is concerned.
  ///
  /// Blocking the menu versions outright was tried and reverted:
  /// `life_age_gates_test` and `budget_teaching_test` assert that a doctor, a
  /// job and the library stay reachable without a walk, and they are right to.
  /// A child who cannot reach a doctor because they have not found the
  /// building is a worse outcome than a little overlap.
  static String? townBonusFor(LifeAction action) => switch (action) {
    LifeAction.library => 'The library in town pays double',
    LifeAction.goOut => 'The park in town is free',
    LifeAction.doctor => 'The clinic in town has a money puzzle',
    LifeAction.findJob => 'The job board in town hires on the spot',
    _ => null,
  };

  /// Why [action] is unavailable, or null when it is allowed.
  ///
  /// Returns copy aimed at the player rather than a boolean, because "You
  /// are too little for that" *is* the content at age three — being told what
  /// you cannot do yet is how the early years teach that a life has stages.
  String? gateFor(LifeAction action) {
    if (finished) return 'This life is over';
    // Off for everybody, on request, through one switch. Asked before age
    // because no age makes it available.
    if (action == LifeAction.gamble && !allowWagering) {
      return 'Not part of Life for now';
    }
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
        LifeAction.practice => 'You are still a baby',
        LifeAction.workHarder ||
        LifeAction.askForRaise => 'You are too young to work',
        LifeAction.network => 'Networking events start at 16',
        LifeAction.payDownDebt => 'You have no debts of your own yet',
        LifeAction.applyJob ||
        LifeAction.applyPromotion => 'You are too young to work',
        LifeAction.applyCollege => 'You need to be 17 to apply',
        LifeAction.conversation ||
        LifeAction.compliment => 'You are still a baby',
        LifeAction.askMoney => 'You are too little to ask for money',
        LifeAction.date => 'You have to be 18',
        _ => 'Not yet',
      };
    }
    return null;
  }

  bool allows(LifeAction action) => gateFor(action) == null;

  /// How many times each action has been taken in the current year.
  final Map<LifeAction, int> _takenThisYear = <LifeAction, int>{};

  /// One action's allowance for this year, for the menu to show.
  ///
  /// The rules live in [EffortRules]; this only supplies how many times the
  /// current year has already used.
  ActionBudget budgetFor(LifeAction action) =>
      EffortRules.budget(action, _takenThisYear[action] ?? 0);

  /// Why [action] cannot be done right now, or null when it can.
  ///
  /// The age gate ([gateFor]) and this year's budget, in one answer, because a
  /// row in a menu only needs to know whether to grey out and what to say.
  /// Age wins when both apply: telling somebody they have "done enough of that
  /// this year" about something they are too young to do at all is a lie.
  String? unavailableFor(LifeAction action) {
    final gate = gateFor(action);
    if (gate != null) return gate;
    if (budgetFor(action).exhausted) {
      return 'Done for this year. Age up and it counts again.';
    }
    return null;
  }

  /// How much of an action's effect still lands, given how often it has
  /// already been used this year.
  ///
  /// **The exploit this closes.** Reported as *"they can spam the gym"*, and
  /// then, when the same fix was needed for everything else, as *"make sure
  /// the player cannot spam the same option"*. Only `exercise` had the curve.
  /// It is a table now, in `life_effort.dart`, and every repeatable action
  /// reads it. See [EffortRules] for the whole argument.
  ///
  /// Diminishing rather than a hard cap, on purpose: a hard "once per year"
  /// reads as the game refusing you and invites save-scumming the year; a
  /// fading return reads as the truth it models.
  double _yield(LifeAction action) =>
      EffortRules.yieldAt(action, _takenThisYear[action] ?? 0);

  /// Records a use and reports whether it did anything.
  ///
  /// Callers that get `false` should return without applying any effect. The
  /// player is told why in the feed rather than the button quietly doing
  /// nothing, because a button that appears to work and does not is the worse
  /// failure. That exact bug is in this project's log twice already.
  bool _spend(LifeAction action) {
    final rate = _yield(action);
    if (rate <= 0) {
      _setLog(
        'You have already done that as much as one year has room for. '
        'Age up and it will matter again.',
        kind: LifeLogKind.life,
      );
      notifyListeners();
      return false;
    }
    _takenThisYear[action] = (_takenThisYear[action] ?? 0) + 1;
    return true;
  }

  /// Scales a gain by this year's remaining yield, never below 1 while the
  /// action still counts, because "+0 Health" reads as broken.
  ///
  /// Costs (zero or negative amounts) are never softened. A course costs the
  /// same the third time you take it in a year, which is the point.
  int _scaled(LifeAction action, int amount) {
    if (amount <= 0) return amount;
    final rate = _yield(action);
    if (rate >= 1) return amount;
    final scaled = (amount * rate).round();
    return scaled < 1 ? 1 : scaled;
  }

  // --- Activities ---

  /// Study to raise Smarts.
  void study() {
    if (!allows(LifeAction.study)) return;
    final gain = _scaled(LifeAction.study, 6);
    if (!_spend(LifeAction.study)) return;
    _smarts = _clamp(_smarts + gain);
    _happiness = _clamp(_happiness - 2);
    if (!isDependent) {
      _money = max(0, _money - 30);
    }
    // A student's grades move now, not only at the end of the year, so the bar
    // on the school card answers the button that was just pressed.
    var gradeNote = '';
    if (_edu.inSchool) {
      final bump = max(1, (gain * 0.7).round());
      _edu.grades = (_edu.grades + bump).clamp(0, 100);
      gradeNote = ' Grades +$bump.';
    }
    _setLog(
      isDependent
          ? 'Hit the books after school: +$gain Smarts.$gradeNote'
          : 'Took a course: +$gain Smarts, -30 coins.$gradeNote',
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
    final joy = _scaled(LifeAction.goOut, 6);
    if (!_spend(LifeAction.goOut)) return;
    if (!isDependent) {
      _money -= 40;
    }
    // Six, not ten, for the same reason as the library: the park is a place
    // on the map, and an afternoon booked from a menu is the lesser version
    // of one you walked to.
    _happiness = _clamp(_happiness + joy);
    _setLog(
      'Had a good afternoon: +$joy Happiness. The park in town is better, '
      'and free.',
      kind: LifeLogKind.life,
    );
    notifyListeners();
  }

  /// Practise a skill. This is the player-driven half of the career loop:
  /// skills gate which career events can fire at all, so a music contract
  /// only becomes reachable after actually putting the hours in.
  void practice(LifeSkill skill) {
    if (!allows(LifeAction.practice)) return;
    final gain = _scaled(LifeAction.practice, 4 + (_smarts ~/ 25));
    if (!_spend(LifeAction.practice)) return;
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
    final health = _scaled(LifeAction.exercise, 8);
    final looks = _scaled(LifeAction.exercise, 3);
    if (!_spend(LifeAction.exercise)) return;

    _health = _clamp(_health + health);
    _looks = _clamp(_looks + looks);
    _happiness = _clamp(_happiness - 1);
    _setLog(
      'Worked out: +$health Health, +$looks Looks.',
      kind: LifeLogKind.health,
    );
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

  /// The youngest age at which the job market will look at you.
  static const int jobHuntingAge = 16;

  /// Whether looking for work is currently possible at all.
  bool get canJobHunt => !finished && _age >= jobHuntingAge && !hasJob;

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
    final healed = _scaled(LifeAction.doctor, 12);
    if (!_spend(LifeAction.doctor)) return;
    if (!isDependent) {
      _money -= cost;
    }
    _health = _clamp(_health + healed);
    _setLog(
      isDependent
          ? 'A parent took you for a check-up: +$healed Health.'
          : 'Check-up done: +$healed Health, -$cost coins.',
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
    final gain = _scaled(LifeAction.library, 2);
    if (!_spend(LifeAction.library)) return;
    _smarts = _clamp(_smarts + gain);
    _setLog(
      'Read at home for the afternoon: +$gain Smarts. The library in town '
      'is worth the walk.',
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
  ///
  /// **Returns the life money actually credited.** Earnings run through
  /// [TownIncome], so the town pays at full rate up to a yearly allowance and a
  /// quarter beyond it. Spending is never softened. The map uses the return
  /// value to say what a visit was really worth.
  int applyTownOutcome({
    required int gold,
    required int xp,
    required int literacy,
    bool hires = false,
  }) {
    if (finished) return 0;
    // The job board actually employing you is the point of it being a job
    // board. Silently ignored when the character is too young or already
    // working — `findJob` checks both and returns false, and the town's own
    // outcome text still lands, so nothing looks broken.
    if (hires) findJob(viaJobBoard: true);
    final credited = gold > 0 ? _creditTown(gold) : gold;
    _money += credited;
    if (literacy > 0) _smarts = _clamp(_smarts + (literacy / 4).round());
    if (xp > 0) _happiness = _clamp(_happiness + (xp / 5).round());
    notifyListeners();
    return credited;
  }

  /// Passes [gross] through the yearly allowance and books what is left.
  int _creditTown(int gross) {
    final paid = TownIncome.payFor(_townEarnedThisYear, gross);
    _townEarnedThisYear += paid;
    _townEarnedTotal += paid;
    return paid;
  }

  /// Picks up a coin from the town map, for life money.
  ///
  /// **Returns what it paid**, 0 when this coin has already been taken this
  /// year. Coins used to pay account gold and only ever once, so after the first
  /// life the map had nothing to give anybody. They restock every year now, at a
  /// value that means something on the scale of the life they are found in.
  /// See [TownIncome].
  int takeTownCoin(String id, int faceValue) {
    if (finished || _townCoinsThisYear.contains(id)) return 0;
    _townCoinsThisYear.add(id);
    final paid = _creditTown(TownIncome.coinWorth(faceValue));
    _money += paid;
    notifyListeners();
    return paid;
  }

  /// Speaking to somebody in town. They become a contact, and each year you
  /// talk again warms it a little.
  ///
  /// Returns a line for the map to show, or null when nothing changed. Under
  /// 14 it does nothing: contacts are about work, and a child chatting to a
  /// stranger in a town square is not a career move.
  String? meetTownContact(String name) {
    if (finished || _age < 14) return null;
    final existing = _personNamed(name);
    if (existing == null) {
      _people.add(
        Relationship(
          name: name,
          kind: RelationshipKind.colleague,
          // A chat is not a friendship, so they arrive cooler than somebody
          // met properly.
          closeness: 45,
          metAtAge: _age,
          lastSeenAge: _age,
        ),
      );
      _contactsMade++;
      _townChatsThisYear.add(name);
      notifyListeners();
      return 'You got talking to $name. They are one of your contacts now.';
    }
    if (!existing.kind.isProfessional) return null;
    if (_townChatsThisYear.contains(name)) return null;
    _townChatsThisYear.add(name);
    _updatePerson(
      name,
      existing.copyWith(
        closeness: (existing.closeness + 8).clamp(0, 100),
        lastSeenAge: _age,
      ),
    );
    notifyListeners();
    return '$name remembered you. Staying in touch keeps a contact warm.';
  }

  /// A side job. Real money for a real cost in time and energy — the only
  /// income source available before a career event fires.
  void workSideJob() {
    if (!allows(LifeAction.sideJob)) return;
    // The pay fades with the year's shifts. Without it this was an
    // infinite-money button: happiness clamps at zero, so no tap ever cost
    // anything more than the one before, and the leaderboard ranks net worth.
    final earned = _scaled(LifeAction.sideJob, 40 + _random.nextInt(60));
    if (!_spend(LifeAction.sideJob)) return;
    _sideJobs++;
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
  /// [place] null keeps the old behavior — the first option open at this
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

    final joy = _scaled(LifeAction.volunteer, chosen.happiness);
    final learned = _scaled(LifeAction.volunteer, chosen.smarts);
    final fitter = _scaled(LifeAction.volunteer, chosen.health);
    if (!_spend(LifeAction.volunteer)) return;
    _happiness = _clamp(_happiness + joy);
    _smarts = _clamp(_smarts + learned);
    _health = _clamp(_health + fitter);
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
    if (!_spend(LifeAction.gamble)) return;
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
    final joy = _scaled(LifeAction.spendTime, 8);
    final closer = _scaled(LifeAction.spendTime, 12);
    if (!_spend(LifeAction.spendTime)) return;
    _happiness = _clamp(_happiness + joy);
    if (existing != null) {
      // Time is the thing that actually repairs a relationship, and it moves
      // closeness more than twice as far as a gift does. That comparison is
      // the whole reason both actions are in the menu.
      _updatePerson(
        person,
        existing.copyWith(
          closeness: (existing.closeness + closer).clamp(0, 100),
          lastSeenAge: _age,
        ),
      );
    }
    _setLog(
      'Spent the day with $person: +$joy Happiness. Cost: nothing.',
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
    final joy = _scaled(LifeAction.buyGift, 5);
    final closer = _scaled(LifeAction.buyGift, 5);
    if (!_spend(LifeAction.buyGift)) return;
    _money -= cost;
    _happiness = _clamp(_happiness + joy);
    final existing = _personNamed(person);
    if (existing != null) {
      _updatePerson(
        person,
        existing.copyWith(
          closeness: (existing.closeness + closer).clamp(0, 100),
          lastSeenAge: _age,
        ),
      );
    }
    _setLog(
      'Bought $person a gift: +$joy Happiness, -$cost coins.',
      kind: LifeLogKind.people,
    );
    notifyListeners();
  }

  /// Go somewhere people in your line of work go.
  ///
  /// Costs a little money and an evening, twice a year, and the second time
  /// pays half as well. Most of the time you meet somebody. Sometimes you stand
  /// by the snacks and go home, which is also what happens.
  void attendNetworkingEvent() {
    if (!allows(LifeAction.network)) return;
    const cost = 25;
    if (!isDependent && _money < cost) {
      _setLog('Not enough coins to get in.', kind: LifeLogKind.money);
      notifyListeners();
      return;
    }
    final rate = _yield(LifeAction.network);
    if (!_spend(LifeAction.network)) return;
    if (!isDependent) _money -= cost;

    // Charisma helps, which is the one place it earns money directly.
    final charisma = (_skills[LifeSkill.charisma] ?? 0) / 100;
    final chance = 0.75 * rate + charisma * 0.15;
    if (_random.nextDouble() < chance) {
      final name = freshContactName(_random, {for (final p in _people) p.name});
      _people.add(
        Relationship(
          name: name,
          kind: RelationshipKind.colleague,
          closeness: 50,
          metAtAge: _age,
          lastSeenAge: _age,
        ),
      );
      _contactsMade++;
      _smarts = _clamp(_smarts + 1);
      _setLog(
        'Went to an evening for people in your line of work and got talking '
        'to $name. You swapped numbers. New contact.',
        kind: LifeLogKind.people,
      );
    } else {
      _setLog(
        'Went along, stood near the snacks and left with nobody new. It '
        'takes a few tries.',
        kind: LifeLogKind.people,
      );
    }
    notifyListeners();
  }

  /// Coffee with a contact. Keeps them warm, which is the only thing that does.
  ///
  /// Contacts fade faster than family, so a network you never touch stops being
  /// one. This is what touching it costs: a few coins and an hour. It shares
  /// the networking budget, so it is the same evenings either way.
  void coffeeWith(String person) {
    if (finished) return;
    final existing = _personNamed(person);
    if (existing == null || !existing.kind.isProfessional) return;
    if (!allows(LifeAction.network)) return;
    const cost = 10;
    if (!isDependent && _money < cost) {
      _setLog('Not enough coins for the coffees.', kind: LifeLogKind.money);
      notifyListeners();
      return;
    }
    final closer = _scaled(LifeAction.network, 12);
    if (!_spend(LifeAction.network)) return;
    if (!isDependent) _money -= cost;
    _happiness = _clamp(_happiness + 2);
    _updatePerson(
      person,
      existing.copyWith(
        closeness: (existing.closeness + closer).clamp(0, 100),
        lastSeenAge: _age,
      ),
    );
    _setLog(
      'Coffee with $person. Catching up costs almost nothing and keeps '
      'the contact warm.',
      kind: LifeLogKind.people,
    );
    notifyListeners();
  }

  /// Applies a year of missed work, and the consequences of a second one.
  void _applyWorkStrain() {
    final strain = assessWorkStrain(health: _health, happiness: _happiness);
    _payShare = strain.payShare;

    if (!strain.missesWork) {
      _strainYears = 0;
      return;
    }

    _weeksMissedTotal += strain.weeksMissed;
    _yearsStrained++;

    if (strain.isSerious) {
      _strainYears++;
      if (_strainYears >= kYearsToLoseJob) {
        final lost = _job;
        _job = 'Unemployed';
        _salary = 0;
        _strainYears = 0;
        _timesLaidOff++;
        _payShare = 1.0;
        _happiness = _clamp(_happiness - 6);
        _setLog(
          'After a second year of missed work, your employer let you go '
          'from your job as a $lost. Your health and your mood are part of '
          'holding a job.',
          kind: LifeLogKind.shock,
        );
        return;
      }
    } else {
      _strainYears = 0;
    }

    final cut = (_salary * strain.missedShare).round();
    _setLog(
      'You missed about ${strain.weeksMissed} '
      '${strain.weeksMissed == 1 ? 'week' : 'weeks'} of work through '
      '${strain.cause}, and were paid for fewer of them: about $cut less.',
      kind: LifeLogKind.career,
    );
  }

  /// Once a year, somebody who knows you might pass on a lead.
  ///
  /// Rolls only when there is a network to roll for, so a life with no contacts
  /// draws nothing from the random stream at all. Odds come from
  /// [NetworkReading.referralChance].
  void _maybeReferral() {
    if (finished || _age < jobHuntingAge) return;
    final reading = networkReading;
    if (reading.contacts == 0) return;
    if (_random.nextDouble() >= reading.referralChance) return;

    // The warmest contact is the one who says your name.
    final introducer = contacts.first.name;
    final kind = pickReferralKind(hasJob: hasJob, random: _random);

    switch (kind) {
      case ReferralKind.jobLead:
        if (!findJob(referredBy: introducer)) return;
      case ReferralKind.goodWord:
        // A share of pay, like every other raise. It was a flat 150 to 349,
        // which on a 240 salary was a raise of up to 145%.
        final percent = 3 + _random.nextInt(6);
        final bump = max(1, (_salary * percent / 100).round());
        _salary += bump;
        _raisesEarned++;
        _referrals++;
        _setLog(
          '$introducer mentioned you to your manager. Word of mouth did what a '
          'year of good work had not: salary up $bump, which is $percent%.',
          kind: LifeLogKind.career,
        );
      case ReferralKind.gig:
        final earned = 60 + _random.nextInt(100);
        _money += earned;
        _referrals++;
        _setLog(
          '$introducer sent a one-off job your way: +$earned coins. '
          'Somebody had to know you existed.',
          kind: LifeLogKind.career,
        );
    }
    _happiness = _clamp(_happiness + 3);
  }

  /// True once the character actually holds a paying job.
  bool get hasJob => _salary > 0 && _job != 'Newborn' && _job != 'Unemployed';

  /// Pay back what was borrowed, from cash first and then from savings.
  ///
  /// Borrowing costs about 18% a year here and a savings pot earns nothing, so
  /// clearing the debt is the better use of the money once a small cushion is
  /// kept. There was no way to do this at all: the only thing that ever reduced
  /// a balance was 30% of whatever cash happened to be lying around at year's
  /// end, which for a player on a budget was nothing. The debrief kept telling
  /// people to pay their debt down, with no button to do it.
  ///
  /// Returns how much was actually paid.
  int payDownDebt([int? amount]) {
    if (!allows(LifeAction.payDownDebt) || _debt <= 0) return 0;
    final wanted = (amount ?? _debt).clamp(1, _debt);
    final fromCash = wanted.clamp(0, _money);
    final fromFund = (wanted - fromCash).clamp(0, _emergencyFund);
    final paid = fromCash + fromFund;
    if (paid <= 0) {
      _setLog(
        'You have nothing to pay it with yet. Cash and savings are both empty.',
        kind: LifeLogKind.money,
      );
      notifyListeners();
      return 0;
    }
    _money -= fromCash;
    _emergencyFund -= fromFund;
    _debt -= paid;
    _debtRepaid += paid;
    final saved = (paid * 0.18).round();
    final from = fromFund > 0
        ? (fromCash > 0
              ? '$fromCash from cash and $fromFund from savings'
              : '$fromFund from savings')
        : '$fromCash from cash';
    if (_debt <= 0) {
      _happiness = _clamp(_happiness + 4);
      _setLog(
        'You paid off everything you owed ($from). That is about $saved a year you will not lose to interest.',
        kind: LifeLogKind.money,
      );
    } else {
      _setLog(
        'You paid back $paid ($from). Still owing $_debt, but about $saved less a year goes to interest.',
        kind: LifeLogKind.money,
      );
    }
    _teach(FinanceConcept.interestCost);
    notifyListeners();
    return paid;
  }

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
    _recordYear();
    notifyListeners();
  }

  int _clamp(int value) => value.clamp(0, 100);
}
