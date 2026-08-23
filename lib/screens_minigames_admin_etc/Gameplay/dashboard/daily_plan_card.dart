import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/daily_plan_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/daily_quest.dart';
import '../../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../../widgets_custom_lotties/idle_hover_icon.dart';

/// The home screen's spine: today's ordered checklist.
///
/// This is the answer to "so many ways to teach — is that good?". Having
/// several game modes is a strength, but only if something tells the player
/// what to do next. This card is that something: three concrete, needs-based
/// actions each day, each routing into one surface, with a streak to reward
/// coming back. The modes stay; the confusion goes.
class DailyPlanCard extends StatelessWidget {
  const DailyPlanCard({
    super.key,
    required this.onOpenQuest,
    this.compact = false,
  });

  final void Function(DailyQuest quest) onOpenQuest;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyPlanController>(
      builder: (context, controller, _) {
        final plan = controller.plan;
        if (plan == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF15392D), Color(0xFF10281F)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Plan",
                          style: GoogleFonts.pixelifySans(
                            color: Colors.white,
                            fontSize: compact ? 20 : 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          plan.allDone
                              ? 'All done — see you tomorrow!'
                              : '${plan.completedCount} of ${plan.quests.length} done',
                          style: GoogleFonts.quicksand(
                            color: Colors.white.withValues(alpha: 0.64),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StreakBadge(days: plan.streakDays),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: plan.progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF85EFAC),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < plan.quests.length; i++) ...[
                _QuestRow(
                  quest: plan.quests[i],
                  done: plan.isDone(plan.quests[i].id),
                  isNext: plan.nextQuest?.id == plan.quests[i].id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onOpenQuest(plan.quests[i]);
                  },
                ),
                if (i != plan.quests.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final active = days > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: (active ? const Color(0xFFFF8A5B) : Colors.white).withValues(
          alpha: active ? 0.16 : 0.06,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (active ? const Color(0xFFFF8A5B) : Colors.white).withValues(
            alpha: active ? 0.4 : 0.12,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: active
                ? const Color(0xFFFF8A5B)
                : Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: GoogleFonts.pixelifySans(
              color: active
                  ? const Color(0xFFFF8A5B)
                  : Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.quest,
    required this.done,
    required this.isNext,
    required this.onTap,
  });

  final DailyQuest quest;
  final bool done;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !done,
      label: done ? '${quest.title} (done)' : quest.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isNext
                ? quest.accent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isNext
                  ? quest.accent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              _StatusDot(
                done: done,
                accent: quest.accent,
                icon: quest.icon,
                spriteMotif: quest.spriteMotif,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: done
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quest.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (done)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF85EFAC),
                  size: 20,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD45C).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${quest.xpReward}',
                    style: GoogleFonts.pixelifySans(
                      color: Color(0xFFFFD45C),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.done,
    required this.accent,
    required this.icon,
    this.spriteMotif,
  });

  final bool done;
  final Color accent;
  final IconData icon;
  final AmbientMotif? spriteMotif;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: done ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Opacity(
        opacity: done ? 0.5 : 1,
        child: spriteMotif == null
            ? IdleHoverIcon(
                // A wobble on top of the bob so the quest icons read as
                // genuinely playful rather than just gently floating.
                rotationAmplitude: 0.14,
                child: Icon(icon, color: accent, size: 20),
              )
            : IdleHoverIcon(
                // AmbientLottieCard already bobs on its own, so this only
                // adds the hover scale-up rather than a second, competing bob.
                idleAmplitude: 0,
                child: AmbientLottieCard(
                  motif: spriteMotif!,
                  semanticLabel: 'Finance Brawl',
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(2),
                  backgroundColor: Colors.transparent,
                  borderColor: Colors.transparent,
                ),
              ),
      ),
    );
  }
}
