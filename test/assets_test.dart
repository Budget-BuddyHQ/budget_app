import 'dart:io';

import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Guards against the two asset failures this project has actually hit:
/// constants pointing at files that were never shipped, and files on disk that
/// were never declared in pubspec (Flutter does not recurse into subfolders).
void main() {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final declared = ((pubspec['flutter'] as YamlMap)['assets'] as YamlList)
      .map((entry) => entry.toString())
      .toList(growable: false);

  bool isDeclared(String path) {
    final normalized = path.replaceAll(r'\', '/');
    return declared.any((entry) {
      if (entry.endsWith('/')) {
        // A directory entry covers files directly inside it, not nested ones.
        if (!normalized.startsWith(entry)) {
          return false;
        }
        return !normalized.substring(entry.length).contains('/');
      }
      return entry == normalized;
    });
  }

  void expectUsable(String path, {required String label}) {
    expect(
      File(path).existsSync(),
      isTrue,
      reason: '$label points at a missing file: $path',
    );
    expect(
      isDeclared(path),
      isTrue,
      reason:
          '$label is not covered by a pubspec assets entry: $path\n'
          'Flutter does not recurse into subfolders — add the directory '
          'explicitly.',
    );
  }

  group('AppAssets', () {
    test('every skin preview resolves to a declared file', () {
      for (final skin in budgetBuddySkins) {
        expectUsable(skin.previewAsset, label: 'Skin "${skin.name}" preview');
      }
    });

    test('every villager walk frame resolves to a declared file', () {
      for (final skin in budgetBuddySkins.where((s) => s.isHuman)) {
        for (final direction in ['south', 'north', 'west', 'east']) {
          final frames = AppAssets.humanWalk(skin.humanVariantId, direction);
          expect(
            frames,
            isNotEmpty,
            reason: '${skin.name} has no $direction frames',
          );
          for (final frame in frames) {
            expectUsable(frame, label: '${skin.name} $direction frame');
          }
        }
      }
    });

    test('goomba walk frames resolve', () {
      for (final frame in [
        ...AppAssets.goombaWalkSouth,
        ...AppAssets.goombaWalkNorth,
      ]) {
        expectUsable(frame, label: 'Goomba frame');
      }
    });

    test('named single-file assets resolve', () {
      final named = <String, String>{
        'logo': AppAssets.logo,
        'coolTurtle': AppAssets.coolTurtle,
        'pixelMainTurtle': AppAssets.pixelMainTurtle,
        'loadingAnimation': AppAssets.loadingAnimation,
        'reactChallengeQuestions': AppAssets.reactChallengeQuestions,
        'villageMapBackground': AppAssets.villageMapBackground,
        'homeTileBackground': AppAssets.homeTileBackground,
        'profileTileBackground': AppAssets.profileTileBackground,
        'arcadeTileBackground': AppAssets.arcadeTileBackground,
        'adventureMapBackground': AppAssets.adventureMapBackground,
        'meadowTileBackground': AppAssets.meadowTileBackground,
        'tileGrass': AppAssets.tileGrass,
        'tileShore': AppAssets.tileShore,
        'tileCoin': AppAssets.tileCoin,
        'iconHouse': AppAssets.iconHouse,
        'iconMoney': AppAssets.iconMoney,
        'iconWater': AppAssets.iconWater,
        'iconMedicine': AppAssets.iconMedicine,
        'iconGas': AppAssets.iconGas,
        'iconInternet': AppAssets.iconInternet,
        'iconPancake': AppAssets.iconPancake,
        'iconStreaming': AppAssets.iconStreaming,
        'iconBox': AppAssets.iconBox,
        'iconCrunchyroll': AppAssets.iconCrunchyroll,
        'iconMarket': AppAssets.iconMarket,
      };

      named.forEach((name, path) {
        expectUsable(path, label: 'AppAssets.$name');
      });
    });
  });

  group('skin catalogue', () {
    test('every case rarity has at least one skin behind it', () {
      // Without this a lucky roll silently degrades to the fallback skin,
      // which is what used to happen to the 1-in-10,000 mythic tier.
      expect(skinCatalogCoversAllRarities, isTrue);
      for (final odds in skinCaseRarityOdds) {
        expect(
          budgetBuddySkins.where((skin) => skin.rarity == odds.rarity),
          isNotEmpty,
          reason: 'No skin exists for ${odds.rarity.name}',
        );
      }
    });

    test('skin ids are unique', () {
      final ids = budgetBuddySkins.map((skin) => skin.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
