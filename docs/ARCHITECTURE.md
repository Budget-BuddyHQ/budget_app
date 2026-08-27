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

## 8b. The Life event engine

Life follows the standard life-sim shape: character state → event generator
→ choice/consequence → career progression, with hidden modifiers.

**Character state** (`LifeSimController`): age, money, investments,
happiness, health, smarts, looks, job, salary, relationships — plus
`fame` (0–100), `skills` (`Map<LifeSkill, int>`, 0–100 each) and `traits`
(`Set<LifeTrait>`, two rolled at birth).

**The generator** is `_drawEvent()`. Each `LifeEvent` declares its own
requirements rather than the controller hard-coding them:

| Field | Gate |
| --- | --- |
| `minAge` / `maxAge` | life stage |
| `requiresSkill` + `minSkill` | career track progression |
| `requiresTrait` | personality-only branches |
| `minFame` | the "you're known now" tier |
| `minMoney` | can't gamble what you don't have |
| `requiresJob` | employment-only beats |
| `weight` | relative likelihood once eligible |

`LifeEvent.matches(LifeContext)` checks all of them; the draw then does a
weighted roll over survivors. **This replaced a uniform pick over an
age-only filter** — previously a rare dramatic beat was exactly as likely as
a routine one, and no event could depend on who the character had become.

**Consequences** live on `LifeChoice`: the existing stat/job/relationship
deltas plus `fame`, `skill` + `skillGain`, and `addTrait`.

**Career progression** is the skill→fame→payoff ladder, e.g. music:
`discover_music` (skill 12) → `first_gig` (needs skill 20, grants fame) →
`record_deal` (skill 45 **and** fame 10) → `sold_out_tour` (skill 65, fame
35). Nothing on that ladder can fire for a character who never practised —
`practise(LifeSkill)` is the player-driven input that opens it.

`test/life_sim_test.dart` locks the gating down: every gated event is
asserted unreachable below its threshold, since the whole system silently
degrades back to "uniform random" if `matches` ever stops being consulted.

**The menu is the other half of the variety problem.** For a long time
`_BottomMenu` rendered the same four actions — School, Assets, Fun, Gym — at
every single age, and `practise(LifeSkill)` had no UI at all, so the entire
skill/career ladder above was unreachable no matter how many events fed it.
Two changes fixed that:

- The left slot is **School** for baby/child/teen and **Assets** afterwards,
  so a toddler isn't offered an investment button and an adult isn't still
  tapping "School".
- A **Skills** button opens `_SkillsSheet`, listing each `LifeSkill` with its
  level, a practise action, and the traits rolled at birth. This is the only
  input that raises a skill, so it is the door to every career track.

The lesson worth keeping: adding content to the event pool does nothing for
perceived variety if the *inputs* the player has each turn never change.

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
21 to 48 events, keeping the existing age-gated structure
(`minAge`/`maxAge`) and the childhood/teen/adult grouping. The additions are
deliberately money-decision shaped rather than flavour — bank accounts,
credit-card offers, rent increases, salary negotiation, a market crash,
employer retirement matching — so the extra content also widens the range of
final stats, which is what makes the seven endings actually reachable.

## 9b. Age-divided curriculum and the "too young" warning

The Academy carries nine units across four `AgeStage` bands
(`lesson.dart`): middle school (11–13), high school (14–17), graduating
(18–20), adult (21+). Three units were added to fill the bands out —
**Spending Traps** (middle school: ads, in-game currency, scams),
**Money by the Numbers** (high school: percentages, mean vs median, reading
and misreading charts), and **Retirement and the 401(k)** (adult: employer
match, Roth vs traditional, fees and vesting).

**Curriculum order is not age order, and can't be.** Units chain on
prerequisites — `lesson_31` requires `test_6` — so the list is a dependency
graph, and it happens to zigzag across bands (Unit 2 is written for 18–20s,
Unit 3 for 14–17s). Two consequences:

- The **unit strip** sorts and groups a *copy* of the list by
  `ageStage.minAge`, emitting an `_AgeGroupHeader` per band. Only the strip
  reorders; `onSelected` still carries each unit's real index, and the
  prerequisite chain is untouched. This is what makes the division by age the
  first thing you see.
- Nothing is **locked** by age. A unit above your band shows an amber chip, a
  `_TooYoungBanner` on its card, and a confirm dialog before a lesson opens —
  then opens anyway if you say so. The point is that a 12-year-old reading the
  401(k) unit knows the salary-shaped examples are a preview of later, not a
  description of now.

**Two age concepts, and mixing them up is a bug.**
`AgeBand.recommendedStage` derives from `representativeAge` (the lower-ish end
of a bucket) and answers "what should we lead with?".
`AgeBand.maxPlausibleStage` is the *top* of the band and answers "who should
we warn?". The first version used `recommendedStage` for both and told every
adult that the 21+ unit was above their age, because "18 or older" has a
representative age of 19. Warnings use `maxPlausibleStage`; the "For you"
badge keeps using `recommendedStage`.

## 9c. What is stored, and where — the complete list

Every write goes through `UserStatsController._saveStats` →
`SupabaseService.saveUserStats`, which does **three** things in order: updates
an in-memory cache, writes SharedPreferences, then upserts the `user_stats`
row. The first two always succeed; only the third can fail.

### In the `user_stats` table

| Data | Column | Notes |
| --- | --- | --- |
| Gold, XP, literacy points | own columns | |
| Personality type | own column | |
| **Stock holdings** | `holdings` | `{symbol: shares}`, fractional |
| Transactions | `transaction_ledger` | full ledger, JSON array |
| Net-worth curve | `portfolio_history` | real `cash + market value` readings |
| Username, equipped/unlocked skins | `spending_habits` | |
| Cost basis per symbol | `spending_habits.cost_basis` | what P&L is computed against |
| Completed lessons | `spending_habits.completed_lessons` | |
| Quiz scores, weak skills | `spending_habits.quiz_scores` / `.weak_skills` | |
| Arcade high scores | `spending_habits.arcade_scores` | |
| Life endings discovered | `spending_habits.discovered_endings` | |
| Achievement celebrations seen | `spending_habits.celebrated_badges` | |
| Daily quests + streak | `spending_habits.daily_*` | |
| Age band, gender, pronoun | `spending_habits` | bucketed, never a date of birth |
| Profile picture URL | `spending_habits.profile_image_url` | |

`spending_habits` is a JSON column, which is why so much lives there — adding a
field needs no migration. Age and gender are **deliberately not** mirrored into
`age`/`gender` columns; those exist on `profiles`, not `user_stats`, and
writing them here broke every save until it was removed.

### Not stored, on purpose

- **Badges** are *derived*, not saved. Every tier is recomputed from progress
  the app already records — endings found, skins owned, lessons done, level —
  so a badge can never disagree with the thing it describes. Only "have I seen
  this celebration" is persisted.
- **An in-progress Life run.** Lives reset per visit by design; only the
  ending archetype and the gold payout survive.

### The failure mode that matters

`saveUserStats` catches upsert errors, keeps the local cache, and returns
`synced: false`. That is the right behaviour for a flaky network — a player
never loses a session to a dropped request. But it is also how a schema
mismatch broke **every** cloud save for a long stretch with no visible symptom:
local saving kept working, so the app looked fine, and the only way to notice
was to sign in on another device and find an empty account.

`UserStatsController.cloudSyncHealthy` now tracks this, and `CloudSyncBanner`
(on the profile screen) shows it. It stays hidden when signed out, where
device-only saving is the expected behaviour rather than a fault.

## 9d. Market API keys live on the server

`supabase/functions/market` proxies Finnhub and Twelve Data. The keys are
Supabase secrets; the client authenticates with the anon key, which is already
public.

The security argument is the obvious one — a key in a client build is not a
secret. The *practical* argument matters more: both free tiers are rated **per
key, not per user**, so with a shipped key fifty simultaneous players
rate-limit each other. The proxy caches responses (30s for quotes, 5min for
candles, 1h for search), so a thousand players cost roughly the same upstream
traffic as one.

`MarketDataService.usesProxy` decides the path. Without Supabase configured it
falls back to direct calls with a local key, so the repo still runs for a
contributor who has only a Finnhub key. See `supabase/README.md` for deployment
and `test/market_proxy_test.dart`, which asserts no `apikey` query parameter,
no `X-Finnhub-Token` header, and no request to `finnhub.io` ever leaves the
client.

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

**On the art:** the real celebration sprite sheet lives at
`assets/own_skins/turtle_celebrate/turtle_celebrate.png` — 8 frames on a
3×3 grid of 640×640 cells (last cell empty), progressing smile → sparkle
burst. It's registered in `pubspec.yaml`, exposed through the constants
`AppAssets.turtleCelebrateSheet` / `turtleCelebrateColumns` /
`turtleCelebrateRows` / `turtleCelebrateFrames` / `turtleCelebrateCellSize`,
and driven by a third `AnimationController` (`_sprite`) that walks the
frame index over ~800ms and then holds on the final celebration pose. The
`_CelebrationPainter` rays and sparks still play underneath — the sprite
plus the painted burst read as one moment. Under reduce-motion the sprite
pins straight to the last frame.

**Firing once, not every visit:** badges are derived from progress, so
"newly earned" needs its own memory. `spendingHabits['celebrated_badges']`
(`UserStats.celebratedBadges`, written by
`UserStatsController.markBadgesCelebrated`) records *only* which badges have
already been congratulated — it never decides what's earned, so it cannot
accidentally grant a badge. `_BadgeShowcase` re-checks on both `initState`
and `didUpdateWidget`, since stats can change while Profile is on screen
(finishing a life, unlocking a skin).

## 14. 2026-08-22 pass: asset reorg, redesign tokens, the town map, a
privacy fix

Five things landed in one session, acting on direct product/design direction
rather than a bug report — noted here since none of it fits the "what broke"
frame of the root README.

**Asset reorg.** Two loose asset dumps sitting directly under `assets/`
(`newly imported for normal map/`, `main Map/`) got sorted: third-party packs
into `assets/imported/` (`Pixel Art Top Down - Basic v1.2.3/`,
`SlideRowAssets/`, plus a `Loose Tilesets/` catch-all for two standalone
PNGs), and the user's own map export promoted into `assets/images/maps/`
(see below). The dead `NormalFont` (declared in `pubspec.yaml`, zero
references in `lib/`) was removed along with its now-empty
`assets/fonts/` directory.

**Redesign tokens.** `AppTheme` (`lib/themes_colors/app_theme.dart`) was,
until now, essentially dead — used once in `main.dart` to build a `ThemeData`
that no screen actually read from (`Theme.of(context).textTheme` had zero
call sites). Every screen hardcoded its own colors/shadows instead. Rather
than a repo-wide rewrite, `AppTheme` became the source of truth for *new*
values and got threaded through the handful of genuinely shared widgets that
fan out across most of the app: `HoverLift`, `CustomButton`, `PopNavBar`,
`AmbientLottieCard`, `UnitRowItem`. Two additions worth knowing about:
- The core palette (`deepForest`/`darkForest`/`panel`/`panelStrong`) moved a
  step lighter/warmer, and radii got rounder (`radiusLarge` 20→24,
  `radiusXLarge` 28→32) — a lit night scene, not a cave.
- `AppTheme.puffyShadow()` / `getPuffyDecoration()` are new: a soft,
  colour-tinted glow shadow, visible **at rest** (not just on hover) so
  touch devices — which never fire hover events — still see cards read as
  raised rather than flat. `HoverLift` in particular used to be invisible on
  mobile for exactly this reason.
- Home, Arcade (`minigames_page.dart`), Academy (`lesson_screen.dart`), and
  Profile scaffolds/cards were updated to the new tokens as representative
  passes matching what was actually screenshotted; most of the ~40 other
  screen-local card classes and ~300 raw (fontless) `TextStyle` call sites
  found in the audit are **not yet touched** — same treatment, just not done
  yet. The floating turtle decoration in Home's `_AdventureLaunchHero` was
  removed outright (was `AmbientLottieCard(motif: AmbientMotif.turtle)` at
  low opacity, per direct request).

**The town map.** The user's exported `map.json` + `spritesheet.png` turned
out to be **Sprite Fusion** format, not Tiled — `{tileSize, mapWidth,
mapHeight, layers: [{name, collider, tiles: [{id, x, y}]}]}`. `bonfire:
3.17.0` (already a dependency) ships a reader for this format,
`WorldMapBySpritefusion` + `SpritefusionAssetReader`
(`bonfire/map/spritefusion/...`), whose numeric-id → spritesheet-rect math
matched the file exactly (8-column sheet, confirmed by reading the PNG
header directly). `adventure_world_screen.dart` now uses that reader instead
of `WorldMapByTiled`/`TiledAssetReader`, pointed at the promoted
`assets/images/maps/map.json`.

Two things needed fixing in the exported data itself, not just the loader:
- **Every layer had `"collider": false`** — the exporter's default, meaning
  nothing in the map blocked movement. `walls`, `Wall Texturing`,
  `structures`, `structures mre`, `more Structures`, and `Structure Ground`
  were flipped to `true` directly in `map.json` (a judgment call from the
  layer names themselves — decorative ground layers like `floor`/`terrain`/
  `playground` stayed walkable). If new layers get exported later, re-check
  which ones should collide.
- **The placeholder spawn (`Vector2(64, 64)`) had no relation to this map.**
  Picked tile (25, 25) instead — the map's centre, an open fenced
  playground area with a fully clear 3×3 neighbourhood once colliders were
  applied — by scanning the layer data programmatically, not by eyeballing
  the preview image.

A small nav link was added: Life Sim (`life_sim_page.dart`) now has an
"Explore the town" app-bar action pushing `AdventureWorldScreen`, closing
the gap the screen's own doc comment had flagged ("a map to explore comes
later"). The exported map's layer names (`top_playground`, `structures`,
`walls`, `terrain`, etc.) aren't named for specific buildings, so there's no
building → Life-Sim-event trigger wiring yet — Sprite Fusion's
`objectsBuilder` mechanism supports it whenever a layer gets named for a
zone (job/school/shop/etc.) and someone specifies which event it should
fire.

**A privacy fix — and one that still needs a manual step.** Cross-checking
§9c directly (rather than trusting first-pass research, which had one wrong
claim — there was no existing "under-13 skips the leaderboard" gating
anywhere, contrary to what a first pass assumed) turned up a real gap: the
`leaderboard` Supabase view had no age filtering at all — any self-declared
`under_13` account's username/gold/XP was as publicly rankable as anyone
else's. The view definition in `SupabaseService.schemaSql` now adds `where
coalesce(spending_habits->>'age_band', '') <> 'under_13'`. **This is a code
change to the documented SQL only — it has not been applied to the live
Supabase project.** Re-run the updated `create or replace view
public.leaderboard as ...` statement in the Supabase SQL editor for it to
take effect; until then the live view is unfiltered.

Other things the audit surfaced but left alone, since they're either
working-as-intended tradeoffs or a product/policy call rather than a bug:
the `pending_feedback_queue` SharedPreferences cache holds a user's email +
feedback text in plaintext until it syncs (normal `shared_preferences`
behaviour, but worth knowing for an offline device); the `profile_pictures`
storage bucket is public-read by design; the `profiles` table (role, email,
disabled flag) has no tracked migration file, same as noted for `user_stats`
elsewhere in this doc.

**Content tone.** A couple of `kLifeEvents` outcome lines
(`life_sim_models.dart`, the `first_words` event) leaned on idioms/hyperbole
("Demanding from day one", "already exhausted") that a literal-minded young
reader might not parse as intended — reworded to be more literal while
keeping the playful tone. This was a light, representative pass, not a full
sweep of the event pool; Academy lesson prose (`lesson_detail_screen.dart`)
was deliberately **not** touched — it's Curriculum Department-owned content
per the org's structure, not something to rewrite unilaterally from the App
Development side.

## 15. Eco Impact — a Climer-inspired feature set

The user watched a demo of **Climer**, a Congressional App Challenge-winning
app gamifying carbon-footprint reduction (weekly habit tracker, adjustable
task catalog, structured "paths," a growing/moody pet, impact stats with a
calendar heatmap, friend-code leaderboard), and asked for the same
mechanics inside Budget Buddy. Full systems reference (data flow, animation
triggers, event timing, navigation map) lives in a new, separate doc —
`docs/CLIMER_FEATURE.md` — since the user specifically asked for something
closer to a wiring reference than this file's narrative-log format. What
follows here is the *why*, kept brief on purpose.

**Reused rather than rebuilt:** `UserStatsController`'s `spendingHabits`
jsonb + `_saveStats` pattern (new `eco_*` keys, same as every other
feature — no migration), the Market Board's internal-`TabController`
pattern for a pushed screen with its own sub-navigation (`EcoImpactScreen`'s
Track/Activity/Paths/Pet tabs), the Academy's prerequisite-chain shape for
`EcoPath`/`EcoPathTask` (copied, not literally reused — `Lesson` carries
Academy-specific baggage), and `IdleHoverIcon` for the pet's idle bob
(no new `AnimationController` needed).

**Built new, because nothing existed to extend:** any multi-day task
history (`DailyPlanController` only ever holds *today's* completion set —
not extensible to a weekly grid), any pet growth/mood concept, any
calendar/heatmap widget (hand-rolled, since no such package is a
dependency — consistent with this project's hand-rolled-chart convention),
and — the biggest gap — any friend concept at all. The pet itself has no
dedicated sprite art (none exists, none was generated this session); it's
built from existing Material icons sized up per growth stage, plus a small
hand-painted face, the same "procedural life from existing primitives"
approach `AmbientLottieCard` already uses for its turtle decoration.

**Friendships are a directed edge, not a mutual handshake.** Adding a
friend by code only ever inserts *your own* row (RLS enforces this), so a
friendship reads as mutual once both sides have added each other — no
request/accept flow exists. This is a deliberate MVP simplification,
documented in `CLIMER_FEATURE.md` §5 rather than silently shipped as if it
were true mutual adding.

**Another pending manual SQL step**, same shape as §14's leaderboard fix:
the new `public.friendships` table + its RLS policies were added to
`SupabaseService.schemaSql` but have **not** been created on the live
Supabase project — "Add a friend" will fail gracefully until someone runs
that block in the Supabase SQL editor. Tracked in the `pending-supabase-sql`
memory alongside the earlier leaderboard filter.

A representative test file, `test/eco_impact_test.dart`, covers the pure
logic (pet stage/mood thresholds, date-key math, catalog/path referential
integrity) the same way `test/daily_plan_test.dart` and
`test/lesson_data_test.dart` cover theirs — not the controller itself, which
(like `DailyPlanController`) needs a live/mocked Supabase to instantiate.

**This entire section describes a prototype that got reworked the same
day — see §16.** The file is `test/money_habit_test.dart` now, and every
`Eco*`/`eco_*` name above (`EcoImpactController`, `EcoPetWidget`,
`eco_impact_models.dart`, the `eco_*` jsonb keys) no longer exists in the
codebase. Kept here rather than deleted so the reasoning that led to the
rework is still visible.

## 16. Same-day follow-up: Money Habits, audio removed, more redesign, a bigger curriculum

Direct user feedback landed right after §15 shipped, in one message with
several distinct asks. What happened, in the order it was decided:

**Supabase/friends: false alarm, restored.** "Remove all the saved to
supabase things" was initially read as "remove the new friends/leaderboard
additions" and executed — then the user clarified that wasn't the intent
("that's not what I meant... restore the code"), so every friends-related
change from §15 (the `friendships` table SQL, `SupabaseService.friendCodeFor`/
`fetchFriendsLeaderboard`/`addFriendByCode`, the Global/Friends leaderboard
toggle, Profile's `_FriendsCard`) was put back exactly as it was. Lesson:
when a broad-sounding instruction follows immediately after a summary that
named a specific pending item, the specific item is the more likely
referent — worth confirming before a destructive-sounding edit lands,
not just after.

**Audio removed, on purpose, temporarily.** All files in `assets/audio/`
were deleted — the user is assembling a new audio set to drop in later and
wanted the old set cleared first. `AppSoundService` was already built to
survive this: sound is **off by default** (`enabled = false`), and even
when a user turns it on, every `player.play()` call is wrapped in try/catch
with a `SystemSound` fallback (click/alert) — so a missing asset file was
already a designed-for case, not a new failure mode. The service itself and
the `assets/audio/` pubspec registration were left in place for when new
files land.

**Eco Impact → Money Habits.** The literal carbon-tracking feature from
§15 was reworked into a budgeting-habit tracker per direct feedback ("make
it different... not too similar" to the Climer demo it was modeled on) —
same weekly-tracker/catalog/challenge/companion mechanics, entirely
different subject matter: skip-eating-out and save-spare-change habits
instead of CO2/waste/water, dollars-saved instead of kilograms, a savings
jar (empty → coin jar → full wallet → piggy bank pro) instead of a growing
plant. This was a full rename, not a re-skin: every `Eco*` type, file, and
jsonb key became `Money*`/`Habit*`/`Jar*` (`EcoImpactController` →
`MoneyHabitController`, `eco_impact_models.dart` →
`money_habit_models.dart`, `eco_xp` → `habit_xp`, etc.) — see
`docs/MONEY_HABITS_FEATURE.md` for the full current reference; §15 above is
left as-is as the historical record of the prototype, not updated in place.
The friends/leaderboard system was **decoupled** from the habit controller
in the same pass — `ProfileScreen`'s `_FriendsCard` now calls
`SupabaseService` directly instead of routing through
`MoneyHabitController`, so retheming one can't ripple into the other again.

**A real bug caught by the test suite, twice.** Two rounds of "run the
tests" surfaced real regressions, not flaky infrastructure:
- Adding `MoneyHabitController` to the provider tree (`main.dart`) without
  adding it to the two widget-test harnesses
  (`test/responsive_layout_test.dart`, `test/market_resize_test.dart`) threw
  `ProviderNotFoundException` deep inside pumped widgets — visible as 14
  failures and, separately, a 10-minute hang in `market_resize_test.dart`
  (an uncaught exception mid-gesture-sequence, not a slow test). Fixed by
  adding the same `ChangeNotifierProxyProvider` wiring `main.dart` already
  had to both harnesses.
- Inserting the two new curriculum units (see below) at the *front* of
  `lessonUnits` broke `DailyPlanBuilder._nextLesson`, which walks the list
  in order and quests the first uncompleted lesson node — every existing
  teen/adult account would have been assigned "What Is Money?" as their
  daily quest. Fixed by moving both new units to the *end* of the list
  instead; the Academy's unit strip still displays them first regardless,
  since it groups by `ageStage.minAge`, not list position.

**Redesign follow-through**: the forest palette (`AppTheme.deepForest`/
`darkForest`/`panel`/`panelStrong`) was lightened a second time, and ~15
more screens that still had literal `Color(0xFF0717...)`-style hex
duplicates (rather than referencing `AppTheme`) were migrated onto the
token — so the second lightening pass actually reaches them. Baloo 2 was
extended to two screens that had zero `GoogleFonts` usage at all: the Play
tab (`main_game_page.dart` — the "Play Life" hero card, endings collection,
shortcut cards) and the React Challenge minigame
(`react_challenge_screen.dart` — question/results cards, both AppBars, the
exit-confirm dialog).

**Curriculum: ages 4-6 and 7-10 added.** Two new `AgeStage` values
(`earlyChildhood`, minAge 4; `youngKids`, minAge 7) were added below the
existing `middleSchool` floor, plus two new units — `unit_10` ("Money Is
Real": what money is, that things cost money, saving in a piggy bank) and
`unit_11` ("Saving and Spending": earning an allowance, needs vs wants, a
simple save/spend plan, why banks exist). Each ships full lesson content
(`_lessonLibrary` entries) and a full quiz/practice/test question bank
(`quiz_bank.dart`), same shape as every existing unit — required by
`quiz_bank_test.dart`'s coverage checks, which fail loudly on a unit or
assessment node with no questions.

These two units are a **second, independent root chain**, not gated behind
the existing teen/adult curriculum (unit_1 → ... → unit_9) — a 5-year-old
realistically shouldn't need to clear a 401(k) unit first. This is a
genuine, documented exception to the single-chain assumption
`test/lesson_data_test.dart` used to enforce; that test was rewritten (not
weakened) to check "opens off the previous unit, **or** starts a fresh root
with an empty-prerequisite first lesson" — anything else still fails the
test, so a real typo still gets caught.

A structural note on the reading-level tradeoff, discussed rather than
quietly worked around: this app is currently text-only (no audio, per
above), so a genuinely non-reading 4-6-year-old can't self-serve these
lessons — the unit description says so directly ("best explored together
with a grown-up or older sibling") rather than pretending the format fits
the audience perfectly.

## 17. The town becomes a game, and a collision bug worth remembering

### The bug I got wrong twice

Two sessions running, the Adventure map was reported as "colliders are not
implemented" while I had claimed the opposite. The claim was based on
checking the **map data** — every structural layer in `map.json` does carry
`"collider": true`, and Bonfire really was building `RectangleHitbox`es from
them. What I never checked was the other half of a collision: the player.

Bonfire 3.17's `SimplePlayer` mixes in `Movement, Attackable, Vision,
PlayerControllerListener, MovementByJoystick` — and **not**
`BlockMovementCollision` — and ships with no hitbox. Only `PlatformPlayer`
and `PlatformEnemy` get the mixin in this version. So the world was full of
hitboxes and the player had nothing to collide with, and walked out of the
map into black void exactly as reported.

The lesson generalises past this bug: *verifying one side of a two-sided
system and reporting it as verified is the same as not verifying it.* The
fix (`TownPlayer with BlockMovementCollision` + a feet-shaped hitbox) is in
`docs/ADVENTURE_TOWN.md` §1, and `test/town_map_test.dart` now pins it
through the type system so it cannot silently regress.

### The town became an actual game

Prompted by wanting something in the shape of an exploration RPG — walk
around, bump into things, get an outcome — the map went from a walking
simulator to a loop:

- **6 interactable places** (store, bank, school, job board, home, notice
  board), each a money decision whose data shape deliberately mirrors the
  Life sim's `LifeChoice`, so both halves of the app teach with one grammar.
- **8 coin pickups** on verified-walkable tiles.
- **An objective bar** ("visit every place"), a proximity prompt, a decision
  sheet, and an outcome dialog that explains *why* the choice went the way
  it did — the beat that turns a stat change into a lesson.
- Rewards route through the existing `applyChallengePayload` sink, so no
  second economy.

Full reference: `docs/ADVENTURE_TOWN.md`. One deliberate non-fix documented
there: map row `y=37` is solid across its whole width, sealing off the
bottom fifth of the map. That's the user's exported art and "delete some
walls" is a design call, so it's flagged rather than silently edited.

### Home lost its second daily system

"Today's Plan" (the lesson/practice/arcade quest board) came off Home
entirely, and Money Habits took its place as *the* daily task — one card
that shows today's pending habit, or prompts you to pick a first one, or
says you're done. `DailyPlanBuilder`/`DailyPlanController` were **kept**,
not deleted: they're real, tested code, and removing a working system on a
guess is worse than leaving it unreferenced from Home.

### Typography, finally at the root

Three separate rounds of "the font is still bad" traced to one cause I kept
treating as a call-site problem: `AppTheme`'s `bodyMedium` is Quicksand, and
a bare `TextStyle(...)` **merges onto the ambient `DefaultTextStyle`**. So
every heading written as a plain `TextStyle(fontSize: 20, fontWeight: w900)`
silently rendered in the rounded body font, sitting right next to headings
that had been explicitly set to the pixel font — which is what read as
"inconsistent" on screen.

Fixed by sweeping every `TextStyle` block containing `FontWeight.w900` (the
app's de-facto heading weight) to `GoogleFonts.pixelifySans` across 19
files. That required dropping `const` from those styles, which then broke
`const` on the enclosing widgets — 30 `invalid_constant` errors, fixed by a
script that walks up to the enclosing constructor and strips its `const`,
plus two grandparent cases (`const Expanded(child: Text(...))`) done by
hand. Body prose stays Quicksand on purpose: pixel fonts are hard to read
in long paragraphs, and lesson content is long paragraphs.

### Backgrounds: boosted, not dimmed

Screens were painting detailed pixel art and then burying it under a
~0.6-alpha near-black wash — the cheapest way to keep text readable and the
fastest way to flatten art into one dark slab. `VividBackdrop`
(`widgets_custom_lotties/vivid_backdrop.dart`) does it the other way round:
a real saturation + brightness **colour matrix** (the maths behind an image
editor's vibrance slider), then a much lighter scrim and an edge-weighted
vignette whose `stops` keep the middle ~55% completely clear. Applied to
Style and Profile; Market Board and the Life sim keep their dark treatment
because dense numeric UI genuinely reads better on flat dark.

Profile also got its cards changed from `white @ 5%` (effectively invisible
over a busy tile background, which is what read as "so much white space")
to a translucent solid panel, and its badge grid tightened from 84px/10px
spacing to 72px/6px.

### Curriculum: sourced, not invented

New practice questions were written from named, checkable sources and cite
them inline, because this is the part of the app that claims to teach:

- **[FICO]** myfico.com — payment history 35%, amounts owed 30%, length
  15%, new credit 10%, credit mix 10%.
- **[SEC]** investor.gov — compound interest is interest on principal *and*
  accumulated interest; Rule of 72 (72 ÷ rate ≈ years to double, most
  accurate 6-10%).
- **[CFPB]** consumerfinance.gov — emergency savings guidance (at least
  about a month of income as a first target).

They're spread into units 2/3/4's existing practice banks rather than
replacing anything. `quiz_bank_test.dart`'s answer-key-balance guard (no
option position above 40%) still passes with them added.

## 18. Making it feel like a game, not a set of screens

### A second proportions bug, same family as the collider one

The walk cycle looked wrong for every skin, and the cause was the same
*shape* of mistake as §17's collision bug: a value that looked reasonable in
isolation and was never checked against the thing it had to match. The
villager sprite cell is 104×152; the player was sized `Vector2.all(32)`, a
square. Every character was squashed.

Fixed by naming the ratio once (`AppAssets.villagerAspectRatio`,
`npcAspectRatio`) and sizing height-first everywhere. Documented in
`docs/ADVENTURE_TOWN.md` §9 so the next character type does not repeat it.

### The town got people

Six NPCs — Tax Collector, Shopper, Careful Spender, Shift Worker, Student,
Neighbour — using the **real sprite sets already sitting unused in the
repo** (`tax-guy/`, `customer_more_animations/`,
`employee_or_background_character_information/`). Those were one-PNG-per-frame
rather than sheets, so they load as sprite lists and each folder had to be
registered in `pubspec.yaml` individually.

NPCs deliberately carry no stat changes — just cycling lines of advice.
Places make you decide; people just talk. Mixing both into "every
interaction is a decision" would have made walking around feel like a
worksheet.

### The town now belongs to a life

Per direct instruction, you can no longer drop onto the map as a standalone
mode: Home's hero starts a Life run, and the town opens from inside it. That
also removed a redundancy — Home had a hero *and* a "Play Life" card both
routing to `/life`, which is two primary actions competing. One now.

### Money Habits was unusable without explanation

Direct feedback: *"I have no idea where I'm clicking and what this thing
does."* Fair — a first-time user landed on four one-word tabs ("Track",
"Activity" — near-synonyms) and an empty grid.

- Tabs renamed and given icons: **My Week / Find Habits / Challenges / My
  Jar**.
- A three-step "How this works" diagram (pick → log → fill the jar) shows
  **only until the first habit is saved**, then gets out of the way.
- Empty states now name the tab to go to instead of describing the feature
  abstractly.

### Life sim: 75 → 95 events

The pool clustered at 14-28. Ages **10-11 had literally zero eligible
events** — a life skipped silently through them. Added a fill-the-gaps pack
(late 20s through 60s: moving in, car repairs, raise-vs-time-off, scam
calls, market drops, retirement-fee reviews) and an early-childhood pack
(ages 4-8).

`life_variety_test` gained a childhood-starvation guard mirroring the
existing adult one — and it **immediately failed at age 5 with only two
eligible events**, which is exactly why it was worth writing rather than
eyeballing the list. The early pack exists because that test caught it.

Composition is done with const spreads (`_kLifeEventsCore` +
`kLifeEventsExtra` + `kLifeEventsEarly` → `kLifeEvents`) so the sets stay
separately readable rather than being merged into one 95-entry literal.

## 19. Menus instead of a big Age button, and the camera reversal

### The camera now clamps — reversing an earlier call

§17 documented `moveOnlyMapArea: false` as deliberate: standing at the wall
would show a sliver of void, "the way an open-world edge reads." That was
wrong for this game, and the screenshots made it obvious — the void is a
large black region with nothing in it, not an atmospheric sliver. It is now
`true`, so the camera stops at the map boundary.

Worth recording as a reversal rather than a silent edit: the reasoning was
coherent and still produced a bad result, because it was reasoning about a
genre convention instead of about this specific 50×50 map with hard cliff
borders. The player was never able to leave (the collider ring holds); only
the camera was.

### The Life sim got menus

The core complaint: *"there is not enough options like in the real BitLife
where the menu leads you to more things like study, career, going out on
command instead of just normal making it occurrence."* That is precisely
right, and structural — the sim was **reactive**. Age up, answer whatever
fired. Five bottom-bar slots can only ever hold five verbs.

Replaced with four category menus plus the Age button:

| Menu | Holds |
| --- | --- |
| **School / Career** | Study or take a course, work harder, ask for a raise, quit |
| **People** | Spend time with / buy a gift for each known relationship |
| **Do** (Activities) | Go out, gym, library, doctor, practise a skill |
| **Money** | Invest, net-worth summary |

New on-demand controller actions backing them: `workHarder`,
`askForRaise`, `quitJob`, `visitDoctor`, `visitLibrary`, `spendTimeWith`,
`giveGift`, plus a `hasJob` getter that gates the career actions.

Two deliberate teaching details baked into the menu rather than into a
lesson:

- **`spendTimeWith` is free and gives +8 happiness; `giveGift` costs 50
  coins and gives +5.** The comparison is right there in the list, and the
  player can notice it themselves.
- **The library is the only completely free stat gain.** Also not
  commented on in-game.

Rows show their cost as a chip, and a disabled row states *why* ("You need
a job first", "Not enough coins") instead of being inertly greyed out.

### Entering a building looks like entering a building

Town spot sheets now open with the room interior art
(`building/rooms/room-background-decorated.png`, already in the repo,
newly registered in `pubspec.yaml`) as a header image with the title over
a gradient. Small change, but it is the difference between "a menu opened"
and "I went inside".

### On the BitLife playthroughs

Two full playthrough transcripts were supplied as reference. They are
mostly murder, torture, assassination and child abandonment — that is
genuinely what BitLife contains, and it is why the game is rated 17+.

**What was taken from them: the menu architecture.** On-demand actions
grouped into categories, costs shown up front, options gated by state.
That is the part that makes BitLife feel deep, and it is exactly what this
sim was missing.

**What was not taken: the content.** This app's Academy now runs from age
4-6 upward, so crime-and-violence mechanics are off the table — not as a
judgement of BitLife, just a different audience. Recorded here so a future
session does not read "make it like BitLife" as unfinished work.

## 20. Bottom nav restructure, phone API keys, and a default-tab bug

### Home moved to the middle

`PopNavBar.appTabs` (`lib/ui/widgets/pop_navbar.dart`) is now five slots —
**Life, Learn, Home, Daily, Profile** — with Home in the centre slot and
Arcade/Style dropped from the bar entirely. `AppTabIndex`
(`lib/navigation_tools_and_animation/app_tab_index.dart`) mirrors that
exactly:

```dart
static const int adventure = 0; // Life
static const int academy = 1;   // Learn
static const int dashboard = 2; // Home
static const int daily = 3;     // Daily (Money Habits)
static const int profile = 4;
static const int count = 5;
```

`MainNavigation`'s `IndexedStack` (`main_navigation.dart`) must list its
five children in that same order — position, not just index, has to match
`PopNavBar.appTabs` or a tap lands on the wrong screen.

**Arcade and Style are now pushed routes, not tabs.** `MinigamesPage` and
`CustomizeScreen` still render fine standalone (their `onNavSelected`
becomes optional; `null` means "show your own AppBar back button instead
of a bottom nav"). Every call site that used to switch tabs now does
`Navigator.of(context).pushNamed('/minigames')` /
`pushNamed('/customize')` — see `main_game_page.dart`'s Arcade shortcut
card and `home_screen.dart`'s `onOpenArcade`/`onCustomize` callbacks.

**Daily replaces the old daily-board tab** and is `MoneyHabitsScreen`
(§16), now built to double as a tab: it takes an optional
`activeTabIndex`/`onNavSelected` pair the same way every other tab screen
does, and shows `CustomBottomNav` only when `onNavSelected` is non-null.

**Label text was bumped** (8/9.2/10.2 → 11/12.5/14 across the
veryTight/dense/normal breakpoints) because the old size read as
decorative rather than readable — dropping from six tabs to five freed the
width for it. This didn't fit in the old bar height as-is: the label's
+3px pushed the tile 3px past `barHeight`, causing an "overflowed by 3.0
pixels on the bottom" on every screen using the bottom nav. `barHeight`
was bumped alongside it (66/74/90 → 70/78/94) to make room.

### A default-tab-index bug this restructure introduced

`DashboardShell` used to default `initialIndex` to a literal `0`. Before
this restructure, tab `0` happened to be Home, so nobody noticed the magic
number. After the restructure, `AppTabIndex.adventure` is `0` — so a bare
`const DashboardShell()` silently started the player on the **Adventure**
(Bonfire game world) tab instead of Home. That default is used in five
places: the `/game` route, and all three branches of `_AppBootstrapGate`
in `main.dart` — meaning every fresh sign-in would have dropped straight
into the game world.

Fixed by defaulting to the named constant instead of a bare literal:

```dart
const DashboardShell({super.key, this.initialIndex = AppTabIndex.dashboard});
```

This also explains why `test/market_resize_test.dart`'s
`DashboardShell()`-based resize test hung for a full 10-minute timeout
during this fix: it was booting straight into the Bonfire `GameWidget` and
driving it through a dozen resize steps, which is a much heavier path than
the Home screen it was meant to be exercising. **Lesson for next time a
tab constant changes value: grep for every bare numeric literal or
un-named default that assumes today's index order** — `initialIndex = 0`
reads perfectly reasonable until the meaning of `0` moves under it.

### Two responsive-test fallouts from the restructure

`test/responsive_layout_test.dart` had a `'Dashboard shell tabs'` group
hardcoded to the old tab names (`Adventure, Arcade, Style, Academy,
Profile`) — updated to match `PopNavBar.appTabs` exactly
(`Life, Learn, Home, Daily, Profile`).

Separately, `_ObjectiveIconButton` on Home (the quick-action row: World /
Daily / Arcade / Academy / Style) hides its label below 70px of available
width per button — with five buttons now in that row instead of four, the
smallest phone-width test (340×480) pushes every button under that
threshold, so the label text disappears and `find.text('Academy')` no
longer finds it. Fixed the test to find the button by its `Tooltip`
instead (the tooltip message is always set, icon-only or not), and to
`ensureVisible()` it first since the row sits below the fold in Home's
`SingleChildScrollView` at that height.

### Phone API keys: `--dart-define-from-file`

The actual bug behind "I can't log in or use Market Board on my phone":
`readRuntimeEnv()` (`lib/config/runtime_env_io.dart`) checked
`Platform.environment` and a local `supabase.env.json` file, in that
order — but on Android/iOS, `Platform.environment` is empty and
`File('supabase.env.json')` resolves against a working directory that
isn't the project folder. Both sources silently returned `null` on a real
device, even though a code comment claimed release builds relied on
`--dart-define`. Nothing ever actually read one.

Fixed with `lib/config/runtime_env_defines.dart`, which wraps every key in
a literal `String.fromEnvironment(...)` call (a `--dart-define` value only
exists at compile time as a constant — it cannot be looked up by a runtime
string key) and normalizes the empty-string default to `null`. This is now
checked *before* the JSON-file fallback (`--dart-define` should win over a
stale checked-out file), and is the **only** source on web (there is no
filesystem or `Platform.environment` there either — see
`runtime_env_stub.dart`).

**To build with your keys baked in, use `supabase.env.json`'s existing
format directly:**

```bash
flutter build apk --dart-define-from-file=supabase.env.json
```

This works with the same JSON shape already documented in
`supabase.env.json.example` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`FINNHUB_API_KEY`, `TWELVE_DATA_API_KEY`) — no separate `--dart-define`
flags needed per key. `flutter run --dart-define-from-file=supabase.env.json`
works the same way for a device/emulator debug run. Without this flag, a
phone build has no Supabase/market keys at all and runs in local-only mode
(no login, no live quotes) — which is exactly the symptom reported.

### Follow-up: Arcade and Style came back as tabs, Home got a circular badge

Same session, immediate follow-up request: bring Arcade and Style back as
bottom tabs (seven slots total) and give Home a distinct circular look.

`AppTabIndex` is now 7 wide: `adventure(0), academy(1), minigames(2),
dashboard(3), daily(4), customize(5), profile(6)` — Home stays exactly in
the middle (`length ~/ 2`). `PopNavBar.appTabs` mirrors it: Life, Learn,
Arcade, Home, Daily, Style, Profile. `MainNavigation`'s `IndexedStack` grew
two more children (`MinigamesPage`, `CustomizeScreen`) in the matching
slots. The `/minigames` and `/customize` routes went back to wrapping
`DashboardShell(initialIndex: ...)` instead of pushing the bare screen —
consistent with `/dashboard`, `/daily`, `/lessons` — and Home's
Arcade/Style quick-action buttons and the Adventure hub's Arcade shortcut
went back to `onNavSelected?.call(AppTabIndex.minigames/.customize)`
instead of `Navigator.pushNamed`.

**The circular Home badge:** `PopNavBar` computes `isCenter = i ==
items.length ~/ 2` per tab and threads it into `_PopNavTile`. Every other
tab keeps the original rounded-pill background; the center tile instead
gets no background of its own and renders its icon inside a fixed-diameter
`BoxShape.circle` container (36/40/46px across the veryTight/dense/normal
breakpoints) — filled with the active accent when selected, a dark
neutral fill with a thin accent-tinted ring when not, so it still reads
as "the special one" even at rest. The label sits below it exactly like
every other tab, just recolored to always sit on the bar's dark
background (white/white70) instead of switching to dark text on an
accent pill, since there is no pill under it.

Packing two more tabs into the same bar meant the `dense` breakpoint
widened from `width < 360` to `width < 420` — seven tabs need the
smaller sizing on more phones than five did — and tile margins/padding
were trimmed a couple of px to keep everything fitting; the label's
`FittedBox` scale-down already absorbs the rest.

**First pass at the badge overflowed by exactly the wrong amount.** The
badge (40px at the `dense` tier) is a lot taller than the plain icon it
replaces (21px), and the first version only clawed back that difference
from `barHeight` and the tile's own padding — the arithmetic landed on an
exact pixel-for-pixel fit (content height == `barHeight`, zero slack).
`flutter test` caught it immediately as "overflowed by 8.0 pixels on the
bottom" on every `DashboardShell`-based test, since `DashboardShell()`
defaults to the Home tab and Home's tile is the one with the badge.
Real-world text/icon metrics don't hit a hand-calculated number exactly,
so an exact fit is never actually safe. Fixed by giving `barHeight`
genuine headroom (70/78/94 → 80/90/106 across the three breakpoints)
instead of trying to compute the tightest value that theoretically works.

### A pre-existing overflow the restructure's tests surfaced

Unrelated to navigation, but caught by the same test pass: `_HowItWorksCard`
on the Daily tab (§16) had two `Row`s (the "How this works" header, and
each step's title row) with a bare `Text` instead of a `Flexible`-wrapped
one, so at 320px width ("small phone portrait", the narrowest tested size)
the text overflowed the row by a few pixels. Both wrapped in `Flexible`
with `maxLines: 1` / `TextOverflow.ellipsis`.

## 21. Market chart fixes, company profile/news, decrowding the nav again, confetti, and a leaderboard redesign

One large follow-up request, covering the Market Board, both bottom-nav
scrollbars, a rewards moment (confetti), and the leaderboard.

### The chart's missing "ball" and gold line color

`PriceChart`'s only per-point marker was `_paintCrosshair` (§13/earlier),
drawn *only* while `hoverIndex` is set. `InteractivePriceChart` — what the
order ticket's full chart actually uses — never sets `hoverIndex` at all
(it only handles pinch/pan, not hover), so on that screen there was
genuinely no marker on the line, ever. Fixed in `price_chart.dart`'s
`_paintLine`: a static filled dot + soft halo at the line's last point,
same idea as `MiniSparkline`'s `livePulse` dot but non-animated (this
chart is redrawn every gesture frame during pinch/pan; a running
`AnimationController` on top of that felt like the wrong trade).

**Line color** was the caller's fixed per-symbol `accent`, i.e. gold
regardless of whether the stock was up or down. Two other `PriceChart`
call sites in `stock_market_page.dart` already compute a rising/falling
color and pass it in as `accent` — `PriceChart` itself was never meant to
own that decision. `order_ticket_page.dart`'s `_ChartSection` now has a
`_lineColor` getter (`bars.last.close >= bars.first.close ? _up : _down`,
computed off whichever candles are currently on screen — so the color
tracks the selected range button, not a fixed day-change figure) and
passes that instead of `accent` to `InteractivePriceChart`.

### Company profile & news — API choice and why it scales

New tab inside the order ticket's existing "Show additional details"
pattern: a collapsible "Company background & news" section with its own
Profile/News toggle (`_CompanyProfileAndNewsSection`), lazy-loaded only
once expanded so a normal trade never spends the extra calls.

**API: Finnhub, reusing the existing `FINNHUB_API_KEY`.** Its free tier
already includes `/stock/profile2` (company background) and
`/company-news` (recent headlines) — no new key, no new vendor to manage.
Both new methods on `MarketDataService` — `fetchCompanyProfile` /
`fetchCompanyNews` — go through the exact same proxy-first,
direct-key-fallback path as quotes/search/candles (§9d), so the
"free API that can handle ~1000 users/minute" requirement is met the same
way it already is for quotes: the Supabase edge function
(`supabase/functions/market/index.ts`) caches responses per-instance —
profile for 1 hour (it barely changes), news for 15 minutes — so a
thousand players reading AAPL's profile cost one upstream Finnhub call,
not a thousand. The client adds its own second layer on top (profile
cached indefinitely per session; news cached 15 minutes per symbol) so
even a signed-out/no-Supabase dev build doesn't hammer a direct key.

**Deploy caveat, same class as the pending leaderboard SQL noted earlier
in this doc**: the `profile` and `news` cases were added to
`supabase/functions/market/index.ts` in this repo, but an edge function
change only takes effect after running

```bash
supabase functions deploy market
```

Until that's run, `fetchCompanyProfile`/`fetchCompanyNews` will 400
("unknown op") through the proxy — the UI degrades to its "not available"
empty state rather than crashing, same as every other market fetch
failure in this app, but the feature is genuinely not live until deployed.

### The bottom bar got crowded again, so Learn and Profile moved to the top

Seven tabs (Life/Learn/Arcade/Home/Daily/Style/Profile, §20) was one
request too far — "moving the setting and profile tab to the top and
academy to learn on the top would be the best idea." `AppTabIndex` keeps
all seven positions (`adventure(0), minigames(1), dashboard(2), daily(3),
customize(4), academy(5), profile(6)` — Home still exactly centered among
the *bottom five*), but `PopNavBar.appTabs` now lists only five: Life,
Arcade, Home, Daily, Style. Academy and Profile still get real
`IndexedStack` slots in `MainNavigation` — switching to them works exactly
like any other tab — they are just not among `PopNavBar`'s five, so the
bottom bar never tries to highlight either of them.

A new `_TopIconBar` in `main_navigation.dart` sits above the
`IndexedStack` (the two are siblings in a `Column`, `IndexedStack` wrapped
in `Expanded`) with two pill buttons, Learn and Profile, styled to match
the bottom bar's active/inactive treatment (`_activeAccent` fill when
that tab is current). It is visible on every tab, not just Home, so
Learn/Profile are reachable the same way from anywhere.

### Confetti

New `lib/widgets_custom_lotties/confetti_burst.dart` —
`ConfettiBurst.show(context)`, same static-overlay shape as `GameToast`
and `AchievementCelebration` (an `OverlayEntry` on the root overlay,
auto-removes itself). Hand-rolled `CustomPainter` (rectangles + rounded
rects falling with a sine-wave wobble and rotation, no package), not
reusing `AchievementCelebration`'s spark painter — that one is a modal
`Dialog` for the deliberate, tap-to-view badge moment; this is meant to
layer over whatever's already on screen without interrupting it.

Wired to two events:
- **A quiz/unit test scored ≥70%** (`lesson_detail_screen.dart`,
  `_nextQuestion` — the same "5/7 or better" bar the request named,
  ⁠`_correctCount / _quiz.length >= 0.7`). Fires once, exactly as the
  results card appears, not on every rebuild while viewing it.
- **A new personal-best arcade score** (`minigames_page.dart`, both
  `_openFinanceBrawl` and `_openReactChallenge`) — reads
  `stats.bestArcadeScore(gameId)` *before* calling the existing
  `recordArcadeRun`, compares the new score against it, and only
  celebrates when there was a previous best to beat (a first-ever run
  isn't "new," it's just a first run).

### Leaderboard: Most Gold, a hall-of-fame podium, and a real Home entry point

`SupabaseService.fetchLeaderboard`/`fetchFriendsLeaderboard` both take a
new `byGold` flag that swaps the Postgres `.order()` sequence to lead with
`gold` — a **separate server-ordered query**, not a client-side re-sort of
the literacy-ranked page, because the top-20-by-literacy page can easily
exclude someone who actually is top-20 by gold; re-sorting the wrong page
would just hide them. `LeaderboardScreen` gained a second toggle (`_byGold`
alongside the existing `_showFriends`) — `_MetricToggle`, "Finance
Wizards" vs "Most Gold" — orthogonal to the Global/Friends toggle, so all
four combinations work.

**Podium**: the top 3 of whichever ranking is active render as
`_HallOfFamePodium` (1st centered and tallest, 2nd left, 3rd right, medal
colors gold/silver/bronze, a crown on 1st) above the regular list, which
now starts at rank 4. Handles fewer than 3 entries by rendering an empty
placeholder stand rather than reflowing the layout.

**More apparent**: the only previous entry point was a small trophy
`IconButton` in Home's `AppBar`. Home now also has a `_LeaderboardPromoCard`
(same visual family as the Adventure/Money-Habits promo cards already on
Home) showing the player's own gold total and a CTA into the leaderboard.

### A Scrollbar bug hit twice, in two different ways

Both new scrollbars (`money_habits_screen.dart`'s `TabBar`,
`order_ticket_page.dart`'s range-chip row) needed two attempts.

**First attempt** — plain `Scrollbar(thumbVisibility: true, ...)` with no
explicit `controller` on both. This crashed `flutter test` immediately on
every `DashboardShell`-based test: `MainNavigation`'s `IndexedStack` keeps
all seven tab screens mounted at once (not just the visible one), and
several of them have their *own* vertical scroll view with no explicit
controller — which all default to attaching themselves to the single
ambient `PrimaryScrollController` for the route. A `thumbVisibility`
`Scrollbar` with no controller of its own falls back to that same ambient
controller — which by then already has several `ScrollPosition`s attached
from the other tabs — and `thumbVisibility: true` asserts there must be
exactly one. Error: *"The PrimaryScrollController is attached to more than
one ScrollPosition."*

**Second attempt** — wrapped both in `PrimaryScrollController.none(child:
...)` to shadow the ambient controller and force notification-based
tracking instead. This fixed the crash but broke a *different* assertion
immediately: `thumbVisibility: true` requires a real, non-null
`ScrollController` to bind to — with the ambient one hidden and no
explicit one supplied, there was nothing left for it to use. Error: *"A
ScrollController is required when Scrollbar.thumbVisibility is true."*

**What actually fixed it, and why it differs per widget:**
- `order_ticket_page.dart`'s scrollable is a plain `SingleChildScrollView`
  the code already builds — it can take an explicit `ScrollController`
  directly. Added `_rangeScrollController` as a real field on
  `_OrderTicketPageState` (created once, disposed in `dispose()`, same
  pattern as `_priceController`/`_quantityController`), passed to *both*
  the `Scrollbar` and the `SingleChildScrollView`. `thumbVisibility: true`
  works correctly now that there's exactly one real controller with
  exactly one attachment.
- `money_habits_screen.dart`'s scrollable is `TabBar`'s **internal**
  horizontal scroll view when `isScrollable: true` — Flutter's `TabBar`
  does not expose that internal `ScrollController` through any public
  parameter, so there is no way to hand it an explicit controller at all.
  Dropped `thumbVisibility`/`trackVisibility` entirely and left `Scrollbar`
  in its default mode, which needs no controller — it tracks scroll
  notifications bubbling from any descendant and shows a fading thumb
  while a drag is in progress. Less permanently visible than a
  `thumbVisibility` thumb, but a real, correct discoverability cue instead
  of a crash.

**Lesson for next time a Scrollbar goes over an existing scrollable inside
an `IndexedStack`-based nav shell:** `thumbVisibility: true` needs an
explicit `ScrollController` attached to the *specific* scroll view it's
meant to track — never rely on the ambient `PrimaryScrollController` for
it once more than one tab's own scroll view could be alive at once, and
check first whether the target widget (`TabBar`, `TabBarView`, etc.) even
exposes the controller you'd need before reaching for `thumbVisibility`.

## 22. Teaching the thing the app is named after

The request behind this whole round: *"right now we are just incorporating
many different features but I don't think it's teaching people to learn
budgeting or finance but instead they are just playing the game."*

That is a fair read of what the app had become, and it is the most
important note anyone has given this project. See `docs/CHALLENGES.md` §1
for the design reasoning; this section is the wiring.

### `FinanceConcept` — the ideas, in one place

`lib/models_Like_Skins_and_lessons_templates/finance_concepts.dart` holds
sixteen money ideas (needs vs wants, opportunity cost, pay yourself first,
50/30/20, emergency fund, compound growth, the cost of borrowing, credit
score, inflation, diversification, income vs wealth, insurance, taxes,
impulse buying, sunk cost, lifestyle creep).

Each carries **two reading levels**:

- `kidExplainer` — roughly ages 4-10. One concrete sentence, no
  percentages, framed on pocket money and snacks.
- `explainer` — 11 and up. The real term, a real number, something
  actionable.

`explainerFor(simple: …)` picks between them. The flag comes from
`AgeBand.prefersSimpleWording` — the **player's** self-declared band, not
the in-game character's age. A nine-year-old running a forty-year-old
character still needs the nine-year-old wording.

`AgeBand.prefersSimpleWording` deliberately does **not** reuse the existing
`representativeAge`, which returns `12` for the under-13 bucket and would
therefore route every child to the adult copy. That bucket spans about 4-12,
so there is no honest single age for it; the useful question is "does this
reader need plain wording", and for the whole bucket the answer is yes.

### The teaching moment

`LifeChoice.teaches` is an optional `FinanceConcept`. When a choice with one
is taken, `LifeSimController.chooseOption` calls `_teach()`, which records
it in `conceptsMet` and queues it. The UI drains the queue via
`takeLesson()` — exactly once, so a lesson can't re-show on every rebuild —
and shows `_MoneyLessonSheet`.

Timing is the point: the sheet appears **after** the outcome text, not
instead of it. The player sees what happened, then gets told what it was
called. `_drainLesson` is called after choosing, after ageing (which can
fire a shock) and after budgeting.

Plenty of events stay pure story with no `teaches` — bolting a lesson onto
every beat would make all of them feel like homework.

### `kLifeEventsMoney` — fifteen events that always teach

A separate list in `life_sim_models.dart`, composed into `kLifeEvents`
alongside the core/extra/early packs. Every choice in it sets `teaches`,
and **both branches of an event teach the same concept** — picking the
worse option is the more instructive path and must not be met with silence.
Both properties are enforced by `test/budget_teaching_test.dart`.

Spread deliberately across ages: three events pitched at ages 5-11 (two
jars, needs vs wants at the shop, sleeping on an impulse buy), three at
teens (savings goals, the first payslip, a phone contract's total cost),
and nine adult ones (raises, credit cards, investing early, hot tips,
insurance, sunk cost, two job offers, an income shock, price creep).

### The budgeting exercise

`_BudgetSheet` in `life_sim_page.dart`, reached from the Money menu (top
item, above investing — it is the skill the app exists to teach).

The player splits take-home pay across needs / wants / savings with 5%
steppers. Design decisions that carry the teaching:

- **It must total exactly 100.** Save stays disabled otherwise. That
  constraint *is* the lesson — a budget is a fixed pie, so raising one
  slice visibly cuts another, and the player feels the trade-off with their
  thumb rather than reading about it.
- **There is no single right answer.** 50/30/20 is a labelled reference on
  each row and a "Use 50/30/20" shortcut, not a win condition. The feedback
  line names the trade-off ("Needs are eating 65% — that is the number to
  attack") instead of grading.
- **Austerity is punished too.** `_applyBudget` docks happiness when wants
  ≤ 5%, because a budget with no room to live in is one that gets abandoned
  in week two. Setting savings to 100% is not the winning move.
- **Percentages stay attached to money.** Each row shows what its slice is
  worth in coins, so the numbers never float free of the salary.

### Consequences, which is what makes it stick

`LifeSimController` gained a real money model:

| Field | What it does |
|---|---|
| `_needsPct` / `_wantsPct` / `_savingsPct` | the split, defaulting to 50/30/20 |
| `_emergencyFund` | what the savings slice banks, kept separate from cash |
| `_debt` | accrues **18% a year**, with 30% of cash going to repayment |
| `emergencyMonths` | fund ÷ monthly needs — teaches the 3-6 month yardstick |

`_applyBudget` runs each earning year: funds needs, spends wants, banks
savings, then charges interest. Underfunding needs costs health and
happiness *and* still takes the money — you cannot decide rent is cheaper
than it is.

`_maybeFinancialShock` fires roughly one earning year in seven: a car,
boiler, dentist or vet bill. `applyShock` walks the same ladder a real
household does — **emergency fund first, then cash, then borrow** — so the
identical event is a shrug for a player who saved and the start of a debt
spiral for one who did not. Without this, saving is a number that only ever
goes up and the player never learns why anyone bothers.

`netWorth` now reads `cash + investments + fund − debt`, so a high salary
financed by borrowing does not read as wealth. That is the income-vs-wealth
lesson made structural rather than stated.

### Where the player sees it accumulate

The Money menu gained "Money ideas you have met", opening `_ConceptsSheet`
— a running list with a `met / total` counter, so the learning visibly
builds instead of each lesson vanishing after its sheet is dismissed.

### `startJob` / `startSalary`

`LifeSimController` gained these constructor parameters alongside the
existing `initialAge` / `startMoney`. Budgeting needs income, and the only
route to a salary was a random life event — so testing the budget path
otherwise meant simulating twenty years and hoping. Added as real API
rather than a test backdoor, since a "quick start" mode would want exactly
this.

---

## 23. Same round: the hill, the walk, the app bar, and two more scrollbars

### The hill is sealed

`assets/images/maps/map.json` gained a `terrain_hill` layer: the rows 34-36
tiles moved out of `terrain` (which is `collider: false` because it also
holds walkable dirt paths) into their own layer with `"collider": true`,
inserted adjacent to `terrain` so draw order is unchanged.

Row 34 had a six-tile hole at x=29..34 and rows 35-36 had no collision at
all, so the player could walk in through the gap and stand inside the
hill — see `docs/CHALLENGES.md` §3 for the collision-grid dump.

Knock-on: the highest-value coin sat at (27, 36), now inside a wall, and
moved to (47, 32) — still the longest walk on the map, still north of the
hill.

The regression test flood-fills from spawn rather than checking the band
tile-by-tile, because a per-tile check would still pass if a later map edit
opened a route *around* the ends. It also asserts >600 tiles stay reachable,
so it cannot pass by walling the player into a closet.

### Walk timing

`kTownWalkSpeed` (60) and `kTownWalkStepTime` (0.07) in
`adventure_world_screen.dart`, replacing bonfire's default 80 and a
`stepTime` of 0.12. These are **one setting, not two**: 8 frames is 2
footfalls, so `speed × 8 × stepTime` is the two-step stride. It was 2.4
tiles per footfall on a 2.1-tile-tall character — the feet visibly skated.
Now 1.05.

`TownPlayer` forwards `speed` to `SimplePlayer` so the caller can tune it.

**Still partial, honestly.** The art itself has the torso frozen across all
8 frames with one leg extending below the standing foot line, so the legs
accordion by 15px while the head stays pinned. That cannot be fixed by
repacking — the cell has 2px of headroom above the head and 0 below the
feet, so lifting the extended frames clips the hat. Fixing it properly means
re-celling every sheet taller and re-normalising, which changes
`villagerAspectRatio` and ripples into every avatar and preview in the app.
Full measurements in `docs/CHALLENGES.md` §2.

### The app bar

`_TopIconBar` in `main_navigation.dart` is now **Learn — Budget Buddy —
Profile**. Putting the wordmark between the two pills turns what was two
floating buttons into a real, symmetrical app bar: it reads as chrome, gives
the brand a permanent home on every tab, and balances the two pills instead
of leaving a dead gap.

It has a solid fill, an accent hairline underneath, and a soft glow on the
active pill matching the bottom bar's treatment. Below ~380px wide it
tightens padding and drops the label font to 11 — but **never hides the
labels**. An unlabelled icon is the opposite of "more apparent", and the
tab-switching tests find these by text.

### Two more scrollbars

- **Money Habits "Find Habits" category row** — got a real
  `ScrollController` shared with its `Scrollbar`. Its bottom padding was
  trimmed 8 → 2 to pay for the scrollbar's own 8px lane, so adding it costs
  no extra vertical space (the request was explicitly "don't make it too
  dense with the top one").
- **The Academy unit strip** already had a correctly-wired scrollbar; it was
  just the default grey Material thumb on a dark green panel, which reads as
  a rendering artifact. Now themed via `ScrollbarTheme` — mint thumb, faint
  green track, thickness 6, `interactive: true` — so it looks like a control
  you can grab, because it is one.

See `docs/CHALLENGES.md` §4 for the two-crash detour these took.

### Randomise the whole character

`_randomiseAll` in `life_character_sheet.dart` — a "Surprise me" button that
rolls name, gender and origin. The dice beside the name field only ever did
the name.

Origin is **weighted 35/35/22/8**, not uniform. A uniform roll makes
"Wealthy" a 1-in-4 start, which quietly teaches that being born rich is the
normal case; weighting it means most lives begin without a cushion, which is
both closer to reality and the version of this game that has anything to
teach about money.

## 24. Phone-only fixes from real screenshots

The Browser preview pane was dead again this session (see the entry in
`docs/CHALLENGES.md` §9 / the `browser-pane-verification-limits` memory) —
everything in this section was found from real phone screenshots the user
sent, not from anything Claude could see directly.

### Learn ↔ Daily swapped again

`AppTabIndex` values reassigned: `academy=3` (back on the bottom bar),
`daily=5` (top strip). This is the second swap of this pair — the doc
comments on `AppTabIndex` and `_TopIconBar` both say so explicitly and name
the two files (`pop_navbar.dart`, `main_navigation.dart`) that need to
change if it swaps again. Every other file references the named constants,
never a literal tab index, so the swap really is contained to those three
files.

### Finance Brawl's HUD didn't share a width budget

The wave/net-worth HUD and the gold/exit controls were two *independently*
`Positioned` widgets in the game's `Stack` — one centred across nearly the
full screen width via `Align` + `ConstrainedBox(maxWidth: 650)`, the other
pinned to the right edge with `right: 16`. Neither knew the other existed.
On a phone-width screen the HUD's right-hand panel (net worth / "Don't Let
it Hit Zero!") extended *under* the floating gold badge and exit button
instead of stopping short of them.

Fixed by merging both into one `Row` inside a single `Positioned`: the HUD
`Expanded` to take the flexible remainder, the gold/exit controls stay
fixed-size next to it. `_HudStatPanel` already had `maxLines: 1` +
ellipsis on every line, so once it actually received a bounded width
instead of silently overlapping something, the existing text-safety code
did the rest.

### Home's AppBar was pure duplication

Once the global `_TopIconBar` (§23) existed, Home's own `AppBar` — title
"Budget Buddy" / "Level N", trophy leaderboard button — showed nothing that
wasn't already somewhere else on the same screen: the wordmark is in the
global strip, "Level N | Gold" is a chip inside the hero card a few pixels
below, and the leaderboard has its own `_LeaderboardPromoCard`. Removing
the whole `AppBar` (not shrinking it — removing it) cost zero information
and was the actual mechanism behind "too much white space at the top on
phone".

### Leaderboard visual pass

Flat solid-color `Container`s throughout, on a flat solid `AppTheme.
deepForest` scaffold — while every other screen in the app uses `AppTheme.
getPuffyDecoration` and a gradient backdrop. Specific changes:

- Page background → `AppTheme.gradientForest` instead of a flat fill.
- The Global/Friends and Finance-Wizards/Most-Gold toggles were two
  visually near-identical pill bars stacked with nothing showing they were
  different kinds of setting. Merged into one `_FilterPanel` with an
  explicit `SHOW` / `RANK BY` label above each row.
- The podium's "stands" were flat translucent rectangles — now a
  top-lit gradient (lighter at the top edge) plus a colour-matched glow, so
  they read as 3D blocks rather than colored boxes. The whole podium now
  sits inside one elevated gold-tinted stage panel instead of floating
  loose on the page background.
- Regular rows switched from a flat fill + hard black shadow to
  `getPuffyDecoration`, accent-colored gold for the signed-in player.

### The money-lesson sheet is now genuinely un-skippable

`isDismissible: false` + `enableDrag: false` on the `showModalBottomSheet`
call blocks the scrim tap and the swipe-to-dismiss gesture — but not an
Android hardware or gesture *back*, which still pops the route underneath
both of those. Wrapped the sheet's content in `PopScope(canPop: false)` to
close that last gap. "Got it" is now the only way out, on every input
method.

### Confetti, gated to first-time concepts

`ConfettiBurst.show(context)` originally fired on every lesson shown,
including ones triggered by bad news — a repeat `interestCost` lesson from
carrying debt looked like a celebration of going deeper into debt.
`LifeSimController._teach()` now tracks whether the concept was new via a
`pendingLessonIsNew` flag (read *before* `takeLesson()` clears it, since
both describe the same pending lesson); confetti only fires when it is —
"you unlocked a new idea" is true the first time and just noise on a
repeat.

## 25. Town progress persistence, a real sprite fix, and a Browser-pane breakthrough

### Adventure Town progress didn't save — and one coin exploit

`AdventureWorldScreen`'s `_visited` (spot ids) and `_coinsFound` were plain
`State` fields, never read from or written to `UserStatsController`. Every
time the screen was left — even just to check Profile — "visit every
place" silently reset to zero, and every coin on the map came back and
could be collected again for real gold (`_collectCoin` already called
`applyChallengePayload({'gold_earned': value})`; nothing stopped it firing
twice for the same coin).

Fixed by threading both through the existing ad-hoc `spending_habits` jsonb
pattern, no schema change needed:

- `UserStats.townVisitedSpotIds` / `townCollectedCoinIds` — new getters,
  same shape as `savedHabitIds`/`completedLessons`.
- `AdventureWorldScreen.initState` seeds `_visited` and a new
  `_collectedCoinIds` from those on open.
- `_openSpot` and `_collectCoin` both pass the updated set through the
  `spending_habits` key of the same `applyChallengePayload` call they
  already made — no extra network round trip.
- The coin-spawning loop now skips any `kTownCoins` entry already in
  `_collectedCoinIds` entirely, rather than spawning-then-hiding it — the
  cleanest way to guarantee an already-collected coin can never pay out
  gold again.

`kTownCoins` has no id of its own, so coins are keyed by `"x_y"` tile
position (`_coinId`).

### The walking animation — the accordion actually fixed this time

Previous session's fix (stride/frame-rate) was real but partial — see
`docs/CHALLENGES.md` §2, which documented a first attempt at fixing the
"legs accordion" that clipped the hat and was reverted. This session
finished it properly: `tool/normalize_walk_baseline.py` now **re-cells
every sheet 10px taller first** (a pure recentre, cannot clip anything by
construction), *then* clamps the dip within the new, roomier cell. The
module docstring walks through the exact arithmetic and includes an
assertion that refuses to run if the safety margin isn't real.

`AppAssets.villagerCellHeight` moved from 152 to 162 (aspect ratio
104/162 ≈ 0.642, was 104/152 ≈ 0.684); every render site already read the
named constant rather than a literal 152, so nothing else needed to
change. Verified after: `flutter test test/assets_test.dart
test/avatar_sprite_test.dart` (grid-size + aspect-ratio regression
guards) and a direct bounding-box measurement confirming zero clipping
across all 22 sheets and a real body-bob (head Y now varies 5-12px
instead of being frozen at 2px).

### Learn ↔ Daily swapped again; React Challenge relocated into Daily

Second swap of this pair (`AppTabIndex.academy=3` back on the bottom bar,
`daily=5` on the top strip) — see `pop_navbar.dart`/`main_navigation.dart`
doc comments, which now explicitly name themselves as the two files to
touch if it swaps a third time.

Separately: Home had **two different things both called "Daily"** — a
bottom-bar/top-strip destination (the Money Habits screen) and a
same-named quick-action button that launched the React Challenge minigame
*directly*, bypassing that screen entirely. Consolidated: the minigame
(`ReactGameScreen`, `gameId: 'daily_budget_battle'`) moved into Money
Habits' own "My Week" tab as a new `_DailyChallengeCard` at the top; Home's
quick-action "Daily" button now just switches to the tab, same as every
other quick-action button already does.

### The top nav bar got a real identity

`_TopIconBar` was flat-filled and text-only — "I'm not getting that top
nav bar feeling". Three changes:
- `AppAssets.logo` (the turtle mascot, `assets/images/logo.png` — sitting
  completely unused before this) now sits next to the wordmark.
- Flat fill → a top-to-bottom gradient, matching the puffy-card look used
  everywhere else in the app.
- A permanent leaderboard trophy button, next to Profile — previously the
  leaderboard's only entry point besides Home's promo card was a small
  button in Home's own (now-removed) `AppBar`, so it wasn't reachable from
  any other tab.

New `AppAssets` constants for the small pixel-art icon kit at
`assets/images/ui/` (coin/heart/star/bag — also previously unused): swapped
in for the Material "coin" stand-ins at the highest-visibility spots
(Finance Brawl's gold HUD, the leaderboard's Gold stat chip) rather than a
blanket icon replacement across the whole app.

### Leaderboard: top 100, not top 20

`fetchLeaderboard`'s default `limit` and the server-side clamp both moved
from 20/50 to 100. Client-side re-sorting still isn't how `byGold` works —
see §21 — this is purely a bigger page size.

### A Browser-pane breakthrough, and its limits

For the first time this session (after two prior sessions where it never
worked at all — see `docs/CHALLENGES.md` §9 and the
`browser-pane-verification-limits` memory), `computer` screenshots
**worked**. This let three real layout bugs be found and fixed directly
from pixel evidence rather than guessed at:

- Home hero card: "Explore the Town" truncated to "Explore th…"
- Home money-habit promo: "Pick a money habit" truncated to "Pick a money
  ha…"
- Home objective card: "Current Objective" truncated to "Curren…"

All three happened at a **~310px pane width — narrower than any viewport
this app's test suite covers** (the smallest tested breakpoint is 320px).
Each title was a plain `Text(maxLines: 1, overflow: ellipsis)` at a fixed
font size that didn't fit the real available width; fixed by wrapping each
in `FittedBox(fit: BoxFit.scaleDown)`, the same pattern already used
successfully elsewhere in this app (`PopNavBar` labels, the leaderboard
wordmark) — the whole line scales down as one unit instead of truncating
into a fragment.

**What still didn't work**: interactive `computer` clicks. Every
coordinate-based click timed out; dispatching raw `PointerEvent`s via
`javascript_tool` did register (confirmed via visible state changes — the
new "Surprise me" button correctly rolled name/gender/origin together
multiple times) but landed on inconsistent targets relative to what the
screenshot showed, with no discoverable fixed offset. Screenshots and
`javascript_exec` state inspection are reliable this session; coordinate-
based interaction is not. Recorded in the `browser-pane-verification-
limits` memory for the next session.

## 26. Undoing a bad collision fix, the friends bug, and going outside

### The "hill" was a road — undoing §23

§23 sealed map rows 34-36 as a hill. That was wrong, and the map render
proves it: tiles 91/92 (and 289/290 in the `structures mre` layer) are
**flat tan road surface**, identical in colour to every other path in the
town. Sealing them walled off **357 walkable tiles**, including the entire
southern strip — which is exactly the "roads in south are blocked off"
report.

Two separate mistakes had compounded:

1. **Mine (§23):** assuming a wide horizontal band must be a boundary. It
   was a road with fences *beside* it, not a cliff.
2. **The original export:** rows 34 and 37 were tiles `289`/`290` — plain
   road surface — sitting inside `structures mre`, a layer marked
   `collider: true` because most of its contents (barrels, bushes, posts)
   genuinely are obstacles. 91 road tiles were solid purely by layer
   association. That is why row 37 was a complete wall before anything I
   did.

**The real hill** is the stepped cliff-face art on the west side — tile ids
`106/107/109/110`, green top with a brown face, running diagonally around
y≈17-21. Those were fully walkable. They now live in a `terrain_cliff`
layer with `collider: true`.

Result: solid tiles 931 → 761, walkable 1569 → **1739, all reachable**.

**How the tiles were identified**: rendering the actual tileset cells with
their ids next to them, and compositing the whole map with the collision
grid overlaid in red. Both are ~15 lines of Pillow. Reading the collision
data as numbers had already produced one wrong conclusion; *looking* at it
settled it in one pass. Worth doing first next time, not third.

### The test that asserted the bug

`town_map_test.dart` had a test literally named "the hill band is sealed —
nothing south of it is reachable", which passed happily while 357 tiles
were stranded. A test can only be as right as its premise.

Replaced with the invariant that does not need rewriting when level design
changes: **every walkable tile is reachable from spawn**. That catches
over-blocking (a road wrongly made solid) *and* under-blocking, without
encoding any specific band. Plus a narrower "the west cliff face is solid"
test for the thing that genuinely should block.

New `town NPCs` group covers placement: on a walkable tile, reachable from
spawn, no two on the same tile, everyone has dialogue — and **no sprite
clips into scenery**, which found the Student standing where a solid tile
sat two rows above them. The villager sheet is ~2 tiles tall and drawn
upward from the feet, so anything solid at `y-1` or `y-2` shows through the
character's head. Moved (17,17) → (17,21).

### Friends: `operator does not exist: uuid ~~* unknown`

The friends feature had never worked, and the reason was one line.

A friend code is the first 8 hex characters of a user's uuid, so resolving
one is a prefix match. It was written as:

```dart
.ilike('id', '$trimmed%')
```

`leaderboard.id` is a **uuid** column. Postgres has no `ILIKE` operator for
uuid, so every single lookup threw `42883`, got swallowed by a blanket
`catch`, and surfaced as "Could not add that friend right now."

Confirmed directly against the live project (read-only, anon key):

```
/rest/v1/leaderboard?id=ilike.16D8FCDE%
  404  operator does not exist: uuid ~~* unknown
```

uuid *does* have btree comparison operators, so a half-open range says the
same thing, works server-side, and stays indexed:

```dart
.gte('id', '$prefix-0000-0000-0000-000000000000')
.lte('id', '$prefix-ffff-ffff-ffff-ffffffffffff')
```

Verified against the same live data: correct match for a real code, empty
result (not an error) for one that matches nobody. The all-`f` upper bound
rather than incrementing the prefix avoids an overflow edge case on the
code `FFFFFFFF`.

**The blanket catch was the deeper bug.** A precise, actionable Postgres
error existed on every attempt and nobody could see it. `PostgrestException`
is now caught separately, logs `code`/`message`/`details`/`hint`, and maps
the two failures a player can act on (`23503` no such user, `42P01` table
missing) to their own wording.

Also confirmed live: the `friendships` table **does exist** — so the
long-standing "pending SQL" note was half stale. What is genuinely still
missing is the `market` edge function (`/functions/v1/market?op=health`
returns `NOT_FOUND`), and `profile_image_url` on the `leaderboard` view.

### Going outside is now a situation, not a button

`lib/models_Like_Skins_and_lessons_templates/outing_rules.dart`.

"Explore the town" was always enabled — a newborn could walk to the bank.
Three factors now decide, chosen so they differ in *kind*:

| Factor | Changes | Purpose |
|---|---|---|
| Age | grows out of it | the floor: nobody under 6 goes out alone |
| `HouseholdStrictness` | rolled once at birth | makes two runs differ |
| `Weather` | re-rolled every year | makes one run differ over time |

Strictness sets a free-roam age of 10/12/14; from 16 nobody's rules apply.
So at age 11 the same character is free in a relaxed household and grounded
in a strict one — which is the point of having the factor at all.

Weather is weighted (clear 50, rain 24, snow 10, storm 8, heatwave 8) and
**only a storm blocks**. Gating on rain would close the town roughly a
quarter of all years, which is tedious rather than realistic.

Checks resolve age → health → household → sky, so the message always names
the thing that would have to change *first*: a toddler in a storm is told
they are too young, not that it is raining.

When blocked the button stays visible, turns into a padlock, and says why.
Being told "not until you're 14" is content, not an error state.

### A latent RNG bug this introduced, and caught

`strictness` was first written as:

```dart
late final HouseholdStrictness strictness = HouseholdStrictness
    .values[_random.nextInt(HouseholdStrictness.values.length)];
```

A `late final` with a random initialiser consumes its number the first time
anything **reads** it. So the entire downstream sequence — every event
draw, every expense shock — depended on whether the UI happened to check
`outingPermission` on a given frame. Same seed, different life.

Moved to a plain field assigned in the constructor body.
`outing_rules_test.dart` guards it directly: two controllers with the same
seed, one of which reads `outingPermission` early, must still age
identically for 20 years.

### A test that was really testing the RNG

Adding the yearly weather roll shifted the random sequence by one draw,
which made `budget_teaching_test`'s "ageing a year banks the savings slice"
fail — a shock now fired in year one and legitimately emptied the fund.

The assertion was the problem, not the code. "The fund is above N after one
year" is only true if no shock happens, so it was quietly asserting a
property of the seed. Replaced with a comparison between **two
identically-seeded lives** — same shocks in the same years, only the budget
differs — which is the actual claim: saving 20% leaves you better off than
saving nothing.

### Smaller fixes in the same pass

- **A live crash.** The Money Habits category-filter `Scrollbar` used
  `thumbVisibility: true` inside a `TabBarView`, which builds the adjacent
  tab *offstage*. On the frame it is built but not laid out the controller
  has no attached `ScrollPosition`, and a persistent thumb has nothing to
  measure — `Scrollbar's ScrollController has no ScrollPosition attached`,
  thrown on every open of the Daily tab. Dropped to default (fading) mode,
  same reasoning as the `TabBar` one in §21.
- **Finance Brawl's upgrade picker** forced three cards into a `Row` at any
  width, so on a phone each got ~150px and words broke mid-syllable
  ("Perfor / mance Bonus"). Below 520px they stack into a column and each
  card turns on its side (icon beside text) so the description gets a
  readable line length.
- **A new life resets the town.** Visited spots and collected coins persist
  per *player* (§25), which is right within one life but meant a second
  character inherited a fully-explored town.
  `UserStatsController.resetTownProgress()` clears both on character
  creation; gold already earned is untouched.
- **Money Habits' double header.** A 70px toolbar plus a 12px title inset,
  stacked under `MainNavigation`'s global top bar, was a second header's
  worth of dead space.
- **Three more Activities.** The menu was five rows, three of them free stat
  bumps. Added a side job (real money, costs happiness and health), a
  volunteer option (no money, best happiness-per-coin in the game), and a
  gamble (42% to double — deliberately worse than even, and it teaches
  opportunity cost whichever way it lands).
- **The turtle logo** was removed from the top bar by request: at 22px it
  read as clutter next to an already-strong pixel wordmark.

### Daily quests are age-aware, unblocking a chronological curriculum

`DailyPlanBuilder._nextLesson` walked `lessonUnits` in raw list order and
quested the first uncompleted node, which made list position secretly mean
"difficulty order". That is why the youngest units (ages 4-6, 7-10) were
pinned to the *end* of the curriculum list — purely so adults would not be
told to study "What Is Money?" — while the Academy's own strip displayed
them first, because it sorts by age. List order and reading order
disagreed, and the list could never be put in the order a human expects.

`_nextLesson` now takes the reader's `AgeStage` and skips units below it on
the first pass, falling back to any uncompleted lesson so the slot never
silently disappears. That decouples the two, which is the prerequisite for
reordering the curriculum chronologically (still to do — see below).

## 27. The curriculum in age order, an ellipsis sweep, and a sprite verdict

### A wider window showed *less* text than a narrow one

Reported as "when it's high resolution, there is no text and when there is
low res then there is text". Real, and the cause is a single threshold.

Home's hero card hid its whole subtitle behind `if (!veryTight)`, where
`veryTight` is `constraints.maxHeight < 196`. The hero's own height is
`(availableHeight * 0.38).clamp(225, 300)` minus padding — which on a phone
lands within a couple of pixels of 196. So a hair more or less available
height made an entire paragraph appear or vanish, and since the two
screenshots differed slightly in chrome, the wider one happened to land on
the hiding side.

**Content should not blink in and out on a 2px threshold.** The subtitle is
now always shown, with copy shortened so it fits two lines unaided at any
supported width. It also stopped repeating "Start a life", which the button
directly beneath it already says.

### 46 ellipsis sites → 22, via a shared widget

`TextOverflow.ellipsis` is a reasonable default for *user data* of unknown
length. It is the wrong answer for UI chrome the app wrote itself, where the
string is known, short and load-bearing: "Curren…" has failed at the one
job it exists to do.

New `FittedLabel` (`lib/widgets_custom_lotties/fitted_label.dart`) measures
the text with a `TextPainter` and scales the whole line down to fit rather
than truncating. On the sizes this app runs at that is a point or two of
font size, which reads as intentional where the truncation read as a bug.

Two deliberate escape hatches:

- **Unbounded width** (inside a scrolling `Row`) → plain `Text`, since there
  is nothing to fit *to* and `FittedBox` would have no meaningful scale.
- **`minScale` (0.62)** → falls back to ellipsis. A 60-character company
  name scaled to fit really would become unreadable; there, truncating is
  the lesser evil.

25 call sites converted by script. The 22 that remain are exactly the ones
that should: usernames, `widget.company`, `item.headline`, `match.company`
— all remote or user-supplied — plus `FittedLabel`'s own fallback.

### The curriculum is now in chronological order

`lessonUnits` runs youngest to oldest: ages 4-6 → 7-10 → 11-13 → 14-17 →
18-20 → 21+, as one continuous prerequisite chain from Unit 1 to Unit 11.

This was blocked until §26 made `_nextLesson` age-aware, because list
position was secretly encoding difficulty (see that section). With the
coupling gone the list is free to mean what it looks like it means.

**IDs did not move.** `unit_10` is now titled "Unit 1: Money Is Real" and
sits first. Progress is stored per lesson/unit id (`completed_lessons`), so
renumbering a *title* is safe while renaming an id silently orphans every
player's history. Four tests lock this down:

| Test | Guards |
|---|---|
| units run youngest to oldest | the ordering itself |
| the youngest unit is first | a 4-year-old starts at the start |
| displayed unit numbers match list position | title "Unit 3:" is actually third |
| unit ids are NOT renumbered | saved progress survives |
| it is one continuous chain | each unit opens off the previous unit's test |

`DailyPlanController` now passes `stats.ageBand.recommendedStage` into the
builder, and `daily_plan_test.dart` gained five tests — the load-bearing one
being **"an adult is never sent to the ages 4-6 unit"**, which is precisely
what would break if anyone removed `readerStage` again.

One existing test had to change: "leads with the next uncompleted lesson"
hardcoded `lesson_1 done → lesson_2 next`, which quietly depended on
`unit_1` being first in the list. It now derives both ids from
`lessonUnits.first`, so it tests the behaviour rather than a snapshot of the
data.

### You now start at your own front door

`kTownSpawnTile` = (13, 31), just outside `spot_home` at (13, 30), replacing
the old town-square spawn at (25, 25). You leave home to go into town and
come back to it; starting in the middle of the square made the map read as
a level select rather than somewhere you live.

The spawn tile gets the same checks every NPC gets — walkable, reachable,
and two clear rows overhead so the sprite does not clip the house — plus one
of its own asserting it is within two tiles of the house.

The exit is now a labelled **"Go home"** pill rather than a bare back arrow,
which described the navigation stack rather than anything happening in the
game. That change also broke the HUD layout: the objective bar sat at a
hardcoded `left: 66`, sized around a circular icon-only button, so the wider
pill overlapped it. Both are now a `Row`, which lays out relative to
whatever the button's label turns out to be.

### The side-walk sprite: measured, and a verdict

Reported twice more as still bad. Rather than a fourth blind attempt, the
west row was measured three ways:

```
head band   f0..f7 left edge:   7  12  12  12   7   2   2   2   (right edge always 102)
torso band  f0..f7 left edge:   7  12  12  12   7   2   2   2   (right edge always  90)
feet Y:                       147 155 155 155 147 155 155 155
legs f1 vs f5:  mirrored (opposite leg)   f2 vs f6: mirrored   f0 vs f4: identical
```

Every one of those is **correct**:

- Right edges are pinned, so the body does not slide horizontally; the
  leftward growth is the forward arm swinging out.
- The two halves of the cycle are *mirrors* of each other, i.e. the
  character genuinely alternates legs rather than hopping on one.
- `f0 == f4` is right — both are the neutral contact pose.
- Feet sit on one line with an 8px dip on stepping frames (§25's
  normalizer), so there is a real body bob.

**The structure is sound. What reads as stiff is the art itself**: across
all eight frames the torso and head are pixel-identical, so only the legs
and one arm ever move. There are also only five distinct poses in the eight
frames (`0,1,2,1,0,5,6,5`), which is why it looks like it holds.

Fixing that means genuinely redrawing the character — adding torso rotation
and head bob per frame. That is art direction, not a transform, and the one
time pixel surgery was attempted here (§25's first clipping attempt) it made
things worse and had to be reverted. Recording the measurements so the next
attempt starts from data rather than re-deriving them, and so nobody
"fixes" a cycle that is already structurally correct.

## 28. The last ellipsis, a quit guard, chart zoom that works, and candle caching

### The last two "…" were a layout problem, not a text problem

After §27's sweep, two places still truncated: Finance Brawl's HUD
("Debts …", "Don't …") and the Life header ("Age 0 · Baby · Newb…").

Both were already converted to `FittedLabel` — what was happening is
`FittedLabel` doing its job. Its `minScale` guard refuses to shrink below
62% and falls back to truncating, on the reasoning that unreadably small
text is worse than a cut-off word. So the ellipsis was a *symptom*: these
containers were too small for their contents at any legible size.

Measured, the HUD panel had **~54px of text column**: two panels share a
row with a gold chip and an exit button, leaving ~119px each, and a 32px
icon plus padding eats ~65px of that. "Debts Paid 4/6" cannot render in
54px, and no amount of text-fitting changes that.

Fixed the layout instead. `_HudStatPanel` is now responsive: under 150px it
drops the flavour line and shrinks the icon; under 112px it drops the icon
entirely. What survives is the label and the number — the part you read
mid-fight. The flavour ("Don't Let it Hit Zero!") is the first thing to go
because it is the least useful thing on screen during a wave.

The Life header was simpler: `'Age $age · ${stage.label} · $job'` rendered
"Age 0 · Baby · Newborn", where the job *always* restates the stage before
a real career exists. `_subtitleFor` drops the job segment while it is a
placeholder ("Newborn", "Student", "Unemployed"), so the line reads
"Age 0 · Baby" and fits. Once there is a real job ("Barista") it earns its
place back.

**The general lesson**: when text-fitting falls back to truncation, the
container is the bug. Shrinking the font is a workaround; giving the string
a sane amount of space, or making it shorter, is the fix.

### Quitting a life now asks first

`LifeSimController` is in-memory only by design — nothing about a run is
persisted. So backing out of the Life screen silently destroyed it, which
after twenty simulated years is an expensive accident with no undo.

A `PopScope(canPop: false)` now routes both the AppBar arrow and the
Android system back gesture through one confirmation. The wording does two
things a bare "Discard?" would not: it says the run is not saved and that
quitting forfeits its gold and XP, and it points at **Retire** as the way
to keep something — retiring cashes out, quitting pays nothing. A finished
life skips the dialog entirely; there is nothing left to lose.

### Chart zoom: the gesture was losing an arena fight

"The user still cannot zoom in" on the buy screen. The pinch maths was
correct; it never got the chance to run.

`InteractivePriceChart` sits inside the order ticket's vertical `ListView`.
A `ScaleGestureRecognizer` and the ListView's drag recogniser both enter the
gesture arena, and the ListView generally wins — so "pinch to zoom, drag to
pan" did nothing on a phone, which is exactly what was reported.

Rather than fight the arena, the chart now has **explicit +/− and
reset-to-fit buttons**. A button cannot be stolen by a parent scrollable, so
zoom works regardless of who wins, and it is far more discoverable than an
undocumented gesture. The pinch handler stays (it works fine outside a
scrollable) and gained `HitTestBehavior.opaque`.

The buttons sit on the **left**: the right 52px is the price-label gutter,
so controls there would cover the numbers. The hint text was updated too —
it had been advertising a gesture that did not work.

### Switching timeframes was a network round trip every time

`fetchCandles` had no cache. Every tap of 1D/5D/1M/3M/1Y hit the network,
*including* tapping back to a range viewed seconds earlier — against Twelve
Data's free tier, which allows eight requests a minute. That is the "make
sure the fetching is fast" complaint, and it is worse right now because the
`market` edge function is not deployed (§26), so these are direct
rate-limited vendor calls rather than cached proxy hits.

Two additions:

- **A TTL cache keyed by `symbol:range`.** The TTL varies by bar size
  rather than being one blanket number: 1D is built from 5-minute bars and
  genuinely moves (2 min), 5D from 30-minute bars (10 min), and 1M/3M/1Y
  from daily and weekly bars that cannot change again until the market
  closes (1 hour). Caching those for an hour is correctness, not staleness.
- **In-flight request sharing.** Two widgets asking for the same series in
  the same frame now await one call instead of racing into two.

**Failures are deliberately not cached.** Storing an empty result would pin
a transient outage in place for the whole TTL and a retry could never
recover; `candle_cache_test.dart` covers that case specifically, along with
cache hits, per-range and per-symbol separation, and the concurrent-request
path.

---

## 29. The side walk, and making the money model visible

### The side-walk sprite: the real defect, and why no redraw shipped

§27 measured the west/east rows structurally — legs alternate, the two
halves mirror, feet stay planted — and every check passed while the
animation still looked wrong. That is because the fault was not in the
*cycle*; it was in two individual frames.

Rendering the west row's leg region enlarged showed it immediately:
**columns 0 and 4 have two legs side by side, symmetric about the body,
with a gap between them.** That is a *front-facing* stance drawn onto a
profile body. Columns 1-3 and 5-7 are correct profile strides. So twice per
cycle the character snapped face-on and back, which no structural
measurement of the cycle could ever catch, because the cycle was fine.

A pixel scan of row 2, frame 0 confirmed the shape:

```
y=118..136   leg A x=27..46 | GAP x=47..51 | leg B x=52..71
y=138..146   shoes, one solid block
```

Worse, `idleLeft` was `frame(2)` — which loads **column 0 of row 2**, the
bad frame. Standing still facing west held the wrong pose indefinitely
instead of flashing past it, which is almost certainly the version of this
bug that was most visible.

**Three redraws were prototyped and all three were rejected.** Filling the
gap merged the legs into one chunky column that did not match frame 1's
weight. Deleting the far leg left the remaining one sitting off-centre
under the coat. Re-centring the survivor moved it out from under the torso.
Each was measurably worse art than what shipped, so the script was deleted
rather than committed.

**What shipped instead: stop using the bad frames.** `kSideWalkFrames`
is `[1, 2, 3, 5, 6, 7]` and `kSideIdleFrame` is `1`. What remains is
contact-pass-contact for each leg — a valid six-frame cycle — and it
cannot damage the source art. `createAnimation` only takes a contiguous
`from`/`to`, so `_loadRowFrames` builds the animation from an explicit
column list via `SpriteAnimation.spriteList`.

This is a workaround, and the comment in the code says so: a genuine fix
means a pixel artist drawing two profile neutral frames. Until then the
constant is a single place to undo it.

`test/town_map_test.dart` guards it — the bad columns stay excluded, the
count stays even (an odd count would make the same leg lead twice at the
loop point), every column is real, and the idle frame is one of the good
ones.

### The money model was real and invisible

The Life sim already modelled cash, an emergency fund, investments, debt at
18% a year, and a needs/wants/savings split. None of it was on the feed.
The header showed a coin count; everything else lived behind the Money
menu. A player could live a whole life and never be shown that a budget
existed.

Worse, `_applyBudget()` only ever wrote to the feed to *complain* — on a
needs shortfall or on debt interest. A year where the budget worked
produced no money line at all. The implicit lesson was "budgeting is
something that shows up when you get it wrong".

Three changes, in order of how much they matter:

1. **A paycheck line every working year.** `_applyBudget()` now always
   names the three numbers: `Paycheck 2400. Needs 1200, wants 720,
   savings 480.` Before a budget is chosen it says so instead, and points
   at the menu. Four tests in `budget_teaching_test.dart` cover it,
   including that a year with no salary writes no such line.
2. **`LifeMoneyPanel`, on the feed, under the year card.** Four tiles —
   cash, saved, invested, owed — so the categories become familiar before
   the vocabulary is explained; the split as a bar rather than three
   percentages; and the emergency fund expressed as *months of cover*,
   which is the entire point of the concept and the part a balance never
   communicates. Under 18 it shows an age-appropriate note instead of a
   disabled budget bar, because a control you are not allowed to touch
   teaches nothing.
3. **The concepts strip.** `FinanceConcept`s were already being recorded by
   `_teach(...)`, but only visible inside a menu. They now show as a row of
   16 glyph slots that fills in, with a `4/16` count. The empty slots are
   the invitation.

### Emoji as structure, not decoration

`LifeLogEntry` gained a `kind`. The tempting cheap version was to guess the
category by scanning the log text for words like "paid" or "school", but a
single sentence can mention a job, a cost and a friend, and the scan would
pick whichever keyword came first. Tagging at the point the line is
*written* is the only version that is right. Event outcomes derive their
kind from what the choice actually did (`_kindOf`), money first — if a
choice moved coins or taught an idea, that is the headline.

The stat pills became meters with bars: "46" means nothing on its own, a
bar not quite half full is legible to the youngest end of this app's
audience. Net worth and investments left that row entirely — they are in
the money panel now, and repeating them made money look like one more stat
out of five rather than the subject of the game. The happiness face now
reacts to the value; it used to be a static "very satisfied" icon sitting
next to a 12% bar.

### A `Spacer` between two rigid labels overflowed at 288px

`test/life_money_panel_test.dart` caught this before it shipped: the budget
strip's header row overflowed by 9.8px at 288 wide.

The cause is worth remembering, because the fix is not the obvious one. A
`Spacer` is `Expanded`, which makes it a **flex child** — so it competes
with any `Flexible` siblings for the same free space, and the labels get
squeezed instead of the gap. The pattern that works is `Expanded` on the
label that may give way, a fixed `SizedBox` gap, and the figure that must
stay readable left rigid. All three headers in the panel use that shape
now.

### The Corner Store is a place now, not a dialog

Walking into a shop used to open a modal bottom sheet with a 96px strip of
interior art across the top. It read as a menu with a picture on it — the
building was never somewhere you *went*.

`TownInteriorScreen` is a pushed route. The room art is the room (`fitWidth`
aligned top, with the scaffold painted the floor colour sampled out of the
art's bottom strip, so the floor continues below rather than the app
background showing through — `cover` on a 500x175 source crops away either
the whole wall or the whole floor on a tall phone). The layout goes side by
side when the viewport is wider than 1.15x its height, which on this screen
is the *common* case, since the Adventure map locks landscape and this
pushes on top of it.

The shopkeeper is animated. `PixelFrameAnimation` is new and exists because
all of this project's character art ships one PNG per frame, and the only
thing that could animate that was Flame, inside the Bonfire canvas —
so every screen outside the map was showing a still. Frames are precached
before the timer starts; on a four-frame idle, the decode stutter is
otherwise most of the animation.

Choosing an option plays the 14-frame `sell` sequence — the shopkeeper
ducks under the counter and comes back with a parcel — and the screen pops
when it finishes, so the purchase visibly happens instead of the screen
vanishing mid-tap. The choice list is disabled while it plays so a second
tap cannot queue a second purchase.

**One asset quirk worth knowing.** The stall sprites are 240x175 and their
left 24 columns are an opaque purple wall panel from the sprite's original
scene, so drawn over a different room the untrimmed sprite paints a stripe
across the wall. It is trimmed at draw time with `ClipRect` +
`Align(widthFactor:)` rather than by re-exporting, because there are 36
files across the two stalls and an edited copy would drift from the source.
Purple also fills the triangle above the sloping awning; that part is left
alone, since it reads as wall behind the stall and removing it would mean
editing every frame.

Every other building takes the NPC branch instead — the suited character at
the bank, the worker at the job board — using idle frames that already
shipped and had never been used outside the map.

Both variants are in the responsive sweep (`Corner Store interior` and
`Bank interior`) at all eight viewports.

---

## 30. Chains, and the job nobody could get

### The pool was 109 events and still felt repetitive

Adding more events was the obvious answer and would not have worked. Every
event was **standalone**: it fired, it moved numbers, and nothing downstream
could know it had happened. A run draws roughly sixty of them, so two runs
differed in *which cards came up* and never in what the life was about. A
hundred unrelated beats in a random order still reads as a shuffled deck.

`LifeFlag` is the memory that fixes the shape rather than the count.
`LifeChoice.setsFlag`/`clearsFlag` record what happened;
`LifeEvent.requiresFlag`/`forbidsFlag` gate on it. An enum rather than free
strings, because a typo would produce a beat that silently never fires —
invisible, since a missing event looks exactly like an unlucky roll.

`kLifeEventsChains` has eight storylines. They are mostly money on purpose:
taking a credit card at twenty-two teaches nothing on its own, and the
minimum-payment trap three years later teaches everything — but only if the
game remembers the card. Same with index investing: "hold or sell" is only a
decision worth having if you were the one who invested.

**Chain beats are boosted 4x in the draw** (`_openChainBoost`). Left on their
declared weight, the third beat of a four-step storyline has to win a
weighted roll against 120-odd standalone events, three separate times,
inside one life — `chain_index_payoff` was unreachable across 2,000
simulated lives before the boost existed, and that is the beat where twenty
years of leaving a fund alone finally shows the player what compounding did.
Applied in the draw rather than baked into each event's weight, so it stays
one rule that every future chain inherits.

`life_chains_test.dart` checks the wiring rather than the prose: every flag a
continuation waits on is set by something, every flag that *gates* something
can also be cleared, openers are not themselves gated, and every thread has
at least one beat that advances it. Those four caught three real content
holes on first run — `hasSideHustle` had no ending, `heldThroughCrash` never
closed, and the `chain_hustle_grow` beat left a business still flagged as a
side hustle.

**Chains are also visible.** `_YourLifeStrip` shows what you currently
*have* — dog, car, card, debt — because a chain the player cannot see is
indistinguishable from coincidence, and the vet bill six years after
adopting the dog only lands as a consequence if you knew in between that you
had a dog. Chain beats also carry a "Because of the dog" badge on the event
card.

### Quiet years were the most repeated string in the game

About a quarter of years draw no event, by design, so events feel like
events. Every one of them printed the identical sentence: "Turned 12. A quiet
year." The *most common* line in the feed was the only line that never
varied, so a run looked repetitive even when its events were not.
`_quietYearLine()` is age-banded, because "you learned to ride a bike" and
"your knees have opinions about the weather" are both quiet years and neither
works at the other end of a life.

### Most players could never get a job

Found by instrumenting simulated runs while checking something else: three of
four seeds reached **age forty still listed as "Newborn" on zero salary**.

Only eight of the ~130 events could set a job, each behind its own age or
skill gate *and* behind the player picking that specific branch. With no
salary, `canBudget` is false — so the budget split, the emergency fund, the
paycheck line and the debt model were all unreachable. The entire thing the
app exists to teach was gated behind a lottery.

`findJob()` makes work a decision. Smarts widens the list you can reach,
which is the one place in the game where studying visibly pays for itself,
and the pick is best-of-two rolls so raising Smarts is *felt* rather than
merely permitted.

**The first version of the salary table was five times too generous** —
900-3000 a year against career events paying 260-520 and a year of essentials
costing 110-180. A simulated run banked a 6,378 emergency fund by thirty: a
game with no tension and therefore no lesson. Rescaled to 240-560, with the
ceiling deliberately at the *bottom* of what the career-ladder events award,
so walking into a job stays worse than earning one. After that, the same four
seeds finished at thirty with a small fund, no fund, a 468 debt, and a 6,674
debt spiral on a 260 salary — which is a game where money decisions matter.

### A test seam that immediately paid for itself

`LifeSimPage` pushes character creation in a post-frame callback, so the
responsive sweep pumping `LifeSimPage` was only ever measuring the
**creation screen**. The feed — money panel, stat meters, event card, chain
chips, every part that actually reflows — had no viewport coverage at all
while appearing to have eight viewports' worth.

`debugInitialLife` skips creation. Adding it surfaced two real overflows at
320px within a minute:

- **The bottom menu bar, by 3.4px.** Five rigid children with `spaceEvenly` —
  which distributes *leftover* space and does nothing when there is none. The
  four menu slots are `Expanded` now, sharing what is left beside the fixed
  Age button.
- **The header, by 1.1px.** It lives in `AppBar.title`, which hands it
  whatever survives the back button and two actions. The avatar is decoration
  and the name and balance are content, so the avatar is what drops below
  210px.

---

## 31. Charts you can move, and a deep link that was never declared

### "I still cannot zoom on the buy screen", three times

Two separate causes, which is why fixing it once did not fix it.

**Cause one: the gesture lost an arena fight.** The order ticket *was*
already using `InteractivePriceChart`, and its +/- buttons did work. But
those are a 28px control in a corner, and what anyone actually tries is to
pinch or drag. Those did nothing, because the wrapper drove them from a
`ScaleGestureRecognizer` — which accepts pointers in **any** direction and so
competes with the enclosing vertical `ListView` for every gesture. The list
wins. The feature existed, the maths was right, and it was unreachable by the
input a person would use.

**Cause two: three other charts were never interactive at all.** The Market
Board's detail sparkline, the P&L curve and the net-worth trend all
instantiated the plain `PriceChart` directly.

The rebuild changes the input model:

- **One finger, horizontal.** `HorizontalDragGestureRecognizer` never
  competes with a vertical list, so it always wins. At 1x there is nowhere to
  pan, so it scrubs the crosshair; zoomed in, it pans.
- **Two fingers.** Pinch, anchored on the focal point so the candle under
  your fingers stays put. Two-pointer gestures do not conflict with a
  one-pointer list drag.
- **Buttons** for zoom in/out/fit and pan left/right, because a mouse has no
  pinch and buttons cannot be stolen by a parent scrollable.

The window is stored as **integer candle indices**, not a zoom factor plus a
fractional centre. A fractional centre drifts as it is re-derived, so
pan-zoom-pan would not land back where it started.

Two subtler fixes came out of it. `PriceChart.axisGutter` is now public —
the painter reserves 52px on the right for price labels, and the Market Board
had its own hardcoded copy of that number for pointer-to-index maths, which
is exactly the sort of duplicated constant that drifts. And the crosshair
index is reported in **whole-series** coordinates, because the painter is
handed a slice when zoomed and an untranslated index would point at the wrong
candle, making the price readout disagree with the crosshair.

`price_chart_interaction_test.dart` asserts what the painter is actually
handed, which is the only honest measure of "is it zoomed" — the visible
window is what it draws and what the price axis is derived from.

### How the news actually works

Finnhub `/api/v1/company-news`, with `from`/`to` set to a rolling 14-day
window, called alongside `/stock/profile2` from the order ticket's
`initState`. Both go through `_proxyUri` when the Supabase edge function is
configured and fall back to a direct call with an `X-Finnhub-Token` header
otherwise.

Responses are cached per symbol for 15 minutes. Failures return an empty list
and are **not** cached, so a transient outage does not pin an empty panel in
place for the whole TTL.

One real fix in this pass: the results were sorted newest-first and capped at
12, with a comment acknowledging that the window returns wire-service
reprints — but nothing actually de-duplicated them. A single story carried by
a dozen outlets could fill the entire panel and hide everything else that
happened. Reprints differ only in casing and trailing attribution, so
matching on a normalised headline (lowercased, punctuation stripped,
whitespace collapsed) catches them without comparing article bodies.

### Password reset was complete in code and dead on device

`resetPasswordForEmail`, the captcha token, the recovery-session handling in
`main.dart` — all already correct. But `passwordResetRedirectUrl` is
`budgetbuddy://password-reset` on mobile, and **that scheme was declared
nowhere**. No intent-filter in `AndroidManifest.xml`, no `CFBundleURLTypes`
in `Info.plist`. So the OS had no idea which app owned the link, tapping it
in a mail client did nothing, and the reset dead-ended — with no error, on a
path that looked finished in the code.

Both are declared now. Three things have to agree for this to work, and the
third is not in the repo:

1. `passwordResetRedirectUrl` in `supabase_service.dart`
2. the native declarations (intent-filter / `CFBundleURLTypes`)
3. the same URL allowlisted under **Authentication → URL Configuration →
   Redirect URLs** in the Supabase dashboard

If (3) is missing, Supabase silently substitutes the project's Site URL and
the app never receives the recovery session — which is the same
indistinguishable dead end.

---

## 32. The crosshair that said nothing, and one company with five faces

### The dot told you where you were pointing, never what was there

Scrubbing drew a vertical line and a dot on the series. That is *position*
information. It answered "which bar am I on" and never "what price is that",
which is the only question anyone scrubs a chart to ask — reading a value off
a y-axis by eye is precisely the work a chart exists to save you.

The readout is now four things, which is what every real trading app draws:

- a **dashed** crosshair (both axes), so it reads as a measurement overlay
  rather than as another series painted on the chart;
- a haloed dot with a white ring, visible over both the filled area under the
  line and the empty space above it;
- a **price tag** pinned into the right-hand gutter beside the axis labels;
- a **card** with the value, the move since that bar opened (absolute and
  percent, coloured), and the timestamp.

Two details that are easy to get wrong and were handled deliberately. The
card **flips to the other side of the crosshair** near the right edge, because
that is exactly where the newest and most-looked-at bars are, and a readout
that runs off the canvas is worse than none. And the timestamp trims itself to
what actually varies in the series — an intraday series spans one day so the
date is noise, a yearly one spans months so the clock time is meaningless.
Which one it is can be read straight off the data rather than needing the
timeframe threaded down from the caller.

### "Go back on past days" is a range problem, not a pan problem

Panning left on a 1D chart cannot reach yesterday: an intraday series only
holds one session's bars. So the answer is the range strip, and it stopped at
a single year. Added **6M** and **5Y**.

### One company, five different faces

`_logoAssetFor` existed and exactly one widget called it. Apple appeared as
the Apple mark on the trending promo card and as a generic phone glyph in the
search results, the ticker tape, the stock card, the holdings list, the
allocation rows and the order-ticket header — the same company wearing five
faces on one screen.

`SymbolBadge` (now in `widgets_custom_lotties/`, since the order ticket needs
it too) is the single treatment: the real logo where there is one, on a
**white** plate — several of these marks are solid black and would vanish
against this app's dark panels, which is why real trading apps put a white
circle behind ticker logos whatever their own theme — and the accent-tinted
Material glyph otherwise, because a coloured glyph on white would look like a
broken image.

### The backdrop was winning against the numbers

Both Market Board screens draw the pixel village behind a transparent
`Scaffold`, scrimmed at 0.62/0.66. At that alpha the village stayed clearly
legible, so every price, label and chart line competed with a busy tiled
illustration. Numbers are the entire point of a trading screen and they were
the thing losing. Raised to **0.88**: still recognisably the village, no
longer reading as content.

---

## 33. The app had no UI because it had nothing to build UI out of

"I still don't see that the app has UI" came back repeatedly, and it was not a
matter of taste. Every panel was a `BoxDecoration` rounded rect, every button a
`FilledButton`, every icon a Material glyph. The one pixel kit — the older
`assets/images/ui/` — is a flat green rectangle with a gold stripe and four 8x8
glyphs. There was no game interface to reach for, so every screen fell back to
Material with a pixel font on top.

**The art was already in the repo, referenced by nothing.**
`assets/imported/Tiny Swords (Free Pack)/UI Elements/` ships papers, banners,
ribbons, bars, buttons with real pressed states and an icon set — better art
than anything worth generating. Two things stopped it being usable, and
`tool/build_ui_pack.py` fixes both.

**It ships as contact sheets, not nine-slices.** Each file is a 64px grid with
the nine pieces parked at cells 0, 2 and 4, gaps between them. Flutter needs
them packed adjacently so `centerSlice` can pin the corners. The slicer detects
pieces by opacity and snaps to the 64px grid rather than assuming a 3x3 split,
because the sheets are not uniform: `RegularPaper` is 320px with one-cell
pieces, `Banner` is 448px with two-cell pieces. Snapping recovers the author's
intent in both without hardcoding either.

**It is fantasy-medieval.** Teal, wood-brown and parchment, against an app whose
identity is forest green and gold. The recolour maps *hue* while preserving
saturation and value — that is the whole trick, because the light edge, shadow
edge and mid tone in this pack are the same hue at three different values, and
it is that ramp, not the hue, that makes a rectangle read as a raised panel. A
flat colour replacement would throw the bevel away.

### The bug that made the scale column non-negotiable

First build asserted in the layout sweep:

> centerSlice was used with a BoxFit that does not guarantee that the image is
> fully visible

Not a fit problem. **Flutter subtracts a nine-slice's end caps from the
destination before fitting, and a negative remainder throws rather than
clipping.** The pack is authored for a desktop RTS on a 64px grid, so a 192px
bar carries 128px of caps — and the Finance Brawl HUD gives its panels about
119px on a phone. That bar was *mathematically unable to render there*.

Two fixes, both needed:

1. **Downscale on the way out.** Bars 0.25, panels/buttons 0.5, banners 0.4.
   Safe for this pack because it is painted, anti-aliased art rather than 1:1
   pixel art. Slicing happens at full resolution *first* — scaling first would
   move the piece boundaries off the 64px grid and the band detection would
   find the wrong seams. Minimum renderable sizes are now bars 32px, panels
   64px, ribbons 128px.
2. **A `_NineSlice` guard in the widget.** These are shared widgets, so any
   caller with a tight `Expanded` can hit the limit; below it they draw a plain
   rounded rect, which at that size is indistinguishable from the art anyway.
   This is not defensive padding — without it a too-narrow panel takes the
   frame down.

`test/pixel_kit_test.dart` pins it: every widget at eight widths including the
119px that crashed, plus slice-rect sanity (a rect one pixel off pins the wrong
column and smears the bevel).

### `pixel_kit.dart`

Assets on disk fix nothing on their own — the previous kit sat unused for
exactly that reason. `PixelFrame`, `PixelRibbon`, `PixelButton`,
`PixelProgressBar` and `PixelKitIcon` are the bridge: they make the art the
*easy* choice at a call site so new UI reaches for it by default.

`tool/make_ui_kit.py` no longer emits frames or buttons — shipping two
competing panel sets would be more unused art on top of the unused art this
whole effort exists to fix. It still owns the **icons**, because the pack has
no coin stack, piggy bank or up/down chart, and those are the concepts a
budgeting app needs most.

### Two fixes that fell out of it

**Money Habits lost its gap.** The `SizedBox(height: 16)` under the Today's
Challenge card lived *inside* the `if (habits.savedHabits.isEmpty)` branch, so
it vanished the moment a player pinned their first habit and the challenge card
ended up welded to the stats row. Spacing between two siblings belongs between
them, not inside a conditional that happens to sit in the middle.

**Finance Brawl was hiding the number the player needs.** `_HudStatPanel`
dropped its `detail` line below 150px — and that line is "Debts Paid 3/12", the
count telling you how far you are from the next upgrade. So the progress
disappeared on exactly the phones where the HUD is tightest, which is why wave 1
showed nothing and wave 2 did. It now draws a `PixelProgressBar` plus a compact
`3 / 12`, kept at *every* width. A new `HudProgress` type is what lets the panel
tell a flavour line ("Don't Let it Hit Zero!") from a progress line — only the
second is information, and only the second has to survive.

---

## 34. Dates on the chart, and the logo that was one field away

### "10:40" does not say which 10:40

The scrub readout printed a bare clock time on an intraday chart. That was a
deliberate call and it was wrong: the reasoning was that a one-day series makes
the date redundant, which stops being true the moment the chart can be zoomed
and panned — and asking *which* moment is the entire purpose of scrubbing.

The date is always shown now, with the year only when the bar is not from the
current year, so a 1D chart stays short and a 5Y chart stays unambiguous.

A real bug came out of it. The old code decided "is this intraday" from the
series' **total span** — but `PriceChart` only ever receives the *visible
window* when it sits inside an `InteractivePriceChart`. So zooming a multi-day
chart down to a handful of bars shrank the span below a day and silently
dropped the date mid-gesture: the label changed meaning as the user pinched.

It now measures the **median gap between consecutive bars**, which does not
move when the window narrows. Median rather than mean because a daily series
jumps three days across every weekend and a month across some holidays, and an
average of those lands between "daily" and "weekly" and decides nothing.

### The chart had no horizontal axis at all

Prices were plotted against nothing. A shape was readable but never locatable
in time. Three labels — first, middle, last — is the most a phone-width chart
carries without collisions, and enough to answer "what period am I looking at".
The plot area now stops above them, but only when the chart is tall enough to
afford it: on a short sparkline the prices matter more than the dates, and
squeezing both makes neither readable.

### One company, one mark — including the ones nobody bundled

Six logos ship as assets. The board trades dozens, so everything else wore a
generic Material glyph — while its real mark sat **one field away** in the
`/stock/profile2` response the order ticket was already fetching for its
Company Background panel. Disney had a logo on its profile card and a purple
glyph in the list, on the same screen.

`MarketDataService.primeLogos` now fetches the rest, and `SymbolBadge` falls
back to that URL. The throttling is the important part: the naive version is
one request per visible row on every scroll, against a free tier that allows
sixty calls a minute. So it skips anything cached or in flight, caps each call
to a handful of new symbols, and stays silent on failure — a missing logo is a
cosmetic downgrade, not an error worth surfacing. Bundled art still wins where
it exists, because it is instant and works offline.

---

## 35. The side view was fat, and the measurement said so

Five rounds on this sprite, and the breakthrough was the user's exact word:
*"the character is fat"*. That is a claim about **silhouette width**, which is
measurable, and the measurement is damning:

| row | front (south) | profile (west) |
|---|---|---|
| head top | 40 | **50** |
| hair | 70 | **85** |
| torso | 70 | 75 |

The profile was **wider than the front view at the head** — anatomically
backwards — and its torso only 7% narrower face-on when a real profile is
closer to half. Every earlier round had been looking at the walk *cycle*:
frame timing, leg alternation, which frames were front-facing. The cycle was
never the problem. A too-wide silhouette reads as fat no matter how well the
legs animate.

### Column deletion, not scaling

Squashing horizontally would blur every outline and destroy the 5px block grid
the art is drawn on. Instead `tool/narrow_side_profile.py` finds the longest
run of a single flat colour in each row — the middle of the hair slab, the
middle of the coat — and deletes columns from *inside* it, sliding the
remainder across. Both edges survive untouched, so the face, the arm and the
back outline come through exactly as drawn.

**The shift has to be uniform.** The first version chose the cut per row
independently, so a row whose flat run could only afford 14 columns shifted 14
while its neighbour shifted 25, and the back of the coat came out as a
staircase — visible immediately in the contact sheet. Every row above the hip
now moves by the same amount; rows too narrow to donate that many columns are
translated by half of it instead, which keeps the neck attached above and
below. Legs are translated by the same half-shift rather than left alone,
because leaving them put detached them from a coat that had moved. Translating
every frame by one constant preserves the walk cycle exactly.

Result: profile width 90 → 71 against a 100-wide front view.

### A narrower blob is still a blob

Slimming fixed "fat" and the sprite still did not read as a person, because
there was no face in it: a 15px skin notch with hair covering everything
behind it, no nose, no eye. So `add_profile_face` adds a nose — one block
pushed forward past the face line, with the outline moved out to meet it,
since a profile is recognisable almost entirely by its nose — and an eye set
back from the front edge.

Every colour is recovered from the art itself (`_palette`) rather than
hardcoded, because the 22 sheets are palette swaps: hardcoding would fix one
skin and corrupt the other twenty-one.

**One step was removed after looking at it.** An earlier version also opened
the hairline, turning hair in front of the face into skin. On most frames it
helped; on frames where the head sits at a different angle it ate the face
entirely and left a head of pure hair. Additive edits cannot fail that way, so
only the nose and eye remain: the worst case is now a frame that gains
nothing, not a frame that loses its face.

### The honest ceiling

This is materially better and it is not *good*. The head still sits large and
juts backwards, because that is how it was drawn and no amount of transforming
existing pixels will re-draw it. The real fix for genuinely good side views is
the `Ninja Adventure` pack already in the repo: 95 characters with
purpose-drawn 4-direction walk cycles whose profiles are correct by
construction. That is the next item in the plan, and it is the one that
actually solves this rather than improving it.

---

## 36. Age gates, and three ways a nine-slice can refuse to draw

### A three-year-old with an investment account

Reported as *"when the age is like 3, there are options that shouldn't be
unlocked"*. It was worse than one option. At age three the menu offered:

- **Hit the books** — no age check
- **Go to the gym** — no age check
- **Visit the library**, alone — no age check
- **Go out** — no age check, and *free* while young
- **Invest 100 coins** — gated only on having the money

The cause is structural, not five separate oversights. The rules lived in the
**menu builder**, which is a view, so each option's gate was whatever that call
site happened to remember — and five of them remembered nothing. The section
was even commented "Always-available activities".

`LifeAction` and `LifeSimController.gateFor` move the rules into the controller
as one table. The menu now asks what to grey out and why. That matters for two
reasons: a menu-only check leaves the rule unenforced everywhere else (an
event, a future screen, a direct call), and it cannot be unit-tested without
pumping a widget. Every action method now guards on `allows(...)`, so the rule
holds no matter who calls.

Ages are the ordinary ones a child reaches these at — school 5, library 6,
gifts 6, volunteering 10, gym and going out alone 12, side job 14, work and
investing 16, gambling 18. **Seeing a doctor has no floor**: a parent takes a
small child, and gating it would punish the character with least control over
it.

The refusals are sentences, not booleans — *"Your family will not let you out
alone yet"*, *"You need to be 16 to open an account"*. At age three, being told
what you cannot do yet **is** the content; it is how the early years read as
childhood instead of as an adult life with less money.

One existing test failed, correctly: `life_sim_test.dart` had a helper named
`_adult()` that was fifteen years old and was investing. The test was fixed,
not the rule.

### Three ways a nine-slice refuses to draw

The Finance Brawl progress bar shipped looking like a brown stick. Diagnosing
it turned up three distinct failure modes, all of which had to be fixed.

**1. Transparent padding.** Every asset in the pack carries generous margins,
and **Flutter fits an image to its file bounds, not to the art inside them**.
`bar_fill_green` was a 64x64 file holding 24 rows of colour, so drawn into a
6px-tall box it painted a ~2px hairline. `bar_base` was 48 wide with art only
between x=7 and x=41, so the track never reached its own widget's edges. The
panels had the same bug less visibly — they rendered inset and never quite
filled. The generator now trims to the bounding box, moving the slice rect by
the same offset.

**2. Slice rects escaping the image.** Trimming introduced a new hazard:
cropping blank rows off the top of a full-height strip pushes its slice `top`
negative, and Flutter asserts on a `centerSlice` not contained by the image.
Seen for real on the ribbons (top −7) and the small bar (−3). The trim clamps
the rect back inside afterwards.

**3. Caps larger than the destination.** Flutter subtracts the end caps from
the destination before fitting, so a nine-slice can never render smaller than
its own corners. The guard for this used `<` where it needed `<=`: a
destination *exactly* equal to the caps leaves a stretchable middle of zero,
which fails the same way a negative one does. That is how a 52px-tall button
drawn from art with 52px of vertical caps still asserted after the guard was
added — and why button art is now emitted at 0.25 scale rather than 0.5. **A
kit asset that always falls back is the same as no kit asset.**

Because the trim makes every output a different size with non-symmetric caps,
slices can no longer share one constant, and the source extent can no longer be
derived from the slice. Both are now per-asset, and the generator prints them
ready to paste rather than leaving them to be re-derived by hand — which is how
a rect ends up one pixel off and the bevel smears.

---

## 37. The money font's missing digit, and giving each ending a face

### A number font with no 5

The underwater set converted to PNG cleanly — 124 files — except
`hud_number_5`, which simply is not there. Not corrupt, not misnamed: absent.
The set has 0,1,2,3,4,6,7,8,9.

That is a blocker rather than a nitpick. A money font missing a digit cannot be
used at all, because no balance, price or percentage can be relied on to avoid
it, and the failure mode is a hole in the middle of a number.

`tool/make_hud_five.py` rebuilds it by **vertically flipping the 2**. That is
how the two letterforms relate: a 2 is a bowl over a flat bar, a 5 is a flat bar
over a bowl, and flipping swaps them exactly. Reusing the real glyph is what
makes the stroke weight, the white outline and the drop shadow match — the part
hand-drawing a replacement would have struggled with. Flipping also negates the
italic, so the slant is measured off the `1` (a single stroke, so its centre
line *is* the slant: k = 0.157) and twice that is sheared back.

Rejected first, recorded in the tool so nobody retries them: 7's top bar plus
6's bowl reads as an 8 (the 7's "bar" is a diagonal, not a flat top); 7's top
plus 3's bottom reads as a 3; 9 mirrored reads as an 'e'.

The set is then packed into `assets/images/hud_font/` with a **shared
baseline** — cropped to one common vertical band, each glyph keeping its own
width. Without the shared band every digit would be a different height and the
number would bounce as its value changed; without per-glyph widths a `1` would
be as wide as an `8`.

`MoneyGlyphs` draws it. It is a widget rather than a `TextStyle` because the
glyphs are art, not a `.ttf`. `canRender` guards each call site, because a
figure that is half art and half fallback text looks worse than one drawn
entirely in the text font.

### The old kit is deleted, not deprecated

`assets/images/ui/` is gone — thirteen files. It was a flat green rounded
rectangle with a gold stripe plus four 8x8 glyphs, and it is the single clearest
reason the app kept reading as Material with a pixel font on top. Everything it
offered now comes from the sliced, recoloured pack at a quality it could not
reach, and keeping both would have meant shipping two competing panel sets —
exactly the unused-art problem this whole effort exists to fix. `PixelPanel` and
`PixelIcon` survive as thin aliases over `PixelFrame` and `PixelKitIcon` so the
existing call sites keep compiling.

### Seven endings that were the same screen

The epilogue card was an accent colour and a Material glyph in a circle. Seven
endings, one layout, one glyph shape — nothing to recognise and nothing worth
collecting.

Each archetype now has a **portrait**, curated one by one from the Ninja
Adventure facesets rather than assigned by index, because the match is the whole
point: the Noble's face is hidden under a top hat, which is what "rich but
lonely" looks like, and no automatic mapping would find that. The Spirit is
"Gone Too Soon", the Master is "Legacy Builder", the laughing Old Man is
"Comfortable Retiree".

The Play page's collection row shows the same faces, with a padlock on the ones
not yet found — the plate keeps its shape either way, so the row reads as a
collection with gaps rather than a list that is partly greyed out. The portrait
is deliberately *not* silhouetted when locked: at 38px a blacked-out face reads
as a bug, where a padlock reads as a lock.

Only the seven portraits that ship are copied into `assets/`; the 3,298-file
imported tree stays out of the bundle.

`life_ending_faces_test.dart` asserts every archetype's file exists and that no
two share one — the same class of bug as the missing 5, where a switch
references an asset that is not there and fails silently into a fallback that
looks deliberate.

---

## 38. Turtles drawn as pixels, and a chart whose dates were invented

### Four turtles in four styles at four resolutions

`assets/images/turtles/` held smooth vector cartoons at 563x750, 736x736,
3200x2400 and 1024x1024 — four rendering styles, four unrelated sizes, one
with a white background baked in. Beside the pixel map, the pixel UI kit and
the pixel ending portraits they read as clip-art dropped into a game. The
verdict was exact: the ending pictures look right and the turtle pictures do
not.

`tool/make_turtle_skins.py` redraws them. One silhouette, one resolution,
varying only by palette and accessory — which is what makes a skin *set*
rather than four unrelated pictures.

**The first attempt used an ASCII sprite map and came out as a bench.** That
technique is right for the 16x16 icons and wrong here: a turtle is curves — a
domed shell, a round head, stubby legs — and hand-placing curve pixels across
a 33-column grid means counting the same arc three times and getting a
different answer each time. The head ended up detached, the shell flat, the
feet floating. Drawing from **ellipses at 1:1** and scaling up
nearest-neighbour gets the proportions right by construction while keeping
every pixel a clean block.

A second pass was still needed: the shell was painted over the head, leaving
it a wedge peeking out the side. Order matters — neck, then head, then eye,
each sitting on the last.

**The celebrating turtle is deliberately untouched.** It is an eight-frame
animation the player sees on every achievement, it reads well, and it was
singled out as the one to keep.

### "Let me see further than a day" was missing data, not a missing setting

The P&L equity curve stored **bare numbers with no times**, and the chart
invented an axis for them: `_flatCandles` pretended every snapshot was exactly
one minute apart, ending now. So the dates on that chart were fiction, and the
visible span could never exceed one minute per point however long the player
had been trading.

The history was also capped at **60 points** — under an hour at a snapshot per
price refresh, which is why the curve never reached past the current session.

Both fixed: timestamps are recorded alongside each value (in `spending_habits`,
so no migration), and the cap is 400. Two details worth keeping:

* Stamps pair with values **from the end**. A save that predates timestamps has
  values with no times, and the newest points are the ones that have them —
  aligning from the front would put yesterday's clock on today's balance.
* Old points are dropped from the front rather than new ones being refused,
  so the curve keeps moving once it is full.

`portfolio_history_test.dart` covers the pairing rule directly, including the
partly-stamped case that a real upgrade will actually hit.
