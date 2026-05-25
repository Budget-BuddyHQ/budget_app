import 'package:flutter/material.dart';

import '../../../navigation_tools_and_animation/app_tab_index.dart';
import 'lesson_screen.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({
    super.key,
    this.activeTabIndex = AppTabIndex.academy,
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
