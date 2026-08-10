class AppAssets {
  AppAssets._();

  static const String logo = 'assets/images/logo.png';
  static const String coolTurtle = 'assets/images/cool_turtle.png';
  static const String pixelMainTurtle = 'assets/own_skins/pixelMainTurtle.png';

  /// 8-frame celebration sprite sheet — 3 columns × 3 rows of 640x640 cells,
  /// with the bottom-right cell empty. Frames build from smile → sparkle
  /// burst. Wired into `AchievementCelebration`.
  static const String turtleCelebrateSheet =
      'assets/own_skins/turtle_celebrate/turtle_celebrate.png';
  static const int turtleCelebrateColumns = 3;
  static const int turtleCelebrateRows = 3;
  static const int turtleCelebrateFrames = 8;
  static const double turtleCelebrateCellSize = 640;

  static const String loadingAnimation =
      'assets/animations/02_Manny_Run_Fill.json';

  static const String reactChallengeQuestions =
      'assets/data/react_challenge_questions.json';

  static const String webGameRoot = 'assets/web_game/';

  static const String villageMapBackground =
      'assets/self_made_backgrounds/map.png';
  static const String homeTileBackground =
      'assets/self_made_backgrounds/home_tile_bg.png';
  static const String profileTileBackground =
      'assets/self_made_backgrounds/profile_tile_bg.png';
  static const String arcadeTileBackground =
      'assets/self_made_backgrounds/arcade_tile_bg.png';
  static const String adventureMapBackground =
      'assets/self_made_backgrounds/adventure_map.png';
  static const String meadowTileBackground =
      'assets/self_made_backgrounds/meadow_tile_bg.png';
  static const String tileGrass =
      'assets/map_assets_coins/PNG_more_map_tiles/rpgTile000.png';
  static const String tileShore =
      'assets/map_assets_coins/PNG_more_map_tiles/rpgTile010.png';
  static const String tileCoin = 'assets/images/tiles/coin.png';
  static const String brawlGrasstile =
    'assets/self_made_backgrounds/brawl_grass_tile.png';
  static const String brawlTreeSprite =
    'assets/images/finance_brawl_ui/brawl_tree.png';
  static const String brawlRockSprite = 
    'assets/images/finance_brawl_ui/brawl_rock.png';
  static const String brawlDollarSprite =
    'assets/images/finance_brawl_ui/brawl_dollar.png';
  static const String brawlEnemyOneSprite =
    'assets/images/finance_brawl_ui/brawl_enemy_one.png';
  static const String brawlEnemyTwoSprite =
    'assets/images/finance_brawl_ui/brawl_enemy_two.png';
  static const String brawlBossSprite =
    'assets/images/finance_brawl_ui/brawl_boss.png';

    
  static const String turtleClassic =
      'assets/images/turtles/Wface_no_bg_l7nvmfum.png';
  static const String turtleCoinShell =
      'assets/images/turtles/cuteBigHead_no_bg_3xfq2ne3.png';
  static const String turtleGuildRunner =
      'assets/images/turtles/walkingredshell_no_bg_63pfbf03.png';
  static const String turtleExplorer =
      'assets/images/turtles/cuteTropicalhandDrawn_no_bg_i3ipxxln.png';

  // --- Villager sprite sheets -------------------------------------------
  //
  // Pipeline: hand-drawn sheets in assets/own_skins/
  //   -> tool/crop_human_skins.ps1      (slice into per-frame PNGs)
  //   -> tool/make_female_bases.ps1     (edit hair silhouette for the female body)
  //   -> tool/make_human_variants.ps1   (palette-swap into colour variants)
  //   -> tool/pack_skin_sheets.ps1      (pack into the sheets below)
  //
  // Only the sheets ship. The intermediate per-frame PNGs are build artifacts
  // and are gitignored.
  //
  // Every sheet is an 8-column x 4-row grid of [villagerCellWidth] x
  // [villagerCellHeight] cells, one row per facing:
  //   row 0 south (8)  row 1 north (7, last cell empty)
  //   row 2 west  (8)  row 3 east  (8)
  static const String villagerSheetRoot = 'assets/self_made_skins';

  static const double villagerCellWidth = 104;
  static const double villagerCellHeight = 152;
  static const int villagerSheetColumns = 8;
  static const int villagerSheetRows = 4;

  static const List<String> humanVariantIds = <String>[
    'emerald_scout',
    'gold_banker',
    'crimson_trader',
    'violet_scholar',
    'teal_analyst',
    'sand_saver',
    'rose_planner',
    'slate_investor',
    'midnight_ledger',
    'aurora_prime',
  ];

  /// Sheet for one villager. [variantId] of null is the original blue outfit.
  static String villagerSheet(String? variantId, {required bool female}) {
    final gender = female ? 'female' : 'male';
    final name = variantId ?? 'classic';
    return '$villagerSheetRoot/villager_${gender}_$name.png';
  }

  /// Same path relative to `assets/images/`, the root Flame resolves against.
  /// The sheets live outside that root, so callers must use a zero-prefix
  /// [Images] cache and pass the full path instead.
  static String villagerSheetForFlame(
    String? variantId, {
    required bool female,
  }) => villagerSheet(variantId, female: female);

  static const Map<String, int> _villagerRowForDirection = <String, int>{
    'south': 0,
    'north': 1,
    'west': 2,
    'east': 3,
  };

  static int villagerRow(String direction) =>
      _villagerRowForDirection[direction] ?? 0;

  /// Frame count for a facing. North is 7; every other facing is 8.
  static int villagerFrameCount(String direction) =>
      direction == 'north' ? 7 : 8;

  // Mushroom Goomba — 4-frame directional walk cycle (south = toward camera,
  // north = away). The first south frame doubles as the skin preview image.
  static const String goombaDir =
      'assets/own_skins/mushroom_goomba/walking_animation/';
  static const String goombaWalk = '${goombaDir}walkingframe1.png';
  static const List<String> goombaWalkSouth = <String>[
    '${goombaDir}walkingframe1.png',
    '${goombaDir}walking frame2.png',
    '${goombaDir}walkingframe3.png',
    '${goombaDir}walkingframe4.png',
  ];
  static const List<String> goombaWalkNorth = <String>[
    '${goombaDir}northwalking1.png',
    '${goombaDir}northwalking2.png',
    '${goombaDir}northwalking3.png',
    '${goombaDir}northwalking4.png',
  ];

  static const String iconHouse = 'assets/icons/icons8-house-48.png';
  static const String iconMoney = 'assets/icons/icons8-money-48.png';
  static const String iconWater = 'assets/icons/icons8-water-48.png';
  static const String iconMedicine = 'assets/icons/icons8-medicine-48.png';
  static const String iconGas = 'assets/icons/icons8-gas-station-48.png';
  static const String iconInternet = 'assets/icons/icons8-internet-48.png';
  static const String iconPancake = 'assets/icons/icons8-pancake-stack-48.png';
  static const String iconStreaming =
      'assets/icons/icons8-streaming-service-48.png';
  static const String iconBox = 'assets/icons/box.png';
  static const String iconCrunchyroll =
      'assets/icons/icons8-crunchyroll-48.png';
  static const String iconMarket = 'assets/icons/market.png';
}
