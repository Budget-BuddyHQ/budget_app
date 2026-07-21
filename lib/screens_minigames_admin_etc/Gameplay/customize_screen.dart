import 'dart:async';

import 'package:budget_app/services_backend_and_other_services/supabase_service.dart'
    show UserStats;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../constants/app_assets.dart';
import '../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../navigation_tools_and_animation/app_tab_index.dart';
import '../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../widgets_custom_lotties/game_toast.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({
    super.key,
    this.activeTabIndex = AppTabIndex.customize,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  bool _openingCase = false;
  bool _showCaseOdds = false;
  late AvatarSkin skin;
  bool _initalized = false;
  Future<void> _openCase() async {
    if (_openingCase) {
      return;
    }

    setState(() => _openingCase = true);
    final result = await context.read<UserStatsController>().openSkinCase();
    if (!mounted) {
      return;
    }

    setState(() => _openingCase = false);

    if (!result.success) {
      GameToast.show(
        context,
        title: 'Case unavailable',
        message: result.message,
        icon: Icons.lock_outline_rounded,
        accent: const Color(0xFFFFB084),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CaseRollDialog(result: result),
    );
  }

  Future<void> _equipSkin(AvatarSkin skin) async {
    final result = await context.read<UserStatsController>().equipSkin(skin.id);

    this.skin = skin;
    if (!mounted) {
      return;
    }

    GameToast.show(
      context,
      title: result.success ? '${skin.name} equipped' : 'Unable to equip',
      message: result.message,
      icon: result.success
          ? Icons.check_circle_rounded
          : Icons.info_outline_rounded,
      accent: skin.accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The a moving arua animation for each skin
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final equippedSkin = skinFromId(stats.equippedSkin);
        final inventorySkins = controller.unlockedAvatarSkins;

        // Initialize skin if not already set
        if (!_initalized) {
          skin = equippedSkin;
          _initalized = true;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          bottomNavigationBar: widget.onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: widget.activeTabIndex,
                  onSelected: widget.onNavSelected,
                ),
          body: Stack(
            children: [
              _CustomizeBackdrop(skin: skin),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width < 340 ? 3 : 4;
                    final childAspectRatio = width < 340 ? 0.84 : 0.76;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CharacterPreviewCard(
                            stats: stats,
                            equippedSkin: equippedSkin,
                          ),
                          const SizedBox(height: 18),
                          _StorePanel(
                            gold: stats.gold,
                            isOpeningCase: _openingCase,
                            showOdds: _showCaseOdds,
                            onOpenCase: _openCase,
                            onToggleOdds: () {
                              setState(() => _showCaseOdds = !_showCaseOdds);
                            },
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Skin Inventory',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: inventorySkins.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: childAspectRatio,
                                ),
                            itemBuilder: (context, index) {
                              final skin = inventorySkins[index];
                              final equipped = stats.equippedSkin == skin.id;

                              return _SkinTile(
                                skin: skin,
                                unlocked: true,
                                equipped: equipped,
                                onTap: () => _equipSkin(skin),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CharacterPreviewCard extends StatelessWidget {
  const _CharacterPreviewCard({
    required this.stats,
    required this.equippedSkin,
  });

  final UserStats stats;
  final AvatarSkin equippedSkin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customize',
            style: TextStyle(
              color: Color(0xFF85EFAC),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your turtle mascot',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  equippedSkin.accent.withValues(alpha: 0.22),
                  const Color(0xFF0D2B20),
                ],
              ),
              border: Border.all(
                color: equippedSkin.accent.withValues(alpha: 0.38),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _RarityAura(
                      skin: equippedSkin,
                      size: 230,
                      imageSize: 160,
                      showImage: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  equippedSkin.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${equippedSkin.rarityLabel} skin • ${stats.gold} gold ready',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorePanel extends StatelessWidget {
  const _StorePanel({
    required this.gold,
    required this.isOpeningCase,
    required this.showOdds,
    required this.onOpenCase,
    required this.onToggleOdds,
  });

  final int gold;
  final bool isOpeningCase;
  final bool showOdds;
  final VoidCallback onOpenCase;
  final VoidCallback onToggleOdds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 430;
          final openAction = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isOpeningCase
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onOpenCase();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: stacked ? double.infinity : 120,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD45C), Color(0xFF85EFAC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isOpeningCase ? 'Rolling...' : 'Open Case',
                  style: const TextStyle(
                    color: Color(0xFF062C21),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );

          final oddsAction = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleOdds();
            },
            child: Container(
              width: stacked ? double.infinity : 120,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: showOdds ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: showOdds ? 0.30 : 0.14),
                ),
              ),
              child: Center(
                child: Text(
                  showOdds ? 'Hide Odds' : 'View Odds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emerald Case',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Spend 180 gold for a Common, Rare, Epic, Legendary or Mythic turtle skin.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wallet: $gold gold',
                style: const TextStyle(
                  color: Color(0xFFFFD45C),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );

          final actions = Column(
            children: [openAction, const SizedBox(height: 10), oddsAction],
          );

          final header = stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [details, const SizedBox(height: 14), actions],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 14),
                    actions,
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: _CaseOddsPanel(),
                ),
                crossFadeState: showOdds
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CaseOddsPanel extends StatelessWidget {
  const _CaseOddsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF061D16).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Case odds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...skinCaseRarityOdds.map((odds) {
            final label = _rarityLabel(odds.rarity);
            final color = _rarityAuraColor(odds.rarity);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    odds.oddsLabel,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            );
          }),
          Text(
            'Duplicate pulls refund gold based on rarity.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.unlocked,
    required this.equipped,
    required this.onTap,
  });

  final AvatarSkin skin;
  final bool unlocked;
  final bool equipped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: equipped
                ? skin.accent.withValues(alpha: 0.52)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: equipped
              ? [
                  BoxShadow(
                    color: skin.accent.withValues(alpha: 0.14),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: ColorFiltered(
                  colorFilter: unlocked
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.srcOver,
                        )
                      : ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.55),
                          BlendMode.srcATop,
                        ),
                  child: Image.asset(skin.assetPath, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unlocked
                  ? equipped
                        ? 'Equipped'
                        : 'Tap to equip'
                  : '${skin.rarityLabel} • Locked',
              style: TextStyle(
                color: unlocked ? skin.accent : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseRollDialog extends StatefulWidget {
  const _CaseRollDialog({required this.result});

  final SkinCaseResult result;

  @override
  State<_CaseRollDialog> createState() => _CaseRollDialogState();
}

class _CaseRollDialogState extends State<_CaseRollDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrollController;
  late final Animation<double> _scrollAnimation;
  late final List<AvatarSkin> _rollSkins;
  late final Widget _rollTrack;
  bool _revealed = false;
  bool _skipped = false;

  static const double _itemWidth = 92;
  static const double _itemSpacing = 14;
  static const int _minCycles = 4;

  double get _itemExtent => _itemWidth + _itemSpacing;

  void _skipRoll() {
    if (!_revealed && !_skipped) {
      setState(() => _skipped = true);
      _scrollController.stop();
      _onReveal();
    }
  }

  @override
  void initState() {
    super.initState();
    _rollSkins = List<AvatarSkin>.generate(
      budgetBuddySkins.length * 8,
      (index) => budgetBuddySkins[index % budgetBuddySkins.length],
    );
    _rollTrack = _RollTrack(
      rollSkins: _rollSkins,
      itemWidth: _itemWidth,
      itemSpacing: _itemSpacing,
    );

    final targetIndex = budgetBuddySkins.indexWhere(
      (skin) => skin.id == widget.result.skin.id,
    );
    final safeTargetIndex = targetIndex < 0 ? 0 : targetIndex;
    final finalIndex = (_minCycles * budgetBuddySkins.length) + safeTargetIndex;
    final totalScroll = finalIndex * _itemExtent;

    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _scrollAnimation =
        Tween<double>(begin: 0, end: totalScroll).animate(
          CurvedAnimation(
            parent: _scrollController,
            curve: const Cubic(0.16, 0.86, 0.41, 1.0),
          ),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _onReveal();
          }
        });

    _scrollController.forward();
  }

  AvatarSkin _skinAtScroll(double value) {
    final index = (value / _itemExtent).round().clamp(0, _rollSkins.length - 1);
    return _rollSkins[index];
  }

  Future<void> _onReveal() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _revealed = true;
    });

    GameToast.show(
      context,
      title: widget.result.isNewUnlock ? 'New skin unlocked' : 'Duplicate pull',
      message:
          '${widget.result.skin.name} • ${widget.result.syncState.message}',
      icon: Icons.auto_awesome_rounded,
      accent: widget.result.skin.accent,
    );
  }

  int _getRefundAmount(SkinRarity rarity) {
    return oddsForRarity(rarity).refundGold;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: AnimatedBuilder(
        animation: _scrollAnimation,
        child: _rollTrack,
        builder: (context, rollTrack) {
          final preview = _revealed
              ? widget.result.skin
              : _skinAtScroll(_scrollAnimation.value);
          return LayoutBuilder(
            builder: (context, dialogConstraints) {
              // Landscape phones / short viewports don't have room for the
              // full fixed layout — shrink the reel and drop the reveal
              // aura rather than overflow.
              final compact = dialogConstraints.maxHeight < 560;
              final reelHeight = compact ? 120.0 : 188.0;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 440,
                  maxHeight: dialogConstraints.maxHeight,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(compact ? 16 : 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071711).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: preview.accent.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _revealed
                              ? 'Case Opened!'
                              : 'Rolling Emerald Case...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        // Fade the reel in so the first layout frame (before
                        // sprites/offsets settle) never flashes on screen.
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 240),
                          builder: (context, opacity, child) =>
                              Opacity(opacity: opacity, child: child),
                          child: SizedBox(
                            height: reelHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          preview.accent.withValues(
                                            alpha: 0.08,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final trackWidth = constraints.maxWidth;
                                      final offset =
                                          (_scrollAnimation.value -
                                                  (trackWidth / 2 -
                                                      _itemWidth / 2))
                                              .clamp(
                                                0.0,
                                                _rollSkins.length * _itemExtent,
                                              );

                                      return Stack(
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (rect) =>
                                                const LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black,
                                                    Colors.black,
                                                    Colors.transparent,
                                                  ],
                                                  stops: [0.0, 0.10, 0.90, 1.0],
                                                ).createShader(rect),
                                            blendMode: BlendMode.dstIn,
                                            child: SizedBox(
                                              width: trackWidth,
                                              child: ClipRect(
                                                child: Transform.translate(
                                                  offset: Offset(-offset, 0),
                                                  child: rollTrack,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: Center(
                                                child: _PulsingHighlightBorder(
                                                  width: _itemWidth + 8,
                                                  height: 172,
                                                  accent:
                                                      widget.result.skin.accent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 12),
                        if (_revealed)
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.96, end: 1.0),
                              duration: const Duration(milliseconds: 420),
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _RarityAura(
                                    skin: preview,
                                    size: compact ? 92 : 132,
                                    imageSize: compact ? 66 : 96,
                                    showImage: true,
                                  ),
                                  _RollShineOverlay(
                                    color: preview.accent,
                                    size: compact ? 92 : 132,
                                    moving: false,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        SizedBox(height: compact ? 8 : 12),
                        Text(
                          preview.name,
                          style: TextStyle(
                            color: preview.accent,
                            fontSize: compact ? 17 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preview.rarityLabel,
                          style: TextStyle(
                            color: preview.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          _revealed
                              ? widget.result.isNewUnlock
                                    ? 'Unlocked and equipped automatically.'
                                    : 'Duplicate pull — ${_getRefundAmount(preview.rarity)} gold refunded.'
                              : 'Rolling... tap Skip or wait to reveal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        Row(
                          children: [
                            if (!_revealed)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _skipRoll,
                                  child: Container(
                                    height: compact ? 44 : 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Skip',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!_revealed) const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _revealed
                                    ? () => Navigator.of(context).pop()
                                    : null,
                                child: Container(
                                  height: compact ? 44 : 52,
                                  decoration: BoxDecoration(
                                    color: _revealed
                                        ? const Color(0xFF85EFAC)
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _revealed ? 'Awesome' : 'Rolling...',
                                      style: TextStyle(
                                        color: _revealed
                                            ? const Color(0xFF062C21)
                                            : Colors.white60,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RollTrack extends StatelessWidget {
  const _RollTrack({
    required this.rollSkins,
    required this.itemWidth,
    required this.itemSpacing,
  });

  final List<AvatarSkin> rollSkins;
  final double itemWidth;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: rollSkins.map((skin) {
        return Container(
          width: itemWidth,
          margin: EdgeInsets.only(right: itemSpacing),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: skin.accent.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(skin.assetPath, fit: BoxFit.contain),
        );
      }).toList(),
    );
  }
}

class _PulsingHighlightBorder extends StatefulWidget {
  const _PulsingHighlightBorder({
    required this.width,
    required this.height,
    required this.accent,
  });

  final double width;
  final double height;
  final Color accent;

  @override
  State<_PulsingHighlightBorder> createState() =>
      _PulsingHighlightBorderState();
}

class _PulsingHighlightBorderState extends State<_PulsingHighlightBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = 0.55 + _pulseController.value * 0.45;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.88),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: glow * 0.55),
                blurRadius: 22,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomizeBackdrop extends StatelessWidget {
  const _CustomizeBackdrop({required this.skin});

  final AvatarSkin skin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/self_made_backgrounds/meadow_tile_bg.png',
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.none,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: const Color(0xFF071711).withValues(alpha: 0.55),
          ),
        ),
        Positioned(
          top: 18,
          right: 20,
          child: Opacity(
            opacity: 0.20,
            child: AmbientLottieCard(
              assetPath: AppAssets.arcadeLoopAnimation,
              semanticLabel: 'Sparkling game ambience',
              width: 110,
              height: 110,
              padding: const EdgeInsets.all(10),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              borderColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          right: 14,
          child: Opacity(
            opacity: 0.16,
            child: AmbientLottieCard(
              assetPath: AppAssets.academyLoopAnimation,
              semanticLabel: 'Floating animation accent',
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(8),
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              borderColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(top: -80, left: -40, child: _Aura(skin: skin)),
      ],
    );
  }
}

class _Aura extends StatelessWidget {
  const _Aura({required this.skin});

  final AvatarSkin skin;

  @override
  Widget build(BuildContext context) {
    final auraColor = _rarityAuraColor(skin.rarity);
    final glowIntensity = _rarityGlowIntensity(skin.rarity);

    return IgnorePointer(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: auraColor.withValues(alpha: glowIntensity),
          boxShadow: [
            BoxShadow(
              color: auraColor.withValues(alpha: glowIntensity),
              blurRadius: 80,
              spreadRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _RarityAura extends StatelessWidget {
  const _RarityAura({
    required this.skin,
    this.size = 120,
    this.imageSize = 86,
    this.showImage = false,
  });

  final AvatarSkin skin;
  final double size;
  final double imageSize;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final auraColor = _rarityAuraColor(skin.rarity);
    final glowIntensity = _rarityGlowIntensity(skin.rarity);

    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    auraColor.withValues(alpha: glowIntensity * 1.3),
                    auraColor.withValues(alpha: glowIntensity * 0.52),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: auraColor.withValues(alpha: 0.42),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: auraColor.withValues(alpha: glowIntensity * 1.5),
                    blurRadius: size * 0.34,
                    spreadRadius: size * 0.06,
                  ),
                  BoxShadow(
                    color: auraColor.withValues(alpha: glowIntensity * 0.7),
                    blurRadius: size * 0.50,
                    spreadRadius: size * 0.12,
                  ),
                ],
              ),
            ),
            if (showImage)
              SizedBox(
                width: imageSize,
                height: imageSize,
                child: Image.asset(skin.assetPath, fit: BoxFit.contain),
              ),
          ],
        ),
      ),
    );
  }
}

class _RollShineOverlay extends StatefulWidget {
  const _RollShineOverlay({
    required this.color,
    this.size = 132,
    this.moving = false,
  });

  final Color color;
  final double size;
  final bool moving;

  @override
  State<_RollShineOverlay> createState() => _RollShineOverlayState();
}

class _RollShineOverlayState extends State<_RollShineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size * 0.90,
            height: widget.size * 0.90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withValues(alpha: 0.28),
                  widget.color.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          if (widget.moving)
            AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) {
                final progress = _shineController.value;
                return Transform.rotate(
                  angle: progress * 2 * 3.141592653589793,
                  child: child,
                );
              },
              child: Center(
                child: Container(
                  width: widget.size * 0.94,
                  height: widget.size * 0.16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.08),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.32),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: widget.size * 0.08,
            left: widget.size * 0.24,
            child: _ShinePoint(size: widget.size * 0.12, color: widget.color),
          ),
          Positioned(
            right: widget.size * 0.16,
            top: widget.size * 0.18,
            child: _ShinePoint(size: widget.size * 0.10, color: widget.color),
          ),
          Positioned(
            bottom: widget.size * 0.12,
            child: _ShinePoint(size: widget.size * 0.08, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ShinePoint extends StatelessWidget {
  const _ShinePoint({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.92), color.withValues(alpha: 0.0)],
          stops: const [0.0, 0.8],
        ),
      ),
    );
  }
}

Color _rarityAuraColor(SkinRarity rarity) {
  return switch (rarity) {
    SkinRarity.common => const Color(0xFF85EFAC),
    SkinRarity.rare => const Color(0xFF58C7FF),
    SkinRarity.epic => const Color(0xFFB9A5FF),
    SkinRarity.legendary => const Color(0xFFFFD45C),
    SkinRarity.mythic => const Color(0xFFFF6B9D),
  };
}

double _rarityGlowIntensity(SkinRarity rarity) {
  return switch (rarity) {
    SkinRarity.common => 0.12,
    SkinRarity.rare => 0.18,
    SkinRarity.epic => 0.22,
    SkinRarity.legendary => 0.30,
    SkinRarity.mythic => 0.36,
  };
}

String _rarityLabel(SkinRarity rarity) {
  return switch (rarity) {
    SkinRarity.common => 'Common',
    SkinRarity.rare => 'Rare',
    SkinRarity.epic => 'Epic',
    SkinRarity.legendary => 'Legendary',
    SkinRarity.mythic => 'Mythic',
  };
}
