import 'dart:io';

import 'package:budget_app/widgets_custom_lotties/money_glyphs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _box(Widget child, {double width = 300}) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: width, child: child)),
  ),
);

void main() {
  group('the font has every glyph it claims', () {
    // The bug this exists for: the SVG conversion silently dropped
    // `hud_number_5`. A money font missing a digit is unusable — no balance,
    // price or percentage can be trusted to avoid it — and nothing would have
    // surfaced it except a number with a 5 rendering as a hole.
    const required = <String>[
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
      'dollar', 'percent', 'dot', 'colon', 'plus',
    ];

    for (final name in required) {
      test('$name.png exists', () {
        expect(
          File('assets/images/hud_font/$name.png').existsSync(),
          isTrue,
          reason: 'assets/images/hud_font/$name.png is missing',
        );
      });
    }

    test('every digit shares one baseline', () {
      // Glyphs are packed by cropping to a common vertical band, each keeping
      // its own width. If a digit had a different height the number would
      // visibly bounce as its value changed.
      final heights = <int, int>{};
      for (var d = 0; d <= 9; d++) {
        final bytes = File('assets/images/hud_font/$d.png').readAsBytesSync();
        final image = decodePngSize(bytes);
        heights[d] = image.$2;
      }
      final distinct = heights.values.toSet();
      expect(
        distinct.length,
        1,
        reason: 'digit heights differ: $heights',
      );
    });

    test('widths vary, so the font is not monospaced by accident', () {
      // A `1` should be narrower than an `8`. If the packer had cropped
      // horizontally to a shared band too, every glyph would be the same
      // width and the numbers would look wrong.
      final one = decodePngSize(
        File('assets/images/hud_font/1.png').readAsBytesSync(),
      ).$1;
      final eight = decodePngSize(
        File('assets/images/hud_font/8.png').readAsBytesSync(),
      ).$1;
      expect(one, lessThan(eight));
    });
  });

  group('canRender', () {
    test('accepts anything the font can draw', () {
      expect(MoneyGlyphs.canRender('1234567890'), isTrue);
      expect(MoneyGlyphs.canRender(r'$9,'), isFalse);
      expect(MoneyGlyphs.canRender(r'$1234'), isTrue);
      expect(MoneyGlyphs.canRender('99.5%'), isTrue);
      expect(MoneyGlyphs.canRender('+250'), isTrue);
    });

    test('rejects characters with no glyph', () {
      // The guard exists so a caller can pick: a figure that is half art and
      // half fallback text looks worse than one drawn entirely in text.
      expect(MoneyGlyphs.canRender('-40'), isFalse);
      expect(MoneyGlyphs.canRender('1,000'), isFalse);
      expect(MoneyGlyphs.canRender('12g'), isFalse);
    });

    test('every digit passes, including the reconstructed 5', () {
      for (var d = 0; d <= 9; d++) {
        expect(MoneyGlyphs.canRender('$d'), isTrue, reason: 'digit $d');
      }
    });
  });

  group('rendering', () {
    testWidgets('draws one image per glyph', (tester) async {
      await tester.pumpWidget(_box(const MoneyGlyphs(r'$150')));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(Image), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unknown character falls back to text, not a gap', (
      tester,
    ) async {
      await tester.pumpWidget(_box(const MoneyGlyphs('1,5')));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text(','), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty string renders nothing and does not throw', (
      tester,
    ) async {
      await tester.pumpWidget(_box(const MoneyGlyphs('')));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long figure still lays out inside a narrow box', (
      tester,
    ) async {
      // Late-game balances get wide; the HUD does not.
      await tester.pumpWidget(
        _box(
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: MoneyGlyphs(r'$9876543', height: 22),
          ),
          width: 90,
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the whole figure is one label for screen readers', (
      tester,
    ) async {
      // Otherwise it announces as eight separate images.
      await tester.pumpWidget(_box(const MoneyGlyphs(r'$150')));
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.bySemanticsLabel(r'$150'),
        findsOneWidget,
      );
    });
  });
}

/// Width and height straight out of a PNG's IHDR chunk.
///
/// Avoids pulling in an image package for what is a fixed 8-byte read at a
/// fixed offset — PNG puts width and height as big-endian uint32s at bytes
/// 16..23, right after the signature and the IHDR length/type.
(int, int) decodePngSize(List<int> bytes) {
  int at(int i) =>
      (bytes[i] << 24) | (bytes[i + 1] << 16) | (bytes[i + 2] << 8) | bytes[i + 3];
  return (at(16), at(20));
}
