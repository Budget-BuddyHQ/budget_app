import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/spritefusion/reader/spritefusion_asset_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/custom_button.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/orientation_scope.dart';
import 'town_components.dart';

/// Where the exported map (Sprite Fusion JSON — see the README next to it)
/// is expected to live. `SpritefusionAssetReader` is hardcoded to read from
/// under `assets/images/` and expects `spritesheet.png` alongside this file,
/// so neither can move without also changing that.
const String kAdventureMapAsset = 'assets/images/maps/map.json';

/// The RPG overworld — walk the equipped villager skin around town, bump
/// into places, and make a money decision at each one. The decisions are
/// the same shape as the Life sim's (a prompt, a few choices, stat deltas),
/// which is what makes this "BitLife plus more" rather than a separate
/// game: Life asks in a feed, the town asks in a world.
class AdventureWorldScreen extends StatefulWidget {
  const AdventureWorldScreen({super.key});

  @override
  State<AdventureWorldScreen> createState() => _AdventureWorldScreenState();
}

class _AdventureWorldScreenState extends State<AdventureWorldScreen> {
  // null = still checking, true = map found, false = not there yet.
  bool? _mapReady;

  // Seeded from saved progress in initState — both used to start empty
  // every time this screen opened, so leaving the town (even just to check
  // Profile) reset "visit every place" to zero and, worse, let the same
  // coins be collected for real gold over and over. See
  // `UserStats.townVisitedSpotIds`/`townCollectedCoinIds`.
  final Set<String> _visited = <String>{};
  final Set<String> _collectedCoinIds = <String>{};
  int _coinsFound = 0;
  TownSpot? _nearby;
  TownNpc? _nearbyNpc;
  final Map<String, int> _npcLineIndex = <String, int>{};
  bool _sheetOpen = false;

  static String _coinId(({int x, int y, int value}) coin) =>
      '${coin.x}_${coin.y}';

  @override
  void initState() {
    super.initState();
    final stats = context.read<UserStatsController>().stats;
    _visited.addAll(stats.townVisitedSpotIds);
    _collectedCoinIds.addAll(stats.townCollectedCoinIds);
    _coinsFound = kTownCoins
        .where((coin) => _collectedCoinIds.contains(_coinId(coin)))
        .fold(0, (sum, coin) => sum + coin.value);
    _checkForMap();
  }

  Future<void> _checkForMap() async {
    var found = true;
    try {
      await rootBundle.load(kAdventureMapAsset);
    } catch (_) {
      found = false;
    }
    if (mounted) {
      setState(() => _mapReady = found);
    }
  }

  void _onEnterSpot(TownSpot spot) {
    if (!mounted) return;
    setState(() => _nearby = spot);
  }

  void _onExitSpot(TownSpot spot) {
    if (!mounted) return;
    // Guarded on identity so leaving spot A doesn't clear the prompt for
    // spot B when two sensors overlap on adjacent tiles.
    if (_nearby?.id == spot.id) {
      setState(() => _nearby = null);
    }
  }

  void _onEnterNpc(TownNpc npc) {
    if (!mounted) return;
    setState(() => _nearbyNpc = npc);
  }

  void _onExitNpc(TownNpc npc) {
    if (!mounted) return;
    if (_nearbyNpc?.id == npc.id) {
      setState(() => _nearbyNpc = null);
    }
  }

  Future<void> _talkTo(TownNpc npc) async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    // Cycle the line so a second conversation isn't a copy of the first.
    final seen = _npcLineIndex[npc.id] ?? 0;
    final line = npc.lines[seen % npc.lines.length];
    _npcLineIndex[npc.id] = seen + 1;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NpcDialogueSheet(npc: npc, line: line),
    );
    _sheetOpen = false;
  }

  Future<void> _collectCoin(String coinId, int value) async {
    if (!mounted || _collectedCoinIds.contains(coinId)) {
      // Belt and braces: the component itself is only ever built for
      // not-yet-collected coins (see the `kTownCoins` loop below), but
      // guarding here too means this method is safe to call regardless of
      // how it's reached.
      return;
    }
    setState(() {
      _coinsFound += value;
      _collectedCoinIds.add(coinId);
    });
    await context.read<UserStatsController>().applyChallengePayload(
      <String, dynamic>{
        'gold_earned': value,
        'spending_habits': <String, dynamic>{
          'town_collected_coins': _collectedCoinIds.toList(),
        },
      },
    );
    if (!mounted) return;
    GameToast.show(
      context,
      message: '+$value gold',
      icon: Icons.paid_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  Future<void> _openSpot(TownSpot spot) async {
    if (_sheetOpen) return;
    _sheetOpen = true;

    final choice = await showModalBottomSheet<TownChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TownSpotSheet(spot: spot),
    );

    _sheetOpen = false;
    if (!mounted || choice == null) {
      return;
    }

    final controller = context.read<UserStatsController>();
    // Gold can go negative on a spending choice; clamp so a purchase can
    // never push the balance below zero (the sheet already shows the cost,
    // so this only bites a player who is genuinely broke).
    final currentGold = controller.stats.gold;
    final goldDelta = choice.gold < 0 && currentGold + choice.gold < 0
        ? -currentGold
        : choice.gold;

    setState(() => _visited.add(spot.id));

    await controller.applyChallengePayload(<String, dynamic>{
      'gold_earned': goldDelta,
      'xp_earned': choice.xp,
      'literacy_points_earned': choice.literacy,
      'spending_habits': <String, dynamic>{
        'town_visited_spots': _visited.toList(),
      },
    });

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _OutcomeDialog(
        spot: spot,
        choice: choice,
        goldApplied: goldDelta,
        allVisited: _visited.length >= kTownSpots.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Locked landscape for the whole screen (loading/pending included, not
    // just once the canvas mounts, so there's no rotation jump mid-screen) —
    // an open-world map reads far better wide than tall, the way Roblox and
    // most overworld games default to landscape on a phone/tablet. Restores
    // the app's normal both-orientations behaviour on the way out via
    // [OrientationScope]'s own dispose hook.
    return OrientationScope(
      orientations: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_mapReady == null) {
      return const Scaffold(
        backgroundColor: AppTheme.deepForest,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF85EFAC)),
        ),
      );
    }

    if (_mapReady == false) {
      return const _AdventureMapPendingScreen();
    }

    final stats = context.read<UserStatsController>().stats;
    final equippedSkin = skinFromId(stats.equippedSkin);
    final body = stats.villagerBody;
    // The world only has directional walk art for the villager body — a
    // non-human equipped skin (turtle, critter) falls back to the classic
    // villager here rather than showing a static image trying to "walk".
    final playerSheet = equippedSkin.isHuman
        ? equippedSkin.sheetAsset(body)
        : AppAssets.villagerSheet(null, female: body.isFemale);

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: Stack(
        children: [
          BonfireWidget(
            map: WorldMapBySpritefusion(
              SpritefusionAssetReader(asset: kAdventureMapAsset),
            ),
            player: _buildPlayer(playerSheet),
            playerControllers: [Joystick(directional: JoystickDirectional())],
            components: [
              for (final spot in kTownSpots)
                TownSpotComponent(
                  spot: spot,
                  onEnter: _onEnterSpot,
                  onExit: _onExitSpot,
                  isVisited: _visited.contains,
                ),
              for (final npc in kTownNpcs)
                TownNpcComponent(
                  npc: npc,
                  idle: _npcIdleAnimation(npc.look),
                  onEnter: _onEnterNpc,
                  onExit: _onExitNpc,
                ),
              // Already-collected coins are simply never spawned, rather
              // than spawned-then-hidden — the cleanest way to guarantee a
              // collected coin can never pay out gold again on this visit.
              for (final coin in kTownCoins)
                if (!_collectedCoinIds.contains(_coinId(coin)))
                  TownCoinComponent(
                    value: coin.value,
                    tileX: coin.x,
                    tileY: coin.y,
                    onCollect: (value) => _collectCoin(_coinId(coin), value),
                  ),
            ],
            cameraConfig: CameraConfig(
              zoom: 1.6,
              // Clamped to the map. Walking to the edge now stops the
              // *camera* at the boundary instead of letting it drift past
              // and reveal empty black space beyond the cliffs.
              //
              // This was previously `false` on the reasoning that a sliver
              // of void reads as a real world edge — that was wrong for
              // this game. The border cliffs already block the player, so
              // the void was pure visual noise with nothing behind it.
              moveOnlyMapArea: true,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // A Row rather than two `Positioned`s with a hardcoded
                // `left: 66` gap between them. That offset was sized around
                // a circular icon-only back button; the moment it became a
                // labelled "Go home" pill it was too narrow and the two
                // overlapped. Laying them out relative to each other means
                // the objective bar takes whatever is left, whatever the
                // button's label ends up being.
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _AdventureBackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ObjectiveBar(
                          visitedCount: _visited.length,
                          totalCount: kTownSpots.length,
                          coinsFound: _coinsFound,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_nearby != null)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: _InteractButton(
                      spot: _nearby!,
                      visited: _visited.contains(_nearby!.id),
                      onTap: () => _openSpot(_nearby!),
                    ),
                  )
                // A place and a person can overlap; the place wins, since
                // it's the one that carries the objective.
                else if (_nearbyNpc != null)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: _TalkButton(
                      npc: _nearbyNpc!,
                      onTap: () => _talkTo(_nearbyNpc!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TownPlayer _buildPlayer(String sheetAsset) {
    // Row layout matches AppAssets' villager sheet convention exactly:
    // 8 columns x 4 rows (south/north/west/east), 104x152 per cell, north
    // has only 7 real frames. See app_assets.dart for the source of truth.
    Future<SpriteAnimation> row(int rowIndex, int frameCount) =>
        _loadRowAnimation(
          sheetAsset,
          rowIndex,
          frameCount,
          stepTime: kTownWalkStepTime,
        );
    Future<SpriteAnimation> frame(int rowIndex) =>
        _loadRowAnimation(sheetAsset, rowIndex, 1, stepTime: 1);
    // Side rows skip their front-facing neutral frames — see
    // [kSideWalkFrames] / [kSideIdleFrame].
    Future<SpriteAnimation> sideRow(int rowIndex) => _loadRowFrames(
      sheetAsset,
      rowIndex,
      kSideWalkFrames,
      stepTime: kTownWalkStepTime,
    );
    Future<SpriteAnimation> sideIdle(int rowIndex) => _loadRowFrames(
      sheetAsset,
      rowIndex,
      const <int>[kSideIdleFrame],
      stepTime: 1,
    );

    return TownPlayer(
      // Just outside your own front door (tile 13,31 — the `spot_home`
      // house is at 13,30), rather than the old town-square spawn at
      // (25,25). You leave home to go into town and come back to it, so
      // starting anywhere else made the map read as a level select rather
      // than a place you live. Verified walkable, reachable, and with two
      // clear rows overhead so the sprite doesn't clip the house — the
      // same checks `test/town_map_test.dart` runs on every NPC.
      position: Vector2(
        kTownSpawnTile.x * 16.0,
        kTownSpawnTile.y * 16.0,
      ),
      // Was `Vector2.all(32)` — a square. The sprite cell is 104x152, so
      // squeezing it into a square squashed every skin and made the walk
      // cycle look wrong. Height-first, width derived from the real cell
      // ratio, keeps the character in proportion.
      size: Vector2(34 * AppAssets.villagerAspectRatio, 34),
      speed: kTownWalkSpeed,
      animation: SimpleDirectionAnimation(
        // enabledFlipX defaults true, which would mirror one direction to
        // fake the other — the sheet already has real, distinct west/east
        // art (verified pixel-wise: row 3 is an exact mirror of row 2), so
        // that's turned off to avoid double-flipping it.
        enabledFlipX: false,
        idleDown: frame(0),
        runDown: row(0, 8),
        idleUp: frame(1),
        runUp: row(1, 7),
        idleLeft: sideIdle(2),
        runLeft: sideRow(2),
        idleRight: sideIdle(3),
        runRight: sideRow(3),
      ),
    );
  }
}

/// Top-of-screen progress, so the map has a stated goal instead of being a
/// walking simulator — "visit every place" is the objective the whole
/// screen is built around.
class _ObjectiveBar extends StatelessWidget {
  const _ObjectiveBar({
    required this.visitedCount,
    required this.totalCount,
    required this.coinsFound,
  });

  final int visitedCount;
  final int totalCount;
  final int coinsFound;

  @override
  Widget build(BuildContext context) {
    final done = visitedCount >= totalCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: (done ? AppTheme.greenPrimary : Colors.white).withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.emoji_events_rounded : Icons.flag_rounded,
            color: done ? const Color(0xFFFFD45C) : AppTheme.greenPrimary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  done ? 'Town explored!' : 'Explore the town',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: totalCount == 0 ? 0 : visitedCount / totalCount,
                    minHeight: 5,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(
                      done ? const Color(0xFFFFD45C) : AppTheme.greenPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$visitedCount/$totalCount',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (coinsFound > 0) ...[
            const SizedBox(width: 12),
            const Icon(Icons.paid_rounded, color: Color(0xFFFFD45C), size: 16),
            const SizedBox(width: 4),
            Text(
              '$coinsFound',
              style: GoogleFonts.pixelifySans(
                color: const Color(0xFFFFD45C),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "walk up to something and press A" affordance. Sits bottom-right so
/// it never overlaps the bottom-left joystick.
class _InteractButton extends StatelessWidget {
  const _InteractButton({
    required this.spot,
    required this.visited,
    required this.onTap,
  });

  final TownSpot spot;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: spot.kind.accent, width: 2),
            boxShadow: AppTheme.puffyShadow(spot.kind.accent, restAlpha: 0.35),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spot.kind.icon, color: spot.kind.accent, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spot.title,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    visited ? 'Visit again' : 'Tap to enter',
                    style: GoogleFonts.quicksand(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Talk" affordance for an NPC. Visually quieter than [_InteractButton]
/// because talking is optional colour, not the objective.
class _TalkButton extends StatelessWidget {
  const _TalkButton({required this.npc, required this.onTap});

  final TownNpc npc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: const Color(0xFFFFD45C), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFFFFD45C),
                size: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    npc.name,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Tap to talk',
                    style: GoogleFonts.quicksand(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// NPC speech. One line, one button — deliberately not a decision, so
/// talking never feels like homework.
class _NpcDialogueSheet extends StatelessWidget {
  const _NpcDialogueSheet({required this.npc, required this.line});

  final TownNpc npc;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD45C).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFFFD45C),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                npc.name,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"$line"',
            style: GoogleFonts.quicksand(
              color: Colors.white,
              height: 1.5,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.greenPrimary,
                foregroundColor: AppTheme.deepForest,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Thanks',
                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The decision sheet — same shape as a Life sim event card (prompt on top,
/// a stack of choices underneath), so the two halves of the game teach with
/// one consistent grammar.
class _TownSpotSheet extends StatelessWidget {
  const _TownSpotSheet({required this.spot});

  final TownSpot spot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A real interior above the dialogue, so walking into a
            // building reads as *going inside* rather than a menu opening
            // over the map. Uses the room art already in the repo.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AppAssets.shopRoomBackground,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.none,
                      // The room art is optional decoration — if it ever
                      // goes missing the sheet still works, just flatter.
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: spot.kind.accent.withValues(alpha: 0.15),
                      ),
                    ),
                    // Keeps the title legible over busy interior art.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.panelStrong.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 8,
                      child: Row(
                        children: [
                          Icon(
                            spot.kind.icon,
                            color: spot.kind.accent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            spot.title,
                            style: GoogleFonts.pixelifySans(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              spot.prompt,
              style: GoogleFonts.quicksand(
                color: Colors.white70,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            for (final choice in spot.choices) ...[
              _ChoiceButton(
                choice: choice,
                accent: spot.kind.accent,
                onTap: () => Navigator.of(context).pop(choice),
              ),
              const SizedBox(height: 10),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: Text(
                'Leave',
                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.accent,
    required this.onTap,
  });

  final TownChoice choice;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                choice.label,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (choice.gold != 0) _DeltaChip(choice: choice),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.choice});

  final TownChoice choice;

  @override
  Widget build(BuildContext context) {
    final positive = choice.gold > 0;
    final color = positive ? AppTheme.greenPrimary : AppTheme.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${positive ? '+' : ''}${choice.gold}',
        style: GoogleFonts.pixelifySans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The "here's what that actually meant" beat after a choice — the part
/// that makes a decision a lesson instead of just a stat change.
class _OutcomeDialog extends StatelessWidget {
  const _OutcomeDialog({
    required this.spot,
    required this.choice,
    required this.goldApplied,
    required this.allVisited,
  });

  final TownSpot spot;
  final TownChoice choice;
  final int goldApplied;
  final bool allVisited;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.panelStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        side: BorderSide(color: spot.kind.accent.withValues(alpha: 0.4)),
      ),
      title: Row(
        children: [
          Icon(spot.kind.icon, color: spot.kind.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              choice.label,
              style: GoogleFonts.pixelifySans(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            choice.outcome,
            style: GoogleFonts.quicksand(
              color: Colors.white70,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (goldApplied != 0)
                _RewardPill(
                  label: '${goldApplied > 0 ? '+' : ''}$goldApplied gold',
                  color: goldApplied > 0
                      ? AppTheme.greenPrimary
                      : AppTheme.errorRed,
                ),
              if (choice.xp > 0)
                _RewardPill(
                  label: '+${choice.xp} XP',
                  color: const Color(0xFF69C6FF),
                ),
              if (choice.literacy > 0)
                _RewardPill(
                  label: '+${choice.literacy} LP',
                  color: const Color(0xFFB388FF),
                ),
            ],
          ),
          if (allVisited) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD45C).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFD45C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You visited every place in town!',
                      style: GoogleFonts.pixelifySans(
                        color: const Color(0xFFFFD45C),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.greenPrimary,
            foregroundColor: AppTheme.deepForest,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Got it',
            style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.pixelifySans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The game canvas is a full-bleed [BonfireWidget] with no `AppBar` of its
/// own, so there was no way out of the map short of the OS back gesture —
/// this floats a real, always-visible exit above the canvas.
/// Leaves the town and returns to the life you are living.
///
/// Reads as **"Go home"**, not a generic back arrow. The town is somewhere
/// your character walked *to* from their house, so the way out is going
/// home — a bare `arrow_back` described the navigation stack rather than
/// anything happening in the game. Labelled as well as iconed, because a
/// lone house glyph could just as easily mean "the home screen".
class _AdventureBackButton extends StatelessWidget {
  const _AdventureBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go home, leaving the town',
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text(
                  'Go home',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Builds a looping idle animation from a folder of individual frame PNGs.
///
/// The NPC art is one file per frame rather than a sprite sheet, so this
/// loads each frame as its own sprite instead of slicing a grid the way
/// [_loadRowAnimation] does for the villager sheets.
Future<SpriteAnimation> _npcIdleAnimation(TownNpcLook look) async {
  final paths = switch (look) {
    TownNpcLook.taxer => AppAssets.taxerIdleFrames,
    TownNpcLook.customer => AppAssets.customerIdleFrames,
    TownNpcLook.fancy => AppAssets.fancyIdleFrames,
    TownNpcLook.worker => AppAssets.workerIdleFrames,
  };
  final sprites = <Sprite>[];
  for (final path in paths) {
    final image = await _villagerSheetImages.load(path);
    sprites.add(Sprite(image));
  }
  // Slow on purpose — an idle loop that reads as breathing, not fidgeting.
  return SpriteAnimation.spriteList(sprites, stepTime: 0.28);
}

/// Walk speed and frame rate, tuned **together** so the feet don't slide.
///
/// These are one setting, not two. A walk cycle is 8 frames = 2 footfalls,
/// so the distance covered in `8 * stepTime` seconds is the character's
/// stride for two steps. Get that wrong and the character moonwalks —
/// which is exactly what was happening:
///
/// | | speed | stepTime | tiles per footfall |
/// |---|---|---|---|
/// | before | 80 (bonfire's `Movement.speedDefault`, never overridden) | 0.12 | **2.40** |
/// | now | 60 | 0.07 | **1.05** |
///
/// The character is 34 units tall on a 16-unit tile grid — about 2.1 tiles.
/// A person's stride is roughly half their height, so ~1 tile per footfall
/// is right; 2.4 tiles meant each foot travelled more than the whole
/// character's height per step and visibly skated across the ground.
const double kTownWalkSpeed = 60;
const double kTownWalkStepTime = 0.07;

final _villagerSheetImages = Images(prefix: '');

Future<SpriteAnimation> _loadRowAnimation(
  String sheetAsset,
  int row,
  int frameCount, {
  double stepTime = 0.12,
}) async {
  final image = await _villagerSheetImages.load(sheetAsset);
  final sheet = SpriteSheet(
    image: image,
    srcSize: Vector2(AppAssets.villagerCellWidth, AppAssets.villagerCellHeight),
  );
  return sheet.createAnimation(row: row, stepTime: stepTime, to: frameCount);
}

/// Frames of a row, by explicit column, in the order given.
///
/// Needed because the side-facing rows use a **non-contiguous** subset —
/// see [kSideWalkFrames].
Future<SpriteAnimation> _loadRowFrames(
  String sheetAsset,
  int row,
  List<int> columns, {
  double stepTime = 0.12,
}) async {
  final image = await _villagerSheetImages.load(sheetAsset);
  final sheet = SpriteSheet(
    image: image,
    srcSize: Vector2(AppAssets.villagerCellWidth, AppAssets.villagerCellHeight),
  );
  return SpriteAnimation.spriteList(
    [for (final c in columns) sheet.getSprite(row, c)],
    stepTime: stepTime,
  );
}

/// The west/east walk cycle, **skipping frames 0 and 4**.
///
/// Those two are the neutral/contact poses, and in the side-facing rows
/// they were drawn with *front-facing* legs — two parallel leg columns with
/// a gap between them, as if the character were facing the camera. Frames
/// 1-3 and 5-7 are correct profile poses. So twice per cycle the legs
/// snapped front-on and back, which is what made the side walk look wrong
/// while every structural measurement of the cycle (legs alternate, halves
/// mirror, feet planted) came back correct.
///
/// Fixed by using the good art rather than repainting the bad art. Three
/// pixel edits were prototyped — merging the two legs into one, deleting
/// the far leg, and re-centring — and each left a visible flaw (too chunky,
/// or a leg sitting off-centre under the coat). Dropping the two frames
/// costs nothing: what remains is contact-pass-contact for each leg, a
/// valid six-frame cycle, and it cannot damage the source art.
///
/// If the sheets are ever redrawn with proper profile neutral frames, set
/// this back to all eight columns.
const List<int> kSideWalkFrames = <int>[1, 2, 3, 5, 6, 7];

/// Standing still, facing sideways.
///
/// Frame 1 rather than frame 0 for the same reason — frame 0 is the
/// front-facing stance, so an idle character facing west used to stand
/// with their legs pointing at the camera.
const int kSideIdleFrame = 1;

class _AdventureMapPendingScreen extends StatelessWidget {
  const _AdventureMapPendingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF85EFAC),
                  size: 56,
                ),
                const SizedBox(height: 18),
                Text(
                  'Map on the way',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The adventure world is wired up and ready — it just '
                  'needs its map. Drop a Sprite Fusion or Tiled export at\n'
                  '$kAdventureMapAsset\n'
                  '(plus its spritesheet.png alongside it) and it will '
                  'load automatically.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Back',
                  width: 160,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
