import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_assets.dart';
import 'life_sim_models.dart';

/// Health, civic life, and the second half of a life.
///
/// **Asked for as:** *"the late game is so repetitive."* The old pool thinned out
/// after fifty and the same handful of events came round again and again, which
/// is the opposite of how the second half of a life feels. These are events for
/// the years when people retire, become grandparents, look after their bodies on
/// purpose, and start thinking about what they will leave behind.
///
/// Losing people is part of this, and it is written the way the rest of the game
/// writes it: in a plain sentence, without describing it, and with real choices.
/// Life is for players nine and up and says so before the first life begins.
const List<LifeEvent> kLifeEventsLaterLife = <LifeEvent>[
  // ==== Health, at any age =======================================================
  LifeEvent(
    id: 'l_broken_bone',
    prompt: 'You slip, and the doctor says you have broken your wrist.',
    icon: Icons.healing_rounded,
    minAge: 8,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Get it treated and use your insurance (30 excess)',
        outcome: 'A cast, a few weeks, and a bill that was mostly covered.',
        money: -30,
        health: -4,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Get it treated and pay it all yourself (90 coins)',
        outcome: 'A cast, a few weeks, and the full bill.',
        money: -90,
        health: -4,
        teaches: FinanceConcept.insurance,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_flu_season',
    prompt: 'Everybody around you has the flu, and now you feel it coming on.',
    icon: Icons.sick_rounded,
    minAge: 5,
    maxAge: 90,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Stay home and rest',
        outcome: 'Three miserable days and a quick recovery.',
        health: 1,
        happiness: -2,
      ),
      LifeChoice(
        label: 'Carry on as normal',
        outcome: 'You were miserable for two weeks and passed it around.',
        health: -6,
        happiness: -4,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_gym_membership',
    prompt:
        'A gym near you offers a year of membership for 120 coins, paid '
        'upfront.',
    icon: Icons.fitness_center_rounded,
    minAge: 16,
    maxAge: 70,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Join for the year (120 coins)',
        outcome:
            'You went eleven times in January and twice after that. '
            'Most memberships are bought in hope.',
        money: -120,
        health: 3,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Pay for a class each time it happens (20)',
        outcome:
            'You only paid for the days you went, which is the honest '
            'way to buy something you might not use.',
        money: -20,
        health: 6,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Go for runs outside',
        outcome: 'Free, and the weather was a good reason to stop for a bit.',
        health: 5,
        happiness: 2,
        teaches: FinanceConcept.lifestyleCreep,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_check_up_advice',
    prompt:
        'The doctor says your numbers are okay, but that you should look '
        'after yourself a bit more.',
    icon: Icons.monitor_heart_rounded,
    minAge: 35,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Change how you eat and move',
        outcome: 'It was not easy and you felt better by spring.',
        health: 8,
        happiness: 2,
      ),
      LifeChoice(
        label: 'Make one small change to start',
        outcome: 'A walk after dinner. It stuck, and it grew from there.',
        health: 4,
        happiness: 2,
      ),
      LifeChoice(
        label: 'Nod and carry on',
        outcome: 'It will come up again. It always does.',
        health: -3,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_dentist',
    prompt:
        'You have been putting off the dentist. A tooth has decided the '
        'matter.',
    icon: Icons.medical_services_rounded,
    minAge: 18,
    maxAge: 90,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Get it fixed now (60 coins)',
        outcome: 'A filling and a stern chat about flossing.',
        money: -60,
        health: 2,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Take painkillers and wait',
        outcome:
            'It got worse. A filling became a root canal, and 60 became '
            '200.',
        money: -200,
        health: -3,
        happiness: -4,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_marathon',
    prompt: 'A friend dares you to train for a charity run.',
    icon: Icons.directions_run_rounded,
    minAge: 16,
    maxAge: 60,
    choices: [
      LifeChoice(
        label: 'Sign up and train properly',
        outcome:
            'Six months of early mornings. You crossed the line '
            'and cried a bit.',
        health: 9,
        happiness: 8,
        smarts: 2,
      ),
      LifeChoice(
        label: 'Sign up for the shorter one',
        outcome: 'Half the training and most of the fun.',
        health: 5,
        happiness: 5,
      ),
      LifeChoice(
        label: 'Cheer from the side',
        outcome: 'You held the water bottles and shouted loudest.',
        happiness: 3,
      ),
    ],
  ),

  // ==== Civic life =================================================================
  LifeEvent(
    id: 'v_register_to_vote',
    prompt:
        'You are old enough to register to vote. A form arrives in the '
        'post.',
    icon: Icons.how_to_vote_rounded,
    minAge: 18,
    maxAge: 21,
    choices: [
      LifeChoice(
        label: 'Register and read up on the candidates',
        outcome:
            'Taxes, schools, roads. Choices made in a voting booth show '
            'up in your paycheck and your street.',
        smarts: 5,
        happiness: 3,
        teaches: FinanceConcept.taxes,
      ),
      LifeChoice(
        label: 'Register, and look into it later',
        outcome: 'The first step is the form. The rest can follow.',
        smarts: 2,
        teaches: FinanceConcept.taxes,
      ),
      LifeChoice(
        label: 'Put the form in a drawer',
        outcome: 'It is still there. Deadlines have a way of arriving.',
        teaches: FinanceConcept.taxes,
      ),
    ],
  ),
  LifeEvent(
    id: 'v_jury_summons',
    prompt: 'A letter arrives asking you to serve on a jury.',
    icon: Icons.gavel_rounded,
    minAge: 21,
    maxAge: 72,
    choices: [
      LifeChoice(
        label: 'Serve, and take it seriously',
        outcome:
            'A week in a courtroom, and a new respect for how slow '
            'fairness is.',
        smarts: 5,
        happiness: 1,
        money: -30,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Ask to be excused, with a good reason',
        outcome: 'Some reasons are accepted. Not wanting to is not one.',
        smarts: 1,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'v_town_meeting',
    prompt: 'There is a public meeting about spending money on a new park.',
    icon: Icons.park_rounded,
    minAge: 20,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go and speak',
        outcome:
            'Your hands shook. Your point was heard, and the park got a '
            'playground.',
        skill: LifeSkill.charisma,
        skillGain: 5,
        smarts: 3,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Go and listen',
        outcome:
            'You learned how a small budget gets argued over, line by '
            'line.',
        smarts: 5,
        teaches: FinanceConcept.taxes,
      ),
      LifeChoice(
        label: 'Read about it afterwards',
        outcome: 'Not the same, and better than nothing.',
        smarts: 2,
      ),
    ],
  ),

  // ==== The middle and later years =================================================
  LifeEvent(
    id: 'l_reunion',
    prompt:
        'A school reunion is coming up. Everybody will be comparing what '
        'they have.',
    icon: Icons.event_rounded,
    minAge: 30,
    maxAge: 65,
    choices: [
      LifeChoice(
        label: 'Go, and just enjoy seeing people',
        outcome:
            'Most people were nervous about the same things. It was a '
            'lovely evening.',
        happiness: 6,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Buy a new outfit and a nicer car for it (150 coins)',
        outcome:
            'Nobody asked. You spent 150 to impress people you will '
            'not see again.',
        money: -150,
        happiness: 1,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Stay home',
        outcome: 'A quiet night in. You wondered a little.',
        happiness: -1,
        teaches: FinanceConcept.lifestyleCreep,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_retirement_party',
    prompt: 'It is your last week at work. They have organised a party.',
    icon: Icons.celebration_rounded,
    minAge: 60,
    maxAge: 72,
    requiresJob: true,
    choices: [
      LifeChoice(
        label: 'Enjoy it, and thank everybody',
        outcome: 'Decades of small moments, and a card signed by everyone.',
        happiness: 10,
        smarts: 1,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Ask the team what they wish they had saved',
        outcome: 'Almost everybody said the same thing: start earlier.',
        smarts: 4,
        happiness: 5,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_grandchild',
    prompt: 'Your child tells you that you are going to be a grandparent.',
    icon: Icons.child_friendly_rounded,
    minAge: 48,
    maxAge: 85,
    requiresChild: true,
    choices: [
      LifeChoice(
        label: 'Cry, hug them, and start planning',
        outcome: 'A new chapter you did not know you were waiting for.',
        happiness: 12,
      ),
      LifeChoice(
        label: 'Buy a first toy (30 coins)',
        outcome: 'It is a rabbit and it is enormous. It will outlive you all.',
        money: -30,
        happiness: 10,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_grandkid_savings',
    prompt:
        'Your grandchild is a year old. You want to give them something '
        'that will last.',
    icon: Icons.savings_rounded,
    minAge: 52,
    maxAge: 88,
    requiresChild: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Open a savings account for them (100 coins)',
        outcome:
            'Left alone for twenty years, 100 grows into far more than '
            '100. Time is the gift.',
        money: -100,
        happiness: 7,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Buy them toys (60 coins)',
        outcome:
            'They were delighted for a week. The toys did not last '
            'twenty years.',
        money: -60,
        happiness: 5,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Write them a letter for when they are older',
        outcome: 'Free, and they will read it long after the toys are gone.',
        happiness: 6,
        smarts: 1,
        teaches: FinanceConcept.compoundGrowth,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_downsize',
    prompt: 'The house is too big now, and the stairs are getting harder.',
    icon: Icons.home_rounded,
    minAge: 62,
    maxAge: 90,
    requiresAsset: AssetKind.home,
    choices: [
      LifeChoice(
        label: 'Sort through everything you no longer need',
        outcome:
            'Fifty years of things. You sold what you could and kept '
            'what mattered.',
        money: 120,
        happiness: 3,
        teaches: FinanceConcept.sunkCost,
      ),
      LifeChoice(
        label: 'Stay, and make the house easier to live in (150 coins)',
        outcome: 'A handrail and a stairlift. Home is worth some money.',
        money: -150,
        happiness: 4,
        teaches: FinanceConcept.sunkCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_scam_call',
    prompt:
        'A caller says they are from your bank and that your money is '
        'in danger unless you act right now.',
    icon: Icons.phone_in_talk_rounded,
    minAge: 55,
    maxAge: 95,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Hang up and call your bank on its real number',
        outcome:
            'It was a scam, and the bank thanked you for checking. A '
            'real bank never rushes you.',
        smarts: 5,
        happiness: 2,
      ),
      LifeChoice(
        label: 'Ask a family member what they think',
        outcome: 'They knew straight away. It is always worth asking.',
        smarts: 3,
      ),
      LifeChoice(
        label: 'Do what they say',
        outcome:
            'It took a lot of effort to put right, and some of it could '
            'not be. It happens to careful people.',
        money: -150,
        happiness: -8,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_memoir',
    prompt: 'Your family keeps asking you to write down your stories.',
    icon: Icons.auto_stories_rounded,
    minAge: 60,
    maxAge: 95,
    choices: [
      LifeChoice(
        label: 'Start writing, a page a day',
        outcome:
            'Some of it made you laugh out loud. The rest made you '
            'think.',
        smarts: 3,
        happiness: 8,
      ),
      LifeChoice(
        label: 'Record yourself telling the stories',
        outcome: 'Easier than writing, and the voice is worth keeping.',
        happiness: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_old_friend',
    prompt: 'You hear that an old friend from your school days has died.',
    icon: Icons.favorite_border_rounded,
    minAge: 58,
    maxAge: 95,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go to the memorial',
        outcome:
            'You met people you had not seen in forty years and told '
            'stories about a person you were lucky to know.',
        money: -30,
        happiness: -4,
      ),
      LifeChoice(
        label: 'Write to their family',
        outcome:
            'A few lines they will keep. It meant more than you '
            'thought it would.',
        happiness: -3,
        smarts: 1,
      ),
      LifeChoice(
        label: 'Call an old friend you have lost touch with',
        outcome: 'It was not too late. It rarely is.',
        happiness: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_will_planning',
    prompt:
        'You realise that you have never written down what you want to '
        'happen to your things.',
    icon: Icons.description_rounded,
    minAge: 50,
    maxAge: 90,
    choices: [
      LifeChoice(
        label: 'Write a will properly (80 coins)',
        outcome:
            'A few forms and an afternoon. It saves your family months '
            'of confusion.',
        money: -80,
        smarts: 4,
        happiness: 3,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Make a simple list and tell your family',
        outcome:
            'A start, and not legally the same thing. Better than '
            'nothing.',
        smarts: 2,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Leave it for another year',
        outcome:
            'It is a job that is easy to put off, and it is a lot '
            'harder for the people who have to sort it out later.',
        teaches: FinanceConcept.insurance,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_long_term_care',
    prompt:
        'A friend needed care at home and it cost far more than they '
        'expected.',
    icon: Icons.elderly_rounded,
    minAge: 52,
    maxAge: 78,
    choices: [
      LifeChoice(
        label: 'Look into insurance for it (120 coins)',
        outcome:
            'It is a cost now for a big cost you may never have. That '
            'is what insurance is.',
        money: -120,
        smarts: 3,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Set aside your own savings for it',
        outcome:
            'A cushion you keep if you do not need it. You need to '
            'have enough to make it work.',
        smarts: 4,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Hope it will not happen to you',
        outcome: 'Most people do. It is not a plan.',
        happiness: -2,
        teaches: FinanceConcept.insurance,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_travel_bucket_list',
    prompt:
        'You have a list of places you always meant to see, and time to '
        'see them at last.',
    icon: Icons.flight_takeoff_rounded,
    minAge: 60,
    maxAge: 85,
    minMoney: 300,
    choices: [
      LifeChoice(
        label: 'Take the big trip (250 coins)',
        outcome:
            'Three weeks, a lot of photographs, and stories that will '
            'last.',
        money: -250,
        happiness: 14,
        health: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Take a shorter trip closer to home (80 coins)',
        outcome: 'Not on the list, and a lovely surprise.',
        money: -80,
        happiness: 8,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Save it for later',
        outcome:
            'There is not always a later. It is a real trade, and you '
            'made it with your eyes open.',
        happiness: -2,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_volunteer_retired',
    prompt:
        'Now you have the time, the local school asks if you could help '
        'children learn to read.',
    icon: Icons.volunteer_activism_rounded,
    minAge: 60,
    maxAge: 90,
    choices: [
      LifeChoice(
        label: 'Say yes, twice a week',
        outcome:
            'A child read you a whole book. It was the best afternoon '
            'of your month.',
        happiness: 10,
        smarts: 2,
        addRelationship: 'A young reader',
      ),
      LifeChoice(
        label: 'Say yes, once a fortnight',
        outcome: 'Less than you wanted and it fitted your life.',
        happiness: 6,
      ),
      LifeChoice(
        label: 'Politely decline',
        outcome: 'You are enjoying doing nothing, for now.',
        happiness: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_tech_help',
    prompt: 'Your grandchild offers to teach you how to use a new tablet.',
    icon: Icons.tablet_mac_rounded,
    minAge: 62,
    maxAge: 95,
    requiresChild: true,
    choices: [
      LifeChoice(
        label: 'Sit down and learn',
        outcome:
            'They were patient and you were quick. You can video call '
            'everyone now.',
        smarts: 5,
        happiness: 7,
      ),
      LifeChoice(
        label: 'Let them do it for you',
        outcome: 'It works, and you will need to ask again.',
        happiness: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_stray_animal',
    prompt: 'A thin, friendly stray hangs around your door every morning.',
    icon: Icons.pets_rounded,
    minAge: 20,
    maxAge: 90,
    repeatable: true,
    choices: [
      LifeChoice(
        label:
            'Take them to the vet and think about a home for them (60 '
            'coins)',
        outcome: 'They were healthy, and somebody kind gave them a home.',
        money: -60,
        happiness: 7,
      ),
      LifeChoice(
        label: 'Leave out some water',
        outcome: 'A small kindness that cost you nothing.',
        happiness: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'l_hobby_group',
    prompt: 'A club for something you enjoy has a spot open.',
    icon: Icons.groups_rounded,
    minAge: 40,
    maxAge: 95,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Join, and go every week',
        outcome: 'It gave your weeks a shape, and you made two real friends.',
        happiness: 8,
        addRelationship: 'A friend from the club',
      ),
      LifeChoice(
        label: 'Try it once',
        outcome: 'A nice afternoon. You did not go back.',
        happiness: 3,
      ),
    ],
  ),
];
