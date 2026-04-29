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
    _NavItemData(label: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavItemData(label: 'Game Hub', icon: Icons.explore_rounded),
    _NavItemData(label: 'Customize', icon: Icons.auto_awesome_rounded),
    _NavItemData(label: 'Lessons', icon: Icons.school_rounded),
    _NavItemData(label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final compact = screenWidth < 380;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 14,
          0,
          compact ? 10 : 14,
          14,
        ),
        child: Container(
          height: compact ? 72 : 84,
          decoration: BoxDecoration(
            color: const Color(0xFF071711).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFF85EFAC).withValues(alpha: 0.08),
                blurRadius: 18,
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
                    active: index == activeIndex,
                    compact: compact,
                    onTap: () => _handleTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
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
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final _NavItemData data;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = active ? const Color(0xFF85EFAC) : Colors.white70;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 3,
            vertical: 8,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 1 : 2,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF85EFAC).withValues(alpha: 0.32),
                      const Color(0xFF0D2B20).withValues(alpha: 0.92),
                    ],
                  )
                : null,
            border: Border.all(
              color: active
                  ? const Color(0xFF85EFAC).withValues(alpha: 0.42)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                data.icon,
                color: accent,
                size: compact ? (active ? 23 : 21) : (active ? 24 : 21),
              ),
              if (!compact) ...[
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ],
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
