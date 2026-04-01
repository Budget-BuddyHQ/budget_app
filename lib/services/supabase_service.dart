import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool get isCredit => amount >= 0;

  String get amountLabel => '${amount >= 0 ? '+' : ''}$amount gold';

  String get relativeLabel {
    final now = DateTime.now();
    final difference = now.difference(createdAt.toLocal());

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} mins ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hrs ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    return '${difference.inDays} days ago';
  }

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
  final Map<String, int> holdings;
  final DateTime updatedAt;

  factory UserStats.defaults(String userId) {
    final now = DateTime.now().toUtc();
    return UserStats(
      id: userId,
      username: 'Username3189',
      gold: 2450,
      xp: 850,
      literacyPoints: 850,
      personalityType: 'Spender',
      spendingHabits: const <String, dynamic>{
        'risk_tolerance': 'balanced',
        'confidence_score': 2.0,
        'missed_questions': <String>[],
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
      holdings: const <String, int>{
        'indexFunds': 3,
        'stocks': 2,
      },
      updatedAt: now,
    );
  }

  factory UserStats.fromMap(Map<String, dynamic> json) {
    final spendingHabits = _readMap(json['spending_habits']);
    final holdings = _readIntMap(json['holdings']);
    final transactions = _readTransactions(json['transaction_ledger']);
    final portfolioHistory = _readDoubleList(json['portfolio_history']);

    return UserStats(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? spendingHabits['username'] ?? 'Username3189')
          .toString(),
      gold: _readInt(json['gold']),
      xp: _readInt(json['xp']),
      literacyPoints: _readInt(json['literacy_points'] ?? json['literacy_score']),
      personalityType: (json['personality_type'] ?? 'Spender').toString(),
      spendingHabits: <String, dynamic>{
        'username': (json['username'] ?? 'Username3189').toString(),
        ...spendingHabits,
      },
      transactions: transactions.isEmpty
          ? UserStats.defaults((json['id'] ?? 'user_123').toString()).transactions
          : transactions,
      portfolioHistory: portfolioHistory.isEmpty
          ? UserStats.defaults((json['id'] ?? 'user_123').toString()).portfolioHistory
          : portfolioHistory,
      holdings: holdings.isEmpty
          ? UserStats.defaults((json['id'] ?? 'user_123').toString()).holdings
          : holdings,
      updatedAt: _readDate(json['updated_at']) ?? DateTime.now().toUtc(),
    );
  }

  int get level => math.max(1, xp ~/ 120);

  String get levelTitle => 'Level $level Finance Wizard';

  String get wizardAdvice {
    switch (personalityType.toLowerCase()) {
      case 'spender':
      case 'the spender':
      case 'impulse spender':
      case 'the impulse spender':
        return 'The market is volatile today, maybe save your gold?';
      case 'risk-taker':
      case 'the risk-taker':
        return 'Momentum is strong, but keep a safety stash before the next boss battle.';
      case 'saver':
      case 'the saver':
        return 'Your discipline is working. A small, consistent investment could grow your kingdom.';
      default:
        return 'You are building smart habits. Keep balancing savings, learning, and strategic risks.';
    }
  }

  double get levelProgress => (xp % 120) / 120;

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
      },
      'transaction_ledger': transactions
          .map((transaction) => transaction.toJson())
          .toList(growable: false),
      'portfolio_history': portfolioHistory,
      'holdings': holdings,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  UserStats copyWith({
    String? username,
    int? gold,
    int? xp,
    int? literacyPoints,
    String? personalityType,
    Map<String, dynamic>? spendingHabits,
    List<LedgerTransaction>? transactions,
    List<double>? portfolioHistory,
    Map<String, int>? holdings,
    DateTime? updatedAt,
  }) {
    return UserStats(
      id: id,
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

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const String userStatsTable = 'user_stats';
  static const String _sessionUserIdKey = 'budget_buddy_session_user_id';
  static const String _sessionEmailKey = 'budget_buddy_session_email';
  static const String _sessionUsernameKey = 'budget_buddy_session_username';
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
''';

  final StreamController<UserStats> _localController =
      StreamController<UserStats>.broadcast();
  final Map<String, UserStats> _memoryCache = <String, UserStats>{};

  SharedPreferences? _preferences;
  bool _isReady = false;
  bool _isSupabaseConnected = false;

  bool get isSupabaseConnected => _isSupabaseConnected;
  bool get hasCachedPreferences => _preferences != null;

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_isReady) {
      return;
    }

    _isReady = true;
    _preferences = await SharedPreferences.getInstance();

    final existingClient = _existingClient;
    if (existingClient != null) {
      _isSupabaseConnected = true;
      return;
    }

    final hasKeys = supabaseUrl.trim().isNotEmpty &&
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
          .maybeSingle();

      if (response == null) {
        await saveUserStats(fallback);
        return fallback;
      }

      final stats = UserStats.fromMap(response);
      await _cacheUserStats(stats);
      _memoryCache[userId] = stats;
      return stats;
    } catch (error) {
      debugPrint('Supabase fetch failed, using cached data: $error');
      return fallback;
    }
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
          final fallback = _memoryCache[userId] ?? UserStats.defaults(userId);
          return fallback;
        }

        final stats = UserStats.fromMap(rows.first);
        _memoryCache[userId] = stats;
        await _cacheUserStats(stats);
        return stats;
      });
      return;
    }

    yield* _localController.stream.where((stats) => stats.id == userId);
  }

  Future<SyncState> saveUserStats(UserStats stats) async {
    await _ensurePreferences();
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

  String _cacheKey(String userId) => 'budget_buddy_user_stats_$userId';

  Future<String?> getActiveSessionUserId() async {
    final preferences = await _ensurePreferences();
    final savedId = preferences.getString(_sessionUserIdKey);
    if (savedId == null || savedId.trim().isEmpty) {
      return null;
    }
    return savedId;
  }

  Future<String> restoreSessionUserId({
    String fallback = 'user_123',
  }) async {
    return await getActiveSessionUserId() ?? fallback;
  }

  Future<String?> getActiveSessionUsername() async {
    final preferences = await _ensurePreferences();
    final username = preferences.getString(_sessionUsernameKey);
    if (username == null || username.trim().isEmpty) {
      return null;
    }
    return username;
  }

  Future<void> persistSession({
    required String userId,
    required String username,
    String? email,
  }) async {
    final preferences = await _ensurePreferences();
    await preferences.setString(_sessionUserIdKey, userId);
    await preferences.setString(_sessionUsernameKey, username);
    if (email != null && email.trim().isNotEmpty) {
      await preferences.setString(_sessionEmailKey, email.trim().toLowerCase());
    }
  }

  Future<void> clearSessionAndCache({String? userId}) async {
    final preferences = await _ensurePreferences();
    await preferences.remove(_sessionUserIdKey);
    await preferences.remove(_sessionEmailKey);
    await preferences.remove(_sessionUsernameKey);

    final keysToRemove = preferences
        .getKeys()
        .where((key) => key.startsWith('budget_buddy_user_stats_'))
        .toList(growable: false);
    for (final key in keysToRemove) {
      await preferences.remove(key);
    }

    _memoryCache.clear();

    if (_isSupabaseConnected) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (error) {
        debugPrint('Supabase sign out skipped: $error');
      }
    }

    if (userId != null) {
      _localController.add(UserStats.defaults(userId));
    }
  }

  Future<SharedPreferences> _ensurePreferences() async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }

  SupabaseClient? get _existingClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
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
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  return <String, dynamic>{};
}

Map<String, int> _readIntMap(dynamic value) {
  final map = _readMap(value);
  return map.map((key, mapValue) => MapEntry(key, _readInt(mapValue)));
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
