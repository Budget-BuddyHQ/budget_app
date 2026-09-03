import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';

import '../../../models_Like_Skins_and_lessons_templates/ranked_run.dart';

import '../../../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_record.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart'
    show LifeOriginInfo;
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets_custom_lotties/pixel_kit.dart';

/// The recap shown when a [LifeSummary] life ends — replaces what used to be
/// a silent `Navigator.pop()` straight back to Home. Purely presentational;
/// [LifeSummary] already carries the resolved [LifeEndingArchetype] and
/// every stat needed here.
class LifeEpilogueScreen extends StatelessWidget {
  const LifeEpilogueScreen({
    super.key,
    required this.summary,
    this.bestsBeaten = const <LifeBest>{},
    this.rankedScore,
  });

  final LifeSummary summary;

  /// Personal bests this run beat, from `recordLifeRun`. Empty for a first
  /// life (nothing to beat yet) and empty when replaying an old screen, so
  /// the banner is genuinely an event rather than decoration.
  final Set<LifeBest> bestsBeaten;

  /// Set only for a ranked run. Normal play is a sandbox and gets no grade —
  /// scoring somebody who was deliberately finding out what happens if they
  /// never work would be answering a question they did not ask.
  final RankedScore? rankedScore;

  @override
  Widget build(BuildContext context) {
    final archetype = summary.archetype;

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  summary.died ? 'The end.' : 'Retired.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (rankedScore != null) ...[
                _RankedScoreCard(score: rankedScore!),
                const SizedBox(height: 16),
              ],
              _ArchetypeCard(archetype: archetype),
              const SizedBox(height: 16),
              // The one place in the app where somebody is deciding whether
              // to play again.
              //
              // The endings collection is the strongest honest reason this
              // game has to start a second life: it rewards playing
              // *differently* rather than playing more, which is exactly the
              // behaviour a financial-literacy game wants. It was sitting on
              // the Play hub, below the fold, as a row of tiles reading
              // "Undiscovered" — visible only to somebody who had already
              // decided to come back.
              //
              // Here it is at the moment it can change a decision, naming one
              // specific ending and how to reach it. No streak, no timer, no
              // "come back tomorrow": just something worth doing next.
              const _NextEndingCard(),
              if (bestsBeaten.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PersonalBestBanner(bests: bestsBeaten),
              ],
              const SizedBox(height: 18),
              _LifeRecapCard(summary: summary),
              if (summary.relationships.isNotEmpty) ...[
                const SizedBox(height: 16),
                _RelationshipsCard(relationships: summary.relationships),
              ],
              const SizedBox(height: 16),
              _GoldRewardCard(gold: summary.goldReward),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Back to Home',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "You beat your own record" — shown only when this run actually topped a
/// previous one, so it stays an event rather than another stat row.
class _PersonalBestBanner extends StatelessWidget {
  const _PersonalBestBanner({required this.bests});

  final Set<LifeBest> bests;

  static const _gold = Color(0xFFFFD45C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: _gold.withValues(alpha: 0.42), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: _gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bests.length == 1
                      ? 'New personal best'
                      : 'New personal bests',
                  style: GoogleFonts.pixelifySans(
                    color: _gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final best in LifeBest.values)
                if (bests.contains(best))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      best.label,
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The ending card: who you turned out to be.
///
/// This used to be an accent colour and a Material glyph in a circle, which
/// meant all seven endings were the same screen wearing different tints —
/// nothing to recognise, nothing to want to collect. It now leads with a
/// **portrait**, because an ending is a person you became, and the name sits
/// on a ribbon so it reads as a title rather than as a heading.
class _ArchetypeCard extends StatelessWidget {
  const _ArchetypeCard({required this.archetype});

  final LifeEndingArchetype archetype;

  @override
  Widget build(BuildContext context) {
    return PixelFrame(
      style: PixelFrameStyle.slate,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        children: [
          // The portrait, on a plate tinted with the ending's own colour so
          // the two read as one thing rather than as art dropped onto a card.
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: archetype.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: archetype.color.withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            child: Image.asset(
              archetype.portrait,
              // 38x38 source drawn at 84 — nearest-neighbour or it turns to
              // mush.
              filterQuality: FilterQuality.none,
              fit: BoxFit.contain,
              // Falls back to the glyph this card used to lead with, so a
              // missing portrait is a downgrade rather than a hole.
              errorBuilder: (_, _, _) =>
                  Icon(archetype.icon, color: archetype.color, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          PixelRibbon(
            label: archetype.label,
            tone: PixelRibbonTone.gold,
            height: 52,
          ),
          const SizedBox(height: 14),
          Text(
            archetype.blurb,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeRecapCard extends StatelessWidget {
  const _LifeRecapCard({required this.summary});

  final LifeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1D17),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary.name} · ${summary.job}',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Lived to ${summary.age} (${summary.yearsLived} years) '
            'from a ${summary.origin.label.toLowerCase()} start.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(
                label: 'Net worth',
                value: '${summary.netWorth}',
                color: const Color(0xFF85EFAC),
              ),
              _StatPill(
                label: 'Happiness',
                value: '${summary.happiness}',
                color: const Color(0xFFFFD45C),
              ),
              _StatPill(
                label: 'Health',
                value: '${summary.health}',
                color: const Color(0xFFFF8A80),
              ),
              _StatPill(
                label: 'Smarts',
                value: '${summary.smarts}',
                color: const Color(0xFF69C6FF),
              ),
              _StatPill(
                label: 'Looks',
                value: '${summary.looks}',
                color: const Color(0xFFFF8FB1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.pixelifySans(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationshipsCard extends StatelessWidget {
  const _RelationshipsCard({required this.relationships});

  final List<String> relationships;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1D17),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'People along the way',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final person in relationships)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8FB1).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 11,
                        color: Color(0xFFFF8FB1),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        person,
                        style: const TextStyle(
                          color: Color(0xFFFF8FB1),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldRewardCard extends StatelessWidget {
  const _GoldRewardCard({required this.gold});

  final int gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD45C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD45C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.paid_rounded, color: Color(0xFFFFD45C), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This life banked $gold gold to your account.',
              style: const TextStyle(
                color: Color(0xFFFFD45C),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ranked scorecard.
///
/// Shows the parts, not just the total. A single number tells you where you
/// finished; the breakdown tells you which of the three things to do
/// differently — and the survival row in particular only makes sense once you
/// can see it is a multiplier rather than an addition.
class _RankedScoreCard extends StatelessWidget {
  const _RankedScoreCard({required this.score});

  final RankedScore score;

  static Color _gradeColour(String grade) => switch (grade) {
    'S' => const Color(0xFFFFD45C),
    'A' => const Color(0xFF85EFAC),
    'B' => const Color(0xFF69C6FF),
    'C' => const Color(0xFFB388FF),
    'D' => const Color(0xFFF2C66D),
    _ => const Color(0xFFFF8FB1),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _gradeColour(score.grade);
    final chip = AppTheme.tintedChip(accent, alpha: 0.16);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RANKED',
                style: GoogleFonts.pixelifySans(
                  color: chip.ink,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                score.grade,
                style: GoogleFonts.pixelifySans(
                  color: accent,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${score.total}',
              style: GoogleFonts.pixelifySans(
                color: Colors.white,
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rankedGradeBlurb(score.grade),
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _ScoreLine(label: 'Wealth', value: '${score.wealthPoints}'),
          _ScoreLine(
            label: 'Understanding',
            value: '${score.understandingPoints}',
          ),
          // Written as a multiplication because that is what it is, and
          // because seeing "x0.62" next to a big wealth number is the whole
          // argument for not dying at thirty-five.
          _ScoreLine(
            label: 'Still standing',
            value: '×${score.survivalMultiplier.toStringAsFixed(2)}',
            highlight: score.survivalMultiplier < 0.9,
          ),
        ],
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.pixelifySans(
            color: highlight ? const Color(0xFFFF8474) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// One ending you have not found yet, and a nudge towards it.
///
/// Reads the collection at build time rather than taking it as an argument,
/// because it has to reflect the ending *this* run just added — the epilogue
/// records the ending on the way in, so a card handed a snapshot from before
/// that would suggest chasing the one you are looking at.
class _NextEndingCard extends StatelessWidget {
  const _NextEndingCard();

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<UserStatsController>().stats;
    final found = stats.discoveredEndings.toSet();
    final missing =
        LifeEndingArchetype.values
            .where((e) => !found.contains(e.name))
            .toList()
          ..sort((a, b) => a.chaseOrder.compareTo(b.chaseOrder));

    final total = LifeEndingArchetype.values.length;
    final have = total - missing.length;

    if (missing.isEmpty) {
      return _EndingsPanel(
        accent: const Color(0xFFE1BB72),
        icon: Icons.emoji_events_rounded,
        title: 'Every ending found',
        body:
            'All $total of them. There is nothing left to collect — which '
            'means the next run is just for the score.',
        progress: 1,
        label: '$total / $total',
      );
    }

    // The most worth chasing, not the first in the enum — see
    // [LifeEndingHint.chaseOrder]. Deterministic rather than random: a card
    // that suggests something different every time you glance at it is a slot
    // machine, and re-reading the same suggestion is how somebody actually
    // decides to go after it.
    final next = missing.first;

    return _EndingsPanel(
      accent: next.color,
      icon: next.icon,
      title: 'Still to find: ${next.label}',
      body: next.howToReach,
      progress: have / total,
      label: '$have / $total',
    );
  }
}

class _EndingsPanel extends StatelessWidget {
  const _EndingsPanel({
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
    required this.progress,
    required this.label,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String body;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(accent, alpha: 0.14);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: FittedLabel(
                  title,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.pixelifySans(
                  color: chip.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.black.withValues(alpha: 0.28),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}
