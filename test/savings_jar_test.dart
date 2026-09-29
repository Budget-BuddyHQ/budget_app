import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import 'package:budget_app/widgets_custom_lotties/savings_jar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The jar is the Money Habits tab's headline: one picture that has to answer
/// "how much have I put away" and "how am I doing" at a glance.
///
/// It is drawn rather than assembled from an asset, which means the usual
/// safety net — a designer noticing the art is wrong — does not exist. So
/// these tests read the actual pixels back.

/// Renders a jar and returns its pixels.
///
/// The capture runs inside [WidgetTester.runAsync] because `toImage` and
/// `toByteData` are real engine work: inside a widget test's fake-async zone
/// their futures are simply never completed, and the test hangs until the
/// runner kills it rather than failing with anything you could act on.
Future<ui.Image> _renderJar(
  WidgetTester tester, {
  required double fill,
  required JarMood mood,
  JarStage stage = JarStage.started,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        disableAnimations: true,
        size: Size(300, 300),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFF0F2E20),
              child: SavingsJarWidget(
                stage: stage,
                mood: mood,
                fill: fill,
                size: 240,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await tester.runAsync(() => boundary.toImage());
  return image!;
}

/// `toByteData` outside the fake-async zone — see [_renderJar].
Future<ByteData> _pixels(WidgetTester tester, ui.Image image) async {
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  return data!;
}

/// How many pixels in [image] are recognizably coin-gold.
///
/// Counting gold is the most direct proxy there is for "how much is in the
/// jar" — it does not care how the coins are arranged, only that more fill
/// puts more gold on screen, which is the property the widget exists to have.
Future<int> _goldPixels(WidgetTester tester, ui.Image image) async {
  final data = await _pixels(tester, image);
  var count = 0;
  for (var i = 0; i < data.lengthInBytes; i += 4) {
    final r = data.getUint8(i);
    final g = data.getUint8(i + 1);
    final b = data.getUint8(i + 2);
    // The coin ramp runs #C79A2E to #FFD45C: strongly red-and-green, weak
    // blue. The glass is cyan and the page is green, so neither can qualify.
    if (r > 150 && g > 120 && b < 120 && r >= g) count++;
  }
  return count;
}

/// The lowest row of the jar body that contains any gold, as a fraction of
/// the image height (0 = top). Lower number means the coins reach higher.
Future<double> _coinLineTop(WidgetTester tester, ui.Image image) async {
  final data = await _pixels(tester, image);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final i = (y * image.width + x) * 4;
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      if (r > 150 && g > 120 && b < 120 && r >= g) {
        return y / image.height;
      }
    }
  }
  return 1.0;
}

void main() {
  group('the jar fills up', () {
    testWidgets('more progress puts more coins in the glass', (tester) async {
      // The old widget scaled a Material glyph across four discrete stages,
      // so a player earning points saw nothing change for most of a stage.
      // This is the property that replaced it.
      var previous = -1;
      for (final fill in <double>[0.0, 0.15, 0.35, 0.6, 0.85, 1.0]) {
        final image = await _renderJar(
          tester,
          fill: fill,
          mood: JarMood.steady,
        );
        final gold = await _goldPixels(tester, image);
        expect(
          gold,
          greaterThan(previous),
          reason:
              'fill $fill drew no more gold than the level below it, so the '
              'jar is not tracking progress',
        );
        previous = gold;
      }
    });

    testWidgets('an empty jar is empty and a full one is not', (tester) async {
      final empty = await _goldPixels(
        tester,
        await _renderJar(tester, fill: 0.0, mood: JarMood.steady),
      );
      final full = await _goldPixels(
        tester,
        await _renderJar(tester, fill: 1.0, mood: JarMood.steady),
      );
      expect(empty, 0);
      expect(full, greaterThan(2000), reason: 'a full jar should look full');
    });

    testWidgets('the coin line rises as the jar fills', (tester) async {
      // Gold pixel *count* could in principle rise while the pile spread
      // sideways. What a player reads is the height of the line.
      final low = await _coinLineTop(
        tester,
        await _renderJar(tester, fill: 0.2, mood: JarMood.steady),
      );
      final high = await _coinLineTop(
        tester,
        await _renderJar(tester, fill: 0.9, mood: JarMood.steady),
      );
      expect(
        high,
        lessThan(low - 0.05),
        reason: 'the coins do not visibly stack higher as the jar fills',
      );
    });
  });

  group('the face matches the mood', () {
    /// The mouth's vertical extent, measured as the topmost and bottommost
    /// dark-ink rows in the band below the eyes.
    ///
    /// A smile in canvas coordinates bows *downward* in the middle, because y
    /// grows downward. Getting that backwards is not a subtle bug — the jar
    /// pulled a face at players for keeping a streak and grinned at them for
    /// abandoning it — but it is invisible in source, which is why it survived
    /// until someone rendered the thing and looked.
    Future<({double left, double middle})> mouthShape(
      WidgetTester tester,
      ui.Image image,
    ) async {
      final data = await _pixels(tester, image);
      final w = image.width;
      final h = image.height;

      /// The mean vertical position of the mouth's ink in a column band.
      ///
      /// The *mean*, not the lowest row: the stroke is several pixels thick
      /// and the curve only deflects a few, so an extreme-row measurement is
      /// mostly reporting stroke width and the two moods came out 1% apart.
      double inkCenter(int fromX, int toX) {
        var sum = 0.0;
        var count = 0;
        for (var y = (h * 0.30).round(); y < (h * 0.55).round(); y++) {
          for (var x = fromX; x < toX; x++) {
            final i = (y * w + x) * 4;
            final r = data.getUint8(i);
            final g = data.getUint8(i + 1);
            final b = data.getUint8(i + 2);
            // The face ink is #0B2419 at 82% over the glass — much darker
            // than anything else drawn inside the body.
            if (r < 60 && g < 80 && b < 70) {
              sum += y / h;
              count++;
            }
          }
        }
        return count == 0 ? 0 : sum / count;
      }

      // Both bands sit strictly *inside* the mouth and strictly outside the
      // eyes. The eyes reach x = 0.429 and 0.571 of the image, and the first
      // version sampled 0.33-0.39 for "left" — which is the left eye, not the
      // end of the mouth, so the comparison was between two different
      // features and reported the wrong sign.
      return (
        left: inkCenter((w * 0.44).round(), (w * 0.475).round()),
        middle: inkCenter((w * 0.485).round(), (w * 0.515).round()),
      );
    }

    testWidgets('a good streak smiles', (tester) async {
      final shape = await mouthShape(
        tester,
        await _renderJar(tester, fill: 0.3, mood: JarMood.onARoll),
      );
      expect(
        shape.middle,
        greaterThan(shape.left),
        reason:
            'the mouth rises in the middle — that is a frown, and this is '
            'the mood for a player who has kept their streak',
      );
    });

    testWidgets('slipping frowns', (tester) async {
      final shape = await mouthShape(
        tester,
        await _renderJar(tester, fill: 0.3, mood: JarMood.slipping),
      );
      expect(
        shape.middle,
        lessThan(shape.left),
        reason: 'the slipping face should not be smiling',
      );
    });
  });

  group('fill comes from progress, not from the stage bucket', () {
    test('jarFill spans the whole ladder', () {
      // Guards the reason `fill` exists: stage-relative progress resets to 0
      // at every milestone, so the jar emptied itself at the exact moment the
      // player was being congratulated.
      expect(JarStage.empty.progressToNext(0), 0);
      expect(JarStage.started.progressToNext(60), 0);
      expect(JarStage.halfFull.progressToNext(220), 0);
      // ...while the whole-ladder fraction only ever climbs.
      final top = JarStage.values.last.xpThreshold;
      double ladder(int xp) => (0.04 + (xp / top) * 0.96).clamp(0.0, 1.0);
      expect(ladder(60), greaterThan(ladder(0)));
      expect(ladder(220), greaterThan(ladder(60)));
      expect(ladder(600), 1.0);
    });
  });
}
