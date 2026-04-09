import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.activeIndex,
    this.onSelected,
    this.onPortalTap,
  });

  final int activeIndex;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onPortalTap;

  static const _items = <_NavItemData>[
    _NavItemData(label: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavItemData(label: 'Customize', icon: Icons.auto_awesome_rounded),
    _NavItemData(label: 'Lessons', icon: Icons.school_rounded),
    _NavItemData(label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final leadingItems = _items.take(2).toList(growable: false);
    final trailingItems = _items.skip(2).toList(growable: false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          height: 88,
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
              for (var index = 0; index < leadingItems.length; index++)
                Expanded(
                  child: _NavTile(
                    data: leadingItems[index],
                    active: index == activeIndex,
                    onTap: () => _handleTap(index),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PortalButton(onTap: _handlePortalTap),
              ),
              for (var index = 0; index < trailingItems.length; index++)
                Expanded(
                  child: _NavTile(
                    data: trailingItems[index],
                    active: index + leadingItems.length == activeIndex,
                    onTap: () => _handleTap(index + leadingItems.length),
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
    onSelected!(index);
  }

  void _handlePortalTap() {
    if (onPortalTap == null) {
      return;
    }
    HapticFeedback.lightImpact();
    onPortalTap!();
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.data,
    required this.active,
    required this.onTap,
  });

  final _NavItemData data;
  final bool active;
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
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              Icon(data.icon, color: accent, size: active ? 24 : 21),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _PortalButton extends StatelessWidget {
  const _PortalButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF85EFAC), Color(0xFF48D58A), Color(0xFF0F4F3B)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.24),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.30),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.explore_rounded,
          color: Color(0xFF062C21),
          size: 34,
        ),
      ),
    );
  }
}
