import 'package:flutter/foundation.dart';

import 'lesson.dart';
import 'lesson_data.dart';

class ProgressionService extends ChangeNotifier {
  final Set<String> _completedLessons = <String>{};
  final List<LessonUnit> _units = lessonUnits;

  List<LessonUnit> get units => List<LessonUnit>.unmodifiable(_units);

  List<Lesson> get lessons => List<Lesson>.unmodifiable(
        _units.expand((unit) => unit.lessons),
      );

  Lesson? getLesson(String id) {
    try {
      return lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  LessonUnit? getUnit(String unitId) {
    try {
      return _units.firstWhere((unit) => unit.id == unitId);
    } catch (e) {
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

  MasteryLevel getUnitMastery(String unitId) {
    final progress = getUnitProgress(unitId);
    if (progress >= 1.0) {
      return MasteryLevel.mastered;
    }
    if (progress >= 0.65) {
      return MasteryLevel.proficient;
    }
    if (progress > 0.0) {
      return MasteryLevel.familiar;
    }
    return MasteryLevel.novice;
  }

  int get completedCount => _completedLessons.length;

  int get totalCount => lessons.length;
}
