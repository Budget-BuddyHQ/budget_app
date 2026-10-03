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
import '../../../models_Like_Skins_and_lessons_templates/npc_encounters.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_missions.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_unlocks.dart';

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
  /// The town this life lives in. See [townMapForLife].
  ///
  /// Was a per-visit random roll, which meant walking out of the village and
  /// back in could land you in the market town instead — inside a single run.
  late final TownMap _townMap = widget.life == null
      ? TownMap.village
      : townMapForLife(widget.life!.name, widget.life!.origin.name);

  final Set<String> _collectedCoinIds = <String>{};

  /// Lessons finished, read once when the map is built.
  ///
  /// Cached rather than read per marker: the Bonfire component list is
  /// constructed inside `build`, and hitting the controller twelve times
  /// there would be twelve identical reads on every frame the map rebuilds.
  late final Set<String> _completedLessons = context
      .read<UserStatsController>()
      .stats
      .completedLessons
      .toSet();

  /// Which encounter each person last ran, so the same one never repeats
  /// back to back — a pickpocket twice running reads as a bug, not a town.
  final Map<String, String> _lastEncounterId = <String, String>{};

  /// Separate from the town's other randomness on purpose: an encounter roll
  /// must not shift which scene a building is showing.
  final Random _encounterRandom = Random();

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

  /// Talking to somebody, which can now go three ways.
  ///
  /// **It used to go one way.** `_talkTo` picked the next canned line and
  /// showed it, which is what "the NPCs still just give out dialogue" was
  /// describing. A line cannot be acted on, so seven people saying sensible
  /// things about money were seven posters you walked up to.
  ///
  /// Now: an **encounter** if one rolls (a pickpocket, a scam, honest work,
  /// somebody handing your wallet back), otherwise a **mission** if this
  /// person has one outstanding, otherwise the conversation — which is still
  /// the common case, because a town where every stranger robs you is
  /// exhausting and would make the pickpocket routine rather than a shock.
  Future<void> _talkTo(TownNpc npc) async {
    if (_sheetOpen) return;
    // Speaking to somebody is how contacts are made: people who know you are
    // how most work is found. The line is shown after the conversation, so the
    // toast is not lost behind the sheet. See `life_network.dart`.
    final contactLine = widget.life?.meetTownContact(npc.name);
    await _converse(npc);
    if (contactLine != null && mounted) {
      GameToast.show(
        context,
        title: 'Contact',
        message: contactLine,
        icon: Icons.groups_rounded,
        accent: const Color(0xFF58C7FF),
      );
    }
  }

  Future<void> _converse(TownNpc npc) async {
    if (_sheetOpen) return;
    _sheetOpen = true;

    final controller = context.read<UserStatsController>();
    final age = widget.life?.age ?? 12;

    final encounter = encounterFor(
      npc.id,
      age: age,
      roll: _encounterRandom.nextDouble(),
      lastActionId: _lastEncounterId[npc.id],
    );

    if (encounter != null) {
      _lastEncounterId[npc.id] = encounter.id;
      await _runEncounter(npc, encounter);
      _sheetOpen = false;
      return;
    }

    final mission = nextMissionFor(
      npc.id,
      age: age,
      completed: controller.stats.completedMissionIds,
    );

    final seen = _npcLineIndex[npc.id] ?? 0;
    final line = npc.lines[seen % npc.lines.length];
    _npcLineIndex[npc.id] = seen + 1;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // Without this a sheet is capped at half the screen and the
      // content underneath is simply unreachable.
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NpcDialogueSheet(
        npc: npc,
        line: line,
        mission: mission,
        progress: mission == null
            ? 0
            : missionProgress(
                mission,
                coinsSaved: widget.life?.emergencyFund ?? 0,
                placesVisited: _visited.length,
                challengesSolved: controller.stats.challengesSolved,
                age: age,
                lessonsFinished: controller.stats.completedLessons.length,
              ),
        canClaim:
            mission != null &&
            missionComplete(
              mission,
              coinsSaved: widget.life?.emergencyFund ?? 0,
              placesVisited: _visited.length,
              challengesSolved: controller.stats.challengesSolved,
              age: age,
              lessonsFinished: controller.stats.completedLessons.length,
            ),
        onClaim: mission == null ? null : () => _claimMission(mission),
      ),
    );
    _sheetOpen = false;
  }

  /// Applies an encounter's outcome.
  ///
  /// Losses come out of *carried* cash only and are capped — see
  /// `NpcAction.resolveGold`. Being robbed into debt would be a punishment
  /// the player had no way to refuse, and this is played by four-year-olds.
  Future<void> _runEncounter(TownNpc npc, NpcAction action) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      // Without this a sheet is capped at half the screen and the
      // content underneath is simply unreachable.
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: isDeclinable(action.kind),
      enableDrag: isDeclinable(action.kind),
      builder: (_) => _NpcEncounterSheet(npc: npc, action: action),
    );
    if (!mounted) return;

    final tookIt = accepted ?? !isDeclinable(action.kind);
    if (!tookIt) return;

    final carried = widget.life?.money ?? 0;
    final delta = action.resolveGold(carried);
    if (delta == 0) return;

    widget.life?.applyTownOutcome(gold: delta, xp: 2, literacy: 1);
    _applyAfterFrame(() {});
    await context.read<UserStatsController>().applyChallengePayload(
      <String, dynamic>{
        'gold_earned': delta > 0 ? delta : 0,
        'xp_earned': 2,
        'literacy_points_earned': 1,
      },
    );
  }

  /// Pays out a finished mission.
  Future<void> _claimMission(TownMission mission) async {
    Navigator.of(context).pop();
    final controller = context.read<UserStatsController>();
    await controller.completeMission(
      mission.id,
      gold: mission.rewardGold,
      literacy: mission.rewardLiteracy,
    );
    widget.life?.applyTownOutcome(
      gold: mission.rewardGold,
      xp: mission.rewardLiteracy * 2,
      literacy: mission.rewardLiteracy,
    );
    _applyAfterFrame(() {});
    if (!mounted) return;
    GameToast.show(
      context,
      title: mission.title,
      message: mission.onSuccess,
      icon: Icons.verified_rounded,
      accent: AppTheme.greenPrimary,
    );
  }

  /// Whether a coin is already gone.
  ///
  /// In a life this is **per year and per life**, kept by the life itself, so
  /// the town restocks every birthday and a new life starts with every coin on
  /// the map. Outside a life it is the account's own one-time list, as before.
  /// Coins used to be account-only, which is why after the first life the map
  /// had nothing left to pay anybody. See `life_town_income.dart`.
  bool _coinTaken(({int x, int y, int value}) coin) {
    final id = _coinId(coin);
    final life = widget.life;
    return life != null
        ? life.townCoinTaken(id)
        : _collectedCoinIds.contains(id);
  }

  Future<void> _collectCoin(String coinId, int value) async {
    if (!mounted) return;
    final life = widget.life;

    // Life money first. It is what the run is about, and it is the only part
    // that repeats: 0 means this coin was already picked up this year.
    var lifePaid = 0;
    if (life != null) {
      lifePaid = life.takeTownCoin(coinId, value);
      if (lifePaid == 0) return;
    } else if (_collectedCoinIds.contains(coinId)) {
      return;
    }

    // Account gold stays a once-ever reward, or the leaderboard's gold column
    // becomes a treadmill. It is the *life money* that restocks.
    final firstTime = !_collectedCoinIds.contains(coinId);
    _applyAfterFrame(() {
      if (firstTime) {
        _coinsFound += value;
        _collectedCoinIds.add(coinId);
      }
    });
    if (firstTime) {
      await context.read<UserStatsController>().applyChallengePayload(
        <String, dynamic>{
          'gold_earned': value,
          'spending_habits': <String, dynamic>{
            'town_collected_coins': _collectedCoinIds.toList(),
          },
        },
      );
    }
    if (!mounted) return;
    GameToast.show(
      context,
      message: life != null
          ? (firstTime
                ? '+$lifePaid coins  ·  +$value gold'
                : '+$lifePaid coins')
          : '+$value gold',
      icon: Icons.paid_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  Future<void> _openSpot(TownSpot spot) async {
    if (_sheetOpen) return;
    _sheetOpen = true;

    // Some doors want the lesson first.
    //
    // The Academy used to sit off to one side as a reading section that
    // nothing depended on — a player could finish the whole town, every
    // minigame and a dozen lives without opening a single lesson. Reading was
    // optional in the only sense that matters: the game did not care.
    //
    // Four of the twelve buildings now want the unit that explains them. The
    // lock **names the unit**, because a door that is simply shut teaches
    // nothing and reads as a bug — the point is to send somebody to a lesson,
    // not to keep them out of a building.
    final completed = context
        .read<UserStatsController>()
        .stats
        .completedLessons
        .toSet();
    if (!isSpotUnlocked(spot.kind, completed)) {
      final unlock = unlockFor(spot.kind)!;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        // Without this a sheet is capped at half the screen and the
        // content underneath is simply unreachable.
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _LockedSpotSheet(
          spot: spot,
          unlock: unlock,
          progress: unlockProgress(spot.kind, completed),
        ),
      );
      _sheetOpen = false;
      return;
    }

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
          life: widget.life,
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

    // Who you actually are in town.
    //
    // This used to read `: AppAssets.villagerSheet(null, ...)` — so **every
    // non-villager skin walked the town as the default blue villager**. All
    // four turtles and the Goomba. A player could win Guild Runner, a
    // 1-in-1,000 legendary, see it on their profile, in the customize grid
    // and in Finance Brawl, then walk in here as a stranger. Nothing threw:
    // the fallback loaded a real sheet, just not theirs.
    //
    // Those skins are stills, and Bonfire wants a packed grid, so
    // `tool/make_town_sheets.py` packs them into the villager layout — which
    // is why nothing else in this file had to change. The villager fallback
    // stays for anything with neither.
    final playerSheet = equippedSkin.isHuman
        ? equippedSkin.sheetAsset(body)
        : (AppAssets.townSheet(equippedSkin.id) ??
              AppAssets.villagerSheet(null, female: body.isFemale));

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
                Joystick(
                  directional: JoystickDirectional(
                    size: TownJoystickLayout.size,
                    margin: TownJoystickLayout.margin,
                  ),
                ),
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
                    isLocked: !isSpotUnlocked(spot.kind, _completedLessons),
                  ),
                // NPCs and floor coins were positioned against the village
                // map by hand and have no second set of coordinates, so on
                // the market map they would stand inside walls. Left out
                // there rather than placed badly -- an NPC embedded in a
                // building is worse than a quieter street.
                // Both maps have people now. This used to be gated to
                // the village because the NPCs had no second position, so
                // half of all visits were to an empty town.
                for (final npc in kTownNpcs)
                  TownNpcComponent(
                    npc: npc,
                    map: _townMap,
                    idle: _npcIdleAnimation(npc.look),
                    walk: _npcWalkAnimation(npc.look),
                    onEnter: _onEnterNpc,
                    onExit: _onExitNpc,
                  ),
                for (final coin in townCoinsFor(_townMap))
                  if (!_coinTaken(coin))
                    TownCoinComponent(
                      value: coin.value,
                      tileX: coin.x,
                      tileY: coin.y,
                      onCollect: (value) => _collectCoin(_coinId(coin), value),
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
                            coinsFound:
                                widget.life?.townEarnedThisYear ?? _coinsFound,
                            coinsNote: widget.life == null
                                ? null
                                : widget.life!.townAllowanceSpent
                                ? 'this year, fading'
                                : 'this year',
                            today: _today,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const _DemoBadge(),
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
    this.coinsNote,
  });

  final int visitedCount;
  final int totalCount;
  final int coinsFound;

  /// Words after the amount, when it is life money. "this year" is what makes
  /// the number read as an income rather than a score, and "fading" is the
  /// honest thing to say once the year's allowance is spent.
  final String? coinsNote;

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
            Flexible(
              child: Text(
                coinsNote == null ? '$coinsFound' : '$coinsFound $coinsNote',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.numeric(
                  color: const Color(0xFFFFD45C),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
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
            boxShadow: AppTheme.ledgeShadow(spot.kind.accent, restAlpha: 0.35),
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

/// Every town bottom sheet, at its wordiest, for the layout sweep.
///
/// These are private widgets inside a Bonfire screen, and a test cannot drive
/// that screen to the point of opening one (the map needs a real game loop
/// and a map file). They are also exactly where the overflow was reported, so
/// `test/town_sheet_layout_test.dart` builds them through here instead. Each
/// is filled from the real catalogues, picking the longest text in each, so
/// the sweep measures the worst case rather than a convenient one.
@visibleForTesting
Map<String, Widget> debugTownSheets() {
  T longestBy<T>(Iterable<T> items, int Function(T) length) =>
      items.reduce((a, b) => length(b) > length(a) ? b : a);

  final npc = longestBy(
    kTownNpcs,
    (n) => longestBy(n.lines, (l) => l.length).length,
  );
  final line = longestBy(npc.lines, (l) => l.length);
  final mission = longestBy(
    kTownMissions,
    (m) => m.brief.length + m.title.length,
  );
  final action = longestBy(
    kNpcActions,
    (a) => a.detail.length + a.headline.length,
  );
  final unlock = longestBy(kTownUnlocks, (u) => u.why.length);
  final spot = kTownSpots.firstWhere((s) => s.kind == unlock.spotKind);

  return <String, Widget>{
    'neighbor with a mission': _NpcDialogueSheet(
      npc: npc,
      line: line,
      mission: mission,
      progress: 0.5,
      canClaim: true,
      onClaim: () {},
    ),
    'neighbor, no mission': _NpcDialogueSheet(npc: npc, line: line),
    'encounter': _NpcEncounterSheet(npc: npc, action: action),
    'locked building': _LockedSpotSheet(
      spot: spot,
      unlock: unlock,
      progress: 0,
    ),
  };
}

/// The frame every town bottom sheet sits in.
///
/// **The bug this fixes.** Each sheet was a fixed-height `Column` in a plain
/// `showModalBottomSheet`, which caps a sheet at half the screen. The town
/// map locks landscape, so the *normal* case here is a phone about 460
/// logical pixels tall. A neighbor handing out a mission, or a locked
/// building explaining its unlock, ran off the bottom: Flutter painted the
/// yellow overflow stripes across the reward line, and the button below it
/// could not be reached at all.
///
/// So a sheet now takes as much height as it needs up to 88% of the screen,
/// scrolls inside that, and keeps its last row clear of the gesture bar.
class _TownSheet extends StatelessWidget {
  const _TownSheet({required this.child, this.border});

  final Widget child;

  /// The encounter sheet tints its edge by what kind of encounter it is.
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.panelStrong,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
          border: border == null
              ? null
              : Border.all(color: border!, width: 1.5),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NpcDialogueSheet extends StatelessWidget {
  const _NpcDialogueSheet({
    required this.npc,
    required this.line,
    this.mission,
    this.progress = 0,
    this.canClaim = false,
    this.onClaim,
  });

  final TownNpc npc;
  final String line;

  /// A job this person is offering, or has already given you.
  ///
  /// `town_missions.dart` was written and then imported by nothing — 346
  /// lines of orphaned code while these people carried on reciting canned
  /// lines. This is the wiring it never had.
  final TownMission? mission;

  /// How far along that job is, 0..1.
  final double progress;

  final bool canClaim;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    return _TownSheet(
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
          if (mission != null)
            _MissionBlock(
              mission: mission!,
              progress: progress,
              canClaim: canClaim,
              onClaim: onClaim,
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

/// Says this town is not the finished game.
///
/// **Why it exists.** The open world is an early piece of what "BitLife plus
/// more" is meant to become — the Life feed is the polished loop, and the
/// town is where that gets built out next. Nothing on screen said so, which
/// let a small, quiet map read as the finished idea rather than the start of
/// one.
class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'This town is an early demo. More places and things to do are '
          'on the way.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFC857), width: 1.5),
        ),
        child: Text(
          'DEMO',
          // Quicksand, not Pixelify: Pixelify's capitals have confusable pairs
          // at every size (see `caps_legibility_test.dart`), and four letters
          // in all-caps has no lowercase neighbor to disambiguate them by.
          style: AppTheme.caps(
            color: const Color(0xFFFFC857),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
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

/// The side-on walk cycle: all eight columns, in order.
///
/// **Why it skipped frames before, and why it does not now.** The old side
/// rows were never a walk. Columns 0 and 4 had face-on legs on a profile
/// body, 1 and 3 were the same pose, and 5-7 were 1-3 with the leg band
/// flipped, which pointed the shoes backwards. No frame had the legs apart,
/// so the cycle `[1, 2, 3, 5, 6, 7]` shuffled on the spot with the feet
/// flipping direction — reported as the left/right walk "not working".
/// Five in-place patches to those frames each fixed one measurement and left
/// the walk just as broken.
///
/// `tool/redraw_side_walk.py` now draws the side rows from scratch: the body
/// from one frame, identical in all eight, and the legs drawn per frame for
/// a real stride — heel strike, weight, passing, push-off, toe-off, lift,
/// swing, reach — with the other leg half a cycle behind, toes always
/// forward, and feet on one ground line. Every column is a good frame, so
/// every column plays.
const List<int> kSideWalkFrames = <int>[0, 1, 2, 3, 4, 5, 6, 7];

/// Standing still sideways: the passing pose, both feet under the body.
const int kSideIdleFrame = 2;

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

/// A mission, shown under whatever the person just said.
class _MissionBlock extends StatelessWidget {
  const _MissionBlock({
    required this.mission,
    required this.progress,
    required this.canClaim,
    required this.onClaim,
  });

  final TownMission mission;
  final double progress;
  final bool canClaim;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final accent = canClaim ? AppTheme.greenPrimary : const Color(0xFFFFD45C);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canClaim ? Icons.verified_rounded : Icons.flag_rounded,
                size: 17,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.title,
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            canClaim ? mission.onSuccess : mission.brief,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          if (canClaim)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onClaim,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.greenPrimary,
                  foregroundColor: const Color(0xFF06251A),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  'Collect ${mission.rewardGold} gold',
                  style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            Text(
              'Reward: ${mission.rewardGold} gold, '
              '${mission.rewardLiteracy} literacy.',
              style: AppTheme.numeric(
                color: AppTheme.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Something a person does to you, rather than says at you.
///
/// Reported twice: *"the NPCs still just give out dialogue, we want action —
/// like that NPC stealing from you and running away with your money."*
///
/// Two shapes. A pickpocket or somebody handing your wallet back is a thing
/// that **happens** — one button, and the sheet cannot be dismissed, because
/// offering a "decline" on being robbed would be a lie about the moment. A
/// scam or a job offer is a thing you **choose**, and gets two buttons.
class _NpcEncounterSheet extends StatelessWidget {
  const _NpcEncounterSheet({required this.npc, required this.action});

  final TownNpc npc;
  final NpcAction action;

  Color get _accent => switch (action.kind) {
    NpcActionKind.pickpocket => const Color(0xFFFF8474),
    NpcActionKind.scam => const Color(0xFFFFB084),
    NpcActionKind.hustle => AppTheme.greenPrimary,
    NpcActionKind.fairDeal => const Color(0xFF58C7FF),
    NpcActionKind.kindness => const Color(0xFF85EFAC),
  };

  @override
  Widget build(BuildContext context) {
    final choosable = isDeclinable(action.kind);

    return _TownSheet(
      border: _accent.withValues(alpha: 0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            npc.name.toUpperCase(),
            style: AppTheme.caps(
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            action.headline,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.detail,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (choosable)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      action.declineLabel,
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                    child: Text(
                      action.acceptLabel,
                      style: GoogleFonts.pixelifySans(
                        color: const Color(0xFF06251A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: _accent),
                child: Text(
                  action.acceptLabel,
                  style: GoogleFonts.pixelifySans(
                    color: const Color(0xFF06251A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // The lesson, shown before the choice as well as after.
          //
          // A scam you only understand *after* it has taken your money is a
          // punishment; the point is to be recognizable in advance. Naming
          // the tell up front is what makes this teaching rather than a trap.
          Text(
            choosable ? action.outcomeDeclined : action.outcomeAccepted,
            style: AppTheme.numeric(
              color: AppTheme.textMuted,
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A door that wants a lesson first.
///
/// **Why this is a signpost and not a wall.** The Academy used to be a
/// reading section nothing depended on — a player could finish the whole
/// town, every minigame and a dozen lives without opening one lesson. Locking
/// four buildings is the answer to "why would I read that?", but only if the
/// lock says where to go. A door that is simply shut teaches nothing and
/// reads as a bug.
class _LockedSpotSheet extends StatelessWidget {
  const _LockedSpotSheet({
    required this.spot,
    required this.unlock,
    required this.progress,
  });

  final TownSpot spot;
  final TownUnlock unlock;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final accent = spot.kind.accent;
    return _TownSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: FittedLabel(
                  spot.title,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            unlock.why,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Finish ${unlock.unitName} in the Academy',
            style: GoogleFonts.pixelifySans(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% of that unit read',
            style: AppTheme.numeric(
              color: AppTheme.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF06251A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Got it',
                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
