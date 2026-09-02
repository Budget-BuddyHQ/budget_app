import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson_extras.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson_sources.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/basic_calculator_dialog.dart';

// Shared quiz presentation, used by both the graded lesson/quiz flow in
// lesson_detail_screen.dart and the repeatable practice runs in
// practice_screen.dart.

class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    required this.selectedOption,
    required this.onSelect,
  });

  final int questionNumber;
  final int totalQuestions;
  final QuizQuestion question;
  final int? selectedOption;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final answered = selectedOption != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Row with Question Count & Calculator Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $questionNumber of $totalQuestions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            // Calculator Trigger Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => const BasicCalculatorDialog(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF85EFAC).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calculate_outlined,
                        color: Color(0xFF85EFAC),
                        size: 26,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Calculator',
                        style: GoogleFonts.pixelifySans(
                          color: const Color(0xFF85EFAC),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: (questionNumber - 1) / totalQuestions,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          question.prompt,
          style: GoogleFonts.pixelifySans(
            color: const Color(0xFFF7FFFB),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < question.options.length; i++) ...[
          _OptionCard(
            label: question.options[i],
            state: _resolveState(i),
            onTap: answered ? null : () => onSelect(i),
          ),
          if (i != question.options.length - 1) const SizedBox(height: 10),
        ],
        if (answered) ...[
          const SizedBox(height: 14),
          _ExplanationNote(
            icon: Icons.lightbulb_outline_rounded,
            accent: const Color(0xFFFFD45C),
            text: question.explanation,
          ),
          if (question.misconception != null &&
              selectedOption != question.correctIndex) ...[
            const SizedBox(height: 10),
            _ExplanationNote(
              icon: Icons.psychology_alt_outlined,
              accent: const Color(0xFF69C6FF),
              text: question.misconception!,
            ),
          ],
        ],
      ],
    );
  }

  _OptionState _resolveState(int index) {
    if (selectedOption == null) {
      return _OptionState.neutral;
    }
    if (index == question.correctIndex) {
      return _OptionState.correct;
    }
    if (index == selectedOption) {
      return _OptionState.incorrect;
    }
    return _OptionState.disabled;
  }
}

enum _OptionState { neutral, correct, incorrect, disabled }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;
    final Color text;
    final Widget? trailing;

    switch (state) {
      case _OptionState.neutral:
        fill = Colors.white.withValues(alpha: 0.06);
        border = Colors.white.withValues(alpha: 0.16);
        text = Colors.white;
        trailing = null;
      case _OptionState.correct:
        fill = const Color(0xFF2F9E68).withValues(alpha: 0.24);
        border = const Color(0xFF85EFAC);
        text = const Color(0xFFF7FFFB);
        trailing = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF85EFAC),
        );
      case _OptionState.incorrect:
        fill = const Color(0xFFE24B4A).withValues(alpha: 0.22);
        border = const Color(0xFFFF8474);
        text = const Color(0xFFF7FFFB);
        trailing = const Icon(Icons.cancel_rounded, color: Color(0xFFFF8474));
      case _OptionState.disabled:
        fill = Colors.white.withValues(alpha: 0.03);
        border = Colors.transparent;
        text = Colors.white.withValues(alpha: 0.38);
        trailing = null;
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                color: text,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing],
        ],
      ),
    );

    final wrapped = state == _OptionState.incorrect
        ? _ShakeX(child: card)
        : state == _OptionState.correct
        ? _PulseScale(child: card)
        : card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: wrapped,
      ),
    );
  }
}

/// A small tinted callout used for explanations and misconception notes.
class _ExplanationNote extends StatelessWidget {
  const _ExplanationNote({
    required this.icon,
    required this.accent,
    required this.text,
  });

  final IconData icon;
  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizResultsCard extends StatelessWidget {
  const QuizResultsCard({
    super.key,
    required this.correct,
    required this.total,
    required this.missed,
  });

  final int correct;
  final int total;
  final List<QuizQuestion> missed;

  @override
  Widget build(BuildContext context) {
    final passed = total == 0 || correct / total >= 0.7;

    // Group misses by skill so the advice names a topic rather than listing
    // every individual question back at the player.
    final missedSkills = <String>{
      for (final question in missed) question.skillId,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              Icon(
                passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                color: const Color(0xFFFFD45C),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                '$correct / $total correct',
                style: GoogleFonts.pixelifySans(
                  color: const Color(0xFFF7FFFB),
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? 'Nice work — those ideas are sticking.'
                    : 'Worth a re-read before the next unit.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (missedSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'WORTH REVISITING',
            style: GoogleFonts.pixelifySans(
              color: const Color(0xFFFFB084),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          for (final skill in missedSkills) ...[
            _MissedSkillRow(
              label: QuizSkills.label(skill),
              questions: missed
                  .where((question) => question.skillId == skill)
                  .toList(growable: false),
              sources: resolveSources(
                kQuizSkillSources[skill] ?? const <String>[],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

/// "CFPB · Credit reports and scores", tappable.
///
/// Shown on the topics a player got **wrong**, which is the moment a citation
/// is worth most: they have just been told an answer they did not expect, and
/// the right response to that is to go and check rather than to take the
/// app's word for it. A source line under a question they got right would be
/// decoration; here it is the next step.
class SourceLink extends StatelessWidget {
  const SourceLink({super.key, required this.source});

  final LessonSource source;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final launched = await launchUrl(
          Uri.parse(source.url),
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(source.url)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.open_in_new_rounded,
              size: 13,
              color: Color(0xFF9CDBFF),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                source.label,
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF9CDBFF),
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One skill the player got wrong, with the correct answers spelled out.
class _MissedSkillRow extends StatelessWidget {
  const _MissedSkillRow({
    required this.label,
    required this.questions,
    this.sources = const <LessonSource>[],
  });

  final String label;
  final List<QuizQuestion> questions;

  /// Where the correct answers for this topic come from. See [SourceLink].
  final List<LessonSource> sources;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.pixelifySans(
              color: const Color(0xFFF7FFFB),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final question in questions) ...[
            Text(
              question.prompt,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF85EFAC),
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.correctOption,
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF85EFAC),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (question != questions.last) const SizedBox(height: 12),
          ],
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
            const SizedBox(height: 8),
            Text(
              'Check it yourself',
              style: GoogleFonts.quicksand(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            for (final source in sources) SourceLink(source: source),
          ],
        ],
      ),
    );
  }
}

class _ShakeX extends StatefulWidget {
  const _ShakeX({required this.child});

  final Widget child;

  @override
  State<_ShakeX> createState() => _ShakeXState();
}

class _ShakeXState extends State<_ShakeX> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final decay = 1 - t;
        final dx = math.sin(t * math.pi * 6) * 8 * decay;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class _PulseScale extends StatefulWidget {
  const _PulseScale({required this.child});

  final Widget child;

  @override
  State<_PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<_PulseScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
