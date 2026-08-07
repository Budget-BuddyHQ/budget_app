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

---

## 9. Progression surfaces: endings, badges, and the Life event pool

Three things now read off the *same* persisted progress rather than each
inventing their own tracking:

**Discovered endings** live in `spendingHabits['discovered_endings']`
(`UserStats.discoveredEndings`), written by
`UserStatsController.recordLifeEnding()` when a life finishes. That single
list drives both the endings collection grid on the Adventure hub
(`main_game_page.dart`) and two of the profile badges.

**Badges** (`_BadgeShowcase` in
[profile_screen.dart](../lib/screens_minigames_admin_etc/profile/profile_screen.dart))
are **derived, not stored** — every tier is computed from progress the app
already records: discovered endings, `unlockedSkins.length`,
`completedLessons.length`, and `level`. Nothing writes a badge, so badges
can never drift out of sync with the progress they describe, and adding one
is a pure data change to `_badges()`. The skin-count badges double as the
"show skins somewhere other than the customise grid" surface.

**The Life event pool** (`kLifeEvents` in `life_sim_models.dart`) went from
21 to 37 events, keeping the existing age-gated structure
(`minAge`/`maxAge`) and the childhood/teen/adult grouping. The additions are
deliberately money-decision shaped rather than flavour — bank accounts,
credit-card offers, rent increases, salary negotiation, a market crash,
employer retirement matching — so the extra content also widens the range of
final stats, which is what makes the seven endings actually reachable.

## 10. Password reset, end to end

The flow spans four pieces, and until this session only the first existed:

1. **Request** — `AuthScreen._submitPasswordReset` grabs a Turnstile token
   (Supabase enforces captcha on the recovery endpoint too) and calls
   `SupabaseService.resetPasswordForEmail`, which now passes
   `passwordResetRedirectUrl`.
2. **The link** — Supabase emails a recovery link. Tapping it signs the user
   in on a short-lived *recovery* session and fires
   `AuthChangeEvent.passwordRecovery`.
3. **Interception** — `_AppBootstrapGate` in `main.dart` checks for that
   event *before* its normal signed-in branch and shows
   `SetNewPasswordScreen`. Without this the gate saw "a user is signed in"
   and went straight to the dashboard, which is exactly why the flow
   silently did nothing.
4. **The change** — `SupabaseService.updatePassword()` calls
   `auth.updateUser(UserAttributes(password:))`. That fires its own auth
   event, which replaces the `passwordRecovery` snapshot and lets the gate
   fall through to the dashboard — so no manual navigation is needed after
   success.

**Two things still have to be configured by hand** (they're outside the Dart
code and can't be fixed from here):
- `passwordResetRedirectUrl` must be listed under Supabase → Authentication
  → URL Configuration → **Redirect URLs**. If it isn't, Supabase ignores it
  and falls back to the project Site URL — the app never sees step 2.
- On mobile the `budgetbuddy://` scheme must be declared natively (Android
  intent-filter in `AndroidManifest.xml`, iOS `CFBundleURLTypes` in
  `Info.plist`) before the OS will hand the link back to the app. On web the
  redirect is just the dev-server origin, so web works as soon as the URL is
  allowlisted.

---

## 11. Rewards that pay out in shares, not just gold

`UserStatsController.applyChallengePayload` originally understood three
currencies — `gold_earned`, `xp_earned`, `literacy_points_earned`. It now
also accepts:

```dart
'shares_earned': {'SPY': 0.25, 'KO': 0.5}
```

Keys are bare tickers; they're stored under the `stock_<SYMBOL>` prefix the
Market Board reads, so granted shares are **real holdings** — they show in
the allocation ring, move with live prices, and can be sold. Fractional on
purpose (a whole share costs thousands of coins at `kCoinsPerDollar = 10`).

**Unit 6 · Stocks and Trading** is the first consumer. Payouts live in
`kLessonPayouts` in
[lesson_detail_screen.dart](../lib/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart),
keyed by lesson id, and fire from `_completeLesson` *after*
`completeLessonProgress`. The `_isCompleted` guard means each lesson pays
once — re-opening a finished lesson pops straight back out before reaching
the payout.

Amounts are deliberately modest (500–1500 gold, fractional shares): enough
that finishing the trading lessons hands you something real to trade with
and watch move, not enough to bypass the game's own economy.

Adding a payout to any other lesson is a one-line entry in that map — no new
plumbing.

## 12. What "supporting more users" currently depends on

Worth being precise, since this is easy to assume is handled:

- **Per-user reads are already cheap** — everything for one player lives in a
  single `user_stats` row keyed by their auth UUID, read with one
  `.eq('id', userId).maybeSingle()`. No N+1, no joins, no fan-out. Adding
  users scales that linearly.
- **The leaderboard is the one query that touches all users** — a `select`
  view over `user_stats`. It's read with a `limit`, but a growing table will
  eventually need an index on the ordering column (gold/xp) to stay fast.
  That's a dashboard-side change, not a code change.
- **Row Level Security is the actual gate.** Every table a client touches
  needs RLS policies that scope rows to `auth.uid()`; the new `app_feedback`
  table needs an insert policy or feedback submissions will fail for real
  users while appearing to work locally (the client queues them either way).
- **Nothing in the app assumes a single user** — no global caches keyed by
  anything but user id, and `clearCachedUserStats` runs on sign-out.

The realistic scaling limits today are the **third-party API tiers**, not the
database: Finnhub free is 60 calls/min shared across *all* users on the same
key, and Twelve Data free is 800 requests/day total. Those are per-key, not
per-user — so a real userbase needs either paid tiers or a server-side proxy
that fetches once and fans out, rather than every client calling directly.

---

## 13. The achievement celebration (and what art actually exists)

`AchievementCelebration.show()`
([achievement_celebration.dart](../lib/widgets_custom_lotties/achievement_celebration.dart))
is the "you earned something" moment, fired from `_BadgeShowcase` when a
badge becomes newly earned.

**On the art:** there is no celebrating-turtle sprite sheet in this project.
Every turtle asset is a single static pose — `pixelMainTurtle.png` (the
mascot/logo with a coin), `cool_turtle.png`, and three skin previews under
`assets/images/turtles/`. None are multi-frame. The celebration is therefore
*composed* rather than played back: the mascot pops in on an `elasticOut`
spring, sitting inside hand-painted rotating rays and sparks that fly
outward once on entrance (`_CelebrationPainter`). Same approach as the
charts — a `CustomPainter`, no new dependency, nothing to crash on odd
sizes. If a real multi-frame celebration sheet gets drawn later, it drops
into the same widget with the painter removed.

**Firing once, not every visit:** badges are derived from progress, so
"newly earned" needs its own memory. `spendingHabits['celebrated_badges']`
(`UserStats.celebratedBadges`, written by
`UserStatsController.markBadgesCelebrated`) records *only* which badges have
already been congratulated — it never decides what's earned, so it cannot
accidentally grant a badge. `_BadgeShowcase` re-checks on both `initState`
and `didUpdateWidget`, since stats can change while Profile is on screen
(finishing a life, unlocking a skin).
