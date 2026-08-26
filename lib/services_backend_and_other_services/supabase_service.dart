import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../models_Like_Skins_and_lessons_templates/life_record.dart';
import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../models_Like_Skins_and_lessons_templates/player_profile.dart';

/// Where the emailed password-reset link sends the player back to.
///
/// **This must also be allowlisted** in the Supabase dashboard under
/// Authentication → URL Configuration → Redirect URLs, otherwise Supabase
/// ignores it and falls back to the project's Site URL — the app then never
/// receives the recovery session and the reset silently dead-ends.
///
/// Web runs on the dev server's origin. Mobile needs a custom scheme, which
/// also has to be declared natively (Android: an intent-filter in
/// AndroidManifest.xml; iOS: CFBundleURLTypes in Info.plist) before the OS
/// will hand the link back to the app.
const String passwordResetRedirectUrl = kIsWeb
    ? 'http://localhost:5960/'
    : 'budgetbuddy://password-reset';

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
      gold: 999999,
      xp: 850,
      literacyPoints: 850,
      personalityType: 'Spender',
      spendingHabits: const <String, dynamic>{
        'risk_tolerance': 'balanced',
        'confidence_score': 2.0,
        'missed_questions': <String>[],
        'equipped_skin': 'classic_turtle',
        'unlocked_skins': <String>['classic_turtle'],
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

  String get equippedSkin {
    final value = spendingHabits['equipped_skin']?.toString().trim();
    if (value == null || value.isEmpty || !isRegisteredSkinId(value)) {
      return budgetBuddySkins.first.id;
    }
    return value;
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
      if (normalized.isNotEmpty) {
        if (!normalized.contains(budgetBuddySkins.first.id)) {
          return <String>[budgetBuddySkins.first.id, ...normalized];
        }
        return normalized;
      }
    }
    return <String>[budgetBuddySkins.first.id];
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
  // All read/written the same way as everything else above: ad hoc keys
  // inside `spendingHabits`, no migration. See
  // docs/MONEY_HABITS_FEATURE.md for the full data-flow reference.

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
        'unlocked_skins': unlockedSkins,
      },
      'transaction_ledger': transactions
          .map((transaction) => transaction.toJson())
          .toList(growable: false),
      'portfolio_history': portfolioHistory,
      'holdings': holdings,
      // NOTE: age/gender are deliberately NOT written here. They were briefly
      // mirrored into `age`/`gender` columns, but those columns live on
      // `profiles` (the table with `disabled` + `profiles_id_fkey`), not on
      // `user_stats` — so the upsert failed with "Could not find the 'age'
      // column of 'user_stats' in the schema cache" and every save silently
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
  });

  final String id;
  final int rank;
  final String username;
  final int literacyPoints;
  final int xp;
  final int gold;
  final bool isCurrentUser;
  final String profileImageUrl;

  String get scoreLabel => '$literacyPoints LP';
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

grant select, insert on table public.friendships to authenticated;

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
end
\$\$;
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
        message: 'Newer stats already saved.',
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
        message: 'Saved to Supabase.',
      );
    } catch (error) {
      debugPrint('Supabase upsert failed, keeping cached data: $error');
      return const SyncState(
        synced: false,
        usedCache: true,
        message: 'Saved locally. Cloud sync will resume automatically.',
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
    bool byGold = false,
  }) async {
    await _ensurePreferences();
    final normalizedLimit = limit.clamp(1, 100);

    if (!_isSupabaseConnected) {
      return _buildCachedLeaderboard(
        limit: normalizedLimit,
        currentUserId: currentUserId,
        byGold: byGold,
      );
    }

    try {
      final unordered = Supabase.instance.client
          .from(leaderboardView)
          .select('*');
      final response =
          await (byGold
                  ? unordered
                        .order('gold', ascending: false)
                        .order('literacy_points', ascending: false)
                        .order('xp', ascending: false)
                  : unordered
                        .order('literacy_points', ascending: false)
                        .order('xp', ascending: false)
                        .order('gold', ascending: false))
              .limit(normalizedLimit)
              .timeout(_supabaseReadTimeout);

      if (response.isEmpty) {
        return _buildCachedLeaderboard(
          limit: normalizedLimit,
          currentUserId: currentUserId,
          byGold: byGold,
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
            (entry) => LeaderboardEntry(
              id: (entry.value['id'] ?? '').toString(),
              rank: entry.key + 1,
              username: (entry.value['username'] ?? 'Finance Wizard')
                  .toString(),
              literacyPoints: _readInt(entry.value['literacy_points']),
              xp: _readInt(entry.value['xp']),
              gold: _readInt(entry.value['gold']),
              isCurrentUser:
                  currentUserId != null && currentUserId == entry.value['id'],
              // Present once the leaderboard view exposes it (see the SQL
              // in this file's schema comment); empty string until then.
              profileImageUrl: (entry.value['profile_image_url'] ?? '')
                  .toString(),
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
  Future<List<LeaderboardEntry>> fetchFriendsLeaderboard({
    required String currentUserId,
    bool byGold = false,
  }) async {
    if (!_isSupabaseConnected) {
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
      if (friendIds.isEmpty) {
        return const <LeaderboardEntry>[];
      }

      final unordered = client
          .from(leaderboardView)
          .select('*')
          .inFilter('id', friendIds.toList());
      final response =
          await (byGold
                  ? unordered
                        .order('gold', ascending: false)
                        .order('literacy_points', ascending: false)
                        .order('xp', ascending: false)
                  : unordered
                        .order('literacy_points', ascending: false)
                        .order('xp', ascending: false)
                        .order('gold', ascending: false))
              .timeout(_supabaseReadTimeout);

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
            (entry) => LeaderboardEntry(
              id: (entry.value['id'] ?? '').toString(),
              rank: entry.key + 1,
              username: (entry.value['username'] ?? 'Finance Wizard')
                  .toString(),
              literacyPoints: _readInt(entry.value['literacy_points']),
              xp: _readInt(entry.value['xp']),
              gold: _readInt(entry.value['gold']),
              isCurrentUser: false,
              profileImageUrl: (entry.value['profile_image_url'] ?? '')
                  .toString(),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('Supabase friends leaderboard failed: $error');
      return const <LeaderboardEntry>[];
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

      await client.from(friendshipsTable).upsert(<String, dynamic>{
        'user_id': currentUserId,
        'friend_id': targetId,
      }, onConflict: 'user_id,friend_id');

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
    bool byGold = false,
  }) {
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
        ),
      ];
    }

    entries.sort((a, b) {
      if (byGold) {
        final goldCompare = b.gold.compareTo(a.gold);
        if (goldCompare != 0) {
          return goldCompare;
        }
        return b.literacyPoints.compareTo(a.literacyPoints);
      }
      final literacyCompare = b.literacyPoints.compareTo(a.literacyPoints);
      if (literacyCompare != 0) {
        return literacyCompare;
      }
      final xpCompare = b.xp.compareTo(a.xp);
      if (xpCompare != 0) {
        return xpCompare;
      }
      return b.gold.compareTo(a.gold);
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
