import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../constants/app_assets.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/custom_button.dart';
import 'game_canvas.dart';

class MainGamePage extends StatelessWidget {
  const MainGamePage({
    super.key,
    this.activeTabIndex = AppTabIndex.adventure,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openAcademy(BuildContext context) async {
    HapticFeedback.lightImpact();
    final selectTab = onNavSelected;
    if (selectTab != null) {
      selectTab(AppTabIndex.academy);
      return;
    }
    await Navigator.of(context).pushNamed('/lessons');
  }

  Future<void> _openArcade(BuildContext context) async {
    HapticFeedback.lightImpact();
    final selectTab = onNavSelected;
    if (selectTab != null) {
      selectTab(AppTabIndex.minigames);
      return;
    }
    await Navigator.of(context).pushNamed('/minigames');
  }

  Future<void> _enterWorld(
    BuildContext context,
    UserStats stats,
    AvatarSkin skin,
  ) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameCanvas(
          mapId: stats.adventureMapId,
          initialPosition: stats.adventurePosition,
          skinAssetPath: skin.assetPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final equippedSkin = skinFromId(stats.equippedSkin);

        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected!,
                ),
          body: Stack(
            children: [
              const _AdventureBackdrop(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final short = constraints.maxHeight < 680;
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 24 : 16,
                        short ? 14 : 18,
                        wide ? 24 : 16,
                        120,
                      ),
                      children: [
                        const _PageHeader(
                          title: 'Adventure',
                          subtitle:
                              'Roam the finance world and battle monsters.',
                        ),
                        SizedBox(height: short ? 14 : 20),
                        _AdventureLaunchPanel(
                          stats: stats,
                          skin: equippedSkin,
                          compact: !wide || short,
                          onEnterWorld: () =>
                              _enterWorld(context, stats, equippedSkin),
                          onOpenAcademy: () => _openAcademy(context),
                          onOpenArcade: () => _openArcade(context),
                        ),
                      ],
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Navigator.of(context).canPop())
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdventureLaunchPanel extends StatelessWidget {
  const _AdventureLaunchPanel({
    required this.stats,
    required this.skin,
    required this.compact,
    required this.onEnterWorld,
    required this.onOpenAcademy,
    required this.onOpenArcade,
  });

  final UserStats stats;
  final AvatarSkin skin;
  final bool compact;
  final VoidCallback onEnterWorld;
  final VoidCallback onOpenAcademy;
  final VoidCallback onOpenArcade;

  @override
  Widget build(BuildContext context) {
    final savedPosition = stats.adventurePosition;
    final positionLabel = savedPosition == null
        ? 'No saved position'
        : 'Saved at ${savedPosition.dx.round()}, ${savedPosition.dy.round()}';
    final art = _AdventureArt(skin: skin, compact: compact);
    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD45C).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFFD45C).withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            'Level ${stats.level} • ${stats.gold} Gold',
            style: const TextStyle(
              color: Color(0xFFFFD45C),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Enter Adventure',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 34 : 48,
            height: 0.98,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This adventure area has been reset for a new Flame/Bonfire game build. The next version of the game will appear here.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            height: 1.42,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        _WorldStatusCard(
          mapTitle: 'Adventure',
          skin: skin,
          positionLabel: positionLabel,
          compact: compact,
        ),
        const SizedBox(height: 22),
        _ActionRow(
          compact: compact,
          onEnterWorld: onEnterWorld,
          onOpenAcademy: onOpenAcademy,
          onOpenArcade: onOpenArcade,
        ),
      ],
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 540 : 620),
      padding: EdgeInsets.all(compact ? 20 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15392D), Color(0xFF081B14)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: const Color(0xFF85EFAC).withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: compact
          ? Column(children: [art, const SizedBox(height: 24), copy])
          : Row(
              children: [
                Expanded(flex: 5, child: copy),
                const SizedBox(width: 28),
                Expanded(flex: 4, child: art),
              ],
            ),
    );
  }
}

class _AdventureArt extends StatelessWidget {
  const _AdventureArt({required this.skin, required this.compact});

  final AvatarSkin skin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 210.0 : 300.0;
    return Center(
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
                color: skin.accent.withValues(alpha: 0.12),
                border: Border.all(color: skin.accent.withValues(alpha: 0.22)),
              ),
            ),
            Container(
              width: size * 0.72,
              height: size * 0.72,
              padding: EdgeInsets.all(size * 0.12),
              decoration: BoxDecoration(
                color: const Color(0xFF071711).withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(size * 0.18),
                border: Border.all(color: skin.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: skin.accent.withValues(alpha: 0.22),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Image.asset(skin.assetPath, fit: BoxFit.contain),
            ),
            Positioned(
              right: size * 0.08,
              bottom: size * 0.18,
              child: _StatusChip(accent: skin.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF071711),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.46)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF85EFAC), size: 16),
          SizedBox(width: 6),
          Text(
            'Ready',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldStatusCard extends StatelessWidget {
  const _WorldStatusCard({
    required this.mapTitle,
    required this.skin,
    required this.positionLabel,
    required this.compact,
  });

  final String mapTitle;
  final AvatarSkin skin;
  final String positionLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = <_WorldStatusItem>[
      _WorldStatusItem(
        icon: Icons.map_rounded,
        label: 'Current Map',
        value: mapTitle,
        accent: const Color(0xFF85EFAC),
      ),
      _WorldStatusItem(
        icon: Icons.location_on_rounded,
        label: 'Save Point',
        value: positionLabel,
        accent: const Color(0xFFFFD45C),
      ),
      _WorldStatusItem(
        icon: Icons.pets_rounded,
        label: 'Equipped Turtle',
        value: skin.name,
        accent: skin.accent,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071711).withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF85EFAC).withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: compact
            ? Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: item,
                      ),
                    )
                    .toList(growable: false),
              )
            : Row(
                children: items
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: item,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
      ),
    );
  }
}

class _WorldStatusItem extends StatelessWidget {
  const _WorldStatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.compact,
    required this.onEnterWorld,
    required this.onOpenAcademy,
    required this.onOpenArcade,
  });

  final bool compact;
  final VoidCallback onEnterWorld;
  final VoidCallback onOpenAcademy;
  final VoidCallback onOpenArcade;

  @override
  Widget build(BuildContext context) {
    final enterWorld = CustomButton(
      label: 'Enter World',
      onPressed: onEnterWorld,
      prefixIcon: const Icon(
        Icons.explore_rounded,
        color: Color(0xFF062C21),
        size: 18,
      ),
      style: const CustomButtonStyle.primary(),
    );
    final academy = CustomButton(
      label: 'Open Academy',
      onPressed: onOpenAcademy,
      prefixIcon: const Icon(
        Icons.school_rounded,
        color: Color(0xFF062C21),
        size: 18,
      ),
      style: const CustomButtonStyle.primary(),
    );
    final arcade = CustomButton(
      label: 'Open Arcade',
      onPressed: onOpenArcade,
      prefixIcon: const Icon(
        Icons.sports_esports_rounded,
        color: Color(0xFF85EFAC),
        size: 18,
      ),
      style: const CustomButtonStyle.tertiary(),
    );

    if (compact) {
      return Column(
        children: [
          enterWorld,
          const SizedBox(height: 10),
          academy,
          const SizedBox(height: 10),
          arcade,
        ],
      );
    }

    return Column(
      children: [
        enterWorld,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: academy),
            const SizedBox(width: 12),
            Expanded(child: arcade),
          ],
        ),
      ],
    );
  }
}

class _AdventureBackdrop extends StatelessWidget {
  const _AdventureBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.adventureMapBackground,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
        ),
        Container(color: const Color(0xFF071711).withValues(alpha: 0.52)),
      ],
    );
  }
}
