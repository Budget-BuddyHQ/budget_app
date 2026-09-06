import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../models_Like_Skins_and_lessons_templates/life_record.dart';
import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../constants/privacy_policy.dart';
import '../models_Like_Skins_and_lessons_templates/player_profile.dart';
import '../services_backend_and_other_services/market_data_service.dart'
    show formatShares;
import '../services_backend_and_other_services/supabase_service.dart';

@immutable
class StatsActionResult {
  const StatsActionResult({
    required this.success,
    required this.message,
    required this.syncState,
    this.requiresEmailConfirmation = false,
  });

  final bool success;
  final String message;
  final SyncState syncState;
  final bool requiresEmailConfirmation;
}

@immutable
class SkinCaseResult extends StatsActionResult {
  const SkinCaseResult({
    required super.success,
    required super.message,
    required super.syncState,
    required this.skin,
    required this.isNewUnlock,
    required this.goldSpent,
  });

  final AvatarSkin skin;
  final bool isNewUnlock;
  final int goldSpent;
}

class UserStatsController extends ChangeNotifier {
  UserStatsController({
    required SupabaseService service,
    String initialUserId = 'user_123',
  }) : _service = service,
       _userId = initialUserId,
       _stats = UserStats.defaults(initialUserId);

  final SupabaseService _service;
  final Random _random = Random();

  String _userId;
  UserStats _stats;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;

  /// False once a save has failed to reach Supabase while signed in.
  ///
  /// `saveUserStats` catches every upsert error, writes to the local cache and
  /// returns `synced: false` — graceful, but completely silent. That is how a
  /// schema mismatch once broke *every* cloud save for a long stretch without
  /// producing a single visible symptom: progress kept saving locally, so
  /// nothing looked wrong until a player signed in on another device and found
  /// their account empty. This flag is what makes that state visible.
  bool _cloudSyncHealthy = true;
  DateTime? _lastCloudSyncFailure;
  StreamSubscription<UserStats>? _subscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  static const Duration _remoteSyncTimeout = Duration(seconds: 8);

  UserStats get stats => _stats;

  /// Test-only: swaps in a stats snapshot without touching the network or
  /// SharedPreferences. Age-band-dependent UI (the Academy's "older than you"
  /// warning, personalised worked examples) only renders once an age band is
  /// set, and the real setter goes through a save round-trip that a widget
  /// test can't complete — so without this seam those branches never run.
  @visibleForTesting
  void seedStatsForTest(UserStats stats) {
    _stats = stats;
    _isLoading = false;
    notifyListeners();
  }

  String get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get statusMessage => _statusMessage;

  /// True when the last save reached the server, or when there is no server to
  /// reach (signed out, or Supabase not configured) — in which case
  /// device-only saving is the expected behaviour, not a fault.
  bool get cloudSyncHealthy => _cloudSyncHealthy || !isAuthenticated;

  /// When cloud sync last failed, for the "last synced" line in the warning.
  DateTime? get lastCloudSyncFailure => _lastCloudSyncFailure;
  bool get isAuthenticated => _service.currentUser != null;
  List<AvatarSkin> get unlockedAvatarSkins {
    final unlockedSkinIds = _stats.unlockedSkins.toSet();
    return budgetBuddySkins
        .where((skin) => unlockedSkinIds.contains(skin.id))
        .toList(growable: false);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _isLoading = true;
    notifyListeners();

    await _syncWithCurrentUser();
    _authSubscription = _service.authStateChanges().listen((_) {
      unawaited(_syncWithCurrentUser());
    });
  }

  Future<void> refresh() async {
    if (!isAuthenticated) {
      await _resetToSignedOutState(notify: true);
      return;
    }

    _isLoading = true;
    notifyListeners();
    _stats = await _service.loadUserStats(_userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<StatsActionResult> signIn({
    required String email,
    required String password,
    String? username,
    bool isNewAccount = false,
    String? captchaToken,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      return const StatsActionResult(
        success: false,
        message: 'Enter your email and password first.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Missing credentials.',
        ),
      );
    }

    _isSaving = true;
    _statusMessage = isNewAccount
        ? 'Creating your Budget Buddy profile...'
        : 'Signing you in...';
    notifyListeners();

    try {
      if (isNewAccount) {
        final response = await _service.signUp(
          email: normalizedEmail,
          password: password,
          username: username,
          captchaToken: captchaToken,
        );
        final user = response.user;
        if (user == null) {
          return _authFailure(
            'That sign-up did not complete. Please try again.',
          );
        }

        if (response.session == null) {
          _isSaving = false;
          _statusMessage = 'Check your email to confirm your account.';
          notifyListeners();
          return const StatsActionResult(
            success: true,
            message:
                'Account created. Check your email to confirm your account before logging in.',
            syncState: SyncState(
              synced: true,
              usedCache: false,
              message: 'Awaiting email confirmation.',
            ),
            requiresEmailConfirmation: true,
          );
        }

        return await _finishAuthenticatedFlow(
          user,
          preferredUsername: username,
          successMessage: 'Account ready. You are signed in.',
        );
      }

      final response = await _service.signInWithPassword(
        email: normalizedEmail,
        password: password,
        captchaToken: captchaToken,
      );
      final user = response.user;
      if (user == null) {
        return _authFailure('That sign-in did not complete. Please try again.');
      }

        await client.auth.signOut();
      return await _finishAuthenticatedFlow(
        user,
        successMessage: 'Welcome back to Budget Buddy.',
      );
    } on AuthException catch (error) {
      return _authFailure(error.message);
    } on StateError catch (error) {
      return _authFailure(error.message);
    } catch (error) {
      return _authFailure('Authentication failed: $error');
    }
  }

  /// Sets a new password on the current (usually recovery) session.
  Future<StatsActionResult> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      return const StatsActionResult(
        success: false,
        message: 'Use at least 6 characters.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Password too short.',
        ),
      );
    }

    try {
      await _service.updatePassword(newPassword);
      return const StatsActionResult(
        success: true,
        message: 'Password updated. You are signed in.',
        syncState: SyncState(
          synced: true,
          usedCache: false,
          message: 'Password updated.',
        ),
      );
    } on AuthException catch (error) {
      return _authFailure(error.message);
    } on StateError catch (error) {
      return _authFailure(error.message);
    } catch (error) {
      return _authFailure('Could not update password: $error');
    }
  }

  Future<StatsActionResult> sendPasswordReset({
    required String email,
    String? captchaToken,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return const StatsActionResult(
        success: false,
        message: 'Enter your email so we know where to send the reset link.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Missing email address.',
        ),
      );
    }

    try {
      await _service.resetPasswordForEmail(
        normalizedEmail,
        captchaToken: captchaToken,
      );
      return const StatsActionResult(
        success: true,
        message: 'Password reset email sent. Check your inbox and spam folder.',
        syncState: SyncState(
          synced: true,
          usedCache: false,
          message: 'Reset email sent.',
        ),
      );
    } on AuthException catch (error) {
      return _authFailure(error.message);
    } on StateError catch (error) {
      return _authFailure(error.message);
    } catch (error) {
      return _authFailure('Password reset failed: $error');
    }
  }

  /// Records that this player accepted the current privacy policy.
  ///
  /// Written at the moment the account is created, from the checkbox the
  /// player actually ticked. Stamped with the version *and* the time, because
  /// "they agreed" is not a useful answer on its own -- the question is always
  /// which document, on what date.
  Future<StatsActionResult> recordPrivacyAcceptance() {
    final nextStats = _stats.copyWith(
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        PrivacyKeys.acceptedVersion: kPrivacyPolicyVersion,
        PrivacyKeys.acceptedAt: DateTime.now().toUtc().toIso8601String(),
      },
      updatedAt: DateTime.now().toUtc(),
    );
    return _saveStats(nextStats, savingMessage: 'Saving your choices...');
  }

  Future<void> signOut() async {
    final previousUserId = _userId;
    await _subscription?.cancel();
    _subscription = null;

    try {
      await _service.signOut(userId: previousUserId);
    } finally {
      await _resetToSignedOutState(notify: true, statusMessage: 'Logged out.');
    }
  }

  Future<StatsActionResult> updateOnboardingProfile({
    required String personalityType,
    required Map<String, dynamic> spendingHabits,
  }) async {
    final nextStats = _stats.copyWith(
      personalityType: personalityType,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        ...spendingHabits,
        'username': _stats.username,
      },
      updatedAt: DateTime.now().toUtc(),
    );
    return _saveStats(
      nextStats,
      savingMessage: 'Saving your wizard profile...',
    );
  }

  /// Saves the self-described age band and gender from onboarding or the
  /// profile editor. Passing null for either leaves that value untouched, so
  /// the profile screen can update one field at a time.
  Future<StatsActionResult> updatePersonalDetails({
    AgeBand? ageBand,
    GenderIdentity? gender,
  }) async {
    final nextStats = _stats.copyWith(
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        if (ageBand != null) ProfileKeys.ageBand: ageBand.id,
        if (gender != null) ProfileKeys.gender: gender.id,
        ProfileKeys.onboardingComplete: true,
      },
      updatedAt: DateTime.now().toUtc(),
    );

    return _saveStats(nextStats, savingMessage: 'Saving your profile...');
  }

  /// Records that a Life run reached [endingId], so the endings collection
  /// on the Adventure hub can show it as discovered. Idempotent — reaching
  /// the same ending twice is a no-op rather than a duplicate entry.
  Future<StatsActionResult> recordLifeEnding(String endingId) async {
    final existing = _stats.discoveredEndings;
    if (existing.contains(endingId)) {
      return StatsActionResult(
        success: true,
        message: 'Already discovered.',
        syncState: const SyncState(synced: true, usedCache: false, message: ''),
      );
    }

    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'discovered_endings': <String>[...existing, endingId],
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Saving your story...',
    );
  }

  /// Files a finished Life run in the player's history and reports which
  /// personal bests it beat.
  ///
  /// Returns the beaten categories rather than persisting them, because
  /// bests are derived from the history (see [LifeRecordBook]) — the caller
  /// wants them only to decorate the epilogue.
  ///
  /// Deliberately separate from [recordLifeEnding]: that one owns the
  /// "outcomes discovered" collection and is idempotent per ending, while
  /// every run belongs in the history even when its ending is a repeat.
  Future<Set<LifeBest>> recordLifeRun(LifeSummary summary) async {
    final book = _stats.lifeRecords;
    final record = LifeRecord.fromSummary(summary);
    // Judged against the book as it stands, so this must happen before add.
    final beaten = book.bestsBeaten(record);

    await _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'life_records': book.add(record).toJson(),
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Filing your life story...',
    );

    return beaten;
  }

  /// Marks badges as already celebrated so their unlock popup shows once.
  Future<StatsActionResult> markBadgesCelebrated(
    Iterable<String> badgeIds,
  ) async {
    final existing = _stats.celebratedBadges.toSet();
    final next = {...existing, ...badgeIds};
    if (next.length == existing.length) {
      return StatsActionResult(
        success: true,
        message: 'Already recorded.',
        syncState: const SyncState(synced: true, usedCache: false, message: ''),
      );
    }

    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'celebrated_badges': next.toList(growable: false),
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Saving achievements...',
    );
  }

  /// Persists daily-plan progress: which quests are done today, and the
  /// current streak. Called by DailyPlanController.
  Future<StatsActionResult> updateDailyPlanProgress({
    required String dateKey,
    required List<String> completedQuestIds,
    required int streak,
    required String streakDateKey,
  }) async {
    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'daily_plan_date': dateKey,
          'daily_quests_done': completedQuestIds,
          'daily_streak': streak,
          'daily_streak_date': streakDateKey,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Saving your daily progress...',
    );
  }

  // ---------------- Money Habits ----------------
  // See docs/MONEY_HABITS_FEATURE.md for the full data-flow reference.

  static const int _habitXpPerCompletion = 8;

  /// Pins a catalog habit to the Home weekly tracker, optionally with a
  /// saved adjustable-parameter value (e.g. "$5").
  Future<StatsActionResult> saveHabit(
    String habitId, {
    double? paramValue,
  }) async {
    final saved = <String>{..._stats.savedHabitIds, habitId}.toList();
    final params = <String, double>{..._stats.savedHabitParams};
    if (paramValue != null) {
      params[habitId] = paramValue;
    }
    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'saved_habit_ids': saved,
          'saved_habit_params': params,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Saving your habit...',
    );
  }

  /// Creates a user-authored habit and pins it to the weekly tracker.
  Future<StatsActionResult> createCustomHabit({
    required String title,
    required String blurb,
    required double moneySavedUsd,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedBlurb = blurb.trim();
    if (trimmedTitle.isEmpty || trimmedBlurb.isEmpty || moneySavedUsd <= 0) {
      return const StatsActionResult(
        success: false,
        message: 'Add a title, description, and savings amount first.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Missing custom habit details.',
        ),
      );
    }

    final id = '$customHabitIdPrefix${DateTime.now().microsecondsSinceEpoch}';
    final customHabits = <HabitTemplate>[
      ..._stats.customHabitTemplates,
      customHabitFromMap(<String, dynamic>{
        'id': id,
        'title': trimmedTitle,
        'blurb': trimmedBlurb,
        'money_saved_usd': moneySavedUsd,
      }),
    ];
    final saved = <String>{..._stats.savedHabitIds, id}.toList();

    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'custom_habits': customHabits
              .map(customHabitToMap)
              .toList(growable: false),
          'saved_habit_ids': saved,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Creating your habit...',
    );
  }

  /// Unpins a habit from the Home tracker. Past completions already logged
  /// in the weekly log/calendar are untouched — only future tracking stops.
  Future<StatsActionResult> unsaveHabit(String habitId) async {
    final saved = _stats.savedHabitIds
        .where((id) => id != habitId)
        .toList(growable: false);
    final params = <String, double>{..._stats.savedHabitParams}
      ..remove(habitId);
    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'saved_habit_ids': saved,
          'saved_habit_params': params,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Updating your habits...',
    );
  }

  /// Marks [template] complete for today (from either the Track tab or a
  /// Challenge). Updates the weekly log, the activity calendar, lifetime/
  /// monthly totals, the savings jar's habit XP, and its last-active date
  /// in one save — the same single-round-trip shape as
  /// [completeLessonProgress]. Pass [challengeTaskId] when this completion
  /// also finishes a Challenge node.
  Future<StatsActionResult> completeHabit(
    HabitTemplate template, {
    double? units,
    String? challengeTaskId,
  }) async {
    final today = HabitDateKeys.todayKey();
    final impact = template.impactFor(
      units ?? template.adjustable?.defaultValue ?? 1,
    );

    final weeklyLog = <String, List<String>>{..._stats.habitWeeklyLog};
    final todayHabits = <String>{
      ...(weeklyLog[today] ?? const <String>[]),
      template.id,
    };
    weeklyLog[today] = todayHabits.toList();
    final prunedWeekly = HabitDateKeys.pruneToTrailing(weeklyLog, 14);

    final calendar = <String, int>{..._stats.habitActivityCalendar};
    calendar[today] = (calendar[today] ?? 0) + 1;
    final prunedCalendar = HabitDateKeys.pruneToTrailing(calendar, 365);

    final totals = _stats.habitTotals + impact;
    final monthKey = today.substring(0, 7);
    final monthly = <String, HabitImpact>{..._stats.habitMonthly};
    monthly[monthKey] = (monthly[monthKey] ?? HabitImpact.zero) + impact;

    final completedChallengeTasks = challengeTaskId == null
        ? _stats.completedChallengeTasks
        : <String>{
            ..._stats.completedChallengeTasks,
            challengeTaskId,
          }.toList(growable: false);

    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'habit_xp': _stats.jarXp + _habitXpPerCompletion,
          'habit_totals': totals.toMap(),
          'habit_monthly': monthly.map(
            (key, value) => MapEntry(key, value.toMap()),
          ),
          'habit_weekly_log': prunedWeekly,
          'habit_activity_calendar': prunedCalendar,
          'completed_challenge_tasks': completedChallengeTasks,
          'jar_last_active': today,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Logging your habit...',
    );
  }

  /// Switches the avatar body. Purely cosmetic — never gates a skin, and
  /// every villager skin ships both bodies, so this costs nothing.
  Future<StatsActionResult> setVillagerBody(VillagerBody body) async {
    if (_stats.villagerBody == body) {
      return const StatsActionResult(
        success: true,
        message: 'Already using that look.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No change.',
        ),
      );
    }

    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          ProfileKeys.villagerBody: body.id,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Updating your look...',
    );
  }

  Future<StatsActionResult> buyIndexFund() async {
    const goldCost = 200;
    if (_stats.gold < goldCost) {
      return const StatsActionResult(
        success: false,
        message: 'You need 200 gold before buying another index fund.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    final holdings = Map<String, double>.from(_stats.holdings)
      ..update('indexFunds', (value) => value + 1, ifAbsent: () => 1);
    final now = DateTime.now().toUtc();

    final nextStats = _stats.copyWith(
      gold: _stats.gold - goldCost,
      xp: _stats.xp + 18,
      literacyPoints: _stats.literacyPoints + 8,
      holdings: holdings,
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Bought Index Fund',
          description: 'Invested 200 gold into your long-term portfolio.',
          amount: -goldCost,
          createdAt: now,
          category: 'invest',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(
      nextStats,
      savingMessage: 'Executing index fund purchase...',
    );
  }

  Future<StatsActionResult> sellStocks() async {
    final currentStockLots = _stats.holdings['stocks'] ?? 0.0;
    if (currentStockLots <= 0) {
      return const StatsActionResult(
        success: false,
        message: 'No stock lots are available to sell right now.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    const goldReturn = 140;
    final holdings = Map<String, double>.from(_stats.holdings)
      ..update('stocks', (value) => value > 0 ? value - 1 : 0.0);
    final now = DateTime.now().toUtc();

    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldReturn,
      xp: _stats.xp + 10,
      literacyPoints: _stats.literacyPoints + 4,
      holdings: holdings,
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Sold Stocks',
          description: 'Trimmed a volatile position for extra spending power.',
          amount: goldReturn,
          createdAt: now,
          category: 'invest',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Executing sell order...');
  }

  Future<StatsActionResult> buyStockLot({
    required String symbol,
    required int goldCost,
    String? companyName,
    double quantity = 1,
  }) async {
    if (_stats.gold < goldCost) {
      return StatsActionResult(
        success: false,
        message: 'You need $goldCost gold before buying $symbol.',
        syncState: const SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    final holdingKey = 'stock_$symbol';
    final holdings = Map<String, double>.from(_stats.holdings)
      ..update(
        holdingKey,
        (value) => value + quantity,
        ifAbsent: () => quantity,
      )
      ..update('stocks', (value) => value + quantity, ifAbsent: () => quantity);

    final existingCostBasis = Map<String, int>.from(
      (_stats.spendingHabits['cost_basis'] as Map?)?.cast<String, int>() ?? {},
    );
    existingCostBasis[holdingKey] =
        (existingCostBasis[holdingKey] ?? 0) + goldCost;

    final now = DateTime.now().toUtc();
    final label = companyName?.trim().isNotEmpty == true
        ? companyName!
        : symbol;

    final nextStats = _stats.copyWith(
      gold: _stats.gold - goldCost,
      xp: _stats.xp + (14 * quantity).round(),
      literacyPoints: _stats.literacyPoints + (7 * quantity).round(),
      holdings: holdings,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'cost_basis': existingCostBasis,
      },
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Bought $symbol',
          description:
              'Opened ${formatShares(quantity)} share(s) of $label for $goldCost gold.',
          amount: -goldCost,
          createdAt: now,
          category: 'invest',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Buying $symbol...');
  }

  Future<StatsActionResult> sellStockLot({
    required String symbol,
    required int goldReturn,
    String? companyName,
    double quantity = 1,
  }) async {
    final holdingKey = 'stock_$symbol';
    final currentLots = _stats.holdings[holdingKey] ?? 0.0;
    if (currentLots < quantity) {
      return StatsActionResult(
        success: false,
        message: 'No $symbol lots are available to sell right now.',
        syncState: const SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    final holdings = Map<String, double>.from(_stats.holdings)
      ..update(holdingKey, (value) => value > quantity ? value - quantity : 0.0)
      ..update(
        'stocks',
        (value) => value > quantity ? value - quantity : 0.0,
        ifAbsent: () => 0.0,
      );
    if ((holdings[holdingKey] ?? 0) <= 0) {
      holdings.remove(holdingKey);
    }
    if ((holdings['stocks'] ?? 0) <= 0) {
      holdings.remove('stocks');
    }

    final existingCostBasis = Map<String, int>.from(
      (_stats.spendingHabits['cost_basis'] as Map?)?.cast<String, int>() ?? {},
    );
    final currentCost = existingCostBasis[holdingKey] ?? 0;
    if (currentLots > 0 && currentCost > 0) {
      final costPerShare = currentCost / currentLots;
      final reducedCost = (costPerShare * quantity).round();
      existingCostBasis[holdingKey] = max(0, currentCost - reducedCost);
    }
    if ((holdings[holdingKey] ?? 0) <= 0) {
      existingCostBasis.remove(holdingKey);
    }

    final now = DateTime.now().toUtc();
    final label = companyName?.trim().isNotEmpty == true
        ? companyName!
        : symbol;

    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldReturn,
      xp: _stats.xp + (10 * quantity).round(),
      literacyPoints: _stats.literacyPoints + (5 * quantity).round(),
      holdings: holdings,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'cost_basis': existingCostBasis,
      },
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Sold $symbol',
          description:
              'Closed ${formatShares(quantity)} share(s) of $label for $goldReturn gold.',
          amount: goldReturn,
          createdAt: now,
          category: 'invest',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Selling $symbol...');
  }

  Future<StatsActionResult> shortStockLot({
    required String symbol,
    required int goldCredit,
    String? companyName,
    double quantity = 1,
  }) async {
    if (quantity <= 0) {
      return const StatsActionResult(
        success: false,
        message: 'Enter a positive quantity to short.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    final holdingKey = 'stock_$symbol';
    final holdings = Map<String, double>.from(_stats.holdings);
    final currentLots = holdings[holdingKey] ?? 0.0;
    final nextLots = currentLots - quantity;
    holdings[holdingKey] = nextLots;
    holdings['stocks'] = (holdings['stocks'] ?? 0.0) - quantity;
    if (nextLots == 0) {
      holdings.remove(holdingKey);
    }
    if ((holdings['stocks'] ?? 0.0) == 0) {
      holdings.remove('stocks');
    }

    final existingCostBasis = Map<String, int>.from(
      (_stats.spendingHabits['cost_basis'] as Map?)?.cast<String, int>() ?? {},
    );
    existingCostBasis[holdingKey] =
        (existingCostBasis[holdingKey] ?? 0) - goldCredit;
    if (nextLots == 0) {
      existingCostBasis.remove(holdingKey);
    }

    final now = DateTime.now().toUtc();
    final label = companyName?.trim().isNotEmpty == true
        ? companyName!
        : symbol;

    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldCredit,
      xp: _stats.xp + (12 * quantity).round(),
      literacyPoints: _stats.literacyPoints + (6 * quantity).round(),
      holdings: holdings,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'cost_basis': existingCostBasis,
      },
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Shorted $symbol',
          description:
              'Borrowed and sold ${formatShares(quantity)} share(s) of $label for $goldCredit gold.',
          amount: goldCredit,
          createdAt: now,
          category: 'invest',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Shorting $symbol...');
  }

  Future<StatsActionResult> coverShortLot({
    required String symbol,
    required int goldCost,
    String? companyName,
    double quantity = 1,
  }) async {
    final holdingKey = 'stock_$symbol';
    final currentLots = _stats.holdings[holdingKey] ?? 0.0;
    if (currentLots >= 0 || currentLots.abs() < quantity) {
      return StatsActionResult(
        success: false,
        message: 'You are not short enough $symbol to cover that amount.',
        syncState: const SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    final holdings = Map<String, double>.from(_stats.holdings);
    final nextLots = currentLots + quantity;
    holdings[holdingKey] = nextLots;
    holdings['stocks'] = (holdings['stocks'] ?? 0.0) + quantity;
    if (nextLots == 0) {
      holdings.remove(holdingKey);
    }
    if ((holdings['stocks'] ?? 0.0) == 0) {
      holdings.remove('stocks');
    }

    final existingCostBasis = Map<String, int>.from(
      (_stats.spendingHabits['cost_basis'] as Map?)?.cast<String, int>() ?? {},
    );
    final currentCost = existingCostBasis[holdingKey] ?? 0;
    existingCostBasis[holdingKey] = currentCost + goldCost;
    if (nextLots == 0) {
      existingCostBasis.remove(holdingKey);
    }

    final now = DateTime.now().toUtc();
    final label = companyName?.trim().isNotEmpty == true
        ? companyName!
        : symbol;

    final nextStats = _stats.copyWith(
      gold: _stats.gold - goldCost,
      xp: _stats.xp + (12 * quantity).round(),
      literacyPoints: _stats.literacyPoints + (6 * quantity).round(),
      holdings: holdings,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'cost_basis': existingCostBasis,
      },
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Covered $symbol',
          description:
              'Bought back ${formatShares(quantity)} share(s) of $label for $goldCost gold.',
          amount: -goldCost,
          createdAt: now,
          category: 'invest',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Covering $symbol...');
  }

  /// Rests a limit order that is not immediately marketable.
  ///
  /// This is the whole point of a limit order: a buy limit *below* the ask (or
  /// a sell limit *above* the bid) does not fill now — it waits for the price
  /// to come to it. [settleWorkingOrders] fills it later when the market
  /// crosses the limit. Sell orders reserve their shares up front (so the same
  /// shares can't be double-sold); buy orders reserve nothing and simply check
  /// affordability at fill time.
  Future<StatsActionResult> placeWorkingOrder({
    required String symbol,
    required bool isBuy,
    required double quantity,
    required int limitPrice,
    String? companyName,
  }) async {
    if (quantity <= 0 || limitPrice < 1) {
      return const StatsActionResult(
        success: false,
        message: 'Enter a quantity and limit price first.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Invalid order.',
        ),
      );
    }

    final holdingKey = 'stock_$symbol';
    final holdings = Map<String, double>.from(_stats.holdings);
    final costBasis = Map<String, int>.from(
      (_stats.spendingHabits['cost_basis'] as Map?)?.cast<String, int>() ?? {},
    );

    var reservedCost = 0;
    if (!isBuy) {
      final owned = holdings[holdingKey] ?? 0.0;
      if (owned < quantity) {
        return StatsActionResult(
          success: false,
          message:
              'You only own ${formatShares(owned)} share(s) of $symbol to reserve.',
          syncState: const SyncState(
            synced: false,
            usedCache: true,
            message: 'No changes saved.',
          ),
        );
      }
      // pull the shares (and their bit of cost basis) out of the live
      // holding so a resting order cant sell shares that got sold somewhere
      // else in the meantime. both come back if you cancel
      final currentCost = costBasis[holdingKey] ?? 0;
      if (owned > 0 && currentCost > 0) {
        reservedCost = (currentCost / owned * quantity).round();
        costBasis[holdingKey] = max(0, currentCost - reservedCost);
      }
      holdings[holdingKey] = owned - quantity;
      holdings['stocks'] = max(0.0, (holdings['stocks'] ?? 0.0) - quantity);
      if ((holdings[holdingKey] ?? 0) <= 0) {
        holdings.remove(holdingKey);
        costBasis.remove(holdingKey);
      }
      if ((holdings['stocks'] ?? 0) <= 0) {
        holdings.remove('stocks');
      }
    }

    final now = DateTime.now().toUtc();
    final order = WorkingOrder(
      id: 'wo_${now.microsecondsSinceEpoch}',
      symbol: symbol,
      company: companyName?.trim().isNotEmpty == true
          ? companyName!.trim()
          : symbol,
      isBuy: isBuy,
      quantity: quantity,
      limitPrice: limitPrice,
      reservedCost: reservedCost,
      createdAt: now,
    );
    final orders = <WorkingOrder>[..._stats.workingOrders, order];

    final nextStats = _stats.copyWith(
      holdings: holdings,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'cost_basis': costBasis,
        'working_orders': orders.map((o) => o.toJson()).toList(),
      },
      updatedAt: now,
    );

    return _saveStats(
      nextStats,
      savingMessage: 'Placing ${isBuy ? 'buy' : 'sell'} limit order...',
    );
  }

  /// Cancels a resting order, returning whatever it reserved (shares + their
  /// cost basis for sells; nothing for buys).
  Future<StatsActionResult> cancelWorkingOrder(String orderId) async {
    WorkingOrder? target;
    for (final order in _stats.workingOrders) {
      if (order.id == orderId) {
        target = order;
        break;
      }
    }
    if (target == null) {
      return const StatsActionResult(
        success: false,
        message: 'That order is no longer working.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    final holdings = Map<String, double>.from(_stats.holdings);
    final costBasis = Map<String, int>.from(
      (_stats.spendingHabits['cost_basis'] as Map?)?.cast<String, int>() ?? {},
    );
    if (!target.isBuy) {
      final holdingKey = 'stock_${target.symbol}';
      holdings[holdingKey] = (holdings[holdingKey] ?? 0.0) + target.quantity;
      holdings['stocks'] = (holdings['stocks'] ?? 0.0) + target.quantity;
      if (target.reservedCost > 0) {
        costBasis[holdingKey] =
            (costBasis[holdingKey] ?? 0) + target.reservedCost;
      }
    }

    final orders = _stats.workingOrders
        .where((o) => o.id != orderId)
        .map((o) => o.toJson())
        .toList();
    final now = DateTime.now().toUtc();

    return _saveStats(
      _stats.copyWith(
        holdings: holdings,
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'cost_basis': costBasis,
          'working_orders': orders,
        },
        updatedAt: now,
      ),
      savingMessage: 'Cancelling order...',
    );
  }

  /// Fills any resting orders the market has now crossed.
  ///
  /// [lastBySymbol] is the current price per symbol. A buy limit fills when the
  /// price drops to/through it; a sell limit fills when the price rises to/
  /// through it. Only saves (and only returns non-zero) when something actually
  /// changes, so it is safe to call on every price refresh. Returns the number
  /// of orders that filled.
  Future<int> settleWorkingOrders(Map<String, int> lastBySymbol) async {
    final open = _stats.workingOrders;
    if (open.isEmpty) {
      return 0;
    }

    final holdings = Map<String, double>.from(_stats.holdings);
    final costBasis = Map<String, int>.from(
      (_stats.spendingHabits['cost_basis'] as Map?)?.cast<String, int>() ?? {},
    );
    final remaining = <WorkingOrder>[];
    final filledTxns = <LedgerTransaction>[];
    var gold = _stats.gold;
    var xp = _stats.xp;
    var literacy = _stats.literacyPoints;
    var fills = 0;
    var idBump = 0;

    for (final order in open) {
      final last = lastBySymbol[order.symbol];
      if (last == null) {
        remaining.add(order);
        continue;
      }
      final buyFills = order.isBuy && last <= order.limitPrice;
      final sellFills = !order.isBuy && last >= order.limitPrice;
      if (!buyFills && !sellFills) {
        remaining.add(order);
        continue;
      }

      final holdingKey = 'stock_${order.symbol}';
      final total = (order.limitPrice * order.quantity).round();
      final now = DateTime.now().toUtc().add(Duration(microseconds: idBump++));

      if (buyFills) {
        if (gold < total) {
          // cant afford it any more, bin the order rather than leaving it
          // sat there unfillable
          continue;
        }
        gold -= total;
        holdings[holdingKey] = (holdings[holdingKey] ?? 0.0) + order.quantity;
        holdings['stocks'] = (holdings['stocks'] ?? 0.0) + order.quantity;
        costBasis[holdingKey] = (costBasis[holdingKey] ?? 0) + total;
        xp += (14 * order.quantity).round();
        literacy += (7 * order.quantity).round();
        filledTxns.add(
          LedgerTransaction(
            id: 'txn_${now.microsecondsSinceEpoch}',
            title: 'Bought ${order.symbol}',
            description:
                'Limit order filled: ${formatShares(order.quantity)} share(s) of ${order.company} at ${order.limitPrice}g.',
            amount: -total,
            createdAt: now,
            category: 'invest',
          ),
        );
      } else {
        // sell fill. shares + cost basis already came out when the order
        // was placed so this only credits the gold
        gold += total;
        xp += (10 * order.quantity).round();
        literacy += (5 * order.quantity).round();
        filledTxns.add(
          LedgerTransaction(
            id: 'txn_${now.microsecondsSinceEpoch}',
            title: 'Sold ${order.symbol}',
            description:
                'Limit order filled: ${formatShares(order.quantity)} share(s) of ${order.company} at ${order.limitPrice}g.',
            amount: total,
            createdAt: now,
            category: 'invest',
          ),
        );
      }
      fills++;
    }

    final changed = fills > 0 || remaining.length != open.length;
    if (!changed) {
      return 0;
    }

    final now = DateTime.now().toUtc();
    await _saveStats(
      _stats.copyWith(
        gold: gold,
        xp: xp,
        literacyPoints: literacy,
        holdings: holdings,
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'cost_basis': costBasis,
          'working_orders': remaining.map((o) => o.toJson()).toList(),
        },
        transactions: <LedgerTransaction>[
          ...filledTxns.reversed,
          ..._stats.transactions,
        ],
        updatedAt: now,
      ),
      savingMessage: 'Filling working orders...',
    );
    return fills;
  }

  Future<StatsActionResult> applyChallengePayload(
    Map<String, dynamic> payload,
  ) async {
    final now = DateTime.now().toUtc();
    final goldEarned = _readInt(payload['gold_earned'] ?? payload['gold']);
    final xpEarned = _readInt(payload['xp_earned'] ?? payload['xp']);
    final literacyEarned = _readInt(
      payload['literacy_points_earned'] ?? payload['literacy_points'],
    );

    // `shares_earned: {'AAPL': 0.5}` grants real Market Board holdings, so a
    // lesson can pay out in stock and not just coins. Keyed by bare symbol
    // here and stored under the `stock_` prefix the board reads.
    final sharesEarned = payload['shares_earned'];
    var nextHoldings = _stats.holdings;
    if (sharesEarned is Map) {
      nextHoldings = <String, double>{..._stats.holdings};
      sharesEarned.forEach((symbol, amount) {
        final key = 'stock_${symbol.toString().trim().toUpperCase()}';
        final granted = (amount is num) ? amount.toDouble() : 0.0;
        if (granted > 0) {
          nextHoldings[key] = (nextHoldings[key] ?? 0.0) + granted;
        }
      });
    }

    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldEarned,
      xp: _stats.xp + xpEarned,
      holdings: nextHoldings,
      literacyPoints: _stats.literacyPoints + literacyEarned,
      personalityType:
          (payload['personality_type'] ?? '').toString().trim().isEmpty
          ? _stats.personalityType
          : payload['personality_type'].toString().trim(),
      spendingHabits: payload['spending_habits'] is Map
          ? <String, dynamic>{
              ..._stats.spendingHabits,
              ...(payload['spending_habits'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            }
          : _stats.spendingHabits,
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: (payload['title'] ?? 'React Challenge Reward').toString(),
          description:
              (payload['description'] ??
                      'Mini-game rewards synced from the local challenge.')
                  .toString(),
          amount: goldEarned,
          createdAt: now,
          category: 'challenge',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Saving challenge rewards...');
  }

  Future<StatsActionResult> completeLessonProgress({
    required String lessonId,
    required String lessonTitle,
    int xpEarned = 10,
    int literacyPointsEarned = 18,
    int goldEarned = 0,
    int? quizCorrect,
    int? quizTotal,
    Iterable<String> missedSkills = const <String>[],
  }) async {
    final completedLessons = _stats.completedLessons.toSet();
    final alreadyComplete = completedLessons.contains(lessonId);

    // A retake still updates the score and skill history — only the rewards
    // and the completion flag are one-time.
    if (alreadyComplete && quizTotal == null) {
      return const StatsActionResult(
        success: true,
        message: 'Lesson already saved.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Lesson progress was already recorded.',
        ),
      );
    }

    completedLessons.add(lessonId);
    final now = DateTime.now().toUtc();

    final quizScores = Map<String, dynamic>.from(_stats.quizScores);
    if (quizTotal != null && quizTotal > 0) {
      final best = _readInt(
        (quizScores[lessonId] as Map?)?['best_correct'] ?? 0,
      );
      quizScores[lessonId] = <String, dynamic>{
        'correct': quizCorrect ?? 0,
        'total': quizTotal,
        // Mastery reads the best attempt so a bad retake cannot erase progress.
        'best_correct': (quizCorrect ?? 0) > best ? (quizCorrect ?? 0) : best,
        'attempts':
            _readInt((quizScores[lessonId] as Map?)?['attempts'] ?? 0) + 1,
        'updated_at': now.toIso8601String(),
      };
    }

    final weakSkills = _stats.weakSkills.toSet();
    if (quizTotal != null) {
      // Skills answered correctly this run clear; freshly missed ones stick
      // until they are answered right somewhere later.
      final missed = missedSkills.toSet();
      weakSkills.addAll(missed);
    }

    final nextStats = _stats.copyWith(
      gold: _stats.gold + (alreadyComplete ? 0 : goldEarned),
      xp: _stats.xp + (alreadyComplete ? 0 : xpEarned),
      literacyPoints:
          _stats.literacyPoints + (alreadyComplete ? 0 : literacyPointsEarned),
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'completed_lessons': completedLessons.toList(growable: false),
        'last_completed_lesson': lessonId,
        'quiz_scores': quizScores,
        'weak_skills': weakSkills.toList(growable: false),
      },
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Academy Lesson Complete',
          description:
              'Finished $lessonTitle and banked $literacyPointsEarned literacy points.',
          amount: goldEarned,
          createdAt: now,
          category: 'lesson',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Saving lesson progress...');
  }

  /// Checks if the daily budget battle challenge has already been completed today.
  /// Checks if any challenge task has been completed.
  bool get isTodayChallengeCompleted {
    final completed = _stats.completedChallengeTasks;
    final today = HabitDateKeys.todayKey();

    return completed.contains('daily_budget_battle') ||
        completed.contains('daily_budget_battle_$today');
  }

  /// Records an arcade run so the hub can show a personal best and play count.
  ///
  /// Rewards are granted by the games themselves through
  /// Clears Adventure Town progress so a new life starts on a fresh map.
  ///
  /// Visited spots and collected coins persist per *player* (they live in
  /// `spending_habits`, like every other saved list), which is right while
  /// a single life is in progress — leaving the town and coming back should
  /// not re-hand you the same coins. But it means a second life would
  /// otherwise inherit a town that is already fully explored. Starting a
  /// new life wipes them; gold already earned is untouched, since that was
  /// genuinely earned.
  Future<StatsActionResult> resetTownProgress() {
    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'town_visited_spots': const <String>[],
          'town_collected_coins': const <String>[],
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Preparing a fresh town...',
    );
  }

  /// [applyChallengePayload]; this only tracks the scoreboard, so it must not
  /// touch gold or XP.
  Future<StatsActionResult> recordArcadeRun({
    required String gameId,
    required int score,
  }) async {
    final scores = Map<String, dynamic>.from(_stats.arcadeScores);
    final previous = scores[gameId];
    final previousBest = previous is Map ? _readInt(previous['best']) : 0;
    final plays = previous is Map ? _readInt(previous['plays']) : 0;

    scores[gameId] = <String, dynamic>{
      'best': score > previousBest ? score : previousBest,
      'plays': plays + 1,
      'last_score': score,
      'last_played_at': DateTime.now().toUtc().toIso8601String(),
    };

    return _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'arcade_scores': scores,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Saving your run...',
    );
  }

  /// Records a practice run. Unlike [completeLessonProgress] this never touches
  /// `completed_lessons` — practice is repeatable and must not inflate the
  /// "lessons complete" count that drives unit progress.
  Future<StatsActionResult> recordPracticeSession({
    required String unitId,
    required int correct,
    required int total,
    Iterable<String> missedSkills = const <String>[],
  }) async {
    if (total <= 0) {
      return const StatsActionResult(
        success: false,
        message: 'Nothing to record.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Empty practice set.',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final missed = missedSkills.toSet();

    // Skills answered correctly this run drop off the weak list; ones missed
    // again stay on it.
    final weakSkills = _stats.weakSkills.toSet()..addAll(missed);

    final xpEarned = correct * 3;
    final nextStats = _stats.copyWith(
      xp: _stats.xp + xpEarned,
      literacyPoints: _stats.literacyPoints + (correct * 2),
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'weak_skills': weakSkills.toList(growable: false),
        'last_practice_unit': unitId,
        'last_practice_at': now.toIso8601String(),
      },
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Saving practice results...');
  }

  /// Clears a skill from the weak list once it has been answered correctly.
  Future<void> clearWeakSkills(Iterable<String> skillIds) async {
    final cleared = skillIds.toSet();
    if (cleared.isEmpty) {
      return;
    }
    final remaining = _stats.weakSkills
        .where((skill) => !cleared.contains(skill))
        .toList(growable: false);
    if (remaining.length == _stats.weakSkills.length) {
      return;
    }

    await _saveStats(
      _stats.copyWith(
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'weak_skills': remaining,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Updating mastery...',
    );
  }

  Future<SkinCaseResult> openSkinCase() async {
    const caseCost = 180;
    if (_stats.gold < caseCost) {
      return SkinCaseResult(
        success: false,
        message: 'You need 180 gold to open an Emerald Case.',
        syncState: const SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
        skin: skinFromId(_stats.equippedSkin),
        isNewUnlock: false,
        goldSpent: 0,
      );
    }

    final unlocked = _stats.unlockedSkins.toSet();
    final awardedSkin = _pickWeightedSkin(budgetBuddySkins);
    final isNewUnlock = !unlocked.contains(awardedSkin.id);
    final now = DateTime.now().toUtc();
    final nextUnlocked = <String>{
      ...unlocked,
      if (isNewUnlock) awardedSkin.id,
    }.toList(growable: false);
    final rebate = isNewUnlock
        ? 0
        : oddsForRarity(awardedSkin.rarity).refundGold;

    final nextStats = _stats.copyWith(
      gold: _stats.gold - caseCost + rebate,
      xp: _stats.xp + (isNewUnlock ? 16 : 8),
      literacyPoints: _stats.literacyPoints + (isNewUnlock ? 8 : 4),
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'equipped_skin': isNewUnlock ? awardedSkin.id : _stats.equippedSkin,
        'unlocked_skins': nextUnlocked,
      },
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: isNewUnlock ? 'Opened Emerald Case' : 'Duplicate Skin Rebate',
          description: isNewUnlock
              ? 'Unlocked ${awardedSkin.name} from the emerald case.'
              : 'Pulled ${awardedSkin.name} again and received a $rebate gold rebate.',
          amount: -(caseCost - rebate),
          createdAt: now,
          category: 'unlock',
        ),
        ..._stats.transactions,
      ],
      updatedAt: now,
    );

    final saveResult = await _saveStats(
      nextStats,
      savingMessage: 'Opening an Emerald Case...',
    );

    return SkinCaseResult(
      success: saveResult.success,
      message: isNewUnlock
          ? 'Unlocked ${awardedSkin.name}!'
          : 'Duplicate pull: ${awardedSkin.name}. $rebate gold returned.',
      syncState: saveResult.syncState,
      skin: awardedSkin,
      isNewUnlock: isNewUnlock,
      goldSpent: caseCost - rebate,
    );
  }

  Future<StatsActionResult> equipSkin(String skinId) async {
    if (!_stats.unlockedSkins.contains(skinId)) {
      return const StatsActionResult(
        success: false,
        message: 'That skin is still locked.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No changes saved.',
        ),
      );
    }

    if (_stats.equippedSkin == skinId) {
      return const StatsActionResult(
        success: true,
        message: 'That skin is already equipped.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Already active.',
        ),
      );
    }

    final nextStats = _stats.copyWith(
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'equipped_skin': skinId,
        'unlocked_skins': _stats.unlockedSkins,
      },
      updatedAt: DateTime.now().toUtc(),
    );

    return _saveStats(
      nextStats,
      savingMessage: 'Equipping your new turtle style...',
    );
  }

  Future<StatsActionResult> updateProfilePhoto(String imageUrl) async {
    final normalizedUrl = imageUrl.trim();
    if (normalizedUrl.isEmpty) {
      return const StatsActionResult(
        success: false,
        message: 'Choose an image before saving a profile photo.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No photo URL was provided.',
        ),
      );
    }

    final nextStats = _stats.copyWith(
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'profile_image_url': normalizedUrl,
      },
      updatedAt: DateTime.now().toUtc(),
    );

    return _saveStats(
      nextStats,
      savingMessage: 'Saving your new profile photo...',
    );
  }

  Future<StatsActionResult> _finishAuthenticatedFlow(
    User user, {
    String? preferredUsername,
    required String successMessage,
  }) async {
    final provisioned = await _service.loadOrCreateUserStatsForUser(
      user: user,
      preferredUsername: preferredUsername,
    );

    _userId = user.id;
    _stats = provisioned.stats;
    _isSaving = false;
    _isLoading = false;
    _statusMessage = provisioned.syncState.message;
    notifyListeners();

    await _attachRealtimeStream();

    final message = provisioned.migratedLegacyProfile
        ? '$successMessage Your existing profile was linked to this account.'
        : successMessage;

    return StatsActionResult(
      success: true,
      message: message,
      syncState: provisioned.syncState,
    );
  }

  StatsActionResult _authFailure(String message) {
    _isSaving = false;
    _statusMessage = message;
    notifyListeners();
    return StatsActionResult(
      success: false,
      message: message,
      syncState: SyncState(
        synced: false,
        usedCache: true,
        message: 'Auth request failed.',
      ),
    );
  }

  Future<void> _syncWithCurrentUser() async {
    final currentUser = _service.currentUser;
    if (currentUser == null) {
      await _resetToSignedOutState(notify: true);
      return;
    }

    final syncUserId = currentUser.id;
    if (_userId != syncUserId) {
      _isLoading = true;
      notifyListeners();
    }

    final cachedStats = await _service.loadCachedUserStatsForUser(
      user: currentUser,
    );
    if (_service.currentUser?.id != syncUserId) {
      return;
    }

    _userId = syncUserId;
    _stats = cachedStats;
    _isLoading = false;
    _isSaving = false;
    _statusMessage = _service.isSupabaseConnected
        ? 'Showing saved progress. Syncing cloud data...'
        : 'Showing saved progress on this device.';
    notifyListeners();

    await _attachRealtimeStream();
    unawaited(_refreshRemoteUserStats(currentUser));
  }

  Future<void> _refreshRemoteUserStats(User user) async {
    try {
      final provisioned = await _service
          .loadOrCreateUserStatsForUser(user: user)
          .timeout(_remoteSyncTimeout);
      if (_service.currentUser?.id != user.id) {
        return;
      }

      _userId = user.id;
      _stats = provisioned.stats;
      _isLoading = false;
      _isSaving = false;
      _statusMessage = provisioned.syncState.message;
      notifyListeners();

      await _attachRealtimeStream();
    } catch (error) {
      debugPrint('Supabase profile sync timed out, using cached data: $error');
      if (_service.currentUser?.id != user.id) {
        return;
      }
      _isLoading = false;
      _isSaving = false;
      _statusMessage = 'Showing saved progress. Cloud sync will retry later.';
      notifyListeners();
    }
  }

  Future<void> _resetToSignedOutState({
    required bool notify,
    String? statusMessage,
  }) async {
    _userId = 'user_123';
    _stats = UserStats.defaults(_userId);
    _isLoading = false;
    _isSaving = false;
    _statusMessage = statusMessage;
    await _subscription?.cancel();
    _subscription = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<StatsActionResult> _saveStats(
    UserStats nextStats, {
    required String savingMessage,
  }) async {
    _stats = nextStats;
    _isSaving = true;
    _statusMessage = savingMessage;
    notifyListeners();

    final syncState = await _service.saveUserStats(nextStats);

    _isSaving = false;
    _statusMessage = syncState.message;
    // Only a signed-in player has a cloud save to lose; signed out, "saved on
    // this device" is simply what is supposed to happen.
    if (isAuthenticated) {
      if (syncState.synced) {
        _cloudSyncHealthy = true;
      } else {
        _cloudSyncHealthy = false;
        _lastCloudSyncFailure = DateTime.now();
      }
    }
    notifyListeners();

    return StatsActionResult(
      success: true,
      message: syncState.message,
      syncState: syncState,
    );
  }

  Future<void> _attachRealtimeStream() async {
    await _subscription?.cancel();
    _subscription = _service
        .watchUserStats(_userId)
        .listen(
          (freshStats) {
            _stats = freshStats;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('User stats realtime stream failed: $error');
          },
        );
  }

  /// Appends a **real** net-worth reading (in coins) to the equity curve the
  /// P&L tab draws.
  ///
  /// This replaces an earlier synthetic series that nudged a 0..1 number up by
  /// a fixed amount on every buy and down on every sell — so the curve rose
  /// whenever you traded, even while you were losing money. Callers pass the
  /// genuine `cash + market value` so the line can actually fall.
  Future<void> recordNetWorth(int netWorth) async {
    if (netWorth <= 0) {
      return;
    }
    final series = List<double>.from(realPortfolioHistory);
    // Ignore no-op ticks so idle polling can't flood the curve with duplicates.
    if (series.isNotEmpty && (series.last - netWorth).abs() < 1) {
      return;
    }
    series.add(netWorth.toDouble());

    // Timestamps travel with the values. Without them the chart had to invent
    // an x-axis — it assumed one minute per point — so no amount of history
    // could ever show a real date, which is what "let me see further than a
    // day" was actually asking for.
    final now = DateTime.now().toUtc();
    final stamps = List<DateTime>.from(_stats.portfolioHistoryAt);
    // Older saves have values but no stamps. Pad the front so the two lists
    // line up by index rather than silently mis-pairing every point.
    while (stamps.length < series.length - 1) {
      stamps.insert(0, now);
    }
    stamps.add(now);

    // Keep the curve bounded, but drop the *oldest* points rather than
    // refusing new ones. 400 is a few weeks of trading at a snapshot per
    // refresh, where the old 60 was under an hour — which is why the chart
    // never reached back beyond the current session.
    while (series.length > _portfolioHistoryLimit) {
      series.removeAt(0);
      if (stamps.isNotEmpty) stamps.removeAt(0);
    }

    await _saveStats(
      _stats.copyWith(
        portfolioHistory: series,
        spendingHabits: <String, dynamic>{
          ..._stats.spendingHabits,
          'portfolio_history_at': [
            for (final t in stamps) t.millisecondsSinceEpoch ~/ 1000,
          ],
        },
        updatedAt: DateTime.now().toUtc(),
      ),
      savingMessage: 'Updating portfolio history...',
    );
  }

  /// How many net-worth snapshots to keep.
  ///
  /// At a snapshot per price refresh this is a few weeks of trading. The old
  /// limit of 60 was well under an hour, so the curve could not reach past
  /// the current session no matter how long the player had been playing.
  static const int _portfolioHistoryLimit = 400;

  /// Times for [realPortfolioHistory], aligned to it by index.
  ///
  /// Empty when the save predates timestamps; shorter than the values when
  /// only part of the history was recorded with them. Callers pair from the
  /// **end**, because the newest points are the ones that have stamps.
  List<DateTime> get portfolioHistoryTimes => _stats.portfolioHistoryAt;

  /// The equity curve with any legacy synthetic points stripped.
  ///
  /// The old series stored normalised 0..1 values; real net worth is always
  /// well above 1 coin, so anything below that is leftover fiction and is
  /// dropped rather than migrated.
  List<double> get realPortfolioHistory => _stats.portfolioHistory
      .where((value) => value.isFinite && value >= 1)
      .toList(growable: false);

  AvatarSkin _pickWeightedSkin(List<AvatarSkin> skins) {
    var rarityRoll = _random.nextInt(skinCaseTotalWeight);
    var selectedRarity = skinCaseRarityOdds.last.rarity;
    for (final odds in skinCaseRarityOdds) {
      if (rarityRoll < odds.weight) {
        selectedRarity = odds.rarity;
        break;
      }
      rarityRoll -= odds.weight;
    }

    final rarityPool = skins
        .where((skin) => skin.rarity == selectedRarity)
        .toList(growable: false);

    if (rarityPool.isNotEmpty) {
      return rarityPool[_random.nextInt(rarityPool.length)];
    }

    return skins.first;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
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

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

extension UserStatsCostBasisExtension on UserStats {
  Map<String, int> get costBasis {
    final raw = spendingHabits['cost_basis'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), _readInt(v)));
    }
    return const {};
  }
}

/// A resting limit order — placed but not yet filled — that lives in
/// `spendingHabits['working_orders']` so it survives a reload and a cloud sync.
@immutable
class WorkingOrder {
  const WorkingOrder({
    required this.id,
    required this.symbol,
    required this.company,
    required this.isBuy,
    required this.quantity,
    required this.limitPrice,
    required this.reservedCost,
    required this.createdAt,
  });

  final String id;
  final String symbol;
  final String company;
  final bool isBuy;
  final double quantity;
  final int limitPrice;

  /// Cost basis pulled aside when a sell order reserved its shares, so a
  /// cancel can restore the position's average cost exactly. Zero for buys.
  final int reservedCost;
  final DateTime createdAt;

  int get total => (quantity * limitPrice).round();

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'symbol': symbol,
    'company': company,
    'is_buy': isBuy,
    'quantity': quantity,
    'limit_price': limitPrice,
    'reserved_cost': reservedCost,
    'created_at': createdAt.toIso8601String(),
  };

  static WorkingOrder? fromJson(Map<String, dynamic> json) {
    final symbol = (json['symbol'] ?? '').toString();
    if (symbol.isEmpty) {
      return null;
    }
    return WorkingOrder(
      id: (json['id'] ?? 'wo_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      symbol: symbol,
      company: (json['company'] ?? symbol).toString(),
      isBuy: json['is_buy'] == true,
      quantity: _readDouble(json['quantity']),
      limitPrice: _readInt(json['limit_price']),
      reservedCost: _readInt(json['reserved_cost']),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }
}

extension UserStatsWorkingOrdersExtension on UserStats {
  List<WorkingOrder> get workingOrders {
    final raw = spendingHabits['working_orders'];
    if (raw is! List) {
      return const <WorkingOrder>[];
    }
    return raw
        .whereType<Map>()
        .map((m) => WorkingOrder.fromJson(m.cast<String, dynamic>()))
        .whereType<WorkingOrder>()
        .toList(growable: false);
  }
}
