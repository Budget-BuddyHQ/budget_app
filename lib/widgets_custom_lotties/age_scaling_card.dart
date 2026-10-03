import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../models_Like_Skins_and_lessons_templates/age_scaling_facts.dart';
import '../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../themes_colors/app_theme.dart';

/// The whole age system, on one card, in the player's own words.
///
/// # Why a panel and not another one-line note
///
/// [AgeScaledNote] says *"questions matched to your age"* wherever content is
/// filtered, which is the right thing at the point of use and is deliberately
/// small enough to stop noticing. It cannot answer the question underneath
/// the report *"I'm still not seeing the age separated for the app"*, which
/// is not "is this screen filtered" but **"what does this app actually do
/// with my age?"**
///
/// That question has one right place to be answered — next to where the age
/// is set — and one honest way to answer it: list every system it changes,
/// with the numbers, and let the reader check.
///
/// # Why the numbers are computed
///
/// "142 of 187 questions" is generated from the bank at runtime by
/// [ageScalingFacts]. A typed-in number would be a claim; this one cannot
/// drift out of date when questions are added, and a reader who counts is
/// right.
///
/// # Why it is expandable
///
/// Six facts is a wall of text on a screen that is mostly settings rows. The
/// collapsed state is one line that a player can act on ("9 to 12 · 6 things
/// change"), and the detail is there for the reader who wants it — which, on
/// this particular subject, includes parents.
class AgeScalingCard extends StatefulWidget {
  const AgeScalingCard({super.key, this.onChangeAge, this.debugBand});

  /// Opens whatever screen sets the age. Null hides the prompt.
  final VoidCallback? onChangeAge;

  /// Bypasses the signed-in account. Tests only.
  final AgeBand? debugBand;

  @override
  State<AgeScalingCard> createState() => _AgeScalingCardState();
}

class _AgeScalingCardState extends State<AgeScalingCard> {
  bool _open = false;

  IconData _iconFor(AgeScalingIcon icon) => switch (icon) {
    AgeScalingIcon.reading => Icons.menu_book_rounded,
    AgeScalingIcon.topics => Icons.shield_moon_rounded,
    AgeScalingIcon.wager => Icons.balance_rounded,
    AgeScalingIcon.wording => Icons.chat_bubble_rounded,
    AgeScalingIcon.speed => Icons.speed_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final band =
        widget.debugBand ?? context.watch<UserStatsController>().stats.ageBand;
    final facts = ageScalingFacts(band);
    final unset = band == AgeBand.undisclosed;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A31).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6CD34A).withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6CD34A).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF8CF3C8),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Matched to your age',
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unset
                              ? 'No age set — showing a general mix.'
                              : '${band.label} · ${facts.length} things '
                                    'change for you',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFFB7F7D7),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFFB7F7D7),
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(
              height: 1,
              color: const Color(0xFF6CD34A).withValues(alpha: 0.18),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final fact in facts) ...[
                    _FactRow(icon: _iconFor(fact.icon), fact: fact),
                    if (fact != facts.last) const SizedBox(height: 12),
                  ],
                  if (widget.onChangeAge != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: widget.onChangeAge,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF6CD34A,
                          ).withValues(alpha: 0.14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: Text(
                          unset ? 'Set my age' : 'Change my age',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF8CF3C8),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.fact});

  final IconData icon;
  final AgeScalingFact fact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 17,
            color: const Color(0xFF8CF3C8).withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fact.title,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fact.detail,
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
