import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/app_settings_controller.dart';
import '../../services/supabase_service.dart';
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
    if (!context.mounted) return;

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
        final user = Supabase.instance.client.auth.currentUser;

        return FutureBuilder<Map<String, dynamic>>(
          future: Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user?.id ?? '')
              .single(),
          builder: (context, snapshot) {
            bool isAdmin = false;

            if (snapshot.hasData) {
              final data = snapshot.data!;
              isAdmin = data['role'] == 'admin';
            }

            return Scaffold(
              backgroundColor: const Color(0xFF071711),
              bottomNavigationBar: widget.onNavSelected == null
                  ? null
                  : CustomBottomNav(
                      activeIndex: widget.activeTabIndex,
                      onSelected: widget.onNavSelected!,
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
                            activeThumbColor: const Color(0xFF85EFAC),
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              setState(() => _notificationsEnabled = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(
                          title: 'Sound',
                          subtitle:
                              'Live across buttons, nav, and reward effects.',
                          icon: Icons.volume_up_rounded,
                          trailing: Switch.adaptive(
                            value: settings.soundEnabled,
                            activeThumbColor: const Color(0xFF85EFAC),
                            onChanged: (value) async {
                              HapticFeedback.lightImpact();
                              await settings.setSoundEnabled(value);
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
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF062C21),
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              stats.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
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
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings, color: Colors.amber),
      title: const Text('Admin Panel', style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFF071711));
  }
}
