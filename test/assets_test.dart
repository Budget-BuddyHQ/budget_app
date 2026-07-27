import 'dart:io';
import 'dart:ui';

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
    test('every non-villager skin preview resolves to a declared file', () {
      // Villagers render from a packed sheet and have no single preview file;
      // they are covered by the sheet tests below instead.
      for (final skin in budgetBuddySkins.where((skin) => !skin.isHuman)) {
        expectUsable(skin.previewAsset, label: 'Skin "${skin.name}" preview');
      }
    });

    test('every villager has a sheet for both bodies', () {
      // The whole point of the packed sheets is that choosing a body never
      // costs a pull, so a missing female sheet would silently fall back to
      // a broken image for half the players.
      for (final skin in budgetBuddySkins.where((s) => s.isHuman)) {
        for (final body in VillagerBody.values) {
          expectUsable(
            skin.sheetAsset(body),
            label: '${skin.name} (${body.label}) sheet',
          );
        }
      }
    });

    test('villager sheets are the expected grid size', () async {
      // A cell-size drift would misalign every frame in the game and in the
      // customise grid, so pin the packed dimensions to what AppAssets assumes.
      final expectedW =
          (AppAssets.villagerCellWidth * AppAssets.villagerSheetColumns)
              .round();
      final expectedH =
          (AppAssets.villagerCellHeight * AppAssets.villagerSheetRows).round();

      for (final skin in budgetBuddySkins.where((s) => s.isHuman)) {
        for (final body in VillagerBody.values) {
          final bytes = await File(skin.sheetAsset(body)).readAsBytes();
          final codec = await instantiateImageCodec(bytes);
          final decoded = (await codec.getNextFrame()).image;
          expect(
            [decoded.width, decoded.height],
            [expectedW, expectedH],
            reason:
                '${skin.name} (${body.label}) sheet is '
                '${decoded.width}x${decoded.height}, expected '
                '${expectedW}x$expectedH. Re-run tool/pack_skin_sheets.ps1.',
          );
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
