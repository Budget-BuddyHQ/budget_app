import 'dart:async';
import 'dart:math';

import 'package:budget_app/services_backend_and_other_services/supabase_service.dart'
    show UserStats;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services_backend_and_other_services/app_sound_service.dart';

import '../../constants/app_assets.dart';
import '../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../themes_colors/app_theme.dart';
import '../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../navigation_tools_and_animation/app_tab_index.dart';
import '../../widgets_custom_lotties/ambient_lottie_card.dart';
import '../../widgets_custom_lotties/avatar_sprite.dart';
import '../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../widgets_custom_lotties/game_toast.dart';
import '../../widgets_custom_lotties/hover_lift.dart';
import '../../widgets_custom_lotties/vivid_backdrop.dart';
import '../../widgets_custom_lotties/fitted_label.dart';

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

  Future<void> _openCase() async {
    if (_openingCase) {
      return;
    }

    setState(() => _openingCase = true);
    // No sound here. Both the ratchet and the reward chime belong to
    // `_CaseRollDialog`, which owns the reel they have to line up with — see
    // the note on [_CaseRollDialogState.initState]. Starting the ratchet at
    // this point instead meant it began before the network round-trip that
    // decides the result, so on a slow connection a chunk of it had already
    // played by the time the reel appeared.
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

  void _showLockedSkinInfo(AvatarSkin skin) {
    HapticFeedback.selectionClick();
    final odds = oddsForRarity(skin.rarity);
    GameToast.show(
      context,
      title: '${skin.name} is locked',
      message:
          '${skin.rarityLabel} • ${odds.oddsLabel} from an Emerald Case. '
          'Duplicates refund ${odds.refundGold} gold.',
      icon: Icons.lock_outline_rounded,
      accent: skin.accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final equippedSkin = skinFromId(stats.equippedSkin);
        final unlockedIds = stats.unlockedSkins.toSet();

        return Scaffold(
          backgroundColor: AppTheme.deepForest,
          bottomNavigationBar: widget.onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: widget.activeTabIndex,
                  onSelected: widget.onNavSelected,
                ),
          body: Stack(
            children: [
              _CustomizeBackdrop(skin: equippedSkin),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // Landscape and tablets get a two-column split so the
                    // preview stays visible while browsing the collection.
                    final split = width >= 900;
                    final gridWidth = split ? width * 0.55 : width;

                    final header = Column(
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
                      ],
                    );

                    final collection = _SkinCollection(
                      unlockedIds: unlockedIds,
                      equippedId: stats.equippedSkin,
                      availableWidth: gridWidth - 36,
                      onEquip: _equipSkin,
                      onLockedTap: _showLockedSkinInfo,
                    );

                    if (split) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: SingleChildScrollView(child: header),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 108),
                                child: collection,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          header,
                          const SizedBox(height: 18),
                          collection,
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
          Text(
            'Customize',
            style: GoogleFonts.pixelifySans(
              color: const Color(0xFF85EFAC),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your turtle mascot',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              // Faint translucent panel instead of an opaque accent-to-dark
              // gradient. The gradient was doing most of the work of making
              // this screen feel like a solid slab of colour — a light fill
              // lets the village map read through it instead.
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(
                color: equippedSkin.accent.withValues(alpha: 0.30),
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
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${equippedSkin.rarityLabel} skin • ${stats.gold} gold ready',
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (equippedSkin.isHuman) ...[
                  const SizedBox(height: 14),
                  _BodyToggle(current: stats.villagerBody),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Switches the avatar body. Free and instant — see [VillagerBody].
class _BodyToggle extends StatelessWidget {
  const _BodyToggle({required this.current});

  final VillagerBody current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final body in VillagerBody.values) ...[
          if (body != VillagerBody.values.first) const SizedBox(width: 8),
          _BodyChip(
            body: body,
            selected: body == current,
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<UserStatsController>().setVillagerBody(body);
            },
          ),
        ],
      ],
    );
  }
}

class _BodyChip extends StatelessWidget {
  const _BodyChip({
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final VillagerBody body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF85EFAC).withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF85EFAC)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          body.label,
          style: TextStyle(
            color: selected ? const Color(0xFF85EFAC) : Colors.white70,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
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
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                // Was a flat lime→mint ramp where both stops were nearly
                // the same lightness, so it read as one washy slab. This
                // runs bright mint → deep emerald on the diagonal, which
                // gives the button an actual lit edge and a shaded base.
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9BF3CE), Color(0xFF2E9E76)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: AppTheme.puffyShadow(
                  AppTheme.greenPrimary,
                  restAlpha: 0.38,
                ),
              ),
              child: Center(
                child: Text(
                  isOpeningCase ? 'Rolling...' : 'Open Case',
                  style: GoogleFonts.pixelifySans(
                    color: const Color(0xFF06251A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emerald Case',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                // Not "turtle skin": the case draws from the whole
                // catalogue, which is four turtles, nineteen villagers and a
                // critter. Naming one family made the other twenty look like
                // they were not in the pool.
                'Spend 180 gold for a Common, Rare, Epic, Legendary or '
                'Mythic skin.',
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.80),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wallet: $gold gold',
                style: GoogleFonts.pixelifySans(
                  color: const Color(0xFFFFD45C),
                  fontWeight: FontWeight.w700,
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
          Text(
            'Case odds',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
                    style: GoogleFonts.pixelifySans(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
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

/// Small rarity pip in the corner of a skin tile. Common is left unmarked so
/// the grid does not get noisy — only the notable pulls get a badge.
class _RarityDot extends StatelessWidget {
  const _RarityDot({required this.rarity, required this.accent});

  final SkinRarity rarity;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (rarity == SkinRarity.common) {
      return const SizedBox.shrink();
    }

    final label = switch (rarity) {
      SkinRarity.rare => 'R',
      SkinRarity.epic => 'E',
      SkinRarity.legendary => 'L',
      SkinRarity.mythic => 'M',
      SkinRarity.common => '',
    };

    // The letter used to be the skin's own accent on a 22% wash of that same
    // accent — which for the darker skins meant a badge with an invisible
    // letter on it (the navy legendary measured 1.04:1). [AppTheme.tintedChip]
    // hands back the wash and a letter colour proven against it.
    final chip = AppTheme.tintedChip(accent, alpha: 0.22);

    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: chip.fill,
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: GoogleFonts.pixelifySans(
          color: chip.ink,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The full skin catalogue, grouped by family, with locked entries shown as
/// dimmed silhouettes so players can see what they are collecting toward.
class _SkinCollection extends StatelessWidget {
  const _SkinCollection({
    required this.unlockedIds,
    required this.equippedId,
    required this.availableWidth,
    required this.onEquip,
    required this.onLockedTap,
  });

  final Set<String> unlockedIds;
  final String equippedId;
  final double availableWidth;
  final ValueChanged<AvatarSkin> onEquip;
  final ValueChanged<AvatarSkin> onLockedTap;

  @override
  Widget build(BuildContext context) {
    final total = budgetBuddySkins.length;
    final owned = budgetBuddySkins
        .where((skin) => unlockedIds.contains(skin.id))
        .length;

    // Size tiles by a target width rather than a fixed column count so the
    // grid stays readable from a 320pt phone through to a tablet in landscape.
    final columns = (availableWidth / 132).floor().clamp(2, 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Collection',
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF85EFAC).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF85EFAC).withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                '$owned / $total',
                style: GoogleFonts.pixelifySans(
                  color: Color(0xFF85EFAC),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : owned / total,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
          ),
        ),
        for (final family in SkinFamily.values) ...[
          if (skinsInFamily(family).isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              family.label.toUpperCase(),
              style: GoogleFonts.pixelifySans(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: skinsInFamily(family).length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              itemBuilder: (context, index) {
                final skin = skinsInFamily(family)[index];
                final unlocked = unlockedIds.contains(skin.id);
                return _SkinTile(
                  skin: skin,
                  unlocked: unlocked,
                  equipped: equippedId == skin.id,
                  onTap: () => unlocked ? onEquip(skin) : onLockedTap(skin),
                );
              },
            ),
          ],
        ],
      ],
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
    return HoverLift(
      accent: skin.accent,
      lift: 3,
      child: GestureDetector(
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: ColorFiltered(
                        // Locked skins render as a flat silhouette so the shape
                        // is still recognisable but clearly not owned yet.
                        colorFilter: unlocked
                            ? const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.srcOver,
                              )
                            : ColorFilter.mode(
                                const Color(0xFF071711).withValues(alpha: 0.82),
                                BlendMode.srcATop,
                              ),
                        // The grid tile's size varies with screen width, so
                        // there's no fixed value to hand AvatarSprite — scale
                        // its natural sheet-cell size down to fit instead of
                        // letting it render oversized and get clipped.
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: AvatarSprite(skin: skin),
                        ),
                      ),
                    ),
                    if (!unlocked)
                      Center(
                        child: Icon(
                          Icons.lock_rounded,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _RarityDot(
                        rarity: skin.rarity,
                        accent: skin.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              FittedLabel(
                skin.name,
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white70,
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
                    : skin.rarityLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // Against the tile, not in a vacuum: several skin accents
                  // are dark enough that their own name sat at 4.4:1 or less
                  // on the card they label.
                  color: unlocked
                      ? AppTheme.legibleOn(skin.accent, AppTheme.panel)
                      : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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

  // Sized so the whole reveal — reel, sprite, name and button — fits on a
  // phone without the dialog scrolling or clipping the action button.
  static const double _itemWidth = 70;
  static const double _itemSpacing = 12;

  /// How many tiles pass the marker before the reel stops.
  ///
  /// **Fixed, not derived from where the winner sits in the catalogue.** This
  /// number, [_rollDuration] and [_rollCurve] are shared with
  /// `tool/make_sounds.py`, which emits one tick of `case_roll.wav` for each
  /// tile crossing — so the ratchet you hear *is* the reel you are watching.
  ///
  /// The previous version travelled `4 * catalogue + indexOf(winner)` tiles,
  /// which is a different distance for every skin. No pre-rendered sound can
  /// follow that, and the reel also showed the same parade of skins in the
  /// same order on every open. Pinning the distance and shuffling the strip
  /// around the winner fixes both: each roll looks different and every roll
  /// ticks identically.
  static const int _rollItems = 72;
  static const Duration _rollDuration = Duration(milliseconds: 4200);
  static const Curve _rollCurve = Cubic(0.16, 0.86, 0.41, 1.0);

  /// Tiles either side of the winner, so the reel is not empty as it settles
  /// and the player can see what they *nearly* got.
  static const int _rollTail = 6;

  double get _itemExtent => _itemWidth + _itemSpacing;

  void _skipRoll() {
    if (!_revealed && !_skipped) {
      setState(() => _skipped = true);
      _scrollController.stop();
      // Cut the ratchet with the picture. Ticks continuing under a stopped
      // reel — and under the reward chime — is the thing that makes a skip
      // feel like a glitch rather than a choice.
      AppSoundService.stop(AppSoundEffect.caseRoll);
      _onReveal();
    }
  }

  @override
  void initState() {
    super.initState();

    // The strip is built around the known result: filler tiles drawn at
    // random, the winner dropped at exactly [_rollItems]. This is how the
    // real thing works too — the outcome is decided first and the animation
    // is staged to arrive at it.
    final rng = Random();
    _rollSkins = <AvatarSkin>[
      for (var i = 0; i < _rollItems + _rollTail; i++)
        budgetBuddySkins[rng.nextInt(budgetBuddySkins.length)],
    ];
    _rollSkins[_rollItems] = widget.result.skin;

    _rollTrack = _RollTrack(
      rollSkins: _rollSkins,
      itemWidth: _itemWidth,
      itemSpacing: _itemSpacing,
    );

    _scrollController = AnimationController(vsync: this, duration: _rollDuration);
    _scrollAnimation =
        Tween<double>(begin: 0, end: _rollItems * _itemExtent).animate(
          CurvedAnimation(parent: _scrollController, curve: _rollCurve),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _onReveal();
          }
        });

    // Sound and motion start on the same frame, which is the only way the
    // two stay in step: the ratchet was previously started back in
    // `_openCase`, before an awaited network call, so how far out of sync it
    // was depended on the connection.
    AppSoundService.play(AppSoundEffect.caseRoll);
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

    // The chime lands *here*, on the frame the skin is revealed — not before
    // the dialog opens, which is where it used to fire, a full 4.2 seconds
    // early. Rarity picks which one: richer harmonics and a longer tail as it
    // climbs, so a legendary is audibly a bigger deal than a common without
    // anyone reading the label.
    AppSoundService.play(switch (widget.result.skin.rarity) {
      SkinRarity.legendary => AppSoundEffect.unboxLegendary,
      SkinRarity.epic => AppSoundEffect.unboxEpic,
      SkinRarity.rare => AppSoundEffect.unboxRare,
      _ => AppSoundEffect.unboxCommon,
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
    // The dialog can be closed before the reel finishes (rotation, a back
    // gesture on Android), and a 4.2-second ratchet playing over the screen
    // behind it would outlive the thing it belongs to.
    AppSoundService.stop(AppSoundEffect.caseRoll);
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
              final reelHeight = compact ? 96.0 : 140.0;

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
                          style: GoogleFonts.pixelifySans(
                            color: Colors.white,
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.w700,
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
                                                // OverflowBox lets the long
                                                // reel Row lay out at its
                                                // natural width instead of
                                                // tripping the debug
                                                // overflow stripes.
                                                child: OverflowBox(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  maxWidth: double.infinity,
                                                  child: Transform.translate(
                                                    offset: Offset(-offset, 0),
                                                    child: rollTrack,
                                                  ),
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
                                    size: compact ? 74 : 100,
                                    imageSize: compact ? 66 : 96,
                                    showImage: true,
                                  ),
                                  _RollShineOverlay(
                                    color: preview.accent,
                                    size: compact ? 74 : 100,
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
                          style: GoogleFonts.pixelifySans(
                            color: preview.accent,
                            fontSize: compact ? 17 : 20,
                            fontWeight: FontWeight.w700,
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
                                    child: Center(
                                      child: Text(
                                        'Skip',
                                        style: GoogleFonts.pixelifySans(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w700,
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
                                      style: GoogleFonts.pixelifySans(
                                        color: _revealed
                                            ? const Color(0xFF062C21)
                                            : Colors.white60,
                                        fontWeight: FontWeight.w700,
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
    // The item's actual content box after its own padding — sprites must be
    // sized to fit inside this, not their natural sheet-cell size, or a
    // villager cell (104x152) overflows this 70px-wide slot and bleeds into
    // neighbouring reel items.
    final contentWidth = itemWidth - 20;
    const villagerAspect =
        AppAssets.villagerCellHeight / AppAssets.villagerCellWidth;

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
          child: AvatarSprite(
            skin: skin,
            // AvatarSprite treats `size` as a height for villagers (width is
            // derived from the sheet's aspect ratio) but as a width/height
            // square for everything else, so the two need different values
            // to both land at the same on-screen content width.
            size: skin.isHuman ? contentWidth * villagerAspect : contentWidth,
          ),
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
        // The village map art, pushed rather than dimmed. This used to sit
        // under a 0.62 near-black wash which flattened the whole screen to
        // one block of dark green; [VividBackdrop] boosts saturation and
        // lifts brightness with a colour matrix, then only darkens the
        // outer edges for text contrast — so the art reads as a lit place
        // and the character in front of it pops off it.
        Positioned.fill(
          child: VividBackdrop(
            image: AppAssets.villageMapBackground,
            saturation: 1.55,
            brightness: 0.06,
            scrimOpacity: 0.22,
            vignetteOpacity: 0.6,
            glowColor: const Color(0xFF78E08F),
          ),
        ),
        Positioned(
          top: 18,
          right: 20,
          child: Opacity(
            opacity: 0.20,
            child: AmbientLottieCard(
              motif: AmbientMotif.coin,
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
              motif: AmbientMotif.turtle,
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
                child: AvatarSprite(skin: skin, size: imageSize),
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
