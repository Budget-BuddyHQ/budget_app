# Adventure Town — systems reference

The RPG half of the app: a walkable 50×50 town where each building is a
money decision. This is the "plus more" in *BitLife plus more* — the Life
sim asks money questions in a scrolling feed, the town asks the **same
shape** of question (`TownChoice` mirrors `LifeChoice`: a label, an outcome
line, stat deltas) except you have to walk there first. Walking is the
game; the decision is the lesson.

Companion docs: `MONEY_HABITS_FEATURE.md` (daily habit tracker),
`ARCHITECTURE.md` §14-17 (narrative history of how this got built).

---

## 1. The collision bug, and why it is worth knowing about

For a while the map had colliders that did nothing and the player walked
straight off the edge of the world into black void. The map data was never
the problem — every structural layer in `map.json` (`walls`,
`Wall Texturing`, `structures`, `structures mre`, `more Structures`,
`Structure Ground`) has `"collider": true`, and Bonfire's
`SpritefusionWorldBuilder` was faithfully turning each of those tiles into a
real `RectangleHitbox`.

**The player was the problem.** Bonfire 3.17's `SimplePlayer` is:

```dart
class Player extends GameComponent
    with Movement, Attackable, Vision, PlayerControllerListener,
         MovementByJoystick { ... }
```

No `BlockMovementCollision`, and no hitbox of its own. In this version only
`PlatformPlayer` and `PlatformEnemy` get the mixin by default — a top-down
player has to opt in. So there were hitboxes all over the map and nothing
that could collide with them.

The fix is `TownPlayer` in `town_components.dart`:

```dart
class TownPlayer extends SimplePlayer with BlockMovementCollision {
  @override
  Future<void> onLoad() {
    add(RectangleHitbox(
      size: Vector2(size.x * 0.55, size.y * 0.35),
      position: Vector2(size.x * 0.225, size.y * 0.6),
    ));
    return super.onLoad();
  }
}
```

The hitbox is deliberately a **"feet" box** — narrow, in the bottom third —
rather than covering the whole sprite, so the character's head can pass in
front of a wall above them the way top-down RPGs expect instead of bumping
a full tile early.

`test/town_map_test.dart` guards this through the *type system*:
`_requiresBlockMovement<TownPlayer>()` only compiles while `TownPlayer` is a
subtype of `BlockMovementCollision`. Drop the mixin and the test file stops
compiling — a louder failure than an assertion.

## 2. Camera and map edges

`CameraConfig.moveOnlyMapArea` is `true`: the camera stops at the map
boundary, so walking to a cliff never reveals empty black space beyond it.

This was **reversed** from `false`. The original reasoning — that a sliver
of void reads as a real world edge — was about a genre convention rather
than this map, where "a sliver" is in practice a large black region with
nothing in it. The player could never leave (the collider ring holds); only
the camera could, and it should not.

The perimeter is verified sealed by test, not by eye: `town_map_test.dart`
walks every `x=0`, `x=49`, `y=0`, `y=49` tile and fails listing any gaps.

**Known map-data quirk, not fixed here:** row `y=37` is solid all the way
across, which seals the bottom strip (`y=38..47`) off from the main area
entirely. That's roughly a fifth of the map the player can never reach. It
looks like the export repeated its border row rather than anything
deliberate — flagged rather than silently edited, because it's the user's
art and "delete some walls" is a design call, not a bug fix.

## 3. Orientation

The whole screen is wrapped in `OrientationScope` locked to
`landscapeLeft`/`landscapeRight` — including the loading and
map-missing states, so there's no rotation jump partway in. `OrientationScope`
restores the app's normal both-orientations behaviour on dispose.

Note this is a **no-op on web by design** (`kIsWeb` early-return inside
`OrientationScope`), so a browser preview will never demonstrate it. Only a
real Android/iOS build can confirm the lock.

## 4. Interactables

| Piece | File | How it works |
| --- | --- | --- |
| Spot data (6 places, prompts, choices) | `models_.../town_spot_models.dart` | `const List<TownSpot> kTownSpots` |
| Coin data (8 pickups) | same file | `const List<...> kTownCoins` |
| Proximity + rendering | `adventure/town_components.dart` | `TownSpotComponent` / `TownCoinComponent`, both `with Sensor<Player>` |
| HUD, sheets, rewards | `adventure/adventure_world_screen.dart` | plain Flutter in a `Stack` over `BonfireWidget` |

**Why `Sensor` and not taps:** walking into a place is the interaction. The
sensor fires `onContact`/`onContactExit`, the screen stores the nearby spot
in state, and a Flutter button appears bottom-right (deliberately opposite
the bottom-left joystick).

**Coins guard against repeat payout.** `Sensor` fires on an *interval*
while overlapping, not once — without the `_taken` flag a single walk-over
would pay repeatedly. The component sets the flag, pays once, then
`removeFromParent()`.

**Every spot and coin sits on a verified-walkable tile.** These coordinates
were picked by reading the collider data, and `town_map_test.dart` asserts
it — a spot placed inside a building would be permanently unreachable and
the objective could never complete, which is exactly the kind of thing that
looks fine in code review and is invisible until someone plays it.

## 5. Rewards

Choices route through `UserStatsController.applyChallengePayload`, the same
generic gold/XP/literacy sink lessons use — no separate economy.

Gold may be **negative** on a spending choice (that's the point of a
purchase). The screen clamps so a purchase can never push the balance below
zero:

```dart
final goldDelta = choice.gold < 0 && currentGold + choice.gold < 0
    ? -currentGold
    : choice.gold;
```

`town_map_test.dart` also asserts no choice is purely punishing — every
option must pay back in at least one of gold/XP/literacy. A choice that
only costs money and teaches nothing is a trap, not a lesson.

## 6. Objective loop

Visiting all 6 spots completes the town. Progress lives in screen state
(`_visited`), shown in the top objective bar and as a tick drawn on each
visited spot's marker, so the map doubles as the checklist. Completion is
currently **per visit** — walking away and coming back starts fresh, the
same way a Life run resets. Persisting it would mean a new `spending_habits`
key; deliberately not done yet.

## 7. Adding a new place

1. Add a `TownSpot` to `kTownSpots` with tile coords on a walkable tile.
2. Run `flutter test test/town_map_test.dart` — it will fail loudly if the
   tile is solid, out of bounds, or the choices are malformed.
3. That's it. The component list, HUD count and objective bar all derive
   from `kTownSpots.length`.

## 8. NPCs

Six townspeople stand around the map. They are deliberately **simpler than
places**: no choices, no stat changes, just a line of money advice. They
exist to make the town feel inhabited and to put an idea in front of you
without demanding a decision.

| Piece | Where |
| --- | --- |
| Data (name, look, tile, dialogue lines) | `kTownNpcs` in `town_spot_models.dart` |
| Component | `TownNpcComponent` in `town_components.dart` — `SimpleNpc with Sensor<Player>` |
| Frames | `assets/map_assets_coins/{tax-guy,customer_more_animations,employee_or_background_character_information}/` |

**The art is one PNG per frame, not a sprite sheet** (102×116 each), so
`_npcIdleAnimation` loads each frame as its own `Sprite` and builds a
`SpriteAnimation.spriteList`, rather than slicing a grid the way the
villager sheets are handled. Every folder had to be registered individually
in `pubspec.yaml` — Flutter does not bundle subfolders recursively.

`SimpleNpc` requires a `SimpleDirectionAnimation`, which requires
`idleRight` and `runRight`. These NPCs stand still, so the same idle loop is
passed for both.

**Dialogue cycles.** `_npcLineIndex` tracks how many times you have talked
to each NPC and advances through their `lines` list, so a second
conversation is not a copy of the first.

**Places beat people.** If a spot and an NPC overlap, the spot's interact
button wins — it is the one carrying the objective.

## 9. Sprite proportions (a bug worth not repeating)

The villager sheet's cell is **104×152** — a tall rectangle. The player was
being sized `Vector2.all(32)` — a square. Every skin was therefore squashed,
which is what made the walk cycle look wrong.

`AppAssets.villagerAspectRatio` (104/152 ≈ 0.684) and
`AppAssets.npcAspectRatio` (102/116 ≈ 0.879) exist so this is stated once
instead of guessed at each call site. **Size height-first, derive width:**

```dart
size: Vector2(34 * AppAssets.villagerAspectRatio, 34)
```

If a new character type is added, do the same — a square `Vector2.all(n)` is
almost always wrong for these sheets.

## 10. Getting in: the town belongs to a life

The town is **not** a standalone mode. Home's hero button starts a Life run
(`/life`); the Life screen's "Explore the town" action opens the map. One
rule: you walk the town *as* the character you are currently living, which
is the point of pairing a life sim with an overworld at all.

`AdventureWorldScreen` itself is still a plain pushed route with no
precondition of its own — the gating is a navigation decision, not an
assertion. If a future entry point pushes it directly, it will work; it just
will not be attached to a life.
