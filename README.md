# Budget Buddy

A Flutter app that teaches teenagers financial literacy through play.

The app has three pillars:

| Pillar | What it is | Where |
| --- | --- | --- |
| **Life** (main game) | A BitLife-style life simulator. You are born, age up one year at a time, and your choices move Happiness, Health, Smarts, Looks and money. Ends on one of 7 distinct **ending archetypes** (`life_ending.dart`) resolved from your final stats, shown on a dedicated epilogue recap screen instead of the old silent pop-back. | `lib/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart` |
| **Market Board** | A Webull-style stock trading board using **real live market data**, priced in in-game coins. Opens on a "Trending Now" strip of real company logos (Wikimedia Commons — `assets/images/stock_logos/`, ~88KB total across 6 tickers) over the always-on ticker tape. | `lib/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart` |
| **Academy** | Khan-Academy-style units of lessons, quizzes and unit tests — 9 units, each with its own accent colour. Units badge "Recommended for you" against the player's self-described age band — a signal only, never a lock; every unit still unlocks purely by finishing the previous one's test. **Unit 5 includes Taxes and Withholding**, and **Unit 6 (Stocks and Trading) pays out real gold and tradeable shares** via `kLessonPayouts`. | `lib/screens_minigames_admin_etc/Gameplay/academy/` |

Supporting features: auth (login / sign-up / welcome), profile, skins &
customization, daily quests, leaderboard, arcade mini-games, in-app feedback
(`lib/screens_minigames_admin_etc/profile/feedback_screen.dart`, toggleable via
`kFeedbackEnabled` in `lib/config/dev_preview_flags.dart`), an admin page, and
an in-progress **Adventure** RPG overworld built on the `bonfire` engine
(`lib/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart`).
It's fully wired (player, joystick, camera) but has no map yet — see
`assets/images/maps/README.md` for exactly where to drop one; until then it
shows a "map on the way" placeholder instead of a blank/broken screen.

**Sound effects are off by default.** The bundled SFX (`AppSoundService`,
`assets/audio/`) read as harsh rather than subtle, so `enabled` now defaults
to `false` — the toggle in Profile still works for anyone who wants them on
in the meantime. See `docs/ARCHITECTURE.md` for details.

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

### Layout

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

144 tests covering responsive layout at seven viewports (now including
Feedback and the Adventure map-pending screen), chart painters against
pathological input, working-order accounting, the Life simulation rules, the
quiz bank, and asset integrity.
