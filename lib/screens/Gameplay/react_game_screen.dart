import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/user_progress_state.dart';
import '../../services/progression_service.dart';

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
  final ProgressionSyncResult syncResult;
}

class ReactGameScreen extends StatefulWidget {
  const ReactGameScreen({
    super.key,
    required this.gameId,
    required this.difficulty,
    required this.playerLevel,
    required this.userId,
    this.reactAppBaseUrl = 'https://your-react-game-app.vercel.app',
    this.base44BaseUrl = 'https://api.base44.app/v1',
    this.base44ApiKey = 'REPLACE_WITH_BASE44_API_KEY',
  });

  final String gameId;
  final String difficulty;
  final int playerLevel;
  final String userId;
  final String reactAppBaseUrl;
  final String base44BaseUrl;
  final String base44ApiKey;

  @override
  State<ReactGameScreen> createState() => _ReactGameScreenState();
}

class _ReactGameScreenState extends State<ReactGameScreen> {
  late final WebViewController _controller;
  late final ProgressionService _progressionService;

  bool _isLoading = true;
  bool _didHandleGameOver = false;
  String? _loadError;

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
    _progressionService = ProgressionService(
      baseUrl: widget.base44BaseUrl,
      userId: widget.userId,
      apiKey: widget.base44ApiKey,
    );

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
    _progressionService.dispose();
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

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    } catch (_) {
      // Ignore malformed bridge messages.
      return;
    }

    if (payload == null) {
      return;
    }

    final status = (payload['status'] ?? '').toString().toLowerCase().trim();
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
    if (!gameOverStatuses.contains(status)) {
      return;
    }

    _didHandleGameOver = true;

    final goldEarned = _readInt(payload['gold_earned']);
    final xpEarned = _readInt(payload['xp_earned']);
    final literacyPointsEarned = _readInt(
      payload['literacy_points_earned'] ?? payload['literacy_points'],
    );

    final userProgress = UserProgressState.instance;
    userProgress.applyGameRewards(
      goldEarned: goldEarned,
      xpEarned: xpEarned,
      literacyPointsEarned: literacyPointsEarned,
    );

    final syncResult = await _progressionService.syncProgression(
      userProgress.gold,
      userProgress.xp,
      userProgress.literacyPoints,
    );

    if (!mounted) {
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
        ],
      ),
    );
  }
}
