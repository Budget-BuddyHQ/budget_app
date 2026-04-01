import 'package:flutter/material.dart';

import 'profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({
    super.key,
    this.activeTabIndex = 4,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      activeTabIndex: activeTabIndex,
      onNavSelected: onNavSelected,
    );
  }
}
