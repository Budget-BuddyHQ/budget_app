import 'lesson.dart';
import 'package:flutter/foundation.dart';

/// Service to manage user progression through lessons
/// Tracks which lessons are completed, available, or locked
class ProgressionService extends ChangeNotifier {
  final Set<String> _completedLessons = {};
  final List<Lesson> _lessons = [];

  ProgressionService() {
    _initializeLessons();
  }

  /// Initialize the default lessons for the learning path
  void _initializeLessons() {
    _lessons.addAll([
      Lesson(
        id: 'lesson_1',
        title: 'Introduction to Budgeting',
        order: 1,
        status: LessonStatus.available,
      ),
      Lesson(
        id: 'lesson_2',
        title: 'Understanding Income',
        order: 2,
        prerequisites: ['lesson_1'],
      ),
      Lesson(
        id: 'lesson_3',
        title: 'Expenses and Spending',
        order: 3,
        prerequisites: ['lesson_2'],
      ),
      Lesson(
        id: 'lesson_4',
        title: 'Saving Strategies',
        order: 4,
        prerequisites: ['lesson_3'],
      ),
      Lesson(
        id: 'lesson_5',
        title: 'Building Your Budget',
        order: 5,
        prerequisites: ['lesson_4'],
      ),
      Lesson(
        id: 'lesson_6',
        title: 'Credit and Debt Management',
        order: 6,
        prerequisites: ['lesson_5'],
      ),
      Lesson(
        id: 'lesson_7',
        title: 'Introduction to Investing',
        order: 7,
        prerequisites: ['lesson_6'],
      ),
      Lesson(
        id: 'lesson_8',
        title: 'Banking and Financial Tools',
        order: 8,
        prerequisites: ['lesson_7'],
      ),
      Lesson(
        id: 'lesson_9',
        title: 'Emergency Planning',
        order: 9,
        prerequisites: ['lesson_8'],
      ),
      Lesson(
        id: 'lesson_10',
        title: 'Long-Term Financial Goals',
        order: 10,
        prerequisites: ['lesson_9'],
      ),
    ]);
    _updateLessonStatuses();
  }

  /// Get all lessons
  List<Lesson> get lessons => List.unmodifiable(_lessons);

  /// Get a specific lesson by ID
  Lesson? getLesson(String id) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a lesson is completed
  bool isCompleted(String lessonId) {
    return _completedLessons.contains(lessonId);
  }

  /// Check if a lesson is available (unlocked)
  bool isAvailable(String lessonId) {
    final lesson = getLesson(lessonId);
    if (lesson == null) return false;

    // Check if all prerequisites are completed
    for (final prereqId in lesson.prerequisites) {
      if (!_completedLessons.contains(prereqId)) {
        return false;
      }
    }

    return true;
  }

  /// Get the status of a lesson
  LessonStatus getLessonStatus(String lessonId) {
    if (isCompleted(lessonId)) {
      return LessonStatus.completed;
    } else if (isAvailable(lessonId)) {
      return LessonStatus.available;
    } else {
      return LessonStatus.locked;
    }
  }

  /// Mark a lesson as completed
  void completeLesson(String lessonId) {
    if (!_completedLessons.contains(lessonId)) {
      _completedLessons.add(lessonId);
      _updateLessonStatuses();
      notifyListeners();
    }
  }

  /// Update all lesson statuses based on completion and prerequisites
  void _updateLessonStatuses() {
    for (var lesson in _lessons) {
      final status = getLessonStatus(lesson.id);
      // Note: We can't directly modify the status field since it's final
      // The status is computed dynamically via getLessonStatus
    }
  }

  /// Get progress percentage (0.0 to 1.0)
  double getProgress() {
    if (_lessons.isEmpty) return 0.0;
    return _completedLessons.length / _lessons.length;
  }

  /// Get number of completed lessons
  int get completedCount => _completedLessons.length;

  /// Get total number of lessons
  int get totalCount => _lessons.length;
}
