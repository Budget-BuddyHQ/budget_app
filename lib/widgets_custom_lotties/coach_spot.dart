import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import '../models_Like_Skins_and_lessons_templates/money_snapshot_source.dart';
import '../screens_minigames_admin_etc/coach/coach_screen.dart';
import '../themes_colors/app_theme.dart';
import 'fitted_label.dart';

/// The coach, as one card that can go anywhere.
///
/// **Why this exists.** The analyser in `money_analyzer.dart` is the most
/// interesting thing this app does — it reads five separate areas of a
/// player's history and tells them the one thing worth knowing — and until
/// now it was reachable through exactly one route: the sixth tab of the Money
/// Habits screen. A player who never opened that tab never met it. Something
/// that only speaks when you go and ask it is a report, and this was supposed
/// to be a coach.
///
/// So the finding comes to them instead. `MoneyReport.headline` already
/// existed for precisely this — "the single line to show if there is only
/// room for one" — and had no caller.
///
/// **Why it is a widget rather than a notification.** A coach that interrupts
/// gets dismissed. This sits in the flow of a screen the player already
/// wanted to be on, says one true thing about their own numbers, and offers
/// one action. If they ignore it, nothing happens; the next finding will be
/// different because their history will be.
class CoachSpot extends StatelessWidget {
  const CoachSpot({
    super.key,
    this.onlyDimensions,
    this.compact = false,
    this.margin = EdgeInsets.zero,
    this.debugReport,
  });

  /// Show a finding only if it belongs to one of these areas.
  ///
  /// The point is relevance, not filtering for its own sake. On the arcade
  /// screen a note about your savings rate is worth reading; a note about
  /// logging habits daily is nagging in the wrong room. When nothing matches,
  /// this renders nothing at all rather than falling back to something
  /// off-topic — an empty space is better than a coach that talks to fill it.
  final Set<MoneyDimension>? onlyDimensions;

  /// Drops the evidence line, for places with little vertical room.
  final bool compact;

  /// Spacing applied **only when a finding renders**.
  ///
  /// Belongs to the widget rather than the caller because this disappears
  /// entirely for a player with no history. A `SizedBox` on either side of it
  /// in a `Column` does not disappear with it, so a silent coach would leave
  /// a double gap on exactly the screens a brand-new player sees first.
  final EdgeInsets margin;

  /// Bypasses the player's real history. Tests only.
  final MoneyReport? debugReport;

  @override
  Widget build(BuildContext context) {
    final report =
        debugReport ??
        analyseMoney(
          buildMoneySnapshot(context.watch<UserStatsController>().stats),
        );

    // Nothing honest to say yet. A brand-new player has no history, and five
    // findings fired at once would all be true and none of them useful.
    if (report.isNewcomer) return const SizedBox.shrink();

    final finding = _pick(report);
    if (finding == null) return const SizedBox.shrink();

    final accent = _accentFor(finding.kind);

    return Padding(
      padding: margin,
      child: Semantics(
        button: true,
        label: 'Coach: ${finding.title}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            onTap: () => openCoach(context),
            child: Ink(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_iconFor(finding.kind), size: 17, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedLabel(
                          _labelFor(finding.kind),
                          style: GoogleFonts.pixelifySans(
                            color: accent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.textMuted.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    finding.title,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textPrimary,
                      fontSize: 14.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 5),
                    // The number out of their own data. This is the line that
                    // makes it a coach rather than a horoscope — every finding
                    // has to be able to show its working.
                    Text(
                      finding.evidence,
                      style: GoogleFonts.quicksand(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The most relevant finding for this surface, or null.
  MoneyFinding? _pick(MoneyReport report) {
    final wanted = onlyDimensions;
    if (wanted == null) return report.headline;
    for (final finding in report.findings) {
      if (wanted.contains(finding.dimension)) return finding;
    }
    return null;
  }

  static Color _accentFor(MoneyFindingKind kind) => switch (kind) {
    MoneyFindingKind.fix => const Color(0xFFFFB084),
    MoneyFindingKind.watch => const Color(0xFF58C7FF),
    MoneyFindingKind.strength => AppTheme.greenPrimary,
  };

  static IconData _iconFor(MoneyFindingKind kind) => switch (kind) {
    MoneyFindingKind.fix => Icons.priority_high_rounded,
    MoneyFindingKind.watch => Icons.visibility_outlined,
    MoneyFindingKind.strength => Icons.check_circle_outline_rounded,
  };

  /// Deliberately not "Warning" / "Problem".
  ///
  /// This app is used by nine-year-olds and the findings are about their own
  /// money behaviour. "Your coach noticed" is the same information without
  /// the implication that they are in trouble.
  static String _labelFor(MoneyFindingKind kind) => switch (kind) {
    MoneyFindingKind.fix => 'YOUR COACH NOTICED',
    MoneyFindingKind.watch => 'WORTH WATCHING',
    MoneyFindingKind.strength => 'YOU ARE DOING THIS WELL',
  };
}

/// Opens the full Coach read-out.
///
/// Pushes [CoachScreen] rather than the Money Habits screen opened on its
/// sixth tab, which is what this did before the Coach became a destination of
/// its own. Pushing Money Habits meant mounting five other tabs — Today,
/// Week, Find, Challenges, Jar — to show one of them, and it put a second
/// live instance of that screen on top of the one already alive in
/// `MainNavigation`'s `IndexedStack`.
void openCoach(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CoachScreen()));
}
