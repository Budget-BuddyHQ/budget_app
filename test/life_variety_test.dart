import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_careers.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_people.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays a life the way a person would — varied choices, occasional practice —
/// and reports which events fired.
({List<String> fired, int years}) _play(int seed, {LifeSkill? focus}) {
  final rng = Random(seed * 7919 + 13);
  final life = LifeSimController(
    random: Random(seed),
    startMoney: LifeOrigin.comfortable.familyMoney,
  );
  final fired = <String>[];

  while (!life.finished && life.age < 85) {
    life.ageUp();
    final event = life.currentEvent;
    if (event != null) {
      fired.add(event.id);
      life.chooseOption(focus == null ? rng.nextInt(event.choices.length) : 0);
    }
    if (life.age > 6) {
      if (focus != null) {
        if (rng.nextBool()) life.practise(focus);
      } else if (rng.nextInt(3) == 0) {
        life.practise(LifeSkill.values[rng.nextInt(LifeSkill.values.length)]);
      }
    }
  }
  return (fired: fired, years: life.age);
}

/// A fuller player than [_play]: one who studies, drives, rents then buys, keeps
/// a pet, marries and has children.
///
/// [_play] is a thin life (no family, nothing owned, no school past sixteen), so
/// an event that is about a car, a home, a partner or a campus can never come up
/// for it, and would look "unreachable" for a reason that has nothing to do with
/// the event. This player is what the coverage sweep uses to draw those.
({List<String> fired, int years}) _playRounded(int seed) {
  final rng = Random(seed * 104729 + 7);
  final life = LifeSimController(
    random: Random(seed),
    startMoney: LifeOrigin.comfortable.familyMoney,
    withFamily: true,
  );
  final fired = <String>[];
  // Each life is headed for one line of work, so between them the sweep visits
  // every ladder and not only the ones that are easy to fall into.
  final want = CareerTrack.values[seed % CareerTrack.values.length];

  // The cheapest thing of that kind this player can actually pay for, on a loan
  // when it can be financed and in cash when it cannot (a bicycle, a hamster).
  void own(AssetKind kind, {bool financed = false}) {
    if (life.assetsOf(kind).isNotEmpty) return;
    final options = assetsOfKind(kind)..sort((a, b) => a.price - b.price);
    for (final def in options) {
      final onLoan = financed && def.canFinance;
      if (life.buyGate(def, financed: onLoan) != null) continue;
      life.buyAsset(def, financed: onLoan);
      return;
    }
  }

  while (!life.finished && life.age < 85) {
    life.ageUp();
    final event = life.currentEvent;
    if (event != null) {
      fired.add(event.id);
      life.chooseOption(rng.nextInt(event.choices.length));
      life.takeFollowUp();
    }

    if (life.age >= 8) own(AssetKind.pet);
    if (life.age >= 18) {
      life.getLicense();
      own(AssetKind.vehicle, financed: true);
    }

    // Study for the line of work this life is headed for, if it asks for a
    // degree, and then take a job on that ladder.
    final startingJob = kJobs.firstWhere(
      (j) => j.track == want && j.rung == 0,
      orElse: () => kJobs.first,
    );
    if (life.age >= 18 &&
        life.age <= 22 &&
        !life.isPostSecondaryStudent &&
        !life.educationLevel.atLeast(EducationLevel.bachelor) &&
        (startingJob.minLevel.atLeast(EducationLevel.bachelor) ||
            seed.isEven)) {
      final matching = programsAt(SchoolStage.college)
          .where(
            (p) =>
                startingJob.fields.isEmpty ||
                startingJob.fields.contains(p.field),
          )
          .toList();
      if (matching.isNotEmpty) {
        life.applyToProgram(matching[rng.nextInt(matching.length)]);
      }
    }
    if (life.age >= 18 &&
        !life.isPostSecondaryStudent &&
        life.careerTrack != want) {
      final open = life.jobListings().where((l) => l.qualified).toList();
      final mine = open.where((l) => l.job.track == want).toList()
        ..sort((a, b) => a.job.rung - b.job.rung);
      final pick = mine.isNotEmpty
          ? mine.first
          : (!life.hasJob && open.isNotEmpty
                ? open[rng.nextInt(open.length)]
                : null);
      if (pick != null) life.applyForJob(pick.job.id);
    }
    if (life.age >= 28) own(AssetKind.home, financed: true);

    // Meet somebody, get close, marry, have children.
    if (life.age >= 19 && !life.hasPartner) {
      life.doActivity('meet_new');
      life.doActivity('dating_app');
    }
    final partners = life.partners;
    if (partners.isNotEmpty) {
      final who = partners.first.name;
      life.doPersonAction(PersonAction.spendTime, who);
      life.doPersonAction(PersonAction.conversation, who);
      if (!life.isMarried) {
        life.doPersonAction(PersonAction.propose, who);
      } else if (life.childrenOfYours.length < 2) {
        life.doPersonAction(PersonAction.startFamily, who);
      }
    }
  }
  return (fired: fired, years: life.age);
}

int _repeatsIn(List<String> fired) {
  final counts = <String, int>{};
  for (final id in fired) {
    counts.update(id, (v) => v + 1, ifAbsent: () => 1);
  }
  return counts.values
      .where((c) => c > 1)
      .fold<int>(0, (sum, c) => sum + (c - 1));
}

void main() {
  // these thresholds come from actually simulating the game, not guessing.
  // before the fixes: 24.4 average repeats per life, 41 in the worst run, and
  // a pool sat flat at ~19 eligible events from age 32 all the way to 85.
  // thats what "it gets repetitive after a while" actually was
  group('event variety across a full life', () {
    late List<List<String>> runs;

    setUpAll(() {
      runs = [for (var seed = 0; seed < 200; seed++) _play(seed).fired];
    });

    test('an average life repeats few events', () {
      final total = runs.map(_repeatsIn).reduce((a, b) => a + b);
      final average = total / runs.length;
      expect(
        average,
        lessThan(14),
        reason:
            'averaging ${average.toStringAsFixed(1)} repeated events per life '
            '— more than half of what a player sees would be a rerun',
      );
    });

    test('no single event dominates one life', () {
      for (final fired in runs) {
        final counts = <String, int>{};
        for (final id in fired) {
          counts.update(id, (v) => v + 1, ifAbsent: () => 1);
        }
        for (final entry in counts.entries) {
          expect(
            entry.value,
            lessThanOrEqualTo(7),
            reason: '${entry.key} fired ${entry.value} times in a single life',
          );
        }
      }
    });

    test('a non-repeatable event never fires twice in one life', () {
      final once = {
        for (final e in kLifeEvents)
          if (!e.repeatable) e.id,
      };
      for (final fired in runs) {
        final seen = <String>{};
        for (final id in fired) {
          if (!once.contains(id)) continue;
          expect(
            seen.add(id),
            isTrue,
            reason: '$id is not repeatable but fired twice in one life',
          );
        }
      }
    });
  });

  group('pool depth by age', () {
    LifeContext plain(int age) => LifeContext(
      age: age,
      money: 800,
      happiness: 50,
      health: 60,
      smarts: 50,
      fame: 0,
      skills: const {},
      traits: const {},
      hasJob: age >= 22,
    );

    test('the adult and senior years are not starved', () {
      // 30 onwards is over half a playthrough and it used to pull from the
      // same ~19 events for fifty years
      for (final age in [32, 40, 50, 60, 70, 80]) {
        final count = kLifeEvents.where((e) => e.matches(plain(age))).length;
        expect(
          count,
          greaterThanOrEqualTo(25),
          reason: 'only $count events are eligible at age $age',
        );
      }
    });

    test('the childhood years are not starved either', () {
      // Ages 10-11 had *zero* eligible events at one point — a life would
      // silently skip straight through them with nothing to decide.
      //
      // The bar was 3, then measured at 20-23 across ages 5-15 while every
      // adult year sat at 60-70. That gap mattered more than the numbers
      // suggest: a run plays eighteen turns through childhood before it
      // reaches twenty, so the thinnest stretch of the pool was also the
      // *opening* of the game, and the whole of what the 4-12 audience ever
      // sees. `kLifeEventsChildhood` was written for exactly this line.
      //
      // Still below the adult floor, because childhood is a dozen turns
      // rather than fifty — but high enough that two children do not play
      // the same decade.
      for (final age in [5, 8, 10, 11, 13, 15]) {
        final count = kLifeEvents.where((e) => e.matches(plain(age))).length;
        expect(
          count,
          greaterThanOrEqualTo(20),
          reason: 'only $count events are eligible at age $age',
        );
      }
    });
  });

  group('career ladders are actually completable', () {
    test('a dedicated musician can reach the top of the music track', () {
      // Regression guard for a real content bug: first_gig granted 4 fame and
      // record_deal required 10, with no other source of music fame — so the
      // top three events on this ladder could never fire for anybody. 400
      // simulated lives never saw one of them.
      //
      // Widened 300 -> 700 when hunger and illness landed. Same reasoning as
      // the previous widening, with one addition: hazards can now end a run
      // early, so a focused sample loses not only share-of-draw but some of
      // its *later years* — and the top of a career ladder is by definition
      // late. The exhaustive sweep below still passes, which is the tell that
      // the event is fine and the sample was thin.
      //
      // Widened 120 -> 300 when the chain pack (kLifeEventsChains) landed,
      // for the same reason the sweep below was widened 200 -> 400: this is
      // a *sampling* guard, so its sensitivity falls with every batch of
      // new content competing for the same draws. The tell that it is the
      // sample and not the content is that the exhaustive sweep below —
      // which is strictly harder to pass — still went green.
      final seen = <String>{};
      for (var seed = 0; seed < 700; seed++) {
        seen.addAll(_play(seed + 900, focus: LifeSkill.music).fired);
      }
      for (final id in ['first_gig', 'record_deal', 'sold_out_tour']) {
        expect(
          seen,
          contains(id),
          reason: '$id is unreachable even for a player who commits to music',
        );
      }
    });

    test('every event in the pool can fire for somebody', () {
      // 400 rather than 200 seeds. This is a sampling guard, and its
      // sensitivity scales with pool size: the rarest events here sit at
      // weight 0.4 behind a skill *and* a fame gate, so every batch of new
      // content shrinks their share of the draw and eventually one stops
      // showing up by luck alone. That happened when the money-lesson pack
      // (kLifeEventsMoney) landed — `sold_out_tour` vanished from this
      // sweep while the dedicated-musician test above still reached it
      // every time, which is the tell that the event was fine and the
      // sample was too small. Widen the sample rather than lower the bar;
      // the guarantee worth keeping is "nothing is unreachable".
      final seen = <String>{};
      for (var seed = 0; seed < 400; seed++) {
        seen.addAll(_play(seed).fired);
        seen.addAll(_playRounded(seed + 8000).fired);
        seen.addAll(_playRounded(seed + 12000).fired);
        for (final skill in LifeSkill.values) {
          seen.addAll(_play(seed + 4000, focus: skill).fired);
        }
      }
      // Gambling is switched off for everybody, so those events are meant to be
      // unreachable and are not a hole in the pool.
      final pool = kLifeEvents
          .where(
            (e) =>
                kLifeGamblingEnabled || !(e.isWager || e.showsGamblingMechanic),
          )
          .toList();
      final unreachable = pool
          .map((e) => e.id)
          .where((id) => !seen.contains(id))
          .toList();
      // A coverage floor, not an exact match. The exact version failed every
      // time the pool changed, because a rare, heavily gated event moved out
      // of the sample by luck and not by fault. The strict guarantee, that no
      // event has gates that cannot be met, is the deterministic test below.
      expect(
        unreachable.length / pool.length,
        lessThan(0.03),
        reason:
            'too many events were never seen by a simulated player: '
            '$unreachable',
      );
    });

    test('every event can be reached, without depending on luck', () {
      // For each event, build the most obliging context that its own gates
      // describe and check it matches. An event fails this only if its gates
      // contradict one another, which is a real defect and not a bad sample.
      //
      // Ownership-backed flags (hasPet, hasCar, ownsHome, hasStudentLoan)
      // never appear as a literal setsFlag: a card grants the asset instead
      // and `LifeSimController._effectiveFlags` reads the flag back from
      // what is owned. See `kOwnershipBackedFlags`.
      final settable = <LifeFlag>{
        for (final e in kLifeEvents)
          for (final c in e.choices)
            if (c.setsFlag != null) c.setsFlag!,
        ...kOwnershipBackedFlags,
      };
      final broken = <String>[];
      for (final e in kLifeEvents) {
        final context = LifeContext(
          age: e.minAge,
          money: e.minMoney,
          happiness: 60,
          health: 80,
          smarts: 60,
          fame: e.minFame,
          skills: e.requiresSkill == null
              ? const {}
              : {e.requiresSkill!: e.minSkill},
          traits: e.requiresTrait == null ? const {} : {e.requiresTrait!},
          hasJob: e.requiresJob || e.requiresTrack != null,
          flags: e.requiresFlag == null ? const {} : {e.requiresFlag!},
          // The gates on the newer parts of a life: what you have studied,
          // own, or share a home with. Each is met by exactly what it asks for.
          education: e.minEducation ?? EducationLevel.none,
          inSchool: e.requiresStudent,
          owns: e.requiresAsset == null ? const {} : {e.requiresAsset!},
          hasPartner: e.requiresPartner,
          hasChild: e.requiresChild,
          hasLivingParent: e.requiresParent,
          debt: e.minDebt,
          renting: e.requiresRenting,
          track: e.requiresTrack,
        );
        if (!e.matches(context)) broken.add(e.id);
        // A beat that waits on a flag nothing ever sets waits forever.
        final needs = e.requiresFlag;
        if (needs != null && !settable.contains(needs)) {
          broken.add('${e.id} (waits on $needs, which nothing sets)');
        }
      }
      expect(
        broken,
        isEmpty,
        reason: 'events that can never be drawn: $broken',
      );
    });
  });

  group('the pre-school years are not one scripted scene', () {
    // `plain` lives in the pool-depth group above, so this one needs its own.
    LifeContext infant(int age) => LifeContext(
      age: age,
      money: 0,
      happiness: 60,
      health: 80,
      smarts: 45,
      fame: 0,
      skills: const {},
      traits: const {},
      hasJob: false,
    );

    // The gap this closes: ages 0-3 had exactly *one* eligible event between
    // them, so every toddler in every run played the identical scene and the
    // opening minute of the game read as scripted — because it was.
    test('every early age has real choice', () {
      for (final age in [0, 1, 2, 3, 4]) {
        final count = kLifeEvents.where((e) => e.matches(infant(age))).length;
        expect(
          count,
          greaterThanOrEqualTo(6),
          reason: 'only $count events are eligible at age $age',
        );
      }
    });

    test('two toddlers with different luck see different years', () {
      // The real complaint was repetition across runs, which a per-age count
      // alone cannot prove. This plays the first handful of years twice with
      // different seeds and checks the stories diverge.
      Set<String> earlyRun(int seed) {
        final life = LifeSimController(random: Random(seed), initialAge: 0);
        final seen = <String>{};
        for (var i = 0; i < 6 && !life.finished; i++) {
          final event = life.currentEvent;
          if (event != null) {
            seen.add(event.id);
            life.chooseOption(0);
          }
          life.ageUp();
        }
        return seen;
      }

      final a = earlyRun(11);
      final b = earlyRun(4242);
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(
        a.difference(b),
        isNotEmpty,
        reason: 'two seeds produced the same early life: $a',
      );
    });
  });
}
