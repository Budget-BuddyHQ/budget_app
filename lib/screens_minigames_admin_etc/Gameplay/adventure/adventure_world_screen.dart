import 'dart:math';
import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/spritefusion/reader/spritefusion_asset_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart'
    show DeviceOrientation, LogicalKeyboardKey, rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../controllers_that_updates_stats/life_sim_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_conditions.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_scenarios.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/custom_button.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/orientation_scope.dart';
import 'town_components.dart';
import 'town_interior_screen.dart';

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
  const AdventureWorldScreen({super.key, this.life});

  /// The run this town was opened from, when it was opened from one.
  ///
  /// Null when the map is reached any other way, and the screen works exactly
  /// as before in that case — the town is still a place you can visit on its
  /// own. When it is set, what you decide in a building lands on the
  /// character as well as on the account: see
  /// [LifeSimController.applyTownOutcome].
  ///
  /// Passed rather than read from a provider because a life is not global
  /// state — there can be a run in progress or not, and the town should not
  /// have to guess which.
  final LifeSimController? life;

  @override
  State<AdventureWorldScreen> createState() => _AdventureWorldScreenState();
}

class _AdventureWorldScreenState extends State<AdventureWorldScreen> {
  // null = still checking, true = map found, false = not there yet
  bool? _mapReady;

  /// Buildings entered *this visit*.
  ///
  /// Starts empty every time you walk into the town, on purpose. It used to
  /// be seeded from saved progress so the "visit every place" tracker could
  /// survive a trip to Profile — but that tracker is gone now, and with it the
  /// reason to remember. What is left is a town where the doors are shut
  /// forever once you have been through them, which is the opposite of a
  /// place worth going back to.
  ///
  /// The scenes behind those doors change with the day *and* your age (see
  /// `townEncounterFor`), so walking back in gets you a different
  /// conversation rather than the same one again.
  final Set<String> _visited = <String>{};

  /// What the town is like this visit.
  ///
  /// Rolled once in `initState` and held. Rolling it in `build` would change
  /// the weather every time the player took a step, and rolling it per spot
  /// would let somebody walk between two buildings and find one on sale and
  /// the other not, on the same afternoon.
  late final TownCondition _today = rollTownCondition(Random());

  /// Which of the two towns this visit is in.
  ///
  /// Rolled once, alongside the weather, for the same reason: re-rolling in
  /// `build` would swap the map out from under a player mid-step. Both are
  /// held for as long as you are inside.
  late final TownMap _townMap =
      TownMap.values[Random().nextInt(TownMap.values.length)];

  final Set<String> _collectedCoinIds = <String>{};

  /// Encounters that have already paid out, by `townEncounterFor().id`.
  ///
  /// Persisted, for exactly the reason the coins are (see
  /// [UserStats.townResolvedSceneIds]): every option in every building calls
  /// `applyChallengePayload` with real gold, and nothing remembered that it
  /// had. Walking out of the town and back in re-rolls `TownCondition`, which
  /// re-deals all twelve buildings — so the loop was: leave, re-enter, take
  /// twelve paying choices, repeat. Unbounded, and for doing the same thing
  /// each time, which is the complaint word for word.
  ///
  /// The [_visited] set above is deliberately *not* this. That one is
  /// per-visit and only tracks which doors have been opened this trip; this
  /// one is per-player and outlives the app.
  final Set<String> _resolvedScenes = <String>{};
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
    // Coins stay remembered, and only coins.
    //
    // They pay real account gold, and gold buys skins — so a coin that came
    // back every time you stepped outside would be an unlimited tap on the
    // economy, which is a different thing from a town that feels alive. The
    // buildings are what reset; the money on the floor does not.
    _collectedCoinIds.addAll(stats.townCollectedCoinIds);
    _resolvedScenes.addAll(stats.townResolvedSceneIds);
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

  /// Applies a state change that a Flame component asked for.
  void _applyAfterFrame(VoidCallback change) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final duringBuild =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!duringBuild) {
      setState(change);
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(change);
    });
  }

  void _onEnterSpot(TownSpot spot) => _applyAfterFrame(() => _nearby = spot);

  void _onExitSpot(TownSpot spot) {
    if (_nearby?.id != spot.id) return;
    _applyAfterFrame(() {
      if (_nearby?.id == spot.id) _nearby = null;
    });
  }

  void _onEnterNpc(TownNpc npc) => _applyAfterFrame(() => _nearbyNpc = npc);

  void _onExitNpc(TownNpc npc) {
    if (_nearbyNpc?.id != npc.id) return;
    _applyAfterFrame(() {
      if (_nearbyNpc?.id == npc.id) _nearbyNpc = null;
    });
  }

  Future<void> _talkTo(TownNpc npc) async {
    if (_sheetOpen) return;
    _sheetOpen = true;
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
      return;
    }
    _applyAfterFrame(() {
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

    // Which conversation this building is having, resolved here as well as
    // inside the interior screen. Both calls pass the same spot, age and
    // condition, and `townEncounterFor` is pure — so they agree, and this is
    // the only place that can check the id against the saved ledger before
    // the screen opens.
    final encounter = townEncounterFor(
      spot,
      lifeAge: widget.life?.age,
      conditionId: _today.id,
    );
    final settled = _resolvedScenes.contains(encounter.id);

    final choice = await Navigator.of(context).push<TownChoice>(
      MaterialPageRoute<TownChoice>(
        builder: (_) => TownInteriorScreen(
          spot: spot,
          lifeAge: widget.life?.age,
          today: _today,
          settled: settled,
        ),
      ),
    );

    _sheetOpen = false;
    if (!mounted || choice == null) {
      return;
    }

    final controller = context.read<UserStatsController>();
    final currentGold = controller.stats.gold;
    // Today's prices, then the affordability clamp — in that order. Clamping
    // first would price a purchase against a balance the player never
    // actually had to cover, and on a cheap day it would refuse a sale they
    // could afford.
    final priced = _today.priceFor(choice.gold, spot.kind);
    final affordable = priced < 0 && currentGold + priced < 0
        ? -currentGold
        : priced;

    // A settled encounter is free in **both** directions.
    //
    // Zeroing only the income would be worse than doing nothing: the shop
    // would still take money for a purchase it no longer rewards, so
    // re-reading a scene you had already worked through would cost you. The
    // rule is that a conversation you have already had does not move your
    // money at all.
    final goldDelta = settled ? 0 : affordable;
    final xpDelta = settled ? 0 : choice.xp;
    final literacyDelta = settled ? 0 : choice.literacy;

    setState(() {
      _visited.add(spot.id);
      if (!settled) _resolvedScenes.add(encounter.id);
    });

    await controller.applyChallengePayload(<String, dynamic>{
      'gold_earned': goldDelta,
      'xp_earned': xpDelta,
      'literacy_points_earned': literacyDelta,
      'spending_habits': <String, dynamic>{
        'town_visited_spots': _visited.toList(),
        'town_resolved_scenes': _resolvedScenes.toList(),
      },
    });

    widget.life?.applyTownOutcome(
      gold: goldDelta,
      xp: xpDelta,
      literacy: literacyDelta,
      // Getting hired is a state change, not a payout, and it is allowed
      // through on a settled encounter — the job board saying "you already
      // read this notice" and then refusing to employ somebody who is now old
      // enough would be a bug wearing an anti-farming rule as a disguise.
      // `LifeSimController.findJob` has its own guard against being hired
      // twice.
      hires: choice.hires,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _OutcomeDialog(
        spot: spot,
        choice: choice,
        goldApplied: goldDelta,
        settled: settled,
        allVisited: _visited.length >= kTownSpots.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final playerSheet = equippedSkin.isHuman
        ? equippedSkin.sheetAsset(body)
        : AppAssets.villagerSheet(null, female: body.isFemale);

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      body: Focus(
        autofocus: true,
        child: Stack(
          children: [
            BonfireWidget(
              map: WorldMapBySpritefusion(
                SpritefusionAssetReader(asset: _townMap.asset),
              ),
              player: _buildPlayer(playerSheet),
              playerControllers: [
                Joystick(directional: JoystickDirectional()),
                Keyboard(
                  config: KeyboardConfig(
                    acceptedKeys: [
                      // WASD Keys
                      LogicalKeyboardKey.keyW,
                      LogicalKeyboardKey.keyA,
                      LogicalKeyboardKey.keyS,
                      LogicalKeyboardKey.keyD,
                      // Arrow Keys
                      LogicalKeyboardKey.arrowUp,
                      LogicalKeyboardKey.arrowDown,
                      LogicalKeyboardKey.arrowLeft,
                      LogicalKeyboardKey.arrowRight,
                    ],
                  ),
                ),
              ],
              components: [
                for (final spot in kTownSpots)
                  TownSpotComponent(
                    spot: spot,
                    townMap: _townMap,
                    onEnter: _onEnterSpot,
                    onExit: _onExitSpot,
                    isVisited: _visited.contains,
                  ),
                // NPCs and floor coins were positioned against the village
                // map by hand and have no second set of coordinates, so on
                // the market map they would stand inside walls. Left out
                // there rather than placed badly -- an NPC embedded in a
                // building is worse than a quieter street.
                if (_townMap == TownMap.village)
                  for (final npc in kTownNpcs)
                    TownNpcComponent(
                      npc: npc,
                      idle: _npcIdleAnimation(npc.look),
                      walk: _npcWalkAnimation(npc.look),
                      onEnter: _onEnterNpc,
                      onExit: _onExitNpc,
                    ),
                if (_townMap == TownMap.village)
                  for (final coin in kTownCoins)
                    if (!_collectedCoinIds.contains(_coinId(coin)))
                      TownCoinComponent(
                        value: coin.value,
                        tileX: coin.x,
                        tileY: coin.y,
                        onCollect: (value) =>
                            _collectCoin(_coinId(coin), value),
                      ),
              ],
              cameraConfig: CameraConfig(zoom: 1.6, moveOnlyMapArea: true),
            ),
            SafeArea(
              child: Stack(
                children: [
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
                            today: _today,
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
      ),
    );
  }

  TownPlayer _buildPlayer(String sheetAsset) {
    Future<SpriteAnimation> row(int rowIndex, int frameCount) =>
        _loadRowAnimation(
          sheetAsset,
          rowIndex,
          frameCount,
          stepTime: kTownWalkStepTime,
        );
    Future<SpriteAnimation> frame(int rowIndex) =>
        _loadRowAnimation(sheetAsset, rowIndex, 1, stepTime: 1);
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
      position: Vector2(
        townSpawnTile(_townMap).x * 16.0,
        townSpawnTile(_townMap).y * 16.0,
      ),
      size: Vector2(34 * AppAssets.villagerAspectRatio, 34),
      speed: kTownWalkSpeed,
      animation: SimpleDirectionAnimation(
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

class _ObjectiveBar extends StatelessWidget {
  const _ObjectiveBar({
    required this.visitedCount,
    required this.totalCount,
    required this.coinsFound,
    required this.today,
  });

  final int visitedCount;
  final int totalCount;
  final int coinsFound;

  /// What the town is like this visit. See [TownCondition] for why the map
  /// had to say this out loud rather than only behave differently.
  final TownCondition today;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      // No progress bar and no "3/12".
      //
      // A completion tracker turns a town into a checklist, and the town is
      // not a checklist any more: it resets every time you walk in, so there
      // is no total to be a fraction of. Counting toward a number that gets
      // wiped on the way out would be actively misleading.
      //
      // The label stays, because a player arriving on a tile map still needs
      // one line telling them what this place is for.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            today.isOrdinary ? Icons.flag_rounded : today.icon,
            color: today.isOrdinary ? AppTheme.greenPrimary : today.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedLabel(
              // An ordinary day keeps the old label. Announcing "an ordinary
              // day" would make the ordinary case — which is most of them —
              // read as an event that failed to happen.
              today.isOrdinary ? 'Explore the town' : today.label,
              style: GoogleFonts.pixelifySans(
                color: today.isOrdinary ? Colors.white : today.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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

class _OutcomeDialog extends StatelessWidget {
  const _OutcomeDialog({
    required this.spot,
    required this.choice,
    required this.goldApplied,
    required this.settled,
    required this.allVisited,
  });

  final TownSpot spot;
  final TownChoice choice;
  final int goldApplied;

  /// Whether this encounter had already paid out before this visit.
  final bool settled;
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
          // The outcome text above is shown either way — it is the lesson,
          // and it is worth re-reading. Only the reward pills change, and on
          // a settled encounter they are replaced by the reason rather than
          // just missing.
          if (settled)
            Text(
              'No coins this time — you had already worked this one out.',
              style: GoogleFonts.quicksand(
                color: Colors.white54,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            )
          else
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
  return SpriteAnimation.spriteList(sprites, stepTime: 0.28);
}

Future<SpriteAnimation> _npcWalkAnimation(TownNpcLook look) async {
  final paths = switch (look) {
    TownNpcLook.taxer => AppAssets.taxerWalkFrames,
    TownNpcLook.customer => AppAssets.customerWalkFrames,
    TownNpcLook.fancy => AppAssets.fancyWalkFrames,
    TownNpcLook.worker => AppAssets.workerWalkFrames,
  };
  final sprites = <Sprite>[];
  for (final path in paths) {
    final image = await _villagerSheetImages.load(path);
    sprites.add(Sprite(image));
  }
  return SpriteAnimation.spriteList(sprites, stepTime: 0.16);
}

const double kTownWalkSpeed = 60;

/// Seconds per frame of the walk cycle.
///
/// Was 0.07 — fourteen frames a second, which on a six-frame cycle meant the
/// whole thing repeated more than twice a second and read as a judder rather
/// than a stride. 0.11 over four frames is a 0.44s cycle, which is roughly
/// the cadence of an actual walking person.
const double kTownWalkStepTime = 0.11;

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
  return SpriteAnimation.spriteList([
    for (final c in columns) sheet.getSprite(row, c),
  ], stepTime: stepTime);
}

/// The side-on walk cycle.
///
/// **What was wrong, and it was not the drawing.** Every villager sheet has
/// eight side-facing columns but only *four distinct poses* — measured across
/// all 38 sheets, column 0 was pixel-identical to 4, 1 to 3, and 5 to 7. And
/// 5-7 were not the other half of the stride, they were the same poses drawn
/// 16% bulkier (7,820 opaque pixels at 79.5px wide against 6,740 at 65px).
///
/// So this cycle used to run slim-pass, slim-up, slim-pass, fat-pass, fat-up,
/// fat-pass: **the same leg leading the whole way round**, with the body
/// swelling and shrinking twice a second. That is what "the character is
/// clanking" was, and it is why redrawing individual frames never fixed it —
/// the frames were fine, the second half of the cycle was missing.
///
/// `tool/fix_side_walk_cycle.py` rebuilds columns 5-7 as copies of 1-2 with
/// only the *leg band* mirrored, so the torso is pixel-identical between the
/// halves (no swell, by construction) and the legs alternate (which is the
/// part that reads as walking). Columns 0 and 4 stay out: they draw
/// front-facing legs on a profile body, so the walk would snap face-on twice
/// per cycle.
const List<int> kSideWalkFrames = <int>[1, 2, 3, 5, 6, 7];
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
