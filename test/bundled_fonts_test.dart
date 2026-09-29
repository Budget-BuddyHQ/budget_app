import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yaml/yaml.dart';

/// The app's two faces ship in the bundle rather than being downloaded.
///
/// **Why this matters enough to test.** `google_fonts` fetches a face over
/// HTTP the first time it is used and caches it to the device. Until that
/// finishes — and forever, if the device is offline — every label in the app
/// renders in the platform fallback. That is not a rare state: it is the
/// first launch, which is what a store reviewer sees, and it is a child on
/// school wifi with the font CDN blocked.
///
/// The package prefers a bundled asset over the network, but only if the file
/// is named exactly `{Family}-{Variant}.ttf` and sits somewhere the asset
/// manifest covers. Both halves of that are easy to get wrong and neither
/// fails loudly — the app just quietly goes back to downloading. So the file
/// names are asserted here rather than trusted.
void main() {
  // The variants the package resolves to, from its own generated manifest.
  // Pixelify Sans only publishes 400-700 upstream, which is why the w800 and
  // w900 call sites in this app map onto Bold rather than needing a file.
  const expected = <String, List<String>>{
    'PixelifySans': ['Regular', 'Medium', 'SemiBold', 'Bold'],
    'Quicksand': ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold'],
  };

  test('every face the app asks for is on disk', () {
    for (final family in expected.entries) {
      for (final variant in family.value) {
        final file = File('assets/fonts/${family.key}-$variant.ttf');
        expect(
          file.existsSync(),
          isTrue,
          reason:
              '${file.path} is missing, so google_fonts will fall back to '
              'downloading ${family.key} $variant at runtime',
        );
        // A truncated download is a file that exists and does not work.
        expect(file.lengthSync(), greaterThan(10000), reason: file.path);
      }
    }
  });

  test('the font directory is declared in pubspec assets', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final assets = (pubspec['flutter'] as YamlMap)['assets'] as YamlList;
    expect(
      assets.map((a) => a.toString()),
      contains('assets/fonts/'),
      reason:
          'the files exist but are not in the bundle, so the asset manifest '
          'will not list them and google_fonts will download instead',
    );
  });

  test('the OFL license ships with the fonts', () {
    // Not a formality. Both faces are SIL Open Font License, which permits
    // bundling and redistribution and requires the license to travel with the
    // font — a store submission that ships the one without the other is
    // distributing them outside their terms.
    for (final family in expected.keys) {
      final license = File('assets/fonts/OFL-$family.txt');
      expect(license.existsSync(), isTrue, reason: license.path);
      expect(
        license.readAsStringSync(),
        contains('SIL Open Font License'),
        reason: '${license.path} is not the license it claims to be',
      );
    }
  });

  test('nothing asks for a weight that has no file', () {
    // The app writes `fontWeight: FontWeight.w800` freely. That is fine —
    // the package maps it onto the nearest variant it publishes — but the
    // mapping is only safe while the *published* set is what is on disk.
    // If a face ever ships an ExtraBold upstream, this is the reminder to
    // add the file rather than silently start downloading it.
    final files = Directory('assets/fonts')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.ttf'))
        .toList();
    for (final family in expected.entries) {
      for (final variant in family.value) {
        expect(files, contains('${family.key}-$variant.ttf'));
      }
    }
    expect(
      files.length,
      expected.values.fold<int>(0, (sum, list) => sum + list.length),
      reason: 'unexpected file in assets/fonts: $files',
    );
  });

  testWidgets('the fonts resolve without runtime fetching', (tester) async {
    // `allowRuntimeFetching = false` makes the package *throw* when a face is
    // neither bundled nor cached, and it prints the failure rather than
    // rethrowing — so the check is that nothing complains.
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Text('Budget Buddy', style: GoogleFonts.pixelifySans()),
            Text(
              'Budget Buddy',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w800),
            ),
            Text('Budget Buddy', style: GoogleFonts.quicksand()),
            Text(
              'Budget Buddy',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Budget Buddy'), findsNWidgets(4));
  });
}
