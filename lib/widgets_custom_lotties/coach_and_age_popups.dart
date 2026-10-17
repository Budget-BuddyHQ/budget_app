import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../models_Like_Skins_and_lessons_templates/age_fit_check.dart';
import '../models_Like_Skins_and_lessons_templates/coach_memory.dart';
import '../models_Like_Skins_and_lessons_templates/coach_nudge.dart';
import '../models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import '../models_Like_Skins_and_lessons_templates/money_snapshot_source.dart';
import '../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../screens_minigames_admin_etc/profile/personal_details_sheet.dart';
import '../themes_colors/app_theme.dart';

// ---------------------------------------------------------------------------
// The Coach pop-up. See `coach_nudge.dart` for when it shows.
// ---------------------------------------------------------------------------

const String _nudgedKey = 'coach_nudged_v1';
const String _nudgeDayKey = 'coach_nudge_last_shown_v1';

/// Shows the Coach pop-up if the Coach has something new, at most once a day.
/// Does nothing without device storage, because it could not keep its
/// once-a-day promise.
Future<void> maybeShowCoachNudge(
  BuildContext context, {
  required VoidCallback onOpenCoach,
}) async {
  final SharedPreferences prefs;
  final CoachMemory memory;
  try {
    prefs = await SharedPreferences.getInstance();
    memory = await CoachMemory.load();
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final stats = context.read<UserStatsController>().stats;
  final now = DateTime.now();
  final nudged = <String, DateTime>{};
  try {
    final raw = jsonDecode(prefs.getString(_nudgedKey) ?? '{}');
    if (raw is Map) {
      for (final e in raw.entries) {
        final when = DateTime.tryParse('${e.value}');
        if (when != null) nudged['${e.key}'] = when;
      }
    }
  } catch (_) {
    // Unreadable: start fresh.
  }
  final nudge = nextCoachNudge(
    report: analyzeMoney(buildMoneySnapshot(stats)),
    weakSkills: stats.weakSkills,
    lastOpen: memory.open,
    unclaimedFixed: memory.fixed,
    nudged: nudged,
    now: now,
    lastShown: DateTime.tryParse(prefs.getString(_nudgeDayKey) ?? ''),
  );
  if (nudge == null) return;

  for (final id in nudge.ids) {
    nudged[id] = now;
  }
  await prefs.setString(
    _nudgedKey,
    jsonEncode({
      for (final e in nudged.entries) e.key: e.value.toIso8601String(),
    }),
  );
  await prefs.setString(_nudgeDayKey, now.toIso8601String());
  if (!context.mounted) return;

  final open = await showDialog<bool>(
    context: context,
    builder: (_) => _CoachNudgeDialog(nudge: nudge),
  );
  if (open == true) onOpenCoach();
}

class _CoachNudgeDialog extends StatelessWidget {
  const _CoachNudgeDialog({required this.nudge});

  final CoachNudge nudge;

  @override
  Widget build(BuildContext context) {
    final fixed = nudge.kind == CoachNudgeKind.fixed;
    const gold = Color(0xFFFFC800);
    final more = nudge.count > 1 ? ' and ${nudge.count - 1} more' : '';
    return _PopupFrame(
      key: const ValueKey('coach-nudge'),
      accent: gold,
      icon: fixed ? Icons.emoji_events_rounded : Icons.insights_rounded,
      title: fixed ? 'You fixed something!' : 'Your Coach noticed something',
      content: [
        Text(
          fixed
              ? '"${nudge.title}"$more is fixed. Open your Coach to claim '
                    'your reward.'
              : '"${nudge.title}". Your Coach has a tip and a lesson to '
                    'help with it.',
          style: _body,
        ),
        const SizedBox(height: 12),
        const _HowTo(
          title: 'How to check your Coach',
          steps: [
            'Tap the yellow Coach button at the top of the screen.',
            'Start with "Your next step". It says what to do and how it '
                'clears.',
          ],
        ),
      ],
      primary: fixed ? 'Claim it in the Coach' : 'Open Coach',
      onPrimary: () => Navigator.of(context).pop(true),
      secondary: 'Later',
      onSecondary: () => Navigator.of(context).pop(false),
    );
  }
}

// ---------------------------------------------------------------------------
// "Are these too easy?" See `age_fit_check.dart` for when it shows.
// ---------------------------------------------------------------------------

const String _streakKey = 'age_fit_streak_v1';
const String _askedKey = 'age_fit_last_asked_v1';
const String _confirmedKey = 'age_fit_confirmed_band_v1';

/// Counts one finished quiz, and asks about the age group after a run of
/// near-perfect ones. See [recordQuizForAgeFit].
Future<void> recordQuizAndMaybeAskAge(
  BuildContext context, {
  required int correct,
  required int total,
}) async {
  final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final band = context.read<UserStatsController>().stats.ageBand;
  final before = AgeFitState(
    streak: prefs.getInt(_streakKey) ?? 0,
    lastAsked: DateTime.tryParse(prefs.getString(_askedKey) ?? ''),
    confirmedBand: prefs.getString(_confirmedKey),
  );
  final result = recordQuizForAgeFit(
    before,
    correct: correct,
    total: total,
    band: band,
    now: DateTime.now(),
  );
  await prefs.setInt(_streakKey, result.state.streak);
  final asked = result.state.lastAsked;
  if (asked != null) await prefs.setString(_askedKey, asked.toIso8601String());
  if (!result.ask || !context.mounted) return;
  await showAgeHelp(context, tooEasy: true);
}

/// How to check and change your age group, with a button that does it.
///
/// [tooEasy] is the version that follows a run of near-perfect quizzes and
/// says the player may be in the wrong age group. Without it, this is the
/// "Too easy or too hard?" help from a quiz's results.
Future<void> showAgeHelp(BuildContext context, {bool tooEasy = false}) async {
  final controller = context.read<UserStatsController>();
  final stats = controller.stats;
  final choice = await showDialog<_AgeChoice>(
    context: context,
    builder: (_) => _AgeHelpDialog(band: stats.ageBand, tooEasy: tooEasy),
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case _AgeChoice.change:
      await PersonalDetailsSheet.show(
        context,
        ageBand: controller.stats.ageBand,
        gender: controller.stats.gender,
      );
    case _AgeChoice.right:
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_confirmedKey, stats.ageBand.id);
      } catch (_) {
        // Then it may ask again in two weeks, which is fine.
      }
  }
}

enum _AgeChoice { change, right }

class _AgeHelpDialog extends StatelessWidget {
  const _AgeHelpDialog({required this.band, required this.tooEasy});

  final AgeBand band;
  final bool tooEasy;

  @override
  Widget build(BuildContext context) {
    const sky = Color(0xFF58C7FF);
    final unset = band == AgeBand.undisclosed;
    final current = unset
        ? 'You have not set your age, so you get a general mix of questions.'
        : 'Your questions are picked for the age group "${band.label}".';
    return _PopupFrame(
      key: const ValueKey('age-help'),
      accent: sky,
      icon: Icons.cake_rounded,
      title: tooEasy ? 'Are these too easy?' : 'Too easy or too hard?',
      content: [
        if (tooEasy) ...[
          Text(
            'You got your last $kAgeFitStreak quizzes almost all right. '
            'Great work!',
            style: _body,
          ),
          const SizedBox(height: 8),
        ],
        Text(current, style: _body),
        const SizedBox(height: 8),
        Text(
          tooEasy
              ? 'If the questions feel too easy, you might be in the wrong '
                    'age group. Changing it gives you questions that fit.'
              : 'If the questions do not feel right for you, your age group '
                    'may be wrong. Changing it changes the questions.',
          style: _body.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const _HowTo(
          title: 'How to change your age',
          steps: [
            'Tap Profile at the top right.',
            'Tap About You.',
            'Pick your age group, then tap Save.',
          ],
        ),
      ],
      primary: 'Change my age now',
      onPrimary: () => Navigator.of(context).pop(_AgeChoice.change),
      secondary: tooEasy ? 'My age is right' : 'Close',
      onSecondary: () =>
          Navigator.of(context).pop(tooEasy ? _AgeChoice.right : null),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

final TextStyle _body = GoogleFonts.quicksand(
  color: Colors.white.withValues(alpha: 0.9),
  fontSize: 14,
  height: 1.4,
  fontWeight: FontWeight.w600,
);

class _PopupFrame extends StatelessWidget {
  const _PopupFrame({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.content,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final List<Widget> content;
  final String primary;
  final VoidCallback onPrimary;
  final String secondary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.panel,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF0B1418)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...content,
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('popup-primary'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.greenPrimary,
                  foregroundColor: const Color(0xFF0B1418),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onPrimary,
                child: Text(
                  primary,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                key: const ValueKey('popup-secondary'),
                onPressed: onSecondary,
                child: Text(
                  secondary,
                  style: GoogleFonts.pixelifySans(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered steps, for "how to check" and "how to change".
class _HowTo extends StatelessWidget {
  const _HowTo({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.caps(
              color: AppTheme.greenPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.greenPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.pixelifySans(
                        color: const Color(0xFF0B1418),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(steps[i], style: _body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
