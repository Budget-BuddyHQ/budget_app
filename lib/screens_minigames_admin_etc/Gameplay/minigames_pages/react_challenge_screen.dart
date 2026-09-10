import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../services_backend_and_other_services/local_web_game_server.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/orientation_scope.dart';

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
    this.isCompleted = false,
  });

  final String gameId;
  final String difficulty;
  final int playerLevel;
  final String userId;
  final bool isCompleted;

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
        return decoded.map((key, value) => MapEntry(key.toString(), value));
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
          .applyChallengePayload(<String, dynamic>{
            ...payload,
            'gold_earned': goldEarned,
            'xp_earned': xpEarned,
            'literacy_points_earned': literacyEarned,
            'title': payload['title'] ?? 'React Challenge Reward',
            'description':
                payload['description'] ??
                'Mini-game rewards synced from the local React challenge.',
          })
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
        // The cloud status has its own pill on this screen (`_cloudMessage`)
        // and does not need to be in the reward line as well.
        message: '+$goldEarned gold • +$xpEarned XP',
        icon: status == 'victory'
            ? Icons.workspace_premium_rounded
            : Icons.flag_rounded,
        accent: const Color(0xFF85EFAC),
        soundEffect: status == 'victory'
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
        message:
            'Challenge reward sync hit a problem. Your next sync will retry.',
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
              backgroundColor: AppTheme.panelStrong,
              title: Text(
                'Exit battle?',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
    const orientationScope = <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];

    if (!_supportsEmbeddedWebView) {
      return OrientationScope(
        orientations: orientationScope,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _confirmExit();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop(result);
            }
          },
          child: _NativeBudgetBattleChallenge(
            isCompleted: widget.isCompleted,
            onComplete: (payload) => _handlePayload(payload),
          ),
        ),
      );
    }

    return OrientationScope(
      orientations: orientationScope,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final shouldPop = await _confirmExit();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result);
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.deepForest,
          appBar: AppBar(
            title: Text(
              'React Challenge',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.darkForest,
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
      ),
    );
  }
}

class _NativeBudgetBattleChallenge extends StatefulWidget {
  const _NativeBudgetBattleChallenge({
    required this.onComplete,
    this.isCompleted = false,
  });

  final Future<void> Function(Map<String, dynamic>) onComplete;
  final bool isCompleted;

  @override
  State<_NativeBudgetBattleChallenge> createState() =>
      _NativeBudgetBattleChallengeState();
}

class _NativeBudgetBattleChallengeState
    extends State<_NativeBudgetBattleChallenge> {
  static const int _questionsPerRun = 5;
  static const String _questionBankAsset = AppAssets.reactChallengeQuestions;
  static const List<_ChallengeQuestion>
  _fallbackQuestions = <_ChallengeQuestion>[
    _ChallengeQuestion(
      prompt: 'Your grocery cart is \$12 over budget. Which swap helps most?',
      choices: <String>[
        'Trade bottled water for a reusable bottle',
        'Buy the same snacks in smaller bags',
        'Remove the store-brand rice',
      ],
      correctIndex: 0,
      explanation:
          'A reusable bottle cuts a repeated cost without removing a need.',
    ),
    _ChallengeQuestion(
      prompt:
          'A subscription renews tomorrow, but you have not used it in 3 months.',
      choices: <String>[
        'Cancel before renewal',
        'Wait until next month',
        'Upgrade to the annual plan',
      ],
      correctIndex: 0,
      explanation:
          'Canceling unused recurring charges protects future cash flow.',
    ),
    _ChallengeQuestion(
      prompt:
          'You get paid Friday and rent is due Monday. What should happen first?',
      choices: <String>[
        'Set aside rent money',
        'Buy a new game now',
        'Leave the full check in spending money',
      ],
      correctIndex: 0,
      explanation:
          'Needs with fixed due dates should be protected before wants.',
    ),
    _ChallengeQuestion(
      prompt:
          'Two items are on sale. One is a planned need, one is an impulse want.',
      choices: <String>[
        'Buy the planned need',
        'Buy both because they are discounted',
        'Buy the want before the sale ends',
      ],
      correctIndex: 0,
      explanation:
          'A sale only saves money when the purchase was already useful.',
    ),
    _ChallengeQuestion(
      prompt: 'You have \$25 left for the week. Which choice is strongest?',
      choices: <String>[
        'Plan meals and keep \$5 aside',
        'Spend all \$25 today',
        'Ignore the balance until payday',
      ],
      correctIndex: 0,
      explanation: 'Planning plus a small cushion makes the money last longer.',
    ),
  ];

  late List<_ChallengeQuestion> _questions;

  int _questionIndex = 0;
  int _correctAnswers = 0;
  int? _selectedIndex;
  bool _roundComplete = false;
  bool _isLoadingQuestions = true;
  bool _isSubmitting = false;

  final Map<int, int> _userAnswers = {};

  _ChallengeQuestion get _currentQuestion => _questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    _roundComplete = false;

    if (widget.isCompleted) {
      _roundComplete = true;
    }
    _questions = _dailyQuestionSet(_fallbackQuestions);
    unawaited(_loadQuestionBank());
  }

  Future<void> _loadQuestionBank() async {
    try {
      final rawQuestions = await rootBundle.loadString(_questionBankAsset);
      final decoded = jsonDecode(rawQuestions);
      if (decoded is! List) {
        throw const FormatException('Question bank must be a JSON list.');
      }

      final loadedQuestions = decoded
          .whereType<Map>()
          .map(
            (questionJson) => _ChallengeQuestion.fromJson(
              questionJson.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((question) => question.isValid)
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _questions = _dailyQuestionSet(
          loadedQuestions.isEmpty ? _fallbackQuestions : loadedQuestions,
        );
        _isLoadingQuestions = false;
      });
    } catch (error) {
      debugPrint('React Challenge question bank fallback: $error');
      if (!mounted) {
        return;
      }

      setState(() {
        _questions = _dailyQuestionSet(_fallbackQuestions);
        _isLoadingQuestions = false;
      });
    }
    if (mounted) {
      setState(() {
        _userAnswers.clear();
        _correctAnswers = 0;
        _questionIndex = 0;
        _roundComplete = false;
      });
    }
  }

  List<_ChallengeQuestion> _dailyQuestionSet(
    List<_ChallengeQuestion> questionBank,
  ) {
    final today = DateTime.now();
    final seed = (today.year * 10000) + (today.month * 100) + today.day;
    final random = math.Random(seed);
    final shuffledQuestions = List<_ChallengeQuestion>.of(questionBank)
      ..shuffle(random);

    return shuffledQuestions
        .take(math.min(_questionsPerRun, shuffledQuestions.length))
        // Choice order is shuffled too — the bank leans heavily toward the
        // right answer being listed first, so leaving it as authored would
        // let a player win by always tapping the top choice.
        .map((question) => question.withShuffledChoices(random))
        .toList(growable: false);
  }

  void _chooseAnswer(int index) {
    if (_selectedIndex != null || _roundComplete) {
      return;
    }

    final isCorrect = index == _currentQuestion.correctIndex;
    HapticFeedback.lightImpact();
    AppSoundService.play(
      isCorrect ? AppSoundEffect.success : AppSoundEffect.error,
    );

    setState(() {
      _selectedIndex = index;
      _userAnswers[_questionIndex] = index; // Stores user selection
      if (isCorrect) {
        _correctAnswers += 1;
      }
    });
  }

  void _advance() {
    if (_selectedIndex == null) {
      return;
    }

    if (_questionIndex == _questions.length - 1) {
      setState(() {
        _roundComplete = true;
      });
      return;
    }

    setState(() {
      _questionIndex += 1;
      _selectedIndex = null;
    });
  }

  void _resetQuiz() {
    setState(() {
      _roundComplete = false;
      _questionIndex = 0;
      _correctAnswers = 0;
      _userAnswers
          .clear(); // Resets the map cleanly so no questions show as answered
    });
  }

  Future<void> _bankRewards() async {
    if (_isSubmitting) {
      return;
    }

    final passed = _correctAnswers >= 3;
    final gold = 45 + (_correctAnswers * 18);
    final xp = 35 + (_correctAnswers * 14);
    final literacyPoints = 12 + (_correctAnswers * 6);

    setState(() {
      _isSubmitting = true;
    });

    // `HabitDateKeys` rather than a hand-rolled `yyyy-MM-dd`, which is what
    // this was. The two happened to agree, but a date format written out
    // twice is a date format that eventually disagrees with itself — and
    // when it does, the dated key silently never matches and the challenge
    // is either always done or never done.
    final today = HabitDateKeys.todayKey();
    final stats = context.read<UserStatsController>().stats;

    // Dated only.
    //
    // This used to add an **undated** `daily_budget_battle` as well, and
    // `isTodayChallengeCompleted` accepted it — so the first win pinned the
    // card to "Challenge cleared" permanently. See that getter.
    //
    // Old day keys are dropped as they go out of range: this list lives in
    // `spending_habits` and is written back on every completion, so an
    // unbounded one is a row that grows by an entry a day forever.
    final updatedTasks = <String>[
      for (final task in stats.completedChallengeTasks)
        if (!task.startsWith('daily_budget_battle')) task,
      for (final key in HabitDateKeys.lastDayKeys(30))
        if (stats.completedChallengeTasks.contains('daily_budget_battle_$key'))
          'daily_budget_battle_$key',
      'daily_budget_battle_$today',
    ];

    await widget.onComplete(<String, dynamic>{
      'status': passed ? 'victory' : 'defeat',
      'gold': gold,
      'xp': xp,
      'literacy_points': literacyPoints,
      'title': 'React Challenge Reward',
      'description':
          'Answered $_correctAnswers of ${_questions.length} daily Budget Battle prompts correctly.',
      'spending_habits': {'completed_challenge_tasks': updatedTasks},
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        title: Text(
          'React Challenge',
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.darkForest,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _roundComplete
                    ? _buildResults()
                    : _isLoadingQuestions
                    ? _buildLoadingQuestions()
                    : _buildQuestion(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingQuestions() {
    return Container(
      key: const ValueKey<String>('loading_questions'),
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.getPuffyDecoration(
        accent: const Color(0xFF85EFAC),
        fillColor: AppTheme.panelStrong,
        restAlpha: 0.14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF85EFAC)),
          const SizedBox(height: 16),
          Text(
            'Loading daily challenge',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _currentQuestion;
    final selectedIndex = _selectedIndex;
    final progress = (_questionIndex + 1) / _questions.length;

    return Container(
      key: ValueKey<int>(_questionIndex),
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.getPuffyDecoration(
        accent: const Color(0xFF85EFAC),
        fillColor: AppTheme.panelStrong,
        restAlpha: 0.14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${_questionIndex + 1} of ${_questions.length}',
                  style: AppTheme.numeric(
                    color: const Color(0xFF85EFAC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Score $_correctAnswers',
                style: AppTheme.numeric(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF85EFAC),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.prompt,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < question.choices.length; index += 1) ...[
            _ChallengeChoiceButton(
              label: question.choices[index],
              isCorrect: index == question.correctIndex,
              isSelected: selectedIndex == index,
              hasAnswered: selectedIndex != null,
              onPressed: () => _chooseAnswer(index),
            ),
            if (index != question.choices.length - 1)
              const SizedBox(height: 10),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: selectedIndex == null
                ? const SizedBox(height: 18)
                : Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(
                      question.explanation,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedIndex == null ? null : _advance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF85EFAC),
                foregroundColor: const Color(0xFF103225),
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _questionIndex == _questions.length - 1
                    ? 'See Results'
                    : 'Next Question',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(int index) {
    final question = _questions[index];
    final userIndex = _userAnswers[index];
    final isCorrect = userIndex == question.correctIndex;
    final userAnswerText = userIndex != null
        ? question.choices[userIndex]
        : 'No Answer';
    final correctAnswerText = question.choices[question.correctIndex];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
            : const Color(0xFFE57373).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE57373),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Q${index + 1}: ${question.prompt}',
                  style: AppTheme.numeric(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your Answer: $userAnswerText',
            style: TextStyle(
              color: isCorrect ? Colors.white70 : const Color(0xFFEF9A9A),
              fontSize: 12.5,
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 2),
            Text(
              'Correct Answer: $correctAnswerText',
              style: const TextStyle(
                color: Color(0xFFA5D6A7),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final passed = _correctAnswers >= 3;
    final title = passed ? 'Victory!' : 'Run Complete';
    final message = passed
        ? 'You made smart spending calls under pressure.'
        : 'You finished the run and earned practice rewards.';

    return Container(
      key: const ValueKey<String>('results'),
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.getPuffyDecoration(
        accent: const Color(0xFF85EFAC),
        fillColor: AppTheme.panelStrong,
        restAlpha: 0.16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? Icons.workspace_premium_rounded : Icons.flag_rounded,
            color: const Color(0xFF85EFAC),
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$message You answered $_correctAnswers of ${_questions.length} correctly.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),

          // Iterates through questions to render the breakdown cards
          for (var i = 0; i < _questions.length; i++) ...[
            _buildQuestionReviewCard(i),
            if (i != _questions.length - 1) const SizedBox(height: 10),
          ],

          const SizedBox(height: 22),

          // Show "Try Again" if already completed today; show "Bank Rewards" for first-time runs
          if (widget.isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF85EFAC),
                  foregroundColor: const Color(0xFF103225),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Try Again (Practice Mode)'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text('Close'),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _bankRewards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF85EFAC),
                  foregroundColor: const Color(0xFF103225),
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF85EFAC),
                        ),
                      )
                    : const Text('Bank Rewards'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChallengeChoiceButton extends StatelessWidget {
  const _ChallengeChoiceButton({
    required this.label,
    required this.isCorrect,
    required this.isSelected,
    required this.hasAnswered,
    required this.onPressed,
  });

  final String label;
  final bool isCorrect;
  final bool isSelected;
  final bool hasAnswered;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final Color foregroundColor;
    final IconData? icon;

    if (hasAnswered && isCorrect) {
      backgroundColor = const Color(0xFF85EFAC);
      borderColor = const Color(0xFF85EFAC);
      foregroundColor = const Color(0xFF103225);
      icon = Icons.check_circle_rounded;
    } else if (hasAnswered && isSelected) {
      backgroundColor = const Color(0xFFFF8A80);
      borderColor = const Color(0xFFFF8A80);
      foregroundColor = const Color(0xFF3B1210);
      icon = Icons.cancel_rounded;
    } else {
      backgroundColor = Colors.white.withValues(alpha: 0.06);
      borderColor = Colors.white.withValues(alpha: 0.12);
      foregroundColor = Colors.white;
      icon = null;
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: hasAnswered ? null : onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 12),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChallengeQuestion {
  const _ChallengeQuestion({
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  factory _ChallengeQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    final choices = rawChoices is List
        ? rawChoices.map((choice) => choice.toString()).toList(growable: false)
        : const <String>[];

    final rawCorrectIndex = json['correctIndex'] ?? json['correct_index'];
    final correctIndex = rawCorrectIndex is num
        ? rawCorrectIndex.toInt()
        : int.tryParse(rawCorrectIndex?.toString() ?? '') ?? -1;

    return _ChallengeQuestion(
      prompt: (json['prompt'] ?? '').toString(),
      choices: choices,
      correctIndex: correctIndex,
      explanation: (json['explanation'] ?? '').toString(),
    );
  }

  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String explanation;

  bool get isValid =>
      prompt.trim().isNotEmpty &&
      choices.length >= 2 &&
      correctIndex >= 0 &&
      correctIndex < choices.length &&
      explanation.trim().isNotEmpty;

  /// Same question with choice order shuffled and [correctIndex] updated to
  /// match. The authored bank (and its fallback) skews toward putting the
  /// right answer first, so without this a player could score well above
  /// chance just by always tapping the top choice.
  _ChallengeQuestion withShuffledChoices(math.Random random) {
    final correctText = choices[correctIndex];
    final shuffled = List<String>.of(choices)..shuffle(random);
    return _ChallengeQuestion(
      prompt: prompt,
      choices: shuffled,
      correctIndex: shuffled.indexOf(correctText),
      explanation: explanation,
    );
  }
}

class _ChallengeLoadingOverlay extends StatelessWidget {
  const _ChallengeLoadingOverlay({required this.controller});

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
