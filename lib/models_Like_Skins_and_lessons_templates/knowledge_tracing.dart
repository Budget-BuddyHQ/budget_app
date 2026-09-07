import 'dart:math' as math;

import 'finance_concepts.dart';

/// Bayesian Knowledge Tracing, plus a prerequisite graph to diagnose *why*
/// somebody is stuck.
///
/// # The problem with a score
///
/// Every quiz in this app has **four options**, so a pure guess is right a
/// quarter of the time. Answer four questions blind and the most likely
/// outcome is 1/4 — but a fifth of the time it is 2/4, which the Academy
/// records as 50% and the coach reads as "half understood". Nothing anywhere
/// distinguishes *knowing* from *being lucky*, and the difference matters
/// most for the learners who need help most: a child who guesses their way to
/// 50% twice looks like steady progress and is learning nothing.
///
/// A score is also a claim about one afternoon. It cannot say whether the
/// knowledge is *stable*, and it cannot say what to do next.
///
/// # What this does instead
///
/// Bayesian Knowledge Tracing — the model underneath intelligent tutoring
/// systems since Corbett & Anderson (1995), and still the standard baseline
/// in educational data mining — tracks a single hidden variable per concept:
/// **P(known)**, the probability that the learner has actually acquired the
/// skill. Every answer is evidence, and the evidence is weighed by how likely
/// it was to happen by accident.
///
/// Four parameters:
///
/// * **P(L0)**, the prior. What we believe before any evidence.
/// * **P(T)**, transition. The chance of learning the idea between one
///   question and the next — because a learner who reads the explanation
///   after getting it wrong has genuinely changed.
/// * **P(G)**, guess. P(correct | *not* known). Here it is **0.25 exactly**,
///   because the questions have four options — this is measured from the
///   quiz bank rather than tuned, which is unusual and is the reason this
///   model is honest for this app specifically.
/// * **P(S)**, slip. P(wrong | known). Mis-taps, misread questions,
///   distraction. Small but never zero, and without it a single careless
///   answer would erase a well-established skill.
///
/// The update is Bayes' rule, then the learning step:
///
/// ```
/// correct   →  P(L|obs) = P(L)(1-S) / [ P(L)(1-S) + (1-P(L))G     ]
/// incorrect →  P(L|obs) = P(L)S     / [ P(L)S     + (1-P(L))(1-G) ]
/// then         P(L')    = P(L|obs) + (1 - P(L|obs)) * T
/// ```
///
/// The consequence worth stating out loud, **stated carefully because the
/// obvious phrasing of it is wrong.** In *likelihood-ratio* terms a wrong
/// answer is much stronger evidence than a right one: with these parameters a
/// correct answer is 3.6x evidence for knowing, while a wrong answer is 7.5x
/// evidence against. There are many ways to be right by accident and very few
/// ways to be wrong on purpose.
///
/// That is **not** the same as saying belief moves further downward. From a
/// low prior it does not — there is more room above 0.25 than below it, so a
/// first correct answer shifts `pKnown` by about +0.35 and a first wrong
/// answer by about -0.09. Both facts are true at once, and confusing them is
/// easy: the strength of evidence lives in the odds, not in the probability.
/// `knowledge_tracing_test.dart` asserts the odds version, because that is
/// the one that is actually a property of the model rather than of where the
/// prior happens to sit.
///
/// # Why a prerequisite graph
///
/// Knowing that somebody keeps failing compound growth is not much use on its
/// own. What a good tutor does next is ask *why*, and the answer is almost
/// always something earlier: you cannot understand compound growth if
/// "pay yourself first" has not landed, because there is nothing to compound.
///
/// [kConceptPrerequisites] is a DAG over the sixteen ideas, and
/// [KnowledgeState.diagnose] walks it to find the **deepest unmastered
/// prerequisite** — the earliest thing in the chain that is missing. That is
/// the thing to teach. Sending somebody back to compound growth when the real
/// gap is two steps upstream is how learners conclude they are bad at maths.
///
/// # Why it is on the device
///
/// Four multiplications per answer. No model to download, no API, no data
/// leaving the phone, and it works offline. The whole point of choosing a
/// 1995 model over something larger is that it is the *right size* for the
/// problem — and it can be explained, in full, to the person it is scoring.

/// The BKT parameters.
///
/// Named rather than inlined so the reasoning behind each number is
/// reviewable, and so a test can assert the guess rate still matches the
/// quiz bank it was derived from.
class BktParameters {
  const BktParameters({
    this.prior = 0.25,
    this.transition = 0.12,
    this.guess = 0.25,
    this.slip = 0.10,
  });

  /// P(L0). Deliberately low.
  ///
  /// A new learner is assumed *not* to know a money concept, because for this
  /// audience that is nearly always true, and the cost of the two errors is
  /// not symmetric: teaching something already known wastes a minute, while
  /// assuming knowledge that is absent means never teaching it at all.
  final double prior;

  /// P(T). The chance of picking the idea up between two questions.
  ///
  /// Non-zero because getting a question wrong in this app shows you the
  /// explanation — so a learner really has had an opportunity to change. Kept
  /// modest: at 0.12, mastery cannot be reached by attrition alone, which a
  /// high transition value would allow.
  final double transition;

  /// P(G) = P(correct | not known). **Measured, not chosen.**
  ///
  /// Every question in `quiz_bank.dart` has four options bar one, so a blind
  /// answer is right a quarter of the time. `knowledge_tracing_test.dart`
  /// asserts this still matches the bank — if questions ever become
  /// three-option, this number is wrong and the model quietly starts
  /// overrating everybody.
  final double guess;

  /// P(S) = P(wrong | known). Mis-taps and misreadings.
  ///
  /// Small, but zero would be a claim that a person who understands something
  /// can never fumble a question — and under that assumption one careless
  /// answer wipes out a skill established over weeks.
  final double slip;
}

const BktParameters kDefaultBkt = BktParameters();

/// What must be understood before a concept can be.
///
/// A DAG, and deliberately shallow. Every edge here is a claim that the
/// second idea is genuinely unreachable without the first, not merely
/// related — a graph where everything depends on everything diagnoses
/// nothing, because the walk always bottoms out in the same place.
///
/// Concepts with no entry are roots: they can be taught to somebody who knows
/// nothing at all about money.
const Map<FinanceConcept, List<FinanceConcept>> kConceptPrerequisites =
    <FinanceConcept, List<FinanceConcept>>{
      // needsVsWants is the root of the whole subject. Everything about
      // choosing between things rests on being able to tell them apart.
      FinanceConcept.opportunityCost: [FinanceConcept.needsVsWants],
      FinanceConcept.payYourselfFirst: [FinanceConcept.needsVsWants],

      FinanceConcept.budgetRule: [
        FinanceConcept.needsVsWants,
        FinanceConcept.payYourselfFirst,
      ],
      FinanceConcept.impulseSpending: [
        FinanceConcept.needsVsWants,
        FinanceConcept.opportunityCost,
      ],
      FinanceConcept.sunkCost: [FinanceConcept.opportunityCost],

      FinanceConcept.emergencyFund: [
        FinanceConcept.payYourselfFirst,
        FinanceConcept.budgetRule,
      ],
      FinanceConcept.lifestyleCreep: [
        FinanceConcept.budgetRule,
        FinanceConcept.impulseSpending,
      ],

      // Nothing compounds until something is being set aside.
      FinanceConcept.compoundGrowth: [FinanceConcept.payYourselfFirst],
      FinanceConcept.interestCost: [FinanceConcept.compoundGrowth],
      FinanceConcept.inflation: [FinanceConcept.compoundGrowth],
      FinanceConcept.diversification: [FinanceConcept.compoundGrowth],

      // A credit score is a price on borrowing, so the cost of borrowing has
      // to mean something first.
      FinanceConcept.creditScore: [FinanceConcept.interestCost],

      FinanceConcept.incomeVsWealth: [
        FinanceConcept.budgetRule,
        FinanceConcept.compoundGrowth,
      ],
      FinanceConcept.taxes: [FinanceConcept.incomeVsWealth],
      FinanceConcept.insurance: [FinanceConcept.emergencyFund],
    };

/// One concept's estimated mastery.
class ConceptKnowledge {
  const ConceptKnowledge({
    required this.concept,
    this.pKnown = 0.25,
    this.observations = 0,
  });

  /// Mastery threshold.
  ///
  /// 0.85 is the conventional BKT cut-off and it is high on purpose. This
  /// number gates whether the app stops teaching something, and the cost of
  /// stopping too early — a gap that silently blocks everything downstream of
  /// it — is much worse than the cost of one extra review.
  static const double masteredAt = 0.85;

  /// Below this, the concept is treated as a genuine gap rather than
  /// "in progress". Roughly the prior: no better than knowing nothing.
  static const double strugglingBelow = 0.35;

  final FinanceConcept concept;

  /// P(the learner knows this), 0..1.
  final double pKnown;

  /// How many answers have contributed. Zero means the prior, untouched.
  final int observations;

  bool get isMastered => pKnown >= masteredAt;
  bool get isStruggling => observations > 0 && pKnown < strugglingBelow;
  bool get isUnseen => observations == 0;

  /// Applies one answer and returns the updated belief.
  ConceptKnowledge observe(
    bool correct, {
    BktParameters params = kDefaultBkt,
  }) {
    final prior = observations == 0 ? params.prior : pKnown;

    final double posterior;
    if (correct) {
      final num = prior * (1 - params.slip);
      final den = num + (1 - prior) * params.guess;
      posterior = den <= 0 ? prior : num / den;
    } else {
      final num = prior * params.slip;
      final den = num + (1 - prior) * (1 - params.guess);
      posterior = den <= 0 ? prior : num / den;
    }

    // The learning step: having just been shown the answer, there is a real
    // chance the idea landed even on a miss.
    final next = posterior + (1 - posterior) * params.transition;

    return ConceptKnowledge(
      concept: concept,
      // Clamped strictly below 1: certainty is not something four multiple
      // choice questions can buy, and a pKnown of exactly 1 is unrecoverable
      // — no amount of later evidence could ever move it.
      pKnown: next.clamp(0.0, 0.999),
      observations: observations + 1,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'p': double.parse(pKnown.toStringAsFixed(4)),
    'n': observations,
  };

  static ConceptKnowledge fromMap(
    FinanceConcept concept,
    Map<String, dynamic> map,
  ) {
    num? asNum(Object? v) =>
        v is num ? v : (v is String ? num.tryParse(v) : null);

    return ConceptKnowledge(
      concept: concept,
      pKnown: (asNum(map['p'])?.toDouble() ?? kDefaultBkt.prior).clamp(
        0.0,
        0.999,
      ),
      observations: math.max(0, asNum(map['n'])?.toInt() ?? 0),
    );
  }
}

/// A diagnosis: the concept that is actually blocking progress.
class LearningDiagnosis {
  const LearningDiagnosis({
    required this.struggling,
    required this.rootCause,
    required this.chain,
  });

  /// The concept the learner is visibly failing.
  final FinanceConcept struggling;

  /// The earliest unmastered thing it depends on.
  ///
  /// Equal to [struggling] when the prerequisites are all solid — which is a
  /// real and useful answer: it means the gap is here, not upstream.
  final FinanceConcept rootCause;

  /// The path from the visible symptom down to the root cause.
  final List<FinanceConcept> chain;

  bool get isUpstream => rootCause != struggling;
}

/// Every concept's estimated mastery, and what to do about it.
class KnowledgeState {
  const KnowledgeState(this.concepts);

  factory KnowledgeState.empty() =>
      KnowledgeState(<FinanceConcept, ConceptKnowledge>{
        for (final c in FinanceConcept.values)
          c: ConceptKnowledge(concept: c),
      });

  final Map<FinanceConcept, ConceptKnowledge> concepts;

  ConceptKnowledge forConcept(FinanceConcept c) =>
      concepts[c] ?? ConceptKnowledge(concept: c);

  KnowledgeState observe(
    FinanceConcept concept,
    bool correct, {
    BktParameters params = kDefaultBkt,
  }) {
    final next = Map<FinanceConcept, ConceptKnowledge>.from(concepts);
    next[concept] = forConcept(concept).observe(correct, params: params);
    return KnowledgeState(next);
  }

  /// Records a whole quiz result as individual answers.
  ///
  /// Order matters to BKT — the transition step runs between observations —
  /// and misses are applied **first** on purpose. A learner who gets two
  /// wrong then two right has most plausibly learnt something during the
  /// quiz, and that ordering lets the model see it that way rather than
  /// treating the run as a coin landing in an arbitrary sequence.
  KnowledgeState observeQuiz(
    FinanceConcept concept,
    int correct,
    int total, {
    BktParameters params = kDefaultBkt,
  }) {
    if (total <= 0) return this;
    final right = correct.clamp(0, total);
    var state = this;
    for (var i = 0; i < total - right; i++) {
      state = state.observe(concept, false, params: params);
    }
    for (var i = 0; i < right; i++) {
      state = state.observe(concept, true, params: params);
    }
    return state;
  }

  /// Walks the prerequisite graph for the earliest thing that is missing.
  ///
  /// Depth-first, deepest-unmastered-wins. A prerequisite that has never been
  /// assessed counts as unmastered — not knowing whether somebody has a
  /// foundation is a reason to check, not a reason to assume.
  ///
  /// Cycle-safe by construction *and* by a visited set. The graph is a DAG
  /// today, and a future edit that accidentally closes a loop should produce
  /// a slightly odd diagnosis rather than a hung app.
  LearningDiagnosis diagnose(FinanceConcept struggling) {
    final visited = <FinanceConcept>{};
    final chain = <FinanceConcept>[struggling];

    FinanceConcept walk(FinanceConcept current) {
      if (!visited.add(current)) return current;

      final prereqs = kConceptPrerequisites[current] ?? const [];
      // Among unmastered prerequisites, follow the weakest — the one the
      // learner is furthest from having. Following the first listed instead
      // would make the diagnosis depend on the order somebody typed a list.
      ConceptKnowledge? weakest;
      for (final prereq in prereqs) {
        if (visited.contains(prereq)) continue;
        final k = forConcept(prereq);
        if (k.isMastered) continue;
        if (weakest == null || k.pKnown < weakest.pKnown) weakest = k;
      }

      if (weakest == null) return current;
      chain.add(weakest.concept);
      return walk(weakest.concept);
    }

    final root = walk(struggling);
    return LearningDiagnosis(
      struggling: struggling,
      rootCause: root,
      chain: List<FinanceConcept>.unmodifiable(chain),
    );
  }

  /// The concept most worth teaching next, or null when nothing is pressing.
  ///
  /// Struggling concepts first, weakest first — then diagnosed down to their
  /// root cause, so the answer is the thing to actually teach rather than the
  /// thing that happens to be visible.
  LearningDiagnosis? nextToTeach() {
    final struggling =
        concepts.values.where((k) => k.isStruggling).toList()
          ..sort((a, b) => a.pKnown.compareTo(b.pKnown));
    if (struggling.isEmpty) return null;
    return diagnose(struggling.first.concept);
  }

  /// Concepts believed mastered.
  List<FinanceConcept> get mastered => concepts.values
      .where((k) => k.isMastered)
      .map((k) => k.concept)
      .toList();

  Map<String, dynamic> toMap() => <String, dynamic>{
    for (final entry in concepts.entries)
      if (!entry.value.isUnseen) entry.key.name: entry.value.toMap(),
  };

  static KnowledgeState fromMap(Map<String, dynamic> map) {
    final out = <FinanceConcept, ConceptKnowledge>{};
    for (final concept in FinanceConcept.values) {
      final raw = map[concept.name];
      out[concept] = raw is Map
          ? ConceptKnowledge.fromMap(
              concept,
              Map<String, dynamic>.from(raw),
            )
          : ConceptKnowledge(concept: concept);
    }
    return KnowledgeState(out);
  }
}
