import 'package:flutter/material.dart';

/// How long a typical run takes, shown on the arcade card so a player can pick
/// something that fits the time they have.
enum ArcadeLength {
  quick('1–2 min'),
  short('3–5 min'),
  medium('5–10 min');

  const ArcadeLength(this.label);

  final String label;
}

enum ArcadeDifficulty {
  easy('Easy', Color(0xFF85EFAC)),
  medium('Medium', Color(0xFFFFD45C)),
  hard('Hard', Color(0xFFFF8474));

  const ArcadeDifficulty(this.label, this.color);

  final String label;
  final Color color;
}

/// Static description of one arcade game.
///
/// Kept separate from the page so the catalogue can be reordered, filtered or
/// reused (for example on the home screen) without touching layout code.
@immutable
class ArcadeGame {
  const ArcadeGame({
    required this.id,
    required this.title,
    required this.tagline,
    required this.teaches,
    required this.accent,
    required this.icon,
    required this.difficulty,
    required this.length,
    required this.scoreLabel,
  });

  final String id;
  final String title;

  /// One line on the card explaining what you actually do.
  final String tagline;

  /// The money concept the game drills — the reason it exists.
  final String teaches;

  final Color accent;
  final IconData icon;
  final ArcadeDifficulty difficulty;
  final ArcadeLength length;

  /// What the recorded score means, e.g. "Best score" or "Most saved".
  final String scoreLabel;
}

/// All arcade games remain preserved in code here.
const List<ArcadeGame> _allArcadeGames = <ArcadeGame>[
  ArcadeGame(
    id: 'bill_dodger',
    title: 'Bill Dodger',
    tagline: 'Grab what you need, dodge what you do not.',
    teaches: 'Needs vs wants',
    accent: Color(0xFFE1BB72),
    icon: Icons.sports_esports_rounded,
    difficulty: ArcadeDifficulty.medium,
    length: ArcadeLength.short,
    scoreLabel: 'Best score',
  ),
  ArcadeGame(
    id: 'finance_brawl',
    title: 'Finance Brawl',
    tagline: 'Answer fast enough to hold off the horde.',
    teaches: 'Recall under pressure',
    accent: Color(0xFF85EFAC),
    icon: Icons.gavel_rounded,
    difficulty: ArcadeDifficulty.hard,
    length: ArcadeLength.medium,
    scoreLabel: 'Best wave',
  ),
  ArcadeGame(
    id: 'market_board',
    title: 'Market Board',
    tagline: 'Trade a live ticker without chasing the hype.',
    teaches: 'Risk and volatility',
    accent: Color(0xFF58C7FF),
    icon: Icons.show_chart_rounded,
    difficulty: ArcadeDifficulty.hard,
    length: ArcadeLength.medium,
    scoreLabel: 'Best portfolio',
  ),
  ArcadeGame(
    id: 'subscription_sweep',
    title: 'Subscription Sweep',
    tagline: 'Cancel the dead weight, keep what you love.',
    teaches: 'Recurring costs',
    accent: Color(0xFFD49B7E),
    icon: Icons.receipt_long_rounded,
    difficulty: ArcadeDifficulty.easy,
    length: ArcadeLength.short,
    scoreLabel: 'Best balance',
  ),
  ArcadeGame(
    id: 'react_challenge',
    title: 'React Challenge',
    tagline: 'Snap decisions on everyday money calls.',
    teaches: 'Quick judgement',
    accent: Color(0xFF6CB6DA),
    icon: Icons.bolt_rounded,
    difficulty: ArcadeDifficulty.easy,
    length: ArcadeLength.quick,
    scoreLabel: 'Best run',
  ),
];

/// Add or remove IDs here to control which games appear in the app.
const Set<String> activeArcadeGameIds = <String>{
  'finance_brawl',
  'market_board',
};

/// Public catalog consumed by your UI — contains ONLY enabled games.
final List<ArcadeGame> arcadeCatalog = _allArcadeGames
    .where((game) => activeArcadeGameIds.contains(game.id))
    .toList(growable: false);
