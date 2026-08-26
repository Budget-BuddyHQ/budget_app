import 'dart:ui' show Rect, Size;

class AppAssets {
  AppAssets._();

  static const String logo = 'assets/images/logo.png';
  static const String coolTurtle = 'assets/images/cool_turtle.png';
  static const String pixelMainTurtle = 'assets/own_skins/pixelMainTurtle.png';

  // Small pixel-art icon kit — a hand-drawn coin/heart/star/bag matching
  // the app's own palette, sitting unused in assets/images/ui/ while every
  // currency/stat icon elsewhere in the app used a generic Material glyph
  // instead. Swap in wherever a Material icon is standing in for one of
  // these specific things (gold, health, a rating/level, an inventory
  // slot) — not a blanket icon replacement, just the places these four
  // concepts already show up as bare Material icons.
  static const String uiIconCoin = 'assets/images/ui/icon_coin.png';
  static const String uiIconHeart = 'assets/images/ui/icon_heart.png';
  static const String uiIconStar = 'assets/images/ui/icon_star.png';
  static const String uiIconBag = 'assets/images/ui/icon_bag.png';

  /// Nine-sliceable panel art from the same kit — see `PixelPanel`, which
  /// is the only thing that should reference these directly. Sizes are
  /// tiny on purpose (48x32 / 32x32): they are stretched, not drawn at
  /// source size.
  static const String uiPanelDialog = 'assets/images/ui/panel_dialog.png';
  static const String uiPanelSquare = 'assets/images/ui/panel_square.png';

  // ---- Pixel UI kit (generated) ---------------------------------------
  //
  // Everything under `assets/images/ui_kit/` is produced by
  // `tool/make_ui_kit.py`. Read that script before editing any of it — the
  // files are rewritten wholesale on every run, so hand-edits are lost.
  //
  // This exists because the older kit above is a flat rounded rectangle and
  // four 8x8 glyphs, which is why the app kept reading as Material defaults
  // with a pixel font on top rather than as a game. These have real bevels,
  // corner rivets, pressed states, and 16x16 icons with enough detail to
  // survive being scaled up.
  static const String _kit = 'assets/images/ui_kit';

  /// Nine-slice surfaces, sliced and recoloured from the Tiny Swords pack by
  /// `tool/build_ui_pack.py`. Each ships with its own `centerSlice` rect —
  /// the script prints them, and a guessed rect smears the bevel into
  /// something that looks like a scaling bug.
  static const String kitPanelPaper = '$_kit/panel_paper.png';
  static const String kitPanelSlate = '$_kit/panel_slate.png';
  static const String kitPanelBanner = '$_kit/panel_banner.png';
  static const String kitPanelWood = '$_kit/panel_wood.png';

  // Slice rects, printed by `tool/build_ui_pack.py`. Do not guess these, and
  // do not share one between assets.
  //
  // Each is per-asset because the generator **trims transparent padding**
  // before saving, so no two outputs end up the same size. That trim is a
  // correctness fix, not tidying: Flutter fits an image to its *file* bounds,
  // not to the art inside them, so the untrimmed pack drew a bar whose 64x64
  // file held 24 rows of colour as a 2px hairline inside a 6px box — which is
  // exactly what the Finance Brawl progress bar looked like.
  //
  // A nine-slice also can never render smaller than its two end caps
  // combined; Flutter subtracts them from the destination and a negative
  // remainder throws rather than clipping. `PixelFrame` and friends guard
  // for that, but keep it in mind when sizing a call site.
  /// Source pixel sizes, needed alongside the slices.
  ///
  /// A nine-slice's end caps are everything *outside* the slice, so working
  /// out the minimum size a widget can render at needs the source extent —
  /// and after trimming, no two of these are the same. Derived from the
  /// slice alone they would be wrong, because the caps are no longer
  /// symmetric.
  static const Size kitSizePanelPaper = Size(90, 82);
  static const Size kitSizePanelSlate = Size(92, 81);
  static const Size kitSizePanelBanner = Size(104, 103);
  static const Size kitSizePanelWood = Size(98, 106);
  static const Size kitSizeBtnPrimary = Size(44, 44);
  static const Size kitSizeBtnPrimaryPressed = Size(46, 43);
  static const Size kitSizeBtnDanger = Size(44, 44);
  static const Size kitSizeBtnDangerPressed = Size(46, 43);
  static const Size kitSizeBarBase = Size(34, 16);
  static const Size kitSizeRibbon = Size(135, 57);
  static const Size kitSizeRibbonSmall = Size(96, 32);

  static const Rect kitSlicePanelPaper = Rect.fromLTRB(29, 25, 61, 57);
  static const Rect kitSlicePanelSlate = Rect.fromLTRB(30, 25, 62, 57);
  static const Rect kitSlicePanelBanner = Rect.fromLTRB(42, 30, 68, 56);
  static const Rect kitSlicePanelWood = Rect.fromLTRB(36, 36, 62, 62);
  static const Rect kitSliceBtnPrimary = Rect.fromLTRB(14, 14, 30, 30);
  static const Rect kitSliceBtnPrimaryPressed = Rect.fromLTRB(15, 12, 31, 28);
  static const Rect kitSliceBtnDanger = Rect.fromLTRB(14, 14, 30, 30);
  static const Rect kitSliceBtnDangerPressed = Rect.fromLTRB(15, 12, 31, 28);
  static const Rect kitSliceBarBase = Rect.fromLTRB(9, 0, 25, 16);
  static const Rect kitSliceBarBaseSmall = Rect.fromLTRB(6, 0, 22, 10);
  static const Rect kitSliceRibbonGreen = Rect.fromLTRB(52, 0, 84, 57);
  static const Rect kitSliceRibbonGold = Rect.fromLTRB(52, 0, 84, 57);
  static const Rect kitSliceRibbonRed = Rect.fromLTRB(52, 0, 84, 57);
  static const Rect kitSliceRibbonSmallGreen = Rect.fromLTRB(32, 0, 64, 32);
  static const Rect kitSliceRibbonSmallGold = Rect.fromLTRB(32, 0, 64, 32);

  static const String kitBtnPrimary = '$_kit/btn_primary.png';
  static const String kitBtnPrimaryPressed = '$_kit/btn_primary_pressed.png';
  static const String kitBtnDanger = '$_kit/btn_danger.png';
  static const String kitBtnDangerPressed = '$_kit/btn_danger_pressed.png';

  /// Section headings. A heading on a ribbon reads as a game; the same words
  /// in bold text read as a settings screen.
  static const String kitRibbonGreen = '$_kit/ribbon_green.png';
  static const String kitRibbonGold = '$_kit/ribbon_gold.png';
  static const String kitRibbonRed = '$_kit/ribbon_red.png';
  static const String kitRibbonSmallGreen = '$_kit/ribbon_small_green.png';
  static const String kitRibbonSmallGold = '$_kit/ribbon_small_gold.png';

  /// Progress bars. The pack's fill is red — right for health, wrong for
  /// progress — so it is emitted in three colours and picked by meaning.
  static const String kitBarBase = '$_kit/bar_base.png';
  static const String kitBarBaseSmall = '$_kit/bar_base_small.png';
  static const String kitBarFillGreen = '$_kit/bar_fill_green.png';
  static const String kitBarFillGold = '$_kit/bar_fill_gold.png';
  static const String kitBarFillRed = '$_kit/bar_fill_red.png';
  static const String kitBarFillSmallGreen = '$_kit/bar_fill_small_green.png';
  static const String kitBarFillSmallRed = '$_kit/bar_fill_small_red.png';

  /// The pack's own icons, kept at their painted colours.
  static const String kitPackCoin = '$_kit/pack_icon_coin.png';
  static const String kitPackShield = '$_kit/pack_icon_shield.png';
  static const String kitPackArrowGreen = '$_kit/pack_icon_arrow_green.png';
  static const String kitPackArrowOrange = '$_kit/pack_icon_arrow_orange.png';
  static const String kitPackX = '$_kit/pack_icon_x.png';
  static const String kitPackInfo = '$_kit/pack_icon_info.png';

  // 16x16 icons from tool/make_ui_kit.py. The pack has no coin stack, piggy
  // bank or up/down chart, and those are the concepts a budgeting app needs
  // most — so these are hand-drawn rather than borrowed.
  static const String kitIconCoin = '$_kit/icon_coin.png';
  static const String kitIconStack = '$_kit/icon_stack.png';
  static const String kitIconPiggy = '$_kit/icon_piggy.png';
  static const String kitIconChartUp = '$_kit/icon_chart_up.png';
  static const String kitIconChartDown = '$_kit/icon_chart_down.png';
  static const String kitIconHeart = '$_kit/icon_heart.png';
  static const String kitIconStar = '$_kit/icon_star.png';
  static const String kitIconShield = '$_kit/icon_shield.png';
  static const String kitIconLock = '$_kit/icon_lock.png';
  static const String kitIconBook = '$_kit/icon_book.png';
  static const String kitIconTrophy = '$_kit/icon_trophy.png';
  static const String kitIconCheck = '$_kit/icon_check.png';
  static const String kitIconCross = '$_kit/icon_cross.png';

  /// Chunky pointers for the first-run tutorial. White-cored on purpose so
  /// they stay readable over both the dark panels and the bright pixel map.
  static const String kitArrowUp = '$_kit/arrow_up.png';
  static const String kitArrowDown = '$_kit/arrow_down.png';
  static const String kitArrowLeft = '$_kit/arrow_left.png';
  static const String kitArrowRight = '$_kit/arrow_right.png';

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
  static const String brawlChestSprite =
      'assets/images/finance_brawl_ui/brawl_vault.png';

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
  //   -> tool/normalize_walk_baseline.py (re-cell taller + clamp the walk
  //                                        dip — run this LAST, after any
  //                                        re-pack, or the goofy accordion
  //                                        walk comes back; see its own
  //                                        docstring and
  //                                        docs/ADVENTURE_TOWN.md §9c)
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
  // Was 152 — grown by 10px of top padding so the walk-cycle normalizer
  // (tool/normalize_walk_baseline.py) had headroom to lift extended-leg
  // frames without clipping the hat. See that script's docstring and
  // docs/CHALLENGES.md §2 for the full account of why this needed to
  // change (not just clamp the dip in place) and what was tried first.
  static const double villagerCellHeight = 162;
  static const int villagerSheetColumns = 8;
  static const int villagerSheetRows = 4;

  /// The sprite cell's width:height ratio (104/162 ≈ 0.642).
  ///
  /// Drawing a villager into a **square** box squashes them — which is
  /// exactly what the Adventure map was doing (`Vector2.all(32)`) and why
  /// every skin's walk cycle looked wrong. Multiply the on-screen height by
  /// this to get the matching width.
  static const double villagerAspectRatio =
      villagerCellWidth / villagerCellHeight;

  // ---- Town NPC frames (individual PNGs, 102x116 each) ----
  // Not sprite sheets — one file per frame — so these are built as
  // numbered path lists rather than sliced out of a grid.
  static const double npcFrameWidth = 102;
  static const double npcFrameHeight = 116;
  static const double npcAspectRatio = npcFrameWidth / npcFrameHeight;

  /// Interior backdrop (500x175) shown behind a town spot's decision sheet,
  /// so entering a building reads as *going inside* rather than opening a
  /// menu over the map.
  static const String shopRoomBackground =
      'assets/map_assets_coins/building/rooms/room-background-decorated.png';
  static const String plainRoomBackground =
      'assets/map_assets_coins/building/rooms/room-background.png';

  static const String _taxerRoot = 'assets/map_assets_coins/tax-guy';
  static const String _customerRoot =
      'assets/map_assets_coins/customer_more_animations';
  static const String _workerRoot =
      'assets/map_assets_coins/employee_or_background_character_information';

  /// Builds `[root/prefix-1.png, ... root/prefix-N.png]`.
  static List<String> _frames(String dir, String prefix, int count) =>
      List<String>.generate(count, (i) => '$dir/$prefix-${i + 1}.png');

  static List<String> get taxerIdleFrames =>
      _frames('$_taxerRoot/idle', 'Taxer_idle', 4);
  static List<String> get customerIdleFrames =>
      _frames('$_customerRoot/idle', 'Customer_idle', 4);
  static List<String> get fancyIdleFrames =>
      _frames('$_customerRoot/idle-fancy', 'Fancy_idle', 4);
  static List<String> get workerIdleFrames =>
      _frames('$_workerRoot/idle', 'Worker_idle', 3);

  static const String _shopRoot = 'assets/map_assets_coins/shop';

  /// The market stall, 240x175 — the same height as the room backdrop, so
  /// the two composite without scaling.
  static const double shopStallWidth = 240;
  static const double shopStallHeight = 175;

  /// The stall's left [shopStallCropLeft] pixels are an **opaque purple
  /// wall panel** left over from the sprite's original scene. Everything to
  /// the right of it is transparent-backed, so drawn over a different room
  /// the untrimmed sprite paints a purple stripe across the wall.
  ///
  /// Trimmed at draw time (`ClipRect` + `Align(widthFactor:)`) rather than
  /// by re-exporting the PNGs, because there are 36 of them across two
  /// stalls and an edited copy would drift from the source art.
  static const double shopStallCropLeft = 24;

  /// Fraction of the sprite that survives the crop above.
  static const double shopStallCropFactor =
      (shopStallWidth - shopStallCropLeft) / shopStallWidth;

  static List<String> get shopIdleFrames =>
      _frames('$_shopRoot/0/idle', 'Shop1_idle', 4);

  /// The over-the-counter sale, played once per purchase.
  static List<String> get shopSellFrames =>
      _frames('$_shopRoot/0/sell', 'Shop1_sell', 14);

  /// The lamplit stall — used for the upmarket shops so two stores in the
  /// same town do not look like the same building.
  static List<String> get fancyShopIdleFrames =>
      _frames('$_shopRoot/1/idle', 'Shop2_idle', 4);
  static List<String> get fancyShopSellFrames =>
      _frames('$_shopRoot/1/sell', 'Shop2_sell', 14);

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
