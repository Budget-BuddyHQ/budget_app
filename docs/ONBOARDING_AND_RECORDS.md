# The guided tour, and Life's memory

Two features that both exist for the same reason: the app had a lot of
surface area and no way to find it, and a main game with no memory of
anything you'd done in it. Written from what's actually in the repository.

---

## 1. The guided tour (`TutorialScreen`)

**The problem.** Budget Buddy ships five bottom tabs, two more in the top
strip, a leaderboard behind a trophy icon, and a Market Board buried one
level inside Arcade. A new player landed on Home with no idea that most of
that existed, and nothing anywhere explained what any of it was *for*.

**The shape.** An eleven-step tour, one step per surface:

| Step | Covers | Jumps to |
|---|---|---|
| `welcome` | Bookend. Meets Buddy, sets the "decision is the lesson" framing | — |
| `home` | Dashboard, the daily habit card, Buddy's tip | Home |
| `life` | The main game: age up, money decisions, the money panel | Life |
| `arcade` | Finance Brawl and Market Board, run lengths | Arcade |
| `market_board` | Trade / Assets / Orders / P&L / Analytics | — (sub-screen) |
| `learn` | The Academy path, literacy points | Learn |
| `daily` | Money Habits — the one part about *real* money | Daily |
| `style` | Skins, the 180-gold Emerald Case, duplicate rebates | Style |
| `leaderboard` | Global vs Friends, by level or gold | — (trophy icon) |
| `profile` | Badges, friend code, settings | Profile |
| `finish` | Bookend. Points at Life as the place to start | — |

Content lives in
[`tutorial_steps.dart`](../lib/models_Like_Skins_and_lessons_templates/tutorial_steps.dart)
as plain data, so copy can be reordered or reworded without touching layout
code. Each step carries a mascot pose, an accent colour, bullets, and a
`teaches` line — that last one is what keeps the tour from reading as a
menu index.

**Why a route, not a spotlight overlay.** The obvious implementation
highlights real widgets in place with a cut-out mask. That needs a
`GlobalKey` on every element it points at and breaks the moment a card
moves — and this app has already moved tabs between the bottom bar and the
top strip more than once. A self-contained route says the same things,
survives that churn, and can be replayed from Profile without the tab it
describes being on screen.

**Navigation contract.** `TutorialScreen.show(context)` resolves to an
`int?`: a tab index when the player tapped "Take me to X", null when they
finished or skipped. `show()` also marks the tour seen on the way out —
there rather than in `dispose` so it covers finishing, skipping *and* the
system back gesture in one place, and so the write is awaited.

**First-run sequencing.** `MainNavigation` owns the ordering. Both the tour
and the age/gender sheet want to interrupt a first run, so they queue:
`_maybeShowTutorial` waits for `AppSettingsController.isInitialized` (acting
on the pre-read default would re-show the whole tour to an existing player
on every cold start), runs the tour, then calls
`_maybeAskForPersonalDetails`. That second method returns early while
`_tutorialResolved` is false, so neither path can double-fire.

**Replay.** Profile → *Replay Tutorial* pushes the tour directly, so the
seen flag never needs clearing — it only ever gated the automatic first-run
opening. "Take me there" is honoured only when Profile is hosted as a tab;
pushed as a standalone route there is no tab bar to switch, so the request
is dropped rather than faked with a navigation nobody asked for.

---

## 2. Life's memory (`LifeRecordBook`)

**The problem.** `LifeSimPage` builds its own `LifeSimController` and throws
it away on exit — right for the game, but it meant finishing a life recorded
exactly one thing: the ending's id, added to a set. Who you were, how long
you lived, what you were worth, how many money ideas you'd met — all shown
once on the epilogue and then gone. A tenth run was indistinguishable from a
first, and there was nothing to beat.

**The model.**
[`life_record.dart`](../lib/models_Like_Skins_and_lessons_templates/life_record.dart)
holds a `LifeRecord` per finished run (ending, name, age, net worth,
happiness, died/retired, concepts met, gold earned, finished-at) and a
`LifeRecordBook` wrapping the list.

Three things worth knowing about it:

- **Bests are computed, never stored.** Storing them would mean two sources
  of truth that can disagree — and they *would*, the moment the cap trims an
  old record.
- **The history is capped at 20** (`LifeRecordBook.maxRecords`). These live
  in the same `spendingHabits` JSON blob as everything else, which is written
  on nearly every action, so the payload stays small. `discoveredEndings` is
  kept separately and uncapped, so "have I ever seen this ending" survives
  the trim.
- **Every field is coerced, not cast.** The blob round-trips through a remote
  JSON column, so an int can come back as a double or a string. One
  unreadable row is skipped rather than costing the player their history.

**Personal bests.** `bestsBeaten(record)` is judged against the book *before*
the record is added, and uses strictly-greater-than so replaying an identical
result doesn't re-announce a best. A first life returns none — it
technically tops every category, but calling a debut three personal bests
would make the label meaningless.

**Where it surfaces.**

- `UserStatsController.recordLifeRun(summary)` files the run and returns the
  beaten categories. Called from `LifeSimPage._finish`, after the gold award
  so the record's reward figure matches what was actually paid.
- `LifeEpilogueScreen` shows a gold banner when that set is non-empty.
- `PastLivesScreen` (Life tab → *Past Lives*) shows the three bests, then the
  history newest-first, with a crown on any row that currently holds a
  record.

**A note on the crowns.** `_RecordRow` uses `identical()` against
`book.richest` / `longest` / `wisest`, not `==`. Two runs can tie on a value
without both being the record holder, and identity is what "this specific
life set it" means.

---

## 3. Tests

- [`tutorial_test.dart`](../test/tutorial_test.dart) — content integrity
  (unique ids, every listed surface covered, no empty copy, jump targets
  in range), plus a full walkthrough, Back/Skip/"Take me there", and an
  overflow check on every step at phone size.
- [`life_record_test.dart`](../test/life_record_test.dart) — JSON
  round-trip, type coercion, junk tolerance, the cap, and every
  `bestsBeaten` edge (first life, ties, partial beats).
- [`past_lives_screen_test.dart`](../test/past_lives_screen_test.dart) —
  empty state, bests, ordering, retired-vs-died wording, an unknown ending
  id from an older save, and narrow-phone layout.

**One testing gotcha worth repeating.** The tutorial's mascot rides an
`IdleHoverIcon`, whose idle bob is a `repeat()`ing controller that never
completes — so `pumpAndSettle` times out. The tests wrap the tour in
`MediaQuery(data: MediaQueryData(disableAnimations: true))`, which both makes
it testable and exercises the reduce-motion path the widget already honours.

The Past Lives tests scope their finders with `ValueKey`s rather than bare
text, because the same figure legitimately appears twice on that screen —
"14 ideas" is both a personal best and a stat chip on the row that set it.
