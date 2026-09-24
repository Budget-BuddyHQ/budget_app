import 'package:flutter/material.dart';

import '../models_Like_Skins_and_lessons_templates/life_activities.dart';
import '../models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import '../models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'life_sim_controller.dart';

/// One thing a character can do while standing in a building in town.
///
/// **Why this exists.** Hiking, meditating, a run, a check-up, a library visit
/// and going out used to be rows in the Activities menu. They belong on the map:
/// the point of walking to the park is that the park is where you do park things.
/// So the menu no longer lists them, and each building lists what can be done in
/// it. The effects and the yearly limits are the ones they always had.
class TownThing {
  const TownThing({
    required this.id,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.perform,
    required this.gate,
    this.cost = 0,
  });

  final String id;
  final String title;
  final String blurb;
  final IconData icon;

  /// Coins, for the chip. Zero shows nothing.
  final int cost;

  /// Why it cannot be done right now, or null.
  final String? Function() gate;

  /// Does it. The result is in [LifeSimController.log] afterwards.
  final void Function() perform;
}

extension LifeTownThings on LifeSimController {
  /// What the character can do at [kind], for the building's screen.
  ///
  /// Empty when there is nothing to do there, and for a building that has only a
  /// conversation. Only what the character is old enough for is listed.
  List<TownThing> thingsToDoAt(TownSpotKind kind) {
    final out = <TownThing>[];

    for (final a in activitiesAt(kind)) {
      if (age < a.minAge) continue;
      out.add(
        TownThing(
          id: a.id,
          title: a.title,
          blurb: a.blurb,
          icon: a.icon,
          cost: a.cost > 0 && (!isDependent || a.earns) ? a.cost : 0,
          gate: () => activityGate(a),
          perform: () => doActivity(a.id),
        ),
      );
    }

    TownThing classic({
      required String id,
      required String title,
      required String blurb,
      required IconData icon,
      required LifeAction action,
      required VoidCallback run,
      int cost = 0,
    }) => TownThing(
      id: id,
      title: title,
      blurb: blurb,
      icon: icon,
      cost: isDependent ? 0 : cost,
      gate: () =>
          unavailableFor(action) ??
          (cost > 0 && !isDependent && money < cost
              ? 'Costs $cost coins'
              : null),
      perform: run,
    );

    switch (kind) {
      case TownSpotKind.gym:
        out.add(
          classic(
            id: 'town_gym',
            title: 'Work out',
            blurb: 'Free. +8 Health, +3 Looks.',
            icon: Icons.fitness_center_rounded,
            action: LifeAction.exercise,
            run: exercise,
          ),
        );
      case TownSpotKind.clinic:
        out.add(
          classic(
            id: 'town_doctor',
            title: 'See the doctor',
            blurb:
                'A check-up. +12 Health. The cheapest care is the kind you get '
                'before you need it.',
            icon: Icons.medical_services_rounded,
            action: LifeAction.doctor,
            cost: 60,
            run: visitDoctor,
          ),
        );
      case TownSpotKind.library:
        out.add(
          classic(
            id: 'town_library',
            title: 'Read at the library',
            blurb: 'Free. +2 Smarts, and the library pays double.',
            icon: Icons.local_library_rounded,
            action: LifeAction.library,
            run: visitLibrary,
          ),
        );
      case TownSpotKind.park:
        out.add(
          classic(
            id: 'town_go_out',
            title: 'Spend the afternoon out',
            blurb: 'An afternoon out. +6 Happiness.',
            icon: Icons.celebration_rounded,
            action: LifeAction.goOut,
            cost: 40,
            run: haveFun,
          ),
        );
      default:
        break;
    }
    return out;
  }
}
