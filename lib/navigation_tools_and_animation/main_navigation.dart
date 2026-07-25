import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/personal_details_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = AppTabIndex.dashboard});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  UserStatsController? _controller;
  bool _askedForPersonalDetails = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, AppTabIndex.count - 1).toInt();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<UserStatsController>();
    if (identical(controller, _controller)) {
      return;
    }
    _controller?.removeListener(_maybeAskForPersonalDetails);
    _controller = controller..addListener(_maybeAskForPersonalDetails);
    _maybeAskForPersonalDetails();
  }

  @override
  void dispose() {
    _controller?.removeListener(_maybeAskForPersonalDetails);
    super.dispose();
  }

  /// Prompts once per app run for the age/gender details, but only after the
  /// profile has finished loading — otherwise the defaults would make an
  /// existing player look like a brand new one.
  void _maybeAskForPersonalDetails() {
    final controller = _controller;
    if (_askedForPersonalDetails || controller == null || !mounted) {
      return;
    }
    if (controller.isLoading || !controller.isAuthenticated) {
      return;
    }

    _askedForPersonalDetails = true;
    if (controller.stats.hasCompletedPersonalDetails) {
      return;
    }

    // Defer past the current build/notify pass before pushing a route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      PersonalDetailsSheet.show(
        context,
        ageBand: controller.stats.ageBand,
        gender: controller.stats.gender,
        isFirstRun: true,
      );
    });
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
