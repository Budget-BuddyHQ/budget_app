import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_sim_models.dart';

/// Events for the years before school.
///
/// **Why this pack exists.** Counting eligible events by age turned up a hard
/// gap: ages 0-3 had exactly **one** event between them (`first_words`). Every
/// toddler in every run got the same scene, which is why the opening minute of
/// the game read as scripted — it was.
///
/// A toddler cannot make a money decision, so these are not money decisions
/// wearing a bib. They do two other jobs. They **characterise the household**
/// the player was born into, which is the setting every later choice happens
/// in; and they plant the *pre-money* intuitions a small child actually meets
/// — things run out, sharing costs you something, waiting gets you more. The
/// vocabulary arrives later; the instincts start here.
const List<LifeEvent> kLifeEventsToddler = <LifeEvent>[
  // --- The first two years -------------------------------------------
  //
  // Weighted toward age 0-1 specifically. Those are the first two turns a
  // player ever takes, so they carry the whole first impression — and with
  // only three eligible events between them, every new player was watching
  // the same opening. A thin pool anywhere is a problem; a thin pool *here*
  // is the one people quit over.
  LifeEvent(
    id: 't_first_laugh',
    prompt: 'Someone pulls a face. Something in you finds it hilarious.',
    icon: Icons.sentiment_very_satisfied_rounded,
    maxAge: 2,
    weight: 1.4,
    choices: [
      LifeChoice(
        label: 'Laugh until you hiccup',
        outcome:
            'The whole room tried to do it again for twenty minutes. You had '
            'them completely.',
        happiness: 8,
      ),
      LifeChoice(
        label: 'Stare at them instead',
        outcome: 'You watched, unimpressed, filing it away. A serious baby.',
        smarts: 4,
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 't_first_tooth',
    prompt: 'Something sharp is happening in your mouth and you hate it.',
    icon: Icons.medical_services_rounded,
    maxAge: 2,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Announce it, loudly, at 3am',
        outcome:
            'Nobody in the house slept. A tooth arrived. Fair trade, arguably.',
        happiness: -2,
        health: 3,
      ),
      LifeChoice(
        label: 'Chew everything in reach',
        outcome: 'The remote never recovered. Neither did one shoe.',
        happiness: 3,
        health: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 't_peekaboo',
    prompt: 'A grown-up keeps vanishing behind their hands and coming back.',
    icon: Icons.visibility_rounded,
    maxAge: 2,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Be astonished every single time',
        outcome:
            'Twenty rounds and it never got old. Somewhere in there you '
            'worked out things still exist when you cannot see them.',
        happiness: 7,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Try to do it back',
        outcome:
            'You covered your own eyes and assumed you had disappeared. '
            'Close enough.',
        happiness: 6,
        smarts: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 't_carried_everywhere',
    prompt: 'You are carried everywhere and have opinions about the route.',
    icon: Icons.stroller_rounded,
    maxAge: 2,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Point at things until they go there',
        outcome:
            'It worked more often than it should have. You learned early '
            'that asking for what you want mostly gets it.',
        happiness: 6,
        addTrait: LifeTrait.ambitious,
      ),
      LifeChoice(
        label: 'Fall asleep on the way',
        outcome:
            'You slept through most of your first year of outings and woke '
            'up cheerful for all of them.',
        happiness: 4,
        health: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 't_first_steps',
    prompt: 'You have worked out that legs go one in front of the other.',
    icon: Icons.directions_walk_rounded,
    maxAge: 3,
    weight: 1.4,
    choices: [
      LifeChoice(
        label: 'Charge at the coffee table',
        outcome: 'You met the coffee table. The coffee table won.',
        happiness: 4,
        health: -2,
        addTrait: LifeTrait.reckless,
      ),
      LifeChoice(
        label: 'Hold the sofa the whole way',
        outcome:
            'Slow, steady, and you stayed upright. You do things carefully.',
        happiness: 5,
        addTrait: LifeTrait.cautious,
      ),
    ],
  ),
  LifeEvent(
    id: 't_shiny_coin',
    prompt:
        'There is a coin on the floor. It is shiny. Everything shiny goes in '
        'your mouth.',
    icon: Icons.savings_rounded,
    maxAge: 3,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Obviously, eat it',
        outcome: 'A grown-up fished it out at speed. Nobody was calm.',
        happiness: -2,
        health: -1,
      ),
      LifeChoice(
        label: 'Put it in the jar on the shelf',
        outcome:
            'It went in the jar with the others. You have just watched money '
            'be kept instead of spent, which is where saving starts.',
        happiness: 3,
        smarts: 3,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 't_last_biscuit',
    prompt: 'One biscuit left, and another child is looking at it.',
    icon: Icons.cookie_rounded,
    minAge: 2,
    maxAge: 5,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Take the whole thing',
        outcome: 'You got the biscuit and a lecture. Worth it, at the time.',
        happiness: 4,
      ),
      LifeChoice(
        label: 'Break it in half',
        outcome:
            'Half a biscuit and a friend. The first thing that ever cost you '
            'something and was still worth it.',
        happiness: 6,
        addTrait: LifeTrait.generous,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 't_bills_at_the_table',
    prompt:
        'The grown-ups are talking about money at the table. The tone is not '
        'a happy one.',
    icon: Icons.receipt_long_rounded,
    minAge: 2,
    maxAge: 6,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Go quiet and listen',
        outcome:
            'You did not follow the words, but you learned money is a thing '
            'that makes the room tense. Plenty of adults learned it exactly '
            'this way.',
        smarts: 4,
        happiness: -3,
      ),
      LifeChoice(
        label: 'Ask what a bill is',
        outcome:
            'Something we have to pay every month whether we want to or not. '
            'Your first encounter with a fixed cost.',
        smarts: 6,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 't_favourite_toy',
    prompt: 'One toy has become the toy. It goes everywhere with you.',
    icon: Icons.toys_rounded,
    minAge: 1,
    maxAge: 5,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Never let go of it',
        outcome:
            'It lost an eye and most of its stuffing and you loved it more '
            'each year. Not everything valuable is expensive.',
        happiness: 8,
      ),
      LifeChoice(
        label: 'Leave it at the shops',
        outcome:
            'A long drive back. It was still there. You have never been so '
            'relieved about an object.',
        happiness: 3,
        health: -1,
      ),
    ],
  ),
  LifeEvent(
    id: 't_hand_me_downs',
    prompt: 'A bag of clothes arrives from an older cousin.',
    icon: Icons.checkroom_rounded,
    minAge: 3,
    maxAge: 8,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Wear them happily',
        outcome:
            'They fit, mostly. Second-hand is how a lot of households make '
            'the numbers work, and nobody that age notices.',
        happiness: 3,
        smarts: 3,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Refuse to wear the green one',
        outcome:
            'You wore the green one. You were three; that negotiation was '
            'never going your way.',
        happiness: -2,
      ),
    ],
  ),
  LifeEvent(
    id: 't_waiting_game',
    prompt: 'One sweet now, or two after dinner.',
    icon: Icons.hourglass_bottom_rounded,
    minAge: 3,
    maxAge: 7,
    weight: 1.4,
    choices: [
      LifeChoice(
        label: 'One now',
        outcome:
            'It was a good sweet. It was also one sweet instead of two, which '
            'is the whole idea behind interest, in miniature.',
        happiness: 4,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Two after dinner',
        outcome:
            'The waiting was agony and you doubled your sweets. Being paid '
            'for patience is the entire reason saving works.',
        happiness: 6,
        smarts: 5,
        addTrait: LifeTrait.frugal,
        teaches: FinanceConcept.compoundGrowth,
      ),
    ],
  ),
  LifeEvent(
    id: 't_shopping_trolley',
    prompt:
        'You are in the trolley at the supermarket, exactly level with the '
        'good shelf.',
    icon: Icons.shopping_cart_rounded,
    minAge: 2,
    maxAge: 6,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Put everything you can reach in',
        outcome:
            'Most of it went back on the shelf at the till — the first time '
            'you saw someone decide a thing was not worth the money.',
        happiness: 2,
        smarts: 3,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Ask before grabbing',
        outcome:
            'You got the cereal you asked for. Asking worked better than '
            'grabbing, which stays true for about eighty years.',
        happiness: 5,
        smarts: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 't_nursery_day',
    prompt: 'First day somewhere new, without your grown-ups.',
    icon: Icons.child_friendly_rounded,
    minAge: 3,
    maxAge: 5,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Cry until they come back',
        outcome:
            'They came back. They always came back. It took a few weeks to '
            'believe that.',
        happiness: -3,
        health: -1,
      ),
      LifeChoice(
        label: 'Find the bricks and get on with it',
        outcome:
            'You built a tower and forgot to be worried. New places got '
            'easier after that one.',
        happiness: 6,
        smarts: 3,
        addTrait: LifeTrait.ambitious,
      ),
    ],
  ),
  LifeEvent(
    id: 't_piggy_bank_gift',
    prompt: 'Someone gives you a piggy bank with a coin already inside.',
    icon: Icons.savings_rounded,
    minAge: 3,
    maxAge: 7,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Shake it out immediately',
        outcome:
            'One coin, briefly. The pig went back on the shelf empty — which '
            'is what happens to most savings with no reason to stay put.',
        happiness: 3,
      ),
      LifeChoice(
        label: 'Add every coin you find',
        outcome:
            'It got heavier. A jar that only ever fills is the simplest '
            'savings account there is, and it works for the same reason.',
        happiness: 4,
        smarts: 4,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 't_broken_thing',
    prompt: 'Something in the house broke. It was, in fairness, you.',
    icon: Icons.report_gmailerrorred_rounded,
    minAge: 3,
    maxAge: 8,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Own up',
        outcome:
            'Less trouble than expected. You also found out what it cost to '
            'replace, which was more than you had pictured.',
        happiness: -1,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Say nothing',
        outcome:
            'They worked it out. They always work it out. The lecture was '
            'longer for the waiting.',
        happiness: -4,
      ),
    ],
  ),
  LifeEvent(
    id: 't_pet_goldfish',
    prompt: 'A goldfish arrives in a bag of water, and is now your job.',
    icon: Icons.set_meal_rounded,
    minAge: 3,
    maxAge: 8,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Feed it every single day',
        outcome:
            'It lived for years. The first thing that depended on you doing '
            'something small and boring, on time, repeatedly.',
        happiness: 6,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Forget about it after a fortnight',
        outcome: 'A grown-up quietly took over. You got the credit anyway.',
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 't_bedtime_story',
    prompt: 'One more story, or lights out.',
    icon: Icons.menu_book_rounded,
    minAge: 2,
    maxAge: 7,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Negotiate for one more',
        outcome:
            'You got the extra story. Your first successful negotiation, and '
            'you were three.',
        happiness: 6,
        smarts: 3,
        addTrait: LifeTrait.ambitious,
      ),
      LifeChoice(
        label: 'Go to sleep',
        outcome:
            'You slept properly and were pleasant company the next morning, '
            'which everyone noticed.',
        happiness: 3,
        health: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 't_puddle',
    prompt: 'There is a puddle. You are wearing the good shoes.',
    icon: Icons.water_drop_rounded,
    minAge: 2,
    maxAge: 7,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Jump in it',
        outcome:
            'Completely worth it. The shoes were never the same and you have '
            'no regrets.',
        happiness: 8,
        addTrait: LifeTrait.reckless,
      ),
      LifeChoice(
        label: 'Walk around it',
        outcome:
            'Dry feet, dry shoes, and a grown-up who did not have to buy new '
            'ones this month.',
        happiness: 1,
        smarts: 3,
        addTrait: LifeTrait.frugal,
      ),
    ],
  ),
];
