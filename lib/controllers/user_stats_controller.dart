import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/supabase_service.dart';

@immutable
class StatsActionResult {
  const StatsActionResult({
    required this.success,
    required this.message,
    required this.syncState,
  });

  final bool success;
  final String message;
  final SyncState syncState;
}

class UserStatsController extends ChangeNotifier {
  UserStatsController({
    required SupabaseService service,
    String initialUserId = 'user_123',
  })  : _service = service,
        _userId = initialUserId,
        _stats = UserStats.defaults(initialUserId);

  final SupabaseService _service;

  String _userId;
  UserStats _stats;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;
  StreamSubscription<UserStats>? _subscription;
  bool _initialized = false;

  UserStats get stats => _stats;
  String get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get statusMessage => _statusMessage;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _isLoading = true;
    notifyListeners();

    _userId = await _service.restoreSessionUserId(fallback: _userId);
    _stats = await _service.loadUserStats(_userId);
    _isLoading = false;
    notifyListeners();

    await _attachRealtimeStream();
  }

  Future<void> refresh() async {
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

    _userId = _userIdFromEmail(normalizedEmail);
    _stats = await _service.loadUserStats(_userId);

    final resolvedUsername =
        (username?.trim().isNotEmpty ?? false) ? username!.trim() : _displayNameFromEmail(normalizedEmail);
    final nextStats = _stats.copyWith(
      username: resolvedUsername,
      spendingHabits: <String, dynamic>{
        ..._stats.spendingHabits,
        'username': resolvedUsername,
        'email': normalizedEmail,
      },
      updatedAt: DateTime.now().toUtc(),
    );

    await _service.persistSession(
      userId: _userId,
      username: resolvedUsername,
      email: normalizedEmail,
    );

    final result = await _saveStats(
      nextStats,
      savingMessage: isNewAccount
          ? 'Creating your Budget Buddy profile...'
          : 'Signing you in...',
    );

    await _attachRealtimeStream();
    return result;
  }

  Future<void> signOut() async {
    await _subscription?.cancel();
    _subscription = null;
    final previousUserId = _userId;
    await _service.clearSessionAndCache(userId: previousUserId);
    _userId = 'user_123';
    _stats = UserStats.defaults(_userId);
    _isLoading = false;
    _isSaving = false;
    _statusMessage = 'Logged out.';
    notifyListeners();
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
      personalityType: (payload['personality_type'] ?? '').toString().trim().isEmpty
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
    series.add(nextPoint.toDouble());
    return series;
  }

  String _userIdFromEmail(String email) {
    final safe = email.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'user_$safe';
  }

  String _displayNameFromEmail(String email) {
    final handle = email.split('@').first.trim();
    if (handle.isEmpty) {
      return 'Finance Wizard';
    }
    final cleaned = handle.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ').trim();
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
