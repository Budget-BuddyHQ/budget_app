import 'dart:async';

import 'package:budget_app/services/supabase_service.dart' show UserStats;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../models/avatar_skin.dart';
import '../../navigation/app_tab_index.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';

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
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final equippedSkin = skinFromId(stats.equippedSkin);
        final unlockedSkins = stats.unlockedSkins.toSet();

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
              const _CustomizeBackdrop(),
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
                            onOpenCase: _openCase,
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
                            itemCount: budgetBuddySkins.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemBuilder: (context, index) {
                              final skin = budgetBuddySkins[index];
                              final unlocked = unlockedSkins.contains(skin.id);
                              final equipped = stats.equippedSkin == skin.id;

                              return _SkinTile(
                                skin: skin,
                                unlocked: unlocked,
                                equipped: equipped,
                                onTap: unlocked ? () => _equipSkin(skin) : null,
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
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        equippedSkin.accent.withValues(alpha: 0.26),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: equippedSkin.accent.withValues(alpha: 0.34),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Image.asset(
                      equippedSkin.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
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
    required this.onOpenCase,
  });

  final int gold;
  final bool isOpeningCase;
  final VoidCallback onOpenCase;

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
          final action = GestureDetector(
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
                'Spend 180 gold for a Common, Rare, or Epic turtle skin.',
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

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 14),
                action,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 14),
              action,
            ],
          );
        },
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

class _CaseRollDialogState extends State<_CaseRollDialog> {
  Timer? _timer;
  AvatarSkin? _rollingSkin;
  bool _revealed = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _rollingSkin = budgetBuddySkins.first;
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _rollingSkin = budgetBuddySkins[_index % budgetBuddySkins.length];
        _index += 1;
      });
    });

    Future<void>.delayed(const Duration(seconds: 2), () {
      _timer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _rollingSkin = widget.result.skin;
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
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _rollingSkin ?? widget.result.skin;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF071711).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: preview.accent.withValues(alpha: 0.34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _revealed ? 'Case Opened!' : 'Rolling Emerald Case...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Image.asset(
                  preview.assetPath,
                  key: ValueKey<String>(preview.id),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              preview.name,
              style: TextStyle(
                color: preview.accent,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _revealed
                  ? widget.result.isNewUnlock
                      ? 'Unlocked and equipped automatically.'
                      : 'Duplicate pull — 40 gold refunded.'
                  : 'Stopping on a ${preview.rarityLabel.toLowerCase()} reward...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _revealed ? () => Navigator.of(context).pop() : null,
              child: Container(
                height: 52,
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
          ],
        ),
      ),
    );
  }
}

class _CustomizeBackdrop extends StatelessWidget {
  const _CustomizeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF071711), Color(0xFF0B231B), Color(0xFF113127)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -40,
          child: _Aura(
            color: const Color(0xFFFFD45C).withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

class _Aura extends StatelessWidget {
  const _Aura({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 80,
              spreadRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
