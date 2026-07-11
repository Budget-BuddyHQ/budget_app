import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:flutter/material.dart';

import '../../../navigation_tools_and_animation/app_tab_index.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = AppTabIndex.dashboard});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, AppTabIndex.count - 1).toInt();
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
          activeTabIndex: AppTabIndex.dashboard,
          onNavSelected: _selectTab,
        ),
        MainGamePage(
          activeTabIndex: AppTabIndex.adventure,
          onNavSelected: _selectTab,
        ),
        MinigamesPage(
          activeTabIndex: AppTabIndex.minigames,
          onNavSelected: _selectTab,
        ),
        CustomizeScreen(
          activeTabIndex: AppTabIndex.customize,
          onNavSelected: _selectTab,
        ),
        LearningPathScreen(
          activeTabIndex: AppTabIndex.academy,
          onNavSelected: _selectTab,
        ),
        ProfileScreen(
          activeTabIndex: AppTabIndex.profile,
          onNavSelected: _selectTab,
        ),
      ],
    );
  }
}
