import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_screen.dart';
import '../../controllers/user_stats_controller.dart';
import '../../navigation/fade_page_route.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/skeleton_loader.dart';
import '../auth/auth_screen.dart';
import '../legal/privacy_policy_page.dart';
import '../profile/goals_setup_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.activeTabIndex = 4, this.onNavSelected});

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _logout(BuildContext context) async {
    final controller = context.read<UserStatsController>();
    await controller.signOut();
    if (!context.mounted) {
      return;
    }
    GameToast.show(
      context,
      title: 'Logged out',
      message: 'Your Supabase session has ended on this device.',
      icon: Icons.logout_rounded,
      accent: const Color(0xFFFFC36B),
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

        final user = Supabase.instance.client.auth.currentUser;

        return Scaffold(
          backgroundColor: const Color(0xFF0A211A),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF173C2F).withValues(alpha: 0.96),
                              const Color(0xFF214D3E).withValues(alpha: 0.92),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF85EFAC),
                                    Color(0xFF48D58A),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF85EFAC,
                                    ).withValues(alpha: 0.26),
                                    blurRadius: 22,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF103225),
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              stats.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
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
                              'Balance: \$${stats.gold} | XP: ${stats.xp}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Financial Personality: ${stats.personalityType}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick actions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ActionRow(
                              title: 'Refresh Cloud Sync',
                              subtitle:
                                  'Pull the latest wallet and XP progress.',
                              icon: Icons.sync_rounded,
                              buttonLabel: 'Sync',
                              onPressed: () async {
                                await controller.refresh();
                                if (!context.mounted) {
                                  return;
                                }
                                GameToast.show(
                                  context,
                                  title: 'Profile synced',
                                  message:
                                      'Your latest progress is now loaded.',
                                  icon: Icons.cloud_done_rounded,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _ActionRow(
                              title: 'Learning Path',
                              subtitle:
                                  'Open your lesson map and continue your journey.',
                              icon: Icons.route_rounded,
                              buttonLabel: 'Open',
                              onPressed: () {
                                onNavSelected?.call(3);
                              },
                            ),
                            const SizedBox(height: 12),
                            _ActionRow(
                              title: 'Goal Setup',
                              subtitle:
                                  'Adjust the goals that guide your weekly quests.',
                              icon: Icons.flag_rounded,
                              buttonLabel: 'Edit',
                              onPressed: () {
                                Navigator.of(context).push(
                                  FadePageRoute(
                                    builder: (_) => const GoalsSetupPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _ActionRow(
                              title: 'Privacy Center',
                              subtitle:
                                  'Review policies and how your data is stored.',
                              icon: Icons.privacy_tip_rounded,
                              buttonLabel: 'View',
                              onPressed: () {
                                Navigator.of(context).push(
                                  FadePageRoute(
                                    builder: (_) => const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),
                            if (user?.email == 'brucksheferaw@gmail.com')
                              _ActionRow(
                                title: 'Admin Panel',
                                subtitle: 'Manage app data and users.',
                                icon: Icons.admin_panel_settings,
                                buttonLabel: 'Open',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AdminScreen(),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        label: 'Log Out',
                        onPressed: () => _logout(context),
                        prefixIcon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        style: const CustomButtonStyle.danger(),
                      ),
                    ],
                  ),
                ),
                if (controller.isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.06),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                        child: Column(
                          children: const [
                            SkeletonLoader(height: 250, borderRadius: 28),
                            SizedBox(height: 18),
                            SkeletonLoader(height: 300, borderRadius: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF85EFAC)),
          ),
          const SizedBox(width: 12),
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
          SizedBox(
            width: 98,
            child: CustomButton(
              label: buttonLabel,
              onPressed: onPressed,
              height: 46,
              style: const CustomButtonStyle.secondary(),
            ),
          ),
        ],
      ),
    );
  }
}
