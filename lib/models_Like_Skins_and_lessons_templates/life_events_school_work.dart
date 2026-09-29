import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_careers.dart';
import 'life_education.dart';
import 'life_sim_models.dart';

/// Events about school, college and work.
///
/// **Asked for as:** *"make more options in the BitLife game, like random
/// pop-ups,"* and *"the late game is so repetitive."* The pool was 196 events and
/// most were about childhood and money in the abstract. These are about the
/// parts of a life that now exist: a classroom, a campus, an office, a shift, a
/// boss. Each is gated on the thing it is about, so a student never gets a
/// layoff rumour and a nurse never gets a stock tip meant for an accountant.
///
/// **Rules kept.** Everything is written for players nine and up: nothing
/// graphic, nothing about crime, drugs or gambling. Where a choice moves money,
/// every such choice in the event teaches the same idea, because the worse option
/// is the more instructive one and must not get silence.
const List<LifeEvent> kLifeEventsSchoolWork = <LifeEvent>[
  // ==== School: eight to seventeen ============================================
  LifeEvent(
    id: 's_pop_quiz',
    prompt: 'Your teacher hands out a surprise quiz. Nobody is happy about it.',
    icon: Icons.quiz_rounded,
    minAge: 8,
    maxAge: 17,
    requiresStudent: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Take a breath and work through it',
        outcome: 'Slow and steady. You knew more than you thought.',
        smarts: 3,
        happiness: 2,
      ),
      LifeChoice(
        label: 'Panic and guess',
        outcome: 'A few lucky guesses and a lot of stress.',
        smarts: 1,
        happiness: -4,
      ),
      LifeChoice(
        label: 'Ask for a few minutes to settle',
        outcome: 'The teacher gave you two. It helped more than you expected.',
        smarts: 2,
        happiness: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 's_science_fair',
    prompt: 'The school science fair is next month. You have an idea.',
    icon: Icons.science_rounded,
    minAge: 9,
    maxAge: 16,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Build it from things at home (10 coins)',
        outcome:
            'Messier and cheaper, and you learned more by fixing what broke.',
        money: -10,
        smarts: 6,
        happiness: 3,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Buy a proper kit (40 coins)',
        outcome:
            'It looked great and worked first time. You paid for the '
            'shortcut, and part of the learning went with it.',
        money: -40,
        smarts: 3,
        happiness: 4,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome: 'Safe, and a small What if for a long while after.',
        happiness: -2,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 's_class_election',
    prompt: 'Class representative elections are coming up.',
    icon: Icons.how_to_vote_rounded,
    minAge: 11,
    maxAge: 17,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Run, and give a speech',
        outcome:
            'You lost your voice and made a promise about the vending '
            'machine. Standing up got easier.',
        skill: LifeSkill.charisma,
        skillGain: 6,
        happiness: 3,
        smarts: 2,
      ),
      LifeChoice(
        label: 'Help a friend run their campaign',
        outcome:
            'Posters, slogans and a lot of glue. They won, and it was fun.',
        skill: LifeSkill.charisma,
        skillGain: 3,
        happiness: 5,
        addRelationship: 'A campaign friend',
      ),
      LifeChoice(
        label: 'Stay out of it',
        outcome: 'Quiet, and not everything has to be a stage.',
        smarts: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 's_bake_sale',
    prompt: 'The school is raising money with a bake sale.',
    icon: Icons.bakery_dining_rounded,
    minAge: 8,
    maxAge: 15,
    requiresStudent: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Bake and sell',
        outcome:
            'You sold out by noon. Selling something you made feels '
            'different from earning it any other way.',
        money: 30,
        happiness: 4,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Help run the stall',
        outcome: 'You counted change all afternoon and got very quick at it.',
        smarts: 4,
        happiness: 2,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Just donate 20 coins',
        outcome:
            'Easy, and it helped. Giving money and giving time are '
            'different gifts.',
        money: -20,
        happiness: 3,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 's_new_kid',
    prompt: 'A new student joins your class and does not know anybody.',
    icon: Icons.person_add_alt_1_rounded,
    minAge: 6,
    maxAge: 14,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Sit with them at lunch',
        outcome: 'A small thing, and it turned into a real friendship.',
        happiness: 6,
        addRelationship: 'A new classmate',
      ),
      LifeChoice(
        label: 'Say hello and leave it there',
        outcome: 'Polite, and you did not really get to know each other.',
        happiness: 1,
      ),
      LifeChoice(
        label: 'Stay with your usual group',
        outcome: 'Comfortable. You wondered about it later.',
        happiness: -1,
      ),
    ],
  ),
  LifeEvent(
    id: 's_teased',
    prompt: 'A classmate keeps making unkind jokes about you.',
    icon: Icons.sentiment_dissatisfied_rounded,
    minAge: 9,
    maxAge: 15,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Tell a teacher you trust',
        outcome:
            'It was hard to say out loud, and it worked. Asking for help '
            'is not weakness.',
        happiness: 4,
        smarts: 2,
      ),
      LifeChoice(
        label: 'Talk to them, calmly, on your own',
        outcome: 'They were more surprised than you were. It mostly stopped.',
        happiness: 3,
        skill: LifeSkill.charisma,
        skillGain: 4,
      ),
      LifeChoice(
        label: 'Ignore it and hope',
        outcome: 'It went on longer than it should have. You got through it.',
        happiness: -5,
      ),
    ],
  ),
  LifeEvent(
    id: 's_field_trip_fee',
    prompt: 'The class trip costs 30 coins. Everybody else is going.',
    icon: Icons.directions_bus_rounded,
    minAge: 8,
    maxAge: 16,
    requiresStudent: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay for it yourself',
        outcome: 'Worth it. The bus ride was half the fun.',
        money: -30,
        happiness: 7,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Ask if there is a cheaper way',
        outcome:
            'The school had a fund for exactly this. Asking cost nothing '
            'and saved the whole fee.',
        happiness: 5,
        smarts: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Skip it and save the money',
        outcome: 'You kept the 30. You also missed the trip.',
        happiness: -4,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 's_scholarship_essay',
    prompt: 'A local business offers a 150 coin scholarship for a short essay.',
    icon: Icons.edit_note_rounded,
    minAge: 16,
    maxAge: 18,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Write it, properly',
        outcome: 'Two evenings for 150 coins is a good hourly rate. You won.',
        money: 150,
        smarts: 3,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Dash off something quick',
        outcome: 'It was fine and it was not chosen. You saved the evenings.',
        smarts: 1,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome: 'More time for other things. Free money left on the table.',
        happiness: 1,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 's_teen_job_offer',
    prompt: 'The cafe near school needs weekend help and asks if you want it.',
    icon: Icons.coffee_rounded,
    minAge: 15,
    maxAge: 17,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Say yes',
        outcome:
            'Your own money, and your own stories about difficult customers. '
            'Homework got squeezed.',
        money: 80,
        happiness: 2,
        smarts: -1,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Say yes, but only one day',
        outcome: 'A smaller paycheck and a lot less stress. A fair trade.',
        money: 40,
        happiness: 3,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Say no and focus on school',
        outcome: 'Grades first. The money can wait, and so can the cafe.',
        smarts: 3,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 's_college_fair',
    prompt:
        'A college fair comes to your school. Every stall is handing out '
        'pens and promises.',
    icon: Icons.account_balance_rounded,
    minAge: 16,
    maxAge: 18,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Ask every stall what a year really costs',
        outcome:
            'Most were vague and a few were honest. The price is the '
            'sticker, not the bill.',
        smarts: 5,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Collect the free stuff and go',
        outcome: 'A good tote bag. Not much else.',
        happiness: 2,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 's_talent_show',
    prompt: 'There is a talent show at school. You could sign up.',
    icon: Icons.mic_rounded,
    minAge: 8,
    maxAge: 17,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Sign up and perform',
        outcome: 'Your knees shook the whole time. The applause did not.',
        skill: LifeSkill.charisma,
        skillGain: 6,
        happiness: 5,
      ),
      LifeChoice(
        label: 'Help behind the scenes',
        outcome: 'You ran the lights and heard every act twice.',
        smarts: 2,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Watch from the audience',
        outcome: 'A fun evening, and you cheered louder than anyone.',
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 's_group_project',
    prompt: 'Your group project is due Friday and one person has done nothing.',
    icon: Icons.groups_rounded,
    minAge: 12,
    maxAge: 17,
    requiresStudent: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Do their share so it gets done',
        outcome:
            'It got done. You were tired and a bit resentful, and they '
            'learned nothing.',
        smarts: 1,
        happiness: -3,
      ),
      LifeChoice(
        label: 'Talk to them and split it fairly',
        outcome: 'They were embarrassed and then they helped. It worked.',
        skill: LifeSkill.charisma,
        skillGain: 4,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Tell the teacher',
        outcome: 'It was sorted out fairly. Awkward for a week.',
        happiness: 1,
        smarts: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 's_driving_lessons',
    prompt: 'You are old enough to start driving lessons. They cost 60.',
    icon: Icons.drive_eta_rounded,
    minAge: 16,
    maxAge: 17,
    requiresStudent: true,
    choices: [
      LifeChoice(
        label: 'Start lessons now',
        outcome:
            'Nervous, then less nervous. You get your license sooner and '
            'pay for it earlier.',
        money: -60,
        happiness: 4,
        smarts: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Wait until you have earned the money',
        outcome: 'Slower, and it felt more like yours when it came.',
        smarts: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),

  // ==== College and after ======================================================
  LifeEvent(
    id: 'c_roommate',
    prompt: 'Your roommate never washes up. The sink is becoming a problem.',
    icon: Icons.cleaning_services_rounded,
    minAge: 18,
    maxAge: 26,
    requiresStudent: true,
    minEducation: EducationLevel.secondary,
    choices: [
      LifeChoice(
        label: 'Talk about it, with a chore chart',
        outcome: 'Awkward for ten minutes and better for a year.',
        skill: LifeSkill.charisma,
        skillGain: 4,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Leave passive-aggressive notes',
        outcome: 'It made you feel better and changed nothing.',
        happiness: -2,
      ),
      LifeChoice(
        label: 'Just do it yourself',
        outcome: 'Peace at a price: your time, every week.',
        happiness: -3,
        health: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_internship',
    prompt:
        'A company offers you a summer internship. It is unpaid. A shop '
        'offers paid summer work.',
    icon: Icons.badge_rounded,
    minAge: 19,
    maxAge: 25,
    requiresStudent: true,
    minEducation: EducationLevel.secondary,
    choices: [
      LifeChoice(
        label: 'Take the unpaid internship',
        outcome:
            'No pay, real experience, and a name on your record. It costs '
            'you a summer of income, and it may be worth it.',
        smarts: 5,
        happiness: 2,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Take the paid shop job',
        outcome: 'Money now, and no line on your resume that helps you later.',
        money: 150,
        happiness: 1,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Do a few days of each',
        outcome: 'Less of both, and it kept your options open.',
        money: 60,
        smarts: 2,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_textbooks',
    prompt: 'Your reading list arrives. The textbooks add up fast.',
    icon: Icons.menu_book_rounded,
    minAge: 18,
    maxAge: 30,
    requiresStudent: true,
    minEducation: EducationLevel.secondary,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Buy everything new (90 coins)',
        outcome: 'Crisp pages and a lighter wallet.',
        money: -90,
        happiness: 1,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Buy them used (30 coins)',
        outcome: 'Somebody else\'s notes in the margins, some of them good.',
        money: -30,
        smarts: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Borrow from the library',
        outcome: 'Free, and you had to plan around the return date.',
        smarts: 3,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_credit_offer',
    prompt:
        'A stall on campus offers a free t-shirt if you sign up for a '
        'credit card.',
    icon: Icons.credit_card_rounded,
    minAge: 18,
    maxAge: 23,
    requiresStudent: true,
    minEducation: EducationLevel.secondary,
    choices: [
      LifeChoice(
        label: 'Sign up for the t-shirt',
        outcome:
            'You have a t-shirt and a card with a high interest rate. The '
            'shirt was the cheapest part of that deal.',
        happiness: 2,
        smarts: -3,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Read the small print first',
        outcome:
            'Twenty-nine percent a year. You walked away, and you '
            'understand the offer better than the person selling it.',
        smarts: 5,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Walk past',
        outcome: 'Free things are rarely free. Good instinct.',
        smarts: 2,
        teaches: FinanceConcept.interestCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_study_abroad',
    prompt: 'You could spend a term studying abroad. It costs 200 extra.',
    icon: Icons.flight_takeoff_rounded,
    minAge: 19,
    maxAge: 23,
    requiresStudent: true,
    minEducation: EducationLevel.secondary,
    choices: [
      LifeChoice(
        label: 'Go',
        outcome:
            'A different country, a different way of thinking, and 200 '
            'coins you will be paying back for a while.',
        money: -200,
        happiness: 12,
        smarts: 5,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Stay and save the money',
        outcome: 'Sensible, and you spent the year wondering.',
        happiness: -2,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_all_nighter',
    prompt: 'A big deadline is tomorrow morning and you have barely started.',
    icon: Icons.bedtime_rounded,
    minAge: 17,
    maxAge: 30,
    requiresStudent: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pull an all-nighter',
        outcome: 'You finished, and you were useless for two days.',
        smarts: 2,
        health: -5,
        happiness: -3,
      ),
      LifeChoice(
        label: 'Sleep, then ask for a short extension',
        outcome: 'They gave you a day. Asking early is a skill.',
        smarts: 1,
        happiness: 2,
        skill: LifeSkill.charisma,
        skillGain: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_mentor_professor',
    prompt:
        'A professor stops you after class and says you have real '
        'potential.',
    icon: Icons.psychology_rounded,
    minAge: 18,
    maxAge: 30,
    requiresStudent: true,
    minEducation: EducationLevel.secondary,
    choices: [
      LifeChoice(
        label: 'Ask them to be your mentor',
        outcome: 'It took nerve, and it changed how you saw your degree.',
        smarts: 6,
        happiness: 4,
        addRelationship: 'A professor who believed in you',
      ),
      LifeChoice(
        label: 'Say thanks and keep going',
        outcome: 'It stayed with you, though you never took it further.',
        smarts: 1,
        happiness: 2,
      ),
    ],
  ),

  // ==== Work ====================================================================
  LifeEvent(
    id: 'w_extra_shift',
    prompt: 'Your manager asks if you can cover an extra shift this weekend.',
    icon: Icons.timer_rounded,
    minAge: 16,
    maxAge: 64,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Say yes',
        outcome: 'Extra pay, a tired weekend, and a manager who remembers.',
        money: 60,
        happiness: -3,
        health: -1,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Ask for time off in return',
        outcome: 'A fair deal, and they agreed. Everyone got something.',
        money: 30,
        happiness: 1,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Say no',
        outcome: 'Your weekend stayed yours. So did your usual paycheck.',
        happiness: 3,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_layoff_rumours',
    prompt: 'There are rumours that your company might be cutting jobs.',
    icon: Icons.warning_amber_rounded,
    minAge: 22,
    maxAge: 62,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Quietly build up your savings',
        outcome:
            'Nothing happened this time, and you slept better knowing '
            'there was a cushion. That is what it is for.',
        smarts: 3,
        happiness: 2,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Update your resume and your contacts',
        outcome:
            'Just in case. It is easier to look for work before you '
            'have to.',
        smarts: 4,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Ignore it and carry on',
        outcome:
            'It did not come to anything. You may not be so lucky '
            'next time.',
        happiness: -2,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_headhunter',
    prompt: 'A recruiter emails you about a role at another company.',
    icon: Icons.mail_rounded,
    minAge: 23,
    maxAge: 58,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Look at what is on the job board',
        outcome:
            'It costs nothing to look, and looking teaches you what '
            'you are worth.',
        smarts: 2,
        followUp: LifeFollowUp.openJobs,
      ),
      LifeChoice(
        label: 'Politely say no',
        outcome: 'You are happy where you are, for now.',
        happiness: 2,
      ),
      LifeChoice(
        label: 'Use it to ask for a raise',
        outcome:
            'Knowing another offer exists changed the conversation. It '
            'is not a threat, it is information.',
        smarts: 3,
        skill: LifeSkill.charisma,
        skillGain: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_office_party',
    prompt:
        'The end-of-year party is on. It is optional, and everybody '
        'goes.',
    icon: Icons.celebration_rounded,
    minAge: 20,
    maxAge: 64,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go and have a good time (30 coins)',
        outcome: 'You got to know people you only email. Good for the network.',
        money: -30,
        happiness: 6,
        smarts: 1,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Go for an hour, then leave',
        outcome: 'Seen, thanked, and home in time for dinner.',
        happiness: 3,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome: 'A quiet evening. You missed a few conversations.',
        happiness: 1,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_retirement_match',
    prompt:
        'Your employer will add money to your retirement savings if you '
        'put some in too.',
    icon: Icons.savings_rounded,
    minAge: 22,
    maxAge: 58,
    requiresJob: true,
    choices: [
      LifeChoice(
        label: 'Put in enough to get the full match',
        outcome:
            'Free money, every year, for doing something you should do '
            'anyway. Turning it down would have been like refusing a raise.',
        money: 60,
        smarts: 6,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Put in a little',
        outcome:
            'Some of the match, and a good start. More would have been '
            'better.',
        money: 20,
        smarts: 3,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Skip it for now',
        outcome:
            'Cash in hand, and the match left on the table. It is easy '
            'to put off and harder to make up.',
        smarts: -2,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_burnout',
    prompt:
        'You have been running on empty for months. Everything feels '
        'heavy.',
    icon: Icons.battery_alert_rounded,
    minAge: 24,
    maxAge: 62,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Take a proper break',
        outcome: 'A week off, and it felt strange to do nothing. It worked.',
        money: -40,
        happiness: 9,
        health: 4,
      ),
      LifeChoice(
        label: 'Talk to your manager about the workload',
        outcome: 'It was not easy to say. They changed some things.',
        happiness: 5,
        skill: LifeSkill.charisma,
        skillGain: 3,
      ),
      LifeChoice(
        label: 'Push through',
        outcome: 'You got through the quarter, and it caught up with you.',
        happiness: -6,
        health: -6,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_business_trip',
    prompt:
        'You are asked to represent the company at a meeting in another '
        'city.',
    icon: Icons.luggage_rounded,
    minAge: 22,
    maxAge: 60,
    requiresJob: true,
    minEducation: EducationLevel.secondary,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go, and make the most of it',
        outcome:
            'New faces, a hotel breakfast, and a better sense of the '
            'whole business.',
        smarts: 3,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Suggest a colleague goes instead',
        outcome: 'They were delighted. You stayed home and caught up.',
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_tax_refund',
    prompt: 'You receive a tax refund. You had forgotten it was coming.',
    icon: Icons.receipt_long_rounded,
    minAge: 18,
    maxAge: 75,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Put it straight into savings',
        outcome:
            'It was your own money, overpaid and returned. A refund is '
            'not a gift, and it is a good moment to save.',
        money: 120,
        smarts: 3,
        teaches: FinanceConcept.taxes,
      ),
      LifeChoice(
        label: 'Spend a bit and save a bit',
        outcome: 'A treat and a cushion. A sensible split.',
        money: 70,
        happiness: 4,
        teaches: FinanceConcept.taxes,
      ),
      LifeChoice(
        label: 'Spend it all on something fun',
        outcome:
            'A great weekend. It reminded you that a big refund means '
            'you lent the government money for a year for nothing.',
        money: 20,
        happiness: 8,
        teaches: FinanceConcept.taxes,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_coworker_help',
    prompt: 'A coworker is struggling with a task and looks stuck.',
    icon: Icons.handshake_rounded,
    minAge: 18,
    maxAge: 64,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Stay late and help',
        outcome:
            'They were grateful, and they remembered it when it '
            'mattered.',
        happiness: 4,
        smarts: 1,
        addRelationship: 'A grateful colleague',
      ),
      LifeChoice(
        label: 'Point them to the right person',
        outcome: 'Quick, kind and it kept your evening.',
        happiness: 2,
      ),
      LifeChoice(
        label: 'Leave them to it',
        outcome: 'Fair, and you noticed how it felt to walk past.',
        happiness: -1,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_tech_conference',
    prompt: 'Your team is sent to an industry conference.',
    icon: Icons.computer_rounded,
    minAge: 22,
    maxAge: 58,
    requiresJob: true,
    requiresTrack: CareerTrack.tech,
    choices: [
      LifeChoice(
        label: 'Go to every session',
        outcome: 'Your notebook is full, and so is your head.',
        smarts: 6,
        happiness: 2,
      ),
      LifeChoice(
        label: 'Spend the time meeting people',
        outcome: 'A few good contacts, and a job lead you did not need yet.',
        skill: LifeSkill.charisma,
        skillGain: 4,
        happiness: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_hard_shift',
    prompt: 'A patient thanks you after a very long, very hard shift.',
    icon: Icons.local_hospital_rounded,
    minAge: 22,
    maxAge: 64,
    requiresJob: true,
    requiresTrack: CareerTrack.health,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Take a moment to let it sink in',
        outcome:
            'It is why you do this. It did not make the tiredness '
            'go, and it helped.',
        happiness: 7,
      ),
      LifeChoice(
        label: 'Go straight home and sleep',
        outcome: 'You slept for eleven hours. That counts as self-care.',
        health: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_former_student',
    prompt:
        'A former student finds you and says you changed how they '
        'think.',
    icon: Icons.emoji_events_rounded,
    minAge: 24,
    maxAge: 68,
    requiresJob: true,
    requiresTrack: CareerTrack.education,
    choices: [
      LifeChoice(
        label: 'Tell them how much it means',
        outcome: 'Teachers rarely find out. You will remember this one.',
        happiness: 9,
      ),
      LifeChoice(
        label: 'Thank them and ask what they are doing now',
        outcome: 'They are doing something you are proud of.',
        happiness: 6,
        smarts: 1,
        addRelationship: 'A former student',
      ),
    ],
  ),
  LifeEvent(
    id: 'w_risky_advice',
    prompt:
        'A client asks you to put all of their savings into one exciting '
        'company.',
    icon: Icons.trending_up_rounded,
    minAge: 24,
    maxAge: 62,
    requiresJob: true,
    requiresTrack: CareerTrack.finance,
    choices: [
      LifeChoice(
        label: 'Explain why spreading it out is safer',
        outcome:
            'They grumbled and then agreed. One exciting company can '
            'fail, and a mix rarely all fails together.',
        smarts: 5,
        happiness: 3,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Do as they ask',
        outcome:
            'It is their money and their choice. It also made you '
            'uneasy, and it was the wrong call.',
        smarts: -2,
        happiness: -3,
        teaches: FinanceConcept.diversification,
      ),
    ],
  ),
  LifeEvent(
    id: 'w_midlife_change',
    prompt:
        'You wake up one morning wondering if this is the work you want '
        'to be doing.',
    icon: Icons.explore_rounded,
    minAge: 35,
    maxAge: 55,
    requiresJob: true,
    choices: [
      LifeChoice(
        label: 'Take a course in something new (60 coins)',
        outcome: 'A few evenings a week, and a door you had not noticed.',
        money: -60,
        smarts: 6,
        happiness: 3,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Look at what is out there',
        outcome: 'It is easier to leave when you know where you are going.',
        smarts: 2,
        followUp: LifeFollowUp.openJobs,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Stay, and change how you work',
        outcome: 'Sometimes the job is fine and the routine is the problem.',
        happiness: 2,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
];
