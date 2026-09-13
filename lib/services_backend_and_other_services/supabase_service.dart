import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../models_Like_Skins_and_lessons_templates/life_record.dart';
import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../constants/privacy_policy.dart';
import '../models_Like_Skins_and_lessons_templates/player_profile.dart';

/// The hosted page the emailed password-reset link lands on.
///
/// A Supabase **edge function** (`supabase/functions/pages`), which is
/// generated from `docs/password-reset.html` by
/// `tool/build_pages_function.py`. The page forwards straight on to
/// [passwordResetDeepLink], carrying the auth payload with it.
///
/// **This used to be GitHub Pages, and it returned 404 on every
/// request.** The repository is private and Pages does not serve
/// private repositories on a free plan, so the emailed link landed on
/// "This site can't be reached" — the exact symptom the long note on
/// [passwordResetRedirectUrl] was written to rule out, arriving again
/// from a completely different direction. Nothing in the app could
/// show it: the constant was right, the deep link was right, and the
/// only evidence lived in an email opened on a phone.
///
/// An edge function needs no new account and no change to the
/// repository's visibility, and it puts the landing page on the same
/// origin as the auth server that issued the link.
///
/// **This is also what the project's Site URL should be set to.** See the
/// long note on [passwordResetRedirectUrl] for why that is the load-bearing
/// half of the fix rather than a nicety.
const String passwordResetLandingUrl =
    'https://cwqjduingvevagrxbwts.supabase.co/functions/v1/pages/password-reset';

/// The custom scheme the OS hands back to this app.
///
/// Declared natively as well — Android: an intent-filter in
/// AndroidManifest.xml; iOS: CFBundleURLTypes in Info.plist — or the OS has
/// no idea who owns `budgetbuddy://` and the link does nothing at all.
const String passwordResetDeepLink = 'budgetbuddy://password-reset';

/// Where the emailed password-reset link sends the player back to.
///
/// **Why this is an https page rather than the app's own scheme.**
///
/// It used to be `budgetbuddy://password-reset` directly, and the reset email
/// arrived pointing at `http://localhost:3000` — "This site can't be reached".
/// The app was not at fault: this constant was right, the intent-filter was
/// right, and `main.dart` handled the recovery session correctly. Supabase
/// checks `redirect_to` against the project's Site URL and Redirect
/// allow-list, and when the value is not on that list it does not report an
/// error — it *substitutes the Site URL*, which on a new project is the
/// `localhost:3000` placeholder. One missing allow-list entry, and the
/// symptom is a broken app rather than a broken setting.
///
/// Pointing at a page that is *also* the Site URL removes that failure mode
/// entirely: the allow-listed value and the fallback value are the same page,
/// so getting the dashboard wrong can no longer produce a dead link.
///
/// It is also more reliable in the place it actually runs. The mail is opened
/// in Gmail's WebView or an in-app Safari, and those handle a **302 to a
/// custom scheme** poorly — several refuse it outright, which looks exactly
/// like the bug above and is not fixable from the dashboard. Landing on an
/// ordinary https page first and letting *that* invoke the scheme is the path
/// browsers actually permit, and it leaves somewhere to explain the two cases
/// a deep link cannot: the app is not installed, or the link has expired.
///
/// The cost is one extra hop. That is worth paying for a flow whose failure
/// mode is "nobody can get back into their account".
///
/// **No `localhost` branch, on any platform.** There used to be one for web —
/// `http://localhost:5960/`, the Flutter dev server. It is the same class of
/// mistake as the `localhost:3000` Site URL that started all of this: an
/// address that resolves on exactly one machine, in one terminal, while a
/// dev server happens to be running on one particular port. Everywhere else
/// it is a connection error, and the person hitting it has no way to tell
/// that from a broken app.
///
/// A reset link is emailed. Emails get opened on phones, on other people's
/// computers, and days later. There is no situation in which the correct
/// destination for one is a loopback address.
///
/// **When a web build is deployed**, this needs to become that build's real
/// origin for `kIsWeb` — on web the app *is* the page, and the PKCE verifier
/// is held in that origin's storage, so a redirect anywhere else cannot
/// complete the exchange. Until such a build exists, sending everyone to the
/// landing page is both honest and the only thing that works: it explains
/// that the link has to be opened on the device that asked for it.
const String passwordResetRedirectUrl = passwordResetLandingUrl;

@immutable
class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.createdAt,
    required this.category,
  });

  final String id;
  final String title;
  final String description;
  final int amount;
  final DateTime createdAt;
  final String category;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'created_at': createdAt.toUtc().toIso8601String(),
      'category': category,
    };
  }

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Transaction').toString(),
      description: (json['description'] ?? '').toString(),
      amount: _readInt(json['amount']),
      createdAt: _readDate(json['created_at']) ?? DateTime.now().toUtc(),
      category: (json['category'] ?? 'general').toString(),
    );
  }
}

@immutable
class UserStats {
  const UserStats({
    required this.id,
    required this.username,
    required this.gold,
    required this.xp,
    required this.literacyPoints,
    required this.personalityType,
    required this.spendingHabits,
    required this.transactions,
    required this.portfolioHistory,
    required this.holdings,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final int gold;
  final int xp;
  final int literacyPoints;
  final String personalityType;
  final Map<String, dynamic> spendingHabits;
  final List<LedgerTransaction> transactions;
  final List<double> portfolioHistory;

  /// Share/lot counts, keyed like `stock_AAPL`. Fractional because a coin is
  /// worth a fraction of a share, so you buy slices (e.g. 0.5 of a share).
  final Map<String, double> holdings;
  final DateTime updatedAt;

  factory UserStats.defaults(String userId) {
    final now = DateTime.now().toUtc();
    return UserStats(
      id: userId,
      username: 'Username3189',
      gold: 2000,
      xp: 850,
      literacyPoints: 850,
      personalityType: 'Spender',
      spendingHabits: const <String, dynamic>{
        'risk_tolerance': 'balanced',
        'confidence_score': 2.0,
        'missed_questions': <String>[],
        'equipped_skin': kDefaultPlayerSkinId,
        'equipped_mascot': kDefaultMascotSkinId,
        'unlocked_skins': <String>[kDefaultMascotSkinId, kDefaultPlayerSkinId],
      },
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_reward_daily',
          title: 'Daily Challenge Reward',
          description: 'Pocketed bonus gold from a clean budget run.',
          amount: 120,
          createdAt: now.subtract(const Duration(minutes: 6)),
          category: 'challenge',
        ),
        LedgerTransaction(
          id: 'txn_market_unlock',
          title: 'Market Unlock',
          description: 'Unlocked the market district tools.',
          amount: -40,
          createdAt: now.subtract(const Duration(days: 1, hours: 2)),
          category: 'unlock',
        ),
        LedgerTransaction(
          id: 'txn_boss_bonus',
          title: 'Boss Battle Bonus',
          description: 'Perfect streak reward from yesterday.',
          amount: 200,
          createdAt: now.subtract(const Duration(days: 1, hours: 5)),
          category: 'boss_battle',
        ),
      ],
      portfolioHistory: const <double>[0.24, 0.3, 0.36, 0.41, 0.48, 0.55, 0.61],
      holdings: const <String, double>{'indexFunds': 3, 'stocks': 2},
      updatedAt: now,
    );
  }

  factory UserStats.fromMap(Map<String, dynamic> json) {
    final spendingHabits = _readMap(json['spending_habits']);
    final holdings = _readDoubleMap(json['holdings']);
    final transactions = _readTransactions(json['transaction_ledger']);
    final portfolioHistory = _readDoubleList(json['portfolio_history']);

    return UserStats(
      id: (json['id'] ?? '').toString(),
      username:
          (json['username'] ?? spendingHabits['username'] ?? 'Username3189')
              .toString(),
      gold: _readInt(json['gold']),
      xp: _readInt(json['xp']),
      literacyPoints: _readInt(
        json['literacy_points'] ?? json['literacy_score'],
      ),
      personalityType: (json['personality_type'] ?? 'Spender').toString(),
      spendingHabits: <String, dynamic>{
        'username': (json['username'] ?? 'Username3189').toString(),
        ...spendingHabits,
      },
      transactions: transactions.isEmpty
          ? UserStats.defaults(
              (json['id'] ?? 'user_123').toString(),
            ).transactions
          : transactions,
      portfolioHistory: portfolioHistory.isEmpty
          ? UserStats.defaults(
              (json['id'] ?? 'user_123').toString(),
            ).portfolioHistory
          : portfolioHistory,
      holdings: holdings.isEmpty
          ? UserStats.defaults((json['id'] ?? 'user_123').toString()).holdings
          : holdings,
      updatedAt: _readDate(json['updated_at']) ?? DateTime.now().toUtc(),
    );
  }

  int get level => math.max(1, xp ~/ 120);

  String get levelTitle => 'Level $level Finance Wizard';

  double get levelProgress => (xp % 120) / 120;

  /// The **player** skin: who you walk around town and fight as.
  ///
  /// This key used to hold whatever you last equipped, turtle or villager,
  /// because there was only one slot. Saves written then can hold a turtle
  /// here. That is read as "no player skin chosen yet" rather than rewritten,
  /// so no existing save is changed by upgrading — the turtle moves to
  /// [equippedMascot] on read, and the player slot shows the default villager.
  String get equippedSkin {
    final value = spendingHabits['equipped_skin']?.toString().trim() ?? '';
    return fitsSlot(value, SkinSlot.player) ? value : kDefaultPlayerSkinId;
  }

  /// The **mascot**: the turtle that guides and explains.
  ///
  /// Falls back to a turtle left in the old single slot, so a player who had
  /// equipped Guild Runner before the split still has Guild Runner as their
  /// guide afterwards.
  String get equippedMascot {
    final value = spendingHabits['equipped_mascot']?.toString().trim() ?? '';
    if (fitsSlot(value, SkinSlot.mascot)) return value;
    final legacy = spendingHabits['equipped_skin']?.toString().trim() ?? '';
    return fitsSlot(legacy, SkinSlot.mascot) ? legacy : kDefaultMascotSkinId;
  }

  List<String> get unlockedSkins {
    final raw = spendingHabits['unlocked_skins'];
    if (raw is List) {
      final normalized = raw
          .map((entry) => entry.toString())
          .where(
            (entry) => entry.trim().isNotEmpty && isRegisteredSkinId(entry),
          )
          .toSet()
          .toList(growable: false);
      // Both defaults are always owned. Before the split only the turtle was,
      // so an old save reading the default villager into its player slot
      // would otherwise show that villager equipped and locked at once.
      return <String>{
        kDefaultMascotSkinId,
        kDefaultPlayerSkinId,
        ...normalized,
      }.toList(growable: false);
    }
    return const <String>[kDefaultMascotSkinId, kDefaultPlayerSkinId];
  }

  /// Ids of [LifeEndingArchetype]s the player has actually reached in Life.
  /// Endings used to be computed, shown once on the epilogue, then forgotten —
  /// persisting them turns them into a collection worth chasing.
  List<String> get discoveredEndings {
    final raw = spendingHabits['discovered_endings'];
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// Badge ids the player has already been shown the celebration for.
  /// Badges themselves are *derived* from progress, so this only records
  /// "we already congratulated them" — it never decides whether a badge is
  /// earned.
  List<String> get celebratedBadges {
    final raw = spendingHabits['celebrated_badges'];
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// Finished Life runs, newest first.
  ///
  /// Separate from [discoveredEndings], which is only a set of ids: this is
  /// the per-run history the Past Lives screen and the personal bests are
  /// built from. Both are kept — the ending set answers "have I ever seen
  /// this outcome", which survives the record cap trimming an old run.
  LifeRecordBook get lifeRecords =>
      LifeRecordBook.fromJson(spendingHabits['life_records']);

  List<String> get completedLessons {
    final raw = spendingHabits['completed_lessons'];
    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// Arcade history keyed by game id, holding `best` and `plays`.
  Map<String, dynamic> get arcadeScores {
    final raw = spendingHabits['arcade_scores'];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  /// Highest score recorded for [gameId], or null if never played.
  int? bestArcadeScore(String gameId) {
    final entry = arcadeScores[gameId];
    if (entry is! Map) {
      return null;
    }
    final best = _readInt(entry['best']);
    return best > 0 ? best : null;
  }

  int arcadePlays(String gameId) {
    final entry = arcadeScores[gameId];
    return entry is Map ? _readInt(entry['plays']) : 0;
  }

  /// Quiz results keyed by lesson-graph node id. Each value holds `correct`,
  /// `total`, `best_correct` and `attempts`.
  Map<String, dynamic> get quizScores {
    final raw = spendingHabits['quiz_scores'];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  /// Best-ever accuracy on an assessment node, or null if never attempted.
  double? accuracyFor(String nodeId) {
    final entry = quizScores[nodeId];
    if (entry is! Map) {
      return null;
    }
    final total = _readInt(entry['total']);
    if (total <= 0) {
      return null;
    }
    return _readInt(entry['best_correct']) / total;
  }

  /// When each money idea should next be reviewed.
  ///
  /// The spaced-repetition schedule, stored as a small map keyed by concept
  /// name. See `review_schedule.dart` for the algorithm and why it runs
  /// entirely on the device.
  ///
  /// Only concepts that have actually been studied are written, so this stays
  /// empty for a new account and does not grow every time a concept is added
  /// to the enum.
  Map<String, dynamic> get reviewScheduleMap {
    final raw = spendingHabits['review_schedule'];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  /// Estimated mastery per money idea, from Bayesian Knowledge Tracing.
  ///
  /// Stored separately from `quiz_scores` because it answers a different
  /// question. `quiz_scores` records what happened; this records what the app
  /// *believes* about the learner as a result — with the 25% chance of
  /// guessing a four-option question already discounted. See
  /// `knowledge_tracing.dart`.
  Map<String, dynamic> get knowledgeMap {
    final raw = spendingHabits['knowledge'];
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  /// Local date key (yyyy-mm-dd) the daily plan was last generated for.
  String get dailyPlanDateKey =>
      spendingHabits['daily_plan_date']?.toString() ?? '';

  /// Quest ids completed within the current daily plan.
  Set<String> get dailyQuestsDone {
    final raw = spendingHabits['daily_quests_done'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  /// Consecutive days the player has completed at least one quest.
  int get dailyStreak => _readInt(spendingHabits['daily_streak']);

  /// Local date key the streak was last advanced on.
  String get dailyStreakDateKey =>
      spendingHabits['daily_streak_date']?.toString() ?? '';

  /// Skill ids the player has missed questions on and not yet recovered.
  List<String> get weakSkills {
    final raw = spendingHabits['weak_skills'];
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  // ---------------- Money Habits ----------------
  // read + written the same way as everything else above, ad hoc keys
  // inside spendingHabits, no migration. docs/MONEY_HABITS_FEATURE.md has
  // the full data flow if you need it

  /// Independent progression counter driving the savings jar's fill
  /// stage — deliberately separate from [xp] so the jar reacts only to
  /// money-habit activity, not stock trades or quizzes.
  int get jarXp => _readInt(spendingHabits['habit_xp']);

  /// Lifetime running totals (money saved, smart choices kept).
  HabitImpact get habitTotals =>
      HabitImpact.fromMap(_readMap(spendingHabits['habit_totals']));

  /// Per-month totals, keyed 'YYYY-MM' — powers the profile's
  /// month-over-month comparison without recomputing from raw history.
  Map<String, HabitImpact> get habitMonthly {
    final raw = _readMap(spendingHabits['habit_monthly']);
    return raw.map(
      (key, value) => MapEntry(key, HabitImpact.fromMap(_readMap(value))),
    );
  }

  /// Catalog habit ids pinned to the Home weekly tracker.
  List<String> get savedHabitIds {
    final raw = spendingHabits['saved_habit_ids'];
    if (raw is! List) return const <String>[];
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// User-authored habit templates. Kept in the same JSON blob as the rest
  /// of Money Habits so custom habits sync/cache with normal progress.
  List<HabitTemplate> get customHabitTemplates {
    final raw = spendingHabits['custom_habits'];
    if (raw is! List) return const <HabitTemplate>[];
    return raw
        .whereType<Map>()
        .map((entry) => customHabitFromMap(entry.cast<String, dynamic>()))
        .where((habit) => habit.id.startsWith(customHabitIdPrefix))
        .toList(growable: false);
  }

  HabitTemplate? habitTemplateForId(String habitId) =>
      habitTemplateById(habitId, customHabits: customHabitTemplates);

  /// Per-habit adjustable-parameter value saved alongside a pinned habit
  /// (e.g. "$5"), keyed by habit id. Falls back to the template's default
  /// when absent.
  Map<String, double> get savedHabitParams {
    final raw = _readMap(spendingHabits['saved_habit_params']);
    return raw.map((key, value) => MapEntry(key, _readDouble(value)));
  }

  /// Habit-id list completed per day, trailing 14 days only — feeds the
  /// weekly tracker grid.
  Map<String, List<String>> get habitWeeklyLog {
    final raw = _readMap(spendingHabits['habit_weekly_log']);
    return raw.map((key, value) {
      final list = value is List
          ? value.map((e) => e.toString()).toList(growable: false)
          : const <String>[];
      return MapEntry(key, list);
    });
  }

  /// Completed-habit count per day, trailing 365 days — a compact,
  /// longer-retention cousin of [habitWeeklyLog] purely for the profile
  /// calendar heatmap (density only, no per-habit detail needed there).
  Map<String, int> get habitActivityCalendar {
    final raw = _readMap(spendingHabits['habit_activity_calendar']);
    return raw.map((key, value) => MapEntry(key, _readInt(value)));
  }

  /// One-off Challenge-task completions (separate from the *recurring*
  /// saved-habit tracker) — same shape as [completedLessons].
  List<String> get completedChallengeTasks {
    final raw = spendingHabits['completed_challenge_tasks'];
    if (raw is! List) return const <String>[];
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// ISO date the jar was last fed a completed habit. Mood is always
  /// derived from this at read time (see [JarMood.forDaysSinceActive]) —
  /// never stored, so it can't go stale.
  String? get jarLastActive => _readString(spendingHabits['jar_last_active']);

  /// Adventure Town spot ids the player has already visited. Previously
  /// tracked only in `AdventureWorldScreen`'s own `State`, so leaving the
  /// screen — even just to check Profile — reset "visit every place" back
  /// to zero every time.
  /// When each `portfolioHistory` point was recorded, as UTC times.
  ///
  /// **Why this exists.** The equity curve stored bare numbers with no times,
  /// and the chart invented them — `_flatCandles` pretended every snapshot was
  /// exactly one minute apart, ending now. So the x-axis was fiction, and the
  /// window could never span more than one minute per point however long the
  /// player had actually been trading. "Let me see further than a day" was not
  /// a range setting, it was missing data.
  ///
  /// Kept in `spending_habits` rather than as a new column so no migration is
  /// needed, matching how every other ad-hoc field on this model is stored.
  /// Older saves have no timestamps at all, so this can be shorter than the
  /// value list — callers must handle that rather than indexing blindly.
  List<DateTime> get portfolioHistoryAt {
    final raw = spendingHabits['portfolio_history_at'];
    if (raw is! List) return const <DateTime>[];
    return raw
        .map((entry) => int.tryParse(entry.toString()))
        .whereType<int>()
        .map((s) => DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true))
        .toList(growable: false);
  }

  List<String> get townVisitedSpotIds {
    final raw = spendingHabits['town_visited_spots'];
    if (raw is! List) return const <String>[];
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// Town coin pickups already collected, by `"x_y"` tile id (`kTownCoins`
  /// has no id of its own). Same gap as [townVisitedSpotIds] — worse,
  /// because each unpersisted coin paid out real gold via
  /// `applyChallengePayload`, so leaving and re-entering the town let a
  /// player collect the same coins for infinite gold.
  List<String> get townCollectedCoinIds {
    final raw = spendingHabits['town_collected_coins'];
    if (raw is! List) return const <String>[];
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  /// Highest Coin Cascade level the player has cleared.
  ///
  /// Was session-scoped — a field on the screen's State, gone the moment the
  /// page was popped. The comment defending that said persisting it would
  /// hand a returning player level 7 with no idea what the earlier rules
  /// were, which is a real concern and the wrong fix for it: the level picker
  /// still opens on the ladder, so an unlocked level is somewhere you *may*
  /// go rather than where you are put. What the session scope actually did
  /// was make thirteen levels of progress evaporate every time somebody left
  /// the arcade, which is most of "I don't know what to work for in that
  /// game".
  ///
  /// 0 means nothing cleared yet, so level 1 is the only one open.
  int get cascadeClearedThrough => _readInt(spendingHabits['cascade_cleared']);

  /// Finished Coin Cascade runs, and the tiles cleared across all of them.
  ///
  /// **Totals rather than a stored average, on purpose.** An average has to be
  /// read, re-weighted and written back on every run, so a lost write
  /// silently corrupts every future reading of it. Totals only ever go up:
  /// a dropped write costs one run's worth of accuracy and nothing else, and
  /// the share is recomputed from scratch each time it is asked for.
  ///
  /// These exist so the coach can compare how somebody *plays* against how
  /// they *answer* — see the cross-domain rules in `money_analyzer.dart`.
  /// Coin Cascade never uses the word budget while it is being played, which
  /// is what makes the split it produces worth checking a quiz score against.
  int get cascadeRuns => _readInt(spendingHabits['cascade_runs']);

  /// Town money puzzles answered correctly, ever.
  ///
  /// Feeds the NPC missions that ask you to prove a skill rather than to
  /// visit a place — see `town_missions.dart`. Counted here rather than per
  /// life because a mission that resets every time you start a new character
  /// is one nobody would ever finish.
  int get challengesSolved => _readInt(spendingHabits['challenges_solved']);

  /// The best Ranked life this player has finished.
  ///
  /// **Ranked had no memory at all.** `scoreRankedRun` computed a score, the
  /// epilogue showed it once, and the number was gone the moment that screen
  /// was popped — so a mode whose entire premise is *"given the same start
  /// everybody else got, how much can you build?"* could not answer "how did
  /// I do compared to last time", let alone compared to anyone else.
  int get bestRankedScore => _readInt(spendingHabits['best_ranked_score']);

  /// The grade letter that came with [bestRankedScore], for display. Stored
  /// rather than recomputed because the grade bands may be retuned, and a
  /// board that silently re-grades old runs is lying about history.
  String get bestRankedGrade =>
      (spendingHabits['best_ranked_grade'] ?? '').toString();

  /// The age reached on that run. The one number that says *how* the score
  /// was got — a fortune at thirty-five and a comfortable eighty can total
  /// the same, and they are not the same run.
  int get bestRankedAge => _readInt(spendingHabits['best_ranked_age']);

  /// Missions finished, by id.
  ///
  /// The whole file `town_missions.dart` was written and then referenced by
  /// nothing at all — 346 lines of orphaned code, while NPCs carried on
  /// reciting canned lines. This is the state it needed and never had.
  Set<String> get completedMissionIds {
    final raw = spendingHabits['completed_missions'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return const <String>{};
  }

  int get cascadeNeedsTotal => _readInt(spendingHabits['cascade_needs_total']);
  int get cascadeWantsTotal => _readInt(spendingHabits['cascade_wants_total']);
  int get cascadeSavesTotal => _readInt(spendingHabits['cascade_saves_total']);

  /// Town encounters that have already paid out, by `townEncounterFor().id`.
  ///
  /// **The same hole as [townCollectedCoinIds], one layer up.** Coins were
  /// de-duplicated because each pickup paid real gold and stepping outside
  /// respawned them. The buildings had exactly that problem and nobody had
  /// noticed, because it is one indirection further away: `_openSpot` calls
  /// `applyChallengePayload` with the chosen option's gold, XP and literacy
  /// every single time, with no memory at all.
  ///
  /// Worse, the anti-repetition work made it *easier*. Today's scene is keyed
  /// partly on `TownCondition`, which is rolled fresh on every entry to the
  /// town — so leaving and coming back re-deals every building. That is
  /// exactly right for keeping the town interesting and exactly wrong for the
  /// economy: it turned "walk out, walk back in" into a fresh set of twelve
  /// paying conversations, repeatable for as long as somebody could be
  /// bothered.
  ///
  /// Keyed on the **encounter**, not the building. Keying on the building
  /// would mean one visit locks a shop out for good, which throws away the
  /// rotation; keying on the encounter means each distinct conversation pays
  /// once and the town still has somewhere new to take you tomorrow.
  List<String> get townResolvedSceneIds {
    final raw = spendingHabits['town_resolved_scenes'];
    if (raw is! List) return const <String>[];
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String get profileImageUrl {
    final value = spendingHabits['profile_image_url']?.toString().trim();
    if (value == null || value.isEmpty) {
      return '';
    }
    return value;
  }

  /// Which villager body the avatar renders with. Defaults from the player's
  /// self-described gender the first time, then follows any explicit choice
  /// made in the customise screen.
  VillagerBody get villagerBody {
    final explicit = spendingHabits[ProfileKeys.villagerBody];
    if (explicit != null) {
      return VillagerBody.fromId(explicit);
    }
    return gender == GenderIdentity.female
        ? VillagerBody.feminine
        : VillagerBody.masculine;
  }

  /// Which privacy policy version this player agreed to, or empty.
  ///
  /// Recorded so a policy change can ask again rather than silently holding
  /// somebody to a document they never saw, and so "did this account accept
  /// it" has an answer that is not a guess. Stored alongside everything else
  /// in `spending_habits`, so it syncs and survives a reinstall.
  String get privacyAcceptedVersion =>
      spendingHabits[PrivacyKeys.acceptedVersion]?.toString() ?? '';

  /// When that acceptance happened, UTC, or null if never.
  DateTime? get privacyAcceptedAt {
    final raw = spendingHabits[PrivacyKeys.acceptedAt]?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// True when this player has accepted the policy the app is currently
  /// shipping. A bump to [kPrivacyPolicyVersion] makes this false again.
  bool get hasAcceptedCurrentPrivacyPolicy =>
      privacyAcceptedVersion == kPrivacyPolicyVersion;

  AgeBand get ageBand => AgeBand.fromId(spendingHabits[ProfileKeys.ageBand]);

  GenderIdentity get gender =>
      GenderIdentity.fromId(spendingHabits[ProfileKeys.gender]);

  /// Drives which worked examples the Academy shows. See [AgeBand.lifeStage].
  LifeStage get lifeStage => ageBand.lifeStage;

  /// True once the player has been through the age/gender step, whether or not
  /// they chose to disclose anything. Without this we cannot tell "skipped" from
  /// "not asked yet" and would re-prompt forever.
  bool get hasCompletedPersonalDetails =>
      spendingHabits[ProfileKeys.onboardingComplete] == true;

  Map<String, dynamic> toStorageMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'gold': gold,
      'xp': xp,
      'literacy_points': literacyPoints,
      'personality_type': personalityType,
      'spending_habits': <String, dynamic>{
        ...spendingHabits,
        'username': username,
        'equipped_skin': equippedSkin,
        'equipped_mascot': equippedMascot,
        'unlocked_skins': unlockedSkins,
      },
      'transaction_ledger': transactions
          .map((transaction) => transaction.toJson())
          .toList(growable: false),
      'portfolio_history': portfolioHistory,
      'holdings': holdings,
      // NOTE age/gender deliberately NOT written here!! they were mirrored
      // into age/gender columns for a bit, but those columns live on
      // `profiles` (the one with disabled + profiles_id_fkey), not on
      // user_stats. so the upsert died with "Could not find the 'age'
      // column of 'user_stats' in the schema cache" and every save quietly
      // fell back to cached data. The app reads the bucketed AgeBand /
      // GenderIdentity out of `spending_habits` above regardless, so nothing
      // functional depends on a mirror. If one is wanted again, write it to
      // `profiles` in its own call rather than into this map.
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  UserStats copyWith({
    String? id,
    String? username,
    int? gold,
    int? xp,
    int? literacyPoints,
    String? personalityType,
    Map<String, dynamic>? spendingHabits,
    List<LedgerTransaction>? transactions,
    List<double>? portfolioHistory,
    Map<String, double>? holdings,
    DateTime? updatedAt,
  }) {
    return UserStats(
      id: id ?? this.id,
      username: username ?? this.username,
      gold: gold ?? this.gold,
      xp: xp ?? this.xp,
      literacyPoints: literacyPoints ?? this.literacyPoints,
      personalityType: personalityType ?? this.personalityType,
      spendingHabits: spendingHabits ?? this.spendingHabits,
      transactions: transactions ?? this.transactions,
      portfolioHistory: portfolioHistory ?? this.portfolioHistory,
      holdings: holdings ?? this.holdings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class SyncState {
  const SyncState({
    required this.synced,
    required this.usedCache,
    required this.message,
  });

  final bool synced;
  final bool usedCache;
  final String message;
}

@immutable
class ProvisionedUserStats {
  const ProvisionedUserStats({
    required this.stats,
    required this.syncState,
    required this.createdProfile,
    required this.migratedLegacyProfile,
  });

  final UserStats stats;
  final SyncState syncState;
  final bool createdProfile;
  final bool migratedLegacyProfile;
}

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.username,
    required this.literacyPoints,
    required this.xp,
    required this.gold,
    required this.isCurrentUser,
    this.profileImageUrl = '',
    this.equippedSkin = '',
    this.personalityType = '',
    this.lessonsCompleted = 0,
    this.dailyStreak = 0,
    this.rankedScore = 0,
    this.rankedGrade = '',
    this.rankedAge = 0,
    this.updatedAt,
  });

  final String id;
  final int rank;
  final String username;
  final int literacyPoints;
  final int xp;
  final int gold;
  final bool isCurrentUser;
  final String profileImageUrl;

  /// Best Ranked life, for the Ranked board. Zero for anybody who has never
  /// finished one, and zero for everybody until
  /// `0005_leaderboard_profile.sql` has been run — read defensively for the
  /// same reason as every other column added after the original six.
  final int rankedScore;
  final String rankedGrade;
  final int rankedAge;

  // --- The extras behind FriendProfileScreen ----------------------------
  //
  // **All of these default to empty and none of them are required**, and that
  // is the important part rather than a Dart nicety. They come from columns
  // added to the `leaderboard` view by `0005_leaderboard_profile.sql`, and
  // this project has a history of migrations sitting un-run for weeks — the
  // friends feature itself shipped ahead of `0002` and spent that time
  // showing players a Postgres error code.
  //
  // So the friend profile is built to be *worth opening* on the columns that
  // already exist, and to quietly gain three more sections when the migration
  // lands. A feature that degrades is one that can ship on either side of a
  // deploy; a feature that requires the migration is one more thing that can
  // be broken by forgetting.

  /// Their equipped skin id, for drawing their villager rather than a letter.
  final String equippedSkin;

  /// "Saver", "Spender", … — the app's own read on how they play.
  final String personalityType;

  final int lessonsCompleted;
  final int dailyStreak;

  /// Last time their row was written, which is the closest thing to "last
  /// seen" this schema has. Null when the view does not expose it.
  final DateTime? updatedAt;

  String get scoreLabel => '$literacyPoints LP';

  /// The headline figure for [metric], and the supporting line under it.
  ///
  /// Stated on the entry rather than in the widget so the podium and the
  /// rows cannot disagree — they were two separate `byGold ? ... : ...`
  /// expressions, which is two places to forget a third case.
  String headlineFor(LeaderboardMetric metric) => switch (metric) {
    LeaderboardMetric.literacy => scoreLabel,
    LeaderboardMetric.gold => '${gold}g',
    // Never "0" for somebody who has not played it. A blank is honest; a
    // zero looks like a score you earned.
    LeaderboardMetric.ranked => rankedScore > 0 ? '$rankedScore' : '—',
  };

  String detailFor(LeaderboardMetric metric) => switch (metric) {
    LeaderboardMetric.literacy => '$xp XP • $gold gold',
    LeaderboardMetric.gold => '$literacyPoints LP • $xp XP',
    // The grade and the age, because they are what the score is made of. A
    // fortune at thirty-five and a comfortable eighty can total the same and
    // are not the same run.
    LeaderboardMetric.ranked =>
      rankedScore > 0
          ? '${rankedGrade.isEmpty ? 'Scored' : rankedGrade} • lived to '
                '$rankedAge'
          : 'No ranked life yet',
  };
}

  const CurrentUserProfile({required this.role, required this.avatarUrl});
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const String userStatsTable = 'user_stats';
  static const String feedbackTable = 'app_feedback';
  static const String leaderboardView = 'leaderboard';
  static const String friendshipsTable = 'friendships';

  /// Derives a shareable "friend code" from a user id — the first 8
  /// characters (the first dash-delimited segment of a uuid), uppercased.
  /// No new column needed; resolving a code back to an id is done by
  /// matching against the already-broadly-readable [leaderboardView].
  static String friendCodeFor(String userId) =>
      userId.substring(0, math.min(8, userId.length)).toUpperCase();
  static const String defaultProfileImageBucket = 'profile_pictures';
  static const Duration _supabaseReadTimeout = Duration(seconds: 6);

  /// Longer than a read, for the one call that cannot be retried blind.
  ///
  /// Account deletion touches four tables and an auth row in one
  /// transaction. Timing that out at six seconds and telling the player it
  /// failed would be the worst possible lie to tell them, because by then it
  /// may well have succeeded.
  static const Duration _supabaseDeleteTimeout = Duration(seconds: 20);


  static const String schemaSql = '''
create table if not exists public.user_stats (
  id text primary key,
  username text not null default 'Username3189',
  gold integer not null default 0,
  xp integer not null default 0,
  literacy_points integer not null default 0,
  personality_type text not null default 'Spender',
  spending_habits jsonb not null default '{}'::jsonb,
  transaction_ledger jsonb not null default '[]'::jsonb,
  portfolio_history jsonb not null default '[]'::jsonb,
  holdings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now())
);

grant select, insert, update on table public.user_stats to authenticated;

alter table public.user_stats enable row level security;

-- Self-declared under-13 accounts (spending_habits.age_band = 'under_13')
-- never appear on the leaderboard — a privacy-protective default, not a
-- setting, since none of the profile-picture/username fields the view
-- exposes should surface a young kid's account publicly. Accounts with no
-- declared age band (age is optional at signup) still appear.
create or replace view public.leaderboard as
select
  id,
  username,
  literacy_points,
  xp,
  gold,
  spending_habits->>'profile_image_url' as profile_image_url,
  updated_at
from public.user_stats
where coalesce(spending_habits->>'age_band', '') <> 'under_13';

grant select on table public.leaderboard to authenticated;

do \$\$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_stats'
      and policyname = 'Users can read their own stats'
  ) then
    create policy "Users can read their own stats"
      on public.user_stats
      for select
      to authenticated
      using (id::text = (select auth.uid())::text);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_stats'
      and policyname = 'Users can create their own stats'
  ) then
    create policy "Users can create their own stats"
      on public.user_stats
      for insert
      to authenticated
      with check (id::text = (select auth.uid())::text);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_stats'
      and policyname = 'Users can update their own stats'
  ) then
    create policy "Users can update their own stats"
      on public.user_stats
      for update
      to authenticated
      using (id::text = (select auth.uid())::text)
      with check (id::text = (select auth.uid())::text);
  end if;
end
\$\$;

-- Friendships for the eco-impact "Friends" leaderboard. A row is a directed
-- edge "user_id added friend_id" — adding a code only ever inserts YOUR own
-- row (RLS below only allows inserting where you're `user_id`), so a
-- friendship reads as mutual once both sides have added each other's code.
-- `friend code` needs no new column: it's derived client-side as the first
-- 8 characters of the user's uuid, uppercased, then resolved back to an id
-- by matching against the already-broadly-readable `leaderboard` view.
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, friend_id)
);

-- `delete` as well as insert: a friends list you cannot leave is not a
-- friends list. No `update` on purpose — nothing about an edge can change,
-- and withholding it means a stray upsert fails loudly instead of quietly
-- rewriting someone else's row.
grant select, insert, delete on table public.friendships to authenticated;

alter table public.friendships enable row level security;

do \$\$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'friendships'
      and policyname = 'Users can read friendships they are part of'
  ) then
    create policy "Users can read friendships they are part of"
      on public.friendships
      for select
      to authenticated
      using (user_id = (select auth.uid()) or friend_id = (select auth.uid()));
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'friendships'
      and policyname = 'Users can only add friends as themselves'
  ) then
    create policy "Users can only add friends as themselves"
      on public.friendships
      for insert
      to authenticated
      with check (user_id = (select auth.uid()));
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'friendships'
      and policyname = 'Users can remove their own friendships'
  ) then
    create policy "Users can remove their own friendships"
      on public.friendships
      for delete
      to authenticated
      using (user_id = (select auth.uid()));
  end if;
end
\$\$;

-- The leaderboard view must NOT be security_invoker.
--
-- `user_stats` RLS restricts SELECT to your own row, which is correct for the
-- table and fatal for the view: with `security_invoker = true` the view
-- inherits the caller's RLS and every player sees a leaderboard containing
-- exactly themselves — and, worse for the friends feature, resolving a friend
-- code returns "No player found with that code" every single time, because
-- the lookup scans a view that can only ever contain the person doing the
-- looking.
--
-- Views default to running as their owner, so this is the state Supabase
-- creates. It is stated explicitly because Supabase's own database linter
-- flags owner-run views and the one-click "fix" is to set security_invoker,
-- which would silently break friends and the global leaderboard together.
alter view public.leaderboard set (security_invoker = false);
''';

  final StreamController<UserStats> _localController =
      StreamController<UserStats>.broadcast();
  final Map<String, UserStats> _memoryCache = <String, UserStats>{};

  SharedPreferences? _preferences;
  bool _isReady = false;
  bool _isSupabaseConnected = false;

  bool get isSupabaseConnected => _isSupabaseConnected;
  User? get currentUser => _existingClient?.auth.currentUser;
  String? get currentUserId => currentUser?.id;

  /// The raw client, for the rare screen (e.g. Admin) that needs to run its
  /// own queries directly. Null — never throws — when Supabase was never
  /// initialized (no keys configured), same as every other accessor here.
  SupabaseClient? get client => _existingClient;

  Stream<AuthState> authStateChanges() async* {
    final client = _existingClient;
    if (client == null) {
      return;
    }
    yield* client.auth.onAuthStateChange;
  }

  Future<bool> isCurrentUserDisabled() async {
    final client = _existingClient;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return false;
    }

    try {
      final response = await client
          .from('profiles')
          .select('disabled')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(_supabaseReadTimeout);

      return response?['disabled'] == true;
    } catch (error) {
      debugPrint(
        'Supabase disabled lookup failed, allowing cached app: $error',
      );
      return false;
    }
  }

  late final String _profileImageBucket;

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
    String? profileImageBucket,
  }) async {
    if (_isReady) {
      return;
    }

    _isReady = true;
    _preferences = await SharedPreferences.getInstance();
    _profileImageBucket = profileImageBucket?.trim().isNotEmpty == true
        ? profileImageBucket!.trim()
        : defaultProfileImageBucket;

    final existingClient = _existingClient;
    if (existingClient != null) {
      _isSupabaseConnected = true;
      return;
    }

    final hasKeys =
        supabaseUrl.trim().isNotEmpty &&
        !supabaseUrl.contains('YOUR-PROJECT') &&
        supabaseAnonKey.trim().isNotEmpty &&
        !supabaseAnonKey.contains('YOUR_SUPABASE');

    if (!hasKeys) {
      _isSupabaseConnected = false;
      return;
    }

    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      _isSupabaseConnected = true;
    } catch (error) {
      debugPrint('Supabase init failed, using cached data: $error');
      _isSupabaseConnected = false;
    }
  }

          .maybeSingle()
          .timeout(_supabaseReadTimeout);
            .maybeSingle()
            .timeout(_supabaseReadTimeout);
          .from(userStatsTable)
          .select('spending_habits')
          .maybeSingle()
          .timeout(_supabaseReadTimeout);
      final habits = _readMap(response?['spending_habits']);
      avatarUrl = _readString(habits['profile_image_url']) ?? avatarUrl;
      debugPrint('Supabase user stats avatar lookup failed: $error');
    return CurrentUserProfile(role: role, avatarUrl: avatarUrl);
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
    String? captchaToken,
  }) async {
    final client = _requireClient();
    return client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: <String, dynamic>{
        if (username != null && username.trim().isNotEmpty)
          'username': username.trim(),
      },
      captchaToken: captchaToken,
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final client = _requireClient();
    return client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<void> resetPasswordForEmail(
    String email, {
    String? captchaToken,
  }) async {
    final client = _requireClient();
    // Supabase has captcha protection enabled project-wide, so the reset
    // request is rejected with captcha_failed unless a token is included.
    //
    // `redirectTo` is where the emailed link sends the user back to. It must
    // also be listed under Authentication → URL Configuration → Redirect URLs
    // in the Supabase dashboard, or Supabase silently falls back to the
    // project's Site URL and the app never sees the recovery session.
    await client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      captchaToken: captchaToken,
      redirectTo: passwordResetRedirectUrl,
    );
  }

  /// Sets a new password for the currently-signed-in user.
  ///
  /// After the player taps the emailed recovery link, Supabase signs them in
  /// with a short-lived recovery session — this is the call that actually
  /// changes the password on that session. Without it the whole reset flow
  /// dead-ends: the email arrives, the link signs you in, and there is no way
  /// to pick a new password.
  Future<void> updatePassword(String newPassword) async {
    final client = _requireClient();
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Deletes the signed-in account: their rows, then their auth record.
  ///
  /// **Why an RPC rather than a pile of `.delete()` calls here.** Removing an
  /// `auth.users` row needs the service-role key, and a mobile app cannot
  /// hold one -- anything shipped to a device is readable by whoever has the
  /// device, and that key is every account in the project rather than just
  /// this one. So the delete has to run server-side. See
  /// `supabase/migrations/0003_account_deletion.sql`, which is also where the
  /// rest of the reasoning lives.
  ///
  /// Returns null on success, or a sentence to show the player. It never
  /// throws: this is called from a screen where the user has already
  /// confirmed twice, and an unhandled exception there would leave them
  /// looking at a dialog with no idea whether it worked.
  Future<String?> deleteOwnAccount() async {
    if (!_isSupabaseConnected) {
      return 'You need to be online to delete your account.';
    }
    final client = _existingClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return 'You are not signed in.';
    }
    try {
      await client
          .rpc<void>('delete_own_account')
          .timeout(_supabaseDeleteTimeout);
    } catch (error) {
      debugPrint('Supabase account deletion failed: $error');
      // 42883 is undefined_function -- the migration has not been run against
      // this project yet. Worth its own message, because the fix is one SQL
      // file and the generic "try again" would send somebody hunting for a
      // network problem that is not there.
      final text = error.toString();
      if (text.contains('42883') || text.contains('delete_own_account')) {
        return 'Account deletion is not set up on the server yet. '
            'Email us and we will remove it by hand.';
      }
      return 'Could not delete your account. Check your connection and '
          'try again.';
    }
    // Local state goes regardless of what the server said, because the
    // account it belonged to is gone.
    await clearCachedUserStats(userId: userId);
    try {
      await client.auth.signOut();
    } catch (_) {
      // The session is already invalid once the user row is deleted; failing
      // to sign out of a dead session is not something to report.
    }
    return null;
  }

  Future<void> signOut({String? userId}) async {
    await clearCachedUserStats(userId: userId);
    final client = _existingClient;
    if (client == null) {
      return;
    }
    await client.auth.signOut();
  }

  Future<String?> uploadProfileAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    if (!_isSupabaseConnected) {
      return null;
    }

    final normalizedExtension = fileExtension
        .replaceAll('.', '')
        .trim()
        .toLowerCase();
    final safeExtension = normalizedExtension.isEmpty
        ? 'jpg'
        : normalizedExtension;
    final storagePath =
        'avatars/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    try {
      await Supabase.instance.client.storage
          .from(_profileImageBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeForExtension(safeExtension),
            ),
          );
    } catch (error) {
      final message = error.toString();
      debugPrint('Supabase storage upload failed: $message');
      rethrow;
    }

    return Supabase.instance.client.storage
        .from(_profileImageBucket)
        .getPublicUrl(storagePath);
  }

  Future<void> updateProfileAvatarUrl({
    required String userId,
    required String avatarUrl,
  }) async {
    if (!_isSupabaseConnected) {
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from(userStatsTable)
          .select('spending_habits')
          .eq('id', userId)
          .maybeSingle()
          .timeout(_supabaseReadTimeout);
      final currentHabits = _readMap(response?['spending_habits']);
      await Supabase.instance.client
          .from(userStatsTable)
          .update(<String, dynamic>{
            'spending_habits': <String, dynamic>{
              ...currentHabits,
              'profile_image_url': avatarUrl,
            },
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } catch (error) {
      debugPrint('Supabase profile image URL update failed: $error');
    }
  }

  /// Sends a piece of user feedback to the `app_feedback` table.
  ///
  /// Always writes a local copy first so nothing is lost if the device is
  /// offline or Supabase isn't configured — matching the rest of this
  /// service's "degrade gracefully" behaviour rather than failing the whole
  /// submission when only the network leg is unavailable.
  Future<bool> submitFeedback({
    required String category,
    required String message,
    String? userId,
    String? userEmail,
  }) async {
    final prefs = await _ensurePreferences();
    final entry = <String, dynamic>{
      'category': category,
      'message': message,
      'user_id': userId,
      'user_email': userEmail,
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    };

    final queued = prefs.getStringList('pending_feedback_queue') ?? <String>[];
    queued.add(jsonEncode(entry));
    await prefs.setStringList('pending_feedback_queue', queued);

    if (!_isSupabaseConnected) {
      return false;
    }

    try {
      await Supabase.instance.client
          .from(feedbackTable)
          .insert(entry)
          .timeout(_supabaseReadTimeout);
      queued.remove(jsonEncode(entry));
      await prefs.setStringList('pending_feedback_queue', queued);
      return true;
    } catch (error) {
      debugPrint('Supabase feedback submit failed, queued locally: $error');
      return false;
    }
  }

  Future<UserStats> loadUserStats(String userId) async {
    await _ensurePreferences();
    final cached = await _readCachedUserStats(userId);
    final fallback = cached ?? UserStats.defaults(userId);
    _memoryCache[userId] = fallback;

    if (!_isSupabaseConnected) {
      return fallback;
    }

    try {
      final response = await Supabase.instance.client
          .from(userStatsTable)
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(_supabaseReadTimeout);

      if (response == null) {
        await saveUserStats(fallback);
        return fallback;
      }

      final stats = UserStats.fromMap(response);
      final current = _memoryCache[userId] ?? fallback;
      if (stats.updatedAt.isBefore(current.updatedAt)) {
        return current;
      }
      await _cacheUserStats(stats);
      _memoryCache[userId] = stats;
      return stats;
    } catch (error) {
      debugPrint('Supabase fetch failed, using cached data: $error');
      return fallback;
    }
  }

  Future<UserStats> loadCachedUserStatsForUser({
    required User user,
    String? preferredUsername,
  }) async {
    await _ensurePreferences();
    final userId = user.id;
    final cached = _memoryCache[userId] ?? await _readCachedUserStats(userId);
    if (cached != null) {
      _memoryCache[userId] = cached;
      return cached;
    }

    final email = user.email?.trim().toLowerCase();
    final defaultTemplate = UserStats.defaults(userId);
    final defaultStats = defaultTemplate.copyWith(
      username: _resolveUsername(user, preferredUsername),
      spendingHabits: <String, dynamic>{
        ...defaultTemplate.spendingHabits,
        'username': _resolveUsername(user, preferredUsername),
        if (email != null) 'email': email,
      },
      updatedAt: DateTime.now().toUtc(),
    );
    _memoryCache[userId] = defaultStats;
    await _cacheUserStats(defaultStats);
    return defaultStats;
  }

  Future<ProvisionedUserStats> loadOrCreateUserStatsForUser({
    required User user,
    String? preferredUsername,
  }) async {
    final userId = user.id;
    final email = user.email?.trim().toLowerCase();
    final resolvedUsername = _resolveUsername(user, preferredUsername);

    final existingStats = await _fetchUserStats(userId);
    if (existingStats != null) {
      final needsProfileRefresh =
          existingStats.username != resolvedUsername ||
          existingStats.spendingHabits['email'] != email;
      if (!needsProfileRefresh) {
        return ProvisionedUserStats(
          stats: existingStats,
          syncState: const SyncState(
            synced: true,
            usedCache: false,
            message: 'Loaded your profile.',
          ),
          createdProfile: false,
          migratedLegacyProfile: false,
        );
      }

      final refreshedStats = existingStats.copyWith(
        username: resolvedUsername,
        spendingHabits: <String, dynamic>{
          ...existingStats.spendingHabits,
          'username': resolvedUsername,
          if (email != null) 'email': email,
        },
        updatedAt: DateTime.now().toUtc(),
      );
      final syncState = await saveUserStats(refreshedStats);
      return ProvisionedUserStats(
        stats: refreshedStats,
        syncState: syncState,
        createdProfile: false,
        migratedLegacyProfile: false,
      );
    }

    final legacyStats = await _loadLegacyStats(email);
    if (legacyStats != null) {
      final migratedStats = legacyStats.copyWith(
        id: userId,
        username: resolvedUsername,
        spendingHabits: <String, dynamic>{
          ...legacyStats.spendingHabits,
          'username': resolvedUsername,
          if (email != null) 'email': email,
        },
        updatedAt: DateTime.now().toUtc(),
      );
      final syncState = await saveUserStats(migratedStats);
      return ProvisionedUserStats(
        stats: migratedStats,
        syncState: syncState,
        createdProfile: false,
        migratedLegacyProfile: true,
      );
    }

    final defaultTemplate = UserStats.defaults(userId);
    final defaultStats = defaultTemplate.copyWith(
      username: resolvedUsername,
      spendingHabits: <String, dynamic>{
        ...defaultTemplate.spendingHabits,
        'username': resolvedUsername,
        if (email != null) 'email': email,
      },
      updatedAt: DateTime.now().toUtc(),
    );
    final syncState = await saveUserStats(defaultStats);
    return ProvisionedUserStats(
      stats: defaultStats,
      syncState: syncState,
      createdProfile: true,
      migratedLegacyProfile: false,
    );
  }

  Stream<UserStats> watchUserStats(String userId) async* {
    final cached = _memoryCache[userId] ?? await _readCachedUserStats(userId);
    if (cached != null) {
      yield cached;
    }

    if (_isSupabaseConnected) {
      yield* Supabase.instance.client
          .from(userStatsTable)
          .stream(primaryKey: const ['id'])
          .eq('id', userId)
          .asyncMap((rows) async {
            if (rows.isEmpty) {
              final fallback =
                  _memoryCache[userId] ?? UserStats.defaults(userId);
              return fallback;
            }

            final incoming = UserStats.fromMap(rows.first);
            final current = _memoryCache[userId];
            if (current != null &&
                incoming.updatedAt.isBefore(current.updatedAt)) {
              return current;
            }
            _memoryCache[userId] = incoming;
            await _cacheUserStats(incoming);
            return incoming;
          });
      return;
    }

    yield* _localController.stream.where((stats) => stats.id == userId);
  }

  Future<SyncState> saveUserStats(UserStats stats) async {
    await _ensurePreferences();
    final current =
        _memoryCache[stats.id] ?? await _readCachedUserStats(stats.id);
    if (current != null && stats.updatedAt.isBefore(current.updatedAt)) {
      _localController.add(current);
      return const SyncState(
        synced: true,
        usedCache: true,
        message: 'Your account is already up to date.',
      );
    }

    _memoryCache[stats.id] = stats;
    await _cacheUserStats(stats);
    _localController.add(stats);

    if (!_isSupabaseConnected) {
      return const SyncState(
        synced: false,
        usedCache: true,
        message: 'Saved on this device.',
      );
    }

    try {
      await Supabase.instance.client
          .from(userStatsTable)
          .upsert(stats.toStorageMap(), onConflict: 'id');
      return const SyncState(
        synced: true,
        usedCache: false,
        message: 'Added to your account.',
      );
    } catch (error) {
      debugPrint('Supabase upsert failed, keeping cached data: $error');
      return const SyncState(
        synced: false,
        usedCache: true,
        message: 'Saved on this device — it will reach your account shortly.',
      );
    }
  }

  Future<void> clearCachedUserStats({String? userId}) async {
    final preferences = await _ensurePreferences();
    if (userId != null && userId.trim().isNotEmpty) {
      await preferences.remove(_cacheKey(userId));
      _memoryCache.remove(userId);
      _localController.add(UserStats.defaults(userId));
      return;
    }

    final keysToRemove = preferences
        .getKeys()
        .where((key) => key.startsWith('budget_buddy_user_stats_'))
        .toList(growable: false);
    for (final key in keysToRemove) {
      await preferences.remove(key);
    }
    _memoryCache.clear();
  }

  Future<void> _cacheUserStats(UserStats stats) async {
    final preferences = await _ensurePreferences();
    await preferences.setString(
      _cacheKey(stats.id),
      jsonEncode(stats.toStorageMap()),
    );
  }

  Future<UserStats?> _readCachedUserStats(String userId) async {
    final preferences = await _ensurePreferences();
    final rawJson = preferences.getString(_cacheKey(userId));
    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return UserStats.fromMap(decoded);
      }
      if (decoded is Map) {
        return UserStats.fromMap(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (error) {
      debugPrint('Failed to read cached user stats: $error');
    }

    return null;
  }

  Future<UserStats?> _fetchUserStats(String userId) async {
    final cached = _memoryCache[userId] ?? await _readCachedUserStats(userId);
    if (!_isSupabaseConnected) {
      return cached;
    }

    try {
      final response = await Supabase.instance.client
          .from(userStatsTable)
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(_supabaseReadTimeout);

      if (response == null) {
        return cached;
      }

      final stats = UserStats.fromMap(response);
      _memoryCache[userId] = stats;
      await _cacheUserStats(stats);
      return stats;
    } catch (error) {
      debugPrint('Supabase profile lookup failed, using cached data: $error');
      return cached;
    }
  }

  Future<UserStats?> _loadLegacyStats(String? email) async {
    if (email == null || email.isEmpty) {
      return null;
    }
    final legacyId = legacyUserIdFromEmail(email);
    return _fetchUserStats(legacyId);
  }

  String _resolveUsername(User user, String? preferredUsername) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final metadataUsername = (metadata['username'] ?? metadata['display_name'])
        ?.toString()
        .trim();
    if (preferredUsername != null && preferredUsername.trim().isNotEmpty) {
      return preferredUsername.trim();
    }
    if (metadataUsername != null && metadataUsername.isNotEmpty) {
      return metadataUsername;
    }
    final email = user.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      return displayNameFromEmail(email);
    }
    return 'Finance Wizard';
  }

  static String legacyUserIdFromEmail(String email) {
    final safe = email.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '_',
    );
    return 'user_$safe';
  }

  static String displayNameFromEmail(String email) {
    final handle = email.split('@').first.trim();
    if (handle.isEmpty) {
      return 'Finance Wizard';
    }
    final cleaned = handle.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ').trim();
    final words = cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .toList(growable: false);
    if (words.isEmpty) {
      return 'Finance Wizard';
    }
    return words.join(' ');
  }

  String _cacheKey(String userId) => 'budget_buddy_user_stats_$userId';

  Future<List<LeaderboardEntry>> fetchLeaderboard({
    int limit = 100,
    String? currentUserId,
    // A separate server-ordered query rather than re-sorting the
    // literacy-ranked page client-side: the top 100 by literacy points can
    // easily exclude someone who is actually top-100 by gold, so re-sorting
    // the wrong page in Dart would just hide them.
    LeaderboardMetric metric = LeaderboardMetric.literacy,
  }) async {
    await _ensurePreferences();
    final normalizedLimit = limit.clamp(1, 100);

    if (!_isSupabaseConnected) {
      return _buildCachedLeaderboard(
        limit: normalizedLimit,
        currentUserId: currentUserId,
        metric: metric,
      );
    }

    try {
      var query = Supabase.instance.client
          .from(leaderboardView)
          .select('*')
          .order(metric.orderColumns.first, ascending: false);
      for (final column in metric.orderColumns.skip(1)) {
        query = query.order(column, ascending: false);
      }
      final response = await query
          .limit(normalizedLimit)
          .timeout(_supabaseReadTimeout);

      if (response.isEmpty) {
        return _buildCachedLeaderboard(
          limit: normalizedLimit,
          currentUserId: currentUserId,
          metric: metric,
        );
      }

      return response
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false)
          .asMap()
          .entries
          .map(
            (entry) => _leaderboardEntryFrom(
              entry.value,
              entry.key,
              isCurrentUser:
                  currentUserId != null && currentUserId == entry.value['id'],
            ),
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('Supabase leaderboard failed, using cached data: $error');
      return _buildCachedLeaderboard(
        limit: normalizedLimit,
        currentUserId: currentUserId,
      );
    }
  }

  /// Friendship is a directed edge ("I added them"); this reads *either*
  /// direction as a friend, so the list fills in once both sides have added
  /// each other's code. Offline or with no friends yet, returns an empty
  /// list rather than falling back to cached data — there's no local cache
  /// of *other* users' stats to fall back to.
  /// Whether [id] is a real Supabase auth id rather than the local
  /// placeholder.
  ///
  /// `UserStatsController` starts every session as `'user_123'` — a local
  /// stand-in so the app has somewhere to keep progress before anybody signs
  /// in. Postgres columns that reference `auth.users` are `uuid`, so handing
  /// it that string is not an empty result, it is a **22P02 syntax error**:
  ///
  ///     invalid input syntax for type uuid: "user_123"
  ///
  /// which was firing on every cold start and filling the device log.
  static bool isRealUserId(String? id) {
    if (id == null || id.isEmpty || id == 'user_123') return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  Future<List<LeaderboardEntry>> fetchFriendsLeaderboard({
    required String currentUserId,
    LeaderboardMetric metric = LeaderboardMetric.literacy,
  }) async {
    // Signed out: there are no friends to fetch, and asking would be a
    // guaranteed 22P02 rather than an empty list.
    if (!_isSupabaseConnected || !isRealUserId(currentUserId)) {
      return const <LeaderboardEntry>[];
    }
    try {
      final client = Supabase.instance.client;
      final edges = await client
          .from(friendshipsTable)
          .select('user_id, friend_id')
          .or('user_id.eq.$currentUserId,friend_id.eq.$currentUserId')
          .timeout(_supabaseReadTimeout);

      final friendIds = <String>{};
      for (final row in edges) {
        final userId = row['user_id']?.toString();
        final friendId = row['friend_id']?.toString();
        if (userId == currentUserId && friendId != null) {
          friendIds.add(friendId);
        }
        if (friendId == currentUserId && userId != null) {
          friendIds.add(userId);
        }
      }
      // No friends is a different screen, not an empty ranking. The board
      // says "ranked among friends who've added your code", and answering
      // that with a list of one — you — reads as a bug rather than an
      // invitation.
      if (friendIds.isEmpty) {
        return const <LeaderboardEntry>[];
      }

      // **You are in your own friends ranking.**
      //
      // This was the bug: the query asked only for the friend ids, so the
      // signed-in player was the one person guaranteed to be missing from a
      // board about them. On an account with one friend it produced a podium
      // with a winner and two blank plinths, and no way to see where you
      // stood — which is the entire question a friends leaderboard exists to
      // answer.
      friendIds.add(currentUserId);

      var query = client
          .from(leaderboardView)
          .select('*')
          .inFilter('id', friendIds.toList())
          .order(metric.orderColumns.first, ascending: false);
      for (final column in metric.orderColumns.skip(1)) {
        query = query.order(column, ascending: false);
      }
      final response = await query.timeout(_supabaseReadTimeout);

      return response
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false)
          .asMap()
          .entries
          .map(
            (entry) => _leaderboardEntryFrom(
              entry.value,
              entry.key,
              // **This was hardcoded `false`**, on the one board that
              // deliberately puts you in it — `friendIds.add(currentUserId)`
              // is right above. So your own row was never marked as yours:
              // no "(you)", no highlight, and no fall back to your locally
              // stored photo when the view had not supplied one. You appeared
              // on your own friends podium as a stranger with a letter for a
              // face.
              isCurrentUser: entry.value['id'] == currentUserId,
            ),
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('Supabase friends leaderboard failed: $error');
      return const <LeaderboardEntry>[];
    }
  }

  /// Removes the edge this user owns, in both directions.
  ///
  /// Deletes `(me -> them)` and `(them -> me)`. The second looks wrong at
  /// first glance — that row belongs to the other person — but the RLS delete
  /// policy only ever lets you remove rows where you are `user_id`, so the
  /// second statement is a no-op unless *you* created it. Sending both is what
  /// makes "remove friend" mean the same thing regardless of who added whom,
  /// which is the only version a player would expect.
  Future<bool> removeFriend({
    required String currentUserId,
    required String friendId,
  }) async {
    if (!_isSupabaseConnected || !isRealUserId(currentUserId)) return false;
    try {
      final client = Supabase.instance.client;
      await client
          .from(friendshipsTable)
          .delete()
          .eq('user_id', currentUserId)
          .eq('friend_id', friendId)
          .timeout(_supabaseReadTimeout);
      await client
          .from(friendshipsTable)
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', currentUserId)
          .timeout(_supabaseReadTimeout);
      return true;
    } catch (error) {
      debugPrint('Supabase remove friend failed: $error');
      return false;
    }
  }

  /// Resolves [code] against [leaderboardView] and inserts a directed
  /// friendship edge from [currentUserId] to whoever matches. Returns a
  /// short human-readable result to show the user directly.
  Future<String> addFriendByCode({
    required String currentUserId,
    required String code,
  }) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return 'Enter a friend code first.';
    }
    if (!_isSupabaseConnected) {
      return 'Connect to the internet to add friends.';
    }
    if (!isRealUserId(currentUserId)) {
      return 'Sign in first, then you can add friends.';
    }
    // A friend code is the first 8 hex characters of the user's uuid, so
    // resolving one is a uuid *prefix* match. This used to be written as
    // `.ilike('id', '$trimmed%')`, which always failed against the live
    // database:
    //
    //     operator does not exist: uuid ~~* unknown
    //
    // `id` is a `uuid` column, and Postgres has no ILIKE operator for uuid
    // — so every single lookup threw, got swallowed by the catch below, and
    // surfaced as "Could not add that friend right now." The friends
    // feature had never worked, and the error message gave no hint why.
    //
    // uuid *does* have btree comparison operators, so a half-open range
    // expresses the same prefix match, works server-side, and stays
    // indexed. Using the all-`f` upper bound rather than incrementing the
    // prefix avoids an overflow edge case on the code `FFFFFFFF`.
    final prefix = trimmed.toLowerCase();
    if (prefix.length != 8 || !RegExp(r'^[0-9a-f]{8}$').hasMatch(prefix)) {
      return 'That code does not look right — codes are 8 characters.';
    }

    try {
      final client = Supabase.instance.client;
      final matches = await client
          .from(leaderboardView)
          .select('id, username')
          .gte('id', '$prefix-0000-0000-0000-000000000000')
          .lte('id', '$prefix-ffff-ffff-ffff-ffffffffffff')
          .limit(5)
          .timeout(_supabaseReadTimeout);

      final normalized = matches
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);

      Map<String, dynamic> match = const <String, dynamic>{};
      for (final row in normalized) {
        if (friendCodeFor((row['id'] ?? '').toString()) == trimmed) {
          match = row;
          break;
        }
      }

      final targetId = (match['id'] ?? '').toString();
      if (targetId.isEmpty) {
        return 'No player found with that code.';
      }
      if (targetId == currentUserId) {
        return "That's your own code!";
      }

      // `ignoreDuplicates`, not a plain upsert.
      //
      // The table grants `select, insert` and has no UPDATE policy — by
      // design, since nothing about an edge should ever change. A default
      // upsert resolves a conflict with an UPDATE, so adding a friend you had
      // already added failed with a permission error rather than doing
      // nothing. `ignoreDuplicates` sends `resolution=ignore-duplicates`,
      // which is `ON CONFLICT DO NOTHING` and needs only INSERT.
      await client
          .from(friendshipsTable)
          .upsert(
            <String, dynamic>{'user_id': currentUserId, 'friend_id': targetId},
            onConflict: 'user_id,friend_id',
            ignoreDuplicates: true,
          );

      return 'Added ${match['username'] ?? 'a new friend'}!';
    } on PostgrestException catch (error) {
      // Distinguished from a generic catch on purpose. A blanket
      // "Could not add that friend right now." is exactly what hid the
      // uuid/ILIKE bug above for as long as it did — the request was
      // failing every time with a precise, actionable Postgres error and
      // nobody could see it. Now the real code/message goes to the log,
      // and the two failures a player can actually do something about get
      // their own wording.
      debugPrint(
        'Supabase add friend failed [${error.code}]: ${error.message} '
        '${error.details ?? ''} ${error.hint ?? ''}',
      );
      if (error.code == '23503') {
        // FK violation: that uuid isn't a real auth user.
        return 'No player found with that code.';
      }
      if (error.code == '42P01') {
        return 'Friends are not set up on the server yet.';
      }
      if (error.code == '42501') {
        // The table exists and the row is refused: RLS is enabled with no
        // policy that accepts an insert. Verified against the live database,
        // where the message is "new row violates row-level security policy
        // for table friendships" rather than "permission denied for table",
        // which is the difference between a missing policy and a missing
        // grant.
        //
        // Worth its own sentence rather than a raw code, because the raw code
        // is what a player saw for months: it is not their fault, retrying
        // will never work, and somebody has to run
        // `supabase/migrations/0002_friendships_rls.sql`.
        //
        // The message names the *folder* rather than that one file. There are
        // two un-run migrations now (0003 adds account deletion), the number
        // will keep going up, and a message pinned to one filename goes stale
        // the moment another lands — which is worse than vague, because it
        // sends whoever reads it to run one file and stop.
        return 'Friends need a setup step on the server that has not been '
            'run yet — paste supabase/RUN_THIS_IN_SUPABASE.sql into the '
            'Supabase SQL editor.';
      }
      return 'Could not add that friend right now (${error.code ?? 'error'}).';
    } catch (error) {
      debugPrint('Supabase add friend failed: $error');
      return 'Could not add that friend right now.';
    }
  }

  Future<SharedPreferences> _ensurePreferences() async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }

  SupabaseClient _requireClient() {
    final client = _existingClient;
    if (client != null) {
      return client;
    }
    throw StateError(
      'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY before using authentication.',
    );
  }

  SupabaseClient? get _existingClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  List<LeaderboardEntry> _buildCachedLeaderboard({
    required int limit,
    String? currentUserId,
    LeaderboardMetric metric = LeaderboardMetric.literacy,
  }) {
    // The face travels with the row.
    //
    // These two fields used to be left at their defaults, so **every avatar
    // on the board vanished the moment it fell back to cache** — no network,
    // a query timeout, an empty response — and came back when the query
    // succeeded. That is what made it read as "pictures work on one tab and
    // not the others" rather than as an outage: the two tabs simply failed
    // over at different moments.
    final entries = _memoryCache.values
        .map(
          (stats) => LeaderboardEntry(
            id: stats.id,
            rank: 0,
            username: stats.username,
            literacyPoints: stats.literacyPoints,
            xp: stats.xp,
            gold: stats.gold,
            isCurrentUser: currentUserId != null && currentUserId == stats.id,
            profileImageUrl: stats.profileImageUrl,
            equippedSkin: stats.equippedSkin,
            rankedScore: stats.bestRankedScore,
            rankedGrade: stats.bestRankedGrade,
            rankedAge: stats.bestRankedAge,
          ),
        )
        .toList(growable: false);

    if (entries.isEmpty && currentUserId != null) {
      final stats = UserStats.defaults(currentUserId);
      return <LeaderboardEntry>[
        LeaderboardEntry(
          id: stats.id,
          rank: 1,
          username: stats.username,
          literacyPoints: stats.literacyPoints,
          xp: stats.xp,
          gold: stats.gold,
          isCurrentUser: true,
          profileImageUrl: stats.profileImageUrl,
          equippedSkin: stats.equippedSkin,
        ),
      ];
    }

    // The same ordering the live query uses, read off the same list of
    // columns. It used to be a hand-written comparator that duplicated the
    // query's `order()` chain — so an offline board could rank two players
    // differently from an online one, and nothing would ever have said so.
    int valueOf(LeaderboardEntry entry, String column) => switch (column) {
      'literacy_points' => entry.literacyPoints,
      'xp' => entry.xp,
      'gold' => entry.gold,
      'best_ranked_score' => entry.rankedScore,
      'best_ranked_age' => entry.rankedAge,
      _ => 0,
    };

    entries.sort((a, b) {
      for (final column in metric.orderColumns) {
        final compare = valueOf(b, column).compareTo(valueOf(a, column));
        if (compare != 0) return compare;
      }
      return 0;
    });

    return entries
        .take(limit)
        .toList(growable: false)
        .asMap()
        .entries
        .map(
          (entry) => LeaderboardEntry(
            id: entry.value.id,
            rank: entry.key + 1,
            username: entry.value.username,
            literacyPoints: entry.value.literacyPoints,
            xp: entry.value.xp,
            gold: entry.value.gold,
            isCurrentUser: entry.value.isCurrentUser,
          ),
        )
        .toList(growable: false);
  }
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

/// What the board is sorted by.
///
/// **This used to be `bool byGold`**, which is the shape that stops working
/// the moment there is a third thing to rank by — and Ranked is a third
/// thing. A boolean also cannot say what the *tie-breaks* are, so those lived
/// as two copy-pasted `order()` chains in the query and a third copy in the
/// cached sort, which is three places for them to disagree.
enum LeaderboardMetric {
  /// Literacy points: the app's own measure of learning. The default,
  /// because it is the one this app exists to move.
  literacy,

  /// Gold. Everything you have earned across every game.
  gold,

  /// Best Ranked life. One life, fixed rules, scored — see `ranked_run.dart`.
  ranked;

  /// Sort key first, then the tie-breaks, most significant first.
  ///
  /// Stated once and used by both the live query and the offline sort, so
  /// two players on the same numbers cannot be ordered differently depending
  /// on whether the network was up.
  List<String> get orderColumns => switch (this) {
    LeaderboardMetric.literacy => const ['literacy_points', 'xp', 'gold'],
    LeaderboardMetric.gold => const ['gold', 'literacy_points', 'xp'],
    // Ties on the score break toward the player who got there *later* in
    // life, because surviving longer for the same total is the harder run —
    // see `scoreRankedRun`, where survival is a multiplier for the same
    // reason.
    LeaderboardMetric.ranked => const [
      'best_ranked_score',
      'best_ranked_age',
      'literacy_points',
    ],
  };
}

/// One leaderboard row, whichever query produced it.
///
/// Factored out because the global board and the friends board built this
/// identically in two places, and the friend profile needs five more fields —
/// which would have been five more chances for the two copies to drift.
///
/// Everything past the original six is read defensively. The columns arrive
/// with `0005_leaderboard_profile.sql`, and until that migration is run the
/// keys are simply absent: `null` reads back as an empty string, a zero or a
/// null date, and the profile screen hides those sections. See the note on
/// [LeaderboardEntry] for why "works before the migration" is a requirement
/// here rather than a courtesy.
LeaderboardEntry _leaderboardEntryFrom(
  Map<String, dynamic> row,
  int index, {
  required bool isCurrentUser,
}) {
  return LeaderboardEntry(
    id: (row['id'] ?? '').toString(),
    rank: index + 1,
    username: (row['username'] ?? 'Finance Wizard').toString(),
    literacyPoints: _readInt(row['literacy_points']),
    xp: _readInt(row['xp']),
    gold: _readInt(row['gold']),
    isCurrentUser: isCurrentUser,
    profileImageUrl: (row['profile_image_url'] ?? '').toString(),
    equippedSkin: (row['equipped_skin'] ?? '').toString(),
    personalityType: (row['personality_type'] ?? '').toString(),
    lessonsCompleted: _readInt(row['lessons_completed']),
    dailyStreak: _readInt(row['daily_streak']),
    rankedScore: _readInt(row['best_ranked_score']),
    rankedGrade: (row['best_ranked_grade'] ?? '').toString(),
    rankedAge: _readInt(row['best_ranked_age']),
    updatedAt: DateTime.tryParse((row['updated_at'] ?? '').toString()),
  );
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _readDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
  return <String, dynamic>{};
}

Map<String, double> _readDoubleMap(dynamic value) {
  final map = _readMap(value);
  return map.map((key, mapValue) {
    final number = mapValue is num
        ? mapValue.toDouble()
        : double.tryParse('$mapValue') ?? 0;
    return MapEntry(key, number);
  });
}

List<LedgerTransaction> _readTransactions(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (item) => LedgerTransaction.fromJson(
            item.map((key, itemValue) => MapEntry(key.toString(), itemValue)),
          ),
        )
        .toList(growable: false);
  }
  return const <LedgerTransaction>[];
}

List<double> _readDoubleList(dynamic value) {
  if (value is List) {
    return value
        .map((entry) {
          if (entry is double) {
            return entry;
          }
          if (entry is num) {
            return entry.toDouble();
          }
          if (entry is String) {
            return double.tryParse(entry) ?? 0.0;
          }
          return 0.0;
        })
        .toList(growable: false);
  }
  return const <double>[];
}

String _contentTypeForExtension(String extension) {
  return switch (extension.toLowerCase()) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/jpeg',
  };
}
