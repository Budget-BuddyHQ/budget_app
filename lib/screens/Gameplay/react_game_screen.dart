import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/user_progress_state.dart';
import '../../services/database_service.dart';

class ReactGameCloseResult {
  const ReactGameCloseResult({
    required this.status,
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyPointsEarned,
    required this.syncResult,
  });

  final String status;
  final int goldEarned;
  final int xpEarned;
  final int literacyPointsEarned;
  final DatabaseSyncResult syncResult;
}

class ReactGameScreen extends StatefulWidget {
  const ReactGameScreen({
    super.key,
    required this.gameId,
    required this.difficulty,
    required this.playerLevel,
    required this.userId,
    this.reactAppBaseUrl = 'https://your-react-game-app.vercel.app',
  });

  final String gameId;
  final String difficulty;
  final int playerLevel;
  final String userId;
  final String reactAppBaseUrl;

  @override
  State<ReactGameScreen> createState() => _ReactGameScreenState();
}

class _ReactGameScreenState extends State<ReactGameScreen> {
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _didHandleGameOver = false;
  bool _isSyncingCloud = false;
  String? _loadError;
  String? _cloudSyncMessage;
  Timer? _syncMessageTimer;

  bool get _supportsWebView {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();

    if (_supportsWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (_) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadError = error.description;
                });
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'BudgetBuddyBridge',
          onMessageReceived: _onBridgeMessage,
        )
        ..loadRequest(_buildReactGameUri());
    }
  }

  @override
  void dispose() {
    _syncMessageTimer?.cancel();
    super.dispose();
  }

  Uri _buildReactGameUri() {
    final uri = Uri.parse(widget.reactAppBaseUrl);
    final query = Map<String, String>.from(uri.queryParameters)
      ..['source'] = 'flutter'
      ..['game_id'] = widget.gameId
      ..['difficulty'] = widget.difficulty
      ..['level'] = widget.playerLevel.toString()
      ..['user_id'] = widget.userId;

    return uri.replace(queryParameters: query);
  }

  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    if (_didHandleGameOver) {
      return;
    }

    final payload = _decodePayload(message.message);
    if (payload == null) {
      return;
    }

    final status = (payload['status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final userProgress = UserProgressState.instance;

    final goldEarned = _readInt(payload['gold_earned']);
    final xpEarned = _readInt(payload['xp_earned']);
    final literacyPointsEarned = _readInt(
      payload['literacy_points_earned'] ?? payload['literacy_points'],
    );

    if (_isTerminalStatus(status)) {
      _didHandleGameOver = true;
      userProgress.applyGameRewards(
        goldEarned: goldEarned,
        xpEarned: xpEarned,
        literacyPointsEarned: literacyPointsEarned,
      );
    }

    final syncPayload = <String, dynamic>{
      ...payload,
      'id': widget.userId,
      'user_id': widget.userId,
      'gold': userProgress.gold,
      'xp': userProgress.xp,
      'literacy_score': userProgress.literacyPoints,
      'personality_type': payload['personality_type'] ?? userProgress.personalityType,
      'spending_habits': payload['spending_habits'] ?? userProgress.spendingHabits,
    };

    final syncResult = await _syncGameplayPayload(syncPayload);

    if (!mounted || !_isTerminalStatus(status)) {
      return;
    }

    Navigator.of(context).pop(
      ReactGameCloseResult(
        status: status,
        goldEarned: goldEarned,
        xpEarned: xpEarned,
        literacyPointsEarned: literacyPointsEarned,
        syncResult: syncResult,
      ),
    );
  }

  Map<String, dynamic>? _decodePayload(String rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool _isTerminalStatus(String status) {
    const gameOverStatuses = <String>{
      'win',
      'won',
      'loss',
      'lose',
      'lost',
      'complete',
      'completed',
      'game_over',
    };
    return gameOverStatuses.contains(status);
  }

  Future<DatabaseSyncResult> _syncGameplayPayload(
    Map<String, dynamic> payload,
  ) async {
    _syncMessageTimer?.cancel();
    if (mounted) {
      setState(() {
        _isSyncingCloud = true;
        _cloudSyncMessage = 'Saving to Cloud...';
      });
    }
    UserProgressState.instance.setCloudSyncState(
      isSyncing: true,
      message: 'Saving to Cloud...',
    );

    final result = await DatabaseService.instance.syncGameplayResults(payload);
    final finalMessage = result.message ??
        (result.synced ? 'Saved to Cloud.' : 'Saved locally only.');

    if (mounted) {
      setState(() {
        _isSyncingCloud = false;
        _cloudSyncMessage = finalMessage;
      });
    }
    UserProgressState.instance.setCloudSyncState(
      isSyncing: false,
      message: finalMessage,
    );

    _syncMessageTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _cloudSyncMessage = null;
      });
      UserProgressState.instance.setCloudSyncState(
        isSyncing: false,
        message: null,
      );
    });

    return result;
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

  @override
  Widget build(BuildContext context) {
    if (!_supportsWebView) {
      return Scaffold(
        appBar: AppBar(title: const Text('React Challenge')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'WebView is supported on Android, iOS, and macOS. '
              'Run this screen on a supported mobile platform.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('React Challenge'),
        backgroundColor: const Color(0xFF1A4D3D),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_loadError == null) WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF85EFAC)),
            ),
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load game: $_loadError',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: (_isSyncingCloud || _cloudSyncMessage != null)
                  ? _CloudSyncBadge(
                      key: ValueKey<String>(
                        '${_isSyncingCloud}_${_cloudSyncMessage ?? ''}',
                      ),
                      message: _cloudSyncMessage ?? 'Saving to Cloud...',
                      isLoading: _isSyncingCloud,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudSyncBadge extends StatelessWidget {
  const _CloudSyncBadge({
    super.key,
    required this.message,
    required this.isLoading,
  });

  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF103225).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: isLoading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF85EFAC),
                    )
                  : const Icon(
                      Icons.cloud_done,
                      size: 14,
                      color: Color(0xFF85EFAC),
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
