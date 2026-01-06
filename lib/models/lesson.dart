/// Lesson model representing a single lesson in the learning path
class Lesson {
  final String id;
  final String title;
  final int order; // Position in the learning path
  final LessonStatus status;
  final List<String> prerequisites; // IDs of lessons that must be completed first

  Lesson({
    required this.id,
    required this.title,
    required this.order,
    this.status = LessonStatus.locked,
    this.prerequisites = const [],
  });
}

enum LessonStatus {
  completed, // Lesson is finished
  available, // Lesson can be started (unlocked)
  locked, // Lesson is locked (prerequisites not met)
}
