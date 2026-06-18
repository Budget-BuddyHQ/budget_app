import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/adventure_state_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../game_prodigy/budget_buddy_game.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../widgets_custom_lotties/orientation_scope.dart';

class GameCanvas extends StatefulWidget {
  const GameCanvas({
    super.key,
    this.mapId,
    this.initialPosition,
    this.skinAssetPath,
  });

  final String? mapId;
  final Offset? initialPosition;
  final String? skinAssetPath;

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas> {
  late final BudgetBuddyGame _game;
  int? _movementPointer;
  Offset? _movementStart;
  Offset? _lastMovementPosition;
  bool _isDraggingMovement = false;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastProgressKey;
  bool _saveInFlight = false;
  ({String mapId, Vector2 position})? _pendingSave;

  static const double _dragDeadZone = 12;
  static const Duration _progressSaveInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    final userStats = context.read<UserStatsController>().stats;
    final equippedSkin = skinFromId(userStats.equippedSkin);
    final initialPosition =
        widget.initialPosition ?? userStats.adventurePosition;
    _game = BudgetBuddyGame(
      adventureState: context.read<AdventureStateController>(),
      mapId: widget.mapId ?? userStats.adventureMapId,
      initialPosition: initialPosition == null
          ? null
          : Vector2(initialPosition.dx, initialPosition.dy),
      skinAssetPath: widget.skinAssetPath ?? equippedSkin.assetPath,
      onProgressChanged: _queueAdventureProgressSave,
    );
  }

  void _queueAdventureProgressSave(
    String mapId,
    Vector2 position, {
    bool force = false,
  }) {
    final progressKey =
        '$mapId:${position.x.round() ~/ 8}:${position.y.round() ~/ 8}';
    final now = DateTime.now();
    if (!force &&
        progressKey == _lastProgressKey &&
        now.difference(_lastProgressSave) < _progressSaveInterval) {
      return;
    }

    if (!force && now.difference(_lastProgressSave) < _progressSaveInterval) {
      _pendingSave = (mapId: mapId, position: position.clone());
      return;
    }

    _lastProgressKey = progressKey;
    _lastProgressSave = now;
    unawaited(_saveProgress(mapId, position.clone()));
  }

  Future<void> _saveProgress(String mapId, Vector2 position) async {
    if (_saveInFlight) {
      _pendingSave = (mapId: mapId, position: position.clone());
      return;
    }

    _saveInFlight = true;
    try {
      await context.read<UserStatsController>().saveAdventureProgress(
        mapId: mapId,
        x: position.x,
        y: position.y,
      );
    } finally {
      _saveInFlight = false;
    }

    final pending = _pendingSave;
    _pendingSave = null;
    if (pending != null && mounted) {
      _queueAdventureProgressSave(pending.mapId, pending.position, force: true);
    }
  }

  Future<void> _saveCurrentProgress() async {
    final position = _game.playerWorldPosition;
    if (position == null) {
      return;
    }
    await _saveProgress(_game.mapId, position);
  }

  Future<void> _saveAndPop() async {
    HapticFeedback.lightImpact();
    await _saveCurrentProgress();
    if (mounted) {
      await Navigator.of(context).maybePop();
    }
  }

  Future<void> _showPetsModal(BuildContext context, String equippedPet) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B251C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Equipped Pet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF85EFAC).withValues(alpha: 0.26),
                    ),
                  ),
                  child: Text(
                    equippedPet,
                    style: const TextStyle(
                      color: Color(0xFF85EFAC),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _handleAnswer(BuildContext context, int index) async {
    final controller = context.read<AdventureStateController>();
    final correct = await controller.submitAnswer(index);
    if (!mounted) {
      return correct;
    }

    if (correct) {
      HapticFeedback.lightImpact();
      AppSoundService.play(AppSoundEffect.success);
    } else {
      HapticFeedback.vibrate();
      AppSoundService.play(AppSoundEffect.error);
    }
    return correct;
  }

  bool _isInJoystickZone(Offset position, Size size) {
    const joystickTouchSize = 156.0;
    return position.dx <= joystickTouchSize &&
        position.dy >= size.height - joystickTouchSize;
  }

  void _beginPointerMovement(PointerDownEvent event, Size size) {
    if (_movementPointer != null ||
        _isInJoystickZone(event.localPosition, size)) {
      return;
    }

    _movementPointer = event.pointer;
    _movementStart = event.localPosition;
    _lastMovementPosition = event.localPosition;
    _isDraggingMovement = false;
  }

  void _updatePointerMovement(PointerMoveEvent event) {
    if (_movementPointer != event.pointer) {
      return;
    }

    _lastMovementPosition = event.localPosition;
    final start = _movementStart;
    if (start == null) {
      return;
    }

    final dragOffset = event.localPosition - start;
    if (!_isDraggingMovement && dragOffset.distance < _dragDeadZone) {
      return;
    }

    _isDraggingMovement = true;
    _game.steerPlayerWithCanvasDirection(Vector2(dragOffset.dx, dragOffset.dy));
  }

  void _endPointerMovement(PointerEvent event) {
    if (_movementPointer != event.pointer) {
      return;
    }

    if (!_isDraggingMovement) {
      final destination = _lastMovementPosition ?? event.localPosition;
      _game.movePlayerTowardCanvasPosition(
        Vector2(destination.dx, destination.dy),
      );
    } else {
      _game.clearPointerMovement();
    }

    _movementPointer = null;
    _movementStart = null;
    _lastMovementPosition = null;
    _isDraggingMovement = false;
  }

  @override
  Widget build(BuildContext context) {
    return OrientationScope(
      orientations: const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF071711),
        body: SafeArea(
          child: Consumer<AdventureStateController>(
            builder: (context, adventure, _) {
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, outerConstraints) {
                              final compactFrame =
                                  outerConstraints.maxHeight < 430 ||
                                  outerConstraints.maxWidth < 760;
                              final framePadding = compactFrame ? 8.0 : 14.0;

                              return Padding(
                                padding: EdgeInsets.all(framePadding),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF85EFAC,
                                        ).withValues(alpha: 0.08),
                                        blurRadius: 28,
                                        spreadRadius: -6,
                                        offset: const Offset(0, 18),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF071711),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF85EFAC,
                                          ).withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final gameSize = Size(
                                            constraints.maxWidth,
                                            constraints.maxHeight,
                                          );

                                          return Listener(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onPointerDown: (event) =>
                                                _beginPointerMovement(
                                                  event,
                                                  gameSize,
                                                ),
                                            onPointerMove:
                                                _updatePointerMovement,
                                            onPointerUp: _endPointerMovement,
                                            onPointerCancel:
                                                _endPointerMovement,
                                            child: GameWidget<BudgetBuddyGame>(
                                              game: _game,
                                              autofocus: true,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 18,
                          left: 18,
                          right: 18,
                          child: _HudBar(
                            level: adventure.level,
                            xpProgress: adventure.xpProgress,
                            gold: adventure.gold,
                            onBack: _saveAndPop,
                            onPetsTap: () =>
                                _showPetsModal(context, adventure.equippedPet),
                          ),
                        ),
                        if (adventure.combatVisible)
                          Positioned.fill(
                            child: _CombatOverlay(
                              controller: adventure,
                              onAnswer: (index) =>
                                  _handleAnswer(context, index),
                              onVictoryComplete: () {
                                _game.resolveCombat(victory: true);
                                unawaited(_saveCurrentProgress());
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HudBar extends StatelessWidget {
  const _HudBar({
    required this.level,
    required this.xpProgress,
    required this.gold,
    required this.onBack,
    required this.onPetsTap,
  });

  final int level;
  final double xpProgress;
  final int gold;
  final VoidCallback onBack;
  final VoidCallback onPetsTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 430;

            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: stacked
                      ? WrapAlignment.start
                      : WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$gold Gold',
                      style: const TextStyle(
                        color: Color(0xFFFFD45C),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: xpProgress.clamp(0.02, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF85EFAC),
                    ),
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: onBack,
                      ),
                      const Spacer(),
                      _GlassIconButton(
                        icon: Icons.pets_rounded,
                        onTap: onPetsTap,
                        label: 'Pets',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  summary,
                ],
              );
            }

            return Row(
              children: [
                _GlassIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
                const SizedBox(width: 12),
                Expanded(child: summary),
                const SizedBox(width: 12),
                _GlassIconButton(
                  icon: Icons.pets_rounded,
                  onTap: onPetsTap,
                  label: 'Pets',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap, this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        AppSoundService.play(AppSoundEffect.navigation);
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 12 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF85EFAC)),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

typedef _CombatAnswerHandler = Future<bool> Function(int index);

class _CombatOverlay extends StatefulWidget {
  const _CombatOverlay({
    required this.controller,
    required this.onAnswer,
    required this.onVictoryComplete,
  });

  final AdventureStateController controller;
  final _CombatAnswerHandler onAnswer;
  final VoidCallback onVictoryComplete;

  @override
  State<_CombatOverlay> createState() => _CombatOverlayState();
}

class _CombatOverlayState extends State<_CombatOverlay> {
  static const Duration _stagingDuration = Duration(milliseconds: 1500);

  int? _selectedIndex;
  bool? _lastCorrect;
  bool _isStaging = false;

  Future<void> _selectAnswer(int index) async {
    if (_isStaging || widget.controller.answerResolved) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _lastCorrect = null;
      _isStaging = true;
    });

    final correct = await widget.onAnswer(index);

    if (!mounted) {
      return;
    }

    setState(() {
      _lastCorrect = correct;
    });

    await Future<void>.delayed(_stagingDuration);

    if (!mounted) {
      return;
    }

    if (correct) {
      widget.onVictoryComplete();
      return;
    }

    setState(() {
      _selectedIndex = null;
      _lastCorrect = null;
      _isStaging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final question = controller.currentQuestion;
    if (question == null) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.sizeOf(context);
    final compact = screenSize.width < 760;
    final answerLocked = _isStaging || controller.answerResolved;
    final stageColor = _lastCorrect == null
        ? const Color(0xFFFFD45C)
        : _lastCorrect!
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF6B6B);

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.28),
                  radius: 1.2,
                  colors: [
                    stageColor.withValues(alpha: 0.18),
                    const Color(0xFF071711).withValues(alpha: 0.86),
                    Colors.black.withValues(alpha: 0.76),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              86,
              compact ? 12 : 20,
              compact ? 12 : 18,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Align(
                        alignment: compact
                            ? Alignment.topCenter
                            : const Alignment(0.62, -0.94),
                        child: _BattleCard(
                          title: controller.encounterEnemyName,
                          subtitle: 'Enemy',
                          icon: Icons.bolt_rounded,
                          accent: const Color(0xFFFFD45C),
                          healthListenable: controller.enemyHealthNotifier,
                          maxHealth: controller.maxEnemyHealth,
                          alignRight: true,
                          isTakingHit: _isStaging && _lastCorrect == true,
                        ),
                      ),
                      Align(
                        alignment: compact
                            ? const Alignment(0, 0.62)
                            : const Alignment(-0.62, 0.58),
                        child: _BattleCard(
                          title: 'Budget Buddy',
                          subtitle: 'Player',
                          icon: Icons.shield_rounded,
                          accent: const Color(0xFF85EFAC),
                          healthListenable: controller.playerHealthNotifier,
                          maxHealth: controller.maxHealth,
                          alignRight: false,
                          isTakingHit: _isStaging && _lastCorrect == false,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: Icon(
                            _lastCorrect == null
                                ? Icons.sports_martial_arts_rounded
                                : _lastCorrect!
                                ? Icons.auto_awesome_rounded
                                : Icons.warning_rounded,
                            key: ValueKey<bool?>(_lastCorrect),
                            color: stageColor,
                            size: compact ? 38 : 48,
                            shadows: [
                              Shadow(
                                color: stageColor.withValues(alpha: 0.38),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _CommandMenu(
                  prompt: question.prompt,
                  options: question.options,
                  selectedIndex: _selectedIndex,
                  answerLocked: answerLocked,
                  lastCorrect: _lastCorrect,
                  feedback: controller.combatFeedback,
                  onSelect: _selectAnswer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BattleCard extends StatelessWidget {
  const _BattleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.healthListenable,
    required this.maxHealth,
    required this.alignRight,
    required this.isTakingHit,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final ValueListenable<int> healthListenable;
  final int maxHealth;
  final bool alignRight;
  final bool isTakingHit;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 760;
    final cardWidth = (screenWidth * (compact ? 0.78 : 0.34)).clamp(
      220.0,
      320.0,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isTakingHit ? 1 : 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, impact, child) {
        final shake = math.sin(impact * math.pi * 8) * 9 * impact;
        return Transform.translate(
          offset: Offset(
            isTakingHit ? shake : 0,
            isTakingHit ? -impact * 2 : 0,
          ),
          child: child,
        );
      },
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B251C).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 30,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.96),
                    accent.withValues(alpha: 0.22),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF071711), size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: alignRight
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AnimatedHealthBar(
                    healthListenable: healthListenable,
                    maxHealth: maxHealth,
                    accent: accent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHealthBar extends StatelessWidget {
  const _AnimatedHealthBar({
    required this.healthListenable,
    required this.maxHealth,
    required this.accent,
  });

  final ValueListenable<int> healthListenable;
  final int maxHealth;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: healthListenable,
      builder: (context, health, _) {
        final target = maxHealth == 0
            ? 0.0
            : (health / maxHealth).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 10,
                color: Colors.white.withValues(alpha: 0.10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: target),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent,
                              const Color(0xFFFFFFFF).withValues(alpha: 0.86),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$health / $maxHealth HP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommandMenu extends StatelessWidget {
  const _CommandMenu({
    required this.prompt,
    required this.options,
    required this.selectedIndex,
    required this.answerLocked,
    required this.lastCorrect,
    required this.feedback,
    required this.onSelect,
  });

  final String prompt;
  final List<String> options;
  final int? selectedIndex;
  final bool answerLocked;
  final bool? lastCorrect;
  final String? feedback;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF85EFAC).withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 34,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFF85EFAC),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.24,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 620;
              final children = List<Widget>.generate(
                options.length,
                (index) => _CommandButton(
                  label: options[index],
                  icon: _answerIcon(index),
                  selected: selectedIndex == index,
                  locked: answerLocked,
                  correct: selectedIndex == index ? lastCorrect : null,
                  onTap: () => onSelect(index),
                ),
              );

              if (!useGrid) {
                return Column(
                  children: children
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: child,
                        ),
                      )
                      .toList(growable: false),
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: children
                    .map(
                      (child) => SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: child,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: feedback == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey<String>(feedback!),
                    padding: const EdgeInsets.only(top: 12),
                    child: _FeedbackPill(
                      feedback: feedback!,
                      success: lastCorrect == true,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _answerIcon(int index) {
    return switch (index) {
      0 => Icons.looks_one_rounded,
      1 => Icons.looks_two_rounded,
      2 => Icons.looks_3_rounded,
      _ => Icons.looks_4_rounded,
    };
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.locked,
    required this.correct,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool locked;
  final bool? correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = correct == null
        ? selected
              ? const Color(0xFFFFD45C)
              : const Color(0xFF85EFAC)
        : correct!
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF6B6B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: locked ? 0.035 : 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.10),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: locked && !selected ? 0.58 : 0.96,
                  ),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackPill extends StatelessWidget {
  const _FeedbackPill({required this.feedback, required this.success});

  final String feedback;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final accent = success ? const Color(0xFF85EFAC) : const Color(0xFFFFB084);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.heart_broken_rounded,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedback,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
