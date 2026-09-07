import 'package:flutter/foundation.dart';

import 'lesson.dart';
import 'lesson_data.dart';

class ProgressionService extends ChangeNotifier {
  ProgressionService({
    Iterable<String> initialCompletedLessons = const <String>[],
    Map<String, double> initialAccuracy = const <String, double>{},
  }) : _completedLessons = initialCompletedLessons.toSet(),
       _accuracy = Map<String, double>.from(initialAccuracy);

  final Set<String> _completedLessons;

  /// Best accuracy (0..1) per assessment node id. Mastery uses this so that
  /// clicking through a quiz is not the same as understanding it.
  final Map<String, double> _accuracy;

  final List<LessonUnit> _units = lessonUnits;

  List<LessonUnit> get units => List<LessonUnit>.unmodifiable(_units);

  List<Lesson> get lessons =>
      List<Lesson>.unmodifiable(_units.expand((unit) => unit.lessons));

  Set<String> get completedLessons =>
      Set<String>.unmodifiable(_completedLessons);

  Lesson? getLesson(String id) {
    try {
      return lessons.firstWhere((lesson) => lesson.id == id);
    } catch (_) {
      return null;
    }
  }

  LessonUnit? getUnit(String unitId) {
    try {
      return _units.firstWhere((unit) => unit.id == unitId);
    } catch (_) {
      return null;
    }
  }

  bool isCompleted(String lessonId) => _completedLessons.contains(lessonId);

  bool isAvailable(String lessonId) {
    final lesson = getLesson(lessonId);
    if (lesson == null) {
      return false;
    }

    for (final prereqId in lesson.prerequisites) {
      if (!_completedLessons.contains(prereqId)) {
        return false;
      }
    }

    return true;
  }

  LessonStatus getLessonStatus(String lessonId) {
    if (isCompleted(lessonId)) {
      return LessonStatus.completed;
    }
    if (isAvailable(lessonId)) {
      return LessonStatus.available;
    }
    return LessonStatus.locked;
  }

  void completeLesson(String lessonId) {
    if (_completedLessons.add(lessonId)) {
      notifyListeners();
    }
  }

  void replaceCompletedLessons(Iterable<String> lessonIds) {
    final next = lessonIds.toSet();
    if (setEquals(_completedLessons, next)) {
      return;
    }

    _completedLessons
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  Lesson? get nextLesson {
    for (final lesson in lessons) {
      if (getLessonStatus(lesson.id) == LessonStatus.available) {
        return lesson;
      }
    }
    return null;
  }

  double getProgress() {
    if (lessons.isEmpty) {
      return 0.0;
    }
    return _completedLessons.length / lessons.length;
  }

  double getUnitProgress(String unitId) {
    final unit = getUnit(unitId);
    if (unit == null || unit.lessons.isEmpty) {
      return 0.0;
    }

    final completed = unit.lessons
        .where((lesson) => _completedLessons.contains(lesson.id))
        .length;
    return completed / unit.lessons.length;
  }

  void replaceAccuracy(Map<String, double> accuracy) {
    if (mapEquals(_accuracy, accuracy)) {
      return;
    }
    _accuracy
      ..clear()
      ..addAll(accuracy);
    notifyListeners();
  }

  /// Best recorded accuracy for an assessment node, or null if never taken.
  double? accuracyFor(String nodeId) => _accuracy[nodeId];

  /// Mean accuracy across the unit's quizzes and tests that have been taken.
  /// Null when none have been attempted yet.
  double? getUnitAccuracy(String unitId) {
    final unit = getUnit(unitId);
    if (unit == null) {
      return null;
    }

    final scores = unit.lessons
        .where((lesson) => lesson.type != LessonNodeType.lesson)
        .map((lesson) => _accuracy[lesson.id])
        .whereType<double>()
        .toList(growable: false);

    if (scores.isEmpty) {
      return null;
    }
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Mastery combines coverage with performance: finishing every node earns
  /// "mastered" only when the assessments in it were actually answered well.
  MasteryLevel getUnitMastery(String unitId) {
    final progress = getUnitProgress(unitId);
    if (progress <= 0.0) {
      return MasteryLevel.novice;
    }

    final accuracy = getUnitAccuracy(unitId);

    if (progress >= 1.0) {
      // No assessment attempted yet cannot be full mastery.
      if (accuracy == null) {
        return MasteryLevel.proficient;
      }
      if (accuracy >= 0.85) {
        return MasteryLevel.mastered;
      }
      return accuracy >= 0.6 ? MasteryLevel.proficient : MasteryLevel.familiar;
    }

    if (progress >= 0.65) {
      if (accuracy != null && accuracy < 0.5) {
        return MasteryLevel.familiar;
      }
      return MasteryLevel.proficient;
    }

    return MasteryLevel.familiar;
  }

  int get completedCount => _completedLessons.length;

  int get totalCount => lessons.length;

  /// Teaching lessons only — no quizzes, no unit tests.
  ///
  /// **Why this exists.** The Academy had two "lesson" counts on screen that
  /// disagreed, and both were right about different things: the sourcing card
  /// said "63 lessons and N questions" (teaching nodes, because the questions
  /// are counted separately in the same sentence), and Your Learning Stats
  /// said "Lessons done: X/89" (every node, including 13 quizzes and 13 unit
  /// tests). A player reading both sees the app disagree with itself about
  /// how big its own curriculum is, which costs more credibility than either
  /// number is worth.
  ///
  /// Fixed by naming rather than by forcing them equal — the two totals
  /// measure genuinely different things and both are worth having. What was
  /// wrong was calling both of them "lessons". [totalCount] stays whole-path
  /// (it is what the progress bar and unlock rules run on, where a quiz is
  /// absolutely a step you have to complete); these two are the ones a
  /// *player-facing* lesson count should use.
  ///
  /// Both sides move together on purpose. Changing only the denominator
  /// would let a player who has finished quizzes see 71/63.
  int get teachingTotal =>
      lessons.where((l) => l.type == LessonNodeType.lesson).length;

  int get teachingCompleted => lessons
      .where(
        (l) =>
            l.type == LessonNodeType.lesson &&
            _completedLessons.contains(l.id),
      )
      .length;
}
