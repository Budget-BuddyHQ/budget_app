class AppAssets {
  AppAssets._();

  static const String logo = 'assets/images/logo.png';
  static const String coolTurtle = 'assets/images/cool_turtle.png';
  static const String pixelMainTurtle = 'assets/own_skins/pixelMainTurtle.png';

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

  static const String turtleClassic =
      'assets/images/turtles/Wface_no_bg_l7nvmfum.png';
  static const String turtleCoinShell =
      'assets/images/turtles/cuteBigHead_no_bg_3xfq2ne3.png';
  static const String turtleGuildRunner =
      'assets/images/turtles/walkingredshell_no_bg_63pfbf03.png';
  static const String turtleExplorer =
      'assets/images/turtles/cuteTropicalhandDrawn_no_bg_i3ipxxln.png';

  // Human villagers. Frames are cropped from the hand-drawn sheets in
  // assets/own_skins by tool/crop_human_skins.ps1; the colour variants are
  // generated from those frames by tool/make_human_variants.ps1. Every variant
  // folder holds the same frame names, so a variant is just a path prefix.
  static const String humansRoot = 'assets/images/humans';

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

  /// Preview frame (front-facing, standing) for [variantId]; pass null for the
  /// original blue villager.
  static String humanPreview(String? variantId) =>
      humanFrame(variantId, 'south', 1);

  static String humanFrame(String? variantId, String direction, int frame) {
    final base = variantId == null ? humansRoot : '$humansRoot/$variantId';
    return '$base/$direction$frame.png';
  }

  /// Walk-cycle frames for one direction: `south` (8), `north` (7), `west` (8)
  /// or `east` (8, mirrored from west by the crop tool).
  static List<String> humanWalk(String? variantId, String direction) {
    final count = direction == 'north' ? 7 : 8;
    return <String>[
      for (var i = 1; i <= count; i++) humanFrame(variantId, direction, i),
    ];
  }

  /// Same as [humanWalk] but relative to `assets/images/`, which is the root
  /// Flame/Bonfire resolves sprite paths against.
  static List<String> humanWalkForFlame(String? variantId, String direction) =>
      humanWalk(variantId, direction)
          .map((path) => path.replaceFirst('assets/images/', ''))
          .toList(growable: false);

  // Mushroom Goomba — 4-frame directional walk cycle (south = toward camera,
  // north = away). The first south frame doubles as the skin preview image.
  static const String goombaDir = 'assets/own_skins/mushroom_goomba/walking_animation/';
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
