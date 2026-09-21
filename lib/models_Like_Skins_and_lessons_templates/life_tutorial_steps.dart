import 'package:flutter/material.dart';

import 'tutorial_steps.dart';

/// The tour that runs *inside* the life simulation.
///
/// **Why a second tour.** The main tour ([kTutorialSteps]) introduces the app:
/// one step per surface, each answering "what is this tab for". It has exactly
/// one step on Life, and Life is the main game: a whole screen with an age
/// button, four money boxes, four stat bars, four tabs and a door to the town.
/// "Press the big Age button" is the right amount of detail when you are being
/// shown around a tab, and nowhere near enough when you are standing in the game.
///
/// **Rewritten for younger players.** Ten-year-olds testing the game said they
/// *"don't know what is taking money from them"* and that *"everything is so
/// advanced."* So the words here are the ones a ten-year-old has met, every menu
/// has a step of its own, and there is a step for the bad days (a boss letting you
/// go, a burst pipe) and one for the "Where does my money go?" row, because those
/// were the two things a new player could not find and could not explain.
///
/// **Why the ids matter.** Each id is a key registered by `life_sim_page.dart`
/// through [TutorialTargets], so the spotlight lands on the real widget at
/// whatever size and scroll position it happens to be. A step whose target is
/// not on screen is not an error, the overlay centres its card instead of
/// pointing at nothing, which is what lets a step run before the player has ever
/// opened the thing it is about.
///
/// No `jumpTab` on any of these: this tour runs over a pushed route, not over
/// the tab bar, so there is nowhere to jump to.
const List<TutorialStep> kLifeTutorialSteps = <TutorialStep>[
  TutorialStep(
    id: 'life_intro',
    title: 'This is your life',
    tagline:
        'You play one person, from a baby to an old age. Each year something '
        'happens, and you decide what to do.',
    bullets: [
      'There is no single right answer. Every choice teaches you something '
          'about money.',
      'After you choose, the game says what it was called and why it matters. '
          'Stuck? Tap Surprise me.',
      'When your life ends it is saved, and you can start a new one.',
    ],
    teaches:
        'You learn money best by living with your choices, not by memorising.',
    icon: Icons.auto_stories_rounded,
    accent: Color(0xFF85EFAC),
    mascot: TutorialMascot.wave,
  ),
  TutorialStep(
    id: 'life_age',
    title: 'The Age button',
    tagline:
        'The big button in the middle at the bottom. Tap it and one year goes '
        'by.',
    bullets: [
      'You get a year older, and something happens.',
      'Rent and bills are paid as the years pass, even if you were not ready.',
      'There is no undo. That is how you learn to plan ahead.',
    ],
    teaches: 'Time is what every money idea needs to work.',
    icon: Icons.cake_rounded,
    accent: Color(0xFF4BD2A3),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_money',
    title: 'Your money',
    tagline:
        'Four boxes show all your money: Cash, Saved, Invested and Owed. They '
        'are always there, even when they are empty.',
    bullets: [
      'Cash is what you can spend today. Saved is your safety net for a bad '
          'day.',
      'Invested grows a little on its own. Owed is money you borrowed, and it '
          'grows too, the wrong way.',
      'An empty Saved box is not a mistake. It is the first thing to fix.',
    ],
    teaches: 'Money is not one number. It is four boxes doing different jobs.',
    icon: Icons.account_balance_wallet_rounded,
    accent: Color(0xFFFFD45C),
    mascot: TutorialMascot.thinking,
  ),
  TutorialStep(
    id: 'life_costs',
    title: 'Where does my money go?',
    tagline:
        'Tap "Where does my money go?" under the four boxes. It shows one whole '
        'year, one line at a time.',
    bullets: [
      'Coming in is your pay. Going out is rent, food and bills, fun money and '
          'savings.',
      'If you borrowed money, the payments and the interest are listed too.',
      'At the bottom it says what is left, so you know before you tap Age.',
    ],
    teaches: 'You cannot control money until you can see where it goes.',
    icon: Icons.search_rounded,
    accent: Color(0xFFFFD45C),
    mascot: TutorialMascot.thinking,
  ),
  TutorialStep(
    id: 'life_bars',
    title: 'Happiness, Health, Smarts, Looks',
    tagline:
        'Four bars show how you are doing. They go up and down with what you '
        'do.',
    bullets: [
      'Study raises Smarts. Sport and the doctor help Health. Friends lift '
          'Happiness.',
      'If Health or Happiness gets very low, you miss work and can lose your '
          'job.',
      'Nothing here is punished forever. Look after yourself and it comes '
          'back.',
    ],
    teaches: 'Money and a good life feed each other. You need both.',
    icon: Icons.favorite_rounded,
    accent: Color(0xFFFF8FB1),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_event',
    title: 'The year\'s decision',
    tagline:
        'Read what happened, then pick. Most years give you two or three ways '
        'to go.',
    bullets: [
      'There is almost always a choice that costs nothing.',
      'The costly choice is sometimes the smart one, like a repair or '
          'insurance.',
      'After you pick, the game names the money idea you just used.',
    ],
    teaches: 'The choice is the lesson. The answer afterwards explains it.',
    icon: Icons.help_center_rounded,
    accent: Color(0xFF69C6FF),
    mascot: TutorialMascot.thinking,
  ),
  TutorialStep(
    id: 'life_surprises',
    title: 'Bad days happen',
    tagline:
        'Sometimes things go wrong: your boss lets you go, the car breaks, a '
        'pipe bursts. Every real life has them.',
    bullets: [
      'You cannot stop them, but savings make them small.',
      'If you lose a job, the Occupation tab helps you find the next one.',
      'Nobody is punished for a bad day. You are shown what would have '
          'helped.',
    ],
    teaches:
        'An emergency fund is money you save before you need it, for a day '
        'like this.',
    icon: Icons.umbrella_rounded,
    accent: Color(0xFF69C6FF),
    mascot: TutorialMascot.thinking,
  ),
  TutorialStep(
    id: 'life_town',
    title: 'Go into the town',
    tagline:
        'The compass in the top corner. It takes you into the town, walking as '
        'your character.',
    bullets: [
      'There are sixteen places, like the bank, a shop, a cafe, a gym and a '
          'clinic. Walk to one to make a money choice.',
      'Hiking, the gym, the doctor, reading and the park are done in the town, '
          'not in the menus.',
      'Some days you cannot go out: too young, too ill, or a storm.',
    ],
    teaches:
        'Going somewhere to make a choice is not the same as tapping a list.',
    icon: Icons.explore_rounded,
    accent: Color(0xFF85EFAC),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_menus',
    title: 'The four menus',
    tagline:
        'Four tabs sit either side of the Age button: Occupation, Assets, '
        'People and Activities. They hold the things you choose to do.',
    bullets: [
      'Events happen to you. The menus are what you do between them.',
      'Tap a tab to open it. Swipe the sheet down to close it.',
      'The next four cards explain one each.',
    ],
    teaches:
        'Half of a money life is what you choose to do between the big events.',
    icon: Icons.apps_rounded,
    accent: Color(0xFFB388FF),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_menu_work',
    title: 'Occupation',
    tagline:
        'Your job, or your school if you are young. This is where your pay '
        'comes from.',
    bullets: [
      'Look for a job, work harder, or ask for a raise.',
      'Some jobs need a degree or a skill first.',
      'Lost your job? Look for the next one here.',
    ],
    teaches: 'Your job is the pipe your money flows through.',
    icon: Icons.work_rounded,
    accent: Color(0xFF4BD2A3),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_menu_assets',
    title: 'Assets',
    tagline:
        'What you own and what you owe: homes, cars, pets, loans, and your '
        'budget.',
    bullets: [
      'Everything you own costs something to keep. It is not just the price.',
      'Your budget is here. It splits each pay into needs, fun and savings.',
      'Loans show what you still owe and what they cost each year.',
    ],
    teaches: 'Owning something is not the same as being able to afford it.',
    icon: Icons.home_work_rounded,
    accent: Color(0xFFFFD45C),
    mascot: TutorialMascot.thinking,
  ),
  TutorialStep(
    id: 'life_menu_people',
    title: 'People',
    tagline:
        'Family, friends and a partner. Tap a person to talk, give a gift or '
        'ask for help.',
    bullets: [
      'Spend time with people or the bond fades.',
      'People change your money too: children cost more, and a partner can '
          'share the bills.',
      'Some people will lend you money. That is borrowing, so it has a price.',
    ],
    teaches: 'The people around you are part of your money.',
    icon: Icons.groups_rounded,
    accent: Color(0xFFFF8FB1),
    mascot: TutorialMascot.wave,
  ),
  TutorialStep(
    id: 'life_menu_activities',
    title: 'Activities',
    tagline:
        'Things to do, in groups: sport, clubs, learning, travel, dating and '
        'side jobs.',
    bullets: [
      'Each one costs a little or nothing, and does something for you.',
      'You can do each a few times a year. Then it stops paying, so try '
          'something new.',
      'Hiking and the gym are in the town. Walk there with the compass.',
    ],
    teaches: 'Time and money are both limited. Spend them on what you value.',
    icon: Icons.sports_esports_rounded,
    accent: Color(0xFFB388FF),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_finish',
    title: 'That is the whole game',
    tagline:
        'Age up, decide, and watch it add up. A run takes a few minutes and '
        'ends for good.',
    bullets: [
      'Retire when you are ready. Your run is scored and saved.',
      'Past lives and endings are on the Life page.',
      'You can watch this tour again from the Life page any time.',
    ],
    teaches: 'A life you cannot restart is a life you pay attention to.',
    icon: Icons.flag_rounded,
    accent: Color(0xFF4BD2A3),
    mascot: TutorialMascot.wave,
  ),
];
