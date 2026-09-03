import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The generated sound effects, measured.
///
/// **Why this file exists.** The same class of fault has now been shipped
/// three times, and none of the three were visible in code review:
///
/// * The effects were bare sine tones with no contact transient — the ear
///   could not tell what had *made* the sound, only what pitch it was.
/// * The transient was added and then filtered away: measured, the first five
///   milliseconds of a tap carried **2%** of their energy above 2kHz. It was
///   there and it was buried.
/// * `_write` normalised the signal and *then* faded its edges, so a sound
///   whose peak landed inside the 1.5ms fade came out far quieter than asked
///   for — tap.wav requested a peak of 0.30 and wrote 0.168.
///
/// Every one of those is a number, and none of them can be seen by reading
/// the generator. So the generator's output is what gets checked.
///
/// Regenerate with `python tool/make_sounds.py` after changing anything here.
void main() {
  /// One decoded mono WAV: its sample rate and samples in -1..1.
  ({int rate, Float64List samples}) load(String name) {
    final bytes = File('assets/audio/$name').readAsBytesSync();
    final data = ByteData.sublistView(bytes);

    // Walk the RIFF chunks rather than assuming a 44-byte header — the
    // generator writes a plain header today and a tool that adds a LIST
    // chunk tomorrow would silently shift every sample.
    var offset = 12;
    var rate = 0;
    var channels = 1;
    late Uint8List pcm;
    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = data.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ') {
        channels = data.getUint16(body + 2, Endian.little);
        rate = data.getUint32(body + 4, Endian.little);
      } else if (id == 'data') {
        pcm = bytes.sublist(body, body + size);
        break;
      }
      offset = body + size + (size.isOdd ? 1 : 0);
    }

    final view = ByteData.sublistView(pcm);
    final frames = pcm.length ~/ (2 * channels);
    final out = Float64List(frames);
    for (var i = 0; i < frames; i++) {
      var sum = 0.0;
      for (var c = 0; c < channels; c++) {
        sum += view.getInt16((i * channels + c) * 2, Endian.little) / 32768.0;
      }
      out[i] = sum / channels;
    }
    return (rate: rate, samples: out);
  }

  /// Zero crossings per second over the first [millis] — a cheap stand-in for
  /// "how bright is the attack" that needs no FFT.
  ///
  /// A dull thud crosses zero at roughly its fundamental. A contact click
  /// crosses it thousands of times a second, because it is broadband noise.
  double attackBrightness(
    ({int rate, Float64List samples}) wav, {
    double millis = 5,
  }) {
    final window = (wav.rate * millis / 1000).round();
    final n = window < wav.samples.length ? window : wav.samples.length;
    var crossings = 0;
    for (var i = 1; i < n; i++) {
      if ((wav.samples[i - 1] < 0) != (wav.samples[i] < 0)) crossings++;
    }
    return crossings / (n / wav.rate);
  }

  double peakOf(Float64List s) {
    var peak = 0.0;
    for (final v in s) {
      if (v.abs() > peak) peak = v.abs();
    }
    return peak;
  }

  /// Every effect, with the peak level `tool/make_sounds.py` asks for.
  const levels = <String, double>{
    'tap.wav': 0.30,
    'navigation.wav': 0.22,
    'selection.wav': 0.34,
    'need_pickup.wav': 0.40,
    'want_hit.wav': 0.46,
    'error.wav': 0.46,
    'shutdown.wav': 0.40,
    'notification.wav': 0.62,
    'success.wav': 0.70,
    'celebration.wav': 0.80,
    'case_roll.wav': 0.52,
    'unbox_common.wav': 0.62,
    'unbox_rare.wav': 0.68,
    'unbox_epic.wav': 0.74,
    'unbox_legendary.wav': 0.80,
  };

  group('levels', () {
    test('every file is written at the level it asked for', () {
      // The fade-then-normalise bug. A file quieter than its target is not a
      // cosmetic problem: the whole loudness design is relative, so one sound
      // arriving 5dB down puts it in the wrong place against every other.
      for (final entry in levels.entries) {
        final peak = peakOf(load(entry.key).samples);
        expect(
          peak,
          closeTo(entry.value, 0.01),
          reason: '${entry.key} peaks at '
              '${peak.toStringAsFixed(3)}, asked for ${entry.value}',
        );
      }
    });

    test('nothing clips', () {
      for (final name in levels.keys) {
        final peak = peakOf(load(name).samples);
        expect(peak, lessThan(0.999), reason: '$name is clipping');
      }
    });

    test('the loudness order still holds', () {
      // Navigation fires dozens of times a session and a reward chime almost
      // never; they cannot sit at the same level or the interface shouts.
      double peak(String n) => peakOf(load(n).samples);
      expect(peak('navigation.wav'), lessThan(peak('tap.wav')));
      expect(peak('tap.wav'), lessThan(peak('success.wav')));
      expect(peak('success.wav'), lessThan(peak('celebration.wav')));
    });
  });

  group('edges', () {
    test('nothing starts or ends on a step', () {
      // A waveform that begins at a non-zero sample is an audible click
      // before the sound it is supposed to be.
      for (final name in levels.keys) {
        final s = load(name).samples;
        expect(s.first.abs(), lessThan(0.02), reason: '$name starts hard');
        expect(s.last.abs(), lessThan(0.02), reason: '$name ends hard');
      }
    });
  });

  group('the attack has an edge on it', () {
    test('the taps read as contact, not as a tone', () {
      // A 430Hz thud crosses zero about 860 times a second. A real contact
      // transient is broadband and crosses it thousands of times. This is the
      // measurement that was 2% and is now 23%, expressed without an FFT.
      for (final name in const <String>[
        'tap.wav',
        'selection.wav',
        'need_pickup.wav',
        'want_hit.wav',
      ]) {
        final rate = attackBrightness(load(name));
        expect(
          rate,
          greaterThan(2500),
          reason: '$name crosses zero only ${rate.round()} times a second in '
              'its first 5ms — there is no click on it, only a body',
        );
      }
    });

    test('navigation stays the dullest thing in the app', () {
      // It fires on every tab switch. It is meant to be texture.
      expect(
        attackBrightness(load('navigation.wav')),
        lessThan(attackBrightness(load('tap.wav'))),
      );
    });

    test('the soft falls are deliberately soft', () {
      // Error and shutdown are meant to be smooth, not percussive. A harsh
      // error tone in an app used by eight-year-olds teaches them to stop
      // trying things.
      for (final name in const <String>['error.wav', 'shutdown.wav']) {
        expect(
          attackBrightness(load(name)),
          lessThan(2500),
          reason: '$name has grown a click it should not have',
        );
      }
    });
  });

  group('formats', () {
    test('effects are full rate, the music loop is not', () {
      // 22k caps everything at an 11kHz ceiling, which removes the octave a
      // click's brightness lives in. The pad has nothing up there to lose and
      // would double in size for no sound.
      expect(load('tap.wav').rate, 44100);
      expect(load('unbox_legendary.wav').rate, 44100);
      expect(load('ambient_loop.wav').rate, 22050);
    });

    test('the bundle stays small enough to ship', () {
      final total = Directory('assets/audio')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'))
          .fold<int>(0, (sum, f) => sum + f.lengthSync());
      expect(
        total,
        lessThan(9 * 1024 * 1024),
        reason: 'audio is ${(total / 1024 / 1024).toStringAsFixed(1)}MB',
      );
    });
  });
}
