import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_sound_service.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.activeIndex,
    this.onSelected,
  });

  final int activeIndex;
  final ValueChanged<int>? onSelected;

  static const _items = <_NavItemData>[
    _NavItemData(label: 'Home', icon: Icons.dashboard_rounded),
    _NavItemData(label: 'Adventure', icon: Icons.explore_rounded),
    _NavItemData(label: 'Arcade', icon: Icons.sports_esports_rounded),
    _NavItemData(label: 'Style', icon: Icons.auto_awesome_rounded),
    _NavItemData(label: 'Academy', icon: Icons.school_rounded),
    _NavItemData(label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final compact = screenWidth < 720;
    final dense = screenWidth < 560;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dense ? 8 : (compact ? 10 : 14),
          0,
          dense ? 8 : (compact ? 10 : 14),
          dense ? 10 : 14,
        ),
        child: Container(
          height: dense ? 84 : (compact ? 88 : 92),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A1D17).withValues(alpha: 0.98),
                const Color(0xFF07110D).withValues(alpha: 0.94),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFF4BD2A3).withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: _NavTile(
                    data: _items[index],
                    index: index,
                    active: index == activeIndex,
                    compact: compact,
                    dense: dense,
                    onTap: () => _handleTap(context, index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (onSelected == null || index == activeIndex) {
      return;
    }

    HapticFeedback.lightImpact();
    AppSoundService.play(AppSoundEffect.navigation);
    onSelected!(index);
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.data,
    required this.index,
    required this.active,
    required this.compact,
    required this.dense,
    required this.onTap,
  });

  final _NavItemData data;
  final int index;
  final bool active;
  final bool compact;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = active ? const Color(0xFFB7F7D7) : Colors.white70;
    return Semantics(
      button: true,
      selected: active,
      label: '${data.label} tab',
      value: active ? 'Selected' : 'Not selected',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(
              horizontal: dense ? 1 : (compact ? 2 : 3),
              vertical: dense ? 7 : 8,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 0 : (compact ? 1 : 2),
              vertical: dense ? 7 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF4BD2A3).withValues(alpha: 0.34),
                        const Color(0xFF123124).withValues(alpha: 0.96),
                      ],
                    )
                  : null,
              border: Border.all(
                color: active
                    ? const Color(0xFF7BE1BB).withValues(alpha: 0.48)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  data.icon,
                  color: accent,
                  size: dense
                      ? (active ? 21 : 19)
                      : compact
                      ? (active ? 23 : 21)
                      : (active ? 24 : 21),
                ),
                SizedBox(height: dense ? 4 : 5),
                SizedBox(
                  height: dense ? 14 : 16,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontSize: dense ? 9.2 : 10.2,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                          letterSpacing: dense ? 0.0 : 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
