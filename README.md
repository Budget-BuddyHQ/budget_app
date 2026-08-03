# Budget Buddy

A Flutter app that teaches teenagers financial literacy through play.

The app has three pillars:

| Pillar | What it is | Where |
| --- | --- | --- |
| **Life** (main game) | A BitLife-style life simulator. You are born, age up one year at a time, and your choices move Happiness, Health, Smarts, Looks and money. | `lib/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart` |
| **Market Board** | A Webull-style stock trading board using **real live market data**, priced in in-game coins. Opens on a "Trending Now" strip of real company logos (Wikimedia Commons — `assets/images/stock_logos/`, ~88KB total across 6 tickers) over the always-on ticker tape. | `lib/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart` |
| **Academy** | Khan-Academy-style units of lessons, quizzes and unit tests. Units badge "Recommended for you" against the player's self-described age band — a signal only, never a lock; every unit still unlocks purely by finishing the previous one's test. | `lib/screens_minigames_admin_etc/Gameplay/academy/` |

Supporting features: auth (login / sign-up / welcome), profile, skins &
customization, daily quests, leaderboard, arcade mini-games, in-app feedback
(`lib/screens_minigames_admin_etc/profile/feedback_screen.dart`, toggleable via
`kFeedbackEnabled` in `lib/config/dev_preview_flags.dart`), an admin page, and
an in-progress **Adventure** RPG overworld built on the `bonfire` engine
(`lib/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart`).
It's fully wired (player, joystick, camera) but has no map yet — see
`assets/images/maps/README.md` for exactly where to drop one; until then it
shows a "map on the way" placeholder instead of a blank/broken screen.

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
| Config / API keys | `tool/README.md` |
| How auth → username → gameplay data → "analytics" fit together | `docs/ARCHITECTURE.md` |

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

### Layout

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
roughly evenly across all four positions (currently 13/15/18/13 across 59
questions in `quiz_bank.dart`). Options are not shuffled at runtime — the fix
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

144 tests covering responsive layout at seven viewports (now including
Feedback and the Adventure map-pending screen), chart painters against
pathological input, working-order accounting, the Life simulation rules, the
quiz bank, and asset integrity.
