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
