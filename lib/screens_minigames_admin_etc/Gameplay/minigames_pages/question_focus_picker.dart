import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/question_focus.dart';
import '../../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../../themes_colors/app_theme.dart';

/// The device's last choice, so the sheet opens on it. Per device on purpose:
/// it is a convenience, not progress.
const String kQuestionFocusPrefKey = 'arcade_question_focus';

/// Asks which questions this game should use: the player's weak spots, or
/// everything for their age. Null when the sheet is closed without choosing,
/// and the game is not opened.
///
/// See [QuestionFocus] for who asked for it and which games show it.
Future<QuestionFocus?> showQuestionFocusPicker(
  BuildContext context, {
  required String gameTitle,
}) async {
  final stats = context.read<UserStatsController>().stats;
  final weak = weakSkillsFor(stats);
  var last = QuestionFocus.ageGroup;
  try {
    final prefs = await SharedPreferences.getInstance();
    last = QuestionFocus.fromName(prefs.getString(kQuestionFocusPrefKey));
  } catch (_) {
    // No storage: start on the age group.
  }
  if (weak.isEmpty) last = QuestionFocus.ageGroup;
  if (!context.mounted) return null;

  final picked = await showModalBottomSheet<QuestionFocus>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTheme.panel,
    builder: (_) =>
        _QuestionFocusSheet(gameTitle: gameTitle, weakSkills: weak, last: last),
  );
  if (picked != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kQuestionFocusPrefKey, picked.name);
    } catch (_) {
      // Remembering is a nicety.
    }
  }
  return picked;
}

class _QuestionFocusSheet extends StatelessWidget {
  const _QuestionFocusSheet({
    required this.gameTitle,
    required this.weakSkills,
    required this.last,
  });

  final String gameTitle;
  final Set<String> weakSkills;
  final QuestionFocus last;

  @override
  Widget build(BuildContext context) {
    final topics = {
      for (final skill in weakSkills) QuizSkills.label(skill),
    }.take(3).toList();
    final hasWeak = weakSkills.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gameTitle,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Which questions do you want?',
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _Choice(
            key: const ValueKey('focus-weak-spots'),
            icon: Icons.track_changes_rounded,
            color: const Color(0xFFFFC36B),
            title: QuestionFocus.weakSpots.label,
            body: hasWeak
                ? 'Practise what you have been missing: ${topics.join(', ')}'
                      '${weakSkills.length > topics.length ? ' and more' : ''}.'
                      ' Getting them right clears them from your Coach.'
                : 'Take a quiz or a lesson first, so we know what to '
                      'practise.',
            selected: last == QuestionFocus.weakSpots,
            onTap: hasWeak
                ? () => Navigator.of(context).pop(QuestionFocus.weakSpots)
                : null,
          ),
          const SizedBox(height: 10),
          _Choice(
            key: const ValueKey('focus-age-group'),
            icon: Icons.groups_rounded,
            color: AppTheme.greenPrimary,
            title: QuestionFocus.ageGroup.label,
            body: 'A mix of everything written for your age.',
            selected: last == QuestionFocus.ageGroup,
            onTap: () => Navigator.of(context).pop(QuestionFocus.ageGroup),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: AppTheme.inset,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected && enabled ? color : AppTheme.outline,
                  width: 2,
                ),
                boxShadow: AppTheme.ledgeShadow(color, restAlpha: 0.18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF0B1418)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.pixelifySans(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (selected && enabled) ...[
                              const SizedBox(width: 8),
                              Text(
                                'LAST TIME',
                                style: AppTheme.caps(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          body,
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
