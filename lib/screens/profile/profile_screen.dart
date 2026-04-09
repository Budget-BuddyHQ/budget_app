import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../navigation/fade_page_route.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.activeTabIndex = 3,
    this.onNavSelected,
    this.onPortalTap,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onPortalTap;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  Future<void> _logout(BuildContext context) async {
    await context.read<UserStatsController>().signOut();
    if (!context.mounted) {
      return;
    }

    GameToast.show(
      context,
      title: 'Logged out',
      message: 'Your session and cached progress were cleared safely.',
      icon: Icons.logout_rounded,
      accent: const Color(0xFFFFB084),
    );

    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute<void>(
        builder: (_) => const AuthScreen(mode: AuthMode.login),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final user = SupabaseService.instance.currentUser;
        final isAdmin = user?.email?.toLowerCase() == 'brucksheferaw@gmail.com';

        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          bottomNavigationBar: widget.onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: widget.activeTabIndex,
                  onSelected: widget.onNavSelected,
                  onPortalTap: widget.onPortalTap,
                ),
          body: Stack(
            children: [
              const _ProfileBackdrop(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
                  children: [
                    _ProfileHero(stats: stats),
                    const SizedBox(height: 18),
                    _SettingsCard(
                      title: 'Notifications',
                      subtitle: 'Quest reminders and reward alerts.',
                      icon: Icons.notifications_active_rounded,
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        activeColor: const Color(0xFF85EFAC),
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          setState(() => _notificationsEnabled = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      title: 'Sound',
                      subtitle: 'Keep taps and reward effects enabled.',
                      icon: Icons.volume_up_rounded,
                      trailing: Switch.adaptive(
                        value: _soundEnabled,
                        activeColor: const Color(0xFF85EFAC),
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          setState(() => _soundEnabled = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      title: 'Account',
                      subtitle:
                          user?.email ?? 'Signed in as ${stats.username}.',
                      icon: Icons.manage_accounts_rounded,
                      trailing: Text(
                        stats.levelTitle,
                        style: const TextStyle(
                          color: Color(0xFF85EFAC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      _AdminCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 22),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _logout(context);
                      },
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8E72), Color(0xFFF55353)],
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF85EFAC), Color(0xFF48D58A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.24),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF062C21),
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stats.levelTitle,
                  style: const TextStyle(
                    color: Color(0xFF85EFAC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gold: ${stats.gold} • XP: ${stats.xp}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF85EFAC)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFFD45C).withValues(alpha: 0.26),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD45C).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFFFFD45C),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage users and internal test tools.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.60),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF071711), Color(0xFF0B231B), Color(0xFF103127)],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF85EFAC).withValues(alpha: 0.14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.14),
                  blurRadius: 80,
                  spreadRadius: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
