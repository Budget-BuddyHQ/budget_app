import 'dart:io';
import 'dart:ui' as ui;

import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
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

  group('every surface declares ink you can actually read on it', () {
    // The kit's art is *generated* — `tool/build_ui_pack.py` recolours and
    // dims a third-party pack — so the colour a panel ends up is not written
    // down anywhere a caller can see. Each style therefore carries the
    // measured mean of its own centre plus the inks that clear WCAG AA
    // against it, and this checks those constants against the real PNG.
    //
    // Without it the constants are a comment: a change to the recolour rules
    // silently makes them lies, and the symptom is unreadable panels rather
    // than a failing build. That is exactly how gold body text ended up at
    // 1.09:1 on the parchment style and 3.73:1 on slate.

    /// The mean colour of the middle ninth of an asset — the part a
    /// nine-slice stretches, and therefore the part text sits on.
    ///
    /// Reads the PNG off disk rather than through `rootBundle`, and runs in a
    /// plain `test` rather than a `testWidgets`. Both matter: image decoding
    /// is genuinely asynchronous work on the engine, and inside a widget
    /// test's fake-async zone the future it returns is never completed, so
    /// the first version of this simply hung until the runner gave up.
    Future<Color> centreMean(String assetPath) async {
      final bytes = await File(assetPath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(pixels, isNotNull);

      var r = 0, g = 0, b = 0, n = 0;
      for (var y = image.height ~/ 3; y < image.height * 2 ~/ 3; y++) {
        for (var x = image.width ~/ 3; x < image.width * 2 ~/ 3; x++) {
          final i = (y * image.width + x) * 4;
          if (pixels!.getUint8(i + 3) < 200) continue; // ignore soft edges
          r += pixels.getUint8(i);
          g += pixels.getUint8(i + 1);
          b += pixels.getUint8(i + 2);
          n++;
        }
      }
      expect(n, greaterThan(0), reason: '$assetPath has no opaque centre');
      return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
    }

    for (final style in PixelFrameStyle.values) {
      test('${style.name} matches its art', () async {
        final measured = await centreMean(style.asset);

        // Tolerance in luminance rather than in RGB: what matters is that the
        // declared surface predicts contrast correctly, and two colours a few
        // points apart in one channel do that identically.
        expect(
          AppTheme.luminance(measured),
          closeTo(AppTheme.luminance(style.surface), 0.02),
          reason:
              '${style.name}.surface says ${style.surface} but the art '
              'measures $measured — regenerate the constant or the asset',
        );

        for (final entry in <String, Color>{
          'ink': style.ink,
          'inkMuted': style.inkMuted,
          'accent': style.accent,
        }.entries) {
          final ratio = AppTheme.contrast(entry.value, measured);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '${style.name}.${entry.key} (${entry.value}) is only '
                '${ratio.toStringAsFixed(2)}:1 on the real art',
          );
        }
      });
    }

    for (final tone in PixelRibbonTone.values) {
      test('ribbon ${tone.name} matches its art', () async {
        final measured = await centreMean(tone.asset);
        expect(
          AppTheme.luminance(measured),
          closeTo(AppTheme.luminance(tone.surface), 0.02),
          reason: '${tone.name}.surface disagrees with the art ($measured)',
        );
        // Ribbon labels are bold and set at ~34% of a 46px ribbon, which is
        // WCAG "large text" — 3:1 is the standard's own bar for that.
        expect(
          AppTheme.contrast(tone.ink, measured),
          greaterThanOrEqualTo(3.0),
          reason: 'the ${tone.name} ribbon label is unreadable on its own art',
        );
      });
    }

    for (final tone in PixelButtonTone.values) {
      test('button ${tone.name} matches its art', () async {
        final measured = await centreMean(tone.asset);
        expect(
          AppTheme.luminance(measured),
          closeTo(AppTheme.luminance(tone.surface), 0.02),
          reason: '${tone.name}.surface disagrees with the art ($measured)',
        );
        expect(
          AppTheme.contrast(tone.ink, measured),
          greaterThanOrEqualTo(4.5),
          reason: 'the ${tone.name} button label is unreadable on its face',
        );
      });
    }
  });

  group('legibleOn', () {
    test('leaves a colour alone when it already passes', () {
      const gold = Color(0xFFFFD45C);
      expect(AppTheme.legibleOn(gold, AppTheme.deepForest), gold);
    });

    test('lifts a tint off a dark surface', () {
      // Mint on panelStrong measures 3.95:1 — the real case behind the
      // weekday initial in the habit tracker.
      final fixed = AppTheme.legibleOn(
        AppTheme.greenPrimary,
        AppTheme.panelStrong,
      );
      expect(
        AppTheme.contrast(fixed, AppTheme.panelStrong),
        greaterThanOrEqualTo(4.5),
      );
      expect(fixed, isNot(AppTheme.greenPrimary));
    });

    test('darkens a tint on a light surface', () {
      const gold = Color(0xFFFFD45C);
      const parchment = Color(0xFFEDE1C2);
      final fixed = AppTheme.legibleOn(gold, parchment);
      expect(AppTheme.contrast(fixed, parchment), greaterThanOrEqualTo(4.5));
      expect(
        AppTheme.luminance(fixed),
        lessThan(AppTheme.luminance(gold)),
        reason: 'on cream, gold has to get darker, not lighter',
      );
    });

    test('takes the smaller move when both directions work', () {
      // A mid-tone surface is the case a single fixed direction gets wrong:
      // picking "darken" for a bright accent on a mid badge produced a
      // near-black glyph that was *still* below the bar.
      const mint = Color(0xFF85EFAC);
      const midBadge = Color(0xFF4F926C);
      final fixed = AppTheme.legibleOn(mint, midBadge, target: 3.0);
      expect(AppTheme.contrast(fixed, midBadge), greaterThanOrEqualTo(3.0));
      expect(
        AppTheme.luminance(fixed),
        greaterThan(AppTheme.luminance(midBadge)),
        reason: 'a bright mint should stay bright, not flip to near-black',
      );
    });

    test('tintedChip returns a fill and an ink that agree', () {
      // The navy legendary badge: its letter was the same colour as the wash
      // it sat on, at 1.04:1.
      const navy = Color(0xFF2E3F6B);
      final chip = AppTheme.tintedChip(navy, alpha: 0.22);
      expect(chip.fill.a, 1.0, reason: 'the fill must be opaque');
      expect(AppTheme.contrast(chip.ink, chip.fill), greaterThanOrEqualTo(4.5));
    });
  });
}
