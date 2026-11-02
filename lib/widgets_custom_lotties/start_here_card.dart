import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../themes_colors/app_theme.dart';

/// The three things to try first, in order: learn, play, see what it means.
///
/// **Why.** Budget Buddy does a lot: lessons, a life simulator, a town, four
/// arcade games, a market, a coach. Somebody with a few minutes, a judge for
/// one, could open it and not know where to begin, and the parts are at their
/// best together: a lesson teaches an idea, a Life puts it to work, and the
/// Coach reads how it went and points back to the lesson. This card walks that
/// loop once, ticks each step off as it is done, and goes away after.
enum StartStep { lesson, life, coach }

/// What has been visited, kept per device. The lesson step is read from the
/// account instead (a completed lesson), so it needs no flag here.
class StartHereProgress extends ChangeNotifier {
  StartHereProgress._();

  static final StartHereProgress instance = StartHereProgress._();

  static const String _lifeKey = 'start_here_life_v1';
  static const String _coachKey = 'start_here_coach_v1';
  static const String _hiddenKey = 'start_here_hidden_v1';

  bool lifeOpened = false;
  bool coachOpened = false;
  bool hidden = false;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      lifeOpened = prefs.getBool(_lifeKey) ?? false;
      coachOpened = prefs.getBool(_coachKey) ?? false;
      hidden = prefs.getBool(_hiddenKey) ?? false;
      notifyListeners();
    } catch (_) {
      // No storage: the card shows, and steps tick for this session only.
    }
  }

  /// Records a visit. Safe to call from anywhere, any number of times.
  Future<void> mark(StartStep step) async {
    switch (step) {
      case StartStep.life:
        if (lifeOpened) return;
        lifeOpened = true;
      case StartStep.coach:
        if (coachOpened) return;
        coachOpened = true;
      case StartStep.lesson:
        return;
    }
    // After the current frame: this is called from screens' initState, and
    // the card on Home must not rebuild in the middle of another build.
    Future<void>.microtask(notifyListeners);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(step == StartStep.life ? _lifeKey : _coachKey, true);
    } catch (_) {}
  }

  Future<void> hide() async {
    hidden = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hiddenKey, true);
    } catch (_) {}
  }

  @visibleForTesting
  void debugReset() {
    lifeOpened = false;
    coachOpened = false;
    hidden = false;
    _loaded = false;
  }
}

class StartHereCard extends StatefulWidget {
  const StartHereCard({
    super.key,
    required this.onLesson,
    required this.onLife,
    required this.onCoach,
  });

  final VoidCallback onLesson;
  final VoidCallback onLife;
  final VoidCallback onCoach;

  @override
  State<StartHereCard> createState() => _StartHereCardState();
}

class _StartHereCardState extends State<StartHereCard> {
  final StartHereProgress _progress = StartHereProgress.instance;

  @override
  void initState() {
    super.initState();
    _progress.addListener(_changed);
    _progress.load();
  }

  @override
  void dispose() {
    _progress.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lessonDone = context
        .watch<UserStatsController>()
        .stats
        .completedLessons
        .isNotEmpty;
    final done = [lessonDone, _progress.lifeOpened, _progress.coachOpened];
    if (_progress.hidden || done.every((d) => d)) {
      return const SizedBox.shrink();
    }
    final next = done.indexOf(false);
    const gold = Color(0xFFFFC800);

    return Container(
      key: const ValueKey('start-here'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: gold, width: 2),
        boxShadow: AppTheme.ledgeShadow(gold, restAlpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Start here',
                  style: GoogleFonts.pixelifySans(
                    color: gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${done.where((d) => d).length} of 3',
                style: AppTheme.numeric(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Three steps that show how Budget Buddy works.',
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _Step(
            key: const ValueKey('start-here-lesson'),
            number: 1,
            title: 'Take a lesson',
            body: 'Learn one money idea in a few minutes.',
            icon: Icons.school_rounded,
            done: done[0],
            isNext: next == 0,
            onTap: widget.onLesson,
          ),
          _Step(
            key: const ValueKey('start-here-life'),
            number: 2,
            title: 'Live a Life',
            body: 'Put it to work: a job, a budget, choices that cost money.',
            icon: Icons.explore_rounded,
            done: done[1],
            isNext: next == 1,
            onTap: widget.onLife,
          ),
          _Step(
            key: const ValueKey('start-here-coach'),
            number: 3,
            title: 'Check your Coach',
            body: 'See what your choices say, and the lesson that helps.',
            icon: Icons.insights_rounded,
            done: done[2],
            isNext: next == 2,
            onTap: widget.onCoach,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('start-here-hide'),
              onPressed: _progress.hide,
              child: Text(
                'Hide',
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.done,
    required this.isNext,
    required this.onTap,
  });

  final int number;
  final String title;
  final String body;
  final IconData icon;
  final bool done;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = done ? AppTheme.greenPrimary : AppTheme.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isNext ? AppTheme.panelStrong : AppTheme.inset,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isNext ? AppTheme.greenPrimary : AppTheme.outline,
                width: isNext ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? AppTheme.greenPrimary : AppTheme.inset,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF0B1418),
                          size: 20,
                        )
                      : Text(
                          '$number',
                          style: GoogleFonts.pixelifySans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.pixelifySans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white70,
                        ),
                      ),
                      Text(
                        body,
                        style: GoogleFonts.quicksand(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isNext ? Icons.chevron_right_rounded : icon,
                  color: isNext ? AppTheme.greenPrimary : accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
