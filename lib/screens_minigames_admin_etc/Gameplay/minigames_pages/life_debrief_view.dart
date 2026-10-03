import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models_Like_Skins_and_lessons_templates/life_debrief.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_run_record.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../utils/number_format.dart';

/// The end of a life, looked back on.
///
/// # What this replaced
///
/// The epilogue named the ending, listed five stats and paid the gold. Somebody
/// who retired at 68 with no emergency fund, everything in cash and money owed
/// got exactly the same screen as somebody who did none of that. It said what a
/// life *was* and nothing about what the player *did*, which is the part that
/// carries into the next run and into a real decision.
///
/// # What it shows, and why in this order
///
///  1. **A grade and one sentence.** What a player reads if they read nothing
///     else.
///  2. **The life's money as a line.** A number at the end is a fact; a curve is
///     a story, and the year it peaked or fell is the thing worth asking about.
///  3. **The areas**, so the grade is explained rather than announced.
///  4. **The life in numbers**, the handful of totals (saved, interest, missed
///     weeks, contacts) that turn "a net worth of 900" into something specific.
///  5. **The story**: the turning point, the money left on the table, the best
///     call. The part a player can learn from.
///  6. **What to do differently**, worst first and never only faults.
///  7. **One challenge for next time**, with a number in it.
///
/// Everything here reads from a [LifeDebrief], which is plain data, so the whole
/// screen can be exercised without playing a life.
class LifeDebriefView extends StatelessWidget {
  const LifeDebriefView({
    super.key,
    required this.debrief,
    this.practice = false,
    this.netWorthsOfEveryLife = const <int>[],
    this.thisNetWorth,
    this.seedText,
  });

  final LifeDebrief debrief;

  /// An ungraded run. It still gets a debrief, since the lessons are the same,
  /// but it says plainly that this one does not feed the Coach.
  final bool practice;

  /// Net worth of every life the player has filed, this one included, for the
  /// "how did this compare" line. Empty hides it.
  final List<int> netWorthsOfEveryLife;
  final int? thisNetWorth;

  /// The seed, to suggest replaying the same start against the challenge.
  final String? seedText;

  @override
  Widget build(BuildContext context) {
    final record = debrief.record;
    final story = debrief.story;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: _Header(debrief: debrief, practice: practice),
        ),
        if (record.curve.length >= 3) ...[
          const SizedBox(height: 14),
          _Panel(child: _MoneyCurve(record: record)),
        ],
        const SizedBox(height: 14),
        _Panel(child: _Areas(scores: debrief.scores)),
        if (_hasNumbers(record.tally)) ...[
          const SizedBox(height: 14),
          _Panel(child: _InNumbers(tally: record.tally)),
        ],
        if (!story.isEmpty) ...[
          const SizedBox(height: 14),
          _Panel(child: _Story(story: story)),
        ],
        if (debrief.findings.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Panel(child: _Findings(findings: debrief.shown())),
        ],
        if (debrief.nextRun.isNotEmpty) ...[
          const SizedBox(height: 14),
          _NextRun(challenge: debrief.nextRun, seedText: seedText),
        ],
        if (_rankLine() != null) ...[
          const SizedBox(height: 12),
          Text(
            _rankLine()!,
            textAlign: TextAlign.center,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  /// "This life ranks 2nd of 6 by net worth", or null when there is nothing to
  /// compare against.
  String? _rankLine() {
    final mine = thisNetWorth;
    if (mine == null || netWorthsOfEveryLife.length < 2) return null;
    final better = netWorthsOfEveryLife.where((v) => v > mine).length;
    final rank = better + 1;
    final total = netWorthsOfEveryLife.length;
    if (rank == 1) return 'Your best life so far by net worth, out of $total.';
    return 'This life ranks ${_ordinal(rank)} of $total by net worth.';
  }

  bool _hasNumbers(LifeRunTally t) =>
      t.incomeTotal > 0 ||
      t.shocksHit > 0 ||
      t.weeksMissed > 0 ||
      t.raises > 0 ||
      t.contactsMade > 0 ||
      t.townEarned > 0 ||
      t.interestPaid > 0 ||
      t.sideJobs > 0;
}

String _ordinal(int n) {
  final tens = n % 100;
  if (tens >= 11 && tens <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

const Color _good = Color(0xFF9BE870);
const Color _warn = Color(0xFFFFD45C);
const Color _bad = Color(0xFFFF8474);
const Color _sky = Color(0xFF7FD3FF);

/// The card every section sits in. One shape for all of them, so the screen
/// reads as one object rather than as seven cards competing.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.pixelifySans(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.debrief, required this.practice});

  final LifeDebrief debrief;
  final bool practice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.greenPrimary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.greenPrimary.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                debrief.grade,
                style: AppTheme.numeric(
                  color: AppTheme.greenPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coach read this run',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    debrief.headline,
                    style: AppTheme.numeric(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (practice) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _sky.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Practice run. It does not count towards your Coach history.',
              style: AppTheme.numeric(
                color: _sky,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The money curve
// ---------------------------------------------------------------------------

class _MoneyCurve extends StatelessWidget {
  const _MoneyCurve({required this.record});

  final LifeRunRecord record;

  @override
  Widget build(BuildContext context) {
    final curve = record.curve;
    final tally = record.tally;
    final first = curve.first.age;
    final last = curve.last.age;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your money, year by year'),
        const SizedBox(height: 12),
        Semantics(
          label:
              'A chart of your net worth from age $first to $last. It peaked '
              'at ${groupedNumber(tally.peakNetWorth)}.',
          child: SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _CurvePainter(
                points: curve,
                jobAge: tally.firstJobAge,
                peakAge: tally.peakAge,
                lowAge: tally.lowAge,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Age $first', style: _axis),
            Text('Age $last', style: _axis),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // A peak of nothing is not a peak worth a pill.
            if (tally.peakAge != null && tally.peakNetWorth > 0)
              _Pill(
                color: _warn,
                label:
                    'Peak ${groupedNumber(tally.peakNetWorth)} at '
                    '${tally.peakAge}',
              ),
            if (tally.lowAge != null && tally.lowNetWorth < 0)
              _Pill(
                color: _bad,
                label:
                    'Low ${groupedNumber(tally.lowNetWorth)} at '
                    '${tally.lowAge}',
              ),
            if (tally.firstJobAge != null)
              _Pill(color: _sky, label: 'First job at ${tally.firstJobAge}'),
          ],
        ),
      ],
    );
  }

  static final TextStyle _axis = AppTheme.numeric(
    color: const Color(0xFFC8DDD3),
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(color, alpha: 0.16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTheme.numeric(
          color: chip.ink,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A net-worth line with an area under it, a zero line when the life went
/// negative, and a dot on the year that mattered.
///
/// One scale places every mark. Hand-rolled rather than a charting package for
/// the same reason the price charts are: this app removed `fl_chart` after a
/// documented NaN and Infinity crash class, and a line through a few dozen
/// points needs nothing a package would add.
class _CurvePainter extends CustomPainter {
  const _CurvePainter({
    required this.points,
    required this.jobAge,
    required this.peakAge,
    required this.lowAge,
  });

  final List<LifeYearPoint> points;
  final int? jobAge;
  final int? peakAge;
  final int? lowAge;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;

    const padTop = 10.0;
    const padBottom = 8.0;
    final h = size.height - padTop - padBottom;

    var lo = points.first.netWorth;
    var hi = points.first.netWorth;
    for (final p in points) {
      lo = min(lo, p.netWorth);
      hi = max(hi, p.netWorth);
    }
    // Zero is always on the chart, so a life that went negative shows it, and a
    // flat life still has a range to draw in.
    lo = min(lo, 0);
    hi = max(hi, lo + 1);
    final span = (hi - lo).toDouble();

    final firstAge = points.first.age;
    final lastAge = points.last.age;
    final ageSpan = max(1, lastAge - firstAge).toDouble();

    double x(int age) => (age - firstAge) / ageSpan * size.width;
    double y(int worth) => padTop + (1 - (worth - lo) / span) * h;

    // The zero line, dashed, only when the life actually crosses below it.
    if (lo < 0) {
      final zeroY = y(0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1;
      for (var dx = 0.0; dx < size.width; dx += 8) {
        canvas.drawLine(
          Offset(dx, zeroY),
          Offset(min(dx + 4, size.width), zeroY),
          paint,
        );
      }
    }

    final line = Path()..moveTo(x(points.first.age), y(points.first.netWorth));
    for (var i = 1; i < points.length; i++) {
      line.lineTo(x(points[i].age), y(points[i].netWorth));
    }

    final baseline = y(lo < 0 ? 0 : lo);
    final area = Path.from(line)
      ..lineTo(x(points.last.age), baseline)
      ..lineTo(x(points.first.age), baseline)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.greenPrimary.withValues(alpha: 0.32),
            AppTheme.greenPrimary.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppTheme.greenPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    void dot(int? age, Color color) {
      if (age == null) return;
      final at = points.where((p) => p.age == age);
      if (at.isEmpty) return;
      final p = at.first;
      final center = Offset(x(p.age), y(p.netWorth));
      canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF0E2A1D));
      canvas.drawCircle(center, 4.2, Paint()..color = color);
    }

    dot(jobAge, _sky);
    dot(lowAge, _bad);
    dot(peakAge, _warn);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points != points ||
      old.jobAge != jobAge ||
      old.peakAge != peakAge ||
      old.lowAge != lowAge;
}

// ---------------------------------------------------------------------------
// The areas
// ---------------------------------------------------------------------------

class _Areas extends StatelessWidget {
  const _Areas({required this.scores});

  final Map<LifeArea, int> scores;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('How each part went'),
        const SizedBox(height: 12),
        for (final area in LifeArea.values)
          if (scores.containsKey(area)) ...[
            _AreaBar(label: area.label, score: scores[area]!),
            const SizedBox(height: 9),
          ],
      ],
    );
  }
}

class _AreaBar extends StatelessWidget {
  const _AreaBar({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 60
        ? _good
        : score >= 35
        ? _warn
        : _bad;

    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: AppTheme.numeric(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The life in numbers
// ---------------------------------------------------------------------------

class _InNumbers extends StatelessWidget {
  const _InNumbers({required this.tally});

  final LifeRunTally tally;

  @override
  Widget build(BuildContext context) {
    final tiles = <_Tile>[
      if (tally.incomeTotal > 0)
        _Tile(
          label: 'Of your pay, saved',
          value: '${(tally.savingsRate * 100).round()}%',
          color: tally.savingsRate >= 0.15
              ? _good
              : tally.savingsRate >= 0.05
              ? _warn
              : _bad,
        ),
      if (tally.shocksHit > 0)
        _Tile(
          label: 'Surprise bills covered',
          value: '${tally.shocksCovered} of ${tally.shocksHit}',
          color: tally.shocksCovered == tally.shocksHit ? _good : _bad,
        ),
      if (tally.interestPaid > 0)
        _Tile(
          label: 'Paid in interest',
          value: groupedNumber(tally.interestPaid),
          color: _bad,
        ),
      if (tally.weeksMissed > 0)
        _Tile(
          label: 'Weeks of work missed',
          value: '${tally.weeksMissed}',
          color: tally.timesLaidOff > 0 ? _bad : _warn,
        ),
      if (tally.raises > 0)
        _Tile(label: 'Pay rises', value: '${tally.raises}', color: _good),
      if (tally.contactsMade > 0)
        _Tile(
          label: 'Contacts, and leads',
          value: '${tally.contactsMade}, ${tally.referrals}',
          color: tally.referrals > 0 ? _good : _sky,
        ),
      if (tally.townEarned > 0)
        _Tile(
          label: 'Earned in town',
          value: groupedNumber(tally.townEarned),
          color: _warn,
        ),
      if (tally.sideJobs > 0)
        _Tile(
          label: 'Side jobs worked',
          value: '${tally.sideJobs}',
          color: _sky,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('This life in numbers'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Two across whenever they fit, one below that. Measured rather than
            // guessed from a phone breakpoint, like the money panel.
            final columns = constraints.maxWidth >= 260 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tile in tiles) SizedBox(width: width, child: tile),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.numeric(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The story
// ---------------------------------------------------------------------------

class _Story extends StatelessWidget {
  const _Story({required this.story});

  final LifeStory story;

  @override
  Widget build(BuildContext context) {
    final turning = story.turningPoint;
    final best = story.bestCall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('The story of it'),
        if (turning != null) ...[
          const SizedBox(height: 12),
          _Beat(
            color: _bad,
            icon: Icons.turn_right_rounded,
            heading: 'Turning point, age ${turning.age}',
            body: _turningBody(turning),
          ),
        ],
        if (best != null) ...[
          const SizedBox(height: 12),
          _Beat(
            color: _good,
            icon: Icons.thumb_up_alt_rounded,
            heading: 'Best call, age ${best.age}',
            body:
                'You picked "${best.chose}" (${_signed(best.moneyDelta)}). The '
                'worst option on the table would have left you '
                '${groupedNumber(best.edge)} worse off.',
          ),
        ],
        if (story.moneyLeftOnTable >= 60) ...[
          const SizedBox(height: 12),
          Text(
            'Across your decisions, the best money option would have kept '
            'about ${groupedNumber(story.moneyLeftOnTable)} more coins. '
            'Money is only one thing a choice can buy, so read that next to '
            'what each one gave you.',
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _turningBody(LifeMoment m) {
    if (m.kind == LifeMomentKind.shock) {
      return '${m.title} cost ${groupedNumber(-m.moneyDelta)}. '
          '${m.covered ? 'You had savings to cover it.' : 'You had to borrow, because nothing was set aside.'}';
    }
    final better = m.betterOption;
    final regret = m.regret;
    final tail = regret > 0 && better != null
        ? ' "$better" would have left you ${groupedNumber(regret)} better off '
              'on money alone.'
        : '';
    return '${m.title} You chose "${m.chose}" (${_signed(m.moneyDelta)}).$tail';
  }
}

String _signed(int value) =>
    value >= 0 ? '+${groupedNumber(value)}' : '-${groupedNumber(-value)}';

class _Beat extends StatelessWidget {
  const _Beat({
    required this.color,
    required this.icon,
    required this.heading,
    required this.body,
  });

  final Color color;
  final IconData icon;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(color, alpha: 0.14);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: chip.ink, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: AppTheme.numeric(
                    color: chip.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppTheme.numeric(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Findings and the next run
// ---------------------------------------------------------------------------

class _Findings extends StatelessWidget {
  const _Findings({required this.findings});

  final List<LifeFinding> findings;

  Color _color(LifeFindingKind kind) => switch (kind) {
    LifeFindingKind.fix => _bad,
    LifeFindingKind.watch => _warn,
    LifeFindingKind.strength => _good,
  };

  IconData _icon(LifeFindingKind kind) => switch (kind) {
    LifeFindingKind.fix => Icons.error_rounded,
    LifeFindingKind.watch => Icons.info_rounded,
    LifeFindingKind.strength => Icons.check_circle_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('What to do differently'),
        const SizedBox(height: 12),
        for (final finding in findings)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _icon(finding.kind),
                    size: 17,
                    color: _color(finding.kind),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        finding.title,
                        style: AppTheme.numeric(
                          color: _color(finding.kind),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        finding.evidence,
                        style: AppTheme.numeric(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        finding.action,
                        style: AppTheme.numeric(
                          color: Colors.white.withValues(alpha: 0.66),
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NextRun extends StatelessWidget {
  const _NextRun({required this.challenge, required this.seedText});

  final String challenge;
  final String? seedText;

  @override
  Widget build(BuildContext context) {
    final chip = AppTheme.tintedChip(AppTheme.greenPrimary, alpha: 0.16);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.greenPrimary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: chip.ink, size: 18),
              const SizedBox(width: 8),
              // Expanded, or the heading overflows a 320px phone by eight
              // pixels: an icon and a Pixelify line do not fit in a bare Row.
              Expanded(
                child: Text(
                  'Your challenge for next time',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (seedText != null) ...[
            const SizedBox(height: 8),
            Text(
              'Type $seedText on a new life to play this exact start again, '
              'and see whether you beat it.',
              style: AppTheme.numeric(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
