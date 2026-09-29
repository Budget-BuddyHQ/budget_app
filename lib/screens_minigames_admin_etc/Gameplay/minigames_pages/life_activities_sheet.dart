import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_activities.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_assets.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import 'life_assets_sheet.dart';
import 'life_ui_kit.dart';

/// **Activities:** a grid of categories, each opening onto a list of things to do
/// with a year.
///
/// **Asked for as:** the BitLife Activities tab, *"the largest menu in the game,
/// categorized into sub-lists for everything your character can actively do
/// that year,"* and *"the options are so simple, it's so boring... the late game
/// is so repetitive."* It was eight rows. It is a grid of eight categories and
/// well over forty things to do, each with a price, an age it opens at and a
/// limit on how often it pays.
///
/// What is not here: crime, drugs, gambling and fighting. Life is for ages nine
/// and up and stays family friendly, and a test holds the list to that.
const Color _accent = Color(0xFFB388FF);

Future<void> openActivities(
  BuildContext context,
  LifeSimController life, {
  required VoidCallback onVolunteer,
  required VoidCallback onSkills,
}) {
  return showLifeSheet<void>(
    context,
    builder: (_) => ActivitiesSheet(
      life: life,
      onVolunteer: onVolunteer,
      onSkills: onSkills,
    ),
  );
}

class ActivitiesSheet extends StatelessWidget {
  const ActivitiesSheet({
    super.key,
    required this.life,
    required this.onVolunteer,
    required this.onSkills,
  });

  final LifeSimController life;
  final VoidCallback onVolunteer;
  final VoidCallback onSkills;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        return LifeSheet(
          title: 'Activities',
          icon: Icons.apps_rounded,
          accent: _accent,
          subtitle: 'Choose how to spend the year',
          children: [
            LifeTileGrid(
              children: [
                for (final c in ActivityCategory.values)
                  LifeTile(
                    icon: c.icon,
                    title: c.label,
                    subtitle: c.blurb,
                    accent: c.accent,
                    badge: _badge(c),
                    onTap: () => _open(context, c),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// How many things in the category can be done right now.
  String? _badge(ActivityCategory c) {
    switch (c) {
      case ActivityCategory.sport:
        return life.sport == null ? null : '${life.sportStanding}';
      case ActivityCategory.special:
        return null;
      default:
        final open = activitiesIn(
          c,
        ).where((a) => life.activityGate(a) == null).length;
        return open == 0 ? null : '$open';
    }
  }

  void _open(BuildContext context, ActivityCategory c) {
    switch (c) {
      case ActivityCategory.sport:
        showLifeSheet<void>(context, builder: (_) => SportSheet(life: life));
      case ActivityCategory.special:
        showLifeSheet<void>(
          context,
          builder: (_) => SpecialCareersSheet(life: life),
        );
      default:
        showLifeSheet<void>(
          context,
          builder: (_) => ActivityListSheet(
            life: life,
            category: c,
            onVolunteer: onVolunteer,
            onSkills: onSkills,
          ),
        );
    }
  }
}

/// One category: the classic actions that belong to it, then the catalogue.
class ActivityListSheet extends StatelessWidget {
  const ActivityListSheet({
    super.key,
    required this.life,
    required this.category,
    required this.onVolunteer,
    required this.onSkills,
  });

  final LifeSimController life;
  final ActivityCategory category;
  final VoidCallback onVolunteer;
  final VoidCallback onSkills;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final classics = _classics();
        final catalogue = activitiesIn(category);
        // What can be done comes first and what cannot follows, so the page
        // reads as a list of things to try and not a wall of locks.
        final open = [
          for (final a in catalogue)
            if (life.activityGate(a) == null) a,
        ];
        final locked = [
          for (final a in catalogue)
            if (life.activityGate(a) != null) a,
        ];
        return LifeSheet(
          title: category.label,
          icon: category.icon,
          accent: category.accent,
          subtitle: category.blurb,
          children: [
            if (_townNote != null) _townNote!,
            for (final row in classics) row,
            for (final a in open) _row(context, a),
            if (locked.isNotEmpty) ...[
              const LifeSection('Not right now'),
              for (final a in locked) _row(context, a),
            ],
          ],
        );
      },
    );
  }

  /// Says where the things that are not listed here have gone.
  ///
  /// A row that vanishes with no word is a bug report waiting to happen. Hiking,
  /// the gym, the doctor and the library are done in town now, and this is how a
  /// player who goes looking for them finds out.
  Widget? get _townNote {
    final canGoOut = life.outingPermission.allowed;
    final text = switch (category) {
      // Somebody who cannot leave the house still needs a doctor. See
      // [_classics].
      ActivityCategory.mindBody when !canGoOut =>
        '${life.outingPermission.message} Hiking, running and the gym are done '
            'in town, so they wait. The doctor still comes to you.',
      ActivityCategory.mindBody =>
        'Hiking, running, meditating, reading, the gym and the doctor are done '
            'in town now. Tap the compass at the top to walk there: the park, '
            'the library, the gym and the clinic are on the map.',
      ActivityCategory.social =>
        'Going out is done in town now. Walk to the park or the cafe from the '
            'compass at the top.',
      ActivityCategory.learning =>
        'Reading and the museum are done at the library in town. Tap the '
            'compass at the top to walk there.',
      _ => null,
    };
    if (text == null) return null;
    return LifeCard(
      key: const ValueKey('activities-town-note'),
      accent: category.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.explore_rounded, color: category.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ActivityDef a) {
    final note = life.activityNote(a);
    return LifeRow(
      icon: a.icon,
      title: a.title,
      subtitle: note == null ? a.blurb : '${a.blurb}\n$note',
      accent: category.accent,
      disabledReason: life.activityGate(a),
      trailing: a.cost > 0 && (!life.isDependent || a.earns)
          ? LifeChip('-${a.cost}', color: const Color(0xFFFFD45C))
          : null,
      onTap: () => life.doActivity(a.id),
    );
  }

  /// The actions that were already in the game, in the category they belong to.
  List<Widget> _classics() {
    LifeRow classic({
      required IconData icon,
      required String title,
      required String detail,
      required LifeAction action,
      required VoidCallback onTap,
      int? cost,
      String? extraReason,
    }) {
      final note = life.budgetFor(action).label;
      return LifeRow(
        icon: icon,
        title: title,
        subtitle: note == null ? detail : '$detail\n$note',
        accent: category.accent,
        disabledReason:
            life.unavailableFor(action) ??
            extraReason ??
            (cost != null && !life.isDependent && life.money < cost
                ? 'Costs $cost coins'
                : null),
        trailing: cost == null || life.isDependent
            ? null
            : LifeChip('-$cost', color: const Color(0xFFFFD45C)),
        onTap: onTap,
      );
    }

    return switch (category) {
      // The gym and the library are in town now, and so is the doctor, except
      // for somebody who cannot leave the house. Below 16 health you are "too
      // unwell to leave", which is exactly when a doctor is what you need, and a
      // clinic you are not allowed to walk to would be a trap. So the menu keeps
      // the one row that has no other way in.
      ActivityCategory.mindBody =>
        life.outingPermission.allowed
            ? const <Widget>[]
            : [
                classic(
                  icon: Icons.medical_services_rounded,
                  title: 'See the doctor',
                  detail: 'A check-up at home. +12 Health.',
                  action: LifeAction.doctor,
                  cost: 60,
                  onTap: life.visitDoctor,
                ),
              ],
      ActivityCategory.social => [
        classic(
          icon: Icons.volunteer_activism_rounded,
          title: 'Volunteer',
          detail:
              'Give your time somewhere. Costs hours, pays nothing, and is worth it.',
          action: LifeAction.volunteer,
          onTap: onVolunteer,
        ),
      ],
      ActivityCategory.learning => [
        classic(
          icon: Icons.menu_book_rounded,
          title: life.isDependent ? 'Hit the books' : 'Take a course',
          detail: life.isDependent
              ? 'Study after school. +6 Smarts.'
              : 'Pay to learn something new. +6 Smarts.',
          action: LifeAction.study,
          cost: 30,
          onTap: life.study,
        ),
        classic(
          icon: Icons.auto_awesome_rounded,
          title: 'Practise a skill',
          detail: 'Music, sport, business and charisma. The career ladders.',
          action: LifeAction.practice,
          onTap: onSkills,
        ),
      ],
      ActivityCategory.money => [
        classic(
          icon: Icons.work_history_rounded,
          title: 'Work a side job',
          detail: 'Earn 40-100 coins. Costs Happiness and Health.',
          action: LifeAction.sideJob,
          onTap: life.workSideJob,
        ),
      ],
      _ => const <Widget>[],
    };
  }
}

// ---------------------------------------------------------------------------
// Sport
// ---------------------------------------------------------------------------

class SportSheet extends StatefulWidget {
  const SportSheet({super.key, required this.life});

  final LifeSimController life;

  @override
  State<SportSheet> createState() => _SportSheetState();
}

class _SportSheetState extends State<SportSheet> {
  LifeSport _pick = LifeSport.soccer;

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    const accent = Color(0xFF58C7FF);
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        final team = life.sport;
        return LifeSheet(
          title: 'Sport',
          icon: Icons.sports_soccer_rounded,
          accent: accent,
          subtitle: team == null
              ? 'Join a team, train, and see how far it goes'
              : '${team.label} · season ${life.seasonsPlayed + 1}',
          children: [
            if (team != null) ...[
              LifeCard(
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(team.icon, color: accent, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            team.label,
                            style: GoogleFonts.pixelifySans(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LifeBar(
                      label: 'Standing on the team',
                      value: life.sportStanding,
                      color: valueColor(life.sportStanding),
                      caption: life.sportStanding >= 85
                          ? 'Good enough for the scouts, and for a scholarship.'
                          : life.sportStanding >= 80
                          ? 'Good enough to help pay for college.'
                          : 'Standing follows your skill, your health and your training.',
                    ),
                    const SizedBox(height: 10),
                    LifeBar(
                      label: 'Skill',
                      value: life.sportSkill,
                      color: const Color(0xFF58C7FF),
                      height: 7,
                    ),
                  ],
                ),
              ),
              const LifeSection('This year'),
              LifeRow(
                icon: Icons.fitness_center_rounded,
                title: 'Train with the team',
                subtitle:
                    'Builds standing and skill, and a little health.\n'
                    '${life.trainGate() ?? '${3 - life.activityUses('train')} sessions left'}',
                accent: accent,
                disabledReason: life.trainGate(),
                onTap: life.trainWithTeam,
              ),
              LifeRow(
                icon: Icons.workspace_premium_rounded,
                title: 'Try out for a professional team',
                subtitle:
                    'Odds ${life.proTryoutChance}%. A pro career is short, and '
                    'it is why saving early matters so much.',
                accent: accent,
                disabledReason: life.proTryoutGate(),
                onTap: () => life.tryOutForPros(),
              ),
              LifeRow(
                icon: Icons.logout_rounded,
                title: 'Leave the team',
                subtitle: 'You can try out again another time.',
                accent: accent,
                onTap: life.leaveTeam,
              ),
            ] else ...[
              LifeDropdown<LifeSport>(
                label: 'Pick a sport',
                value: _pick,
                accent: accent,
                items: [
                  for (final s in LifeSport.values)
                    LifeDropdownItem<LifeSport>(
                      value: s,
                      label: s.label,
                      hint: s.blurb,
                    ),
                ],
                onChanged: (s) => setState(() => _pick = s),
              ),
              const SizedBox(height: 12),
              LifeCard(
                accent: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LifeBar(
                      label: 'Your chance of making the team',
                      value: life.tryoutOdds(),
                      color: valueColor(life.tryoutOdds()),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'It follows your sport skill and your health. Training '
                      'and looking after yourself change it. You can try out '
                      'twice a year.',
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
              const SizedBox(height: 12),
              LifeButton(
                label: 'Try out for ${_pick.label.toLowerCase()}',
                icon: _pick.icon,
                onPressed: life.tryoutGate(_pick) == null
                    ? () => _tryOut(context, life)
                    : null,
                note: life.tryoutGate(_pick),
              ),
              const LifeSection('Why join'),
              const LifeCard(
                child: Text(
                  'Being on a team builds health and friends. A strong player '
                  'can earn a scholarship that pays for part of college, and '
                  'the very best can turn pro.',
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _tryOut(BuildContext context, LifeSimController life) {
    final made = life.tryOut(_pick) && life.sport != null;
    GameToast.show(
      context,
      title: made ? 'You made the team' : 'Not this time',
      message: made
          ? 'Welcome to ${_pick.label.toLowerCase()}.'
          : 'Practice and good health change those odds.',
      icon: _pick.icon,
      accent: made ? const Color(0xFF85EFAC) : const Color(0xFFF2C66D),
    );
  }
}

// ---------------------------------------------------------------------------
// Special careers
// ---------------------------------------------------------------------------

/// Paths that are not on the job board: elected office, a professional contract,
/// a business of your own.
class SpecialCareersSheet extends StatelessWidget {
  const SpecialCareersSheet({super.key, required this.life});

  final LifeSimController life;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE9C46A);
    return ListenableBuilder(
      listenable: life,
      builder: (context, _) {
        return LifeSheet(
          title: 'Special careers',
          icon: Icons.workspace_premium_rounded,
          accent: accent,
          subtitle: 'Paths that are not on the job board',
          children: [
            LifeRow(
              icon: Icons.how_to_vote_rounded,
              title: 'Run for the town council',
              subtitle:
                  'Odds ${life.electionChance}%. A campaign costs 100, and '
                  'winning is a job with a salary and a ladder above it. '
                  'Charisma is what wins elections.',
              accent: accent,
              disabledReason: life.officeGate(),
              trailing: const LifeChip('-100', color: Color(0xFFFFD45C)),
              onTap: () {
                final ok = life.runForOffice();
                if (ok) {
                  GameToast.show(
                    context,
                    title: life.hasJob ? 'You won' : 'Not this time',
                    message: life.hasJob
                        ? 'You are now a ${life.job}.'
                        : 'Most people who win lost first.',
                    icon: Icons.how_to_vote_rounded,
                    accent: life.hasJob
                        ? const Color(0xFF85EFAC)
                        : const Color(0xFFF2C66D),
                  );
                }
              },
            ),
            LifeRow(
              icon: Icons.sports_soccer_rounded,
              title: 'Go professional',
              subtitle: life.sport == null
                  ? 'Join a team first, and build your standing.'
                  : 'Odds ${life.proTryoutChance}%. Needs a standing of 85, '
                        'and to be between 18 and 32.',
              accent: accent,
              disabledReason: life.proTryoutGate(),
              onTap: () => life.tryOutForPros(),
            ),
            LifeRow(
              icon: Icons.storefront_rounded,
              title: 'Start a business',
              subtitle:
                  'A market stall, an online shop or a restaurant. Some '
                  'years pay and some do not. That is the risk.',
              accent: accent,
              disabledReason: life.age < 18 ? 'You need to be 18' : null,
              onTap: () => showLifeSheet<void>(
                context,
                builder: (_) =>
                    ShopSheet(life: life, initialKind: AssetKind.business),
              ),
            ),
            LifeRow(
              icon: Icons.groups_rounded,
              title: 'Go to a networking event',
              subtitle:
                  'Meet people who know people.\n'
                  '${life.budgetFor(LifeAction.network).label ?? ''}',
              accent: accent,
              disabledReason:
                  life.unavailableFor(LifeAction.network) ??
                  (life.isDependent || life.money >= 25
                      ? null
                      : 'Costs 25 coins'),
              trailing: life.isDependent
                  ? null
                  : const LifeChip('-25', color: Color(0xFFFFD45C)),
              onTap: life.attendNetworkingEvent,
            ),
          ],
        );
      },
    );
  }
}
