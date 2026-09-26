import 'dart:math' as math;

import 'finance_concepts.dart';

// tracks if a kid actually knows a concept or just guessed right.
// 4 answer choices means blind guessing gets you 25%, so a raw score
// cant tell "knows it" from "got lucky twice". this can.
// classic bkt model (corbett & anderson 95), still what most tutoring
// apps use under the hood. also walks a prereq graph so it can say
// WHY someone's stuck, not just that they are.
class BktParameters {
  const BktParameters({
    this.prior = 0.25,
    this.transition = 0.12,
    this.guess = 0.25,
    this.slip = 0.10,
  });

  // starts assuming they dont know it. safer wrong guess than the other way
  final double prior;

  // odds they pick it up between questions, kept low on purpose
  final double transition;

  // 1 in 4 = guessing right on a 4-option quiz. matches quiz_bank
  final double guess;

  // small chance of a dumb mistake even when they actually know it
  final double slip;
}

const BktParameters kDefaultBkt = BktParameters();

// what you gotta know before you can get this one. kept shallow on purpose,
// if everything depends on everything it stops being useful

const Map<FinanceConcept, List<FinanceConcept>> kConceptPrerequisites =
    <FinanceConcept, List<FinanceConcept>>{
      // needsVsWants is the root of basically everything else here
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

      // cant compound anything til youre actually setting money aside
      FinanceConcept.compoundGrowth: [FinanceConcept.payYourselfFirst],
      FinanceConcept.interestCost: [FinanceConcept.compoundGrowth],
      FinanceConcept.inflation: [FinanceConcept.compoundGrowth],
      FinanceConcept.diversification: [FinanceConcept.compoundGrowth],

      // credit score = price of borrowing, gotta get interest cost first
      FinanceConcept.creditScore: [FinanceConcept.interestCost],

      FinanceConcept.incomeVsWealth: [
        FinanceConcept.budgetRule,
        FinanceConcept.compoundGrowth,
      ],
      FinanceConcept.taxes: [FinanceConcept.incomeVsWealth],
      FinanceConcept.insurance: [FinanceConcept.emergencyFund],
    };

// one concept's estimated mastery
class ConceptKnowledge {
  const ConceptKnowledge({
    required this.concept,
    this.pKnown = 0.25,
    this.observations = 0,
  });

  // 85% = mastered, set high so we dont stop teaching too early
  static const double masteredAt = 0.85;

  // below this its an actual gap, not "still learning"
  static const double strugglingBelow = 0.35;

  final FinanceConcept concept;

  // 0 to 1, how sure we are they know it
  final double pKnown;

  // how many answers went into this. 0 = still just the starting guess
  final int observations;

  bool get isMastered => pKnown >= masteredAt;
  bool get isStruggling => observations > 0 && pKnown < strugglingBelow;
  bool get isUnseen => observations == 0;

  // applies one answer, spits out the updated belief
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

    // they just saw the right answer, so even a miss might've taught them
    final next = posterior + (1 - posterior) * params.transition;

    return ConceptKnowledge(
      concept: concept,
      // never let it hit exactly 1, 4 mc questions cant prove real certainty
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

// the concept thats actually blocking progress, not just whats failing
class LearningDiagnosis {
  const LearningDiagnosis({
    required this.struggling,
    required this.rootCause,
    required this.chain,
  });

  // what theyre visibly failing
  final FinanceConcept struggling;

  // earliest thing upstream thats actually missing. same as struggling
  // if the prereqs are fine, thats a valid answer too
  final FinanceConcept rootCause;

  // path from the symptom down to the root cause
  final List<FinanceConcept> chain;

  bool get isUpstream => rootCause != struggling;
}

// every concept's mastery + what to do about it
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

  // logs a whole quiz as separate answers. wrong ones go in first on purpose
  // so 2 wrong then 2 right reads as "learned it mid-quiz" not random luck
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

  // walks prereqs to find the earliest unmastered thing. never-tested
  // counts as unmastered, visited set so it cant loop forever
  LearningDiagnosis diagnose(FinanceConcept struggling) {
    final visited = <FinanceConcept>{};
    final chain = <FinanceConcept>[struggling];

    FinanceConcept walk(FinanceConcept current) {
      if (!visited.add(current)) return current;

      final prereqs = kConceptPrerequisites[current] ?? const [];
      // go with whichever prereq is weakest, not just the first one listed
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

  // whats actually worth teaching next, or null if nothings pressing
  LearningDiagnosis? nextToTeach() {
    final struggling =
        concepts.values.where((k) => k.isStruggling).toList()
          ..sort((a, b) => a.pKnown.compareTo(b.pKnown));
    if (struggling.isEmpty) return null;
    return diagnose(struggling.first.concept);
  }

  // concepts we think are mastered
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
