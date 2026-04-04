import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.activeIndex,
    this.onSelected,
  });

  final int activeIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ClipRect(
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        const Color(0xFF082117).withValues(alpha: 0.96),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x77000000),
                        blurRadius: 24,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavTile(
                            label: 'Home',
                            icon: Icons.home_rounded,
                            active: activeIndex == 0,
                            onTap: () => _handleTap(0),
                          ),
                        ),
                        Expanded(
                          child: _NavTile(
                            label: 'Financials',
                            icon: Icons.account_balance_wallet_rounded,
                            active: activeIndex == 1,
                            onTap: () => _handleTap(1),
                          ),
                        ),
                        const SizedBox(width: 78),
                        Expanded(
                          child: _NavTile(
                            label: 'Lessons',
                            icon: Icons.school_rounded,
                            active: activeIndex == 3,
                            onTap: () => _handleTap(3),
                          ),
                        ),
                        Expanded(
                          child: _NavTile(
                            label: 'Profile',
                            icon: Icons.person_rounded,
                            active: activeIndex == 4,
                            onTap: () => _handleTap(4),
                          ),
                        ),
                      ],
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
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        width: active ? 88 : 82,
        height: active ? 88 : 82,
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
    );
  }
}
