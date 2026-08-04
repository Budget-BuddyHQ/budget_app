# How Budget Buddy is actually put together

This is the technical companion to the root `README.md`'s error log — where
that document tracks *what broke and how it got fixed*, this one tracks
*how the pieces fit together*: auth → username → gameplay data → the
Supabase project, what "analytics" means in this app today, and how the
overall codebase is organized. Written from what's actually in the
repository and the Supabase project as of this session — not aspirational.

---

## 1. Auth → username → gameplay data, end to end

**Sign-up.** `AuthScreen` collects email, password, and a display name, then
calls `SupabaseService.signUp()`
([supabase_service.dart](../lib/services_backend_and_other_services/supabase_service.dart)),
which hits `client.auth.signUp(...)`. The username is passed through Supabase
Auth's `data:` field (`user_metadata`), **not** written directly to a
gameplay table — Supabase Auth and the app's own tables are two separate
systems that only share the user's `id` (a UUID).

Every auth call (`signUp`, `signInWithPassword`, `resetPasswordForEmail`)
requires a Cloudflare Turnstile `captchaToken`. This was a real, silently-broken
bug earlier in the project — password reset called the API without a token
and Supabase rejected it with `captcha_failed`, but the UI showed a generic
error. It's now passed through everywhere auth is called. See the README's
error log for the original writeup.

**Where gameplay data lives.** A `user_stats` table, keyed by `id` = the
Supabase Auth user's UUID (a foreign key, `profiles_id_fkey`, ties it back to
`auth.users`). `UserStats` ([supabase_service.dart](../lib/services_backend_and_other_services/supabase_service.dart))
is the Dart model for one row:

| Column | What it holds |
| --- | --- |
| `id` | The Supabase Auth UUID — the only link between auth and gameplay data |
| `username` | Display name. Mirrored here from auth metadata on first save so the rest of the app never needs to touch `auth.users` directly |
| `gold`, `xp`, `literacy_points` | Core progression counters |
| `spending_habits` | A JSON blob — see §2, this is where most "soft" profile data actually lives |
| `transaction_ledger` | JSON array of `LedgerTransaction`s (the in-app ledger feed) |
| `portfolio_history` | Net-worth-over-time series, used for the Market Board P&L chart |
| `holdings` | Share/lot counts per stock symbol |
| `age`, `gender` | Added directly in the Supabase table editor this session — see §2 for why the app doesn't read these back |
| `updated_at` | Set by the app on every write |

**The sync path.** `UserStatsController` ([user_stats_controller.dart](../lib/controllers_that_updates_stats/user_stats_controller.dart))
is the single source of truth the UI reads from — every screen gets stats via
`Provider`/`Consumer<UserStatsController>`, never by querying Supabase
directly. Underneath it, `SupabaseService.loadUserStats()` /
`saveUserStats()` layer three tiers, checked in order so the app never just
shows a blank screen:

1. **In-memory cache** (`_memoryCache`) — instant, cleared on sign-out.
2. **`SharedPreferences`** — a local JSON copy (`_cacheUserStats`), so the
   app opens with real data even fully offline.
3. **Supabase** — the actual source of truth when reachable. Every network
   call has a timeout (`_supabaseReadTimeout`, 6s) and a `try/catch` that
   falls back to the cache with `debugPrint` rather than surfacing an error
   to the player, per the project's "degrade gracefully" rule (see the
   README's "Teammates need no API keys" note).

Writes go the other direction: the controller mutates its in-memory
`UserStats`, saves to `SharedPreferences` immediately, and pushes to
Supabase in the background — the player never waits on a network round trip
to see their own gold/XP update.

---

## 2. Age & gender: two representations, on purpose

There are now genuinely two places age/gender data lives, and that's a
deliberate design, not an oversight:

- **`spending_habits.age_band` / `.gender`** (a bucketed `AgeBand` /
  `GenderIdentity` enum — see
  [player_profile.dart](../lib/models_Like_Skins_and_lessons_templates/player_profile.dart))
  is what the app's own logic reads: which worked-example dollar amounts
  Academy shows (`AgeBand.lifeStage`), which villager body an avatar
  defaults to, and — new this session — which Academy unit gets a
  "Recommended for you" badge (`AgeBand.recommendedStage`, via
  `AgeStage.minAge` in
  [lesson.dart](../lib/models_Like_Skins_and_lessons_templates/lesson.dart)).
  It's collected as a **bucket**, not a birthdate, on purpose — good
  practice for an app used by minors, and it's exactly enough precision to
  drive every feature that actually uses it.
- **The `age` (int2) / `gender` (text) columns**, added directly in the
  Supabase table editor this session, are written by
  `UserStats.toStorageMap()` as a **mirror** of the bucketed data — a
  representative number (`AgeBand.representativeAge`) and the human-readable
  label. The app never reads these back for its own logic. They exist so
  the raw table is readable/queryable by a human (or a future SQL query)
  without unpacking the `spending_habits` JSON blob by hand.

If a future feature genuinely needs finer-grained age than 5 buckets give
(the current buckets are `12 or under`, `13–15`, `16–17`, `18+`,
`undisclosed`), the right move is extending `AgeBand`'s buckets, not
switching the app's logic over to the raw `age` column — that would mean
collecting exact birthdates, which the app has deliberately avoided.

**Recommendation, not a lock.** Academy's age-stage badge only *highlights*
a unit — it never hides or unlocks one. Content is gated purely by
completing the previous unit's test (`Lesson.prerequisites` in
[lesson_data.dart](../lib/models_Like_Skins_and_lessons_templates/lesson_data.dart)),
regardless of age. This was a deliberate call: the curriculum is strictly
sequential (Unit 4 "Investing Basics" requires finishing Units 1–3 first,
for anyone), so "show lessons for their age" was implemented as a visible
"this unit fits your age" signal within that existing order rather than a
skip-ahead — building real parallel per-age curricula so an 18-year-old
could jump straight to Unit 4 would be a much bigger restructure, and
wasn't something to do silently.

---

## 3. What "analytics" actually means in this app today

There is **no dedicated analytics pipeline** — no PostHog, Mixpanel,
Amplitude, Firebase Analytics, or custom events table. Worth saying plainly,
since "analytics" can imply an event-tracking system that doesn't exist
here.

What *does* exist, and is the closest equivalent:

- **`_AcademyAnalyticsCard`** ([lesson_screen.dart](../lib/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart))
  — literally named that in its own doc comment: "how much of the Academy is
  done, how accurate the player's answers are, which age stages they have
  reached, and which skills still need work." It's computed entirely from
  data already on `UserStats` and `ProgressionService` — no separate
  tracking, just a summary view over state the app already has.
- **Arcade play counts / best scores** — `arcadeScores` on `UserStats`,
  keyed by game id, holding `best` and `plays`. Drives the "least-played
  game" pick in the daily plan (`DailyPlanBuilder._leastPlayedGame`) and the
  "Not played yet" vs. "Best wave: N • M runs" line on arcade cards.
  There's no timestamped history — just running totals.
- **Quiz accuracy** — `quizScores`/`accuracyFor()` on `UserStats`, best
  accuracy per quiz/unit-test node. Drives `MasteryLevel` and the "weakest
  skill" pick for the daily plan's practice slot.
  `ProgressionService._accuracy` mirrors this in memory for the currently
  open Academy session.
- **Daily quest streaks** — `DailyPlanController`/`DailyPlan.streakDays`,
  a simple day-over-day counter.
- **The leaderboard** — a Supabase `view` (`leaderboard`) over `user_stats`,
  read-only, ranked by gold/XP.

None of this is event-level ("player tapped X at time Y") — it's all
running totals and best-scores recomputed from the current row, which is
also why it degrades the same way the rest of the app does: offline, it
just reads whatever's cached locally.

---

## 4. Codebase shape, if you're new to it

- **Screens** live under `lib/screens_minigames_admin_etc/`, grouped by
  area (`Gameplay/academy`, `Gameplay/minigames_pages`,
  `Gameplay/dashboard`, `profile`, `auth`, `admin`, `onboarding`).
- **State** is `ChangeNotifier` + `Provider` — `UserStatsController` is the
  one every screen actually depends on;
  `DailyPlanController`/`AppSettingsController`/`MarketDataService` are
  narrower, feature-specific controllers.
- **Content is data, not hardcoded UI** — lesson copy lives in
  `lesson_data.dart` + `_lessonLibrary` in `lesson_detail_screen.dart`, the
  arcade catalog in `arcade_catalog.dart`, daily quests generated by
  `DailyPlanBuilder`. Adding content is a data change, not a new screen.
- **Two game engines, two different jobs**: `fl_chart` was tried and
  removed (see README error log — it crashed on certain widths); the Market
  Board's charts are a hand-rolled `CustomPainter`
  (`MiniSparkline`/`PriceChart`) instead. `bonfire` (+ `flame_tiled`) powers
  the Adventure world — see
  [adventure_world_screen.dart](../lib/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart)
  and `assets/images/maps/README.md` for exactly what it's waiting on.
- **Everything degrades gracefully by design** — no Supabase keys, no
  market-data keys, no network at all: the app still opens and plays using
  cached/default state. This is a repeated, deliberate pattern across the
  service layer, not just a Market Board thing.
- **The test suite's backbone** is `test/responsive_layout_test.dart` — it
  pumps every major screen at seven viewport sizes and fails the build on
  any layout overflow. New screens get added to its `screens` map as part
  of building them, not as an afterthought; several real bugs (see the
  README error log) were only caught because of this.

---

## 5. Academy row status: what "Mastered" actually shows

Every lesson/quiz/unit-test row in `UnitRowItem`
([unit_row_item.dart](../lib/custom_made_widgets/unit_row_item.dart)) reads
two different things from `ProgressionService`:

- `statusFor(lessonId)` → `LessonStatus` (completed/available/locked) — drives
  the badge's icon, color, and label ("Mastered"/"Ready"/"Locked").
- `accuracyFor(lessonId)` → `double?` — the best-attempt accuracy on that
  *specific* node, not a unit-wide average. Only meaningful for
  `LessonNodeType.quiz`/`unitTest` nodes; always `null` for plain lessons.

For an attempted quiz/test, the row shows the accuracy as a second line
under the badge (e.g. "92% score") — the status badge alone couldn't answer
"how did I actually do", only "did I finish it". Plain lesson rows don't get
a score line (there's nothing to score), but got the same badge-visibility
treatment anyway — bigger font, a status icon, stronger contrast — since
"more visible" was a general ask, not just about quizzes specifically.

## 6. The idle-animation vocabulary (`IdleHoverIcon`)

[idle_hover_icon.dart](../lib/widgets_custom_lotties/idle_hover_icon.dart) is
the shared building block for "this icon should read as alive, not static."
It composes four independent motions, all driven off one looping
`AnimationController` so they can combine without fighting each other:

| Param | Motion | Used for |
| --- | --- | --- |
| `idleAmplitude` | vertical bob | the default — most icons |
| `rotationAmplitude` | pendulum wobble (side to side, not a full spin) | daily-quest status icons — reads as playful |
| `pulseAmplitude` | breathing scale | the Play Life heart — a pulse fits a heart, a bob doesn't |
| `continuousSpin` | full 360° rotation over one `period` | the Play Life play-button icon — a slow, subtle spin as a CTA cue |

Deliberately **not** one-size-fits-all: which motion(s) an icon gets is a
per-call-site choice (see `daily_plan_card.dart` and `home_screen.dart`),
picked for what actually suits that icon rather than reusing the same
animation everywhere. `hoverScale` (desktop/web pointer hover) and reduced-
motion handling are shared across all of them regardless of which motion
params are set.

## 7. Sound is off by default

`AppSoundService.enabled` ([app_sound_service.dart](../lib/services_backend_and_other_services/app_sound_service.dart))
now defaults to `false` — the 10 bundled SFX (`assets/audio/*.wav`) read as
harsh rather than subtle. This is a default change, not a removal: the
service, the asset files, and all 37 `AppSoundService.play(...)` call sites
across the app are untouched, and the existing "Sound" toggle in Profile
(`AppSettingsController.setSoundEnabled`) still works for anyone who wants
them on. The right long-term fix is a quieter, more deliberate sound pass —
this just stops the current set from playing until that happens.

---

## 8. Life's endings — Phase 1 of the "main game" framework

Life could always be *played*, but until this session it had no real
*ending* — `retire()` was a flat "set retired, done" with zero branching,
and `_finish()` in `life_sim_page.dart` computed a gold reward, showed one
toast, and called `Navigator.pop()` straight back to Home. A whole run —
name, origin, however many years — ended in silence.

**[life_ending.dart](../lib/models_Like_Skins_and_lessons_templates/life_ending.dart)**
adds:
- `LifeEndingArchetype` — 7 distinct, non-horror outcomes (Gone Too Soon,
  Cautionary Tale, Rich but Lonely, Broke but Happy, Legacy Builder,
  Comfortable Retiree, A Quiet Life), each with a label/icon/color/blurb —
  same `enum` + metadata shape as `ArcadeDifficulty` and `MasteryLevel`
  elsewhere in the codebase, not a new modeling style.
- `resolveLifeEnding(...)` — a deterministic, first-match-wins resolver over
  stats `LifeSimController` **already tracked** (`netWorth`, `happiness`,
  `smarts`, `age`, `died`) — no new stat plumbing, same pattern as
  `stageForAge` in `lesson.dart`.
- `LifeSummary` — an immutable snapshot (`LifeSummary.fromController`) taken
  the instant a life ends. It has to be a snapshot, not a live reference:
  `LifeSimController` gets disposed once the page navigates away, so
  whatever shows the ending needs its own frozen copy of the numbers.

**[life_epilogue_screen.dart](../lib/screens_minigames_admin_etc/Gameplay/minigames_pages/life_epilogue_screen.dart)**
is the screen that was missing — archetype card, stat recap, relationship
chips, gold banked, "Back to Home." `life_sim_page.dart`'s `_finish()` now
builds the `LifeSummary` right after `life.retire()` and
`pushReplacement`s to it instead of popping (`pushReplacement`, not `push`,
so the back button can't return to a finished life and "Back to Home" is a
single `pop()`).

**Deliberately out of scope for this phase** (see the approved plan for the
full reasoning): no change to `_drawEvent()`'s uniform-random event draw, no
achievement/milestone system, and no Adventure-world tie-in — that's
Phase 2, blocked on the user providing a real map file, and needs real zone
names to design concretely rather than guessing them now.
