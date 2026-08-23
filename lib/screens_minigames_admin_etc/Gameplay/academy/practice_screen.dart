import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../models_Like_Skins_and_lessons_templates/lesson.dart';
import '../../../models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import 'quiz_widgets.dart';

/// A repeatable practice run over a unit's extra questions.
///
/// Unlike a quiz or unit test this never marks anything complete — it exists so
/// a player can rehearse a shaky skill without the pressure of a graded node.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.unit});

  final LessonUnit unit;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final List<QuizQuestion> _questions = practiceFor(widget.unit.id);

  int _index = 0;
  int? _selected;
  int _correct = 0;
  final List<QuizQuestion> _missed = <QuizQuestion>[];
  bool _saving = false;

  bool get _finished => _questions.isNotEmpty && _index >= _questions.length;

  void _select(int optionIndex) {
    if (_selected != null) {
      return;
    }
    final question = _questions[_index];
    final isCorrect = optionIndex == question.correctIndex;
    setState(() {
      _selected = optionIndex;
      if (isCorrect) {
        _correct++;
      } else {
        _missed.add(question);
      }
    });
    AppSoundService.play(
      isCorrect ? AppSoundEffect.success : AppSoundEffect.error,
    );
  }

  Future<void> _finish() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);

    final controller = context.read<UserStatsController>();
    final missedSkills = _missed.map((q) => q.skillId).toSet();
    // Skills that came up and were answered right everywhere they appeared are
    // no longer weak.
    final recovered = _questions
        .map((q) => q.skillId)
        .toSet()
        .difference(missedSkills);

    final result = await controller.recordPracticeSession(
      unitId: widget.unit.id,
      correct: _correct,
      total: _questions.length,
      missedSkills: missedSkills,
    );
    await controller.clearWeakSkills(recovered);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    GameToast.show(
      context,
      title: 'Practice saved',
      message: '$_correct/${_questions.length} correct. ${result.message}',
      icon: Icons.fitness_center_rounded,
      accent: const Color(0xFF69C6FF),
      soundEffect: AppSoundEffect.celebration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.panel,
      appBar: AppBar(
        backgroundColor: AppTheme.panel,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Practice',
          style: GoogleFonts.baloo2(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.villageMapBackground,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppTheme.panel.withValues(alpha: 0.78),
            ),
          ),
          SafeArea(
            child: _questions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No practice questions for this unit yet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            Text(
                              widget.unit.title,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_finished)
                              QuizResultsCard(
                                correct: _correct,
                                total: _questions.length,
                                missed: _missed,
                              )
                            else
                              QuizQuestionCard(
                                questionNumber: _index + 1,
                                totalQuestions: _questions.length,
                                question: _questions[_index],
                                selectedOption: _selected,
                                onSelect: _select,
                              ),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1D17),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          child: _buildAction(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction() {
    if (_finished) {
      return FilledButton(
        onPressed: _saving ? null : _finish,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2F9E68),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(
          _saving ? 'Saving...' : 'Done',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      );
    }

    if (_selected == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Tap an answer to continue',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final isLast = _index == _questions.length - 1;
    return FilledButton(
      onPressed: () => setState(() {
        _index++;
        _selected = null;
      }),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFFD45C),
        foregroundColor: const Color(0xFF3C2B00),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(
        isLast ? 'See Results' : 'Next Question',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}
