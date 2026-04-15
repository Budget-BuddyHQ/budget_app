import 'package:flutter/material.dart';

import 'lesson_screen.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({
    super.key,
    this.activeTabIndex = 3,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
