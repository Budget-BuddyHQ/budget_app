import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../navigation_tools_and_animation/app_tab_index.dart';

/// Which mentor-turtle pose a tutorial step shows.
///
/// The poses are static PNGs drawn by `tools/turtle_mentor_sprites.py` at a
/// 64x64 pixel grid — same character and palette as the celebration sheet,
/// so the guide is recognisably the same Buddy who shows up when you win.
enum TutorialMascot {
  /// Greeting. Opening and closing steps only, so it stays a bookend rather
  /// than the default face.
  wave,

  /// Neutral, attentive. The workhorse pose for "here is a thing".
  idle,

  /// Leaning in. Used where the step is explaining a mechanic rather than
  /// naming a place.
  thinking,

  /// Sweating. Reserved for the steps about money going *out* — debt,
  /// volatility, spending — so the tone shifts with the subject.
  worried;

  String get asset => switch (this) {
    TutorialMascot.wave => AppAssets.turtleMentorWave,
    TutorialMascot.idle => AppAssets.turtleMentorIdle,
    TutorialMascot.thinking => AppAssets.turtleMentorThinking,
    TutorialMascot.worried => AppAssets.turtleMentorWorried,
  };
}

/// One screen of the guided tour.
///
/// Deliberately data, not widgets: the tour is a list of facts about the app
/// that needs to stay editable by someone who is not reading layout code, and
/// keeping it declarative means a step can be reordered, reworded, or dropped
/// without touching [TutorialScreen].
@immutable
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.title,
    required this.tagline,
    required this.bullets,
    required this.teaches,
    required this.icon,
    required this.accent,
    required this.mascot,
    this.whereToFind,
    this.jumpTab,
  });

  /// Stable key, safe to persist or log against. Never reuse one for
  /// different content.
  final String id;

  /// The feature's own name, exactly as it is labelled in the app — a tour
  /// that renames things is worse than no tour.
  final String title;

  /// One sentence: what this place *is*.
  final String tagline;

  /// What you actually do here. Two or three, each a concrete action rather
  /// than a description of the screen.
  final List<String> bullets;

  /// Why the feature exists in a financial-literacy app. This is the line
  /// that keeps the tour from reading as a menu index.
  final String teaches;

  final IconData icon;
  final Color accent;
  final TutorialMascot mascot;

  /// How to get there from a cold start, for the steps whose entry point is
  /// not one of the five bottom tabs (the trophy in the top bar, a card on
  /// Home). Null when the tab bar is the answer and saying so would be noise.
  final String? whereToFind;

  /// Tab to land on if the player taps "Take me there" — null for steps that
  /// describe something reached another way (a pushed route, a sub-tab).
  final int? jumpTab;
}

/// The full guided tour, in the order it is presented.
///
/// Ordered by *when a new player meets each thing*, not by tab position:
/// Home first because it is where every session starts, then Life because it
/// is the main game, then the things you reach from either. The bookend
/// steps (welcome, finish) carry no feature of their own.
const List<TutorialStep> kTutorialSteps = <TutorialStep>[
  TutorialStep(
    id: 'welcome',
    title: 'Hey, I\'m Buddy',
    tagline:
        'I\'ll show you around Budget Buddy — it takes about a minute, and '
        'you can skip out any time.',
    bullets: [
      'Every game here is really a money decision wearing a costume.',
      'Nothing you do in a game can cost you real money.',
      'You can replay this tour later from your Profile.',
    ],
    teaches: 'The decision is the lesson.',
    icon: Icons.waving_hand_rounded,
    accent: Color(0xFF85EFAC),
    mascot: TutorialMascot.wave,
  ),
  TutorialStep(
    id: 'home',
    title: 'Home',
    tagline:
        'Your dashboard — the middle button, and where every session starts.',
    bullets: [
      'Start a Life straight from the big card at the top.',
      'Log today\'s money habit without digging through menus.',
      'Read my tip of the day — a new money idea every day.',
    ],
    teaches: 'One screen that always tells you what\'s worth doing next.',
    icon: Icons.dashboard_rounded,
    accent: Color(0xFF4BD2A3),
    mascot: TutorialMascot.idle,
    jumpTab: AppTabIndex.dashboard,
  ),
  TutorialStep(
    id: 'life',
    title: 'Life',
    tagline:
        'The main game. Live a whole financial life one year at a time, from '
        'childhood to retirement.',
    bullets: [
      'Press the big Age button to advance a year.',
      'Answer the money decisions that come up — a first credit card, a vet '
          'bill, a market crash.',
      'Watch cash, savings, investments and debt move in the money panel.',
    ],
    teaches:
        'Choices compound. The card you took at 22 is the debt you meet at 25.',
    icon: Icons.explore_rounded,
    accent: Color(0xFF85EFAC),
    mascot: TutorialMascot.thinking,
    jumpTab: AppTabIndex.adventure,
  ),
  TutorialStep(
    id: 'arcade',
    title: 'Arcade',
    tagline: 'Short games that drill one money skill each.',
    bullets: [
      'Finance Brawl — answer fast enough to hold off the horde.',
      'Market Board — trade a live ticker without chasing the hype.',
      'Every card shows how long a run takes, so you can pick one that fits.',
    ],
    teaches: 'Recall under pressure, and knowing a good call from a fast one.',
    icon: Icons.sports_esports_rounded,
    accent: Color(0xFF58C7FF),
    mascot: TutorialMascot.idle,
    jumpTab: AppTabIndex.minigames,
  ),
  TutorialStep(
    id: 'market_board',
    title: 'Market Board',
    tagline:
        'A full trading desk running on real market data — with play money.',
    bullets: [
      'Trade to buy and sell, Assets to see what you hold.',
      'Orders for what\'s pending, P&L for what you actually made or lost.',
      'Analytics for the honest version: how your picks really did.',
    ],
    teaches:
        'Prices fall as well as rise, and a loss is only real when you sell.',
    icon: Icons.show_chart_rounded,
    accent: Color(0xFF69C6FF),
    mascot: TutorialMascot.worried,
    whereToFind: 'Arcade tab → Market Board',
  ),
  TutorialStep(
    id: 'learn',
    title: 'Learn',
    tagline: 'The Academy — proper lessons, in a path you work down.',
    bullets: [
      'Work through units at your own pace.',
      'Finish a lesson to earn literacy points and gold.',
      'Lessons unlock as you go, so the order always makes sense.',
    ],
    teaches:
        'The background a good decision needs, before you have to make it.',
    icon: Icons.school_rounded,
    accent: Color(0xFFB388FF),
    mascot: TutorialMascot.thinking,
    jumpTab: AppTabIndex.academy,
  ),
  TutorialStep(
    id: 'daily',
    title: 'Daily',
    tagline:
        'Money Habits — the one part of the app about your real money, not a '
        'character\'s.',
    bullets: [
      'Pick habits to track: skip a takeaway, save the spare change, wait a '
          'day before a big buy.',
      'Log them in My Week and keep the streak alive.',
      'Watch My Jar fill up with what those choices actually saved you.',
    ],
    teaches: 'Small repeated choices beat one big gesture.',
    icon: Icons.savings_rounded,
    accent: Color(0xFF4BD2A3),
    mascot: TutorialMascot.idle,
    whereToFind: 'Daily, top-left of the screen',
    jumpTab: AppTabIndex.daily,
  ),
  TutorialStep(
    id: 'style',
    title: 'Style',
    tagline: 'Spend the gold you\'ve earned on skins for your buddy.',
    bullets: [
      'Equip any skin you\'ve unlocked, free, whenever you like.',
      'Open an Emerald Case for 180 gold to roll a new one.',
      'Duplicates pay some gold back, so a roll is never wasted.',
    ],
    teaches: 'A case is a lesson in odds — check the chances before you spend.',
    icon: Icons.auto_awesome_rounded,
    accent: Color(0xFFFFD45C),
    mascot: TutorialMascot.worried,
    jumpTab: AppTabIndex.customize,
  ),
  TutorialStep(
    id: 'leaderboard',
    title: 'Leaderboard',
    tagline: 'See where you rank — globally, or against friends only.',
    bullets: [
      'Switch between Global and Friends.',
      'Rank by level or by gold, whichever you\'re chasing.',
      'Add friends with their code from your Profile.',
    ],
    teaches: 'A reason to come back that isn\'t a notification.',
    icon: Icons.emoji_events_rounded,
    accent: Color(0xFFFFD45C),
    mascot: TutorialMascot.idle,
    whereToFind: 'The trophy button, top-right on every screen',
  ),
  TutorialStep(
    id: 'profile',
    title: 'Profile',
    tagline: 'Your badges, your friend code, and everything you can turn off.',
    bullets: [
      'Tap an earned badge to watch its celebration.',
      'Share your friend code, or add someone else\'s.',
      'Sound, notifications, and your details all live here.',
    ],
    teaches: 'Proof of what you\'ve actually finished.',
    icon: Icons.person_rounded,
    accent: Color(0xFF5EE7D6),
    mascot: TutorialMascot.idle,
    whereToFind: 'Profile, top-right of the screen',
    jumpTab: AppTabIndex.profile,
  ),
  TutorialStep(
    id: 'finish',
    title: 'That\'s the tour',
    tagline:
        'Start a Life when you\'re ready — it\'s the quickest way to see how '
        'all of this fits together.',
    bullets: [
      'Stuck? My tip on Home changes every day.',
      'Replay this tour any time from Profile.',
      'Have fun. Lose the play money, not the real kind.',
    ],
    teaches: 'You learn this by deciding, not by reading.',
    icon: Icons.rocket_launch_rounded,
    accent: Color(0xFFFFD45C),
    mascot: TutorialMascot.wave,
  ),
];
