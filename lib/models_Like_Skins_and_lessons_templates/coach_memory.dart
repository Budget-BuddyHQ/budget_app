import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'money_analyzer.dart';

/// Something the Coach flagged before that it no longer finds: the player
/// fixed it, and the Coach should say so.
class FixedFinding {
  const FixedFinding({required this.id, required this.title});

  final String id;
  final String title;
}

/// What the Coach has asked the player to work on, remembered on the device.
///
/// A finding only lives while the data behind it is true, so once a player
/// improves, the card just vanished — and nothing said they had done anything.
/// This remembers what was open last time, so a finding that drops off is
/// noticed and celebrated rather than silently missing.
class CoachMemory {
  CoachMemory({Map<String, String>? open, Map<String, String>? fixed})
    : open = open ?? <String, String>{},
      fixed = fixed ?? <String, String>{};

  static const String _openKey = 'coach_open_findings_v1';
  static const String _fixedKey = 'coach_fixed_findings_v1';

  /// Findings shown as something to improve last time, id to title.
  final Map<String, String> open;

  /// Findings fixed and not yet dismissed, id to title.
  final Map<String, String> fixed;

  static bool isToImprove(MoneyFinding f) =>
      f.kind != MoneyFindingKind.strength;

  /// Whether dropping off counts as the player fixing something. The
  /// newcomer placeholder goes away just by using the app, which is not a fix.
  static bool _celebrates(MoneyFinding f) =>
      isToImprove(f) && f.id != 'start_here';

  /// Moves anything that was open and is no longer flagged into [fixed], and
  /// records what is open now. Returns whether anything changed.
  ///
  /// [extra] is anything else the Coach lists as "to improve" that is not a
  /// finding — the weak quiz topics, keyed `skill:<id>` — so fixing one of
  /// those is celebrated the same way.
  bool update(
    List<MoneyFinding> findings, {
    Map<String, String> extra = const <String, String>{},
  }) {
    final now = <String, String>{
      for (final f in findings)
        if (_celebrates(f)) f.id: f.title,
      ...extra,
    };
    var changed = false;
    for (final entry in open.entries) {
      if (!now.containsKey(entry.key) && !fixed.containsKey(entry.key)) {
        fixed[entry.key] = entry.value;
        changed = true;
      }
    }
    // Flagged again after being fixed: it is not fixed any more.
    for (final id in now.keys) {
      if (fixed.remove(id) != null) changed = true;
    }
    if (!_sameKeys(open, now)) {
      open
        ..clear()
        ..addAll(now);
      changed = true;
    }
    return changed;
  }

  List<FixedFinding> get fixedFindings => [
    for (final entry in fixed.entries)
      FixedFinding(id: entry.key, title: entry.value),
  ];

  void dismissFixed() => fixed.clear();

  static Future<CoachMemory> load() async {
    final prefs = await SharedPreferences.getInstance();
    return CoachMemory(
      open: _decode(prefs.getString(_openKey)),
      fixed: _decode(prefs.getString(_fixedKey)),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openKey, jsonEncode(open));
    await prefs.setString(_fixedKey, jsonEncode(fixed));
  }

  static Map<String, String> _decode(String? raw) {
    if (raw == null) return <String, String>{};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  static bool _sameKeys(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.keys.every(b.containsKey);
}
