import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Numerals must never render in the pixel font.
///
/// **The bug this exists to prevent.** A tester was shown a quiz question
/// reading *"you do the dishes every day and get \$1 each time. After 5 days,
/// how much have you earned?"* with options \$1 / \$3 / \$5 / \$10. They read
/// the 5 as an 8, worked out \$8, and found no matching option. There was no
/// answer to the question in front of them, and nothing about the app looked
/// broken — the source said 5, the correct option was \$5, and every test
/// passed.
///
/// Pixelify Sans's 5 and 6 have **closed top counters**: rows 3 to 9 of those
/// glyphs are pixel-identical to the 8's. Measured by
/// `tool/check_digit_legibility.py` at 22px, **18 of its 45 digit pairs
/// differ in under 18% of their inked pixels**, and 8/9 differ in under 4%.
/// Quicksand scores 0 of 45 on the same measurement.
///
/// These tests are cheap source checks rather than a rasteriser, because the
/// measurement lives in the Python tool where it belongs and the thing that
/// needs guarding in Dart is the *rule*: number-bearing widgets use
/// [AppTheme.numeric].
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// Widgets whose text is frequently or entirely a number.
  ///
  /// Each entry is a file and a snippet that must appear *near* a
  /// `AppTheme.numeric` rather than a `GoogleFonts.pixelifySans`. Chosen
  /// because a misread digit in these changes the meaning rather than the
  /// looks — the two quiz prompts are the ones a tester actually could not
  /// answer, and the calculator is a tool for getting arithmetic right.
  const criticalSites = <String, List<String>>{
    'lib/screens_minigames_admin_etc/Gameplay/academy/quiz_widgets.dart': [
      'question.prompt',
    ],
    'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart':
        ['q.question'],
    'lib/widgets_custom_lotties/basic_calculator_dialog.dart': ['_display'],
  };

  group('the places a misread digit changes the answer', () {
    criticalSites.forEach((path, snippets) {
      for (final snippet in snippets) {
        test('$snippet is not in the pixel font', () {
          final src = read(path).replaceAll('\r\n', '\n');

          // Anchor on the `Text(` that renders it, not the first textual
          // match. `q.question` also appears twice as `question: q.question,`
          // — plain data plumbing — and an earlier version of this test
          // matched one of those, then reported a font failure in code that
          // renders nothing at all.
          final at =
              RegExp(
                'Text\\(\\s*${RegExp.escape(snippet)}\\s*,',
              ).firstMatch(src)?.start ??
              -1;
          expect(
            at,
            greaterThan(-1),
            reason: 'no Text() rendering $snippet found in $path',
          );

          // The style argument follows the content within a few lines.
          final window = src.substring(
            at,
            (at + 400).clamp(0, src.length),
          );

          expect(
            window,
            contains('AppTheme.numeric('),
            reason:
                '$snippet in $path should use AppTheme.numeric — it renders '
                'numbers, and Pixelify Sans has 18 of 45 confusable digit '
                'pairs',
          );
          expect(
            window.substring(0, window.indexOf(')') + 1),
            isNot(contains('pixelifySans')),
            reason: '$snippet is back on the pixel font',
          );
        });
      }
    });
  });

  group('the rule is written down where it can be found', () {
    test('AppTheme.numeric exists and routes away from Pixelify', () {
      final theme = read('lib/themes_colors/app_theme.dart');
      expect(theme, contains('static TextStyle numeric('));
      final start = theme.indexOf('static TextStyle numeric(');
      final body = theme.substring(start, start + 500);
      expect(
        body,
        contains('GoogleFonts.quicksand'),
        reason: 'AppTheme.numeric must not resolve to the pixel font',
      );
      expect(body, isNot(contains('pixelifySans')));
    });

    test('the measurement tool is still in the repo', () {
      // The tool is the evidence. Without it the doc comments above are just
      // an assertion somebody made once.
      expect(File('tool/check_digit_legibility.py').existsSync(), isTrue);
      expect(File('tool/audit_number_fonts.py').existsSync(), isTrue);
    });
  });

  group('the fix reached the whole app, not just the reported screen', () {
    test('no money or score widget slipped back onto the pixel font', () {
      // A sample of the sixty-odd sites converted in the sweep. Not
      // exhaustive on purpose — `tool/audit_number_fonts.py` is the
      // exhaustive check, and pinning all sixty here would fail on every
      // unrelated refactor without telling anybody anything new.
      const sampled = <String>[
        'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart',
        'lib/widgets_custom_lotties/life_money_panel.dart',
        'lib/screens_minigames_admin_etc/profile/profile_screen.dart',
      ];
      for (final path in sampled) {
        expect(
          read(path),
          contains('AppTheme.numeric('),
          reason: '$path renders numbers and none of them use the safe face',
        );
      }
    });
  });
}
