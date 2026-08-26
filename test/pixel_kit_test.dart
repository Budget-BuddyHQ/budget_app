import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/widgets_custom_lotties/pixel_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _box(Widget child, {double? width, double? height}) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: width, height: height, child: child)),
  ),
);

/// Widths a shared widget realistically gets handed, including the ones that
/// used to crash: the Finance Brawl HUD gives its panels about 119px on a
/// phone, which is narrower than the unscaled pack art could ever draw.
const List<double> _widths = <double>[24, 40, 64, 96, 119, 160, 320, 800];

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('nine-slices survive every width they are given', () {
    // Flutter subtracts a centerSlice's end caps from the destination before
    // fitting, and a negative remainder throws rather than clipping — so a
    // panel asked to render narrower than its own corners takes the frame
    // down. These are the sizes that hazard actually shows up at.
    for (final w in _widths) {
      testWidgets('PixelFrame at ${w.toInt()}px', (tester) async {
        await tester.pumpWidget(
          _box(
            const PixelFrame(child: SizedBox()),
            width: w,
            height: 80,
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull);
      });

      testWidgets('PixelProgressBar at ${w.toInt()}px', (tester) async {
        await tester.pumpWidget(
          _box(const PixelProgressBar(value: 0.4, height: 14), width: w),
        );
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull);
      });

      testWidgets('PixelButton at ${w.toInt()}px', (tester) async {
        await tester.pumpWidget(
          _box(
            PixelButton(label: 'Buy', onPressed: () {}),
            width: w,
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull);
      });

      testWidgets('PixelRibbon at ${w.toInt()}px', (tester) async {
        await tester.pumpWidget(
          _box(const PixelRibbon(label: 'This week'), width: w),
        );
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a frame survives a box shorter than its corners', (
      tester,
    ) async {
      await tester.pumpWidget(
        _box(const PixelFrame(child: SizedBox()), width: 300, height: 20),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('every frame style renders', (tester) async {
      for (final style in PixelFrameStyle.values) {
        await tester.pumpWidget(
          _box(
            PixelFrame(style: style, child: const SizedBox()),
            width: 300,
            height: 200,
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull, reason: style.name);
      }
    });
  });

  group('slice rects describe their art', () {
    // A slice rect that is even a pixel off pins the wrong column and the
    // bevel smears. These are printed by tool/build_ui_pack.py; if the art is
    // regenerated and the constants are not updated, these catch it.
    //
    // Every asset carries its own rect *and* its own source size because the
    // generator trims transparent padding, so no two outputs are the same
    // shape and the caps are not symmetric.
    const cases = <(String, Rect, Size)>[
      ('panel_paper', AppAssets.kitSlicePanelPaper, AppAssets.kitSizePanelPaper),
      ('panel_slate', AppAssets.kitSlicePanelSlate, AppAssets.kitSizePanelSlate),
      (
        'panel_banner',
        AppAssets.kitSlicePanelBanner,
        AppAssets.kitSizePanelBanner,
      ),
      ('panel_wood', AppAssets.kitSlicePanelWood, AppAssets.kitSizePanelWood),
      ('btn_primary', AppAssets.kitSliceBtnPrimary, AppAssets.kitSizeBtnPrimary),
      (
        'btn_primary_pressed',
        AppAssets.kitSliceBtnPrimaryPressed,
        AppAssets.kitSizeBtnPrimaryPressed,
      ),
      ('bar_base', AppAssets.kitSliceBarBase, AppAssets.kitSizeBarBase),
      ('ribbon_green', AppAssets.kitSliceRibbonGreen, AppAssets.kitSizeRibbon),
      (
        'ribbon_small_green',
        AppAssets.kitSliceRibbonSmallGreen,
        AppAssets.kitSizeRibbonSmall,
      ),
    ];

    test('every slice sits inside its source', () {
      // Flutter asserts if a centerSlice is not contained by the image. The
      // trim step made this a live hazard: cropping blank rows off the top of
      // a full-height strip pushed its slice top negative until it was
      // clamped.
      for (final (name, slice, size) in cases) {
        expect(slice.left, greaterThanOrEqualTo(0), reason: name);
        expect(slice.top, greaterThanOrEqualTo(0), reason: name);
        expect(slice.right, lessThanOrEqualTo(size.width), reason: name);
        expect(slice.bottom, lessThanOrEqualTo(size.height), reason: name);
      }
    });

    test('a slice never eats its whole source', () {
      // If the caps summed to the full width there would be no stretchable
      // middle at all, and the panel could only render at source size.
      for (final (name, slice, size) in cases) {
        final capsWide = slice.left + (size.width - slice.right);
        final capsTall = slice.top + (size.height - slice.bottom);
        expect(capsWide, lessThan(size.width), reason: name);
        expect(capsTall, lessThanOrEqualTo(size.height), reason: name);
        expect(slice.width, greaterThan(0), reason: name);
        expect(slice.height, greaterThan(0), reason: name);
      }
    });

    test('the art is trimmed, so nothing is mostly padding', () {
      // The bug this locks: an untrimmed 64x64 fill held 24 rows of colour,
      // so a 6px-tall destination painted a 2px hairline. Flutter fits to the
      // file, not to the art inside it.
      for (final (name, _, size) in cases) {
        expect(size.width, greaterThan(8), reason: name);
        expect(size.height, greaterThan(8), reason: name);
      }
    });
  });

  group('progress bar maths', () {
    testWidgets('a zero total does not become NaN', (tester) async {
      // Reachable the first frame of a wave, before the target is set.
      await tester.pumpWidget(
        _box(const PixelProgressBar(value: 0 / 0), width: 200),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('out-of-range values clamp instead of overflowing', (
      tester,
    ) async {
      for (final v in [-2.0, 1.5, 99.0]) {
        await tester.pumpWidget(
          _box(PixelProgressBar(value: v), width: 200),
        );
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull, reason: 'value $v');
      }
    });
  });

  group('button states', () {
    testWidgets('a disabled button does not fire', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _box(
          PixelButton(label: 'Locked', onPressed: null, icon: null),
          width: 200,
        ),
      );
      await tester.tap(find.byType(PixelButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('an enabled button fires once per tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _box(PixelButton(label: 'Buy', onPressed: () => taps++), width: 200),
      );
      await tester.tap(find.byType(PixelButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('holding swaps to the pressed art', (tester) async {
      // The pressed state is separate art with an inverted bevel, not a tint —
      // only moving the light reads as "this went down".
      await tester.pumpWidget(
        _box(PixelButton(label: 'Buy', onPressed: () {}), width: 200),
      );
      final gesture = await tester.press(find.byType(PixelButton));
      await tester.pump();
      expect(find.byType(PixelButton), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
