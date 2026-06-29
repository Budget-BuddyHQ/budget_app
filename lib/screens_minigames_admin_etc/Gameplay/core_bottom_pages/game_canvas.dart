import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import '../../../widgets_custom_lotties/orientation_scope.dart';

class GameCanvas extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final userStats = context.watch<UserStatsController>().stats;
    final equippedSkin = skinFromId(userStats.equippedSkin);
    final savedPosition = userStats.adventurePosition;
    final positionLabel = savedPosition == null
        ? 'No saved position yet'
        : 'Saved at ${savedPosition.dx.round()}, ${savedPosition.dy.round()}';

    return OrientationScope(
      orientations: const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF071711),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      splashRadius: 26,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Adventure Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F261C),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF85EFAC).withOpacity(0.18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videogame_asset_rounded,
                              color: equippedSkin.accent,
                              size: 86,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Adventure content has been cleared.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'The old game engine is removed. A Flame/Bonfire version can now be built here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _BadgeLabel(
                                  label: 'Map',
                                  value: mapId ?? 'unset',
                                ),
                                const SizedBox(width: 12),
                                _BadgeLabel(
                                  label: 'Saved',
                                  value: positionLabel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  const _BadgeLabel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1E16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
