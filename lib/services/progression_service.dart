import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ProgressionSyncResult {
  const ProgressionSyncResult({
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

/// Handles cloud persistence of user economy progression to Base44.
class ProgressionService {
  ProgressionService({
    required this.baseUrl,
    required this.userId,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String userId;
  final String apiKey;
  final http.Client _client;

  static final List<Map<String, dynamic>> _pendingQueue =
      <Map<String, dynamic>>[];

  static const Duration _requestTimeout = Duration(seconds: 12);

  Future<ProgressionSyncResult> syncProgression(
    int newGold,
    int newXp,
    int newLiteracyPoints,
  ) async {
    await _flushPendingQueue();

    final payload = <String, dynamic>{
      'user_id': userId,
      'gold': newGold,
      'xp': newXp,
      'literacy_points': newLiteracyPoints,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _sendProgression(payload);
      return const ProgressionSyncResult(synced: true, queued: false);
    } catch (error) {
      _pendingQueue.add(payload);
      return ProgressionSyncResult(
        synced: false,
        queued: true,
        queuedCount: _pendingQueue.length,
        message: 'Sync queued: $error',
      );
    }
  }

  Future<void> _flushPendingQueue() async {
    if (_pendingQueue.isEmpty) {
      return;
    }

    final queueSnapshot = List<Map<String, dynamic>>.from(_pendingQueue);
    _pendingQueue.clear();

    for (final queuedPayload in queueSnapshot) {
      try {
        await _sendProgression(queuedPayload);
      } catch (_) {
        _pendingQueue.insert(0, queuedPayload);
        break;
      }
    }
  }

  Future<void> _sendProgression(Map<String, dynamic> payload) async {
    final patchUri = Uri.parse('$baseUrl/users/$userId/progression');
    final response = await _client
        .patch(
          patchUri,
          headers: _headers(),
          body: jsonEncode(payload),
        )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    // Fallback for APIs that prefer creating/upserting via POST.
    if (response.statusCode == 404 || response.statusCode == 405) {
      final postUri = Uri.parse('$baseUrl/progression');
      final postResponse = await _client
          .post(
            postUri,
            headers: _headers(),
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      if (postResponse.statusCode >= 200 && postResponse.statusCode < 300) {
        return;
      }

      throw Exception(
        'Base44 POST failed (${postResponse.statusCode}): ${postResponse.body}',
      );
    }

    throw Exception('Base44 PATCH failed (${response.statusCode}): ${response.body}');
  }

  Map<String, String> _headers() {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'x-api-key': apiKey,
    };
  }

  void dispose() {
    _client.close();
  }
}
