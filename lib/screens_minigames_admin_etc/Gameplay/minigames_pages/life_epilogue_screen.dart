import 'package:flutter/material.dart';

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
  });

  final LifeSummary summary;

  /// Personal bests this run beat, from `recordLifeRun`. Empty for a first
  /// life (nothing to beat yet) and empty when replaying an old screen, so
  /// the banner is genuinely an event rather than decoration.
  final Set<LifeBest> bestsBeaten;

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
              _ArchetypeCard(archetype: archetype),
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
              const Icon(Icons.workspace_premium_rounded,
                  color: _gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bests.length == 1 ? 'New personal best' : 'New personal bests',
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
