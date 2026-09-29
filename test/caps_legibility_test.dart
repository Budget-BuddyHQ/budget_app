import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ALL CAPS must never render in the pixel font.
///
/// # The report, and why the obvious fix was the wrong one
///
/// *"I like the pixelated fonts however that E ... is pretty hard to read."*
///
/// The obvious reading is that Pixelify Sans's lowercase is too small — it is
/// a pixel face, and next to a capital L the 'e' looks like a blob. The first
/// idea was therefore to set headings in caps.
///
/// Measured with `tool/check_digit_legibility.py --chars ABC...`, that would
/// have made it **worse**:
///
/// | face                   | confusable pairs of 325 |
/// |------------------------|-------------------------|
/// | Pixelify lowercase     | 3                       |
/// | Pixelify **CAPITALS**  | 10–23, at every size    |
/// | Quicksand lowercase    | 2                       |
/// | Quicksand **CAPITALS** | 0–1                     |
///
/// Three of Pixelify's confusable capital pairs contain an E — **E/S, B/E,
/// E/G** — so the reader named exactly the right letter and the guess about
/// the cause was backwards. It is not a size problem either: the capitals
/// score badly at 12px and at 30px alike, because they share skeletons rather
/// than lose detail at small sizes.
///
/// # The rule
///
/// Pixelify stays for **mixed-case** titles — "Play", "Play Life", the
/// wordmark — which is every place the app is recognized by it, and where it
/// measures fine. All-caps labels use [AppTheme.caps].
///
/// Like `digit_legibility_test.dart`, these are source checks rather than a
/// rasteriser: the measurement lives in the Python tool, and what needs
/// guarding here is the rule.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// A string literal, single or double quoted, optionally raw. Mirrors the
  /// pattern in `tool/audit_caps_font.py` so the test and the audit cannot
  /// disagree about what counts as a hit.
  final literal = RegExp("r?(['\"])((?:\\\\.|(?!\\1).)*)\\1");

  bool isShouting(String text) {
    final letters = text.split('').where((c) => RegExp('[A-Za-z]').hasMatch(c));
    if (letters.length < 3) return false;
    return letters.every((c) => c == c.toUpperCase());
  }

  /// Text set in Pixelify that is also all caps.
  ///
  /// Looks in a small window around the font call, because a `Text(...)` and
  /// its `style:` sit within a few lines of each other and anything further
  /// apart is a different widget.
  List<String> capsHits(File file) {
    final lines = file.readAsStringSync().replaceAll('\r\n', '\n').split('\n');
    final hits = <String>[];

    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].contains('GoogleFonts.pixelifySans(')) continue;

      for (var j = (i - 6).clamp(0, lines.length); j < i + 2; j++) {
        if (j == i || j >= lines.length) continue;

        if (lines[j].contains('toUpperCase()')) {
          // A single character is a monogram, not a label — there is no word
          // for a confusable letter to corrupt.
          if (!lines[j].contains('characters.first') &&
              !lines[j].contains('[0]')) {
            hits.add('${file.path}:${j + 1}  ${lines[j].trim()}');
          }
        }
        for (final match in literal.allMatches(lines[j])) {
          final text = match.group(2) ?? '';
          if (isShouting(text) && text != 'BUDGET BUDDY') {
            hits.add('${file.path}:${j + 1}  $text');
          }
        }
      }
    }
    return hits;
  }

  test('no all-caps text is set in Pixelify Sans', () {
    final offenders = <String>[for (final f in dartFiles) ...capsHits(f)];

    expect(
      offenders,
      isEmpty,
      reason:
          'Pixelify has 10-23 confusable capital pairs of 325 at every size, '
          'three of them containing an E. Use AppTheme.caps() instead.\n'
          '${offenders.join('\n')}',
    );
  });

  test('the wordmark keeps the pixel face on purpose', () {
    // The one deliberate exception, asserted so it reads as a decision rather
    // than as a site the sweep missed. A logotype beside the logo is learned
    // as a shape, not spelled out, and it is the app's identity.
    final welcome = File(
      'lib/screens_minigames_admin_etc/onboarding/welcome_screen.dart',
    ).readAsStringSync();

    expect(welcome.contains('BUDGET BUDDY'), isTrue);
    expect(welcome.contains('GoogleFonts.pixelifySans('), isTrue);
  });

  test('AppTheme.caps exists and is not Pixelify', () {
    final theme = File(
      'lib/themes_colors/app_theme.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n');

    final start = theme.indexOf('static TextStyle caps(');
    expect(start, greaterThan(-1), reason: 'AppTheme.caps() was removed');

    final body = theme.substring(start, start + 400);
    expect(body.contains('GoogleFonts.quicksand('), isTrue);
    expect(body.contains('pixelifySans'), isFalse);
  });

  group('the money display art is off the balances', () {
    // Reported in the same breath as the E: *"the numbers above there is
    // pretty hard to read"*, pointing at the gold figure on the hub.
    //
    // `tool/check_digit_legibility.py --glyph-dir assets/images/hud_font`
    // scores that art at **13 of 45 confusable digit pairs** — worse than the
    // Pixelify digits a tester had already misread in a quiz question. The
    // heavy italic weight and the baked-in outline close every counter, so
    // 0/3/6/8/9 collapse into one shape.
    //
    // It escaped the original digit sweep because it is not a font.
    const balanceScreens = <String>[
      'lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/'
          'main_game_page.dart',
      'lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart',
      'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
          'life_sim_page.dart',
      'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
          'finance_brawl_game.dart',
    ];

    test('no screen renders a balance in the display art', () {
      for (final path in balanceScreens) {
        expect(
          File(path).readAsStringSync().contains('MoneyGlyphs('),
          isFalse,
          reason: '$path puts a figure the player must read into art that '
              'has 13 of 45 confusable digit pairs',
        );
      }
    });

    test('the hub groups its digits', () {
      // `8371128` is hard to read in any face. This is the cheaper half of
      // the fix and it applies regardless of typeface.
      final hub = File(balanceScreens.first).readAsStringSync();
      expect(hub.contains('groupedNumber(stats.gold)'), isTrue);
    });
  });
}
