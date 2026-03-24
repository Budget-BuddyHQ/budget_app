import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

class ReactChallengeScreen extends StatefulWidget {
  const ReactChallengeScreen({
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
  State<ReactChallengeScreen> createState() => _ReactChallengeScreenState();
}

class ReactGameScreen extends ReactChallengeScreen {
  const ReactGameScreen({
    super.key,
    required super.gameId,
    required super.difficulty,
    required super.playerLevel,
    required super.userId,
    super.reactAppBaseUrl,
  });
}

class _ReactChallengeScreenState extends State<ReactChallengeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;
  WebViewController? _controller;

  bool _isLoading = true;
  bool _didHandleGameOver = false;
  bool _isSyncingCloud = false;
  String? _loadError;
  String? _cloudSyncMessage;
  Timer? _syncMessageTimer;

  bool get _supportsEmbeddedWebView {
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
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _loadError = null;
                });
              }
            },
            onPageFinished: (_) async {
              if (mounted) {
                setState(() => _isLoading = false);
              }
              await _injectBridgeHelpers();
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
    _loadingController.dispose();
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

  Future<void> _injectBridgeHelpers() async {
    if (_controller == null) {
      return;
    }

    try {
      await _controller!.runJavaScript('''
        window.BudgetBuddyFlutter = {
          postMessage: function(payload) {
            if (typeof payload === 'string') {
              BudgetBuddyBridge.postMessage(payload);
              return;
            }
            BudgetBuddyBridge.postMessage(JSON.stringify(payload));
          }
        };
      ''');
    } catch (_) {
      // Bridge shim is best-effort only.
    }
  }

  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    if (_didHandleGameOver) {
      return;
    }

    final payload = _decodePayload(message.message);
    if (payload == null) {
      return;
    }

    final status = (payload['status'] ?? '').toString().toLowerCase().trim();
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
      'username': userProgress.username,
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

  Future<void> _launchBrowserFallback(BuildContext context) async {
    final uri = _buildReactGameUri();
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!mounted || launched) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open the React challenge in the browser.'),
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
    if (!_supportsEmbeddedWebView) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A4D3D),
        appBar: AppBar(
          title: const Text('React Challenge'),
          backgroundColor: const Color(0xFF1A4D3D),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF254E3F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B6B59)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_browser,
                      color: Color(0xFF85EFAC),
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Launch React Challenge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      kIsWeb
                          ? 'Flutter web uses a browser fallback here. Open the React challenge in a new tab, then return once the game is connected.'
                          : 'This platform does not embed the challenge view yet, so we\'re opening the React app in your browser instead.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _launchBrowserFallback(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF85EFAC),
                          foregroundColor: const Color(0xFF1A4D3D),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Open Challenge'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07150F),
      appBar: AppBar(
        title: const Text('React Challenge'),
        backgroundColor: const Color(0xFF1A4D3D),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _loadError == null)
            WebViewWidget(controller: _controller!),
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load challenge: $_loadError',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.38),
                child: Center(
                  child: _ChallengeLoadingOverlay(
                    controller: _loadingController,
                  ),
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

class _ChallengeLoadingOverlay extends StatelessWidget {
  const _ChallengeLoadingOverlay({
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF103225).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Preparing Challenge',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(3, (index) {
                  final wave = (controller.value + (index * 0.18)) % 1.0;
                  final size = 8 + (wave * 8);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: size,
                      width: size,
                      decoration: const BoxDecoration(
                        color: Color(0xFF85EFAC),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
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
