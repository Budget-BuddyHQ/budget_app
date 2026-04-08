import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/avatar_skin.dart';
import '../services/supabase_service.dart';

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
  })  : _service = service,
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

  UserStats get stats => _stats;
  String get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get statusMessage => _statusMessage;
  bool get isAuthenticated => _service.currentUser != null;

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
        );
        final user = response.user;
        if (user == null) {
          return _authFailure('Supabase did not return a user for this sign-up.');
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
      );
      final user = response.user;
      if (user == null) {
        return _authFailure('Supabase did not return a user for this sign-in.');
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
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return const StatsActionResult(
        success: false,
        message:
            'Enter your email so we know where to send the reset link.',
        syncState: SyncState(
          synced: false,
          usedCache: true,
          message: 'Missing email address.',
        ),
      );
    }

    try {
      await _service.resetPasswordForEmail(normalizedEmail);
      return const StatsActionResult(
        success: true,
        message:
            'Password reset email sent. Check your inbox and spam folder.',
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
      await _resetToSignedOutState(
        notify: true,
        statusMessage: 'Logged out.',
      );
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

    return _saveStats(
      nextStats,
      savingMessage: 'Executing sell order...',
    );
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
          description: (payload['description'] ??
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

    return _saveStats(
      nextStats,
      savingMessage: 'Saving challenge rewards...',
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
    final availablePool = budgetBuddySkins
        .where((skin) => !unlocked.contains(skin.id))
        .toList(growable: false);
    final pool = availablePool.isEmpty ? budgetBuddySkins : availablePool;
    final awardedSkin = _pickWeightedSkin(pool);
    final isNewUnlock = !unlocked.contains(awardedSkin.id);
    final now = DateTime.now().toUtc();
    final nextUnlocked = <String>{
      ...unlocked,
      if (isNewUnlock) awardedSkin.id,
    }.toList(growable: false);
    final rebate = isNewUnlock ? 0 : 40;

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
              : 'Pulled ${awardedSkin.name} again and received a 40 gold rebate.',
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
          : 'Duplicate pull: ${awardedSkin.name}. 40 gold returned.',
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

    _isLoading = true;
    notifyListeners();

    final provisioned = await _service.loadOrCreateUserStatsForUser(
      user: currentUser,
    );
    _userId = currentUser.id;
    _stats = provisioned.stats;
    _isLoading = false;
    _isSaving = false;
    _statusMessage = provisioned.syncState.message;
    notifyListeners();

    await _attachRealtimeStream();
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
    _subscription = _service.watchUserStats(_userId).listen((freshStats) {
      _stats = freshStats;
      notifyListeners();
    });
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
    final totalWeight = skins.fold<int>(0, (sum, skin) => sum + skin.weight);
    var roll = _random.nextInt(totalWeight);
    for (final skin in skins) {
      if (roll < skin.weight) {
        return skin;
      }
      roll -= skin.weight;
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
