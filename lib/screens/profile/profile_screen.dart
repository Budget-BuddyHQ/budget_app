import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_settings_controller.dart';
import '../../controllers/user_stats_controller.dart';
import '../../navigation/app_tab_index.dart';
import '../../navigation/fade_page_route.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.activeTabIndex = AppTabIndex.profile,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  Future<void> _logout(BuildContext context) async {
    await context.read<UserStatsController>().signOut();

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
    return Consumer2<UserStatsController, AppSettingsController>(
      builder: (context, controller, settings, _) {
        final stats = controller.stats;
                    ),
                            activeThumbColor: const Color(0xFF85EFAC),
                          subtitle:
                              'Live across buttons, nav, and reward effects.',
                            value: settings.soundEnabled,
                            activeThumbColor: const Color(0xFF85EFAC),
                            onChanged: (value) async {
                              await settings.setSoundEnabled(value);
                            ),
                        ),
                              ),
                            ),
                        ),
                    ),
              ),
        );
      },
    );
  }
}

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
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF062C21),
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            ),
          ),
        ],
      ),
    );
  }
}

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
    );
  }
}

  const _AdminCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
      onTap: onTap,
    );
  }
}

  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
  }
