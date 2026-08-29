import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/app_fonts.dart';

/// Guards the assumption every layout suite in this repo now rests on.
///
/// `test/support/app_fonts.dart` registers the bundled faces under the family
/// keys `google_fonts` builds internally (`{Family}_{variant}`, with 400
/// spelled `regular`). That is not a public API. If the package ever changes
/// the spelling, the registration would silently land on names nothing asks
/// for, every layout test would quietly go back to measuring the one-em
/// fallback, and the failure would show up as widths that are wrong by about
/// 70% in suites that look like they are about something else entirely.
///
/// The fallback has an unmistakable signature: it is monospaced at exactly the
/// font size, so `M` and `i` measure identically. That is what is checked.
void main() {
  setUpAll(loadAppFonts);

  for (final face in <String, TextStyle Function()>{
    'Pixelify Sans 400': () => GoogleFonts.pixelifySans(fontSize: 20),
    'Pixelify Sans 700': () =>
        GoogleFonts.pixelifySans(fontSize: 20, fontWeight: FontWeight.w700),
    // The app writes w800 and w900 freely; Pixelify Sans publishes neither, so
    // the package maps them onto Bold. If that mapping ever changed, this is
    // where it would show up.
    'Pixelify Sans 800': () =>
        GoogleFonts.pixelifySans(fontSize: 20, fontWeight: FontWeight.w800),
    'Quicksand 300': () =>
        GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w300),
    'Quicksand 400': () => GoogleFonts.quicksand(fontSize: 20),
    'Quicksand 600': () =>
        GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w600),
    'Quicksand 700': () =>
        GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w700),
  }.entries) {
    test('${face.key} is the real face, not the fallback', () {
      double widthOf(String text) => (TextPainter(
        text: TextSpan(text: text, style: face.value()),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout()).width;

      final wide = widthOf('MMMMMMMM');
      final narrow = widthOf('iiiiiiii');

      expect(
        wide,
        isNot(closeTo(narrow, 0.5)),
        reason:
            '${face.key} measures an M and an i identically (${wide}px), '
            'which is the test fallback rather than a proportional face — '
            'check the family keys in test/support/app_fonts.dart against '
            'GoogleFontsFamilyWithVariant.toString()',
      );
      // 8 glyphs at 20px would be 160 in the fallback.
      expect(wide, lessThan(160.0), reason: face.key);
    });
  }
}
