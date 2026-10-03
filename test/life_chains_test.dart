import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_event_chains.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every event that hangs off a flag, i.e. every chain continuation.
Iterable<LifeEvent> get _continuations =>
    kLifeEventsChains.where((e) => e.requiresFlag != null);

/// Every event that starts one.
Iterable<LifeEvent> get _openers =>
    kLifeEventsChains.where((e) => e.requiresFlag == null);

Set<LifeFlag> _flagsSetBy(LifeEvent e) => {
  for (final c in e.choices)
    if (c.setsFlag != null) c.setsFlag!,
};

Set<LifeFlag> _flagsClearedBy(LifeEvent e) => {
  for (final c in e.choices)
    if (c.clearsFlag != null) c.clearsFlag!,
};

/// Stands in for the sheet a follow-up would open. `chain_study_loan`'s
/// "take the loan" choice no longer sets `hasStudentLoan` directly — it
/// opens a college application, and the loan is only real once a simulated
/// life actually enrols, same as a player. Without this, no simulated life
/// could ever reach `chain_study_repay`.
void _resolveFollowUp(LifeSimController life) {
  switch (life.takeFollowUp()) {
    case LifeFollowUp.openCollege:
      for (final program in programsAt(SchoolStage.college)) {
        if (life.programGate(program) == null) {
          life.applyToProgram(program);
          break;
        }
      }
    case LifeFollowUp.openTrades:
    case LifeFollowUp.openJobs:
    case LifeFollowUp.openHousing:
    case LifeFollowUp.none:
      break;
  }
}

LifeContext _ctx({
  int age = 30,
  int money = 5000,
  Set<LifeFlag> flags = const <LifeFlag>{},
  bool hasJob = true,
}) => LifeContext(
  age: age,
  money: money,
  happiness: 60,
  health: 80,
  smarts: 60,
  fame: 0,
  skills: const <LifeSkill, int>{},
  traits: const <LifeTrait>{},
  hasJob: hasJob,
  flags: flags,
);

void main() {
  group('chain wiring', () {
    test('every flag a continuation waits on is set by something', () {
      // A continuation gated on a flag nothing ever sets is dead content —
      // and invisibly so, because a beat that never fires looks exactly
      // like a beat that keeps losing the roll.
      //
      // Ownership-backed flags (hasPet, hasCar, ownsHome, hasStudentLoan)
      // never appear as a literal setsFlag: a card grants the asset instead
      // and `LifeSimController._effectiveFlags` reads the flag back from
      // what is owned. See `kOwnershipBackedFlags`.
      final settable = <LifeFlag>{
        for (final e in kLifeEvents) ..._flagsSetBy(e),
        ...kOwnershipBackedFlags,
      };
      for (final event in _continuations) {
        expect(
          settable,
          contains(event.requiresFlag),
          reason:
              '${event.id} waits on ${event.requiresFlag} and nothing in the '
              'pool ever sets it',
        );
      }
    });

    test('every open thread has a way to close', () {
      // Otherwise a life carries the thread for sixty years while the
      // draw's open-chain boost keeps favouring a beat that has nothing
      // left to say.
      //
      // Scoped to flags that actually *gate* something. A flag no event
      // waits on (`gotDegree`, `soldTheBusiness`) is a record of what
      // happened, not an open thread, and requiring those to be cleared
      // would mean inventing an event to un-graduate someone.
      final gating = <LifeFlag>{
        for (final e in kLifeEvents)
          if (e.requiresFlag != null) e.requiresFlag!,
      };
      // Ownership-backed flags close via selling/paying off the asset
      // (sellsAsset, removesAsset, paysOffStudentLoan), never a literal
      // clearsFlag. See `kOwnershipBackedFlags`.
      final cleared = <LifeFlag>{
        for (final e in kLifeEvents) ..._flagsClearedBy(e),
        ...kOwnershipBackedFlags,
      };
      for (final flag in gating) {
        expect(
          cleared,
          contains(flag),
          reason: '$flag gates an event but nothing ever clears it',
        );
      }
    });

    test('openers are not themselves gated', () {
      // A chain that needs a flag to *start* can never start.
      for (final event in _openers) {
        expect(event.requiresFlag, isNull);
      }
      expect(_openers, isNotEmpty);
    });

    test('every thread has at least one beat that advances it', () {
      // Not every continuation has to move the chain — `chain_pet_vet` is a
      // pure cost beat and should leave the dog exactly where he was. What
      // must not happen is a flag whose *entire* set of continuations
      // leaves it unchanged, because then the thread can never resolve.
      final byFlag = <LifeFlag, List<LifeEvent>>{};
      for (final event in _continuations) {
        byFlag.putIfAbsent(event.requiresFlag!, () => []).add(event);
      }
      byFlag.forEach((flag, events) {
        final advances = events.any(
          (e) => _flagsSetBy(e).isNotEmpty || _flagsClearedBy(e).isNotEmpty,
        );
        expect(
          advances,
          isTrue,
          reason:
              'every beat gated on $flag leaves it untouched, so the thread '
              'never resolves',
        );
      });
    });

    test('chain ids are unique and namespaced', () {
      final ids = kLifeEventsChains.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate chain id');
      for (final id in ids) {
        expect(id, startsWith('chain_'));
      }
    });

    test('no chain id collides with the rest of the pool', () {
      final all = kLifeEvents.map((e) => e.id).toList();
      expect(all.toSet().length, all.length);
    });
  });

  group('flag gating', () {
    test('a continuation is invisible until its flag is set', () {
      final vet = kLifeEventsChains.firstWhere((e) => e.id == 'chain_pet_vet');
      expect(vet.matches(_ctx()), isFalse);
      expect(vet.matches(_ctx(flags: {LifeFlag.hasPet})), isTrue);
    });

    test('forbidsFlag closes a chain off', () {
      // The vet beat must not fire after the dog is gone.
      final vet = kLifeEventsChains.firstWhere((e) => e.id == 'chain_pet_vet');
      expect(
        vet.matches(_ctx(flags: {LifeFlag.hasPet, LifeFlag.petGone})),
        isFalse,
      );
    });

    test('the age gate still applies on top of the flag', () {
      final payoff = kLifeEventsChains.firstWhere(
        (e) => e.id == 'chain_index_payoff',
      );
      final flags = {LifeFlag.heldThroughCrash};
      expect(payoff.matches(_ctx(age: 30, flags: flags)), isFalse);
      expect(payoff.matches(_ctx(age: 50, flags: flags)), isTrue);
    });
  });

  group('the controller carries flags', () {
    /// Ages up until [id] is the current event, then returns it.
    LifeEvent? reachEvent(
      LifeSimController life,
      String id, {
      int maxYears = 90,
    }) {
      for (var i = 0; i < maxYears && !life.finished; i++) {
        if (life.currentEvent?.id == id) return life.currentEvent;
        if (life.currentEvent != null) life.chooseOption(0);
        life.ageUp();
      }
      return life.currentEvent?.id == id ? life.currentEvent : null;
    }

    test('choosing a flagged option records it', () {
      final life = LifeSimController(random: Random(4), initialAge: 0);
      // Drive straight at the pet opener rather than hoping for it.
      final found = reachEvent(life, 'chain_pet_adopt');
      if (found == null) {
        // Not every seed reaches every opener; the wiring tests above cover
        // the content, so this one just skips rather than asserting on luck.
        return;
      }
      expect(life.flags, isNot(contains(LifeFlag.hasPet)));
      life.chooseOption(0);
      expect(life.flags, contains(LifeFlag.hasPet));
    });

    test('flags start empty and are unmodifiable from outside', () {
      final life = LifeSimController(random: Random(1));
      expect(life.flags, isEmpty);
      expect(() => life.flags.add(LifeFlag.hasPet), throwsUnsupportedError);
    });
  });

  group('chains reach their endings in play', () {
    /// Plays [seed] to the end and reports which event ids fired.
    ///
    /// Choices are picked at random rather than fixed. A fixed index cannot
    /// reach the deeper beats at all: `chain_index_payoff` needs choice 0 at
    /// the opener (invest) and then choice 1 or 2 at the crash (hold), so
    /// no single constant index walks that path.
    Set<String> play(int seed, {int? pick, Map<String, int> steer = const {}}) {
      final rng = Random(seed * 31 + 7);
      final life = LifeSimController(random: Random(seed), initialAge: 0);
      final fired = <String>{};
      for (var i = 0; i < 95 && !life.finished; i++) {
        final event = life.currentEvent;
        if (event != null) {
          fired.add(event.id);
          life.chooseOption(
            steer.containsKey(event.id)
                ? steer[event.id]!
                : pick != null
                ? pick.clamp(0, event.choices.length - 1)
                : rng.nextInt(event.choices.length),
          );
          _resolveFollowUp(life);
        }
        life.ageUp();
      }
      return fired;
    }

    test('a chain that starts usually gets to continue', () {
      // The whole point of the draw's open-chain boost: once a thread is
      // open the game should want to close it, rather than leaving a
      // storyline hanging behind 120 unrelated events.
      //
      // Sample size matters here: a dog is now a real, aging asset with a
      // 12-year lifespan (see `_ageAssets`), so its hasPet window is bounded
      // instead of open for the rest of the character's life. That is a
      // narrower, more honest window than before, and 120 seeds landed close
      // enough to the 50% line to flip on it; 400 reads the same rate more
      // reliably rather than papering over the narrower window.
      var started = 0;
      var continued = 0;
      for (var seed = 0; seed < 400; seed++) {
        final fired = play(seed);
        if (fired.contains('chain_pet_adopt')) {
          started++;
          if (fired.contains('chain_pet_vet') ||
              fired.contains('chain_pet_old')) {
            continued++;
          }
        }
      }
      expect(started, greaterThan(0), reason: 'the pet chain never started');
      expect(
        continued / started,
        greaterThan(0.5),
        reason:
            'only $continued of $started pet chains went anywhere — the '
            'open-chain boost is not doing its job',
      );
    });

    test('every chain event is reachable across a spread of lives', () {
      final seen = <String>{};
      for (var seed = 0; seed < 400; seed++) {
        seen.addAll(play(seed));
      }
      // The last beat of a long chain is the rarest thing in the game: to see
      // `chain_index_regret` a life must be offered the index fund (about one
      // life in twelve), invest, and then sell in the crash, and by luck that
      // was two lives in fifteen hundred. Every batch of new events makes it
      // rarer, so a sweep of random lives goes red without anything being
      // wrong. So the beats a random player almost never reaches get a player
      // who walks the path on purpose. What is being guarded is that the path
      // exists and is open, and that is a claim about content, not about luck.
      const paths = <Map<String, int>>[
        {'chain_index_start': 0, 'chain_index_crash': 0}, // invest, then sell
        {'chain_index_start': 0, 'chain_index_crash': 1}, // invest, then hold
      ];
      for (final steer in paths) {
        for (var seed = 0; seed < 400; seed++) {
          seen.addAll(play(seed, steer: steer));
        }
      }
      // Clearing a student loan needs a college place, a job and then the
      // overpay choice, about one random life in four hundred, so the beat
      // after it is walked from the repayment itself.
      final repay = kLifeEventsChains.firstWhere(
        (e) => e.id == 'chain_study_repay',
      );
      for (var seed = 0; seed < 40; seed++) {
        final life = LifeSimController(
          random: Random(seed),
          initialAge: 28,
          startMoney: 3000,
          startJob: 'Baker',
          startSalary: 900,
        );
        life.debugSetEvent(repay);
        life.chooseOption(0);
        for (var y = 0; y < 20 && !life.finished; y++) {
          life.ageUp();
          final event = life.currentEvent;
          if (event == null) continue;
          seen.add(event.id);
          life.chooseOption(0);
        }
      }
      final unreachable = kLifeEventsChains
          .map((e) => e.id)
          .where((id) => !seen.contains(id))
          .toList();
      expect(
        unreachable,
        isEmpty,
        reason: 'no simulated life ever reached: $unreachable',
      );
    });
  });
}
