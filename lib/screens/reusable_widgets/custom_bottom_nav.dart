import 'package:flutter/material.dart';

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
      (label: 'Home', icon: Icons.home),
      (label: 'Budget', icon: Icons.attach_money),
      (label: 'Invest', icon: Icons.trending_up),
      (label: 'Challenges', icon: Icons.emoji_events),
      (label: 'Profile', icon: Icons.person),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F4E3B),
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List<Widget>.generate(items.length, (index) {
            final item = items[index];
            final active = activeIndex == index;
            final color = active ? activeColor : Colors.white70;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSelected == null ? null : () => onSelected!(index),
                  radius: 48,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: activeColor.withValues(alpha: 0.16),
                  highlightColor: activeColor.withValues(alpha: 0.08),
                  child: SizedBox(
                    height: 74,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: color, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
