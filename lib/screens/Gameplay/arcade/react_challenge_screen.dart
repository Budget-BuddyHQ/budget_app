import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../controllers/user_stats_controller.dart';
import '../../../services/app_sound_service.dart';
import '../../../services/local_web_game_server.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/game_toast.dart';

class ReactGameCloseResult {
  const ReactGameCloseResult({
    required this.status,
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyPointsEarned,
    required this.syncState,
  });

  final String status;
  final int goldEarned;
  final int xpEarned;
  final int literacyPointsEarned;
  final SyncState syncState;
}

class ReactChallengeScreen extends StatefulWidget {
  const ReactChallengeScreen({
    super.key,
    required this.gameId,
    required this.difficulty,
    required this.playerLevel,
    required this.userId,
  });

  final String gameId;
  final String difficulty;
  final int playerLevel;
  final String userId;

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
  });
}

class _ReactChallengeScreenState extends State<ReactChallengeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;
  final LocalWebGameServer _localServer = LocalWebGameServer();
  WebViewController? _webViewController;

  bool _isLoading = true;
  bool _isSyncing = false;
  bool _didHandleGameOver = false;
  String? _loadError;
  String? _cloudMessage;
  Timer? _messageTimer;

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
      unawaited(_loadEmbeddedChallenge());
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _loadingController.dispose();
    unawaited(_localServer.stop());
    super.dispose();
  }

  Future<void> _loadEmbeddedChallenge() async {
    try {
      final launchUri = await _localServer.start(
        queryParameters: <String, String>{
          'gameId': widget.gameId,
          'difficulty': widget.difficulty,
          'playerLevel': widget.playerLevel.toString(),
          'userId': widget.userId,
        },
      );

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _isLoading = true;
                _loadError = null;
              });
            },
            onPageFinished: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (error) {
              if (!mounted) {
                return;
              }
              setState(() {
                _isLoading = false;
                _loadError = error.description;
              });
            },
          ),
        )
        ..addJavaScriptChannel(
          'GameBridge',
          onMessageReceived: _onBridgeMessage,
        )
        ..addJavaScriptChannel(
          'BudgetBuddyBridge',
          onMessageReceived: _onBridgeMessage,
        )
        ..loadRequest(launchUri);

      if (!mounted) {
        return;
      }
      setState(() {
        _webViewController = controller;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load the local React challenge bundle: $error';
      });
    }
  }

  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    final payload = _decodePayload(message.message);
    if (payload == null) {
      return;
    }

    await _handlePayload(payload);
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

  Future<void> _handlePayload(Map<String, dynamic> payload) async {
  if (_didHandleGameOver) {
    return;
  }

  final status = (payload['status'] ?? '').toString().trim().toLowerCase();
  if (!_isTerminalStatus(status)) {
    return;
  }

  _didHandleGameOver = true;

  final userStatsController = context.read<UserStatsController>();
  final goldEarned = _readInt(payload['gold_earned'] ?? payload['gold']);
  final xpEarned = _readInt(payload['xp_earned'] ?? payload['xp']);
  final literacyEarned = _readInt(
    payload['literacy_points_earned'] ?? payload['literacy_points'],
  );

  _messageTimer?.cancel();

  if (mounted) {
    setState(() {
      _isSyncing = true;
      _cloudMessage = 'Saving to Cloud...';
    });
  }

  try {
    final actionResult = await userStatsController
        .applyChallengePayload(
          <String, dynamic>{
            ...payload,
            'gold_earned': goldEarned,
            'xp_earned': xpEarned,
            'literacy_points_earned': literacyEarned,
            'title': payload['title'] ?? 'React Challenge Reward',
            'description': payload['description'] ??
                'Mini-game rewards synced from the local React challenge.',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
      _cloudMessage = actionResult.message;
    });

    HapticFeedback.lightImpact();
    GameToast.show(
      context,
      title: status == 'victory' ? 'Victory!' : 'Battle complete',
      message:
          '+$goldEarned gold • +$xpEarned XP • ${actionResult.message}',
      icon: status == 'victory'
          ? Icons.workspace_premium_rounded
          : Icons.flag_rounded,
      accent: const Color(0xFF85EFAC),
      soundEffect:
          status == 'victory'
              ? AppSoundEffect.celebration
              : AppSoundEffect.shutdown,
    );

    _messageTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _cloudMessage = null;
      });
    });

    Navigator.of(context).pop(
      ReactGameCloseResult(
        status: status,
        goldEarned: goldEarned,
        xpEarned: xpEarned,
        literacyPointsEarned: literacyEarned,
        syncState: actionResult.syncState,
      ),
    );
  } catch (e) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
      _cloudMessage = 'Save failed';
    });

    GameToast.show(
      context,
      title: 'Save failed',
      message: 'Challenge reward sync hit a problem. Your next sync will retry.',
      icon: Icons.cloud_off_rounded,
      accent: const Color(0xFFFF8A80),
      soundEffect: AppSoundEffect.shutdown,
    );
  }
}

  bool _isTerminalStatus(String status) {
    const terminalStatuses = <String>{
      'victory',
      'defeat',
      'win',
      'won',
      'loss',
      'lose',
      'lost',
      'complete',
      'completed',
      'game_over',
    };
    return terminalStatuses.contains(status);
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

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF214C3D),
              title: const Text(
                'Exit battle?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Leaving now will close the active Budget Battle session.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsEmbeddedWebView) {
      return WillPopScope(
        onWillPop: _confirmExit,
        child: _NativeChallengeFallback(
          onComplete: (payload) => _handlePayload(payload),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _confirmExit();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07150F),
        appBar: AppBar(
          title: const Text('React Challenge'),
          backgroundColor: const Color(0xFF1A4D3D),
          foregroundColor: Colors.white,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_webViewController != null && _loadError == null)
              WebViewWidget(controller: _webViewController!),

            if (_loadError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
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
                child: (_isSyncing || _cloudMessage != null)
                    ? _CloudSyncBadge(
                        key: ValueKey<String>(
                          '${_isSyncing}_${_cloudMessage ?? ''}',
                        ),
                        message: _cloudMessage ?? 'Saving to Cloud...',
                        isLoading: _isSyncing,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeChallengeFallback extends StatelessWidget {
  const _NativeChallengeFallback({
    required this.onComplete,
  });

  final Future<void> Function(Map<String, dynamic>) onComplete;

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Challenge Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'WebView isn’t available on this platform, so Budget Buddy falls back to a local native challenge panel instead of sending you to a dead external URL.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onComplete(
                        const <String, dynamic>{
                          'status': 'victory',
                          'gold': 120,
                          'xp': 90,
                          'literacy_points': 30,
                          'title': 'Fallback Challenge Reward',
                          'description': 'Completed the native fallback challenge.',
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF85EFAC),
                        foregroundColor: const Color(0xFF1A4D3D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Complete Challenge'),
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

