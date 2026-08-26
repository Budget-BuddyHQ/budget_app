import 'dart:io';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('every ending has its own face', () {
    // Same class of bug as the money font's missing 5: an asset referenced by
    // a switch that has no file behind it fails silently at runtime, showing
    // a fallback glyph that looks deliberate. Only a test catches it.
    for (final archetype in LifeEndingArchetype.values) {
      test('${archetype.name} has a portrait file', () {
        expect(
          File(archetype.portrait).existsSync(),
          isTrue,
          reason: '${archetype.portrait} is missing',
        );
      });
    }

    test('no two endings share a portrait', () {
      // Seven endings that look the same are the problem this replaced —
      // reusing a face would quietly recreate it.
      final paths = LifeEndingArchetype.values
          .map((a) => a.portrait)
          .toList();
      expect(paths.toSet().length, paths.length);
    });

    test('every ending still has copy to go with the face', () {
      for (final archetype in LifeEndingArchetype.values) {
        expect(archetype.label, isNotEmpty, reason: archetype.name);
        expect(
          archetype.blurb.length,
          greaterThan(40),
          reason: '${archetype.name} needs a real sentence, not a stub',
        );
      }
    });

    test('portraits live under the bundled folder, not the imported tree', () {
      // The imported pack is 3,298 files and stays out of the build; only the
      // seven copied portraits ship.
      for (final archetype in LifeEndingArchetype.values) {
        expect(
          archetype.portrait,
          startsWith('assets/images/ending_faces/'),
          reason: archetype.name,
        );
      }
    });
  });
}
