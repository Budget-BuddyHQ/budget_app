# Every page in Budget Buddy, and what it does

A map of the app: what each screen is for, what a player does there, what it
teaches, and where its state comes from. Written for someone who has to work
on a screen they have not seen before — so each entry says *why* the page
exists as well as what is on it, because most of the non-obvious decisions in
this app are about teaching rather than about code.

`docs/ARCHITECTURE.md` is the running log of *changes*; this is the
description of the app as it stands.

---

## How the app is put together

```
main.dart
 └─ MainNavigation                 the shell: top bar + IndexedStack + bottom bar
     ├─ [0] MainGamePage           Life  · the main game's front door
     ├─ [1] MinigamesPage          Arcade
     ├─ [2] HomeScreen             Home
     ├─ [3] LearningPathScreen     Learn
     ├─ [4] CustomizeScreen        Style
     ├─ [5] MoneyHabitsScreen      Daily  (top bar)
     └─ [6] ProfileScreen          Profile (top bar)
```

**Seven screens, five bottom tabs.** Daily and Profile moved to the top bar
because seven items across the bottom read as crowded. `AppTabIndex` names
every slot; nothing outside `main_navigation.dart` and that file's doc comment
uses a literal index.

**Every screen stays alive.** `IndexedStack` keeps all seven mounted, so
switching tabs preserves scroll position and in-progress state. That has one
consequence worth knowing: a `GlobalKey` inside a tab is a key inside *seven
live widgets*, which is why the tutorial's coach marks derive the bottom bar's
geometry from layout instead (see `coach_mark.dart`).

**State lives in controllers, not screens.** `UserStatsController` is the
single source of truth for gold, XP, literacy, unlocks and the `spending_habits`
JSON blob everything else hangs off; `MoneyHabitController`, `DailyPlanController`
and `AppSettingsController` are narrower views onto the same store. Screens
read through `context.watch`, and a screen that owns transient state (a running
game, an open quiz) keeps it in its own `State`.

---

## The shell

### `MainNavigation`
The frame every tab is drawn inside. Owns the tab index, the top bar (Daily ·
Budget Buddy · 🏆 · Profile), and the first-run sequence: the guided tour, then
the personal-details sheet, queued so the two never stack.

It also draws the tour. `CoachMarkOverlay` is a **layer over the live app**
rather than a pushed route, which is the entire point of it — a full-screen
deck teaches the idea of a feature and never its location, so a player who read
it still had to go and find everything afterwards.

---

## Home

### `HomeScreen` — "what should I do right now?"
The landing tab. Its job is to answer one question — what should I do next —
because an app with seven tabs and no answer to that is a menu, not a game.

Top to bottom:

* **The reef** (`ReefScene`, `reef_scene.dart`). Home is an underwater scene
  rather than a column of cards on a tiled pattern: water graded from teal to
  deep, light shafts, a sea floor with seaweed, coral and rocks, fish crossing
  it and bubbles going up through it, all drawn from the underwater art pack
  in `assets/map_assets_coins/underwater_UI_svgs/`. The hero card is a full
  reef; the page behind it is the same widget at a darker grade with the
  bright near floor switched off, so the background is a place without
  competing with the content on it. The mascot is a turtle, which is the
  short version of why this and not something else.
* **The hero** — the player's turtle in that reef, level and gold as HUD pills
  (the gold figure in `MoneyGlyphs`, the pack's own display numerals, not a
  text font), and one primary action: Start a Life.
* **Today** (`_TodayCard`) — the streak, how far through today's plan you are,
  and the single next quest. Tapping it switches to the Daily tab, where the
  whole plan lives. `DailyPlanController` builds that plan from what the
  player has and has not done.
* **Buddy's tip** — one mentor card.
* **Level and destinations** — level progress and five tiles into Adventure,
  Daily, Arcade, Academy and Style.
* **Leaderboard promo.**

### `DashboardShell`
The route `/game` lands on. A thin wrapper that hosts `MainNavigation`; kept
separate so a deep link can open the app at a specific tab.

---

## The main game

### `MainGamePage` — Life's front door
Not the game itself: a hub with **Play Life**, **Past Lives**, and the endings
gallery. The sky behind it changes with the device clock (`DayNightSky`).

Sits in front of the sim on purpose. A life takes several minutes and ends
permanently, so dropping a player straight into one removes the moment where
they decide to start.

### `LifeSimPage` — the main game
A BitLife-shaped life simulation with an open-world half. You age one year at a
time; each year offers an event with real choices, and your money, happiness,
health and smarts move with them.

* **The feed** is the year's events, choices and outcomes, newest last.
* **The money panel** (`life_money_panel.dart`) shows cash, savings,
  investments and debt as four boxes — *always all four*, including the empty
  ones, because an empty savings box is the lesson.
* **The stat meters** are smarts / health / looks, and the "this year" panel
  surfaces the weather and household rules that gate what you can do.
* **Town** hands off to the Adventure map, where a decision means walking
  somewhere first.

What it teaches: that money decisions compound over a life. The budget sheet,
the expense shocks and the age gates are all load-bearing — see the
teaching-layer note in `docs/ARCHITECTURE.md` before changing them.

### `LifeEpilogueScreen`
How a life ended, with an archetype (Legacy Builder, Rich but Lonely…), the
final numbers, and the gold it earned. Each ending has its own portrait, so the
result is a *character* rather than a scoreboard.

### `PastLivesScreen`
Every life you have finished. Makes the game a series rather than a one-off, and
gives the endings gallery something to fill.

### `LifeCharacterSheet`
The full stat/flag readout for the current life — what the feed summarises.

---

## Adventure (the town)

### `AdventureWorldScreen`
A tile map you walk around with six interactable buildings. Bonfire/Flame
render the map; movement picks frames out of the villager sheets
(`kSideWalkFrames`, `kSideIdleFrame`).

Walking there is the game; the decision is the lesson. The same money question
asked on a feed and asked after a walk are not the same experience.

### `TownInteriorScreen`
What happens inside a building: a prompt and two to four choices, each with an
outcome line that explains the money idea rather than scoring it.

**Encounters rotate by day *and* by your age.** 69 scenarios across twelve
buildings live in `town_scenarios.dart`, and the town picks from the date and
the character's age: fixed within a visit so the place has a state you can plan
around, different tomorrow and different a decade later. The age is *hashed*
into the draw rather than multiplied — a linear mix repeats for a player
ageing in round decades, which is how most people skim a life.
The per-spot floor is five rather than two, because the rotation is by *day*
and at two scenes a building repeats itself every other day, which is about how
often somebody actually plays.

Every encounter has at least one option that costs nothing, and
`town_scenarios_test.dart` fails the build on one that does not — a scene where
spending is compulsory teaches the opposite of the point. The free option has
to be a real money behaviour, not a "do nothing" button: read the labels and
buy neither today, pack lunch from the cupboard, read the meter yourself before
paying the bill.

---

## Arcade

### `MinigamesPage`
The catalogue. Each card says what you do, what it teaches, how hard it is and
how long a run takes, so a player can pick something that fits the time they
have.

### `CoinCascadePage` — match three
The game for everybody: a four-year-old can play it by matching pictures. The
budgeting is in the **mechanics**, not in a quiz bolted on —

| Tile | Effect |
|---|---|
| 🥫 Need | pays your bills down |
| 🎮 Want | scores best, and raises what you owe |
| 🐷 Save | the only thing that reaches the goal |
| 🪙 Coin | buys extra moves |
| 🧾 Bill | arrives on a schedule; clearing it is defence |

Chase the biggest matches and you lose. Cover needs, keep wants in check, bank
the rest and you win — 50/30/20 with the numbers taken out. The engine
(`coin_cascade_models.dart`) is pure Dart and separately tested.

### `FinanceBrawlScreen` — survival + quiz
Waves of debts to pay off. Clearing enough triggers a **level-up** with three
offers drawn from nine levelled tracks (fire rate, pierce, spread, splash, ring,
streams, damage, shield, speed). Maxed tracks leave the pool, so the choices
narrow as a run goes on and late picks are between things you actually want.

Every few waves a **literacy checkpoint** interrupts with three questions from
a 140-question bank (100 in the game file, 40 more in
`brawl_questions_extra.dart` — twenty each on earning and work, and on scams,
fees and fine print, the two areas the original bank was thinnest on and the
two an under-21 player meets first).
Options are shuffled per encounter and matched by *text*, so no answer is ever
findable by position.

### `StockMarketPage` — the Market Board
Real quotes from Finnhub, candles from Twelve Data, a pan/zoom/scrub chart,
company logos and a portfolio with P&L history. Ten coins to the dollar and
fractional shares, so a player with a few hundred coins can hold something real.

Teaches risk and volatility with actual market data, which no simulated ticker
does as well.

### `ReactChallengeScreen`
Snap judgement on everyday money calls. Short, and the easiest thing in the
arcade to pick up.

---

## Learn (the Academy)

### `LearningPathScreen` / `LessonScreen`
The curriculum: **13 units, 63 lessons, 13 quizzes, 13 unit tests** and 186
questions, ordered by age from "what is money" (4–6) to protecting your money
as an adult. Units sort by age
stage and a unit above the reader's band shows a warning rather than a lock —
the gate is finishing the previous unit's test, not being old enough.

Also carries the **credibility card**: how many lessons, how many questions,
which publishers, and one tap to the full source list.

### `LessonDetailScreen`
One lesson: objectives, sections, a worked example scaled to the reader's life
stage (a 13-year-old sees allowance-sized numbers, an adult rent-sized ones),
key terms, a takeaway — and **sources**.

Every lesson cites primary publishers (CFPB, SEC/Investor.gov, IRS, SSA, FDIC,
FTC, BLS, DoL, Federal Student Aid, Treasury). `lesson_sources_test.dart` fails
the build if any lesson ships uncited, so "every lesson is sourced" is a
guarantee rather than a claim.

### `PracticeScreen`
Extra questions for one unit, drawn toward the skills you have missed.

### `quiz_widgets.dart`
The question and results cards. The results screen groups misses by *topic*
rather than listing questions back, and puts a source link under each topic you
got wrong — the moment a citation is worth most, because you have just been
told an answer you did not expect.

---

## Daily (Money Habits)

### `MoneyHabitsScreen`
Titled **Daily** when it is the tab (which is what the top strip's Daily
button opens) and **Money Habits** when it is pushed as a route. Six inner
tabs — index them through `MoneyHabitsTab`, never a literal:

* **Today** — the one that answers "what do I do now": a seven-day streak
  strip, today's ordered plan (`DailyPlanCard`, fed by `DailyPlanController`),
  and the daily reflex challenge. Everything below it is the habit tracker.
* **My Week** — the habits you have pinned and a seven-day tracker.
* **Find/Create Habits** — the catalogue, plus custom habits.
* **Challenges** — multi-step paths (Cut the Spending Leaks, Build Your
  Savings) whose steps unlock in order.
* **My Jar** — the payoff screen. A painted glass jar fills with coins as you
  earn habit points, with the four milestones shown as a ladder, your lifetime
  money-saved and good-calls totals, and a next-step card that says what to do
  rather than what is true.

The jar's fill is a fraction of the **whole** ladder, not of the current stage —
stage-relative progress resets to zero at every milestone, so the jar used to
empty itself at the exact moment the player was being congratulated.

---

### `_CoachTab` — the budget and habit analyser
The fifth Money Habits tab. Reads what the player has actually done — habits
logged, lessons taken, town visited, lives finished — and returns findings
rather than metrics.

**How it was built:** `money_analyzer.dart` is pure Dart, `MoneySnapshot` in
and `MoneyReport` out, so the rules can be tested against a player who has
pinned six habits and logged one — a state that takes a fortnight of real use
to reach and four lines to describe. `money_snapshot_source.dart` is the only
part that knows about storage and contains no judgement; the screen decides how
a finding looks and never what counts as one.

Every finding carries the number out of the player's own data, exactly one
action, and where there is one, the money idea behind it — which links back to
the lesson and its citation.

## Style (Customize)

### `CustomizeScreen`
Your character, the skin collection grouped by family, and the **Emerald Case**.

Opening a case runs a reel: a strip built around the already-decided result,
with the winner at a fixed index and random filler around it. The ratchet sound
is generated from the same easing curve the reel animates on, so the ticks *are*
the tiles crossing the marker. The rarity chime plays on the reveal, not before.

24 skins across three families — turtles, a critter and 19 villagers. Villager
skins ship both a masculine and a feminine body; choosing one never costs a
pull, because doubling the pool would have halved everyone's odds.

New villager skins cost a **palette entry**, not an art commission:
`tool/redraw_villagers.py --new` draws a full 32-frame sheet from four colours,
which is what makes it reasonable to keep growing the pool after release.

---

## Profile

### `ProfileScreen`
Account, settings and social. Sound and music are separate toggles (plenty of
people want the click and not the loop). Also: replay the tutorial, edit your
age band and gender, the cloud-sync banner, and **Friends** — your code, an add
box, and the list itself with removal.

Email is masked before display.

### `LeaderboardScreen`
Global and friends-only boards, by literacy or by gold. Self-declared under-13
accounts never appear on the global board — a privacy default, not a setting.

### `FeedbackScreen`
Sends feedback to Supabase. Occasionally prompted from Home, with a cooldown.

---

## Onboarding and auth

### `WelcomeScreen`
First launch: what the app is, then sign up or log in.

### `AuthScreen` / `SetNewPasswordScreen`
Supabase email auth, with a Turnstile check and a password-reset flow.

### `CoachMarkOverlay`
The guided tour. Eleven steps, each spotlighting a real widget on the real
screen and switching tabs underneath as it goes. The card is capped and centred
and scales its contents off the shorter screen edge, so it is a speech bubble on
a phone and still a speech bubble on a desktop window.

### `PersonalDetailsSheet`
Age band and gender, asked once. Age drives which Academy unit is recommended,
which life-sim options are available, and whether the account appears on the
leaderboard.

### `TemporaryLoadingScreen`
Shown while Supabase and the stats cache warm up.

---

## Admin

### `AdminScreen`
An internal tool: user lookup, disable/enable, and raw queries through the
Supabase client. Not part of the player-facing app.

---

## Where the numbers live

| Thing | Owner |
|---|---|
| Gold, XP, literacy, level | `UserStatsController` |
| Unlocked skins, equipped skin | `UserStatsController` |
| Habit log, jar points, streak | `MoneyHabitController` → `spending_habits` |
| Today's objective | `DailyPlanController` |
| Lesson/quiz progress, mastery | `ProgressionService` |
| Holdings, cash, P&L history | `UserStatsController` + `MarketDataService` |
| Sound/music/notifications | `AppSettingsController` |
| The current life | `LifeSimController` (not persisted until it ends) |

Anything stored per-user that does not have its own column goes into the
`spending_habits` JSON blob — an ad-hoc key pattern that avoids a migration for
every new feature. It is deliberate, and the tradeoff is that nothing validates
those keys, so a typo is a silently-lost feature rather than a compile error.
