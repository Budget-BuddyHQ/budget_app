import 'package:flutter/material.dart';

import 'tutorial_steps.dart';

/// The tour that runs *inside* the life simulation.
///
/// **Why a second tour.** The main tour ([kTutorialSteps]) introduces the app
/// — eleven steps, one per surface, each answering "what is this tab for".
/// It has exactly one step on Life, and Life is the main game: a whole
/// screen with an age button, four money boxes, four stat bars, a chain-flag
/// strip, four tabs and a door to the town. "Press the big Age button"
/// is the right amount of detail when you are being shown around a tab, and
/// nowhere near enough when you are standing in the game.
///
/// The failure this fixes is specific and quiet: a new player ages up, reads
/// an event, picks an option, and never finds the Money panel, the town, or
/// the career menu — because nothing ever said they were there. They play the
/// simulation as a multiple-choice quiz, which is the one reading of it that
/// teaches nothing.
///
/// **Why the ids matter.** Each id is a key registered by `life_sim_page.dart`
/// through [TutorialTargets], so the spotlight lands on the real widget at
/// whatever size and scroll position it happens to be. A step whose target is
/// not on screen is not an error — the overlay centres its card instead of
/// pointing at nothing — which is what lets the town step run before the
/// player has ever opened the town.
///
/// No `jumpTab` on any of these: this tour runs over a pushed route, not over
/// the tab bar, so there is nowhere to jump to.
const List<TutorialStep> kLifeTutorialSteps = <TutorialStep>[
  TutorialStep(
    id: 'life_intro',
    title: 'This is your life',
    tagline:
        'One year at a time, from being born to whenever you stop. Every '
        'year gives you something to decide.',
    bullets: [
      'Nothing here is a quiz — there is no single right answer.',
      'Every choice tells you afterwards what it was called and why. Stuck? '
          'Surprise me picks for you.',
      'When the run ends it is recorded, and you start a new one.',
    ],
    teaches:
        'Money decisions are easier to understand after you have lived '
        'with one.',
    icon: Icons.auto_stories_rounded,
    accent: Color(0xFF85EFAC),
    mascot: TutorialMascot.wave,
  ),
  TutorialStep(
    id: 'life_age',
    title: 'The Age button',
    tagline: 'The middle button at the bottom. Press it and a year goes by.',
    bullets: [
      'A year passes, you get older, and something happens.',
      'Bills, rent and interest are charged as the years pass — whether or '
          'not you were ready for them.',
      'There is no undo. That is the point.',
    ],
    teaches: 'Time is the ingredient every money idea needs.',
    icon: Icons.cake_rounded,
    accent: Color(0xFF4BD2A3),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_money',
    title: 'Your money',
    tagline:
        'Four boxes: cash, saved, invested, owed. All four are always shown, '
        'including the empty ones.',
    bullets: [
      'Cash is what you can spend today. Saved is what survives a bad month.',
      'Invested grows on its own; owed grows on its own too, the wrong way.',
      'An empty savings box is not a bug — it is the thing to fix.',
    ],
    teaches: 'Net worth is one number hiding four very different situations.',
    icon: Icons.account_balance_wallet_rounded,
    accent: Color(0xFFFFD45C),
    mascot: TutorialMascot.thinking,
  ),
  TutorialStep(
    id: 'life_event',
    title: 'The year\'s decision',
    tagline:
        'Read what happened, then pick. Most years give you two or three ways '
        'to go.',
    bullets: [
      'There is almost always an option that costs nothing.',
      'The expensive option is sometimes the right one — insurance, a repair, '
          'a course.',
      'After you pick, the outcome names the money idea you just used.',
    ],
    teaches: 'The decision is the lesson; the outcome is the explanation.',
    icon: Icons.help_center_rounded,
    accent: Color(0xFF69C6FF),
    mascot: TutorialMascot.thinking,
  ),
  TutorialStep(
    id: 'life_town',
    title: 'Go into the town',
    tagline:
        'The compass in the top corner. It drops you into the town as your '
        'character, on foot.',
    bullets: [
      'Six buildings, and walking into one starts a money decision.',
      'What each building offers changes every day, so it is worth going back.',
      'Whether you are allowed out depends on your age, health, the weather '
          'and how strict your family is.',
    ],
    teaches:
        'Walking somewhere to make a decision is not the same as tapping it '
        'on a list.',
    icon: Icons.explore_rounded,
    accent: Color(0xFF85EFAC),
    mascot: TutorialMascot.idle,
  ),
  TutorialStep(
    id: 'life_menus',
    title: 'Occupation, Assets, People, Activities',
    tagline:
        'The four tabs either side of the Age button, above the four bars for '
        'Happiness, Health, Smarts and Looks. These are the things you choose '
        'to do, rather than the things that happen to you.',
    bullets: [
      'Occupation: study, apply for a job, work harder, ask for a raise or '
          'a promotion. Some jobs need a degree.',
      'Assets: homes, cars and pets, what you owe on them, and your budget '
          'and savings.',
      'People: family, friends and a partner. Spend time with them or the '
          'closeness fades. Activities: sports, clubs, dating and travel.',
    ],
    teaches:
        'Half of a financial life is what you decide to do between the events.',
    icon: Icons.apps_rounded,
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
      'Retire when you are ready and the run is scored and saved.',
      'Past lives and the endings gallery are on the Life hub.',
      'You can replay this tour from the Life hub any time.',
    ],
    teaches: 'A life you cannot restart is a life you pay attention to.',
    icon: Icons.flag_rounded,
    accent: Color(0xFF4BD2A3),
    mascot: TutorialMascot.wave,
  ),
];
