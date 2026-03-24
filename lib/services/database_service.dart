import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseSyncResult {
  const DatabaseSyncResult({
    required this.synced,
    required this.queued,
    this.message,
    this.queuedCount = 0,
  });

  final bool synced;
  final bool queued;
  final String? message;
  final int queuedCount;
}

@immutable
class UserProgressRecord {
  const UserProgressRecord({
    required this.id,
    required this.username,
    required this.xp,
    required this.gold,
    required this.literacyScore,
    required this.spendingHabits,
    required this.personalityType,
    this.updatedAt,
  });

  final String id;
  final String username;
  final int xp;
  final int gold;
  final int literacyScore;
  final Map<String, dynamic> spendingHabits;
  final String personalityType;
  final DateTime? updatedAt;

  factory UserProgressRecord.defaults(String userId) {
    return UserProgressRecord(
      id: userId,
      username: 'Username3189',
      xp: 850,
      gold: 2450,
      literacyScore: 850,
      spendingHabits: const <String, dynamic>{
        'username': 'Username3189',
        'risk_tolerance': 'balanced',
        'impulse_spend_score': 0.62,
        'missed_questions': <String>[],
      },
      personalityType: 'Spender',
      updatedAt: DateTime.now().toUtc(),
    );
  }

  factory UserProgressRecord.fromJson(Map<String, dynamic> json) {
    final spendingHabits = _readMap(json['spending_habits']);
    return UserProgressRecord(
      id: (json['id'] ?? '').toString(),
      username: _extractUsername(json, spendingHabits),
      xp: _readInt(json['xp']),
      gold: _readInt(json['gold']),
      literacyScore: _readInt(json['literacy_score']),
      spendingHabits: spendingHabits,
      personalityType: (json['personality_type'] ?? 'Spender').toString(),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'xp': xp,
      'gold': gold,
      'literacy_score': literacyScore,
      'spending_habits': <String, dynamic>{
        ...spendingHabits,
        'username': username,
      },
      'personality_type': personalityType,
      'updated_at': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    };
  }

  UserProgressRecord copyWith({
    String? username,
    int? xp,
    int? gold,
    int? literacyScore,
    Map<String, dynamic>? spendingHabits,
    String? personalityType,
    DateTime? updatedAt,
  }) {
    return UserProgressRecord(
      id: id,
      username: username ?? this.username,
      xp: xp ?? this.xp,
      gold: gold ?? this.gold,
      literacyScore: literacyScore ?? this.literacyScore,
      spendingHabits: spendingHabits ?? this.spendingHabits,
      personalityType: personalityType ?? this.personalityType,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _readInt(dynamic value) {
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

  static Map<String, dynamic> _readMap(dynamic value) {
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

  static DateTime? _readDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  static String _extractUsername(
    Map<String, dynamic> json,
    Map<String, dynamic> spendingHabits,
  ) {
    final explicitUsername = json['username']?.toString().trim();
    if (explicitUsername != null && explicitUsername.isNotEmpty) {
      return explicitUsername;
    }

    final embeddedUsername = spendingHabits['username']?.toString().trim();
    if (embeddedUsername != null && embeddedUsername.isNotEmpty) {
      return embeddedUsername;
    }

    return 'Username3189';
  }
}

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String userProgressTable = 'user_progress';

  static const String userProgressSchemaSql = '''
create table if not exists public.user_progress (
  id text primary key,
  username text not null default 'Username3189',
  xp integer not null default 0,
  gold integer not null default 0,
  literacy_score integer not null default 0,
  spending_habits jsonb not null default '{}'::jsonb,
  personality_type text not null default 'Spender',
  updated_at timestamptz not null default timezone('utc', now())
);
''';

  final StreamController<UserProgressRecord> _localProgressController =
      StreamController<UserProgressRecord>.broadcast();
  final Map<String, UserProgressRecord> _cachedRecords =
      <String, UserProgressRecord>{};
  final List<Map<String, dynamic>> _pendingQueue = <Map<String, dynamic>>[];

  bool _initialized = false;
  bool _supabaseReady = false;
  String _supabaseUrl = '';
  String _supabaseAnonKey = '';

  bool get isSupabaseReady => _supabaseReady;

  String get configurationMessage {
    if (_supabaseReady) {
      return 'Connected to PostgreSQL via Supabase.';
    }
    return 'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY dart-defines to enable cloud sync.';
  }

  Future<void> initialize({
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    final existingClient = _tryGetExistingClient();
    if (existingClient != null) {
      _supabaseReady = true;
      return;
    }

    _supabaseUrl = supabaseUrl ?? const String.fromEnvironment('SUPABASE_URL');
    _supabaseAnonKey =
        supabaseAnonKey ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      debugPrint(configurationMessage);
      return;
    }

    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      _supabaseReady = true;
      debugPrint('Supabase initialized for Budget Buddy.');
    } catch (error) {
      _supabaseReady = false;
      debugPrint('Supabase initialization failed: $error');
    }
  }

  void primeLocalRecord(UserProgressRecord record) {
    _cachedRecords[record.id] = record;
    _localProgressController.add(record);
  }

  Future<UserProgressRecord> fetchUserProgress(
    String userId, {
    UserProgressRecord? fallback,
  }) async {
    final seededRecord =
        fallback ?? _cachedRecords[userId] ?? UserProgressRecord.defaults(userId);

    if (!_supabaseReady) {
      return seededRecord;
    }

    try {
      final response = await Supabase.instance.client
          .from(userProgressTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        await ensureUserProgressRow(userId: userId, defaults: seededRecord);
        return seededRecord;
      }

      final record = UserProgressRecord.fromJson(response);
      _cachedRecords[userId] = record;
      return record;
    } catch (error) {
      debugPrint('Failed to fetch user progress: $error');
      return seededRecord;
    }
  }

  Future<void> ensureUserProgressRow({
    required String userId,
    UserProgressRecord? defaults,
  }) async {
    final record =
        defaults ?? _cachedRecords[userId] ?? UserProgressRecord.defaults(userId);
    _cachedRecords[userId] = record;
    _localProgressController.add(record);

    if (!_supabaseReady) {
      return;
    }

    try {
      await Supabase.instance.client
          .from(userProgressTable)
          .upsert(record.toUpsertJson(), onConflict: 'id');
    } catch (error) {
      debugPrint('Failed to ensure user progress row: $error');
    }
  }

  Stream<UserProgressRecord> watchUserProgress(String userId) async* {
    final cached = _cachedRecords[userId];
    if (cached != null) {
      yield cached;
    }

    if (_supabaseReady) {
      yield* Supabase.instance.client
          .from(userProgressTable)
          .stream(primaryKey: const ['id'])
          .eq('id', userId)
          .map((rows) {
            if (rows.isEmpty) {
              return _cachedRecords[userId] ?? UserProgressRecord.defaults(userId);
            }

            final record = UserProgressRecord.fromJson(rows.first);
            _cachedRecords[userId] = record;
            return record;
          });
      return;
    }

    yield* _localProgressController.stream.where((record) => record.id == userId);
  }

  Future<DatabaseSyncResult> syncGameplayResults(Map<String, dynamic> data) async {
    final userId = (data['id'] ?? data['user_id'] ?? '').toString();
    if (userId.isEmpty) {
      return const DatabaseSyncResult(
        synced: false,
        queued: false,
        message: 'Missing user id for cloud sync.',
      );
    }

    final fallback = _cachedRecords[userId] ?? UserProgressRecord.defaults(userId);
    final normalized = _normalizeRecord(data, fallback: fallback);
    _cachedRecords[userId] = normalized;
    _localProgressController.add(normalized);

    if (!_supabaseReady) {
      return const DatabaseSyncResult(
        synced: false,
        queued: false,
        message: 'Supabase not configured. Saved locally only.',
      );
    }

    await _flushPendingQueue();

    final payload = normalized.toUpsertJson();
    try {
      await Supabase.instance.client
          .from(userProgressTable)
          .upsert(payload, onConflict: 'id');
      return const DatabaseSyncResult(
        synced: true,
        queued: false,
        message: 'Saved to Postgres.',
      );
    } catch (error) {
      _pendingQueue.add(payload);
      return DatabaseSyncResult(
        synced: false,
        queued: true,
        queuedCount: _pendingQueue.length,
        message: 'Cloud save queued: $error',
      );
    }
  }

  Future<void> _flushPendingQueue() async {
    if (!_supabaseReady || _pendingQueue.isEmpty) {
      return;
    }

    final queuedPayloads = List<Map<String, dynamic>>.from(_pendingQueue);
    _pendingQueue.clear();

    for (final payload in queuedPayloads) {
      try {
        await Supabase.instance.client
            .from(userProgressTable)
            .upsert(payload, onConflict: 'id');
      } catch (_) {
        _pendingQueue.insert(0, payload);
        break;
      }
    }
  }

  UserProgressRecord _normalizeRecord(
    Map<String, dynamic> data, {
    required UserProgressRecord fallback,
  }) {
    final rawSpendingHabits = _readMap(data['spending_habits']);
    final username = (data['username'] ?? '').toString().trim().isNotEmpty
        ? data['username'].toString().trim()
        : (rawSpendingHabits['username'] ?? fallback.username).toString();

    return fallback.copyWith(
      username: username,
      xp: data['xp'] == null ? fallback.xp : _readInt(data['xp']),
      gold: data['gold'] == null ? fallback.gold : _readInt(data['gold']),
      literacyScore: data['literacy_score'] == null && data['literacy_points'] == null
          ? fallback.literacyScore
          : _readInt(data['literacy_score'] ?? data['literacy_points']),
      spendingHabits: rawSpendingHabits.isEmpty
          ? <String, dynamic>{...fallback.spendingHabits, 'username': username}
          : <String, dynamic>{...rawSpendingHabits, 'username': username},
      personalityType: (data['personality_type'] ?? '').toString().trim().isEmpty
          ? fallback.personalityType
          : data['personality_type'].toString().trim(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  SupabaseClient? _tryGetExistingClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static int _readInt(dynamic value) {
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

  static Map<String, dynamic> _readMap(dynamic value) {
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
}
