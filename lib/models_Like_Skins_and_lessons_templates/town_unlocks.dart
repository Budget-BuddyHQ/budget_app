import 'lesson.dart';
import 'lesson_data.dart';
import 'town_spot_models.dart';

/// Buildings that stay shut until you have read the thing they are about.
///
/// # Why the Academy needed to pay into the game
///
/// The app was framed as financial literacy *with gamification*, and then the
/// Academy sat off to one side as a reading section — the one part that felt
/// like homework and the one part nothing else depended on. A player could
/// finish the entire town, every minigame and a dozen lives without opening
/// a single lesson, which meant the reading was optional in the only sense
/// that matters: the game did not care whether you had done it.
///
/// So four of the twelve buildings are locked behind the unit that explains
/// them. Not as a punishment — as the answer to "why would I read that?"
///
/// # Why only four
///
/// Twelve locked buildings would be a paywall made of homework, and a new
/// player would walk into an empty town. Eight are open from the first step,
/// which is more than enough town to play. The locked four are the ones whose
/// decisions are genuinely unreadable without the idea behind them:
///
///  * The **bank** is compound growth. Without it, "leave it there" is just a
///    button that seems to do nothing.
///  * The **pawn shop** is what things are really worth, and it is the one
///    building that can take advantage of a player who does not know.
///  * The **clinic** is insurance — a cost that looks pointless right up
///    until the year it is not.
///  * The **market stalls** are unit pricing, which is the skill the whole
///    building is built around.
///
/// # Why the lock says what it wants
///
/// A door that is simply shut teaches nothing and reads as a bug. Each one
/// names the unit, so the lock is a signpost rather than a wall — the point
/// is to send somebody to a lesson, not to keep them out of a building.
class TownUnlock {
  const TownUnlock({
    required this.spotKind,
    required this.unitId,
    required this.unitName,
    required this.why,
  });

  final TownSpotKind spotKind;

  /// The unit that opens it, from `lesson_data.dart`.
  final String unitId;

  /// Shown on the lock, so the player knows where to go.
  final String unitName;

  /// Why this particular building needs this particular idea.
  final String why;
}

/// The four locked buildings.
const List<TownUnlock> kTownUnlocks = <TownUnlock>[
  TownUnlock(
    spotKind: TownSpotKind.bank,
    unitId: 'unit_4',
    unitName: 'Investing Basics',
    why:
        'The bank is about money that grows on its own. Until that idea has '
        'landed, leaving it there looks like a button that does nothing.',
  ),
  TownUnlock(
    spotKind: TownSpotKind.market,
    unitId: 'unit_1',
    unitName: 'Budgeting',
    why:
        'The stalls are about what things really cost per unit — which is a '
        'question you have to know to ask before the answer is any use.',
  ),
  TownUnlock(
    spotKind: TownSpotKind.pawnShop,
    unitId: 'unit_12',
    unitName: 'Big Purchases',
    why:
        'This is the one building that can take advantage of somebody who '
        'does not know what their things are worth.',
  ),
  TownUnlock(
    spotKind: TownSpotKind.clinic,
    unitId: 'unit_13',
    unitName: 'Protecting Your Money',
    why:
        'Insurance looks like a waste right up until the year it is not. '
        'That is hard to see from inside a single good year.',
  ),
];

/// The unlock guarding [kind], or null when the building is always open.
TownUnlock? unlockFor(TownSpotKind kind) {
  for (final unlock in kTownUnlocks) {
    if (unlock.spotKind == kind) return unlock;
  }
  return null;
}

/// Whether [kind] is open, given the lessons finished so far.
///
/// A unit counts as done when **every teaching lesson in it** is complete.
/// Deliberately not "any lesson in the unit" — opening a building for reading
/// one page of six would make the lock decorative — and deliberately not the
/// quizzes, because the point is that the idea has been *met*, not that it
/// has been assessed. The Coach handles assessment.
bool isSpotUnlocked(TownSpotKind kind, Set<String> completedLessons) {
  final unlock = unlockFor(kind);
  if (unlock == null) return true;

  final unit = lessonUnits.where((u) => u.id == unlock.unitId).firstOrNull;
  // A unit that has been renamed or removed must not lock a building
  // forever. Failing open is right here: the worst case is a building that
  // opens early, against a town that can never be finished.
  if (unit == null) return true;

  for (final lesson in unit.lessons) {
    if (lesson.type != LessonNodeType.lesson) continue;
    if (!completedLessons.contains(lesson.id)) return false;
  }
  return true;
}

/// How far through the unlocking unit the player is, 0..1.
double unlockProgress(TownSpotKind kind, Set<String> completedLessons) {
  final unlock = unlockFor(kind);
  if (unlock == null) return 1;

  final unit = lessonUnits.where((u) => u.id == unlock.unitId).firstOrNull;
  if (unit == null) return 1;

  final teaching = unit.lessons
      .where((l) => l.type == LessonNodeType.lesson)
      .toList();
  if (teaching.isEmpty) return 1;

  final done = teaching.where((l) => completedLessons.contains(l.id)).length;
  return done / teaching.length;
}

/// Buildings still shut, for the "why is that greyed out" list.
List<TownUnlock> lockedSpots(Set<String> completedLessons) => [
  for (final unlock in kTownUnlocks)
    if (!isSpotUnlocked(unlock.spotKind, completedLessons)) unlock,
];
