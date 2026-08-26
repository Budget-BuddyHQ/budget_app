# Budget Buddy

A Flutter app that teaches financial literacy through play, for ages 4 to
21+.

## How it teaches (not just what it contains)

The honest failure mode for an app like this is to become a pile of fun
features that quietly teach nothing — you can enjoy a stock-trading screen
for an hour and learn only where the Buy button is. Three mechanisms exist
specifically to stop that, and they are the part worth reviewing first:

1. **Ideas are named at the moment of the decision.**
   `finance_concepts.dart` holds 16 money ideas, each written at two reading
   levels (roughly 4–10, and 11+, picked from the player's own age band —
   not the in-game character's). `LifeChoice.teaches` attaches one to a
   choice, and the explainer appears *after* the consequence lands.
   **Both branches of a money event teach the same idea** — picking the
   worse option is the more instructive path, so it is never met with
   silence.
2. **The player does the budgeting, not reads about it.** The 50/30/20
   sheet in Life makes you allocate a fixed 100% across needs / wants /
   savings, and won't save until it totals exactly 100. That constraint is
   the lesson: every increase is visibly a cut somewhere else.
3. **Saving is given something to be for.** Roughly one earning year in
   seven throws an unavoidable bill, which draws down the emergency fund,
   then cash, then borrows at 18%. The same event is a shrug for a player
   who budgeted savings and a debt spiral for one who didn't.

`docs/CHALLENGES.md` §1 has the full reasoning, including what we tried
first that didn't work.

The app has these pillars:

| Pillar | What it is | Where |
| --- | --- | --- |
| **Life** (main game) | A BitLife-style life simulator. You are born, age up one year at a time, and your choices move Happiness, Health, Smarts, Looks and money. Ends on one of 7 distinct **ending archetypes** (`life_ending.dart`) resolved from your final stats, shown on a dedicated epilogue recap screen instead of the old silent pop-back. | `lib/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart` |
| **Market Board** | A Webull-style stock trading board using **real live market data**, priced in in-game coins. Opens on a "Trending Now" strip of real company logos (Wikimedia Commons — `assets/images/stock_logos/`, ~88KB total across 6 tickers) over the always-on ticker tape. | `lib/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart` |
| **Academy** | Khan-Academy-style units of lessons, quizzes and unit tests — 11 units spanning **ages 4–6 through 21+**, each with its own accent colour. Units badge "Recommended for you" against the player's self-described age band — a signal only, never a lock; every unit still unlocks purely by finishing the previous one's test. **Unit 6 (Stocks and Trading) pays out real gold and tradeable shares**; units 2/3/4 carry a **sourced** question bank citing FICO, SEC/investor.gov and CFPB inline. | `lib/screens_minigames_admin_etc/Gameplay/academy/` |
| **Adventure Town** | A walkable 50×50 RPG overworld (`bonfire`) where 6 buildings are each a money decision, plus coin pickups and a "visit every place" objective. Decisions use the same data shape as Life's, so both halves teach with one grammar. Landscape-locked on mobile. | `lib/screens_minigames_admin_etc/Gameplay/adventure/` — see `docs/ADVENTURE_TOWN.md` |
| **Money Habits** | The daily task: a budgeting-habit tracker (skip eating out, save spare change, wait 24h before a big purchase) with challenges and a savings jar that fills as habits stick. This replaced the old generic "Today's Plan" board on Home. | `lib/screens_minigames_admin_etc/Gameplay/money_habits/` — see `docs/MONEY_HABITS_FEATURE.md` |

Supporting features: auth (login / sign-up / welcome), profile, skins &
customization, leaderboard (global + friends via friend code), arcade
mini-games, in-app feedback
(`lib/screens_minigames_admin_etc/profile/feedback_screen.dart`, toggleable via
`kFeedbackEnabled` in `lib/config/dev_preview_flags.dart`), and an admin page.

**Sound is currently silent on purpose.** `assets/audio/` was emptied to make
room for a new set; `AppSoundService` is unaffected — sound is off by default
and every `play()` already falls back to a system click on a missing asset.
Drop new `.wav`s into `assets/audio/` matching the existing `AppSoundEffect`
names and they play automatically. See `ASSET_WORKFLOW.md`.

**Typography:** headings use `GoogleFonts.pixelifySans` (the "Budget Buddy"
wordmark font); body prose stays `GoogleFonts.quicksand` because pixel fonts
are hard to read in long paragraphs. Note that a bare `TextStyle(...)`
inherits the theme's Quicksand `bodyMedium` — so a new *heading* must set
`pixelifySans` explicitly or it will silently render in the body font. That
exact trap is why the fonts looked inconsistent for three rounds; see
`docs/ARCHITECTURE.md` §17.

---

## Where to start

| Thing | Path |
| --- | --- |
| App entry & routes | `lib/main.dart` |
| Tab shell | `lib/screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart` |
| Home dashboard | `lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart` |
| Backend / data layer | `lib/services_backend_and_other_services/supabase_service.dart` |
| Live market data | `lib/services_backend_and_other_services/market_data_service.dart` |
| Shared user state | `lib/controllers_that_updates_stats/user_stats_controller.dart` |
| Life game rules | `lib/controllers_that_updates_stats/life_sim_controller.dart` |
| **What the app actually teaches, and how** | `lib/models_Like_Skins_and_lessons_templates/finance_concepts.dart` |
| Config / API keys | `tool/README.md` |
| How auth → username → gameplay data → "analytics" fit together | `docs/ARCHITECTURE.md` |
| **The hard problems and what we learned** | `docs/CHALLENGES.md` |
| Adventure Town: collision, interactables, camera, map quirks | `docs/ADVENTURE_TOWN.md` |
| Money Habits: data flow, jar animation, event timing | `docs/MONEY_HABITS_FEATURE.md` |
| Where art/audio goes and how it's wired | `ASSET_WORKFLOW.md` |

Run it:

```bash
flutter pub get && flutter run
```

**Teammates need no API keys.** Everything degrades gracefully — missing Supabase
falls back to local-only mode, missing market keys hide live prices. See
`tool/README.md` for the optional keys.

---

## Project problems we hit (and how we solved them)

### 1. Nobody on the team knew Flutter or Dart

None of us had written Flutter before this year, so we had to learn the framework
and ship at the same time.

**How we overcame it:** each person built a small, self-contained mini-game and
put it in the Arcade tab. That gave everyone a low-risk sandbox to learn widgets,
state and layout in, without being able to break the rest of the app. Most of
those learning-exercise mini-games have since been deleted now that they have
served their purpose.

### 2. We iterated through too many designs

We went back and forth on what the main game should be — a Prodigy-style
learning RPG, a tycoon game, or a Sims-style game with lots of skins — while
under a hard September deadline. We asked AI which direction would be fastest to
build well, and settled on a **hybrid RPG / Sims** game.

**How we overcame it:** committing to one answer and deleting the alternatives.
The main game is now **Life**, a BitLife-style simulator.

### 3. The app lost its sense of direction

Because we were rushing and building Arcade, Academy and a main game
simultaneously, the app started to feel like a shopping mall — lots of things to
do, but nothing that stood out as *the* reason to open it. No single feature was
the main attraction.

**How we overcame it:** we picked one headline feature (**Life**) and
restructured around it — promoting it on the home screen and the Play tab, and
deleting anything that did not serve the new direction. Removed along the way:
Subscription Sweep, Bill Dodger, the open-world adventure map, an abandoned
board-game prototype, and several dead screens. This cut roughly 3,500 lines.

---

## Technical problems

### Layout clipping and overflow (the big recurring one)

Our most frequent bug by far. Content would run off the edge of the screen and
the console would print `A RenderFlex overflowed by N pixels` — the Flutter
equivalent of a website's layout breaking out of its container.

**What we do about it now:**

- **`SingleChildScrollView`** — the single most useful fix. Wrapping a column
  that can grow (or that shrinks on a small phone) lets it scroll instead of
  overflowing.
- **`BoxFit.cover` on backgrounds** — so background art fills the screen at any
  aspect ratio rather than leaving gaps or stretching. Some of our backgrounds
  are deliberately extruded/oversized so there is always enough image to cover.
- **Constraints instead of `width: double.infinity`** — using `BoxConstraints`
  and `Expanded` / `Flexible` means a widget adapts to the space it is given
  rather than demanding a size its parent cannot provide.
- **`Wrap` instead of `Row`** when a row of chips or badges might not fit; it
  moves items onto a second line instead of overflowing.
- **A regression test.** `test/responsive_layout_test.dart` pumps every major
  screen at seven viewport sizes (small phone through tablet, portrait and
  landscape) and **fails the build if anything overflows**. This is what turns
  clipping from a bug we find by accident into one CI catches for us.

---

## Error log

Every bug worth remembering, what caused it, and how it was fixed.

### Data correctness

**Every stock chart had an identical shape**
The card sparklines drew `LiveQuote.miniSeries`, which was
`[previousClose, open, low, high, current]`. Index 2 is *always* the minimum and
index 3 *always* the maximum, so every stock rendered the same dip-then-spike
silhouette regardless of its actual price action.
*Fix:* `miniSeries` now returns only the three points whose order in time is
known (`previousClose → open → current`), and real shape comes from cached
intraday candles via `MarketDataService.seriesFor()`.
*Files:* `market_data_service.dart`, `stock_market_page.dart`

**The P&L graph went up while you were losing money**
`portfolioHistory` was generated by `_nextPortfolioSeries(delta)`, which nudged a
normalised 0–1 number by a fixed amount on every trade (`+0.04` per buy) and
clamped it to `0.16–0.95`. It rose whenever you traded, so the curve climbed
while P&L read −238g.
*Fix:* deleted the synthetic generator. `recordNetWorth()` now appends the real
`cash + market value` after each price refresh, and legacy sub-1.0 values are
filtered out on read.
*Files:* `user_stats_controller.dart`, `stock_market_page.dart`

**Prices did not update live**
*Fix:* the board now polls every 30s (`MarketDataService.livePollInterval`) with
a LIVE badge showing the last update time. The refresh floor dropped 60s → 20s,
which stays inside Finnhub's 60 calls/minute.

**Stock search only matched our 16 hard-coded symbols**
Searching "WDC" or "NVO" returned "No stocks match" even though they are real.
The search filtered an in-memory list.
*Fix:* call Finnhub's free `/api/v1/search`, debounced 350 ms, with a generation
counter so a slow earlier response cannot overwrite a newer one.

**Finnhub historical candles return HTTP 403**
`/stock/candle` was moved behind a paid plan. Verified live.
*Fix:* chart candles come from **Twelve Data** `/time_series` (free, 800/day)
instead. Two different APIs now: Finnhub for quotes + search, Twelve Data for
candles.

**Candles still missing even with a valid key**
Not a code bug: `runtime_env_io.dart` caches the env file on first read, so a key
added while the app is running is not seen until a **full restart** (hot reload
is not enough).

### Crashes

**Market Board crashed at narrow widths**
`Unsupported operation: Infinity or NaN` from inside fl_chart's axis/grid
interval math (upstream issues #1739, #774). No configuration avoids it.
*Fix:* removed fl_chart entirely and replaced it with our own `CustomPainter`
widgets (`MiniSparkline`, `PriceChart`) that map values straight onto the canvas
with no interval solver. 8 regression tests cover NaN, Infinity, empty, single
point, zero width and zero height.

**Profile crashed with no Supabase keys configured** (`Assertion failed: You
must initialize the supabase instance before calling Supabase.instance`)
Four call sites reached into `Supabase.instance.client` directly instead of
through `SupabaseService`'s safe accessors, so on a phone/device with no
`supabase.env.json` — no keys, `Supabase.initialize()` never runs — the very
first thing that touched `Supabase.instance` threw, taking out whichever
screen (or tab, since all tabs mount at once in an `IndexedStack`) hit it
first. Profile hit it on every load; Admin would have hit it the moment its
`State` was constructed, before even reaching its own "not connected" check.
*Fix:* `SupabaseService.currentUser` (already existed, just wasn't used
everywhere) and a new `SupabaseService.client` getter — both return `null`
instead of throwing when Supabase was never initialized, same pattern as
every other accessor in that file. Four call sites switched over:
`profile_screen.dart`, `feedback_screen.dart`, `admin_screen.dart` (also
made its `SupabaseClient` field nullable so a disconnected admin sees "Access
denied" instead of a crash).
*Files:* `supabase_service.dart`, `profile_screen.dart`, `feedback_screen.dart`,
`admin_screen.dart`

**A visible Scrollbar crashed the whole nav shell, twice, in two different ways**
Adding `Scrollbar(thumbVisibility: true, ...)` with no explicit `controller`
around Money Habits' `TabBar` and the order ticket's range-chip row (to make
narrow-width scrolling more discoverable, per request) crashed every
`DashboardShell`-based test: `MainNavigation`'s `IndexedStack` keeps all
seven tab screens mounted at once, several of which have their own vertical
scroll view with no explicit controller — all defaulting to the same ambient
`PrimaryScrollController` for the route. A `thumbVisibility` Scrollbar with
no controller of its own falls back to that same ambient controller, which
already had several `ScrollPosition`s attached from the other tabs, and
`thumbVisibility: true` requires exactly one. *("The PrimaryScrollController
is attached to more than one ScrollPosition.")*
The first fix attempt — `PrimaryScrollController.none(child: Scrollbar(...))`
to shadow the ambient controller — traded that crash for a different one:
`thumbVisibility: true` *requires* a real controller to bind to, and with the
ambient one hidden there was nothing left. *("A ScrollController is required
when Scrollbar.thumbVisibility is true.")*
*Fix (two different, because the two widgets differ):* the order ticket's
scrollable is a plain `SingleChildScrollView` the code already builds, so it
got a real, explicit `ScrollController` (`_rangeScrollController`, disposed
like every other controller on that page) shared by both the `Scrollbar` and
the scroll view. Money Habits' scrollable is `TabBar`'s **internal** scroll
view when `isScrollable: true` — Flutter's `TabBar` does not expose that
controller through any public parameter, so there is no explicit controller
to give it at all. Dropped `thumbVisibility`/`trackVisibility` there and left
`Scrollbar` in its default (notification-based, fades in while dragging)
mode instead, which needs no controller.
*Lesson:* `thumbVisibility: true` needs an explicit `ScrollController`
attached to the *specific* scroll view it should track — never rely on the
ambient `PrimaryScrollController` once more than one tab's own scroll view
can be alive at once (any `IndexedStack`-based nav shell), and check first
whether the target widget even exposes a controller before reaching for
`thumbVisibility`.
*Files:* `order_ticket_page.dart`, `money_habits_screen.dart`

### Gameplay

**Adventure Town progress didn't save, and coins could be farmed for infinite gold**
`_visited` and `_coinsFound` were plain `State` fields on
`AdventureWorldScreen`, never read from or written to `UserStatsController`.
Leaving the screen — even to check Profile — reset "visit every place" to
zero, and every coin reappeared and could be re-collected for real gold
(`_collectCoin` already called `applyChallengePayload({'gold_earned':
value})` with nothing stopping it firing twice for the same coin).
*Fix:* `UserStats.townVisitedSpotIds`/`townCollectedCoinIds` (same
ad-hoc-jsonb pattern as every other saved list in this app) persist both;
the coin-spawning loop now skips any already-collected coin id entirely
rather than spawning and hiding it.
*Files:* `supabase_service.dart`, `adventure_world_screen.dart`

**The walking animation's "accordion legs" — actually fixed this time**
A previous fix (stride length vs. animation frame rate) was real but
partial — the torso stayed frozen across all 8 walk frames while one leg
extended below the standing-foot line by up to 15px. A first attempt to
clamp that dip in place clipped the hat (the cell had only 2px of headroom)
and was reverted.
*Fix:* `tool/normalize_walk_baseline.py` now re-cells every sheet 10px
taller **first** (a pure recentre — cannot clip anything) and *then* clamps
the dip within the new, roomier cell, with an assertion that refuses to run
if the safety margin isn't real. `AppAssets.villagerCellHeight` moved
152→162; every render site already used the named constant, not a literal,
so nothing else needed to change.
*Files:* `tool/normalize_walk_baseline.py` (new), `app_assets.dart`,
`assets/self_made_skins/*.png` (all 22)

**Three real text-truncation bugs, found from an actual screenshot**
"Explore the Town", "Pick a money habit", and "Current Objective" all
truncated to fragments ("Explore th…", etc.) at a genuine ~310px pane
width — narrower than any viewport this app's test suite covers (smallest
tested is 320px). Each was a fixed-size `Text(maxLines: 1, overflow:
ellipsis)` that didn't fit the real available width at that size.
*Fix:* wrapped each in `FittedBox(fit: BoxFit.scaleDown)`, the same pattern
already used successfully elsewhere (`PopNavBar` labels, the leaderboard
wordmark) — scales the whole line down as one unit instead of truncating a
fragment.
*Files:* `home_screen.dart`

**The player could walk around *inside* the hill**
The town map's southern boundary — the wide tan band across map rows 34–37 —
lives in the `terrain` layer, which is `collider: false` because that same
layer also holds walkable dirt paths. Rows 34 and 37 were already solid, but
row 34 had a **six-tile hole at x=29..34** and rows 35–36 had no collision
at all, so the player could step in through the gap and wander around inside
the band.
*Fix:* moved the rows 34–36 tiles into a new `terrain_hill` layer with
`"collider": true`, inserted adjacent to `terrain` so draw order is
unchanged. The highest-value coin was at (27, 36) — now inside a wall — and
moved to (47, 32).
*Guard:* the regression test flood-fills from the spawn tile rather than
checking the band tile-by-tile, because a per-tile check would still pass if
a later map edit opened a route *around* the ends. It also asserts >600
tiles stay reachable, so it can't pass by walling the player into a closet.
*Files:* `assets/images/maps/map.json`, `town_spot_models.dart`,
`test/town_map_test.dart`

**The walking animation looked "goofy" — the feet were sliding 2.4x**
Bonfire's `Movement.speedDefault` (80 units/sec) was never overridden while
the walk ran at `stepTime: 0.12`. Eight frames is two footfalls, so that is
**2.4 tiles of ground per footfall on a 2.1-tile-tall character** — each
foot travelling further than the character's whole height per step, i.e.
textbook moonwalking.
*Fix:* `kTownWalkSpeed` (60) and `kTownWalkStepTime` (0.07) → 1.05 tiles per
footfall. These are one setting, not two, and are documented as such.
*Still partial, and the docs say so:* the art has the torso frozen across
all 8 frames with one leg extending *below* the standing foot line, so the
legs accordion 15px while the head stays pinned. Not fixable by repacking —
the cell has 2px of headroom above the head and 0 below the feet, so lifting
the extended frames clips the hat (tried, measured, reverted). See
`docs/CHALLENGES.md` §2.
*Files:* `adventure_world_screen.dart`, `town_components.dart`

**Finance Brawl's HUD didn't wrap on phone — the exit button covered the balance panel**
The wave/net-worth HUD and the gold/exit controls were two *independently*
`Positioned` widgets: one centred across almost the full screen width, the
other pinned to the right edge with no awareness of the first one's width.
On a phone-width screen the HUD's right-hand panel extended under the
floating gold badge and exit button instead of making room for them, so
"Don't Let it Hit Zero!" rendered clipped behind the coin icon.
*Fix:* merged both into one `Row` sharing one width budget — the HUD panels
`Expanded` to flex, the controls stay fixed-size next to them. One place to
divide the space instead of two independently-guessed ones.
*Files:* `finance_brawl_game.dart`

### Layout

**Bottom-nav restructure silently sent fresh sign-ins into the game world instead of Home**
The bottom nav was rebuilt to 5 tabs with Home centred (Life/Learn/Home/Daily/
Profile), which reassigned `AppTabIndex` — `adventure` became `0`, the slot
`dashboard` (Home) used to occupy. `DashboardShell`'s `initialIndex` defaulted
to a bare literal `0`, so every bare `DashboardShell()` — the `/game` route
and all three sign-in branches in `main.dart` — silently landed on the
Adventure/Bonfire tab instead of Home. Also caused a resize test that used
`DashboardShell()` to hang for a full 10-minute timeout, since it was booting
into the heavier Bonfire `GameWidget` instead of Home.
*Fix:* `DashboardShell`'s default is now the named `AppTabIndex.dashboard`
constant, not a bare `0`.
*Lesson:* when an index/enum constant's values change, grep for every
default parameter or bare literal elsewhere that assumed the old values.
*Files:* `dashboard_shell.dart`, `pop_navbar.dart`, `app_tab_index.dart`,
`main_navigation.dart`, `main.dart`

**Bigger bottom-nav label text overflowed its own bar**
The nav labels were bumped a few px for readability, but the bar's fixed
height wasn't bumped with them — every screen using the bottom nav threw
"overflowed by 3.0 pixels on the bottom."
*Fix:* `barHeight` raised alongside the label size.
*Files:* `pop_navbar.dart`

**Phone UI got cramped and key visuals disappeared**
The dashboard and Academy had separate compact-mode decisions: the bottom nav
only reacted to width, the Academy turtle illustration was removed in compact
layouts, the Current Objective shop/arcade icon was hidden behind `if (!tight)`,
and profile badges used roomy desktop-ish tiles. On phone-shaped windows this
made the UI feel oversized, caused the `Enter World` button to overflow, and
made achievement labels like `Completionist` truncate too aggressively.
*Fix:* compact sizing now considers height, the turtle and shop visuals scale
instead of disappearing, the home hero/CTA and Academy metric pills use tighter
phone spacing, and the badge grid uses denser columns with fixed text bands and
`FittedBox` scaling for long labels/details.
*Files:* `pop_navbar.dart`, `home_screen.dart`, `lesson_screen.dart`,
`profile_screen.dart`, `responsive_layout_test.dart`, `market_resize_test.dart`

**Finance Brawl only accepted keyboard movement**
Movement was built only from `_pressedKeys`, so WASD/arrow keys worked on
desktop but a phone/tablet finger drag did nothing. That made Finance Brawl
technically launch on mobile while being functionally unplayable.
*Fix:* a transparent drag layer over the game canvas now records a normalized
touch movement vector, feeds it into the same movement calculation as keyboard
input, and shows a temporary joystick knob while the finger is down. HUD buttons
and overlays stay above that layer, so exit/quiz/upgrade interactions still win
the hit test.
*Files:* `finance_brawl_game.dart`, `responsive_layout_test.dart`

**Tax lesson existed by title but not as a complete teen-friendly lesson**
Unit 5 had `Taxes and Withholding`, but the Academy lesson content only covered
withholding/refunds at a high level. The pasted lesson introduced the actual
first-job flow — W-4, W-2, Form 1040, payroll taxes, sales/property tax,
marginal vs average rates, credits, deductions, and paycheck/sales-tax
scenarios — but none of that was represented in the Academy.
*Fix:* `lesson_24` now teaches those concepts in the existing lesson-content
system and includes a worked paycheck example. Unit 5 quiz/test coverage now
checks W-4 withholding, Social Security/Medicare payroll taxes, sales tax,
credits vs deductions, and filing for a refund when tax was withheld.
*Files:* `lesson_detail_screen.dart`, `quiz_bank.dart`

**"Enter World" button's icon+label sat left-aligned instead of centered**
The `Row` holding them used `mainAxisSize: MainAxisSize.min` inside a `Stack`
with no explicit `alignment` — `Stack` defaults non-positioned children to
top-*start*, so the shrink-wrapped Row hugged the left edge of the button
instead of sitting in the middle.
*Fix:* `Stack(alignment: Alignment.center, ...)`.
*Files:* `home_screen.dart`

**Arcade game card overflowed once a game had a long length label**
`ArcadeLength.none` ("As much time as you need") is far longer than the
"5–10 min"-style labels the row was built around; the difficulty chip,
length chip, and play icon sat in a plain `Row` with no give, so the long
label pushed the row past its width.
*Fix:* the length chip is now `Flexible` (shrinks + ellipsizes) and
`_MetaChip`'s `Text` got `overflow: TextOverflow.ellipsis` to match — the
same "give the unpredictable-length element room to shrink" fix as most of
the other overflow bugs in this section.
*Files:* `minigames_page.dart`

**Villager sprites bled outside their frame**
A square ancestor's *tight* constraints forced the sprite's aspect-corrected
`SizedBox` to stretch to the full square.
*Fix:* wrap in `Center`, which loosens tight constraints so the child lays out at
its own intrinsic size. Regression test in `test/avatar_sprite_test.dart`.

**Human skins looked distorted in the case-open reel and skin grid**
`AvatarSprite` defaults to a villager's *natural* sheet-cell size (104x152)
when no explicit `size` is given. Three call sites relied on that default
inside boxes far smaller than 104x152 — the 70px-wide case-roll reel item, the
skin inventory grid tile, and `ProfileAvatar`'s sprite fallback — so the
sprite rendered oversized and bled into its neighbours or got clipped by the
surrounding `ClipOval`/reel mask. Turtles/critters looked mostly fine because
their source art happens to be closer to square already, which is why this
went unnoticed for a while.
*Fix:* the case-roll reel now passes an explicit `size` computed from the
item's actual content box (accounting for the villager sheet's aspect ratio);
the skin grid tile and `ProfileAvatar` fallback wrap the sprite in a
`FittedBox` instead, since their box size varies with screen width and isn't
known ahead of time.
*Files:* `customize_screen.dart`, `profile_avatar.dart`

**Home "Play Life" promo card overflowed 130px on narrow phones**
A `Row` holding the title plus a badge.
*Fix:* `Wrap`. Caught by `responsive_layout_test.dart` before shipping.

**Feedback screen header overflowed on the smallest phone width**
The back button + title lived in a plain `Row`; at 320px wide the title text
pushed 53px past the right edge.
*Fix:* wrap the title in `Expanded` with `TextOverflow.ellipsis`. Caught by
`responsive_layout_test.dart` before shipping — the same pattern that's
caught every overflow bug in this table since it was added.

**Arcade game card taglines got silently clipped mid-line**
The grid tile's `mainAxisExtent: 168` was the *exact* sum of every fixed row
plus a full 2-line tagline, with zero slack. Any tagline that actually
wrapped to 2 lines (Market Board's did; Finance Brawl's happened to fit on
one) had its second line clipped by the `Expanded`'s tight height. This one
slipped past `responsive_layout_test.dart` because it isn't a `RenderFlex`
overflow — the flex box itself was never too small, `Text` just painted past
a box that was too short for its own content, which Flutter doesn't warn
about the way it does for `Row`/`Column` overflow.
*Fix:* `mainAxisExtent` bumped to 192 for real margin.
*Files:* `minigames_page.dart`

**Small repeating background icons read as clutter, not decoration**
Home, Arcade and Style each draw a small repeating icon tile
(`home_tile_bg`/`arcade_tile_bg`/`meadow_tile_bg`) as ambient texture behind
their cards, dimmed at only ~0.48–0.55 alpha. In the narrow gaps between
cards there was nothing else covering it, so a crisp, chopped-off sliver of
icons showed through every gap — it read as visual debris, not intentional
texture.
*Fix:* dim bumped to 0.82 alpha on all three screens, so the pattern fades to
a soft wash instead of legible confetti. Academy uses the same tile assets
too, but at `BoxFit.cover` as one large image rather than a tight repeat, so
it never had this problem — that one got a *lighter* vignette instead, to
make the art pop more rather than wash it out further.
*Files:* `home_screen.dart`, `minigames_page.dart`, `customize_screen.dart`

**Adventure world's "map on the way" screen overflowed 56px on short viewports**
Its content sat in a `Column` inside `Center` with no scroll fallback — fine
until the viewport got short enough (568x320 landscape) that the icon, title,
body copy and button no longer fit.
*Fix:* `SingleChildScrollView`. Caught immediately by
`responsive_layout_test.dart` since the new screen was added to its coverage
the same session it was written.

**Skins too large in the Case Opened dialog**
The reveal reel and sprite pushed the action button off-screen.
*Fix:* reel items 92→70px, reel height 188→140, revealed sprite 132→100.

**Profile picture off-centre**
Three screens each had their own avatar implementation, each subtly different.
*Fix:* one shared `ProfileAvatar` widget — photos centre-cropped with
`BoxFit.cover`, sprite fallback inset and centred so it is never clipped.

### Logic

**Input fields drew two borders — `InputBorder.none` isn't enough**
The order ticket's `_StepperField` wraps a `TextField` in its own bordered
`Container` and set `border: InputBorder.none` to suppress the field's own
outline. But `InputDecoration.border` is only the *fallback*: the app theme
(`app_theme.dart`) also sets `enabledBorder`, `focusedBorder` and
`errorBorder`, and those still painted — so every price/quantity box showed
a second 1.5px outline nested inside the container's.
*Fix:* clear all six border slots (`enabled`/`focused`/`error`/
`focusedError`/`disabled` as well as `border`) plus `filled: false`, since
the theme also sets a fill.
*Files:* `order_ticket_page.dart`

**Nested cards stacked two rounded outlines**
`_MiniPriceCard` carried its own border while always being rendered inside
an already-bordered `_StockCard`/holdings row, so the mini chart appeared to
have a double frame.
*Fix:* dropped the inner border and kept only the fill.
*Files:* `stock_market_page.dart`

**The Market Board "broke" below 450px — because the window minimum said so**
`WindowOptions.minimumSize` was `450x400`. Forcing the Windows window
narrower than its declared minimum doesn't make Flutter reflow — the
framework keeps laying out for the minimum and the surplus is clipped, so
content ran off the right edge with **no overflow error anywhere**, which is
why three rounds of layout tests all came back clean. Every screen is
layout-tested down to 320x568, so the floor was simply set higher than the
sizes people actually drag to.
*Fix:* `minimumSize` lowered to `340x480`.
*Lesson:* "content is cut off" with zero overflow errors points at the
window/viewport, not the widget tree.
*Files:* `main.dart`

**The layout sweep only ever tested one of the Market Board's five tabs**
`TabBarView` builds its children lazily, so pumping `StockMarketPage` in
`responsive_layout_test.dart` rendered **Assets** and nothing else. Trade,
Orders, P&L and Analytics — including the most complex cards in the app —
were never laid out by any test, while the suite reported the screen clean.
*Fix:* a dedicated `Market Board tabs` group taps through all five tabs at
all seven viewports (35 cases).
*Files:* `test/responsive_layout_test.dart`

**The layout sweep never exercised the charted trade cards**
`seedQuotesForTest` seeded `_quotes` but not `_series`, so `seriesFor`
returned the short quote-derived fallback, `_MiniPriceCard` short-circuited
to "No chart data yet", and the entire charted branch of the trade cards was
invisible to `responsive_layout_test.dart` — the test reported Market Board
as clean without ever laying out its most complex widget.
*Fix:* the seed now also populates a 24-point intraday series per symbol.
*Files:* `market_data_service.dart`

**`extendBodyBehindAppBar` pushed the Market Board's content under its own title**
Giving the board a full-bleed green backdrop was done by setting
`extendBodyBehindAppBar: true` and painting the art inside the body `Stack`,
with `SafeArea(top: false)` on the content. That put the tab content at
y=0 — so the ticker tape overlapped the "Market Board" title and the
trending strip overlapped the tab row.
*Fix:* the backdrop moved *outside* the Scaffold — `Stack(children: [art,
Scaffold(backgroundColor: transparent, ...)])`. Same full-bleed result, but
the Scaffold lays out normally so nothing can collide with the AppBar. The
order ticket now uses the same pattern rather than repeating the mistake.
*Files:* `stock_market_page.dart`, `order_ticket_page.dart`

**The 1D/5D/1M/3M/1Y chart ranges did nothing**
`MarketDataService.fetchCandles` returns an empty list whenever no Twelve
Data key is configured, so every range produced the identical quote-derived
3-point fallback — five buttons that visibly did nothing when pressed.
*Fix:* the range chips now read `MarketDataService.hasCandleKey` and render
disabled when history isn't available, alongside the existing "Add a
TWELVE_DATA_API_KEY…" note. Deliberately *not* fixed by synthesising
plausible history — inventing price data in an app that teaches investing
would be worse than an honest disabled state.
*Files:* `order_ticket_page.dart`

**Every cloud save silently failed after mirroring age/gender**
`UserStats.toStorageMap()` started writing `'age'` and `'gender'` keys to
mirror columns that had been added in the Supabase dashboard. But those
columns were on **`profiles`** (the table carrying `disabled` and
`profiles_id_fkey`), not `user_stats` — so every upsert came back
`PostgrestException: Could not find the 'age' column of 'user_stats' in the
schema cache`, and the service's own catch-all quietly fell through to
"keeping cached data". Progress looked fine in-app and stopped reaching the
backend entirely. Only visible in the console.
*Fix:* removed both keys. Nothing depended on them — the app reads the
bucketed `AgeBand`/`GenderIdentity` from `spending_habits`, and the mirror
was only ever for human readability in the table editor. If it's wanted
again it has to be a separate write to `profiles`.
*Lesson:* a `try/catch` that degrades gracefully will also hide a schema
mismatch forever. Worth checking the console after any change to
`toStorageMap`.
*Files:* `supabase_service.dart`

**Two allocation slices drew in the identical colour**
Cash was hardcoded `0xFFE1BB72` and AAPL's accent in `_kSymbolStyle` is
*also* `0xFFE1BB72`, so a portfolio holding both drew two "different" donut
slices in exactly the same colour and the legend became unreadable. Three
more collisions sit in the symbol palette too (MSFT/PYPL, SPY/MCD,
NFLX/AMD).
*Fix:* rather than hand-editing the palette (which would silently re-collide
the next time a symbol is added), the chart now de-duplicates at render
time — any repeat colour is reassigned to the next unused entry from a
dedicated 10-colour chart palette, falling back to a hue rotation if a
portfolio ever has more slices than the palette.
*Files:* `stock_market_page.dart`

**Password reset sent the email but could never change a password**
The half of the flow the app owned worked — the captcha token was attached
(that fix is above) and Supabase sent the recovery email. But nothing
downstream existed: `resetPasswordForEmail` passed no `redirectTo`, there
was **no `auth.updateUser` call anywhere in `lib/`**, no screen to type a new
password into, and no listener for `AuthChangeEvent.passwordRecovery`. So
tapping the emailed link signed you in on a recovery session, the auth gate
in `main.dart` treated that like any normal sign-in and dropped you on the
dashboard — password unchanged, no way to change it.
*Fix:* added `SupabaseService.updatePassword()` (the missing
`auth.updateUser(UserAttributes(password:))`), a `SetNewPasswordScreen`, a
`passwordRecovery` branch in the auth gate that shows it, and a
`passwordResetRedirectUrl` constant wired into `resetPasswordForEmail`.
*Still needs configuring by hand:* that redirect URL must be allowlisted in
Supabase → Authentication → URL Configuration → Redirect URLs, and mobile
needs the `budgetbuddy://` scheme declared natively (Android intent-filter /
iOS `CFBundleURLTypes`) before the OS hands the link back to the app.
*Files:* `supabase_service.dart`, `user_stats_controller.dart`,
`set_new_password_screen.dart`, `main.dart`

**Two named routes would have stranded the player with no bottom nav**
`/main-gameplay` and `/minigames` built `MainGamePage()`/`MinigamesPage()`
directly with no `onNavSelected`, which makes those screens render their
`bottomNavigationBar` as null — a tab screen you cannot navigate out of.
Latent rather than live (nothing pushed them by name; only `/life` is
actually used), but a trap for the next person who wires a button to one.
*Fix:* both now route through `DashboardShell(initialIndex: ...)` like
`/dashboard` and `/customize` already did. `/life` deliberately stays
full-screen — it's a game with its own exit, not a tab.
*Files:* `main.dart`

**The feedback prompt could never fire without Supabase keys**
The occasional prompt was gated on `stats.hasCompletedPersonalDetails`, the
flag set by finishing the age/gender onboarding sheet — a sensible-looking
"don't ask before they've onboarded" rule. But that sheet only shows when
`controller.isAuthenticated` is true (`main_navigation.dart`), which is
false in local-only mode, so the flag was never written and the prompt was
**unreachable** on any device without `supabase.env.json`. Same shape as the
Profile crash above: a feature silently dead in the exact configuration most
people run locally.
*Fix:* replaced the gate with a persisted launch counter in
`AppSettingsController` — "they've opened the app at least 3 times" means
the same thing ("not brand new"), works identically with or without
Supabase, and keeps the 4-day cooldown on top.
*Files:* `app_settings_controller.dart`, `home_screen.dart`

**Arcade header claimed "Five ways to practise money" with two games active**
The subtitle was a hardcoded string written when the catalog had 5 entries;
`activeArcadeGameIds` was later trimmed to 2 (`finance_brawl`, `market_board`)
without touching the copy.
*Fix:* `'${arcadeCatalog.length} ways...'`, driven by the actual catalog.
*Files:* `minigames_page.dart`

**Limit orders were rejected instead of resting**
A buy limit *below* the ask was blocked with "this order would not fill" — which
is backwards, since waiting for the price to come down is the entire point of a
limit order.
*Fix:* non-marketable limits now rest as **working orders** and fill when the
market crosses them. Sell orders reserve their shares up front so the same shares
cannot be double-sold; cancelling returns the reservation. 6 tests.

**Coin/USD confusion**
Coins were 1:1 with dollars, which made in-game currency feel meaningless.
*Fix:* `kCoinsPerDollar = 10`, and every money value now shows coins **and** the
real-money equivalent. Because a share then costs thousands of coins, fractional
shares shipped with it (`holdings` became `Map<String, double>`).
*Gotcha:* Dart does not implicitly convert a non-literal `int` to `double`, so
every `holdings[...] ?? 0` had to become `?? 0.0`.

**Buy price equalled sell price (free-XP exploit)**
Buying and selling the same lot back to back was a free, infinite source of gold.
*Fix:* a bid-ask spread that widens with the day's volatility, so a round trip
always costs something — the same way a real spread does.

**Academy node tiles were repetitive**
Every lesson node used one of only two tile images.
*Fix:* a curated 12-tile pool seeded by `unitIndex + index * 5`, so adjacent
nodes differ and the sequence shifts between units.

**Quiz answer-key bias**
Early quiz content skewed toward `correctIndex: 0` — a player could clear a
quiz by always tapping the first option.
*Fix:* rebalanced every question bank by hand so the correct answer is spread
roughly evenly across all four positions in `quiz_bank.dart`, guarded by
`answerKeyIsBalanced` and a test that fails if any single position holds more
than 40% of the answers. Options are not shuffled at runtime — the fix
is in the authored data, not the widget.

**Finance Brawl's daily-plan icon was a courtroom gavel**
`DailyQuest`'s arcade icon map used `Icons.gavel_rounded` for Finance Brawl —
a placeholder that never matched what the game actually is.
*Fix:* arcade quests can now carry an optional `spriteMotif` alongside the
Material icon fallback; Finance Brawl uses the existing animated turtle
mascot (`AmbientMotif.turtle`) instead. Other quest types are untouched.
*Files:* `daily_quest.dart`, `daily_plan_card.dart`

**Subscription Sweep: starting subscriptions could never be cancelled**
The game shipped with subscriptions the player was structurally unable to remove.
*Fix:* corrected the cancel path. (Game later deleted for other reasons.)

**The side walk snapped front-on twice per cycle**
Columns 0 and 4 of the west/east sprite rows were drawn with front-facing legs
-- two leg columns with a gap between them -- on an otherwise profile body, so
the character flipped face-on and back twice per stride. `idleLeft` loaded
column 0, so standing still facing west held the bad pose indefinitely. Three
previous audits passed because they all measured the *cycle* (legs alternate,
halves mirror, feet planted), and the cycle was fine; the fault was in two
individual frames.
*Fix:* three pixel redraws were prototyped and all three made the art worse
(merged legs too chunky, single leg off-centre, re-centred leg outside the
torso), so none shipped. Instead `kSideWalkFrames = [1, 2, 3, 5, 6, 7]` and
`kSideIdleFrame = 1` skip the bad columns entirely; `_loadRowFrames` builds the
animation from an explicit column list because `createAnimation` only takes a
contiguous range. A real fix needs a pixel artist.
*Files:* `adventure_world_screen.dart`, `town_map_test.dart`

**The budget ran silently on every year it worked**
`_applyBudget()` only wrote to the life feed to report a needs shortfall or debt
interest, so a year where the budget went fine produced no money line at all.
The one mechanic the game exists to teach was invisible on exactly the years it
succeeded.
*Fix:* every working year now writes a paycheck line naming all three slices,
or, before a budget is chosen, says it is running the 50/30/20 default and
points at the menu.
*Files:* `life_sim_controller.dart`, `budget_teaching_test.dart`

**A `Spacer` between two rigid labels overflowed by 9.8px at 288 wide**
`Spacer` is `Expanded`, so it is a flex child and competes with any `Flexible`
siblings for the same free space -- protecting the labels with `Flexible` makes
it worse, not better, because the free space is then split three ways.
*Fix:* `Expanded` on the label allowed to give way, a fixed `SizedBox` gap, and
the figure that must stay readable left rigid. Caught by a new layout test
before it shipped.
*Files:* `life_money_panel.dart`, `life_money_panel_test.dart`

**Most simulated players never got a job, so budgeting never switched on**
Only 8 of ~130 events could set a job, each behind its own gate and behind the
player picking one specific branch. Simulated runs showed three of four seeds
reaching age 40 still listed as "Newborn" on zero salary — and with no salary
`canBudget` is false, so the budget split, emergency fund, paycheck line and
debt model were all unreachable. Every test passed throughout, because every
budgeting test used the `startSalary` constructor hook to skip past the broken
part.
*Fix:* a `findJob()` action in the Career menu, with Smarts widening the list
of open roles. The first salary table (900-3000/yr) was 5x the game's economy
and removed all tension — rescaled to 240-560, below what the career-ladder
events award.
*Files:* `life_sim_controller.dart`, `life_sim_page.dart`, `budget_teaching_test.dart`

**The responsive sweep had been measuring the wrong screen for months**
`LifeSimPage` pushes character creation in a post-frame callback, so pumping it
at eight viewports only ever measured the creation screen. The feed — money
panel, stat meters, event card, chain chips — had no viewport coverage while
the report said it had eight viewports' worth.
*Fix:* a `debugInitialLife` seam that skips creation. It immediately found two
real 320px overflows: the bottom menu bar (five rigid children with
`spaceEvenly`, which distributes leftover space and does nothing when there is
none) and the header inside `AppBar.title`.
*Files:* `life_sim_page.dart`, `responsive_layout_test.dart`

**A four-step storyline was unreachable across 2,000 simulated lives**
Chain events have to win a weighted roll against ~120 standalone events once
per beat, so `chain_index_payoff` — the payoff for holding an index fund
through a crash — never fired.
*Fix:* `_openChainBoost`, a 4x draw multiplier for any event with an unmet
prerequisite already satisfied, applied in the draw rather than baked into each
event's weight so future chains inherit it.
*Files:* `life_sim_controller.dart`, `life_chains_test.dart`

**The most-repeated line in the game was the one that never varied**
About a quarter of years draw no event by design, and every one of them printed
"Turned N. A quiet year." — so a run read as repetitive even when its events
were not.
*Fix:* `_quietYearLine()`, age-banded so the filler suits the life stage.
*Files:* `life_sim_controller.dart`

**Pinch and drag on the price chart lost a gesture-arena fight, three times**
The order ticket already used `InteractivePriceChart` and its +/- buttons worked,
but the pinch and pan were driven by a `ScaleGestureRecognizer`, which accepts
pointers in any direction and therefore competes with the enclosing vertical
`ListView` for every gesture. The list wins. So the feature existed, the maths
was right, and it was unreachable by the input anyone would actually try. The
Market Board's other three charts used the plain `PriceChart` and were not
interactive at all.
*Fix:* rewrote the wrapper around a `HorizontalDragGestureRecognizer` (never
competes with a vertical list) that scrubs at 1x and pans when zoomed, plus a
`ScaleGestureRecognizer` that ignores single-pointer gestures so it only claims
real pinches. Added pan arrows for mouse users, and wired the wrapper into all
three remaining charts.
*Files:* `price_chart.dart`, `stock_market_page.dart`, `order_ticket_page.dart`,
`price_chart_interaction_test.dart`

**The chart's 52px label gutter was hardcoded in two places**
`_PriceChartPainter` reserves 52px on the right for price labels, and the Market
Board kept its own copy of that number to map a pointer x onto a candle index.
*Fix:* `PriceChart.axisGutter` is public and both sides read it. The
pointer-to-index maths moved into the chart, which is also the only place that
can translate a zoomed window back into whole-series coordinates.
*Files:* `price_chart.dart`, `stock_market_page.dart`

**Company news could show the same story twelve times**
Results were sorted newest-first and capped at 12, with a comment noting that
the 14-day window returns wire-service reprints — but nothing de-duplicated
them, so one story carried by a dozen outlets could fill the panel and hide
everything else.
*Fix:* de-duplicate on a normalised headline (lowercased, punctuation stripped,
whitespace collapsed) before capping. Reprints differ only in casing and
trailing attribution, so this catches them without comparing article bodies.
*Files:* `market_data_service.dart`

**Password reset was complete in code and dead on device**
`passwordResetRedirectUrl` is `budgetbuddy://password-reset` on mobile, and the
scheme was declared nowhere — no intent-filter in AndroidManifest.xml, no
CFBundleURLTypes in Info.plist. The OS had no idea which app owned the link, so
tapping it in a mail client did nothing and the reset dead-ended silently on a
path that looked finished in the code.
*Fix:* declared the scheme on both platforms. Note this needs a third piece
that is not in the repo — the same URL allowlisted under Authentication -> URL
Configuration -> Redirect URLs in the Supabase dashboard, or Supabase quietly
substitutes the Site URL and the app never receives the recovery session.
*Files:* `AndroidManifest.xml`, `Info.plist`

**The scrub dot showed no price, unlike every real trading app**
The crosshair drew a vertical line and a dot — position information only. It
answered "which bar am I on" and never "what price is that", which is the only
question anyone scrubs a chart to ask.
*Fix:* a dashed two-axis crosshair, a haloed marker, a price tag pinned to the
axis gutter, and a card with the value, the move since that bar opened, and the
timestamp. The card flips to the other side of the crosshair near the right
edge (where the newest bars are), and the timestamp trims itself to what varies
in the series — date for a yearly range, clock time for an intraday one.
*Files:* `price_chart.dart`, `price_chart_interaction_test.dart`

**One company wore five different faces on the same screen**
`_logoAssetFor` existed and only the trending promo strip ever called it, so
Apple was the Apple mark on one card and a generic phone glyph in the search
results, ticker tape, stock card, holdings list and order-ticket header.
*Fix:* extracted `SymbolBadge` into `widgets_custom_lotties/` and used it
everywhere a ticker appears. Logos sit on a white plate — several of these
marks are solid black and would vanish against the app's dark panels.
*Files:* `symbol_badge.dart`, `stock_market_page.dart`, `order_ticket_page.dart`

**The pixel-village backdrop was competing with the prices**
Both Market Board screens scrim the village art at 0.62/0.66 alpha, which left
it clearly legible — so every price, label and chart line fought a busy tiled
illustration for attention, on a screen whose entire point is numbers.
*Fix:* raised the scrim to 0.88. Still recognisably the village, no longer
reading as content.
*Files:* `stock_market_page.dart`, `order_ticket_page.dart`

**Panning could not reach yesterday, and the range strip stopped at 1Y**
An intraday series only holds one session's bars, so "show me older prices" is
a range question, not a pan question.
*Fix:* added 6M and 5Y ranges.
*Files:* `market_data_service.dart`

**A nine-slice panel narrower than its own corners crashes the frame**
The Tiny Swords UI pack is authored on a 64px grid, so its bar art carries 128px
of end caps. Flutter subtracts a `centerSlice`'s caps from the destination before
fitting and a negative remainder *throws* rather than clipping — and the Finance
Brawl HUD gives its panels about 119px on a phone, so that bar was
mathematically unable to render there. The layout sweep caught it as
"centerSlice was used with a BoxFit that does not guarantee that the image is
fully visible", which reads like a fit problem and is not one.
*Fix:* downscale the pack on the way out (bars 0.25, panels/buttons 0.5) so the
caps shrink with it, slicing at full resolution *first* so the piece boundaries
stay on the 64px grid; plus a `_NineSlice` guard that falls back to a rounded
rect below the cap limit, since these are shared widgets and any caller with a
tight `Expanded` can hit it.
*Files:* `tool/build_ui_pack.py`, `pixel_kit.dart`, `app_assets.dart`,
`pixel_kit_test.dart`

**Money Habits lost the gap under Today's Challenge once you saved a habit**
The `SizedBox(height: 16)` lived inside the `if (habits.savedHabits.isEmpty)`
branch, so it disappeared the moment the player pinned their first habit and the
challenge card welded itself to the stats row.
*Fix:* moved the spacing out of the conditional. Spacing between two siblings
belongs between them, not inside a branch that happens to sit in the middle.
*Files:* `money_habits_screen.dart`

**Finance Brawl hid the progress the player needs to see**
`_HudStatPanel` dropped its `detail` line below 150px width — and that line is
"Debts Paid 3/12", the count telling you how far you are from the next upgrade.
So it vanished on exactly the phones where the HUD is tightest (wave 1 showed
nothing, wave 2 did).
*Fix:* a `PixelProgressBar` plus a compact `3 / 12`, kept at every width. A new
`HudProgress` type lets the panel distinguish a flavour line ("Don't Let it Hit
Zero!") from a progress line — only the second is information, and only the
second has to survive a narrow screen.
*Files:* `finance_brawl_game.dart`

**A three-year-old could study, go to the gym, and buy index funds**
Age rules lived in the Life sim's *menu builder*, which is a view, so each
option's gate was whatever that call site happened to remember — and five of
them remembered nothing. The section was commented "Always-available
activities". At age 3 the menu offered Hit the books, Go to the gym, Visit the
library alone, Go out (free while young) and Invest 100 coins.
*Fix:* a `LifeAction` enum plus `LifeSimController.gateFor`, one table in the
controller. Every action method guards on `allows(...)` so the rule holds no
matter who calls, and the menu asks the controller what to grey out. Seeing a
doctor deliberately has no age floor — a parent takes a small child. An existing
test failed correctly: a helper named `_adult()` was 15 and was investing.
*Files:* `life_sim_controller.dart`, `life_sim_models.dart`, `life_sim_page.dart`,
`life_age_gates_test.dart`

**The Brawl progress bar rendered as a brown stick — three separate causes**
1. *Transparent padding.* Flutter fits an image to its **file** bounds, not the
   art inside them. `bar_fill_green` was a 64x64 file holding 24 rows of colour,
   so a 6px-tall box painted a 2px hairline; `bar_base` was 48 wide with art
   only from x=7 to x=41, so the track never reached its widget's edges.
2. *Slice rects escaping the image.* Trimming the padding pushed a full-height
   strip's slice `top` negative (ribbons −7, small bar −3), and Flutter asserts
   on a centerSlice not contained by the image.
3. *Caps equal to the destination.* The guard used `<` where it needed `<=` — a
   destination exactly equal to the caps leaves zero stretchable middle and
   fails like a negative one. A 52px button drawn from art with 52px of vertical
   caps asserted even after the guard existed.
*Fix:* trim to bbox and move the slice with it, clamp the rect back inside
afterwards, use `<=` in the guard, and emit button art at 0.25 scale so its caps
fit a real button. Slices and source sizes are now per-asset (the trim makes
every output a different size with non-symmetric caps) and the generator prints
them ready to paste.
*Files:* `tool/build_ui_pack.py`, `app_assets.dart`, `pixel_kit.dart`,
`pixel_kit_test.dart`

**The side-facing villager was 90px wide against a 100px front view**
Measured rather than guessed: the profile's *head* was wider than the front
view's (85 vs 70), which is anatomically backwards, and the torso only 7%
narrower face-on. Five earlier rounds had all examined the walk *cycle* — frame
timing, leg alternation, which frames were front-facing — and the cycle was
never the problem.
*Fix:* `tool/narrow_side_profile.py` deletes columns from the interior of each
row's widest flat run (the middle of the hair slab, the middle of the coat) and
slides the remainder across, so both edges survive exactly as drawn. The shift
must be **uniform** — a first version cut per row and the coat's back came out
as a staircase. A nose and an eye are added on top, since a narrower blob is
still a blob. Profile is now 71px wide. Colours are recovered from each sheet
rather than hardcoded, because all 22 sheets are palette swaps.
*Files:* `tool/narrow_side_profile.py`, `assets/self_made_skins/*.png`

### Process / tooling

**`responsive_layout_test.dart` silently failed to compile**
It imported `subscription_sweep.dart` long after that file was deleted, so the
whole suite skipped it.
*Fix:* removed the dead import. Lesson: a test that does not compile is not a
test that passes.

**Deleting "unused" service methods broke the build**
A grep for unused methods excluded the file being searched, so methods only
called *internally* looked dead.
*Fix:* always check for internal callers before deleting. (`clearCachedUserStats`
survived this way.)

**Tests broke when game defaults changed**
Life's starting age/money changed from 15/200 to 0/0 (proper BitLife birth) and
tests asserting the defaults failed.
*Fix:* tests now pass starting values explicitly and assert *behaviour* rather
than defaults.

**Market Board's ticker tape and trending strip were never actually tested**
`MarketDataService.quotes` only populates from a real live-price fetch, which
never completes in a widget test — so `responsive_layout_test.dart`'s "Market
Board" case was silently exercising an empty board the whole time. The
`if (quotes.isNotEmpty)` branch holding the ticker tape (and, this session,
the new trending-stocks strip) had zero layout coverage despite the test
"passing".
*Fix:* added `MarketDataService.seedQuotesForTest()` (`@visibleForTesting`)
and seeded a handful of fake quotes in the test wrapper, so that branch
actually renders during the sweep now.
*Files:* `market_data_service.dart`, `test/responsive_layout_test.dart`

**Age-band UI was untestable, so the age warning shipped unverified at first**
`UserStatsController`'s only path to setting an age band is
`updatePersonalDetails()`, which goes through a full save round-trip. A widget
test can't complete that, so every branch keyed on the player's age band —
the "Recommended for you" badge, the new "older than you" warning, the
age-scaled worked examples — rendered as if nobody had ever set an age.
*Fix:* added `UserStatsController.seedStatsForTest()` (`@visibleForTesting`),
mirroring the existing `seedQuotesForTest` seam, and
`test/academy_age_warning_test.dart` now renders the Academy as a 12-year-old,
an adult, and an undisclosed player.
*Files:* `user_stats_controller.dart`, `test/academy_age_warning_test.dart`

**The age warning fired on adults**
The first version compared a unit's `AgeStage` against `AgeBand.recommendedStage`,
which is derived from `representativeAge` — 19 for the open-ended "18 or older"
band. That put the 21+ retirement unit "above" every adult, so a 30-year-old
was told the 401(k) lesson was written for people older than them.
*Fix:* warnings now use `AgeBand.maxPlausibleStage` (the *top* of the band, and
`AgeStage.adult` for the open-ended one) while the "For you" badge keeps using
`recommendedStage`. Caught by the widget test above, which is exactly why it
was worth adding the seam first.
*Files:* `player_profile.dart`, `lesson_screen.dart`

**The lesson graph had no integrity check at all**
Prerequisites are plain strings. A typo doesn't throw — it silently makes a
lesson permanently locked, which nobody would notice until a player got stuck
partway through a unit.
*Fix:* `test/lesson_data_test.dart` now asserts that every prerequisite id
resolves to a real lesson, ids are unique, each lesson is filed under the unit
it claims, and each unit opens off the previous one.

**Life got repetitive after about age thirty — measured, not guessed**
The complaint was that runs felt samey past a point. Simulating 400 full lives
found three causes at once: `_drawEvent()` had **no memory**, so the same beat
could fire repeatedly (`phone_breaks` and `crypto_tip` each landed eight times
in a single life, and 24 of the ~40 events in an average run were reruns); the
eligible pool sat **flat at ~19 events from age 32 to 85**, so half a
playthrough drew from one small set; and three events had never fired in any
run at all.
*Fix:* `LifeEvent.repeatable` (default false) plus a six-year cooldown on the
ones that genuinely recur; 27 new adult/senior events, taking the 40+ pool from
19 to 31. Average repeats per life fell 24.4 → 9.8.
*Files:* `life_sim_models.dart`, `life_sim_controller.dart`,
`test/life_variety_test.dart`

**The music career ladder was mathematically impossible**
`first_gig` granted 4 fame, `record_deal` required 10, and no other event
produced music fame — so the top three events on that track could never fire
for anybody. `sold_out_tour` needed fame 35 against a reachable ceiling of 30.
The simulation above is what exposed it; no amount of playtesting would
reliably have.
*Fix:* first_gig now grants 12, and the two ceilings dropped to reachable
values. A test plays 120 lives as a committed musician and asserts the whole
ladder completes.

**A test suite that reported clean while screens were crashing**
`responsive_layout_test.dart` collected every exception and then filtered to
messages containing `overflowed by`, discarding the rest. A screen could fail
to lay out entirely and the sweep still passed.
*Fix:* it asserts on all exceptions now. That immediately surfaced seven real
failures — see the two below, both of which had been shipping.
*Files:* `test/responsive_layout_test.dart`

**Market Board: `Null check operator used on a null value` when narrowing the window**
`_StockCard` built its header pre-wrapped in `Expanded`, then used it in a
`Row` *and*, below 520px wide, a `Column`. The card lives in a `ListView`, so
that Column has unbounded height — an `Expanded` there cannot lay out, leaving
a render box with no size for the next paint to dereference.
*Fix:* the header is a plain `Row`, wrapped in `Expanded` only at the `Row`
call site. `test/market_resize_test.dart` drags an already-mounted board from
1280x800 down to the 340x480 minimum on every tab — the previous tests always
set the viewport *before* the first pump, so live resizing had no coverage.

**`TemporaryLoadingScreen.compact` was declared and never read**
The Academy passes `compact: true` into a `Positioned(top: 10, right: 10)` —
no width or height, so unbounded constraints — and got the full-screen
`Scaffold` back, which tries to be infinitely large. That threw on the first
frame of *every* Academy visit while stats were syncing.
*Fix:* `compact` now returns a small self-sizing pill.

**Cloud-save failures were completely invisible**
`saveUserStats` catches upsert errors, keeps the local cache and returns
`synced: false`. Correct for a flaky network, but nothing ever displayed that
state — which is how the `age` column bug broke every cloud save for a long
stretch with no symptom, since local saving kept working.
*Fix:* `UserStatsController.cloudSyncHealthy` plus `CloudSyncBanner` on the
profile screen. Hidden when signed out, where device-only saving is correct.

**Finance Brawl drew a flat "C" for the player**
The player token painted `equippedSkinId.characters.first` — the equipped skin
happened to start with a C.
*Fix:* it draws the player's uploaded profile picture, clipped to the existing
ring, and falls back to the letter when there is no upload.

**Sprite tooling only runs on Windows PowerShell 5.1**
The `tool/*.ps1` sprite scripts use `System.Drawing`, which PowerShell 7 (`pwsh`)
does not ship.
*Fix:* documented in `tool/README.md`; run them with
`%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe`.

---

## Testing

```bash
flutter analyze && flutter test
```

589 tests covering responsive layout at eight viewports (including the Life
sim itself, Feedback, and the Adventure map-pending screen), the money
panel at seven widths, the life-event chain wiring, price-chart zoom/pan/scrub, chart painters against pathological input,
working-order accounting, the Life simulation rules and its budgeting
model, town-map reachability, the side-walk frame selection, candle
caching, the quiz bank, and asset integrity.
