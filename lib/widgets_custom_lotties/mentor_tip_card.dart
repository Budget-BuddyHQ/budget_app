import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import '../models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import 'mentor_image.dart';
import '../themes_colors/app_theme.dart';
import 'fitted_label.dart';
import 'idle_hover_icon.dart';
import 'life_money_panel.dart' show LifeEmoji;

/// "Buddy's tip" — the mentor turtle showing up on Home with one money idea,
/// independent of any life run.
///
/// **Why this exists.** [FinanceConcept] explainers already existed and were
/// genuinely good copy, but the only place they surfaced was a sheet buried
/// inside a life in progress (`_ConceptsSheet` in life_sim_page.dart) — so a
/// player who hadn't started a life, or who bounces off Home most sessions,
/// never saw any of it. This puts one concept where every session already
/// starts, using the same mascot from [AppAssets.turtleCelebrateSheet] in
/// poses drawn for this ("Buddy's tip"), and the win moment.
///
/// The tip rotates once a day (by day-of-year), not per rebuild — the same
/// idea should still be there if you background the app and come back an
/// hour later, and a new one is worth a reason to open the app again
/// tomorrow.
class MentorTipCard extends StatelessWidget {
  const MentorTipCard({super.key, this.simpleWording = false});

  /// Mirrors [FinanceConceptInfo.explainerFor]'s `simple` flag — pass the
  /// player's own age band here, not any in-game character's.
  final bool simpleWording;

  static const _risk = <FinanceConcept>{
    FinanceConcept.interestCost,
    FinanceConcept.creditScore,
    FinanceConcept.impulseSpending,
    FinanceConcept.lifestyleCreep,
    FinanceConcept.sunkCost,
  };

  FinanceConcept _todaysConcept() {
    const values = FinanceConcept.values;
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    return values[dayOfYear % values.length];
  }

  @override
  Widget build(BuildContext context) {
    final concept = _todaysConcept();
    final worried = _risk.contains(concept);
    // Wearing the skin the player equipped -- the daily tip is the guide's
    // most-seen appearance, so it is the one that most needed to stop being
    // a different turtle from the one on their profile. See [MentorImage].
    final pose = worried ? TutorialMascot.worried : TutorialMascot.thinking;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetail(context, concept, worried);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.getPuffyDecoration(
          accent: concept.accent,
          fillColor: const Color(0xFF1E2C33),
          restAlpha: 0.16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IdleHoverIcon(
              idleAmplitude: 3,
              pulseAmplitude: 0.03,
              child: MentorImage(pose: pose, size: 60),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FittedLabel(
                        "Buddy's tip",
                        style: GoogleFonts.pixelifySans(
                          color: concept.accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      LifeEmoji(concept.emoji, size: 13),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    concept.label,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    concept.explainerFor(simple: simpleWording),
                    // Three, not two. At two, the longest explainers stopped
                    // dead in the middle of a word — "A want is everything
                    // el..." — which is worse than no tip at all, because the
                    // card's whole job is to leave the reader with one idea.
                    // The card sizes to its content, so the third line costs
                    // about sixteen points of height and nothing else.
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    FinanceConcept concept,
    bool worried,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MentorTipSheet(
        concept: concept,
        worried: worried,
        simpleWording: simpleWording,
      ),
    );
  }
}

class _MentorTipSheet extends StatelessWidget {
  const _MentorTipSheet({
    required this.concept,
    required this.worried,
    required this.simpleWording,
  });

  final FinanceConcept concept;
  final bool worried;
  final bool simpleWording;

  @override
  Widget build(BuildContext context) {
    final pose = worried ? TutorialMascot.worried : TutorialMascot.idle;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2C33),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(color: concept.accent.withValues(alpha: 0.35)),
          boxShadow: AppTheme.ledgeShadow(concept.accent, restAlpha: 0.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MentorImage(pose: pose, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    concept.label,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              concept.explainerFor(simple: simpleWording),
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: concept.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_rounded, color: concept.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      concept.tryThis,
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
