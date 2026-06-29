import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'player/player.dart';

class GameCanvas extends StatelessWidget {
  const GameCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<UserStatsController>().stats;
    final skin = skinFromId(stats.equippedSkin);

    return Scaffold(
      body: Stack(
        children: [
          BonfireWidget(
            playerControllers: [Joystick(directional: JoystickDirectional())],
            map: WorldMapByTiled(
              WorldMapReader.fromAsset('map/starter_village.tmx'),
            ),
            player: AdventurePlayer(
              position: Vector2(100, 100),
              size: Vector2(32, 32),
              skin: skin,
              gold: stats.gold,
              level: stats.level,
            ),
          ),
          Positioned(
            top: 24,
            left: 16,
            right: 16,
            child: _GameHud(gold: stats.gold, level: stats.level),
          ),
        ],
      ),
    );
  }
}

class _GameHud extends StatelessWidget {
  const _GameHud({required this.gold, required this.level});

  final int gold;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _HudBadge(label: 'Gold', value: gold.toString()),
        _HudBadge(label: 'Level', value: level.toString()),
      ],
    );
  }
}

class _HudBadge extends StatelessWidget {
  const _HudBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
