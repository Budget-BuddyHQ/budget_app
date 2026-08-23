# Challenges we went through

A running record of the problems that actually cost time on Budget Buddy —
what broke, what the wrong theory was, and what the fix turned out to be.

This is deliberately different from the error log in `README.md`. That one
is organised by *symptom* so someone hitting the same bug can find it. This
one is organised by *lesson*, for the write-up question "what was hard about
building this?" — the honest answer to which is rarely "writing the code".

Newest first.

---

## 1. A feature-complete app that taught nothing

**The problem, in the owner's words:** *"right now we are just incorporating
many different features but I don't think it's teaching people to learn
budgeting or finance but instead they are just playing the game."*

This was the hardest problem in the project, and it is not a bug. Every
individual feature worked. There was a life sim, an explorable town, an
arcade, a live stock market, a habit tracker, a lesson academy. A player
could spend an hour in the app, enjoy it, and come away having learned
nothing about money.

**Why it happened.** Each feature was built to be *fun first*, and the
teaching was assumed to be implicit — "the stock market teaches investing
because it has stocks in it". It does not. A player pressing Buy and
watching a number move learns the interface, not the idea. The app was
measuring engagement (taps, runs, streaks) and calling it education.

**What we got wrong first.** The initial instinct was to add *more content*
— more quiz questions, more lesson units, more events. That deepens the
Academy, which is the one place players already expect to be taught, and
which they can simply not visit. It does nothing for the 90% of session time
spent in the games.

**What actually worked** was to stop separating "the game" from "the
lesson":

1. **Name the idea at the moment of the decision.** `FinanceConcept`
   (`lib/models_Like_Skins_and_lessons_templates/finance_concepts.dart`) is
   a catalog of sixteen money ideas, each written at two reading levels.
   `LifeChoice.teaches` attaches one to a choice, and the explainer appears
   *after the consequence lands* — while the player still has the decision
   in their head.
2. **Both branches teach.** Picking the worse option is not punished with
   silence; it is the more instructive path, so it surfaces the same
   concept. A test enforces this (`budget_teaching_test.dart`).
3. **Make the player do the thing, not read about it.** The 50/30/20
   budgeting sheet (`_BudgetSheet` in `life_sim_page.dart`) makes the
   player allocate a fixed 100% across needs / wants / savings. The Save
   button is disabled until it totals exactly 100 — that constraint *is*
   the lesson, because it forces the trade-off to be felt rather than
   described.
4. **Give the lesson consequences.** A random expense shock
   (`LifeSimController._maybeFinancialShock`) hits roughly one earning year
   in seven and draws down the emergency fund, then cash, then borrows at
   18%. Saving is otherwise an abstract number that only goes up; the shock
   is what makes a player who budgeted savings feel the difference from one
   who did not.

**The design rule that came out of it:** *if a feature can be enjoyed
without noticing the idea behind it, it is entertainment, not education.*
Adding a lesson screen next to a game does not fix that. Putting the idea
in the path of the decision does.

---

## 2. The walking animation: three wrong theories before the right one

**Symptom:** *"the walking animation is still so goofy and bad"* — reported
across multiple rounds, after two previous "fixes".

**Wrong theory 1 — the sprite is squashed.** An earlier pass found the
player was being drawn into `Vector2.all(32)`, a square, while the sprite
cell is 104x152. That was real and worth fixing (`villagerAspectRatio`), but
the walk still looked wrong afterwards.

**Wrong theory 2 — west and east are the same art.** Looking at the sheet,
rows 2 and 3 appear to face the same direction, which would mean
`enabledFlipX: false` was making the character moonwalk sideways. Checked it
pixel-by-pixel rather than trusting the eye:

```
row2 vs row3, per frame: identical_score=1941178  mirrored_score=0
```

Row 3 is an exact mirror of row 2. The art is correct and `enabledFlipX:
false` is right. **Reading the pixels took two minutes and saved a wrong
"fix" that would have broken a working thing.**

**Wrong theory 3 — the frames are duplicated.** Frames 1 and 3 of each row
are byte-identical, which looked like a packing bug. It is not — that is a
normal 8-frame walk cycle (contact, down, pass, up, ×2).

**The actual causes, both measurable:**

*Cause A — the stride was 2.4x too long.* Bonfire's `Movement.speedDefault`
is 80 units/sec and was never overridden; the animation ran at
`stepTime: 0.12`.

| | speed | stepTime | tiles per footfall |
|---|---|---|---|
| before | 80 | 0.12 | **2.40** |
| after | 60 | 0.07 | **1.05** |

The character is 2.1 tiles tall. Covering 2.4 tiles per footfall means each
foot travels further than the character's whole height per step — textbook
foot-sliding. Speed and frame rate are **one setting, not two**; they have
to be tuned against each other or the feet skate. Fixed via
`kTownWalkSpeed` / `kTownWalkStepTime`.

*Cause B — the legs accordion, and it is unfixable in the current art.* The
head sits at y=2 in every frame while the feet swing between y=137 and
y=152:

```
frame   f0   f1   f2   f3   f4   f5   f6   f7
feetY  137  147  152  147  137  147  152  147
```

The torso is pixel-identical across all 8 frames; only one leg moves, and it
extends *below* the standing foot line. So the head stays nailed in place
while the legs stretch — the character reads as an accordion, not a walker.

A script was written to clamp the foot dip and shift the frames back up,
which would convert leg-stretch into body-bob (a real walk cycle). **It was
written, run, and reverted**, because the cell has only 2px of headroom
above the head and 0 below the feet — lifting the extended frames clipped up
to 6px off the top of the hat. Strictly worse than the bug.

**Status: honestly partial.** The timing fix is in and is the dominant
factor. The accordion is inherent to the art at its current cell size, and
fixing it properly means re-celling every sheet taller (say 104x160) and
re-normalising inside the roomier cell — which changes
`villagerAspectRatio` and therefore how the sprite renders in every avatar
frame and preview across the app. That is a deliberate, separate piece of
work, not something to slip in silently.

**Lesson:** measure before fixing. Two of the three theories were plausible
from looking at the sheet and both were wrong; bounding-box numbers and a
pixel diff settled it in minutes.

---

## 3. The map's "hill" that the player could stand inside

**Symptom:** *"people can still walk on the hill"*.

The town map is a Sprite Fusion export where `collider` is a **per-layer**
boolean, not per-tile. An earlier pass flipped the structural layers
(`walls`, `structures`, …) to `true`, which stopped the player leaving the
map. The wide tan band across map rows 34-37 — the town's southern boundary
— lives in the `terrain` layer, which is `collider: false` because that same
layer also holds walkable dirt paths.

Dumping the collision grid showed the actual shape of the bug:

```
34 #############################TTTTTT#############T#
35 ##TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT#
36 ##TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT#
37 ##################################################
```

(`#` = has collision, `T` = terrain tile with none.)

Rows 34 and 37 were already solid — but row 34 had a **six-tile hole at
x=29..34**, and rows 35-36 had no collision at all. So the player could walk
in through the gap and wander around *inside* the hill, which is exactly
what "walking on the hill" looked like.

**Fix:** moved the rows 34-36 tiles out of `terrain` into a new
`terrain_hill` layer with `"collider": true`, inserted adjacent to `terrain`
so draw order is unchanged. Knock-on: the highest-value coin was sitting at
(27, 36) — now inside a wall — and had to move to (47, 32).

**The guard that matters:** the regression test flood-fills from the spawn
tile rather than checking the band tile-by-tile. A per-tile check would
still pass if a future map edit opened a path *around* the ends of the
band; a reachability check cannot. It also asserts that more than 600 tiles
remain reachable, so the test cannot pass by accidentally walling the player
into a closet.

---

## 4. A visible scrollbar that crashed the whole app, twice, in two different ways

Adding `Scrollbar(thumbVisibility: true)` around two existing horizontal
lists took two failed attempts, and each failed *differently*.

**Attempt 1 — no controller.** Crashed every `DashboardShell` test:

> The PrimaryScrollController is attached to more than one ScrollPosition.

`MainNavigation` keeps all seven tab screens mounted at once in an
`IndexedStack`. Several have their own vertical scroll view with no explicit
controller, so they all attach to the single ambient
`PrimaryScrollController`. A `thumbVisibility` scrollbar with no controller
falls back to that same shared one — which by then has several positions
attached — and `thumbVisibility` requires exactly one.

**Attempt 2 — shadow the ambient controller** with
`PrimaryScrollController.none(...)`. Fixed that crash, caused another:

> A ScrollController is required when Scrollbar.thumbVisibility is true.

With the ambient controller hidden and no explicit one supplied, there was
nothing left to bind to.

**The fix is different per widget, and that is the actual lesson:**

- `order_ticket_page.dart` and the Money Habits category row scroll a plain
  `SingleChildScrollView` that the code itself builds → give it a real
  `ScrollController`, shared with the `Scrollbar`, disposed properly.
- The Money Habits `TabBar` scrolls **`TabBar`'s own internal** scroll view
  when `isScrollable: true`, and Flutter exposes no way to pass a controller
  to it. There is no correct controller to supply → drop `thumbVisibility`
  and use `Scrollbar`'s default notification-based mode, which needs none.

**Rule:** `thumbVisibility: true` needs an explicit `ScrollController`
attached to the *specific* scroll view it should track. Never rely on the
ambient `PrimaryScrollController` inside an `IndexedStack` nav shell, and
check whether the target widget even exposes a controller *before* reaching
for `thumbVisibility`.

---

## 5. A magic `0` that moved under us

Restructuring the bottom nav (Home to the centre) changed what `AppTabIndex`
constants evaluate to. `DashboardShell` defaulted its `initialIndex` to a
bare literal `0` — which had silently meant "Home" and now meant
"Adventure".

Five call sites use that default, including all three sign-in branches, so
**every fresh sign-in landed in the Bonfire game world instead of Home**. It
also made a resize test hang for a full 10-minute timeout, because it was
now booting a game canvas instead of a dashboard.

**Lesson:** when an index or enum constant's *values* change, grep for bare
numeric literals and un-named defaults that encode the old meaning.
`initialIndex = 0` reads as completely innocuous right up until the meaning
of `0` moves.

---

## 6. Keys that worked on desktop and silently did nothing on a phone

*"im not able to log in or use market board"* on a real device.

`readRuntimeEnv()` checked `Platform.environment`, then a local
`supabase.env.json` file. On Android/iOS `Platform.environment` is empty and
the file path resolves against a working directory that is not the project
folder — so **both sources returned null on device**, while a code comment
claimed release builds relied on `--dart-define`. Nothing ever read one.

The subtle part: this fails *silently and correctly*. The app is designed to
degrade to local-only mode without keys, so there is no crash and no error —
the phone build just quietly behaves like a fresh install with no backend.
A failure mode that looks exactly like intended behaviour is much harder to
spot than a crash.

**Fix:** `runtime_env_defines.dart` wraps each key in a literal
`String.fromEnvironment(...)` (a `--dart-define` value only exists at
compile time as a constant, so it cannot be looked up by a runtime string
key), checked before the file fallback. Build with:

```bash
flutter build apk --dart-define-from-file=supabase.env.json
```

---

## 7. Fonts that would not stay consistent (three rounds)

Headings kept rendering in the body font no matter how many were fixed.

**Root cause:** a bare `TextStyle(...)` *merges onto* the ambient
`DefaultTextStyle`, which is the theme's Quicksand `bodyMedium`. So a
heading that sets weight and size but not `fontFamily` silently inherits the
body font. It is not a missing font — it is inheritance doing exactly what
it is documented to do.

Fixed by sweeping every `FontWeight.w900` style across 19 files to
`pixelifySans`. That broke `const` on 30 enclosing widgets
(`invalid_constant`), which needed a second scripted pass walking up to each
enclosing constructor, plus two grandparent cases by hand.

**Lesson:** when the same class of bug survives two fixes, the fix is
addressing symptoms. The third round started by asking *why* the font was
wrong rather than *which widget* was wrong, and that found it in minutes.

---

## 8. Colliders that existed and did nothing

*"The colliders are not implemented yet"* — reported twice, after the map
data had been verified as correct both times.

The map's `collider: true` layers **were** being built into real
`RectangleHitbox`es. The player simply had nothing to collide with:
Bonfire's `SimplePlayer` mixes in `Movement`, `Attackable`, `Vision`,
`PlayerControllerListener` and `MovementByJoystick` — but **not**
`BlockMovementCollision` — and ships with no hitbox at all. Only
`PlatformPlayer` gets the mixin by default; a top-down player has to opt in.

Both earlier investigations checked the map data, found it correct, and
concluded the feature worked. Neither checked the *other half* of a
collision, which takes two participants.

The regression test proves the relationship through the **type system**
rather than an assertion, because constructing a real `TownPlayer` needs
sprite sheets and a running game loop:

```dart
bool _requiresBlockMovement<T extends BlockMovementCollision>() => true;
test('TownPlayer opts into BlockMovementCollision', () {
  expect(_requiresBlockMovement<TownPlayer>(), isTrue);
});
```

Drop the mixin and the file stops compiling — a louder failure than a
failing assertion.

---

## 9. Verifying UI without being able to see it

A persistent constraint rather than a bug: the Browser preview pane is
frequently unavailable in this environment. The page loads, the engine
boots, and then nothing paints:

```
canvases: 0   flt-scene: 0   flt-semantics: 0   document.hidden: true
```

Flutter web stops rasterising when the page is hidden, and the pane is
hidden whenever it is not displayed on the user's side. Overriding
`document.hidden` / `visibilityState` in JS and dispatching
`visibilitychange` does **not** help — the block is that the pane has no
display surface, not that the Page Visibility API says so. Resizing the
viewport does not help either.

One workaround worked once, in an earlier session: clicking
`flt-semantics-placeholder` enables Flutter's semantics tree, giving a
real, navigable widget tree without needing pixels. When the harder variant
above is in play, even that returns an empty tree.

**What we do instead:** lean hard on `flutter analyze` and the widget test
suite — in particular `responsive_layout_test.dart`, which lays out every
screen at eight viewport sizes and fails on *any* thrown exception, not just
overflow. That is why the layout regressions in this document were caught at
all. It is genuinely weaker than looking at the screen, and this file says
so rather than pretending otherwise.

---

## 10. Heredocs and Dart do not mix

A small, repeated time-waster worth recording: writing Dart into a file via
a bash heredoc mangles it. Apostrophes in comments and doc text
(`don't`, `you're`) interact badly with shell quoting and produce
`unexpected EOF while looking for matching quote`.

**Rule:** write Dart with the file-writing tools, never a shell heredoc. If
content has to be appended, write it to a scratch file first and `cat` it
on.
