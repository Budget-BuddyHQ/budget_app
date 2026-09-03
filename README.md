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
  screen at eight viewport sizes (small phone through tablet, portrait and
  landscape) and **fails the build if anything overflows**. This is what turns
  clipping from a bug we find by accident into one CI catches for us.

---

## Error log

Every bug worth remembering, what caused it, and how it was fixed.

### Data correctness

**Every year in the feed restated the header above it**
`'Turned $age.'` printed on every year that drew an event — about three
quarters of them — directly underneath a feed header that already read
"Age 12". So the single most common line in the whole log was a restatement of
the line immediately above it, and a life read as repetitive even though,
measured over sixty runs, any two lives share only 2-12% of their events. The
paycheck line was a second offender at 15% of all lines, word for word, and
"A tight year. You made it work." a third at 6%.
*Fix:* no filler line at all on a year that had an event; five openers for the
paycheck line and six for the tight year. The most repeated line dropped from
6.8% of the feed to 3.2% and distinct lines went from 938 to 1,078.
*Files:* `life_sim_controller.dart`, `life_feed_texture_test.dart`

**An event no player had ever seen**
`fame_scandal` was gated at `minFame: 24` when the peak fame reachable in 300
random runs is 16 — it had already been lowered once from 40, and was still
above the ceiling both times. What surfaced it was adding eleven new events to
the pool, which diluted every draw by about 6% and pushed a marginal case over
the line: a content addition breaking balance somewhere unrelated.
*Fix:* `minFame: 12`. `life_variety_test` plays 400 seeds plus one per skill
focus and fails on any event nobody reached, which is the only thing that
would ever have said so.
*Files:* `life_sim_models.dart`

**The market board spent its whole rate budget off screen**
Every tick refreshed all sixteen tracked symbols, sequentially. Against a
60-call minute that caps the entire board at one update per sixteen seconds,
and nearly all of it fetched prices that were scrolled out of view.
*Fix:* a batch of four per tick, weighted to the player's holdings and
rotating through the rest — 48 calls a minute, a full sweep every 20s, and
anything being watched refreshing every 5s. Two things had to move with it: the
throttle from one board-wide clock to one per symbol (or pinned symbols were
refused by their own throttle five seconds after being fetched), and a cap that
includes the pinned ones (or ten holdings means 120 calls a minute).
*Files:* `market_data_service.dart`, `stock_market_page.dart`,
`market_batching_test.dart`

**A two-year-old could press Invest, and nothing happened**
Reported as "can you invest when you're 2 years old". The controller was
correct the whole time — `invest` checks `allows(LifeAction.invest)` and the
age table has said 16 since it was written. The *menu row* set its
`disabledReason` from whether you held 100 coins and never asked about age, so
a toddler with 150 coins got a lit button that took the tap and did nothing,
because `invest` returned silently. A dead control that looks alive is worse
than a blocked one that explains itself, and in a game for children it does not
read as a fault, it reads as being ignored. Gamble and Practise were the same
mistake without being broken yet: both duplicated the controller's numbers and
happened to agree with them.
*Fix:* structural rather than three patches. `_LifeAction` takes a **required**
`performs` field naming the action it runs, and `_actions` applies `gatedBy` to
every row it returns in one expression, so there is nowhere left to forget the
gate. Rows state only their local reason; the age rule is layered on top and
wins when both apply.
*Files:* `life_sim_page.dart`, `life_sim_controller.dart`,
`life_menu_honesty_test.dart`, `life_menu_render_test.dart`

**The sale said cheaper and the button said full price**
Town conditions applied their discount when *charging* but the choice rows
printed `choice.gold` straight from the data, so on a sale day the sign read
"cheaper than usual today" and the row under it still said -8. A discount you
only discover by watching your balance afterwards is not a lesson about sales,
it is a game that cannot be trusted to quote a price.
*Fix:* the row takes `shownGold`, computed with the same `priceFor` the map
charges with.
*Files:* `town_interior_screen.dart`, `town_conditions_test.dart`

**Every screenshot was of a tree whose images had never painted**
Three picture tiles rendered empty. I blamed the widget and "fixed" it; the
next shot came back with the tiles still empty *and the hero's map gone* —
which was the tell, because nothing I had touched could affect the map.
`tester.pump()` advances a fake clock and drains microtasks; decoding an
`Image.asset` is real async work. It hid for so long because it was not
consistent: an asset already in `imageCache` from an earlier screen in the same
file paints immediately, so the map appeared on some runs and not others, and
that got read as a broken widget rather than a broken harness.
*Fix:* a `runAsync` delay and one more pump before the shutter. It also brought
back the endings padlocks and the coin icon, silently missing from every
screenshot ever taken.
*Files:* `screen_render_test.dart`

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

**The tutorial spotlight claimed to be exact and was a guess, on both axes**
The overlay could not use a `GlobalKey` to find a nav tab — `MainNavigation`
keeps every screen alive in an `IndexedStack` and each renders its own bar, so
one static key per tab attaches to several widgets at once — so it computed
the tab rectangle from constants of its own: full screen width divided by the
tab count, 72px tall, flush to the bottom. The real bar is 80-106px tall
depending on the viewport, inset 10px each side (plus a 4px border, which is
drawn *inside* the box and insets the child — easy to miss, and worth 3.2px of
the total error on its own), and lifted 6-12px off the bottom. Wrong size and
wrong position on both axes, so the highlight drew its box beside the tab it
was meant to point at rather than around it. Reported three times before it
was measured instead of eyeballed.
*Fix:* the geometry now lives once, on `PopNavBar` itself (`barHeight`,
`bottomGap`, `sideInset`, `tabRect`), and the spotlight (`TutorialTargets.
navTabRect`) reads it rather than keeping its own copy. Fixing it surfaced a
second bug: with a *correct* spotlight, the coach card started colliding with
the real bar it had previously been avoiding a phantom of, because the card
was free to grow to the full screen height and only placed afterwards. The
card is now capped to the room actually available beside its target.
*Lesson:* a comment asserting a derived value is "exact" is not evidence that
it is — it has to be checked against the real widget, not against its own
assumptions restated. `nav_geometry_test` renders a real `PopNavBar` at five
viewports and measures a real tab's `Rect` against the prediction, specifically
so this class of drift cannot ship silently again.
*Files:* `pop_navbar.dart`, `coach_mark.dart`, `nav_geometry_test.dart`,
`tutorial_test.dart`

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

### Legibility

**The sound toggle reset itself to off on every launch**
`AppSoundService.enabled` declared a default, and then `initialize()` read the
stored preference as `?? false`. A fresh install has no stored key, so the
hardcoded fallback won and the declaration was decorative.
*Fix:* `?? enabled`, so the field's default is the actual default.
*Files:* `app_sound_service.dart`

**Every audio asset path pointed at nothing**
`assets/audio/` contained only `.gitkeep`, while `_assetPaths` listed ten WAVs.
Sound was disabled by default with a comment blaming those files for sounding
harsh — files that did not exist.
*Fix:* `tool/make_sounds.py` synthesises all sixteen from the standard library
(`wave`, `math`, `struct`). Named sources were not usable — CS:GO case audio is
Valve's, Minecraft's music is Mojang's/C418's, and this app is going to the
stores — but what makes a case roll work is the decelerating tick rhythm, which
is reproducible and is not anyone's property.
*Files:* `tool/make_sounds.py`, `app_sound_service.dart`, `customize_screen.dart`

**A gold label on a gold chip: the "yellow text" report**
The "MAIN GAME" pill wrote `#FFD45C` on an 18% wash of `#FFD45C`, measuring
**3.48:1**. The same gold on the page background measures 10.3:1, so nothing
about the colour was wrong — the wash raises the background *towards* the label.
The pattern is everywhere: rarity badges, difficulty pills, stat meters,
category tags. The navy legendary badge measured **1.04:1**, i.e. a badge with
no letter on it.
*Fix:* `AppTheme.tintedChip()` returns the fill and the ink as a pair, with the
fill pre-blended to opaque so the label cannot inherit whatever is behind the
chip. `test/contrast_audit_test.dart` walks nine screens and fails on anything
below WCAG AA; it found 47 of these.
*Files:* `app_theme.dart`, `main_game_page.dart`, `customize_screen.dart`,
`minigames_page.dart`, `lesson_screen.dart`, `money_habits_screen.dart`,
`life_sim_page.dart`, `life_money_panel.dart`, `habit_progress_grids.dart`

**"Dark slate" was a mid tone, and twenty findings came from it**
`panel_slate` is the app's main panel. The pack recolour left its centre at
`#51655E`, so every caller — all of which wrote their text for a dark surface —
was wrong at once: gold body text at 3.73:1, muted greys at 2.5–3.2:1.
*Fix:* `tool/build_ui_pack.py` dims that one asset to 0.60 after recolouring
(centre `#303C38`), and `PixelFrameStyle` now carries the measured surface plus
inks that clear AA against it. `test/pixel_kit_test.dart` decodes the real PNGs
and checks the constants, so recolouring fails the build rather than silently
producing unreadable panels.
*Files:* `tool/build_ui_pack.py`, `pixel_kit.dart`, `test/pixel_kit_test.dart`

**A nine-slice too small to draw fell back to the wrong colour**
`PixelFrame` used one hardcoded dark green as the fallback fill for all four
styles. A parchment panel squeezed below its own corner size therefore flipped
to dark green while its text stayed dark ink — legible copy becoming invisible
on a narrow phone, with nothing in the source to suggest it.
*Fix:* the fallback is `style.surface`.
*Files:* `pixel_kit.dart`

**The contrast audit's first run was almost entirely false positives**
Compositing flattened to opaque after a single layer, so "white at 6% over
white at 10% over a dark page" — the app's most common card — reported as solid
white, and every white caption on it looked like a 1:1 failure.
*Fix:* source-over that preserves alpha, and keep climbing the tree until a
layer is actually opaque. A second pass excluded emoji, which are colour
bitmaps and ignore the declared text colour.
*Files:* `test/contrast_audit_test.dart`

**A contrast fix turned a mint icon near-black and still failed**
`legibleOn` picked its direction from the surface's luminance — right for a
clearly dark or light ground, wrong for the mid-tones this app is full of. An
accent badge is a wash of its own accent, so it lands mid.
*Fix:* walk both directions and take whichever reaches the target with the
smaller change.
*Files:* `app_theme.dart`

**A chip blended its base over its own colour**
The arcade `_MetaChip` computed the card colour it sits on by lerping in *the
chip's* tint instead of the card's. The neutral near-white "5–10 min" chip
therefore invented a pale card that no text could sit on, and the fix briefly
looked like a regression.
*Fix:* the chip takes `cardAccent` explicitly.
*Files:* `minigames_page.dart`

**The kit-constant test hung until the runner killed it**
`test/pixel_kit_test.dart` decoded PNGs inside `testWidgets`. Image decoding is
real asynchronous engine work, and inside a widget test's fake-async zone the
future is never completed.
*Fix:* plain `test`, reading bytes from disk with `dart:io`.
*Files:* `test/pixel_kit_test.dart`

### Onboarding, audio and the jar

**The coach card overflowed a phone from step two onward**
Four ordinary-looking children in the tour card's footer — a counter, Back,
Skip and a 116px Next — came to 372px inside 333 on a 393px phone, because
Material's text buttons carry a 64px minimum width and a 48px tap target on
top of their padding. Back only exists from the second step, so it appeared
mid-tour, on some devices, and vanished when the tour closed: a red flash the
user could not screenshot.
*Fix:* flexible counter, compact button style, and a primary button that
shrinks from 104px when the row is tight. `tutorial_test.dart` walks the whole
tour at six viewports.
*Files:* `coach_mark.dart`, `test/tutorial_test.dart`

**The tour described the app instead of showing it**
`TutorialScreen.show` pushed a full-screen deck, so a player who read all
eleven pages still had to go and find every feature afterwards.
*Fix:* `CoachMarkOverlay` is drawn by `MainNavigation` as a layer over the live
`IndexedStack`, spotlighting real widgets and switching tabs underneath as it
goes. Profile asks for a replay through `AppSettingsController` rather than
pushing anything, because it is a screen inside the shell that draws the tour.
*Files:* `main_navigation.dart`, `coach_mark.dart`, `app_settings_controller.dart`,
`profile_screen.dart`

**The case-roll sound was out of sync by however slow your connection was**
The ratchet started in `_openCase()` *before* the awaited network call that
decides the result, and the reward chime played before `showDialog` — 4.2
seconds before the reveal it was announcing.
*Fix:* both moved into `_CaseRollDialog`, which owns the reel. The ratchet
starts on the same frame as the animation, the chime plays on reveal, and Skip
stops the ratchet with the picture.
*Files:* `customize_screen.dart`, `app_sound_service.dart`

**The reel travelled a different distance for every skin**
`4 * catalogue + indexOf(winner)` tiles, so no pre-rendered ratchet could ever
match more than one result — and the reel showed the same parade in the same
order on every open.
*Fix:* the strip is built around the known result (random filler, winner at a
fixed index), and `tool/make_sounds.py` emits one tick per tile crossing by
inverting the reel's own easing curve. `case_roll_sync_test.dart` reads the
item count, duration and curve from both files and fails if they disagree.
*Files:* `customize_screen.dart`, `tool/make_sounds.py`, `test/case_roll_sync_test.dart`

**The savings jar frowned when you were doing well**
Canvas y grows downward, so a quadratic control point *below* the endpoints
makes a smile. The mouth had the sign inverted, so the jar pulled a face at
players for keeping a streak and grinned at them for abandoning it.
*Fix:* signs corrected, and `savings_jar_test.dart` renders the widget and
measures the mouth's curvature so it cannot silently flip again.
*Files:* `savings_jar_widget.dart`, `test/savings_jar_test.dart`

**The jar showed four states for a continuous number**
Progress was a Material glyph at one of four sizes, so a player earning habit
points saw nothing change for most of a stage.
*Fix:* a painted glass jar with coins clipped inside, whose count follows
`MoneyHabitController.jarFill` — a fraction of the *whole* ladder, not of the
current stage, which used to reset to zero at the exact moment the player was
being congratulated.
*Files:* `savings_jar_widget.dart`, `money_habit_controller.dart`,
`money_habits_screen.dart`

**Three of four Money Habits tabs were never laid out in the sweep**
The viewport sweep and the contrast audit both saw only the first tab, so the
jar tab shipped unchecked.
*Fix:* an `initialTab` seam on `MoneyHabitsScreen`, the same shape as
`LifeSimPage.debugInitialLife`. It immediately caught the jar's milestone pips
at 3.2:1.
*Files:* `money_habits_screen.dart`, `test/responsive_layout_test.dart`,
`test/contrast_audit_test.dart`

**Rendering a widget to pixels in a widget test hangs the runner**
`toImage` and `toByteData` are real engine work; inside a widget test's
fake-async zone their futures are never completed, so the test runs until the
harness kills it instead of failing.
*Fix:* wrap the capture in `tester.runAsync`. (The same class of problem as the
PNG-decoding test in `pixel_kit_test.dart`, which uses a plain `test` instead.)
*Files:* `test/savings_jar_test.dart`

### Content, credibility and audio levels

**Every UI sound was mixed at the same loudness**
`tool/make_sounds.py` normalised all sixteen files to a single peak, so the
click under a tab switch — which fires dozens of times a session — was as loud
as opening a case.
*Fix:* per-file peak targets (navigation 0.22, taps 0.30–0.34, rewards
0.62–0.80) plus a per-effect playback volume in `AppSoundService`, so overall
loudness can change without regenerating the files.
*Files:* `tool/make_sounds.py`, `app_sound_service.dart`

**The de-click fade was eating short sounds**
A symmetric 10ms fade on a 55ms navigation blip whose peak is in the first
millisecond flattened the attack, and the file came out at roughly half its
requested level.
*Fix:* asymmetric — 1.5ms in, 10ms out. Long enough to remove the
discontinuity, short enough to keep the transient.
*Files:* `tool/make_sounds.py`

**The town said the same thing every visit**
Six buildings, one prompt and one choice set each, so the second visit to any
of them was the first visit word for word.
*Fix:* `town_scenarios.dart` adds 12 encounters that rotate daily — fixed
within a day so the town has a state you can plan around, different tomorrow.
*Files:* `town_scenarios.dart`, `town_interior_screen.dart`

**A town scene where every option cost money**
The "buy 2 get 1 free" encounter offered three choices and all three spent
something, which teaches that spending is compulsory.
*Fix:* a fourth option that costs nothing, and a test asserting every encounter
has one.
*Files:* `town_scenarios.dart`, `test/town_scenarios_test.dart`

**Lessons made claims with nothing behind them**
Nothing in the Academy said where any fact came from, so a researched lesson
and one written from memory looked identical to a reader.
*Fix:* `lesson_sources.dart` (39 citations, primary publishers only, enforced
by an allowlist) plus `lesson_extras.dart` mapping every lesson and every quiz
skill to them. `test/lesson_sources_test.dart` fails the build on an uncited
lesson, a broken citation, a non-HTTPS or untrusted source, or a source that is
defined and never used.
*Files:* `lesson_sources.dart`, `lesson_extras.dart`, `lesson_detail_screen.dart`,
`quiz_widgets.dart`, `curriculum_sources_card.dart`

**Finance Brawl never asked about a payslip or a free trial**
The 100-question bank covered curriculum topics and skipped the two areas an
under-21 player meets first — earning/work and scams/fees/fine print.
*Fix:* 20 questions in `brawl_questions_extra.dart`, kept out of the 3,800-line
game file so they can be tested without pumping a game. The test models the
game's per-encounter option shuffle and asserts the correct answer reaches
every slot, so the source's authored index can never become guessable.
*Files:* `brawl_questions_extra.dart`, `finance_brawl_game.dart`,
`test/brawl_extra_questions_test.dart`

**Coin Cascade was one puzzle**
A single tuning — 25 moves, one goal, one bill schedule — so once a player
solved it there was nothing left to find out.
*Fix:* seven levels whose rule twists are the curriculum in order (bills every
3 moves, coins worth double, wants costing double). The rule stays on screen
rather than appearing once in a dialog.
*Files:* `coin_cascade_models.dart`, `coin_cascade_page.dart`,
`test/coin_cascade_test.dart`

**Eight new skins, and a generator that makes more from four colours**
*Fix:* `tool/redraw_villagers.py --new` writes a full 32-frame sheet per skin
from a palette entry, so growing the gacha pool after release costs a table row
rather than an art commission. Catalogue is 24.
*Files:* `tool/redraw_villagers.py`, `avatar_skin.dart`, `assets/self_made_skins/*`

**The sprites were the right shape and still looked wrong**
Drawn with ellipses at 1x, so a "pixel" was one unit tall on the shoulder and
three on the jaw and none of them shared a grid — a blur pretending to be pixel
art.
*Fix:* draw on a 26x40 grid and scale x4 with nearest-neighbour, so every
visible pixel is a perfect 4x4 block. The walk is a hand-written eight-frame
table, because at three pixels of travel a sine rounds to a stutter.
*Files:* `tool/redraw_villagers.py`

**The arcade had nothing for a younger player**
Two hard games, both requiring reading and quick recall.
*Fix:* Coin Cascade — a match-3 where needs pay bills, wants raise them and
savings win the run. Pure-Dart engine, 19 tests, including one asserting that a
bot taking the first legal swap it sees does *not* always win.
*Files:* `coin_cascade_models.dart`, `coin_cascade_page.dart`,
`test/coin_cascade_test.dart`, `arcade_catalog.dart`, `minigames_page.dart`

### Sprites, upgrades and friends

**The villager sprites were wrong in every direction**
The torso was twice the head's width and bulged past the shoulders; there was
no neck; the profile had a skin tab where a nose belongs and a hair wedge
behind it, which together read as a beak.
*Fix:* `tool/redraw_villagers.py` redraws all 22 sheets from scratch with
chosen proportions — head 40, shoulders 40, waist 33, profile 23 (0.58 of the
front). A side view narrower than the front is what stops a character looking
inflated when they turn.
*Files:* `tool/redraw_villagers.py`, `assets/self_made_skins/*`

**Palette extraction turned a white-haired skin bright yellow**
The first redraw ranked each sheet's colours by area and guessed which was
skin. `aurora_prime` has white hair on a gold shirt, so the "warm, light,
saturated" test picked the shirt.
*Fix:* four fixed probe coordinates, verified against all 22 sheets.
*Files:* `tool/redraw_villagers.py`

**Half the side walk was being thrown away**
`kSideWalkFrames` skipped columns 0 and 4 because the old art drew those
neutral poses with front-facing legs on a profile body, and `kSideIdleFrame`
was 1 for the same reason — so a character standing still stood mid-stride.
*Fix:* the redraw's walk phase is a true eight-frame loop with proper profile
contact poses, so both workarounds are gone and the test asserts they stay
gone.
*Files:* `adventure_world_screen.dart`, `test/town_map_test.dart`

**The tour card was a 930px banner on a desktop window**
Pinned 14px from each edge, it covered a quarter of the app it was pointing at.
*Fix:* capped at 460 and centred, with contents scaling 0.78→1.0 off the
*shorter* screen edge — a landscape phone has generous width and no height.
*Files:* `coach_mark.dart`, `test/tutorial_test.dart`

**Adding a friend twice failed with a permission error**
`friendships` grants `select, insert` and has no UPDATE policy, and a default
`upsert` resolves a conflict with an UPDATE.
*Fix:* `ignoreDuplicates`, which is `ON CONFLICT DO NOTHING` and needs only
INSERT.
*Files:* `supabase_service.dart`

**There was no way to remove a friend, and no list to remove them from**
The card showed a code and an input and nothing else, so adding someone was
indistinguishable from the feature being broken.
*Fix:* `removeFriend()` (deletes both directions; the policy makes the second
a no-op unless you own that row), plus a friends list that reloads after any
add or removal.
*Files:* `supabase_service.dart`, `profile_screen.dart`

**Fourteen sky gradients shipped and were never shown**
`assets/map_assets_coins/day-night-cycle/` was referenced by nothing while the
app painted the same flat green at every hour.
*Fix:* `DayNightSky` picks one from the device clock, behind the main game —
dimmed and scrimmed, because a full-strength noon gradient would invalidate
every contrast number the audit measures.
*Files:* `day_night_sky.dart`, `main_game_page.dart`, `pubspec.yaml`

### The town, the tour and the settings page

**The sprite redraw traded detail for a grid**
Dropping to a 26x40 canvas fixed the misaligned pixels and left no room for a
face, a collar or a shoe.
*Fix:* 52x81 at 2x — every pixel is still a clean 2x2 block on the grid, with
four times as many of them to draw with.
*Files:* `tool/redraw_villagers.py`

**The palette probe rebuilt every skin bald**
It took the first *opaque* candidate, and opaque is not correct: run against
sheets an earlier version of the script had generated, the hair probe landed on
the forehead and all 22 skins were rebuilt with hair the colour of skin. The
sheets had to be restored from git.
*Fix:* reject a candidate matching a colour already claimed, so the extraction
survives being pointed at art it did not generate.
*Files:* `tool/redraw_villagers.py`

**Nobody in the town ever moved**
Walk cycles for all four NPC looks shipped in the bundle with nothing
referencing them.
*Fix:* short patrols along one axis, pausing at each end and stopping while the
player is in range — an NPC that wanders can walk into the sea, or away from
the player trying to reach it.
*Files:* `town_components.dart`, `town_spot_models.dart`,
`adventure_world_screen.dart`, `app_assets.dart`,
`test/town_npc_patrol_test.dart`

**The shop interior looked broken on a wide window**
The panel hugged the top-right, the stall sat bottom-left, and the middle was
empty floor.
*Fix:* both columns centred, panel capped at 460, and floorboards so the
largest area on screen reads as a floor rather than a void.
*Files:* `town_interior_screen.dart`

**The coach card pointed at nothing on a desktop window**
Pinned to the screen edge, so the explanation sat in the top-left while the
arrow pointed 700px lower.
*Fix:* anchored to the spotlight, clamped to stay on screen.
*Files:* `coach_mark.dart`, `test/tutorial_test.dart`

**A town map was running through the settings rows**
The profile backdrop was tuned up to saturation 1.4 behind a 0.42 scrim, and
the cards were 72% transparent, so grass and fences slid behind
"Notifications" and "Sound".
*Fix:* opaque cards, and a backdrop that is texture rather than a picture.
*Files:* `profile_screen.dart`

### Crashes

**Walking up to an NPC threw a full-screen red error**
```
setState() or markNeedsBuild() called during build.
This AdventureWorldScreen widget cannot be marked as needing to build
because the framework is already in the process of building widgets.
The widget which was currently being built when the offending call was
made was: LayoutBuilder
```
Bonfire ticks its components from inside the game widget's own build — the
widget sits in a `LayoutBuilder` — so a proximity sensor firing calls back into
Flutter *during the build phase*, and `setState` there throws. The hazard was
always present (a shop sensor could trip it too), but it became reproducible
the moment NPCs started patrolling: an NPC walking *into* the player fires the
sensor from inside a frame the player did not initiate.
*Fix:* `_applyAfterFrame` checks the scheduler phase and defers to a
post-frame callback when a build is in progress. Every sensor callback — spots,
NPCs and coin pickups — goes through it. Deferring is the correct fix rather
than a workaround: the state change is a *response* to something the game
simulated, and the next frame is when it should become visible.
*Files:* `adventure_world_screen.dart`

**Unit titles ran off the edge of their own card**
The Academy's unit strip sized each chip to a 146px minimum while its contents
— icon, gap and a 118px column inside 14px of padding either side — need 178.
"Stocks and Trading" and "Protecting Your Money" were clipped mid-word.
*Fix:* a 196px minimum over a 132px text column, and the column is `Flexible`
so the label scales instead of overflowing if anything ever does constrain the
chip. The column went 118 -> 132 because the test caught a second route to the
same visible bug: "Retirement and the 401(k)" needed ~124px even at
`FittedLabel`'s 62% scale floor, so it was being ellipsised rather than
scaled. The title
prefix is now stripped by splitting on `": "` rather than by matching the
chip's *position* — unit ids are permanent and display order is not, so
`unit_10` is titled "Unit 1" and a position-based strip left the prefix in
place whenever the two disagreed.
*Files:* `lesson_screen.dart`

### The sprites, settled

**Four redraws, and the hand-drawn original was the answer**
*Fix:* new skins are palette swaps of the shipped template
(`tool/recolour_villager_skins.py`) rather than procedural drawings, so all 30
skins are the same art at the same quality. `tool/redraw_villagers.py` is
deleted — keeping a generator whose output was rejected three times is keeping
a trap.
*Files:* `tool/recolour_villager_skins.py`, `assets/self_made_skins/*`

**The profile read as a bird**
The nose was an L: a small skin patch at eye level and a much wider one below
jutting two or three big pixels past the hairline.
*Fix:* `tool/fix_side_heads.py` trims it to a single big pixel, in place on the
art's own 5px grid. The bar across the top of the head is left alone — against
the front-facing row it is the brim of the character's cap, and a detector for
it only recognised it in 6 of 16 frames, which would have put a hat on the same
head in some frames of a walk cycle and not others.
*Files:* `tool/fix_side_heads.py`

**The art tool destroyed art on a second run**
It trimmed one big pixel per pass, so a three-pixel beak needed three runs and
the run after that ate the nose, leaving a sliver of skin for a face.
*Fix:* trim to a *target* (`overhang - BIG`) rather than by a fixed amount, so
one run lands on the final result and every run afterwards finds nothing to do.
*Files:* `tool/fix_side_heads.py`

**The tutorial card was positioned in fixed pixels**
14px insets, a 48px gap and a 460px cap mean the card is a different proportion
of the screen on every device it runs on.
*Fix:* every number is a fraction of the viewport, clamped — 2.5% side margin,
42% width, 5% gap. The fraction started at a third and had to rise: at 34% a
375px phone and an 834px tablet both hit the 300px floor and got an identical
card, so "proportional" was fixed across most of its range. The test asserts
the ramp (phone < tablet <= desktop) rather than any pixel count.
*Files:* `coach_mark.dart`, `test/tutorial_test.dart`

---

### Content wiring and text fit

**Twelve adult-years life events did not compile**
`life_events_adult.dart` was written against a `FinanceConcept` enum from
memory rather than from the file, so it used four constants that do not exist
(`compoundInterest`, `budgeting`, `income`, `investing`) and a `LifeFlag`
called `homeowner`. 22 analyzer errors.
*Fix:* mapped onto the real members — `compoundGrowth`, `budgetRule`,
`incomeVsWealth`, `diversification` and `LifeFlag.ownsHome`. The lesson is
that an enum with sixteen closely-related members is exactly the kind of thing
worth reading before writing against.
*Files:* `life_events_adult.dart`

**A new life-sim flag opened a thread nothing could close**
`life_chains_test.dart` asserts that every flag which *gates* an event is also
cleared by one, because otherwise a life carries the thread for sixty years
while the draw's open-chain boost keeps favouring a beat that has nothing left
to say. Buying a house set `ownsHome`; nothing ever sold it.
*Fix:* added `a_downsize` — sell, stay, or rent the spare room — which clears
the flag on the selling branch. The guard did its job: the missing content was
a missing *scene*, not a missing line of plumbing.
*Files:* `life_events_adult.dart`

**"Card debt" failed the contrast audit at 4.26:1**
The life-sim chip strip painted its label in the same `#FF8FB1` as its 14%
background wash. `AppTheme.tintedChip` fixes exactly this, but its default
surface is `deepForest`, and the strip sits on a lighter composite — measured
against the wrong backdrop it reported the tint as already legible.
*Fix:* pass the real surface (`on: AppTheme.panel`). The tint keeps its
meaning — trouble is still pink — and the ink lifts until it clears AA.
*Files:* `life_sim_page.dart`

**Four new town scenarios charged for every option**
`town_scenarios_test.dart` refuses an encounter where walking away is not on
the table, because a scene in which spending is compulsory teaches that
spending is compulsory.
*Fix:* each got a free option that is a real money behaviour rather than a
token "do nothing" — read the labels and buy neither today, pack lunch from
the cupboard, make the present, read the meter yourself before paying.
*Files:* `town_scenarios.dart`

**The jar's mood pill was cut off on a small phone**
"Slipping · last logged 999 days ago" wanted 260px in a 201px pill. Three
problems in one string: it repeats what the pill already says, a raw day count
stops meaning anything past a fortnight, and nobody reads 340 as "eleven
months".
*Fix:* coarsen the unit as the gap grows — today, yesterday, N days, N weeks,
N months, "over a year ago" — and drop the redundant prefix.
*Files:* `money_habits_screen.dart`

**Childhood was the thinnest part of the life sim, and it is the opening**
Counting eligible events by age put ages 5-15 at 20-23 while every adult year
sat at 60-70. Not a crash, and easy to miss, because the symptom is "it feels
samey" rather than an error — but a run plays eighteen turns through childhood
before it reaches twenty, so the thinnest stretch of the pool was also the
first ten minutes of the game and the whole of what the 4-12 audience plays.
*Fix:* `life_events_childhood.dart` — 15 school-years events (first pocket
money, saving for the thing, a friend who has one, chores, a stall, lost money,
a broken window, lending to a friend, a card at the shop, birthday money, a
first account). Ages 5-15 now sit at 23-34, and the guard in
`life_variety_test.dart` was raised from 3 to 20 so it cannot quietly thin out
again.
*Files:* `life_events_childhood.dart`, `life_sim_models.dart`

**The text-fit audit's first run was mostly false positives**
`flutter_test` substitutes a fallback for anything `google_fonts` would fetch,
and that fallback is Ahem: every glyph, from `i` to `M`, is exactly one em
wide. "Retirement and the 401(k)" measured 350px at 14px — 14.0px a character
with no variation, against 10.7 for an `M` and 3.1 for an `i` in real Pixelify
Sans. Every width the environment reported was about 1.7x the truth, and
`didExceedMaxLines` flagged a dozen labels that are fine in the running app.
*Fix:* the first attempt calibrated around it — re-measure each finding at an
estimated 0.62em advance and skip `FittedLabel`. That worked and it was the
wrong fix, because it left every other suite still laying out in the wrong
face. Bundling the fonts (below) removed the problem at the source, and the
audit now takes the renderer at its word.
*Files:* `test/text_fit_test.dart`

**The app downloaded its own typefaces on first launch**
`google_fonts` fetches a face over HTTP the first time it is used and caches it
to the device. Until that finishes — and forever, offline — every label renders
in the platform fallback. That is not an edge case: it is the first launch,
which is what a store reviewer sees, and it is a child on school wifi with the
font CDN blocked.
*Fix:* `tool/fetch_fonts.py` bundles the nine faces the app resolves to. The
files have to be real TrueType, and all three obvious sources give something
Flutter cannot read — the `css2` endpoint returns **EOT** with an old user
agent (it has a `.ttf` in the URL and is not a TrueType file) and **WOFF** with
a modern one, and `github.com/google/fonts` now ships only a **variable** TTF
per family, which registers under one name and renders every weight at its
default instance. So the tool downloads the variable font and cuts static
instances out of it with `fonttools`. The tell that the first attempt had
failed was that a hand-registered `FontLoader` still measured every glyph at
exactly one em: the load had silently fallen back.
572KB, and `AssetManifest` resolves inside `flutter test` too — so every suite
in this repo now lays out in the face a player actually sees.
*Files:* `tool/fetch_fonts.py`, `pubspec.yaml`, `test/bundled_fonts_test.dart`

**`FittedLabel` measured one font and painted another**
It read `style ?? DefaultTextStyle.of(context).style`, so passing *any* style
dropped the ambient one — for measurement only, because `Text` itself always
merges. Every label with a style that did not name a family was measured in the
platform default and painted in Pixelify Sans or Quicksand.
The failure is silent and one-directional: when the painted face is wider,
`needed <= available` comes out true, the widget decides no scaling is needed,
and the text overflows exactly as if the widget were not there. "Mushroom
Goomba" ellipsised inside a 114px tile it needed 123px for — a 0.93 scale,
nowhere near the 62% truncation floor.
*Fix:* `DefaultTextStyle.of(context).style.merge(style)`, and 1% of slack on
the computed scale so a label that fits to the exact pixel is not one rounding
step from overflowing.
*Files:* `fitted_label.dart`

### The tutorial spotlight was pointing next to things

Reported three times, and the comment above the code claimed it was "exact
rather than a guess". It was a guess.

The overlay cannot use a `GlobalKey` to find a nav tab — `MainNavigation` keeps
every screen alive in an `IndexedStack` and each renders its own bar, so one
static key per tab attaches to several widgets at once — so it computed the
rectangle from constants: full screen width divided by the tab count, 72px
tall, flush to the bottom.

**Every one of those was wrong.** The bar is 80-106px tall depending on the
viewport, inset 10px each side, and lifted 6-12px off the bottom. Wrong size,
wrong position, on both axes. The numbers now live on `PopNavBar` itself and
the spotlight reads them, and `nav_geometry_test` renders a real bar at five
viewports and measures a real tab against the prediction.

Two things fell out of fixing it. The **4px border** was the last 3.2px of
error, and it is easy to miss: a `Container`'s border is drawn inside its box
and insets the child, so the row of tabs starts four pixels further in than the
padding alone suggests. And with a correct spotlight the card started colliding
with the *real* bar, which it had been avoiding a phantom of — so the card is
now capped to the space beside its target rather than free to grow and then be
placed wherever it fits.

### The Daily strip

One label was doing the damage. **"Find/Create Habits"** was three times the
width of every other tab and carried a slash in it — a slash in a label is two
labels that could not agree — and in a strip of six it made the whole row
scroll for one tab's sake. The page that lists habits and lets you make one is
"Habits".

The strip is also a pill now rather than a Material underline, which is the
same shape the bottom bar uses for its active tab: the two places in the app
that say "you are here" finally say it the same way. All six fit on one line
without scrolling.

### Two ways to find work

Reported as an idea rather than a bug: the map has a notice **board** with
cards pinned to it, so the menu should be *going online*. That is a better
model than the one that was there, and it fixes the duplication complaint at
the root — the two entries are not the same action listed twice, they are two
channels a person really uses.

So the menu row is "Search for work online", the board hires you in person, and
turning up is worth an extra roll on the job market: best of three instead of
best of two. Both stay available, because both are real, and blocking the menu
route would punish somebody who cannot get to the map.

The board could not employ anybody before this. It handed out 15 or 40 coins,
so the one building in the game named after employment was a coin dispenser
with a career theme, while the only real route to a job was a menu row — which
is the wrong way round.

### The sounds had no attack, and the level was a lie

"Still meh", and measuring said why. **85% of the energy in a tap was below
401Hz.** The transient was there and correct — 91% of *its own* energy is above
2kHz — but it sat about 9dB under the body, and then the whole mix was
lowpassed a second time. A dull thud with no click on it.

Filtering the body and the transient separately, and raising the contact level
four to five times, took the first five milliseconds of a tap from **2% to
23%** high-frequency energy.

Then a second fault surfaced underneath the first. `_write` normalised the
signal and *afterwards* faded its edges, so a sound whose peak landed inside
the 1.5ms fade-in came out far quieter than asked for: tap.wav requested a peak
of 0.30 and wrote 0.168. That fade had already been shortened once, from 10ms,
for exactly this reason. It is 0.3ms now and the normalisation happens after
it, so every file lands on its target to within a thousandth.

Effects moved to 44.1kHz as well — 22k caps everything at an 11kHz ceiling,
which is the octave a click's brightness lives in. The ambient loop stays at
22k, because it is a low pad with nothing up there to lose and would otherwise
double to 8MB. `audio_quality_test` measures all of it: peak against intended
level, zero-crossing rate in the attack as an FFT-free brightness proxy, and
that nothing starts or ends on a step.

### A reason to play a second life

The endings collection is the strongest honest retention mechanic this app has:
it rewards playing *differently* rather than playing more, which is exactly the
behaviour a financial-literacy game wants, and it needs no streak, timer or
notification to work.

It was sitting on the Play hub, below the fold, as a row of tiles reading
"Undiscovered" — visible only to somebody who had already decided to come back,
and telling them there was something to find but nothing at all about how to
find it. It is on the **epilogue** now, at the moment a player is deciding
whether to start another run, naming one specific ending and how to reach it.

The ordering needed care. The first version took the first ending missing from
the enum, which is `goneTooSoon` — so the game's advice to a child who had just
finished their life was "ignore your health long enough and the run ends
early". `chaseOrder` is a safety ordering, not a difficulty one: the two
failure endings are still collectable and still described honestly, they are
just never what the app suggests while anything else is outstanding. What it
leads with is the ending the whole curriculum points at.

### The second map became playable

`assets/images/maps/map (1).png` had been sitting unused for weeks. It was
exported as a flat 800x800 PNG — no tile grid, no collider flags — and three
attempts at inferring collision from the image alone (edge density, colour
clustering, tile variance) all marked the main promenade solid, which cuts the
town in half and is worse than not shipping it.

**The fourth attempt stopped guessing.** Both maps are drawn from the same
8x66 spritesheet, and `map.json` is hand-authored with real collider layers —
so it is ground truth about which tile ids are solid. `tool/build_map_two.py`
recovers map 2's tile ids by matching each 16px cell against the sheet (70%
are an exact match; most of the rest are a transparent tile composited over a
background, which takes it to 93%; the last 172 fall back to nearest), then
labels each one using map 1's mapping: **186 solid ids, 51 open, and only two
that appear in both.**

Result: 237 solid tiles, 2,263 walkable, and **99.6% of the walkable space is
one connected region spanning the whole map**. Unknown ids default to walkable
on purpose — the two failure modes are not symmetric, and a town you can walk
through a bush in is much better than a town cut into quarters.

### The markers were floating in the road

Reported as "make the store near the building", and measured, that was
generous. Against the collider data the cafe and the clinic were sitting *four
tiles* from the nearest solid thing and the market and library three — on
screen, a coloured circle in the middle of a road with no building anywhere
near it.

`tool/place_town_spots.py` snaps each one to the nearest walkable tile that
actually touches a **building**, where a building is a connected solid cluster
of six or more tiles. The size floor matters: trees, fences and bins are solid
too, and snapping a shop marker to the side of a hedge is a different wrong
answer rather than a fix. The first run also cheerfully dragged all six NPCs
onto doorsteps, which is why it now only moves `spot_` ids — a person is not a
building entrance, and pinning them to walls made the town look like everyone
was queueing.

### The walking animation, and why four redraws never fixed it

**It was never the drawing.** Each sheet has eight side-facing columns but
only *four distinct poses* — measured across all 38 sheets, column 0 is
pixel-identical to 4, 1 to 3, and 5 to 7. And 5-7 are not the other half of
the stride: they are the same poses drawn 16% bulkier, 7,820 opaque pixels at
79.5px wide against 6,740 at 65px.

So the cycle ran slim-pass, slim-up, slim-pass, fat-pass, fat-up, fat-pass.
**The same leg led the whole way round**, while the body swelled and shrank
twice a second. That is what "the character is clanking" was, and it is why
redrawing individual frames never helped — every frame was fine on its own,
and the missing thing was the second half of the cycle.

A stride's second half is the first half with the **legs swapped**, so
`tool/fix_side_walk_cycle.py` rebuilds columns 5-7 from 1-2 mirroring only the
leg band. The torso is pixel-identical between halves, so the swell is gone by
construction; the legs alternate, which is the part that reads as walking.
Step time went 0.07 to 0.11 as well — fourteen frames a second was a judder
rather than a stride.

### The market board was spending its whole budget off screen

"Can it change real time so it's quick" — and the answer had two parts, one of
which was mine to get wrong.

The **first** was the ten-cent coin: at 10 coins to the dollar one coin is
10p, and most of what a real share does in twenty seconds is smaller than
that, so the integer price sat perfectly still while the percentage beside it
moved. The board now displays one decimal (cent resolution) while trades keep
using whole coins, so nothing about the economy changes.

The **second** was the user's idea and a better one than mine. Every tick
refreshed all sixteen tracked symbols, sequentially — and against Finnhub's
60-call minute that caps the entire board at one update per sixteen seconds,
almost all of it spent on prices scrolled off the screen. Now a tick fetches a
**batch of four**, weighted to the symbols the player holds and rotating
through the rest: 48 calls a minute, a full sweep every 20 seconds, and
anything being watched updating every **5**. Four times fresher for what is in
front of you.

Two things had to be got right for that to be safe, and neither was obvious.
The throttle had to move from one clock for the whole board to one per symbol,
or every pinned symbol was refused five seconds after the batch that fetched
it. And the batch has to be capped *including* the pinned ones — a player
holding ten stocks would otherwise pin ten symbols into a five-second tick and
make 120 calls a minute against a limit of 60. `market_batching_test` does
that arithmetic, because getting it wrong means a 429 and a dead board rather
than anything visible on screen.

### The main game was not repeating its events, it was repeating its prose

Reported as the main gameplay feeling repeated. Measured over sixty runs, any
two lives share only **2-12% of their events** — the variety was already
there. What repeated was the writing around them:

* `'Turned $age.'` printed on every year that drew an event, about three
  quarters of them, **directly under a feed header that already said "Age
  12"**. The single most common line in the log was a restatement of the line
  immediately above it.
* The paycheck line was one fixed sentence on every earning year: 15% of every
  line in the feed, word for word.
* "A tight year. You made it work." was another 6%.

A player scrolling back through a life saw the same handful of sentences over
and over and correctly concluded the game was repeating itself, even though
the decisions were not. The age restatement is gone, the budget line has five
openers and the tight year six — the *numbers* stay identical every year,
because that is what makes it a routine and the routine is the lesson, but the
sentence around them does not.

Measured after: the most repeated line dropped from 6.8% of the feed to 3.2%,
and distinct lines went from 938 to 1,078. `life_feed_texture_test` holds it,
with loose thresholds — the point is to catch a *new* line becoming wallpaper,
not to freeze the current wording.

### An event nobody had ever seen

`life_variety_test` plays 400 seeds plus one per skill focus and fails on any
event no simulated player reached. It caught `fame_scandal`, gated at
`minFame: 24` when the peak fame reachable in 300 runs is **16**. That gate had
already been wrong once — lowered from 40 — and both times for the same
reason: it was set to what "famous enough for a tabloid" sounds like rather
than to anything a player can get to.

Worth noting what surfaced it. Adding eleven new events to the pool diluted
every other draw by about 6%, which pushed a marginal case over the line. A
content addition can break balance somewhere unrelated, and the sweep is the
only thing that would ever have said so.

### A two-year-old could press Invest

Reported as a question — "can you invest when you're 2 years old" — and the
answer was that the button was lit, yes.

The controller was never wrong. `LifeSimController.invest` checks
`allows(LifeAction.invest)` and the age table has said 16 the whole time. The
menu row was the problem: it set `disabledReason` from whether you were holding
100 coins and never asked about age at all. So a toddler with 150 coins got a
button that looked pressable, took the tap, and did nothing — `invest` returned
silently. **That is the worst shape a bug can take in a game for children.** It
does not look like a fault, it looks like the game ignoring you.

Two more rows were wrong in the same family without being broken yet: Gamble
hardcoded `age < 18` and Practise tested `stage == LifeStage.baby`, both of
which happened to agree with the controller by coincidence rather than by
construction.

**The fix is structural, because patching three rows leaves the fourth.**
`_LifeAction` now takes a **required** `performs` field naming the
`LifeAction` it runs — nullable, so "this is not a gated action" is an answer
somebody typed rather than a default they inherited — and `_actions` applies
`gatedBy` to every row it returns, in one expression. There is no longer a
place to forget the gate. The row states only its *local* reason ("Not enough
coins", "You have no job to quit") and the age rule is layered on top, with age
winning when both apply: telling a nine-year-old they are short of coins, when
the real answer is that nine-year-olds cannot do this at all, sends them off to
earn money for something that still will not work.

`life_menu_honesty_test` holds the other half — that for every action, at every
age, "the controller allows you" and "calling it changes something" are the
same answer. It is worth being clear that those tests would *not* have caught
the reported bug, because the controller was correct; the widget test in
`life_menu_render_test` is the one that does.

### The menu and the map stopped competing

Two complaints, one cause: "half of these options are irrelevant when you're
going to the map", and the menu and map being a confusing mix.

**The wall of grey.** Activities at age five was eight rows, seven of them
locked, with the single thing a five-year-old can actually do sitting fourth in
the list. Nothing overflowed and nothing clipped, so no layout test could see
it — the screen was technically correct and practically useless. Available
actions now come first and locked ones sit under a heading at the bottom. They
are not removed, because at that age being told what you cannot do yet *is* the
content: it is what makes the early years read as childhood rather than as an
adult life with less money.

The heading has to be chosen rather than fixed, which I got wrong first time.
"When you are older" is true of Activities at five, where age is the only thing
in the way. It is false of Money at five, which locks budgeting because there
is no job yet and money ideas because none have been met — neither of which
growing up fixes. A mixed group says "Not yet" instead.

**The duplication.** The library, the clinic, the park and the job board are
all *places*, and the menu carried a button for each with nothing anywhere
saying they were the same thing. Two routes to one outcome is fine — the map is
not always open to you, and making somebody walk across a town to be treated
would be a worse simulation, not a stricter one. Two routes with no
acknowledgement that they meet is what read as duplication. Those rows now
carry an **in town** tag.

### The town says what day it is

The town already reset every visit and rotated its scenes by day and by age, so
it was never the same twice. It still *read* the same, because nothing on
screen ever said so — and a place that changes invisibly is indistinguishable
from a place that does not change.

`town_conditions.dart` adds a line at the top of the map and prices that follow
it: market day, a sale at the store, a quiet week where the pawn shop pays over
the odds, a month where prices have gone up, a free day at the clinic, rain
that fills the cafe. It teaches the thing a static price list cannot — **the
same item costs different amounts on different days, and noticing is worth
money** — which is the groundwork for comparison shopping and for inflation,
neither of which lands as a sentence in a lesson.

Three things that took thought rather than typing:

* **Ordinary days carry more weight than every special day combined.** If every
  visit were an event, none of them would be one.
* **Buying and selling move independently.** A good week to sell is not a good
  week to buy, and one multiplier for both would quietly teach that a shop's
  prices and its offers rise together.
* **The quoted price had to become the charged price.** The first pass applied
  the discount when charging and printed the list price on the button, so the
  sign said "cheaper than usual today" and the row under it still said -8. A
  discount you only discover by watching your balance afterwards is not a
  lesson about sales, it is a game that cannot be trusted to quote a price.

### The password reset email

Plain, because nobody had ever touched it: Supabase's default template is a
bare `<h2>` and a naked link on a white page, and it goes to the same child
every other screen here is careful with. `tool/build_auth_emails.py` generates
four — reset, signup, magic link, email change.

The markup looks like it is from 2004 because email is. Tables, because Outlook
renders through Word's layout engine. Inline styles, because Gmail strips
`<style>` blocks in several contexts. No external images, because most clients
block them until the reader asks. A button wrapped in its own single-cell
table, because a styled `<a>` arrives in Outlook as blue underlined text.

The one real design decision: the body is **dark-on-light** even though the app
is a dark forest theme. Dark-mode inversion in Gmail and Outlook mangles
hand-set dark palettes far more often than light ones. The header band carries
the brand; the part somebody has to read stays legible everywhere.

They are not bundled — Supabase sends them, so they have to be pasted into the
dashboard. See `docs/auth_emails/README.md`.

### The Play hub was five paragraphs deep before it showed a picture

Reported as "that play menu is pretty bad right now, make more picture than
more card and words", which was exactly right. The hub was a hero card and
then four stacked full-width rows, each carrying a heading and up to two lines
of prose, on the screen whose entire job is to make somebody press something.

Ranked, How to play and Past Lives are now a three-up row of picture tiles —
art you can see, one word, one fact. The prose was not wrong, it was answering
a question nobody had asked yet: you find out what Ranked is by pressing
Ranked, and the epilogue explains the scoring at the point it means something.

The hero card is a **place** now rather than a gradient: the town this launch
rolled behind it, and the player's own chosen character standing in it. That
last part is doing the real work — somebody who spent gold on a skin had no
other screen showing it at size, and "the thing I chose is standing in the
world I am about to enter" beats a sentence describing one.

### Two towns, and the map that could not be played

There is a second town map in the repo that was drawn to be *playable* and
could not be: its collision data was never in the PNG, and three independent
heuristics all read the main promenade as solid, which cuts the town in half.
It had been sitting unused ever since.

A backdrop needs no colliders. `MapVariant` rolls one of the two towns per
**app launch** — not per build, because a `Random()` inside `build` re-rolls on
every setState and the background would flicker between two towns, and not per
screen, because you should not walk out of a Learn screen in one town and into
a Play screen in another. `debugOverride` pins it, since a screenshot of a
randomised backdrop is a coin flip.

### The bottom bar's gold slab

Reported as "for the bottom menu, I don't know what is it doing down there",
which is the correct reaction. The active tab's gold treatment was meant to be
a pill. It was a `Container` with no width inside an `Expanded`, which hands
down a *tight* constraint, so it filled the entire fifth of the bar — a ~190px
block of solid yellow that reads as a rendering fault rather than a selection.

`_HuggingPill` loosens the constraint with a `Center` so the pill sizes to its
own label. The cap on it is the part doing real work: the active tab is painted
at 1.16x by a `Transform`, transforms do not participate in layout, and a pill
that exactly fills its cell paints 16% *outside* it with nothing to catch it.
Capping at `1 / scale` of the cell means the scaled version lands inside by
construction, at every width. Same family of bug as the 192px padding, caught
this time before it shipped.

### The sounds were bare sines

"Make sound more better since right now as a user it's sound pretty bad." My
first guess was onset clicks, and measuring said no — `_write` already de-clicks
both edges and the discontinuities are tiny. The problem was the synthesis
itself: every effect was a sine with integer harmonics, and three things follow
from that.

**No transient.** Real sounds start with a burst of broadband noise — the
finger hitting the surface, the hammer hitting the string. Strip it and the ear
cannot tell what *made* the sound, only what pitch it was. A tap is closer to a
"tok" than to a note, and `tap.wav` was an 880Hz A with a touch of octave,
which is a telephone. **No pitch movement**, when almost nothing physical holds
a dead-flat pitch through its decay. And **integer harmonics only** — 1x, 2x,
3x is a string or a pipe, while bells and glass, which every reward chime is
borrowing from, are inharmonic.

`_struck` takes partials at arbitrary ratios, each with its own decay rate
(upper partials die first, which is why a piano note gets *duller* as it rings
rather than just quieter), over an optional pitch glide with phase accumulated
per partial so the glide is not itself a click. Plus a room, because a sound
with no space around it reads as coming from inside the speaker.

One measurement worth keeping: the first pass turned a 70ms tap into a **0.47s
file**, because the reverb appends its full tail whether or not anything is
left to decay. A tap that rings for half a second is a worse sound than the
beep it replaced, so `_room` now trims back to -54dB off peak. Tap is 0.11s.

### Scams, fees and fine print

The rest of the simulation is about decisions where both options are honest:
save or spend, rent or buy, index fund or savings account. That is most of
financial literacy and it is not all of it. The money a fifteen-year-old
actually loses does not go to a bad investment — it goes to a free trial that
started charging, a subscription nobody cancelled, a \$35 overdraft fee on a \$4
coffee, or somebody very friendly who needed gift cards. None of it was in the
game.

`life_events_traps.dart` adds eleven, written to one rule: **the tell is always
in the prompt.** Urgency, a stranger who found you, a guaranteed return, a
payment method that cannot be reversed. A player who reads carefully can spot
every one, which is the actual transferable skill — and the careful option is
never free, because making caution costless would misrepresent why people do
not take it.

Two of them, `t_loot_box` and `t_skin_gamble`, are pointed at this app's own
machinery. Budget Buddy has a case-opening screen with a ratchet sound on it. A
game that teaches money to children while running an unexamined loot box would
be teaching the wrong thing far more effectively than any lesson teaches the
right one, so the sim names the mechanic and states the house edge.

Swept over 400 runs: every event fires, each in about 40% of lives, 99% of runs
see at least one.

### The screenshot harness had been photographing undecoded images

Worth its own note, because it wasted an hour and the lesson generalises.

Three picture tiles rendered empty. I blamed the widget, added `SizedBox.expand`
to fix a real but unrelated bug (a bare `Image` under a `Column`'s *loose* width
constraint lays out at the source's intrinsic size, so a 16x16 kit icon drew at
16x16 in a 100px slot), and the next screenshot came back with the tiles still
empty *and the hero's map gone too*.

The map disappearing was the tell, because nothing I had touched could affect
it. `tester.pump()` advances a fake clock and drains microtasks; it does not
run real async work, and decoding an `Image.asset` is real async work. Every
screenshot had been taken of a tree whose images had resolved their layout and
never painted a pixel. It stayed hidden for so long because it was not
consistent — an asset already in `imageCache` from an earlier screen in the
same file paints immediately, so the map appeared on some runs and not others,
and that got read as a broken widget rather than a broken harness.

A `runAsync` delay and one more pump before the shutter. The fix also brought
back the endings-row padlocks and the coin icon, which had been silently
missing from every screenshot ever taken.

### Money ideas became a mechanic

**Sixteen concepts, and the simulation did not care about any of them.**
Meeting one produced a chip on a screen and a line in a log. A run played
identically whether you had met all sixteen or none, which quietly said the
opposite of every lesson in the app.

`concept_powers.dart` turns each one into a power you can arm for 6-10 years —
Cushion takes 60% off shocks, Snowball adds 4% to investment growth, Debt Brake
halves interest, Automatic moves a tenth of your pay to savings before you see
it. **You can only arm an idea you have actually met in that run**, so the
route to a strong run goes through understanding, and a player optimising for
score is optimising for learning without being told to. Two at a time, so it is
a choice about which.

### Starvation and illness, and three rounds of getting them wrong

The point was to give the emergency fund something to be *for*. The first pass
gave it a graveyard instead: **average life 35, 86% of runs dead before sixty.**

The cause was not the numbers, it was a missing world. Taking the first option
every year usually means never getting a job, so *every* adult year was a
starving year. That is not a simulation of being poor, it is a simulation of
having nobody around you. There is a scraped-income floor now — rolled 62-98%
of living costs each year, **rolled and not fixed**, because a flat rate made
the shortfall identical every year, always under the threshold, and hunger
mathematically unreachable. Savings absorb the gap before hunger starts, and
eating again restores health, because a one-way ratchet is a hole you cannot
climb out of.

Illness got a **distinct job from expense shocks**. The first version priced it
like a car repair, and six years of disciplined 20% saving came out at a fund
of zero — the exact opposite of what the emergency fund exists to demonstrate.
An expense shock takes your money; an illness takes your *health* and lingers
for years, and where they overlap illness is the smaller number.

Two of the test failures on the way were real bugs rather than noise: a
dependent child was paying their own medical bills, and `budget_teaching_test`
was banking **one** year of savings while believing it banked six, because a
pending event blocks `ageUp`.

### Buying a guitar, and where it can end up

The music ladder already existed and topped out at a sixteen-city tour worth
£4,200 — a good year, not a life change. `life_events_stardom.dart` adds the
rest: busking, a viral clip, a label advance, arena years, and an $800,000
offer for your back catalogue.

It is not a jackpot, because a jackpot teaches nothing. Fame arrives with
almost no money attached, because being known and being paid are different
columns. The advance is explicitly a loan against yourself. The catalogue sale
is the same decision as a redundancy payout at a scale that makes the answer
feel like it matters. And `stardom_spent_it` is reachable, because it is the
most common real ending for this story.

**Balancing it took four attempts and the sweep caught every one.** The peak
and its ending fought over the same window: heavier on the ending and
`x_stadium_years` never fired, heavier on the peak and `stardom_faded` never
did. A `maxAge` cap on the peak looked like the fix and made it worse —
measuring when players actually become famous gave ages 24, 26, 36, 44, 49 and
63, so a lid at 38 locked out most of the people who got there. And the peak's
original gates (skill 70, fame 45) sat *above* what the rungs below it can
deliver, which is not a hard event, it is an absent one.

### Ranked

One life, scored, same rules. Wealth carries most of it on a square root — a
linear score would make one lucky stardom draw worth more than every other
decision in the game combined, and a leaderboard that ranks "did you get the
guitar event" is not ranking anything.

Survival is a **multiplier, not a bonus**, because dying at thirty-five with a
fortune should not beat retiring at eighty with less, and a multiplier is the
only shape that makes that trade real. Understanding adds a modest amount per
idea met: enough to be worth learning something, never enough to replace a
financial life. No F grade — this is a financial-literacy app for children, and
a screen that tells a nine-year-old they failed at a life is not worth
building.

### The Life bar had four dead labels and a missing button

**`horizontal: 192` inside an `Expanded`**
The five slots along the bottom of the life sim each sit in an `Expanded`, so
each gets about 178px on a normal window. `_MenuButton` asked for 192px of
padding *a side* — 384px of padding for a 178px slot — so every child was
handed zero width. The `FittedLabel` scaled to nothing and vanished, the `Icon`
painted outside its box, and Money got pushed off the end. Four unlabelled
icons and a missing fifth button.
**Nothing errored**, and that is the interesting part: a `Column` only reports
overflow on its *main* axis, which is vertical, so a child too wide for its box
paints over the edge in silence. `responsive_layout_test` saw no exception
because there was none to see.
*Fix:* `horizontal: 4`.
*Files:* `life_sim_page.dart`

**And the audit that should have caught it was skipping exactly this case**
`text_fit_test.dart` read `if (available <= 0) continue;` — a label with *no*
room was treated as uninteresting and waved through. It is the worst case, not
the boring one.
*Fix:* zero width is now a finding of its own. Put the 192 back and the suite
names all four labels; that was checked rather than assumed.
*Files:* `test/text_fit_test.dart`

### The budget and habit analyser

**The app counted plenty and advised nothing.** Gold, XP, literacy points, jar
fill, lives played — all of it is a number telling you where you are, and none
of it tells you which single thing to change. "Here are eleven metrics" is how
most money apps quietly hand the hard part back to the user.

`money_analyzer.dart` is `MoneySnapshot` in, `MoneyReport` out, with no Flutter
in it. Every finding has three parts and is useless without all of them:

* **evidence** — a number out of *their* data. "You have 7 habits saved and
  logged 2 of them in the last fortnight" is arguing with somebody about their
  own week, which is much harder to shrug off than "consistency is important".
* **one action**, small enough to do today. A finding ending in "consider
  reviewing your spending" is decoration.
* **a concept**, where there is one, so the finding hands off to the lesson
  that explains it and through that to the lesson's source. The Academy
  refuses to ship an uncited fact; advice does not get a free pass either.

Five areas are scored **separately** — showing up, money moving, finishing,
understanding, trying things — because somebody can be extremely consistent and
save nothing, or save well and understand none of it, and one blended "money
score" hides the only interesting part.

The rule that matters most is `motion_not_money`: habit points, jar fill and
streaks are all satisfying and none of them is money. It is entirely possible
to be a model user of this app and be no better off, and if that is happening
the analyser has to be the thing that says so.

Two things it deliberately will not do. A brand-new player gets **one** line
rather than five red zeroes — every rule would fire, all of them would be true
and none would be useful. And a concept that was never assessed is *absent*,
not scored zero: telling somebody they are weak at a lesson they have never
opened is the fastest way to make an analyser worth ignoring.
*Files:* `money_analyzer.dart`, `money_snapshot_source.dart`,
`money_habits_screen.dart`, `test/money_analyzer_test.dart`

### The town becomes the game

**Twelve buildings, not six**
The first six cover the money decisions a school lesson would list. The second
six cover the ones a *week* contains: a market with no unit prices, a cafe you
have been in three times already, a clinic that charges $40 or nine days, a
library that gives away what other people sell, a pawn shop that prices metal
rather than meaning, and a park where the free option is the one you have to
choose on purpose. Four rotating scenes each, so the town now holds 69
encounters.
*Files:* `town_spot_models.dart`, `town_scenarios.dart`

**Every building said the same thing at seven as it did at seventy**
The rotation was keyed on the calendar day, which is right for somebody
wandering the town on its own and wrong the moment it is part of a run — a life
plays sixty-odd years inside one afternoon. Walking back into the bank a decade
later to find the identical conversation is the clearest way to tell a player
that nothing they do out there matters.
*Fix:* the character's age is mixed into the draw alongside the day.

**And the age is hashed, not multiplied** — the first version used `age * 17`,
and the test that samples ages ten years apart found *every* sample landing on
the same scene. That is not a bad constant, it is arithmetic: a spot with five
scenes takes the index mod 5, and `10 * m` is divisible by 5 for every m, so no
linear mix survives a player ageing in round decades. Which is exactly how
somebody skims a life.
*Files:* `town_scenarios.dart`, `town_interior_screen.dart`

**The menu could play the whole game without opening the map**
The library, the clinic, the park and the job board are all *places*, and the
Life menu had a button for each.
*Fix, second attempt:* the first one blocked those buttons whenever the town
was open, and three suites objected within a minute — `life_age_gates_test`
asserts seeing a doctor is never blocked, `budget_teaching_test` asserts an
adult with no job can always find one, and the library is the only way to raise
Smarts on demand. They were right. A doctor you have to walk to is a worse
simulation, not a more realistic one, and the map is not always open to you
anyway.
So the menu keeps every door and **pays less** for using them: reading at home
is +2 Smarts against the library's +4-and-change through `applyTownOutcome`, an
afternoon in is +6 Happiness against the park's more. Going in person is
better; staying in is still allowed. That is also true.
*Files:* `life_sim_controller.dart`

### Friends, the tutorial, and the town

**Adding a friend failed with 42501, and it is not a code bug**
Probing the live database directly with the anon key returns the exact error
the app shows:

    42501 - new row violates row-level security policy for table "friendships"

Note *which* 42501. "permission denied for table" would mean the GRANT is
missing; this wording means the grant is fine and there is no INSERT **policy**
that accepts the row. The table exists and SELECT works, so it was created and
RLS was switched on, and the policies were never applied — and with RLS on and
no policy, every write is refused. The client side is correct: `stats.id` is
the Supabase auth uid whenever somebody is signed in, so the row it writes does
satisfy `with check (user_id = auth.uid())` once that policy exists.
*Fix:* `supabase/migrations/0002_friendships_rls.sql`, which has to be run in
the Supabase SQL editor — DDL is not something the anon key can do. The app's
message for 42501 now says that instead of printing the raw code, because the
raw code is what a player saw: not their fault, and retrying will never work.
*Files:* `supabase/migrations/0002_friendships_rls.sql`, `supabase_service.dart`

**The tutorial card was placed from a guess at its own height**
The coach mark's `top` was computed from `190 * scale` — a constant standing in
for something that varies with how the copy wraps, whether a Back button is
showing, and the reader's text scale. Whenever the real card was taller, the
maths meant to keep it clear of the spotlight put it *over* the spotlight, and
the clamp meant to keep it on screen let it hang off the bottom. Everything
else about the placement was already proportional; this one number was not, and
it was the one that decided where the box went.
*Fix:* a `SingleChildLayoutDelegate`, which is handed the child's measured size
before it has to say where the child goes. One layout pass, no second frame, no
flicker — and with the real height it can also **flip sides** when the
preferred one genuinely does not fit, which an estimate could not decide.
`tutorial_test.dart` now walks every step at six viewports asserting the card is
fully on screen and never overlapping the bar it is describing.
*Files:* `coach_mark.dart`, `test/tutorial_test.dart`

**The main game had no tutorial of its own**
The app tour has one step on Life, and Life is the main game: an age button,
four money boxes, a stat row, a chain-flag strip, four sub-menus and a door to
the town. "Press the big Age button" is the right depth when you are being
shown around a tab and nowhere near enough when you are standing in the game.
The quiet failure is a player who ages up, reads an event, picks an option, and
never finds the money panel, the town or the career menu — playing the
simulation as a multiple-choice quiz, which is the one reading of it that
teaches nothing.
*Fix:* `kLifeTutorialSteps`, seven steps run over the real widgets through the
existing `TutorialTargets` registry, started automatically on a player's first
life and replayable from "How to play" on the Life hub. Deliberately *not* a
button in the game's own app bar: that bar already carries a name, age, job and
balance beside two actions, and adding a third squeezed the name column to 58px
on a 320px phone — "Alex Morgan" needs 96.
*Files:* `life_tutorial_steps.dart`, `life_sim_page.dart`, `main_game_page.dart`

**The town had no effect on the life it was opened from**
Walking into a building changed the *account* — gold, XP, literacy points — and
nothing about the character. So the one part of the app where you physically go
somewhere to make a money decision had no bearing on the money simulation that
launched it, and the town read as a side attraction.
*Fix:* `LifeSimController.applyTownOutcome`. The mapping is deliberately not
one-to-one: town gold is spending money so it lands on cash, literacy is what
you understood so it lands on smarts, and XP is having turned up at all, so it
is the smallest of the three.
*Files:* `life_sim_controller.dart`, `adventure_world_screen.dart`

**Coin Cascade stopped at level 7**
About twenty minutes of play, after which `cascadeLevelFor` silently returns
the last level for ever — so the ladder ended without saying so.
*Fix:* thirteen levels, and a test that each one differs from the one before it
on a *rule* dial rather than only on its numbers. A ladder that just raises the
target is a grind wearing a progression's clothes.
*Files:* `coin_cascade_models.dart`, `test/coin_cascade_test.dart`

### The side-facing walk, sixth attempt

**The head in profile was three mistakes stacked on each other.** Read back at
its true resolution the sheet is 8x4 cells of 104x162, and the west row says:

* *The crown is drawn flat.* From the front the head is six pixels wide at the
  crown; in profile it is **two**. A head seen from the side is at least as
  deep as it is wide, so reusing the front crown turns it into a spike.
* *The face is a three-pixel notch, one row proud of the row above it.* That
  step, under the spike, is what read as a beak.
* *The head is redrawn differently in every frame* — frame 0's crown spans four
  columns, frame 2's seven, frame 5's five. A walk cycle bobs a head; it does
  not reshape it. That was the "shifting pixels".

**Why the five previous attempts failed, which matters more.** Every one of
them assumed the sheet was a single clean grid — 14x27 logical pixels at 5x,
anchored at (6, 12) in every cell. Measuring it says otherwise:

* Each frame has *its own* origin. Frames 0 and 4 start at y=12, frames 1/3/5/7
  at y=10, frames 2 and 6 at y=5, and horizontally at x=6, 12 and 2. None of
  those differences is a multiple of the block size, so a fixed grid reads
  frames 1-7 at the wrong phase — coherent enough to *look* at, wrong to
  *write* to.
* Vertically the sheet is a clean 5px grid within each frame. **Horizontally it
  is not.** No phase makes the column groups uniform, so the art was scaled
  unevenly at some point in its history. Stamping fixed 5x5 blocks therefore
  lands half a block off — which is precisely the symptom the redraws were
  supposed to cure.

*Fix:* `tool/redraw_side_profile.py` works from each frame's own measured
geometry — its vertical grid, its coat colour to find where the torso starts,
the raw x-range of its own neck to centre on. The head is rendered at 1:1 and
scaled once, so its blocks are exactly even whatever the sheet around it does.
Only the head is replaced; the neck row and everything below is untouched,
which keeps the men's collars and the women's ponytails attached to the bodies
they were drawn for. East is rebuilt as a per-frame mirror of west, which it
already was in all 38 sheets.

Two smaller things fell out of it: the women's ponytail root sits outside the
new head on the frames where the arm swings forward, so the hair at the back of
the head is drawn out to meet whatever hair the body carries; and the head's
bottom row is outlined along the back for the men and continues as hair for the
women, decided per sheet by reading what is underneath.

*The guardrail that was missing before:* the tool is dry by default. It writes
a magnified before/after to `build/sprite/` and touches nothing until
`--write`. Every earlier attempt was saved first and looked at afterwards.

### Things only a screenshot could find

`test/screen_render_test.dart` renders every main screen to `build/screens/`
and asserts nothing. It exists because the three audits that *do* assert —
contrast, text fit, viewport overflow — can only fail on things they know how
to describe, and the following are not among them. Every one of these was
found by opening the PNGs and looking at them.

**A brand-new player was greeted by a frowning jar labelled "Slipping"**
`JarMood.forDaysSinceActive` maps a gap of five days or more onto "slipping",
and `HabitDateKeys.daysSince` returns **999** when there is no last-active
date at all. So somebody who installed the app a minute ago got the lapsed
face, the lapsed colour, and the sentence "It has been 999 days".
*Fix:* `jarEverActive`, and a jar that has never moved reads as steady. Not
started and lapsed are different states and should not wear the same face. The
copy branches too: "Nothing in the jar yet. Save one habit on Track and log it
once" rather than a day count for a streak nobody was given a chance to start.
*Files:* `money_habit_controller.dart`, `money_habits_screen.dart`

**The Academy's reading screens put body text on a pixel tilemap**
The lesson, quiz and practice screens paint the village map behind their
content under a translucent scrim. Measured against the real asset that scrim
was fine on paper: white text over the *brightest* pixel in the map came out at
4.53:1, which clears WCAG AA. It still read badly, and the numbers say why —
under the 0.74 scrim the backdrop ranged from **4.53:1 to 12.4:1** depending on
which tile a given letter happened to land on, and the map's detail sits at
roughly the scale of a letterform. A contrast ratio describes one pixel against
one background. It cannot describe a background that changes underneath a word.
This is also why the audit passed it: text over an image is skipped rather than
guessed at.
*Fix:* take the structure out instead of turning the lights down.
`tool/make_reading_backdrop.py` emits a blurred, slightly desaturated copy of
the same map; that collapses the spread from 7.9 points to **2.2**, with a
floor of 6.5:1. Blurring at build time rather than with `ImageFiltered` keeps
it free at runtime — it is a static image behind a scrolling list. The seven
screens that paint this map had drifted to four different scrim alphas with
nothing recording why, so they now share a `MapBackdrop` widget with three
named strengths.
*Files:* `map_backdrop.dart`, `tool/make_reading_backdrop.py`,
`lesson_detail_screen.dart`, `practice_screen.dart`

**"Welcome Back" sat on pale water tiles**
The launch screen — the first thing anybody sees — laid its wordmark and both
buttons over the busiest block of the map, at the exact point where the
screen's own radial glow was *lightening* the background.
*Fix:* `MapBackdropStyle.hero` keeps the art sharp and vivid through the top
fifth and deepens to a calm band by the halfway mark, where the wordmark and
buttons live. Blurring this one would have thrown away the first impression;
the answer was to move the darkness to where the text is.
*Files:* `map_backdrop.dart`, `welcome_screen.dart`

**Buddy's tip stopped mid-word**
Capped at two lines, the longest explainer rendered as "A want is everything
el…". Truncating body copy is a design; truncating it four characters into a
word is a bug wearing the design's clothes.
*Fix:* three lines. The card sizes to its content, so it costs about sixteen
points of height.
*Files:* `mentor_tip_card.dart`

**The Academy opened with its selected unit chip cut off**
The unit strip is grouped by age band, so the first thing in it is a ~174px age
header and the second is the selected chip at 196px — 6px more than a 390px
phone has. The one chip that has to be readable was the one being clipped.
Underneath that, the strip's scroll estimate carried its own hardcoded chip
width of 156 and kept it when the chip's declared minimum went to 196 to stop
unit *titles* being clipped. Nothing connected the two, so every jump landed
40px per chip short of its target — almost half a screen by the end of a
thirteen-unit strip.
*Fix:* one `unitChipMinWidth` constant read by the chip, the estimate and the
test; and the selected chip is scrolled into view on the first frame rather
than only when tapped.
*Files:* `lesson_screen.dart`, `test/unit_chip_test.dart`

**The Emerald Case said it sold turtles**
"Spend 180 gold for a Common, Rare, Epic, Legendary or Mythic **turtle** skin"
— while the case draws from all 24 skins: four turtles, nineteen villagers and
a critter. Naming one family made the other twenty look like they were not in
the pool.
*Files:* `customize_screen.dart`

## Where to read next

* **`docs/CONGRESSIONAL_APP_CHALLENGE.md`** — the submission write-up: what the
  app is, how it teaches, what each page does and how it was built. Start here
  if you want the whole thing in one read.
* **`docs/PAGES.md`** — every screen in the app: what a player does there, what
  it teaches, and where its state comes from. Start here if you are working on
  a screen you have not seen before.
* **`docs/ARCHITECTURE.md`** — the running log of changes, in order, with the
  reasoning behind each one.
* **`docs/ADVENTURE_TOWN.md`**, **`docs/MONEY_HABITS_FEATURE.md`**,
  **`docs/CHALLENGES.md`**, **`docs/ONBOARDING_AND_RECORDS.md`** — deep dives on
  individual systems.

---

## Testing

```bash
flutter analyze && flutter test
```

1,232 tests covering responsive layout at eight viewports (including the Life
sim itself, Feedback, and the Adventure map-pending screen), the money
panel at seven widths, the life-event chain wiring, price-chart zoom/pan/scrub,
chart painters against pathological input, working-order accounting, the Life
simulation rules and its budgeting model, town-map reachability, the side-walk
frame selection, candle caching, the quiz bank, and asset integrity.

Two of those suites are worth calling out because they measure rendered output
rather than logic:

* **`contrast_audit_test.dart`** walks the real widget tree of nine screens and
  fails on any text below WCAG AA (4.5:1, relaxed to 3:1 for large or bold
  text, which is the standard's own allowance). It found 47 illegible labels on
  its first run. Anything it cannot resolve — text over a sprite, over a
  `CustomPaint` — is skipped rather than guessed at, and emoji are excluded
  because they are colour bitmaps that ignore the declared text colour.
* **`pixel_kit_test.dart`** decodes the generated UI-pack PNGs and checks that
  each surface's declared colour and ink constants still match the art, so a
  change to `tool/build_ui_pack.py` fails the build instead of quietly making
  those constants wrong.
* **`playtest_test.dart`** opens each of seventeen screens and *presses every
  control on it*, one at a time, rebuilding between presses. The other suites
  check that a screen paints; almost every bug reported in this project came
  from an interaction — a sensor firing during build, a dialog over a scrolling
  list, a state change on a disposed screen. The town interiors are in the list
  specifically because they open a scenario dialog on entry, so the first press
  lands on the dialog rather than on the page underneath.
* **`text_fit_test.dart`** asks the renderer which single-line labels ran out
  of room, across 23 screens at the narrowest phone and in landscape. A
  one-line cap is a promise that the text fits, so a paragraph reporting
  `didExceedMaxLines` is that promise being broken.
* **`app_fonts_loaded_test.dart`** guards the thing the three suites above now
  rest on: that they are measuring Pixelify Sans and Quicksand rather than the
  test fallback. The fallback is monospaced at exactly the font size, so an `M`
  and an `i` come out the same width — that is what it checks, per face.
* **`screen_render_test.dart`** renders each screen to `build/screens/` and
  asserts nothing at all. The audits catch what they can describe; this is for
  everything else, and it has earned its place — see the section above.
* **`savings_jar_test.dart`** renders the coin jar and reads the pixels back —
  gold rises with the fill, the coin line climbs with it, and the mouth curves
  the right way per mood. It exists because the mouth's sign was inverted for
  months without anyone being able to see it in source.
* **`case_roll_sync_test.dart`** reads the roll duration, tile count and easing
  curve out of both `customize_screen.dart` and `tool/make_sounds.py`, because
  the pre-rendered ratchet only lines up with the reel while those agree and
  nothing in the compiler links the two.
* **`lesson_sources_test.dart`** is the one the curriculum's credibility rests
  on: it fails the build if any lesson ships without a citation, if a citation
  points at a source that does not exist, if a source is not HTTPS or not on
  the trusted-publisher allowlist, or if a source is defined and never used.
* **`coin_cascade_test.dart`** drives the match-3 engine through whole runs —
  including an assertion that a bot taking the first legal swap it sees does
  *not* always win, because a game a random player always wins has no decisions
  in it.
