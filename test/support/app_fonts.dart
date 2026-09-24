import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Registers the app's real typefaces before a layout test runs.
///
/// **Why this is needed even though the fonts are bundled.** `google_fonts`
/// resolves a bundled asset the first time a face is *used*, and that
/// resolution is asynchronous — it returns the `TextStyle` immediately and
/// registers the font a moment later. In a widget test that means only the
/// faces referenced in the very first build are loaded by the time anything
/// gets measured; a face first used deeper in the tree is still the fallback.
///
/// Measured directly: after one `pumpAndSettle`, `Quicksand_regular` laid out
/// "MMMMiiii" at 83.3px (real) while `Quicksand_700`, `Quicksand_600` and
/// every Pixelify weight came out at exactly 160px — 20px a glyph, which is
/// the one-em-per-character signature of the test fallback. Half the app was
/// being measured in the wrong font, and the half varied with build order.
///
/// So the faces are registered by hand instead, from the same files the app
/// bundles. [FontLoader] is synchronous to await and does not race.
///
/// The family names are the ones `google_fonts` itself uses —
/// `{Family}_{variant}`, where the 400 variant is spelled `regular`. That is
/// an internal detail of the package, and it is checked rather than assumed:
/// `app_fonts_loaded_test.dart` fails if a face still measures like the
/// fallback, so a rename upstream surfaces as one clear failure rather than
/// as mysteriously wrong widths across every layout suite.
Future<void> loadAppFonts() async {
  // Required in a plain `test` file: without a binding, `FontLoader.load()`
  // has nothing to register against and returns without doing anything.
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final face in _faces.entries) {
    final bytes = File('assets/fonts/${face.value}').readAsBytesSync();
    await (FontLoader(face.key)
          ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer))))
        .load();
  }
  await _loadMaterialIcons();
}

/// Registers the icon font, so a picture taken in a test shows icons.
///
/// **Why.** Without it every `Icon` in a test renders as an empty box, so the
/// pictures the layout suites save look broken in a way the real app is not, and
/// a person reviewing them cannot judge whether an icon is the right one or in
/// the right place. Layout is unaffected either way: an `Icon` is a fixed-size
/// box whatever glyph is drawn in it.
///
/// Read from the Flutter SDK the tests are running under, and skipped quietly
/// when it cannot be found, because the pictures are a convenience and a test
/// must never fail for want of one.
Future<void> _loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer))))
      .load();
}

/// `{google_fonts family key}: {file in assets/fonts}`.
const Map<String, String> _faces = <String, String>{
  'PixelifySans_regular': 'PixelifySans-Regular.ttf',
  'PixelifySans_500': 'PixelifySans-Medium.ttf',
  'PixelifySans_600': 'PixelifySans-SemiBold.ttf',
  'PixelifySans_700': 'PixelifySans-Bold.ttf',
  'Quicksand_300': 'Quicksand-Light.ttf',
  'Quicksand_regular': 'Quicksand-Regular.ttf',
  'Quicksand_500': 'Quicksand-Medium.ttf',
  'Quicksand_600': 'Quicksand-SemiBold.ttf',
  'Quicksand_700': 'Quicksand-Bold.ttf',
};

/// The faces this helper claims to have registered, for a suite that wants to
/// assert its own measurements are meaningful.
Iterable<String> get appFontFamilies => _faces.keys;
