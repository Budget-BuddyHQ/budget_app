import 'coach_memory.dart';
import 'money_analyzer.dart';

/// What the Coach pop-up says, when it has something worth saying.
///
/// **Asked for as:** *"make pop ups for the user to check their coach and
/// guide them how they can check."* The Coach only spoke when somebody opened
/// it, and plenty of players never did, so a fix they had earned sat there
/// unclaimed and a new finding went unread.
///
/// Two kinds, the good news first:
///  * [CoachNudgeKind.fixed]: something the Coach flagged last time is no
///    longer true, and there is a reward waiting for it.
///  * [CoachNudgeKind.found]: the Coach has noticed something new.
///
/// At most once a day, and never twice about the same thing within
/// [kCoachNudgeRepeatAfter], because a pop-up that keeps coming back is a
/// pop-up people learn to close without reading.
enum CoachNudgeKind { fixed, found }

const Duration kCoachNudgeRepeatAfter = Duration(days: 30);

class CoachNudge {
  const CoachNudge({
    required this.kind,
    required this.title,
    required this.ids,
    this.count = 1,
  });

  final CoachNudgeKind kind;

  /// The first thing it is about, by its Coach title.
  final String title;

  /// How many things it is about.
  final int count;

  /// Every id this pop-up covers, recorded so it is not repeated.
  final List<String> ids;
}

/// The next pop-up, or null for none.
///
/// [lastOpen] and [unclaimedFixed] are what the Coach remembered from the
/// last time it was opened (`CoachMemory.open` and `CoachMemory.fixed`).
/// [weakSkills] are the weak quiz topics, which the Coach lists as things to
/// improve under `skill:<id>`. [nudged] is id to when it was last announced.
CoachNudge? nextCoachNudge({
  required MoneyReport report,
  required List<String> weakSkills,
  required Map<String, String> lastOpen,
  required Map<String, String> unclaimedFixed,
  required Map<String, DateTime> nudged,
  required DateTime now,
  DateTime? lastShown,
}) {
  if (lastShown != null &&
      lastShown.year == now.year &&
      lastShown.month == now.month &&
      lastShown.day == now.day) {
    return null;
  }
  bool fresh(String id) {
    final when = nudged[id];
    return when == null || now.difference(when) >= kCoachNudgeRepeatAfter;
  }

  final flaggedNow = <String>{
    for (final f in report.findings)
      if (_toImprove(f)) f.id,
    for (final s in weakSkills) 'skill:$s',
  };

  // Fixed: flagged last visit and not now, or already moved to "fixed" and
  // not yet claimed.
  final fixed = <String, String>{
    for (final e in lastOpen.entries)
      if (!flaggedNow.contains(e.key)) e.key: e.value,
    ...unclaimedFixed,
  }..removeWhere((id, _) => !fresh(id));
  if (fixed.isNotEmpty) {
    return CoachNudge(
      kind: CoachNudgeKind.fixed,
      title: fixed.values.first,
      count: fixed.length,
      ids: fixed.keys.toList(),
    );
  }

  if (report.isNewcomer) return null;
  for (final f in report.findings) {
    if (!_toImprove(f)) continue;
    if (lastOpen.containsKey(f.id) || !fresh(f.id)) continue;
    return CoachNudge(kind: CoachNudgeKind.found, title: f.title, ids: [f.id]);
  }
  return null;
}

/// What `CoachMemory` counts as something to improve. The newcomer card goes
/// away just by using the app, so it is never news.
bool _toImprove(MoneyFinding f) =>
    CoachMemory.isToImprove(f) && f.id != 'start_here';
