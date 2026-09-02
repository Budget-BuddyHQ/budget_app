# Money Habits — systems reference

This is a **systems reference**, not a narrative log like `ARCHITECTURE.md`'s
dated sections — it answers "where does X live and when does X fire" for
the Money Habits feature specifically: a daily/weekly budgeting-habit
tracker (skip eating out, save spare change, wait before a big purchase), a
habit catalog with adjustable dollar amounts, structured "challenges," and a
savings jar that fills up as habits stick. Keep this updated if the
feature's wiring changes; `docs/ARCHITECTURE.md` §15/§16 has the narrative
of *why* it was built this way and how it got here.

**Naming note:** this feature was first prototyped as an "Eco Impact"
carbon-tracking module (inspired by a demo of a different app, Climer) and
then reworked into Money Habits per direct feedback — same tracker/catalog/
challenge/companion mechanics, entirely different subject matter (budgeting,
not carbon), and it does **not** touch the friends/leaderboard system (see
"What this feature is not," below). If you see a reference to "Climer" or
"eco" anywhere in the codebase, it's stale — flag it.

## 1. Data flow — where every stat lives

Same rule as the rest of the app: no migrations for anything inside
`spending_habits` — new state is a new jsonb key, read/written through a
getter/method pair.

| Data | Lives at | Getter | Written by |
| --- | --- | --- | --- |
| Savings jar fill XP (independent of player XP) | `spending_habits.habit_xp` | `UserStats.jarXp` | `UserStatsController.completeHabit` |
| Lifetime totals (money saved, smart choices) | `spending_habits.habit_totals` | `UserStats.habitTotals` | same |
| Per-month totals (`'YYYY-MM'` keys) | `spending_habits.habit_monthly` | `UserStats.habitMonthly` | same |
| Habit ids pinned to the Home tracker | `spending_habits.saved_habit_ids` | `UserStats.savedHabitIds` | `UserStatsController.saveHabit` / `unsaveHabit` |
| Saved adjustable-param value per habit | `spending_habits.saved_habit_params` | `UserStats.savedHabitParams` | same |
| Habit ids completed per day (trailing 14 days) | `spending_habits.habit_weekly_log` | `UserStats.habitWeeklyLog` | `completeHabit` |
| Habit count per day (trailing 365 days) | `spending_habits.habit_activity_calendar` | `UserStats.habitActivityCalendar` | `completeHabit` |
| One-off Challenge-task completions | `spending_habits.completed_challenge_tasks` | `UserStats.completedChallengeTasks` | `completeHabit` (when `challengeTaskId` is passed) |
| Date the jar was last fed a habit | `spending_habits.jar_last_active` | `UserStats.jarLastActive` | `completeHabit` |

Client read path: `UserStatsController.stats` (a `UserStats`, loaded/synced
by `SupabaseService`) → `MoneyHabitController` (a thin `ChangeNotifier`
derived view, `lib/controllers_that_updates_stats/money_habit_controller.dart`)
→ every Money Habits widget via `context.watch<MoneyHabitController>()`.
`MoneyHabitController` holds **no state of its own** for anything in the
table above — it recomputes from `_stats.stats` on every rebuild, the same
way `ProgressionService` is a derived view over `completedLessons`.

Write path: any mutation (`saveHabit`, `unsaveHabit`, `completeTrackedHabit`,
`completeChallengeTask`) calls straight into a matching `UserStatsController`
method (`saveHabit`/`unsaveHabit`/`completeHabit`), which builds one
`copyWith(spendingHabits: {...})` and calls the controller's private
`_saveStats` — the same single-round-trip upsert-then-cache-fallback every
other feature in this app uses. There is no separate save path to get out
of sync with the rest of `UserStats`.

## 2. Savings jar — where it's built and what drives it

File: `lib/widgets_custom_lotties/savings_jar_widget.dart` (`SavingsJarWidget`).

**There is no dedicated jar sprite** — none exists in the project and none
was generated for this feature. The jar is built from existing primitives,
the same philosophy `AmbientLottieCard` already uses for its "moving
turtle" decoration (a real static image, animated procedurally) — except
here there's no source image at all, so it's built entirely from:
- `JarStage.icon` (a plain `IconData` carried on the enum in
  `money_habit_models.dart` — `savings_outlined` → `savings_rounded` →
  `account_balance_wallet_rounded` → `workspace_premium_rounded`), sized
  larger per stage (`_iconSize` getter, `0.22×` to `0.58×` of the widget's
  total size), sitting on a small drawn "shelf."
- A `RadialGradient` glow behind it, tinted by **mood** (`JarMood.color`) —
  colour communicates "how's it doing", icon size communicates "how full
  it's gotten". These are deliberately two separate visual channels.
- A small `CustomPainter` (`_JarFacePainter`) drawing two dot eyes and a
  quadratic-bezier mouth whose curvature flips by mood (smile / flat /
  frown) — the only actual custom painting in the widget.
- `IdleHoverIcon` (`lib/widgets_custom_lotties/idle_hover_icon.dart`) wraps
  the whole thing for the idle bob/breathing motion — **no new
  `AnimationController` was written for this feature**; `IdleHoverIcon`
  already owns one and honours the platform "reduce motion" setting on its
  own.

**What triggers a stage/mood change**: nothing polls. `SavingsJarWidget` is
handed `stage`/`mood` as plain constructor params, computed fresh every
build by `_JarTab` in `money_habits_screen.dart`:
```dart
final stage = habits.jarStage;  // JarStage.forXp(habits.jarXp)
final mood  = habits.jarMood;   // JarMood.forDaysSinceActive(daysSince(jarLastActive))
```
`MoneyHabitController` calls `notifyListeners()` whenever the underlying
`UserStatsController` changes (registered as a listener in its
constructor), which happens immediately after any `completeHabit` save
resolves. Mood also changes passively just by time passing (opening the Jar
tab a week later recomputes `daysSince` fresh, no save required) — see §3.

## 3. Event timing — when things update, and how often

**Nothing in this feature runs on a timer, poll, or background job.** Every
state change is a direct response to a user action:

- **Habit completion** (Track tab's grid tap, or Activity/Challenges'
  buttons): updates weekly log, calendar, totals, monthly totals, habit XP,
  and the jar's last-active date **in one save**, synchronously awaited by
  the button's `onPressed`. No batching or delayed write — the UI reflects
  the new state as soon as the awaited `Future` resolves (a toast confirms
  it via `GameToast.show`).
- **Weekly grid rollover**: the 7 columns are `HabitDateKeys.lastDayKeys(7)`,
  computed fresh on every build from `DateTime.now()` — no explicit "new
  week" event. Crossing midnight simply changes what "today" resolves to on
  the next rebuild, the same way `DailyPlanController._todayKey()` works.
- **Weekly log / activity-calendar pruning**: happens inline, every time
  `completeHabit` runs (`HabitDateKeys.pruneToTrailing(..., 14)` and
  `(..., 365)`) — not a separate cleanup pass.
- **Jar mood decay**: as noted in §2, mood is **never written** — it's
  `JarMood.forDaysSinceActive(daysSince(jar_last_active))`, recomputed from
  wall-clock time every time it's read.

## 4. Navigation map — every entry point and transition

| From | To | How |
| --- | --- | --- |
| Home screen, `_TodayCard` | Daily tab | `onNavSelected(AppTabIndex.daily)` — a **tab switch, not a push**. It used to `Navigator.push` a fresh `MoneyHabitsScreen`, which put a second live instance on top of the one already in `MainNavigation`'s `IndexedStack`; each had its own `TabController`, so which inner tab you saw depended on which route you came through. Falls back to the `/daily` named route when Home is mounted without a tab bar |
| `MoneyHabitsScreen`'s Today/My Week/Find/Challenges/Jar/Coach | (within the same screen) | **Not** separate pushes — a single `TabController(length: MoneyHabitsTab.count)` + `TabBar`/`TabBarView`, identical in shape to `StockMarketPage`'s 5-tab Market Board. Address the tabs by `MoneyHabitsTab.*`; a "Today" tab was inserted at the front and every literal index shifted by one |
| Today tab, tapping a quest row | the quest's own surface | `onNavSelected` to the Academy/Arcade/Adventure tab, or `onOpenInnerTab(MoneyHabitsTab.week)` for a habit quest, after `DailyPlanController.completeQuest` |
| Activity tab, tapping a habit card | Habit detail | `showModalBottomSheet` (`_HabitDetailSheet`) — a sheet, not a new screen, since it's a quick adjust-and-save/complete interaction |
| Profile screen | Impact stats | **Not a navigation** — `_MoneyHabitsProfileCard` is an inline section added directly into `ProfileScreen`'s existing `ListView`, next to `_BadgeShowcase` |

No 7th bottom tab was added — `PopNavBar.appTabs`/`AppTabIndex`/
`MainNavigation`'s `IndexedStack` are untouched. This mirrors exactly how
`LeaderboardScreen`, `AdventureWorldScreen`, `FeedbackScreen`, and
`AdminScreen` already work: a pushed screen with its own `Scaffold`, no
`CustomBottomNav`, launched from wherever it's contextually relevant.

## 5. What this feature is *not*

Money Habits does **not** own the friends/leaderboard system.
`SupabaseService.friendCodeFor` / `addFriendByCode` and `ProfileScreen`'s
`_FriendsCard` are a separate, standing feature — they were briefly wired
through the eco-impact controller during the earlier prototype, then
decoupled back onto `SupabaseService` directly (via
`context.watch<UserStatsController>().stats.id`) once the feature was
reworked into Money Habits, so a future retheme of one doesn't ripple into
the other. See `docs/ARCHITECTURE.md` §14 and the `pending-supabase-sql`
memory note for the friends feature's own backend status (a `friendships`
table + RLS policies that exist in code but haven't been applied to the
live Supabase project yet — unrelated to anything in this doc).

## 6. Where things are, at a glance

| Concern | File |
| --- | --- |
| Data model (catalog, challenges, jar enums, date-key helpers) | `lib/models_Like_Skins_and_lessons_templates/money_habit_models.dart` |
| `UserStats` habit getters | `lib/services_backend_and_other_services/supabase_service.dart` (search `Money Habits`) |
| `UserStatsController` habit mutators | `lib/controllers_that_updates_stats/user_stats_controller.dart` (search `Money Habits`) |
| Derived controller widgets watch | `lib/controllers_that_updates_stats/money_habit_controller.dart` |
| Entry screen + all 4 tabs | `lib/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart` |
| Savings jar widget | `lib/widgets_custom_lotties/savings_jar_widget.dart` |
| Challenge task row widget | `lib/custom_made_widgets/habit_challenge_row_item.dart` |
| Weekly grid + calendar heatmap widgets | `lib/widgets_custom_lotties/habit_progress_grids.dart` |
| Home entry card | `lib/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart` (`_MoneyHabitsPromo`) |
| Profile integration | `lib/screens_minigames_admin_etc/profile/profile_screen.dart` (`_MoneyHabitsProfileCard`) |
| Pure-logic tests | `test/money_habit_test.dart` |
