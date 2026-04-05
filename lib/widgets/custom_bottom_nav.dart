import 'package:flutter/services.dart';

    this.onSelected,
  final int activeIndex;
  final ValueChanged<int>? onSelected;

    return SafeArea(
      top: false,
      child: SizedBox(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
                    ],
                  ),
                        ),
                        ),
                        ),
                        ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 34,
              child: _TownSquareButton(
                active: activeIndex == 2,
                onTap: () => _handleTap(2),
              ),
            ),
          ],
        ),

  void _handleTap(int index) {
    if (onSelected == null || index == activeIndex) {
      return;
    }
    HapticFeedback.lightImpact();
    onSelected!(index);
  }
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.onTap,
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

    final foreground = active ? const Color(0xFF062C21) : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB7F7D0), Color(0xFF4ADE80)],
                  )
                : null,
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0xFF166534),
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x3385EFAC),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: active ? 22 : 20),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
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

class _TownSquareButton extends StatelessWidget {
  const _TownSquareButton({
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE55C),
              Color(0xFF4ADE80),
              Color(0xFF179D5B),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.62), width: 3),
          boxShadow: [
            const BoxShadow(
              color: Color(0xFF166534),
              offset: Offset(0, 7),
            ),
            BoxShadow(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.36),
              blurRadius: active ? 28 : 18,
              spreadRadius: active ? 4 : 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF062C21),
              size: 28,
            ),
            Text(
              'Town',
              style: TextStyle(
                color: const Color(0xFF062C21),
                fontSize: active ? 11 : 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
