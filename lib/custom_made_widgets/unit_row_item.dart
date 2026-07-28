import 'package:flutter/material.dart';

import '../models_Like_Skins_and_lessons_templates/lesson.dart';

class UnitRowItem extends StatelessWidget {
  const UnitRowItem({
    super.key,
    required this.lessons,
    required this.statusFor,
    required this.onLessonTap,
    this.unitIndex = 0,
  });

  final List<Lesson> lessons;
  final LessonStatus Function(String lessonId) statusFor;
  final ValueChanged<Lesson> onLessonTap;

  /// Which unit (0-based) this row belongs to — shifts which icon each node
  /// gets so the same node position doesn't always show the same tile
  /// across units.
  final int unitIndex;

  @override
  Widget build(BuildContext context) {
    final typeSeen = <LessonNodeType, int>{};
    return Column(
      children: [
        for (var index = 0; index < lessons.length; index++) ...[
          Builder(
            builder: (context) {
              final type = lessons[index].type;
              final occurrence = typeSeen[type] ?? 0;
              typeSeen[type] = occurrence + 1;
              return _UnitLessonBlock(
                lesson: lessons[index],
                status: statusFor(lessons[index].id),
                index: index,
                iconSeed: unitIndex + occurrence,
                // Stride by 5 so adjacent nodes land on different tiles, and
                // offset by the unit so unit 2's nodes don't mirror unit 1's.
                tileSeed: unitIndex + index * 5,
                onTap: () => onLessonTap(lessons[index]),
              );
            },
          ),
          if (index != lessons.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Distinct icon pools per node type — picking by [iconSeed] means every
/// individual lesson/quiz gets its own tile, and the order shifts unit to
/// unit instead of repeating identically.
const List<IconData> _lessonIcons = [
  Icons.savings_rounded,
  Icons.account_balance_wallet_rounded,
  Icons.pie_chart_rounded,
  Icons.credit_card_rounded,
  Icons.trending_up_rounded,
  Icons.receipt_long_rounded,
  Icons.lightbulb_rounded,
  Icons.shield_rounded,
  Icons.handshake_rounded,
  Icons.calculate_rounded,
];
const List<IconData> _quizIcons = [
  Icons.bolt_rounded,
  Icons.psychology_rounded,
  Icons.quiz_rounded,
  Icons.flash_on_rounded,
  Icons.extension_rounded,
  Icons.whatshot_rounded,
];
const List<IconData> _unitTestIcons = [
  Icons.star_rounded,
  Icons.emoji_events_rounded,
  Icons.military_tech_rounded,
  Icons.workspace_premium_rounded,
];

IconData _iconFor(LessonNodeType type, int seed) {
  final pool = switch (type) {
    LessonNodeType.lesson => _lessonIcons,
    LessonNodeType.quiz => _quizIcons,
    LessonNodeType.unitTest => _unitTestIcons,
  };
  return pool[seed % pool.length];
}

/// Curated full-coverage terrain tiles behind each node's icon — grass, dirt,
/// sand, stone, wood, water. Picking one per node by a seed stops every stop
/// from sharing the same two tiles (the old grass/shore pair), and the seed
/// shifts unit to unit so the sequence doesn't repeat identically either.
const List<String> _nodeTiles = [
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile001.png', // grass
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile020.png', // grass
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile040.png', // grass
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile024.png', // dirt
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile042.png', // dirt
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile049.png', // sand
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile052.png', // sand
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile057.png', // stone
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile076.png', // stone
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile122.png', // wood
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile142.png', // wood
  'assets/map_assets_coins/PNG_more_map_tiles/rpgTile032.png', // water
];

String _tileFor(int seed) => _nodeTiles[seed % _nodeTiles.length];

class _UnitLessonBlock extends StatelessWidget {
  const _UnitLessonBlock({
    required this.lesson,
    required this.status,
    required this.index,
    required this.iconSeed,
    required this.tileSeed,
    required this.onTap,
  });

  final Lesson lesson;
  final LessonStatus status;
  final int index;
  final int iconSeed;
  final int tileSeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = switch (status) {
      LessonStatus.completed => const _LessonPalette(
        fill: Color(0xFF85EFAC),
        border: Color(0xFF2A7D52),
        foreground: Color(0xFF0B2D1A),
      ),
      LessonStatus.available => const _LessonPalette(
        fill: Color(0xFFFFD45C),
        border: Color(0xFFB38C10),
        foreground: Color(0xFF3C2B00),
      ),
      LessonStatus.locked => const _LessonPalette(
        fill: Color(0xFFE7ECF2),
        border: Color(0xFFB8C1CC),
        foreground: Color(0xFF6B7280),
      ),
    };

    final icon = _iconFor(lesson.type, iconSeed);
    final statusLabel = _statusLabel(status);
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Semantics(
      button: true,
      label: 'Lesson ${index + 1}: ${lesson.title}. $statusLabel.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF173B2E), Color(0xFF10291F)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border.withValues(alpha: 0.32)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 48 : 56,
                height: compact ? 48 : 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: palette.border.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: status == LessonStatus.locked
                          ? const ColorFilter.matrix(_grayscaleTileMatrix)
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Image.asset(
                        _tileFor(tileSeed),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                    // A lighter status tint than before so the varied tile art
                    // stays visible while green/gold/grey still signals state.
                    Container(color: palette.fill.withValues(alpha: 0.24)),
                    Center(
                      child: Icon(
                        icon,
                        color: palette.foreground,
                        size: compact ? 24 : 28,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFF7FFFB),
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.border.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: palette.border,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(LessonStatus status) {
    return switch (status) {
      LessonStatus.completed => 'Mastered',
      LessonStatus.available => 'Ready',
      LessonStatus.locked => 'Locked',
    };
  }
}

// Desaturates the locked-tile ground art so unexplored stops read as dimmed.
const List<double> _grayscaleTileMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

class _LessonPalette {
  const _LessonPalette({
    required this.fill,
    required this.border,
    required this.foreground,
  });

  final Color fill;
  final Color border;
  final Color foreground;
}
