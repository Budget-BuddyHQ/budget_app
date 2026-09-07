import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_unlocks.dart';

/// Buildings that want a lesson first.
///
/// **What this fixes.** The app was framed as financial literacy *with*
/// gamification, and the Academy sat off to one side as the one part that
/// felt like homework and the one part nothing depended on. A player could
/// finish the whole town, every minigame and a dozen lives without opening a
/// single lesson — so the reading was optional in the only sense that
/// matters: the game did not care whether it had happened.
///
/// The risk in fixing that is over-correcting into a town made of locked
/// doors, so most of these tests are about how *little* is locked.
void main() {
  Set<String> lessonsIn(String unitId) {
    final unit = lessonUnits.firstWhere((u) => u.id == unitId);
    return unit.lessons
        .where((l) => l.type == LessonNodeType.lesson)
        .map((l) => l.id)
        .toSet();
  }

  group('most of the town is open from the first step', () {
    test('a brand-new player can walk into most buildings', () {
      final open = TownSpotKind.values
          .where((k) => isSpotUnlocked(k, const <String>{}))
          .length;
      expect(
        open,
        greaterThanOrEqualTo(TownSpotKind.values.length - 4),
        reason: 'too much of the town is locked — a new player would walk '
            'into an empty map, which is a paywall made of homework',
      );
    });

    test('your own house and the park are never locked', () {
      // Places to *be* rather than to calculate. Locking somewhere to sit
      // behind a reading task is the version of this idea that makes people
      // hate it.
      expect(isSpotUnlocked(TownSpotKind.home, const {}), isTrue);
      expect(isSpotUnlocked(TownSpotKind.park, const {}), isTrue);
      expect(isSpotUnlocked(TownSpotKind.school, const {}), isTrue);
    });

    test('exactly the four documented buildings are locked', () {
      final locked = TownSpotKind.values
          .where((k) => !isSpotUnlocked(k, const <String>{}))
          .toSet();
      expect(locked, {
        TownSpotKind.bank,
        TownSpotKind.market,
        TownSpotKind.pawnShop,
        TownSpotKind.clinic,
      });
    });
  });

  group('a lock opens when the unit is genuinely done', () {
    test('finishing the unit opens the door', () {
      for (final unlock in kTownUnlocks) {
        expect(
          isSpotUnlocked(unlock.spotKind, lessonsIn(unlock.unitId)),
          isTrue,
          reason: '${unlock.spotKind.name} stays shut after finishing '
              '${unlock.unitName} — the lock can never be opened',
        );
      }
    });

    test('reading one page of six does not open it', () {
      for (final unlock in kTownUnlocks) {
        final lessons = lessonsIn(unlock.unitId);
        if (lessons.length < 2) continue;
        final partial = {lessons.first};
        expect(
          isSpotUnlocked(unlock.spotKind, partial),
          isFalse,
          reason: '${unlock.spotKind.name} opened for one lesson, which makes '
              'the lock decorative',
        );
      }
    });

    test('the wrong unit does not open the wrong door', () {
      final bankLessons = lessonsIn('unit_4');
      expect(isSpotUnlocked(TownSpotKind.bank, bankLessons), isTrue);
      expect(isSpotUnlocked(TownSpotKind.clinic, bankLessons), isFalse);
    });

    test('progress runs 0 to 1 and reaches 1 exactly when unlocked', () {
      for (final unlock in kTownUnlocks) {
        expect(unlockProgress(unlock.spotKind, const {}), 0);
        expect(unlockProgress(unlock.spotKind, lessonsIn(unlock.unitId)), 1);
      }
      // Unlocked buildings report full progress rather than zero, so a bar
      // drawn for them is never misleadingly empty.
      expect(unlockProgress(TownSpotKind.park, const {}), 1);
    });
  });

  group('every lock can explain itself', () {
    test('each names a real unit and says why', () {
      final unitIds = lessonUnits.map((u) => u.id).toSet();
      for (final unlock in kTownUnlocks) {
        expect(
          unitIds,
          contains(unlock.unitId),
          reason: '${unlock.spotKind.name} points at a unit that does not '
              'exist, so the door could never open',
        );
        expect(unlock.unitName.trim(), isNotEmpty);
        expect(
          unlock.why.trim().length,
          greaterThan(40),
          reason: 'a door that is simply shut teaches nothing and reads as a '
              'bug — every lock has to say what it wants and why',
        );
      }
    });

    test('the named unit actually has lessons in it', () {
      for (final unlock in kTownUnlocks) {
        expect(
          lessonsIn(unlock.unitId),
          isNotEmpty,
          reason: '${unlock.unitName} has no teaching lessons, so the lock '
              'would open for free',
        );
      }
    });

    test('lockedSpots lists what is still shut', () {
      expect(lockedSpots(const {}).length, kTownUnlocks.length);
      final everything = <String>{
        for (final u in kTownUnlocks) ...lessonsIn(u.unitId),
      };
      expect(lockedSpots(everything), isEmpty);
    });
  });
}
