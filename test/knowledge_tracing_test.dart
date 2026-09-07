import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/knowledge_tracing.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';

/// Bayesian Knowledge Tracing and the prerequisite diagnosis.
///
/// **Why this is tested on properties rather than numbers.** Nobody can look
/// at `pKnown = 0.7314` and say whether it is right. What can be checked, and
/// what actually matters, is that the model behaves the way the maths
/// promises: that a correct answer is discounted by the chance of guessing
/// it, that a wrong answer carries more weight *in the odds*, that no single
/// mistake erases weeks of work, and that a diagnosis points at the earliest
/// missing idea rather than the visible symptom.
///
/// That second one is stated carefully. The intuitive phrasing — "belief
/// moves further down than up" — is false here, and an earlier version of
/// this file asserted it and failed. From a low prior there is simply more
/// room above the starting point than below it. Evidence strength lives in
/// the likelihood ratio, not in the change to the probability.
///
/// A drifting model here fails silently and expensively — it does not crash,
/// it just starts telling children they understand things they do not.
void main() {
  ConceptKnowledge fresh([
    FinanceConcept c = FinanceConcept.compoundGrowth,
  ]) => ConceptKnowledge(concept: c);

  ConceptKnowledge afterAll(
    Iterable<bool> answers, {
    FinanceConcept c = FinanceConcept.compoundGrowth,
  }) {
    var k = ConceptKnowledge(concept: c);
    for (final a in answers) {
      k = k.observe(a);
    }
    return k;
  }

  group('the guess rate is measured, not chosen', () {
    test('it matches the number of options the quiz bank actually uses', () {
      // If questions ever become three-option, 0.25 is wrong and the model
      // silently starts overrating everybody. This is the only parameter in
      // the model that is a fact about the content rather than a judgement,
      // so it is the one that can be checked against the content.
      final counts = <int, int>{};
      for (final q in allQuizQuestions) {
        counts[q.options.length] = (counts[q.options.length] ?? 0) + 1;
      }

      final commonest = counts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );

      expect(
        kDefaultBkt.guess,
        closeTo(1 / commonest.key, 0.001),
        reason:
            'most questions have ${commonest.key} options, so a blind answer '
            'is right ${(100 / commonest.key).round()}% of the time — but the '
            'model assumes ${(kDefaultBkt.guess * 100).round()}%',
      );
    });
  });

  group('evidence is weighed by how likely it was to be an accident', () {
    test('a single correct answer is weak evidence', () {
      final k = fresh().observe(true);
      // One right answer on a four-option question moves the needle, and
      // must not come close to mastery. A quarter of guessers would look
      // like learners otherwise.
      expect(k.pKnown, greaterThan(kDefaultBkt.prior));
      expect(k.pKnown, lessThan(ConceptKnowledge.masteredAt));
    });

    test('a wrong answer is stronger evidence, measured in odds', () {
      // Stated in odds on purpose. The tempting version of this test —
      // "belief moves further down than up" — is FALSE with these
      // parameters, and asserting it would have pinned a misunderstanding
      // into the suite. From a low prior there is more room above 0.25 than
      // below it, so the first correct answer moves pKnown by about +0.35
      // and the first wrong answer by about -0.09.
      //
      // The strength of evidence lives in the likelihood ratio, which is a
      // property of the model, not of where the prior happens to sit.
      double odds(double p) => p / (1 - p);

      final start = odds(kDefaultBkt.prior);
      // Undo the transition step, which is applied after the Bayes update
      // and is not evidence — it is the chance of having just learnt.
      double bayesOnly(bool correct) {
        final p = kDefaultBkt.prior;
        if (correct) {
          final n = p * (1 - kDefaultBkt.slip);
          return n / (n + (1 - p) * kDefaultBkt.guess);
        }
        final n = p * kDefaultBkt.slip;
        return n / (n + (1 - p) * (1 - kDefaultBkt.guess));
      }

      final upFactor = odds(bayesOnly(true)) / start;
      final downFactor = start / odds(bayesOnly(false));

      expect(upFactor, closeTo(3.6, 0.05));
      expect(downFactor, closeTo(7.5, 0.05));
      expect(
        downFactor,
        greaterThan(upFactor),
        reason:
            'a wrong answer should outweigh a right one, because a quarter '
            'of blind answers are right and almost nobody is wrong on '
            'purpose — if these are equal the model has stopped accounting '
            'for guessing',
      );
    });

    test('guessing is discounted: the same answer means less on 4 options', () {
      // The most direct statement of what this model buys. An identical
      // correct answer must move belief LESS when a quarter of wrong-headed
      // learners would have got it right anyway.
      const noGuessing = BktParameters(guess: 0.001);

      final withGuess = fresh().observe(true).pKnown;
      final without = fresh().observe(true, params: noGuessing).pKnown;

      expect(withGuess, lessThan(without));
    });

    test('sustained correct answers do reach mastery', () {
      // The model has to be able to conclude something, or it is just a
      // pessimism generator.
      final k = afterAll(List<bool>.filled(8, true));
      expect(k.isMastered, isTrue);
    });

    test('a coin-flip performance never reads as mastery', () {
      // 50% on four-option questions is barely above chance. A raw score
      // would call this "half understood"; the model should not.
      final k = afterAll(const [true, false, true, false, true, false]);
      expect(k.isMastered, isFalse);
    });

    test('one slip does not erase an established skill', () {
      final strong = afterAll(List<bool>.filled(8, true));
      final slipped = strong.observe(false);

      expect(slipped.pKnown, lessThan(strong.pKnown));
      expect(
        slipped.pKnown,
        greaterThan(0.5),
        reason:
            'a single careless answer wiped out eight correct ones — the '
            'slip parameter is doing nothing',
      );
    });

    test('belief never reaches certainty', () {
      // A pKnown of exactly 1 is unrecoverable: no later evidence could ever
      // move it, so the learner could never be found to have forgotten.
      final k = afterAll(List<bool>.filled(60, true));
      expect(k.pKnown, lessThan(1.0));
      expect(k.pKnown, greaterThan(0.9));
    });

    test('never assessed is different from assessed badly', () {
      expect(fresh().isUnseen, isTrue);
      expect(fresh().isStruggling, isFalse);
      expect(fresh().observe(false).isStruggling, isTrue);
    });
  });

  group('a whole quiz result', () {
    test('the same score from more questions is stronger evidence', () {
      final short = KnowledgeState.empty().observeQuiz(
        FinanceConcept.taxes,
        3,
        4,
      );
      final long = KnowledgeState.empty().observeQuiz(
        FinanceConcept.taxes,
        9,
        12,
      );

      expect(
        long.forConcept(FinanceConcept.taxes).pKnown,
        greaterThan(short.forConcept(FinanceConcept.taxes).pKnown),
        reason: '75% over twelve questions is far better evidence than 75% '
            'over four, and a raw percentage cannot tell them apart',
      );
    });

    test('a zero-question quiz changes nothing', () {
      final before = KnowledgeState.empty();
      final after = before.observeQuiz(FinanceConcept.taxes, 0, 0);
      expect(
        after.forConcept(FinanceConcept.taxes).observations,
        0,
      );
    });

    test('scores outside the range are clamped rather than trusted', () {
      final state = KnowledgeState.empty().observeQuiz(
        FinanceConcept.taxes,
        99,
        4,
      );
      expect(state.forConcept(FinanceConcept.taxes).observations, 4);
    });
  });

  group('the prerequisite graph', () {
    test('is acyclic', () {
      // A cycle would make the diagnosis walk meaningless, and the visited
      // set would paper over it — so it is checked directly.
      final visiting = <FinanceConcept>{};
      final done = <FinanceConcept>{};

      bool hasCycle(FinanceConcept c) {
        if (done.contains(c)) return false;
        if (!visiting.add(c)) return true;
        for (final p in kConceptPrerequisites[c] ?? const <FinanceConcept>[]) {
          if (hasCycle(p)) return true;
        }
        visiting.remove(c);
        done.add(c);
        return false;
      }

      for (final c in FinanceConcept.values) {
        expect(hasCycle(c), isFalse, reason: 'cycle reachable from ${c.name}');
      }
    });

    test('nothing is its own prerequisite', () {
      for (final entry in kConceptPrerequisites.entries) {
        expect(entry.value, isNot(contains(entry.key)));
      }
    });

    test('at least one concept is a root', () {
      // Every idea depending on another means there is nothing to teach
      // first, and the diagnosis walk would have no floor.
      final roots = FinanceConcept.values.where(
        (c) => (kConceptPrerequisites[c] ?? const []).isEmpty,
      );
      expect(roots, isNotEmpty);
      expect(roots, contains(FinanceConcept.needsVsWants));
    });
  });

  group('diagnosis finds the cause, not the symptom', () {
    test('it points upstream when the foundation is missing', () {
      // Failing compound growth having never grasped paying yourself first.
      var state = KnowledgeState.empty();
      for (var i = 0; i < 4; i++) {
        state = state.observe(FinanceConcept.compoundGrowth, false);
        state = state.observe(FinanceConcept.payYourselfFirst, false);
      }

      final d = state.diagnose(FinanceConcept.compoundGrowth);

      expect(d.struggling, FinanceConcept.compoundGrowth);
      expect(d.rootCause, isNot(FinanceConcept.compoundGrowth));
      expect(d.isUpstream, isTrue);
      // needsVsWants sits under payYourselfFirst, so the walk should reach
      // the very bottom of the chain.
      expect(d.rootCause, FinanceConcept.needsVsWants);
      expect(d.chain.first, FinanceConcept.compoundGrowth);
      expect(d.chain.last, d.rootCause);
    });

    test('it stops at the concept itself when the foundation is solid', () {
      var state = KnowledgeState.empty();
      for (var i = 0; i < 8; i++) {
        state = state.observe(FinanceConcept.needsVsWants, true);
        state = state.observe(FinanceConcept.payYourselfFirst, true);
      }
      for (var i = 0; i < 4; i++) {
        state = state.observe(FinanceConcept.compoundGrowth, false);
      }

      final d = state.diagnose(FinanceConcept.compoundGrowth);
      expect(d.rootCause, FinanceConcept.compoundGrowth);
      expect(d.isUpstream, isFalse,
          reason: 'the prerequisites are mastered, so the gap really is here');
    });

    test('an unassessed prerequisite counts as missing', () {
      // Not knowing whether somebody has a foundation is a reason to check,
      // not a reason to assume they have it.
      var state = KnowledgeState.empty();
      for (var i = 0; i < 4; i++) {
        state = state.observe(FinanceConcept.compoundGrowth, false);
      }
      final d = state.diagnose(FinanceConcept.compoundGrowth);
      expect(d.isUpstream, isTrue);
    });

    test('it follows the weakest prerequisite, not the first listed', () {
      // budgetRule depends on needsVsWants and payYourselfFirst. Making one
      // strong and the other weak must send the walk to the weak one,
      // whichever order they happen to appear in the list.
      var state = KnowledgeState.empty();
      for (var i = 0; i < 8; i++) {
        state = state.observe(FinanceConcept.needsVsWants, true);
      }
      for (var i = 0; i < 5; i++) {
        state = state.observe(FinanceConcept.payYourselfFirst, false);
        state = state.observe(FinanceConcept.budgetRule, false);
      }

      final d = state.diagnose(FinanceConcept.budgetRule);
      expect(d.chain, contains(FinanceConcept.payYourselfFirst));
      expect(d.chain, isNot(contains(FinanceConcept.needsVsWants)));
    });

    test('nextToTeach is quiet when nothing is going wrong', () {
      var state = KnowledgeState.empty();
      for (final c in FinanceConcept.values) {
        for (var i = 0; i < 8; i++) {
          state = state.observe(c, true);
        }
      }
      expect(state.nextToTeach(), isNull);
      expect(state.mastered, hasLength(FinanceConcept.values.length));
    });

    test('nextToTeach returns a root cause, not the worst symptom', () {
      var state = KnowledgeState.empty();
      for (var i = 0; i < 6; i++) {
        state = state.observe(FinanceConcept.taxes, false);
        state = state.observe(FinanceConcept.needsVsWants, false);
      }
      final d = state.nextToTeach();
      expect(d, isNotNull);
      expect(d!.rootCause, FinanceConcept.needsVsWants);
    });
  });

  group('storage', () {
    test('a round trip preserves belief', () {
      var state = KnowledgeState.empty()
          .observeQuiz(FinanceConcept.creditScore, 3, 4)
          .observeQuiz(FinanceConcept.inflation, 1, 5);

      final restored = KnowledgeState.fromMap(state.toMap());
      for (final c in FinanceConcept.values) {
        expect(
          restored.forConcept(c).pKnown,
          closeTo(state.forConcept(c).pKnown, 0.001),
        );
        expect(
          restored.forConcept(c).observations,
          state.forConcept(c).observations,
        );
      }
    });

    test('only assessed concepts are written', () {
      final state = KnowledgeState.empty().observe(FinanceConcept.taxes, true);
      expect(state.toMap().keys, ['taxes']);
    });

    test('corrupt storage reads as unassessed rather than throwing', () {
      // This comes back from a jsonb column, so it holds whatever any version
      // of the app ever put there. A throw here takes the Coach screen down.
      final restored = KnowledgeState.fromMap(<String, dynamic>{
        'taxes': 'not a map',
        'inflation': {'p': 'high', 'n': 'lots'},
        'creditScore': {'p': 5.0, 'n': -3},
      });

      expect(restored.forConcept(FinanceConcept.taxes).isUnseen, isTrue);
      expect(restored.forConcept(FinanceConcept.inflation).pKnown,
          kDefaultBkt.prior);
      // Out-of-range values are clamped, not trusted.
      expect(restored.forConcept(FinanceConcept.creditScore).pKnown,
          lessThanOrEqualTo(0.999));
      expect(restored.forConcept(FinanceConcept.creditScore).observations, 0);
    });
  });
}
