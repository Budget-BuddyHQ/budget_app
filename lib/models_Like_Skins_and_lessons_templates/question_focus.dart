import 'dart:math';

import '../services_backend_and_other_services/supabase_service.dart';
import 'finance_concepts.dart';
import 'knowledge_tracing.dart';
import 'leak_patrol_models.dart';
import 'money_snapshot_source.dart';
import 'player_profile.dart';
import 'quiz_bank.dart';
import 'skill_lessons.dart';

/// Where an arcade game's questions come from.
///
/// **Asked for as:** *"give them an option for the questions to be on the
/// things they need to work on, or just the questions in their age group."*
/// Finance Brawl, Coin Cascade and Leak Patrol all ask it; the Market Board
/// asks nothing, so it does not.
enum QuestionFocus {
  /// What this player has been getting wrong.
  weakSpots,

  /// Everything written for their age, as before.
  ageGroup;

  String get label => switch (this) {
    QuestionFocus.weakSpots => 'My weak spots',
    QuestionFocus.ageGroup => 'My age group',
  };

  static QuestionFocus fromName(String? name) => QuestionFocus.values
      .firstWhere((f) => f.name == name, orElse: () => QuestionFocus.ageGroup);
}

/// Fewer than this and a weak-spots run is topped up from the age group, so a
/// run does not ask the same two questions on a loop.
const int kWeakSpotMinimum = 6;

/// The concepts this player is struggling with, from their quiz history.
Set<FinanceConcept> strugglingConcepts(UserStats stats) {
  final knowledge = KnowledgeState.fromMap(stats.knowledgeMap);
  return {
    for (final k in knowledge.concepts.values)
      if (k.isStruggling) k.concept,
  };
}

/// Quiz skills this player needs to work on: the topics they missed, plus
/// every skill taught in a unit whose idea they are struggling with.
Set<String> weakSkillsFor(UserStats stats) {
  final skills = <String>{...stats.weakSkills};
  for (final concept in strugglingConcepts(stats)) {
    final unitId = unitIdForConcept(concept);
    if (unitId == null) continue;
    skills.addAll(kSkillLessonByUnit[unitId]?.keys ?? const <String>[]);
  }
  return skills;
}

/// The money ideas behind [weakSkillsFor], for games that are about ideas
/// rather than quiz skills (Leak Patrol's items each teach one).
Set<FinanceConcept> weakConceptsFor(UserStats stats) {
  final concepts = <FinanceConcept>{...strugglingConcepts(stats)};
  for (final skill in stats.weakSkills) {
    for (final entry in kSkillLessonByUnit.entries) {
      if (!entry.value.containsKey(skill)) continue;
      final concept = kUnitConcepts[entry.key];
      if (concept != null) concepts.add(concept);
    }
  }
  return concepts;
}

/// The questions for one run.
class FocusedQuestions {
  const FocusedQuestions({required this.questions, required this.toppedUp});

  final List<QuizQuestion> questions;

  /// Weak-spots mode had too few of its own and mixed in the age group.
  final bool toppedUp;
}

/// The Academy questions a game may ask in [focus].
///
/// Always starts from what [band] may be asked, so weak-spots mode can never
/// reach past the age gate: a ten-year-old who keeps missing "saving" gets
/// the saving questions written for ten-year-olds.
FocusedQuestions focusedQuestions({
  required AgeBand band,
  required QuestionFocus focus,
  required Set<String> weakSkills,
}) {
  final forAge = ageAppropriateQuestions(allQuizQuestions.toList(), band);
  if (focus == QuestionFocus.ageGroup) {
    return FocusedQuestions(questions: forAge, toppedUp: false);
  }
  final weak = [
    for (final q in forAge)
      if (weakSkills.contains(q.skillId)) q,
  ];
  if (weak.length >= kWeakSpotMinimum) {
    return FocusedQuestions(questions: weak, toppedUp: false);
  }
  return FocusedQuestions(
    questions: [
      ...weak,
      for (final q in forAge)
        if (!weakSkills.contains(q.skillId)) q,
    ],
    toppedUp: true,
  );
}

/// Picks one question for a single bonus question: a weak one when there is
/// one, so the top-up never crowds out the point of the mode.
QuizQuestion? pickFocusedQuestion(
  Random random,
  FocusedQuestions pool,
  Set<String> weakSkills, {
  Set<String> avoid = const <String>{},
}) {
  if (pool.questions.isEmpty) return null;
  final fresh = [
    for (final q in pool.questions)
      if (!avoid.contains(q.id)) q,
  ];
  final from = fresh.isEmpty ? pool.questions : fresh;
  final weak = [
    for (final q in from)
      if (weakSkills.contains(q.skillId)) q,
  ];
  final choices = weak.isNotEmpty ? weak : from;
  return choices[random.nextInt(choices.length)];
}

/// Share of Leak Patrol spawns drawn from the weak ideas in weak-spots mode.
const double kWeakLeakShare = 0.6;

/// The next thing to pop out of a hole.
///
/// With no weak ideas, or fewer than three items about them, this is the
/// uniform draw the game always made. Otherwise [kWeakLeakShare] of draws come
/// from the items about those ideas, so a player who keeps missing interest
/// meets the interest traps more often, and still sees the rest.
LeakItem pickLeakItem(
  Random random,
  List<LeakItem> pool,
  Set<FinanceConcept> weak,
) {
  if (weak.isNotEmpty) {
    final focused = [
      for (final item in pool)
        if (weak.contains(item.concept)) item,
    ];
    if (focused.length >= 3 && random.nextDouble() < kWeakLeakShare) {
      return focused[random.nextInt(focused.length)];
    }
  }
  return pool[random.nextInt(pool.length)];
}
