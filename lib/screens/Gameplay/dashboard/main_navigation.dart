import 'package:flutter/material.dart';

import '../../profile/profile_screen.dart';
import '../academy/learning_path_screen.dart';
import '../core/game_hub_page.dart';
import '../customize_screen.dart';
import 'home_screen.dart';

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

  Future<void> _openPortal() async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => GameHubPage(
          activeTabIndex: _currentIndex,
          onNavSelected: (index) {
            Navigator.of(context).pop();
            _selectTab(index);
          },
          onPortalTap: _openPortal,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
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
