import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.activeIndex,
    this.onSelected,
    this.activeColor = const Color(0xFF85EFAC),
  });

  final int activeIndex;
  final ValueChanged<int>? onSelected;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    const items = <({String label, IconData icon})>[
      (label: 'Home', icon: Icons.home_rounded),
      (label: 'Budget', icon: Icons.wallet_rounded),
      (label: 'Invest', icon: Icons.insights_rounded),
      (label: 'Challenges', icon: Icons.emoji_events_rounded),
      (label: 'Profile', icon: Icons.person_rounded),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              const Color(0xFF062C21).withValues(alpha: 0.96),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: List<Widget>.generate(items.length, (index) {
                final item = items[index];
                return Expanded(
                  child: _NavItem(
                    label: item.label,
                    icon: item.icon,
                    active: activeIndex == index,
                    activeColor: activeColor,
                    onTap: onSelected == null ? null : () => onSelected!(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? const Color(0xFF062C21) : Colors.white70;
    final labelColor = active ? const Color(0xFF062C21) : Colors.white60;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 62;
        final showLabel = !compact || active;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.symmetric(
                vertical: showLabel ? 8 : 10,
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          activeColor.withValues(alpha: 0.28),
                          activeColor.withValues(alpha: 0.92),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: active
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
                boxShadow: active
                    ? [
                        const BoxShadow(
                          color: Color(0xFF166534),
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.26),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: active ? 22 : 20),
                  if (showLabel) const SizedBox(height: 4),
                  if (showLabel)
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: compact ? 9 : 10,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
