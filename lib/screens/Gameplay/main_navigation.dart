import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'customize_screen.dart';
import 'game_hub_page.dart';
import 'home_screen.dart';
import 'learning_path_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(
          activeTabIndex: 0,
          onNavSelected: _selectTab,
        ),
        GameHubPage(
          activeTabIndex: 1,
          onNavSelected: _selectTab,
        ),
        CustomizeScreen(
          activeTabIndex: 2,
          onNavSelected: _selectTab,
        ),
        LearningPathScreen(
          activeTabIndex: 3,
          onNavSelected: _selectTab,
        ),
        ProfileScreen(
          activeTabIndex: 4,
          onNavSelected: _selectTab,
        ),
      ],
    );
  }
}
