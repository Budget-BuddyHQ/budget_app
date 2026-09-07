import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../services_backend_and_other_services/supabase_service.dart';
import '../../themes_colors/app_theme.dart';
import '../../widgets_custom_lotties/profile_avatar.dart';

/// One friend, opened by tapping their row.
///
/// **Why this exists.** The friends list was a name, two numbers and a remove
/// button, and tapping it did nothing. That is a contact list, and it is the
/// wrong shape for what friends are actually for here — the reason to add
/// somebody in a game about money is to have a second data point for how
/// you are doing. A row that shows "6325 literacy · 8645956 gold" and cannot
/// be opened is a fact with nowhere to go.
///
/// So the screen is built around **comparison rather than display**. Every
/// number is shown against the viewer's own, with a bar and a sentence saying
/// which way round it is. Which is also the honest version of a leaderboard:
/// a rank tells you that you are third, and this tells you what third means.
///
/// It degrades on purpose. Three of the sections come from columns added by
/// `0005_leaderboard_profile.sql`, and every one of them is hidden rather
/// than zeroed when the migration has not been run — see the note on
/// [LeaderboardEntry].
class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({
    super.key,
    required this.friend,
    required this.onRemove,
  });

  final LeaderboardEntry friend;

  /// Called after the player confirms removal. The list that pushed this
  /// screen owns the refresh, so this pops first and lets the caller reload.
  ///
  /// **Null hides the button entirely**, which is how the leaderboard opens
  /// this. Adding and removing friends lives in one place — the Friends card
  /// in Profile — and a Remove button on a leaderboard row would be a
  /// destructive action sitting inside a screen whose whole purpose is
  /// browsing. It is also not always meaningful there: the global board shows
  /// people who are not friends at all.
  final Future<bool> Function()? onRemove;

  @override
  Widget build(BuildContext context) {
    final mine = context.watch<UserStatsController>().stats;

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        // Deliberately not the username: the header below is already a large
        // name under a large avatar, and putting it in the bar as well
        // printed it twice within 200px of itself.
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
          children: [
            _Header(friend: friend),
            const SizedBox(height: 22),

            _SectionTitle('How you compare'),
            const SizedBox(height: 10),
            _CompareRow(
              label: 'Literacy',
              theirs: friend.literacyPoints,
              yours: mine.literacyPoints,
              colour: const Color(0xFFB388FF),
              // Literacy is the score this app actually cares about, so it
              // goes first and gets the sentence underneath.
              explain: true,
            ),
            _CompareRow(
              label: 'XP',
              theirs: friend.xp,
              yours: mine.xp,
              colour: AppTheme.teal,
            ),
            _CompareRow(
              label: 'Gold',
              theirs: friend.gold,
              yours: mine.gold,
              colour: const Color(0xFFFFD45C),
            ),

            if (friend.personalityType.isNotEmpty ||
                friend.lessonsCompleted > 0 ||
                friend.dailyStreak > 0) ...[
              const SizedBox(height: 24),
              _SectionTitle('How they play'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (friend.personalityType.isNotEmpty)
                    _Fact(
                      icon: Icons.psychology_rounded,
                      label: friend.personalityType,
                      caption: 'money style',
                      colour: AppTheme.greenPrimary,
                    ),
                  if (friend.lessonsCompleted > 0)
                    _Fact(
                      icon: Icons.school_rounded,
                      label: '${friend.lessonsCompleted}',
                      caption: friend.lessonsCompleted == 1
                          ? 'lesson done'
                          : 'lessons done',
                      colour: const Color(0xFF69C6FF),
                    ),
                  if (friend.dailyStreak > 0)
                    _Fact(
                      icon: Icons.local_fire_department_rounded,
                      label: '${friend.dailyStreak}',
                      caption: 'day streak',
                      colour: const Color(0xFFFF8A65),
                    ),
                ],
              ),
            ],

            if (onRemove != null) ...[
              const SizedBox(height: 28),
              _RemoveButton(username: friend.username, onRemove: onRemove!),
              const SizedBox(height: 14),
              Text(
                'Removing them takes them off your leaderboard. Either of you '
                'can add the other again with a friend code.',
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  fontSize: 11.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.friend});

  final LeaderboardEntry friend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileAvatar(
          imageUrl: friend.profileImageUrl,
          // Their villager, not a generic one. `skinFromId` falls back to the
          // starter skin for an unknown or empty id, which is what happens
          // before `0005_leaderboard_profile.sql` is run.
          fallbackSkin: skinFromId(friend.equippedSkin),
          size: 108,
        ),
        const SizedBox(height: 14),
        Text(
          friend.username,
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _lastSeen(friend.updatedAt),
          style: GoogleFonts.quicksand(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Rounded, and rounded *down* in specificity as it gets older.
  ///
  /// "Active 3 minutes ago" on a children's app is a presence indicator, and
  /// a presence indicator is a thing that tells other people when a child is
  /// on their phone. Days are enough to answer the only question worth
  /// asking here — is this account still being played — and answer nothing
  /// else.
  static String _lastSeen(DateTime? at) {
    if (at == null) return 'Friend';
    final days = DateTime.now().toUtc().difference(at.toUtc()).inDays;
    if (days <= 0) return 'Played today';
    if (days == 1) return 'Played yesterday';
    if (days < 7) return 'Played $days days ago';
    if (days < 30) return 'Played ${days ~/ 7}w ago';
    return 'Not played in a while';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.pixelifySans(
        color: AppTheme.limeAccent,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// One stat, theirs against yours.
class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.theirs,
    required this.yours,
    required this.colour,
    this.explain = false,
  });

  final String label;
  final int theirs;
  final int yours;
  final Color colour;

  /// Whether to spell the gap out in a sentence underneath.
  final bool explain;

  @override
  Widget build(BuildContext context) {
    // Both bars are scaled against the larger of the two, so the bigger
    // number is always full width and the smaller one is readable as a
    // proportion of it. Scaling against a fixed maximum would make two
    // beginners look identical and two veterans look identical.
    final ceiling = (theirs > yours ? theirs : yours).clamp(1, 1 << 62);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.quicksand(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _Bar(value: theirs, ceiling: ceiling, colour: colour, who: 'Them'),
          const SizedBox(height: 6),
          _Bar(
            value: yours,
            ceiling: ceiling,
            colour: Colors.white.withValues(alpha: 0.55),
            who: 'You',
          ),
          if (explain) ...[
            const SizedBox(height: 8),
            Text(
              _gapSentence(),
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _gapSentence() {
    final gap = (yours - theirs).abs();
    if (gap == 0) return 'Dead level on literacy.';
    if (yours > theirs) {
      return "You are $gap literacy ahead. Their lessons are the same "
          'lessons — nothing is stopping them catching up.';
    }
    return 'They are $gap literacy ahead of you. Literacy comes from '
        'lessons and quizzes, not from gold.';
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.ceiling,
    required this.colour,
    required this.who,
  });

  final int value;
  final int ceiling;
  final Color colour;
  final String who;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            who,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: (value / ceiling).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(colour),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: GoogleFonts.quicksand(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.caption,
    required this.colour,
  });

  final IconData icon;
  final String label;
  final String caption;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colour, size: 18),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.quicksand(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                caption,
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.username, required this.onRemove});

  final String username;
  final Future<bool> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.panelStrong,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            title: Text(
              'Remove $username?',
              style: AppTheme.numeric(color: AppTheme.textPrimary),
            ),
            content: Text(
              'They will drop off your friends leaderboard. You can add them '
              'again any time with their code.',
              style: GoogleFonts.quicksand(color: AppTheme.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;

        // Pop first, then let the caller do the removal and the refresh.
        // Removing while this screen is still on top would leave it showing a
        // profile for somebody who is no longer a friend, with a Remove
        // button that would fail the second time.
        Navigator.of(context).pop();
        await onRemove();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.errorRed,
        side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
      icon: const Icon(Icons.person_remove_rounded, size: 18),
      label: Text(
        'Remove friend',
        style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
      ),
    );
  }
}
