import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../screens_minigames_admin_etc/auth/auth_screen.dart';
import '../navigation_tools_and_animation/fade_page_route.dart';
import '../themes_colors/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warns when progress is saving to the device but not reaching Supabase.
///
/// `SupabaseService.saveUserStats` deliberately swallows upsert errors so a
/// flaky network can never lose a player's session — it writes the local cache
/// and reports `synced: false`. The gap was that nothing ever *showed* that
/// state. A schema mismatch once broke every cloud save for a long stretch and
/// produced no visible symptom at all, because local saving kept working; the
/// only way to notice was to sign in on another device and find the account
/// empty.
///
/// Renders nothing in the healthy case. A signed-out guest gets a different
/// banner from this same widget (see below) rather than nothing at all --
/// that used to be correct when "signed out" only ever meant "hasn't reached
/// the welcome screen yet", but guest mode made it a real, possibly
/// long-lived state worth actually warning about.
class CloudSyncBanner extends StatelessWidget {
  const CloudSyncBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserStatsController>();

    if (controller.isGuest) {
      return _Banner(
        compact: compact,
        icon: Icons.person_outline_rounded,
        accent: const Color(0xFF7FD8F2),
        title: 'Playing as a guest',
        body:
            'Your progress is only on this device -- not everything is '
            'guaranteed to be saved if you clear app data, switch phones, or '
            'uninstall. Create a free account any time to keep it safe.',
        actionLabel: 'Sign Up',
        onAction: () {
          Navigator.of(context).push(
            FadePageRoute<void>(
              builder: (_) => const AuthScreen(mode: AuthMode.signUp),
            ),
          );
        },
      );
    }

    if (controller.cloudSyncHealthy) {
      return const SizedBox.shrink();
    }

    return _Banner(
      compact: compact,
      icon: Icons.cloud_off_rounded,
      accent: const Color(0xFFFFB84D),
      title: 'Not syncing to the cloud',
      body:
          'Your progress is safe on this device, but the last save did not '
          'reach the server -- it will not appear if you sign in somewhere '
          'else. Syncing resumes automatically.',
      actionLabel: 'Retry',
      onAction: controller.isSaving ? null : controller.refresh,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.compact,
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final bool compact;
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 10 : 14),
      padding: EdgeInsets.all(compact ? 12 : 14),
      // Opaque: the same tint as before, mixed into a card color so the
      // water does not show through it like frosted glass.
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.12),
          const Color(0xFF12352C),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        boxShadow: AppTheme.ledgeShadow(accent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
