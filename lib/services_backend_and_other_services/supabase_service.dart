import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';

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
      holdings: const <String, int>{'indexFunds': 3, 'stocks': 2},
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

  String get profileImageUrl {
    final value = spendingHabits['profile_image_url']?.toString().trim();
    if (value == null || value.isEmpty) {
      return '';
    }
    return value;
  }

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
    Map<String, int>? holdings,
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
  });

  final String id;
  final int rank;
  final String username;
  final int literacyPoints;
  final int xp;
  final int gold;
  final bool isCurrentUser;

  String get scoreLabel => '$literacyPoints LP';
}

@immutable
class CurrentUserProfile {
  const CurrentUserProfile({
    required this.role,
    required this.avatarUrl,
  });

  final String role;
  final String avatarUrl;

  bool get isAdmin => role.trim().toLowerCase() == 'admin';
}

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const String userStatsTable = 'user_stats';
  static const String leaderboardView = 'leaderboard';
  static const Set<String> _ownerAdminEmails = <String>{
    'brucksheferaw@gmail.com',
  };
  static bool isKnownAdminEmail(String? email) {
    return _ownerAdminEmails.contains(email?.trim().toLowerCase());
  }
  static bool hasAdminMetadata(User? user) {
    final role =
        _roleFromMetadata(user?.appMetadata) ??
        _roleFromMetadata(user?.userMetadata);
    return role?.trim().toLowerCase() == 'admin';
  }
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

create or replace view public.leaderboard as
select
  id,
  username,
  literacy_points,
  xp,
  gold,
  updated_at
from public.user_stats;

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
''';

  final StreamController<UserStats> _localController =
      StreamController<UserStats>.broadcast();
  final Map<String, UserStats> _memoryCache = <String, UserStats>{};

  SharedPreferences? _preferences;
  bool _isReady = false;
  bool _isSupabaseConnected = false;

  bool get isSupabaseConnected => _isSupabaseConnected;
  bool get hasCachedPreferences => _preferences != null;
  User? get currentUser => _existingClient?.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  Session? get currentSession => _existingClient?.auth.currentSession;

  Stream<AuthState> authStateChanges() async* {
    final client = _existingClient;
    if (client == null) {
      return;
    }
    yield* client.auth.onAuthStateChange;
  }

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

  Future<CurrentUserProfile?> getCurrentUserProfile() async {
    final client = _existingClient;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return null;
    }

    final email = user.email?.trim().toLowerCase();
    var role =
        _roleFromMetadata(user.appMetadata) ??
        _roleFromMetadata(user.userMetadata) ??
        (SupabaseService.isKnownAdminEmail(email) ? 'admin' : '');
    var avatarUrl =
        _readString(user.userMetadata?['avatar_url']) ??
        _readString(user.userMetadata?['profile_image_url']) ??
        '';

    try {
      final response = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      role = _readString(response?['role']) ?? role;
    } catch (error) {
      debugPrint('Supabase profile role lookup failed by id: $error');
    }

    if (role.trim().isEmpty && email != null && email.isNotEmpty) {
      try {
        final response = await client
            .from('profiles')
            .select('role')
            .eq('email', email)
            .maybeSingle();
        role = _readString(response?['role']) ?? role;
      } catch (error) {
        debugPrint('Supabase profile role lookup failed by email: $error');
      }
    }

    try {
      final response = await client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      avatarUrl = _readString(response?['avatar_url']) ?? avatarUrl;
    } catch (error) {
      debugPrint('Supabase profile avatar lookup failed: $error');
    }

    if (role.trim().isEmpty && avatarUrl.trim().isEmpty) {
      return null;
    }

    return CurrentUserProfile(
      role: role,
      avatarUrl: avatarUrl,
    );
  }

  Future<String?> getUserRole() async {
    return (await getCurrentUserProfile())?.role;
  }

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

  Future<void> resetPasswordForEmail(String email) async {
    final client = _requireClient();
    await client.auth.resetPasswordForEmail(email.trim().toLowerCase());
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

    await Supabase.instance.client.storage
        .from('profile-images')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeForExtension(safeExtension),
          ),
        );

    return Supabase.instance.client.storage
        .from('profile-images')
        .getPublicUrl(storagePath);
  }

  Future<void> updateProfileAvatarUrl({
    required String userId,
    required String avatarUrl,
  }) async {
    if (!_isSupabaseConnected) {
      return;
    }

    await Supabase.instance.client
        .from('profiles')
        .update(<String, dynamic>{'avatar_url': avatarUrl})
        .eq('id', userId);
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
          .maybeSingle();

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
    int limit = 20,
    String? currentUserId,
  }) async {
    await _ensurePreferences();
    final normalizedLimit = limit.clamp(1, 50);

    if (!_isSupabaseConnected) {
      return _buildCachedLeaderboard(
        limit: normalizedLimit,
        currentUserId: currentUserId,
      );
    }

    try {
      final response = await Supabase.instance.client
          .from(leaderboardView)
          .select('id, username, literacy_points, xp, gold')
          .order('literacy_points', ascending: false)
          .order('xp', ascending: false)
          .order('gold', ascending: false)
          .limit(normalizedLimit);

      if (response.isEmpty) {
        return _buildCachedLeaderboard(
          limit: normalizedLimit,
          currentUserId: currentUserId,
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

Map<String, int> _readIntMap(dynamic value) {
  final map = _readMap(value);
  return map.map((key, mapValue) => MapEntry(key, _readInt(mapValue)));
}

String? _readString(dynamic value) {
  final stringValue = value?.toString().trim();
  if (stringValue == null || stringValue.isEmpty) {
    return null;
  }
  return stringValue;
}

String? _roleFromMetadata(Map<String, dynamic>? metadata) {
  if (metadata == null) {
    return null;
  }
  return _readString(metadata['role']) ??
      _readString(metadata['app_role']) ??
      _readString(metadata['user_role']);
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
