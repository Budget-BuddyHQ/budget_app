import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
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
  StreamSubscription<UserStats>? _subscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  static const Duration _remoteSyncTimeout = Duration(seconds: 8);

  UserStats get stats => _stats;
  String get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get statusMessage => _statusMessage;
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
            'Supabase did not return a user for this sign-up.',
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

        return _finishAuthenticatedFlow(
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
        return _authFailure('Supabase did not return a user for this sign-in.');
      }

      final client = Supabase.instance.client;

      final profile = await client
          .from('profiles')
          .select('disabled')
          .eq('id', user.id)
          .maybeSingle();

      final isDisabled = profile?['disabled'] == true;

      if (isDisabled) {
        await client.auth.signOut();

        _isSaving = false;
        _statusMessage = 'This account has been disabled.';
        notifyListeners();

        return const StatsActionResult(
          success: false,
          message: 'Your account has been disabled. Contact support.',
          syncState: SyncState(
            synced: false,
            usedCache: true,
            message: 'User disabled',
          ),
        );
      }

      return _finishAuthenticatedFlow(
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

    final holdings = Map<String, int>.from(_stats.holdings)
      ..update('indexFunds', (value) => value + 1, ifAbsent: () => 1);
    final nextHistory = _nextPortfolioSeries(0.06);
    final now = DateTime.now().toUtc();

    final nextStats = _stats.copyWith(
      gold: _stats.gold - goldCost,
      xp: _stats.xp + 18,
      literacyPoints: _stats.literacyPoints + 8,
      holdings: holdings,
      portfolioHistory: nextHistory,
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
    final currentStockLots = _stats.holdings['stocks'] ?? 0;
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
    final holdings = Map<String, int>.from(_stats.holdings)
      ..update('stocks', (value) => value > 0 ? value - 1 : 0);
    final nextHistory = _nextPortfolioSeries(-0.05);
    final now = DateTime.now().toUtc();

    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldReturn,
      xp: _stats.xp + 10,
      literacyPoints: _stats.literacyPoints + 4,
      holdings: holdings,
      portfolioHistory: nextHistory,
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
    final holdings = Map<String, int>.from(_stats.holdings)
      ..update(holdingKey, (value) => value + 1, ifAbsent: () => 1)
      ..update('stocks', (value) => value + 1, ifAbsent: () => 1);
    final nextHistory = _nextPortfolioSeries(0.04);
    final now = DateTime.now().toUtc();
    final label = companyName?.trim().isNotEmpty == true
        ? companyName!
        : symbol;

    final nextStats = _stats.copyWith(
      gold: _stats.gold - goldCost,
      xp: _stats.xp + 14,
      literacyPoints: _stats.literacyPoints + 7,
      holdings: holdings,
      portfolioHistory: nextHistory,
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Bought $symbol',
          description: 'Opened one lot of $label for $goldCost gold.',
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
  }) async {
    final holdingKey = 'stock_$symbol';
    final currentLots = _stats.holdings[holdingKey] ?? 0;
    if (currentLots <= 0) {
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

    final holdings = Map<String, int>.from(_stats.holdings)
      ..update(holdingKey, (value) => value > 0 ? value - 1 : 0)
      ..update(
        'stocks',
        (value) => value > 0 ? value - 1 : 0,
        ifAbsent: () => 0,
      );
    if ((holdings[holdingKey] ?? 0) <= 0) {
      holdings.remove(holdingKey);
    }
    if ((holdings['stocks'] ?? 0) <= 0) {
      holdings.remove('stocks');
    }

    final nextHistory = _nextPortfolioSeries(-0.03);
    final now = DateTime.now().toUtc();
    final label = companyName?.trim().isNotEmpty == true
        ? companyName!
        : symbol;

    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldReturn,
      xp: _stats.xp + 10,
      literacyPoints: _stats.literacyPoints + 5,
      holdings: holdings,
      portfolioHistory: nextHistory,
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'txn_${now.microsecondsSinceEpoch}',
          title: 'Sold $symbol',
          description: 'Closed one lot of $label for $goldReturn gold.',
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

  Future<StatsActionResult> applyChallengePayload(
    Map<String, dynamic> payload,
  ) async {
    final now = DateTime.now().toUtc();
    final goldEarned = _readInt(payload['gold_earned'] ?? payload['gold']);
    final xpEarned = _readInt(payload['xp_earned'] ?? payload['xp']);
    final literacyEarned = _readInt(
      payload['literacy_points_earned'] ?? payload['literacy_points'],
    );

    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldEarned,
      xp: _stats.xp + xpEarned,
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
  }) async {
    final completedLessons = _stats.completedLessons.toSet();
    if (completedLessons.contains(lessonId)) {
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
    final nextStats = _stats.copyWith(
      gold: _stats.gold + goldEarned,
      xp: _stats.xp + xpEarned,
      literacyPoints: _stats.literacyPoints + literacyPointsEarned,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'completed_lessons': completedLessons.toList(growable: false),
        'last_completed_lesson': lessonId,
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

  Future<StatsActionResult> saveAdventureProgress({
    required String mapId,
    required double x,
    required double y,
  }) async {
    final normalizedMapId = mapId.trim().isEmpty
        ? _stats.adventureMapId
        : mapId.trim();
    if (!x.isFinite || !y.isFinite) {
      return const StatsActionResult(
        success: false,
        message: 'Invalid adventure position.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'No adventure progress saved.',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final nextStats = _stats.copyWith(
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'adventure_map_id': normalizedMapId,
        'adventure_position_x': x,
        'adventure_position_y': y,
      },
      updatedAt: now,
    );

    return _saveStats(nextStats, savingMessage: 'Saving adventure progress...');
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

  List<double> _nextPortfolioSeries(double delta) {
    final series = List<double>.from(_stats.portfolioHistory);
    final current = series.isEmpty ? 0.42 : series.last;
    final nextPoint = (current + delta).clamp(0.16, 0.95).toDouble();
    if (series.length >= 8) {
      series.removeAt(0);
    }
    series.add(nextPoint);
    return series;
  }

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
