import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toasts talk about the player's game, never about the backend.
///
/// **What this is guarding.** Every reward flow in the app funnels through
/// `UserStatsController._saveStats`, which returns
/// `StatsActionResult(message: syncState.message, …)`. So `result.message` on
/// a *successful* save is not a description of what happened in the game — it
/// is the sync status, and for a long time that status read literally
/// "Saved to Supabase."
///
/// Ten call sites had pasted it onto the end of a reward line, so finishing a
/// lesson said:
///
///     What Is Money? saved. Earned +12 XP, +50 Gold! Saved to Supabase.
///
/// Renaming the string is not the fix, and that is the point of this file. The
/// problem is structural: the sync status is *always* appended, whether or not
/// anything went wrong, in the one moment the player is being told what they
/// earned. Rename it to "Added to your account." and it is still a sentence
/// about a database in a nine-year-old's reward popup.
///
/// A save that genuinely fails is worth surfacing, and it already is —
/// `CloudSyncBanner` on the Profile screen renders nothing while sync is
/// healthy and a standing warning when it is not. That is the right shape for
/// it: persistent, and only present when it means something.
void main() {
  List<File> dartFiles(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Strips `//` comments so the notes explaining this rule do not trip it.
  String withoutComments(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  final quoted = RegExp(r"'[^'\n]*'");

  test('no toast pastes the sync status onto a reward line', () {
    final offenders = <String>[];
    for (final file in dartFiles('lib')) {
      final source = withoutComments(file.readAsStringSync());
      if (!source.contains('GameToast.show')) continue;
      if (source.contains('syncState.message')) {
        offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'these screens show a toast and read syncState.message:\n'
          '${offenders.join('\n')}\n'
          'A reward toast says what the player earned. Where a save fails, '
          'CloudSyncBanner is the place that says so.',
    );
  });

  test('the backend is never named in the copy the player reads', () {
    // "Supabase" is an implementation detail, and it reached a toast because
    // a message written for a developer got shown to a child.
    //
    // Scoped to the layers where copy actually lives — screens, widgets and
    // controllers — and skipping `debugPrint`, which is the device log and is
    // *supposed* to name the service that failed. Two deliberate exceptions
    // live in `supabase_service.dart` and are outside this scan: a StateError
    // that is never rendered, and the "run the migration" message on the
    // friend-add path, which is aimed at whoever deploys this and says so at
    // length in its own comment.
    final offenders = <String>[];
    for (final root in const <String>[
      'lib/screens_minigames_admin_etc',
      'lib/widgets_custom_lotties',
      'lib/controllers_that_updates_stats',
    ]) {
      for (final file in dartFiles(root)) {
        for (final line in file.readAsStringSync().split('\n')) {
          if (line.contains('debugPrint(')) continue;
          if (line.trimLeft().startsWith('//')) continue;
          for (final match in quoted.allMatches(line)) {
            final literal = match.group(0)!;
            if (literal.contains('.dart') || literal.contains('package:')) {
              continue;
            }
            // A bare identifier like 'supabase' is a key or a table name.
            // Copy has spaces in it.
            if (literal.toLowerCase().contains('supabase') &&
                literal.contains(' ')) {
              offenders.add('${file.path}: $literal');
            }
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'player-visible copy naming the backend:\n${offenders.join('\n')}',
    );
  });
}
