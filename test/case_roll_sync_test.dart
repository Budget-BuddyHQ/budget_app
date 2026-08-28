import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The case ratchet and the case reel have to be the same event.
///
/// `case_roll.wav` is pre-rendered: `tool/make_sounds.py` emits one tick for
/// each skin tile crossing the reel's marker, timed by inverting the reel's
/// own easing curve. That only works while four numbers agree across the two
/// languages — the item count, the duration, the curve, and the fact that the
/// reel travels a **fixed** distance rather than one that depends on where
/// the winning skin sits in the catalogue.
///
/// Nothing in the compiler connects a Python generator to a Dart animation,
/// so this is the connection. Change one side and this fails, rather than the
/// sound quietly becoming a noise that plays near the picture.
void main() {
  /// Reads a `NAME = value` constant out of the generator.
  String pythonConstant(String name) {
    final source = File('tool/make_sounds.py').readAsStringSync();
    final match = RegExp(
      '^$name = (.+)\$',
      multiLine: true,
    ).firstMatch(source);
    expect(
      match,
      isNotNull,
      reason: 'tool/make_sounds.py no longer defines $name',
    );
    return match!.group(1)!.split('#').first.trim();
  }

  /// Reads a `static const ... _name = value;` out of the dialog.
  String dartConstant(String name) {
    final source = File(
      'lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart',
    ).readAsStringSync();
    final match = RegExp(
      r'static const [\w<>]+ ' + name + r' = ([^;]+);',
      multiLine: true,
    ).firstMatch(source);
    expect(
      match,
      isNotNull,
      reason: 'the roll dialog no longer defines $name',
    );
    return match!.group(1)!.trim();
  }

  group('the ratchet matches the reel', () {
    test('the tile count is the same on both sides', () {
      expect(
        dartConstant('_rollItems'),
        pythonConstant('CASE_ROLL_ITEMS'),
        reason:
            'the reel and the generated ratchet disagree about how many '
            'tiles pass the marker, so the ticks will drift out of the '
            'picture — regenerate the audio (python tool/make_sounds.py)',
      );
    });

    test('the duration is the same on both sides', () {
      // 4.2s in Python, 4200ms in Dart.
      final seconds = double.parse(pythonConstant('CASE_ROLL_SECONDS'));
      final millis = int.parse(
        RegExp(
          r'milliseconds: (\d+)',
        ).firstMatch(dartConstant('_rollDuration'))!.group(1)!,
      );
      expect(millis / 1000.0, closeTo(seconds, 0.001));
    });

    test('the easing curve is the same on both sides', () {
      final dart = dartConstant('_rollCurve'); // Cubic(0.16, 0.86, 0.41, 1.0)
      final numbers = RegExp(
        r'[\d.]+',
      ).allMatches(dart).map((m) => double.parse(m.group(0)!)).toList();
      final python = RegExp(r'[\d.]+')
          .allMatches(pythonConstant('CASE_ROLL_CURVE'))
          .map((m) => double.parse(m.group(0)!))
          .toList();
      expect(numbers, python);
    });

    test('the audio file is as long as the roll', () async {
      // A WAV header carries the sample rate at byte 24 and the data length
      // in the chunk after it; rather than parse the whole thing, this checks
      // the file is in the right ballpark for a 22050Hz 16-bit mono render.
      final file = File('assets/audio/case_roll.wav');
      expect(file.existsSync(), isTrue, reason: 'run tool/make_sounds.py');

      final bytes = await file.readAsBytes();
      final rate =
          bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
      final samples = (bytes.length - 44) / 2;
      final seconds = samples / rate;

      final expected = double.parse(pythonConstant('CASE_ROLL_SECONDS'));
      expect(
        seconds,
        closeTo(expected, 0.1),
        reason:
            'case_roll.wav is ${seconds.toStringAsFixed(2)}s but the reel '
            'runs for ${expected}s',
      );
    });
  });

  group('the reel travels a fixed distance', () {
    test('the winner is placed at the fixed index, not looked up', () {
      // The regression this guards: the reel used to travel
      // `4 * catalogue + indexOf(winner)` tiles, so the distance — and
      // therefore the number of ticks — changed with every result. Any
      // pre-rendered ratchet is wrong for all but one skin under that scheme.
      final source = File(
        'lib/screens_minigames_admin_etc/Gameplay/customize_screen.dart',
      ).readAsStringSync();
      expect(
        source,
        contains('_rollSkins[_rollItems] = widget.result.skin;'),
        reason: 'the winning skin is no longer pinned to the fixed index',
      );
      expect(
        source,
        isNot(contains('_minCycles')),
        reason: 'the variable-distance roll is back',
      );
    });
  });

  group('the curve inverts the way the generator assumes', () {
    test('progress is monotonic, so tick times are well defined', () {
      // `_tick_times` inverts this curve by scanning for the first time each
      // tile boundary is crossed. That is only valid while the curve never
      // goes backwards — an overshooting curve (elastic, back-ease) would
      // make a tile cross the marker more than once and the generator would
      // silently emit the wrong rhythm.
      const curve = Cubic(0.16, 0.86, 0.41, 1.0);
      var previous = -1.0;
      for (var i = 0; i <= 1000; i++) {
        final value = curve.transform(i / 1000);
        expect(
          value,
          greaterThanOrEqualTo(previous - 1e-9),
          reason: 'the roll curve reverses at t=${i / 1000}',
        );
        previous = value;
      }
      expect(curve.transform(0), closeTo(0, 1e-6));
      expect(curve.transform(1), closeTo(1, 1e-6));
    });

    test('the last tile takes the longest, which is the whole effect', () {
      // If the final approach were not the slowest stretch, the ratchet would
      // read as a rattle that stops rather than as a decision being made.
      const curve = Cubic(0.16, 0.86, 0.41, 1.0);
      const items = 72;

      double timeFor(int tile) {
        final target = tile / items;
        var lo = 0.0, hi = 1.0;
        for (var i = 0; i < 60; i++) {
          final mid = (lo + hi) / 2;
          if (curve.transform(mid) < target) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        return (lo + hi) / 2;
      }

      final lastGap = timeFor(items) - timeFor(items - 1);
      final firstGap = timeFor(1) - timeFor(0);
      expect(
        lastGap,
        greaterThan(firstGap * 20),
        reason: 'the reel barely decelerates, so the ticks will not either',
      );
    });
  });
}
