import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
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
/// Renders nothing in the healthy case, and nothing when signed out — saving
/// only to the device is the correct behaviour there, not a fault.
class CloudSyncBanner extends StatelessWidget {
  const CloudSyncBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserStatsController>();
    if (controller.cloudSyncHealthy) {
      return const SizedBox.shrink();
    }

    const accent = Color(0xFFFFB84D);
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 10 : 14),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not syncing to the cloud',
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your progress is safe on this device, but the last save did '
                  'not reach the server — it will not appear if you sign in '
                  'somewhere else. Syncing resumes automatically.',
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
            onPressed: controller.isSaving ? null : controller.refresh,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
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
