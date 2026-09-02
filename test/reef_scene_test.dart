import 'dart:ui' as ui;

import 'package:budget_app/widgets_custom_lotties/reef_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the numbers [ReefProp] and [ReefFish] carry by hand.
///
/// **Why this test exists.** Every file in the underwater pack is a 128x128
/// box with the art floating inside it and transparent padding around it, and
/// Flutter fits an image to its *file* bounds rather than to the art. So the
/// scene sizes each prop by how many rows it actually occupies — numbers
/// measured off the alpha channel once and then written into Dart, where
/// nothing stops them drifting from the art they describe. Swapping a
/// seaweed for a shorter one, or re-exporting the pack, would leave plants
/// hovering above the sea floor or sunk into it, and it would look like a
/// layout bug rather than a stale constant.
///
/// Measuring them back out of the real PNGs is the only way that stays true.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Rows of [asset] whose alpha is not zero, and the same for columns.
  Future<({int height, int width})> contentBoxOf(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(pixels, isNotNull, reason: '$asset decoded to nothing');

    final bytes = pixels!.buffer.asUint8List();
    var top = image.height;
    var bottom = -1;
    var left = image.width;
    var right = -1;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (bytes[(y * image.width + x) * 4 + 3] == 0) continue;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
        if (x < left) left = x;
        if (x > right) right = x;
      }
    }
    image.dispose();
    codec.dispose();
    expect(bottom, isNonNegative, reason: '$asset is fully transparent');
    return (height: bottom - top + 1, width: right - left + 1);
  }

  const props = <String, ReefProp>{
    'kelpTall': ReefProp.kelpTall,
    'kelpShort': ReefProp.kelpShort,
    'kelpStub': ReefProp.kelpStub,
    'grass': ReefProp.grass,
    'coralTall': ReefProp.coralTall,
    'coralShort': ReefProp.coralShort,
    'starfish': ReefProp.starfish,
    'rockWide': ReefProp.rockWide,
    'rockTall': ReefProp.rockTall,
    'hazeKelp': ReefProp.hazeKelp,
    'hazeRock': ReefProp.hazeRock,
    'hazeRockTall': ReefProp.hazeRockTall,
  };

  const fish = <String, ReefFish>{
    'orange': ReefFish.orange,
    'blue': ReefFish.blue,
    'pink': ReefFish.pink,
    'green': ReefFish.green,
  };

  group('the recorded art metrics still match the art', () {
    for (final entry in props.entries) {
      testWidgets('${entry.key} is ${entry.value.contentHeight} rows tall', (
        tester,
      ) async {
        await tester.runAsync(() async {
          final box = await contentBoxOf(entry.value.asset);
          expect(
            box.height,
            closeTo(entry.value.contentHeight, 1),
            reason:
                '${entry.value.asset} draws ${box.height} of its 128 rows, '
                'not ${entry.value.contentHeight} — resize it here or the '
                'prop will float above the sea floor',
          );
        });
      });
    }

    for (final entry in fish.entries) {
      testWidgets('${entry.key} fish is ${entry.value.contentWidth} wide', (
        tester,
      ) async {
        await tester.runAsync(() async {
          final box = await contentBoxOf(entry.value.asset);
          expect(box.width, closeTo(entry.value.contentWidth, 1));
        });
      });
    }

    testWidgets('every prop is bottom-anchored in its box', (tester) async {
      // The whole "stand this on the floor" placement is a plain bottom
      // alignment, which only works because the art in these files runs all
      // the way to row 127. A prop with padding underneath would hover.
      await tester.runAsync(() async {
        for (final entry in props.entries) {
          final data = await rootBundle.load(entry.value.asset);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          final pixels = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final bytes = pixels!.buffer.asUint8List();
          final lastRow = image.height - 1;
          var painted = false;
          for (var x = 0; x < image.width; x++) {
            if (bytes[(lastRow * image.width + x) * 4 + 3] != 0) {
              painted = true;
              break;
            }
          }
          image.dispose();
          codec.dispose();
          expect(
            painted,
            isTrue,
            reason:
                '${entry.key} has transparent padding below it, so aligning '
                'its box to the floor line leaves it hovering',
          );
        }
      });
    });

    testWidgets('the floor tiles fill their boxes edge to edge', (
      tester,
    ) async {
      // These are drawn with ImageRepeat, so any transparent margin would
      // show as a regular gap in the sea bed.
      await tester.runAsync(() async {
        for (final asset in <String>[
          ...ReefArt.sandTop,
          ReefArt.sandBody,
          ReefArt.distantTop,
        ]) {
          final box = await contentBoxOf(asset);
          expect(box.width, ReefArt.tile.toInt(), reason: asset);
        }
      });
    });
  });

  group('the scene itself', () {
    testWidgets('lays out at a phone width without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 220);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ReefScene(floorHeight: 60))),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('is a still frame, not an empty one, with motion off', (
      tester,
    ) async {
      // Somebody who turns animations off should still get the reef.
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: Scaffold(body: ReefScene())),
        ),
      );
      // No repeating controller is running, so this settles — which is also
      // the property that keeps `pumpAndSettle` usable on any screen the
      // scene is dropped into.
      await tester.pumpAndSettle();
      expect(find.byType(ReefScene), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the same seed lays out the same reef twice', (tester) async {
      // Placement runs through a seeded Random in initState. An unseeded one
      // inside build would reshuffle the seaweed every time the gold counter
      // changed, which is worse than having no scenery at all.
      // Distinct keys so the second mount really is a fresh `State` — with
      // the same key Flutter reuses the element, `initState` never runs
      // again, and the test would pass by not having tried anything. Motion
      // is off so the clock is pinned at zero and only *placement* is being
      // compared, not where a fish had swum to.
      Future<List<Rect>> layOutWith(Key key) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 600,
                    height: 300,
                    child: ReefScene(key: key, seed: 4),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        return find
            .byType(Image)
            .evaluate()
            .map((e) => tester.getRect(find.byElementPredicate((c) => c == e)))
            .toList();
      }

      final first = await layOutWith(const ValueKey('first'));
      expect(first, isNotEmpty, reason: 'the reef drew no art at all');
      final again = await layOutWith(const ValueKey('second'));
      expect(again, first);
    });
  });
}
