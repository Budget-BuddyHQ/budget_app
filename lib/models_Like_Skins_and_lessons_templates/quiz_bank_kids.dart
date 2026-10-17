import 'quiz_bank.dart';

/// Questions written for younger players on units written for older ones.
///
/// **Reported as:** *"it still has no quizzes for some."* Every question takes
/// its age from its unit (`question_stage.dart`), and the rule is that you are
/// never *tested* above your age. Right rule, and it left whole units with no
/// quiz at all below a certain age: nothing on Credit or Big Purchases for a
/// fifteen-year-old, nothing past Saving Systems for a ten-year-old, nothing
/// past Saving and Spending for an eight-year-old. They got the reading and a
/// note saying the test was for older players.
///
/// The fix keeps the rule. These are the same ideas asked at a young
/// player's level: what borrowing means rather than how interest is
/// calculated, why grown-ups save for when they stop working rather than
/// which account to use. They are tagged `youngKids` (see `question_stage.dart`) so the age
/// filter treats them as written for seven-to-ten-year-olds, which serves
/// them to every band up to seventeen. An adult never sees them while the
/// unit's own questions exist.
///
/// Three per quick quiz, four per unit test, on the unit's own skills so a
/// wrong answer still points at the right lesson. None names anything on
/// `kAdultOnlyTopics`, which `test/question_stage_test.dart` checks.
const Map<String, List<QuizQuestion>>
kKidQuizAdditions = <String, List<QuizQuestion>>{
  // ---- Unit 3: Budgeting ---------------------------------------------
  'quiz_1': <QuizQuestion>[
    QuizQuestion(
      id: 'kq1a',
      skillId: QuizSkills.budgetBasics,
      prompt: 'What is a budget?',
      options: [
        'A plan for how to use your money',
        'A kind of piggy bank',
        'A list of toys you want',
        'Money the bank gives you',
      ],
      correctIndex: 0,
      explanation:
          'A budget is a plan. It says how much you will spend and how '
          'much you will save before the money is gone.',
    ),
    QuizQuestion(
      id: 'kq1b',
      skillId: QuizSkills.income,
      prompt: 'Money that comes in to you is called what?',
      options: ['Spending', 'Income', 'A bill', 'A price tag'],
      correctIndex: 1,
      explanation:
          'Income is money coming in, like allowance or pay. Spending '
          'and bills are money going out.',
    ),
    QuizQuestion(
      id: 'kq1c',
      skillId: QuizSkills.expenses,
      prompt: 'Which one is an expense?',
      options: [
        'Your birthday money',
        'Money you find',
        'Paying for a school lunch',
        'Money you save',
      ],
      correctIndex: 2,
      explanation:
          'An expense is money you spend. Lunch costs money, so it is an '
          'expense.',
    ),
  ],
  'test_1': <QuizQuestion>[
    QuizQuestion(
      id: 'kt1a',
      skillId: QuizSkills.saving,
      prompt:
          'Mia has 10 dollars. She wants a game that costs 30. What is '
          'the best plan?',
      options: [
        'Spend it on candy now',
        'Ask a stranger for money',
        'Forget about the game',
        'Save some each week until she has 30',
      ],
      correctIndex: 3,
      explanation:
          'Saving a little each week gets her there. Spending it now '
          'puts the game further away.',
    ),
    QuizQuestion(
      id: 'kt1b',
      skillId: QuizSkills.budgetBuilding,
      prompt: 'You have 10 dollars and plan to spend 6. How much is left?',
      options: ['3', '4', '6', '16'],
      correctIndex: 1,
      explanation: '10 take away 6 is 4. That is what you can save.',
    ),
    QuizQuestion(
      id: 'kt1c',
      skillId: QuizSkills.expenses,
      prompt: 'Why is it good to write down what you spend?',
      options: [
        'So you can see where your money goes',
        'So the money grows',
        'So you never spend again',
        'So stores give you more',
      ],
      correctIndex: 0,
      explanation:
          'Writing it down shows where your money went, so you can '
          'change what you do next time.',
    ),
    QuizQuestion(
      id: 'kt1d',
      skillId: QuizSkills.budgetBasics,
      prompt:
          'Your plan says save 2 dollars a week. How much do you have '
          'after 5 weeks?',
      options: ['7', '2', '10', '25'],
      correctIndex: 2,
      explanation: '2 dollars, 5 times, is 10 dollars.',
    ),
  ],

  // ---- Unit 4: Spending Traps ----------------------------------------
  'quiz_7': <QuizQuestion>[
    QuizQuestion(
      id: 'kq7a',
      skillId: QuizSkills.advertising,
      prompt: 'Why do ads make toys look so much fun?',
      options: [
        'To help you save',
        'So you will want to buy them',
        'Because every toy is the best',
        'To teach you math',
      ],
      correctIndex: 1,
      explanation:
          'Ads are made to make you want things. The toy may not be as '
          'fun at home.',
    ),
    QuizQuestion(
      id: 'kq7b',
      skillId: QuizSkills.impulseControl,
      prompt:
          'You see a toy you did not plan to buy. What is a smart thing '
          'to do?',
      options: [
        'Wait a day and think about it',
        'Buy it right now',
        'Buy two of them',
        'Cry until you get it',
      ],
      correctIndex: 0,
      explanation:
          'Waiting a day lets the "I want it now" feeling pass. If you '
          'still want it, you can plan for it.',
    ),
    QuizQuestion(
      id: 'kq7c',
      skillId: QuizSkills.digitalSpending,
      prompt: 'Gems in a game are bought with real money. Is it real money?',
      options: [
        'No, it is just a game',
        'Only on weekends',
        'Only if you win',
        'Yes, real money pays for them',
      ],
      correctIndex: 3,
      explanation:
          'Game gems and coins are bought with real money, even when '
          'they look like play money.',
    ),
  ],
  'test_7': <QuizQuestion>[
    QuizQuestion(
      id: 'kt7a',
      skillId: QuizSkills.scams,
      prompt:
          'A message says you won a prize. It asks for your password. '
          'What should you do?',
      options: [
        'Send it fast',
        'Do not send it, and tell a grown-up',
        'Send it to a friend',
        'Click every link',
      ],
      correctIndex: 1,
      explanation:
          'Real prizes never need your password. This is a trick, so '
          'tell a grown-up.',
    ),
    QuizQuestion(
      id: 'kt7b',
      skillId: QuizSkills.wantsVsNeeds,
      prompt: 'Which one is a need?',
      options: ['A new video game', 'A toy car', 'Food for dinner', 'Candy'],
      correctIndex: 2,
      explanation:
          'A need is something you must have, like food. The others are '
          'wants.',
    ),
    QuizQuestion(
      id: 'kt7c',
      skillId: QuizSkills.advertising,
      prompt: 'An ad says "Everyone has one!" What is it trying to do?',
      options: [
        'Tell you a true fact',
        'Help you save',
        'Give it away free',
        'Make you feel left out so you buy it',
      ],
      correctIndex: 3,
      explanation:
          'Saying everyone has one makes you feel left out. That feeling '
          'is what the ad is selling.',
    ),
    QuizQuestion(
      id: 'kt7d',
      skillId: QuizSkills.impulseControl,
      prompt: 'What does it mean to buy on impulse?',
      options: [
        'Buy something fast without thinking',
        'Save money in a bank',
        'Plan a buy for weeks',
        'Share with a friend',
      ],
      correctIndex: 0,
      explanation:
          'An impulse buy happens in the moment, without a plan. Those '
          'are the buys people wish they had not made.',
    ),
  ],

  // ---- Unit 5: Saving Systems ----------------------------------------
  'quiz_3': <QuizQuestion>[
    QuizQuestion(
      id: 'kq3a',
      skillId: QuizSkills.payYourself,
      prompt: 'You get your allowance. When is the best time to save?',
      options: [
        'After you spend the rest',
        'Right away, before you spend',
        'Only on your birthday',
        'Never',
      ],
      correctIndex: 1,
      explanation:
          'Save first. If you wait until after spending, there is often '
          'nothing left.',
    ),
    QuizQuestion(
      id: 'kq3b',
      skillId: QuizSkills.savingsAccounts,
      prompt: 'Why do people keep savings in a bank?',
      options: [
        'It keeps money safe and can grow a little',
        'Banks give out free toys',
        'Money vanishes at home',
        'It makes things cheaper',
      ],
      correctIndex: 0,
      explanation:
          'A bank keeps money safe, and a savings account adds a little '
          'extra to it over time.',
    ),
    QuizQuestion(
      id: 'kq3c',
      skillId: QuizSkills.sinkingFunds,
      prompt:
          'A gift for a friend costs 8 dollars. Their birthday is in 4 '
          'weeks. How much should you save each week?',
      options: ['1', '4', '2', '8'],
      correctIndex: 2,
      explanation: '8 dollars split over 4 weeks is 2 dollars a week.',
    ),
  ],
  'test_3': <QuizQuestion>[
    QuizQuestion(
      id: 'kt3a',
      skillId: QuizSkills.automation,
      prompt:
          'Some people make saving happen on its own each week. Why does '
          'that help?',
      options: [
        'It makes money vanish',
        'It means they cannot buy food',
        'It is a rule for kids only',
        'They never have to remember to do it',
      ],
      correctIndex: 3,
      explanation:
          'When saving happens by itself, forgetting cannot stop it. '
          'That is why it works.',
    ),
    QuizQuestion(
      id: 'kt3b',
      skillId: QuizSkills.irregularCosts,
      prompt: 'Your bike tire might pop one day. What is smart to do now?',
      options: [
        'Hope it never happens',
        'Keep a little money saved for fixes',
        'Spend all your money today',
        'Buy a new bike every week',
      ],
      correctIndex: 1,
      explanation:
          'Things break. Money saved for fixes means a flat tire is a '
          'small problem, not a big one.',
    ),
    QuizQuestion(
      id: 'kt3c',
      skillId: QuizSkills.saving,
      prompt: 'Jay saves 3 dollars every week for 4 weeks. How much is that?',
      options: ['7', '3', '12', '34'],
      correctIndex: 2,
      explanation: '3 dollars, 4 times, is 12 dollars.',
    ),
    QuizQuestion(
      id: 'kt3d',
      skillId: QuizSkills.payYourself,
      prompt: 'What does "pay yourself first" mean?',
      options: [
        'Put some money in savings before you spend',
        'Buy yourself a treat first',
        'Pay your friends back',
        'Spend it all on you',
      ],
      correctIndex: 0,
      explanation:
          'It means your savings get paid before anything else, like a '
          'bill you owe yourself.',
    ),
  ],

  // ---- Unit 6: Money by the Numbers ----------------------------------
  'quiz_8': <QuizQuestion>[
    QuizQuestion(
      id: 'kq8a',
      skillId: QuizSkills.percentages,
      prompt: 'What is half of 10 dollars?',
      options: ['2 dollars', '5 dollars', '10 dollars', '20 dollars'],
      correctIndex: 1,
      explanation: 'Half means 2 equal parts. 10 split in 2 is 5.',
    ),
    QuizQuestion(
      id: 'kq8b',
      skillId: QuizSkills.chartReading,
      prompt: 'A chart shows a line going up each week. What does that mean?',
      options: [
        'The number is getting bigger',
        'The number is getting smaller',
        'Nothing changed',
        'The chart is broken',
      ],
      correctIndex: 0,
      explanation: 'A line going up means the number is growing.',
    ),
    QuizQuestion(
      id: 'kq8c',
      skillId: QuizSkills.spendingTracking,
      prompt: 'You write down every time you buy a snack. What can you learn?',
      options: [
        'How tall you are',
        'What time it is',
        'How much you spend on snacks',
        'Nothing at all',
      ],
      correctIndex: 2,
      explanation:
          'Your list adds up what snacks really cost you, which is '
          'usually more than you guessed.',
    ),
  ],
  'test_8': <QuizQuestion>[
    QuizQuestion(
      id: 'kt8a',
      skillId: QuizSkills.averages,
      prompt:
          'Sam saved 2, 4 and 6 dollars in three weeks. What is the '
          'average each week?',
      options: ['2', '6', '12', '4'],
      correctIndex: 3,
      explanation:
          'Add them up to get 12. Share 12 over 3 weeks and you get 4 '
          'a week.',
    ),
    QuizQuestion(
      id: 'kt8b',
      skillId: QuizSkills.misleadingCharts,
      prompt:
          'A chart has bars that start at 90, not at 0. Why can that trick '
          'you?',
      options: [
        'Small changes look huge',
        'It shows the real size',
        'Bars cannot trick anyone',
        'It makes numbers smaller',
      ],
      correctIndex: 0,
      explanation:
          'Starting high cuts off the bottom, so a tiny change looks '
          'like a big one. Always check where the bars start.',
    ),
    QuizQuestion(
      id: 'kt8c',
      skillId: QuizSkills.percentages,
      prompt: 'A toy is 10 dollars and 50% off. What is the new price?',
      options: ['10', '15', '5', '1'],
      correctIndex: 2,
      explanation: '50% is half. Half of 10 is 5.',
    ),
    QuizQuestion(
      id: 'kt8d',
      skillId: QuizSkills.spendingTracking,
      prompt:
          'Ana spent 3 dollars on Monday and 2 on Tuesday. How much in '
          'total?',
      options: ['1', '5', '6', '32'],
      correctIndex: 1,
      explanation: '3 and 2 more is 5 dollars.',
    ),
  ],

  // ---- Unit 7: Credit ------------------------------------------------
  'quiz_2': <QuizQuestion>[
    QuizQuestion(
      id: 'kq2a',
      skillId: QuizSkills.credit,
      prompt: 'If you borrow money, what do you have to do?',
      options: [
        'Keep it forever',
        'Pay it back',
        'Give it to a friend',
        'Forget about it',
      ],
      correctIndex: 1,
      explanation:
          'Borrowed money belongs to someone else. You have to pay it '
          'back.',
    ),
    QuizQuestion(
      id: 'kq2b',
      skillId: QuizSkills.banking,
      prompt: 'What does a bank do?',
      options: [
        'Makes toys',
        'Grows food',
        'Fixes cars',
        'Keeps money safe for people',
      ],
      correctIndex: 3,
      explanation:
          'A bank keeps money safe, and lends some of it to people who '
          'need to borrow.',
    ),
    QuizQuestion(
      id: 'kq2c',
      skillId: QuizSkills.emergencyFund,
      prompt: 'What is an emergency fund for?',
      options: [
        'Surprise problems, like a broken phone',
        'Buying candy every day',
        'Showing off',
        'Games only',
      ],
      correctIndex: 0,
      explanation:
          'An emergency fund is money kept for surprises, so a problem '
          'does not mean borrowing.',
    ),
  ],
  'test_2': <QuizQuestion>[
    QuizQuestion(
      id: 'kt2a',
      skillId: QuizSkills.credit,
      prompt:
          'When you borrow money, you often pay back a bit more than you '
          'got. Why?',
      options: [
        'It is a gift',
        'You win a prize',
        'The lender charges extra for lending it',
        'Money grows on trees',
      ],
      correctIndex: 2,
      explanation: 'The extra is called interest. It is what borrowing costs.',
    ),
    QuizQuestion(
      id: 'kt2b',
      skillId: QuizSkills.goals,
      prompt: 'Which one is a money goal?',
      options: [
        'Eating lunch',
        'Saving 20 dollars for a new ball',
        'Going to sleep',
        'Watching a movie',
      ],
      correctIndex: 1,
      explanation:
          'A money goal names what you are saving for and how much it '
          'takes.',
    ),
    QuizQuestion(
      id: 'kt2c',
      skillId: QuizSkills.investingBasics,
      prompt: 'What does it mean to invest money?',
      options: [
        'Hide it under your bed',
        'Spend it on snacks',
        'Put it somewhere it can grow over time',
        'Throw it away',
      ],
      correctIndex: 2,
      explanation:
          'Investing means putting money to work so it can grow, though '
          'it can also go down.',
    ),
    QuizQuestion(
      id: 'kt2d',
      skillId: QuizSkills.credit,
      prompt: 'Why should you only borrow what you can pay back?',
      options: [
        'Borrowing is always free',
        'Lenders never ask for it back',
        'To get more toys',
        'So you do not end up owing more than you have',
      ],
      correctIndex: 3,
      explanation:
          'Borrowing more than you can pay back leaves you owing money '
          'you do not have, and it costs extra the longer it lasts.',
    ),
  ],

  // ---- Unit 8: Real-World Money Moves --------------------------------
  'quiz_5': <QuizQuestion>[
    QuizQuestion(
      id: 'kq5a',
      skillId: QuizSkills.taxes,
      prompt:
          'Part of the money people earn goes to the government. What is '
          'it called?',
      options: ['Taxes', 'Tips', 'Toys', 'Tickets'],
      correctIndex: 0,
      explanation:
          'That part is taxes. Grown-ups take home less than they earn '
          'because of them.',
    ),
    QuizQuestion(
      id: 'kq5b',
      skillId: QuizSkills.livingCosts,
      prompt: 'Which one is a cost of living in a home?',
      options: [
        'A birthday party',
        'Paying for water and lights',
        'A new game',
        'A movie ticket',
      ],
      correctIndex: 1,
      explanation:
          'Water and lights are bills every home pays each month. The '
          'others are choices.',
    ),
    QuizQuestion(
      id: 'kq5c',
      skillId: QuizSkills.jobOffers,
      prompt:
          'Two jobs pay the same. One is close to home. Why might that '
          'one be better?',
      options: [
        'It has a nicer name',
        'Far jobs pay nothing',
        'It costs less time and money to get there',
        'It is always more fun',
      ],
      correctIndex: 2,
      explanation:
          'Getting to work costs time and money too. A shorter trip '
          'leaves more of both.',
    ),
  ],
  'test_5': <QuizQuestion>[
    QuizQuestion(
      id: 'kt5a',
      skillId: QuizSkills.payStub,
      prompt:
          'A paper from work shows how much someone earned. What is it '
          'called?',
      options: ['A menu', 'A pay stub', 'A map', 'A ticket'],
      correctIndex: 1,
      explanation:
          'A pay stub shows what was earned, what was taken out, and '
          'what is left to take home.',
    ),
    QuizQuestion(
      id: 'kt5b',
      skillId: QuizSkills.taxes,
      prompt: 'What do taxes help pay for?',
      options: [
        'Only rich people',
        'Nothing at all',
        'Video games',
        'Roads, schools and parks',
      ],
      correctIndex: 3,
      explanation:
          'Taxes pay for things everyone shares, like roads, schools and '
          'parks.',
    ),
    QuizQuestion(
      id: 'kt5c',
      skillId: QuizSkills.moneyPlan,
      prompt:
          'Grown-ups earn money and have bills to pay. What helps them '
          'not run out?',
      options: [
        'Spending it all on day one',
        'Not looking at the bills',
        'Buying lots of treats',
        'A plan for their money',
      ],
      correctIndex: 3,
      explanation:
          'A plan says where each part of the pay goes, bills first, so '
          'it lasts the whole month.',
    ),
    QuizQuestion(
      id: 'kt5d',
      skillId: QuizSkills.livingCosts,
      prompt: 'Rent is 500 dollars and food is 200. What is the total?',
      options: ['300', '700', '500', '200'],
      correctIndex: 1,
      explanation: '500 and 200 more is 700 dollars.',
    ),
  ],

  // ---- Unit 9: Big Purchases -----------------------------------------
  'quiz_12': <QuizQuestion>[
    QuizQuestion(
      id: 'kq12a',
      skillId: QuizSkills.carCosts,
      prompt: 'A car costs money to buy. What else costs money?',
      options: [
        'Gas and repairs',
        'Nothing else',
        'Only the radio',
        'Only the color',
      ],
      correctIndex: 0,
      explanation:
          'A car needs gas, fixes and more for as long as you have it, '
          'not just on the day you buy it.',
    ),
    QuizQuestion(
      id: 'kq12b',
      skillId: QuizSkills.renting,
      prompt: 'What does it mean to rent a home?',
      options: [
        'You own it forever',
        'You pay to live there, but someone else owns it',
        'It is free',
        'You build it yourself',
      ],
      correctIndex: 1,
      explanation: 'Renting means paying the owner each month to live there.',
    ),
    QuizQuestion(
      id: 'kq12c',
      skillId: QuizSkills.buyOrWait,
      prompt:
          'You want something big but do not have enough money. What is '
          'a smart choice?',
      options: [
        'Take money from a friend',
        'Buy it anyway',
        'Wait and save until you can afford it',
        'Give up on saving',
      ],
      correctIndex: 2,
      explanation:
          'Waiting and saving means you own it with no money owed '
          'afterwards.',
    ),
  ],
  'test_12': <QuizQuestion>[
    QuizQuestion(
      id: 'kt12a',
      skillId: QuizSkills.loanOffers,
      prompt: 'A store says "only 10 dollars a month!" What should you check?',
      options: [
        'The color of the sign',
        'The total you will pay in the end',
        'If the store is big',
        'Nothing, it sounds cheap',
      ],
      correctIndex: 1,
      explanation:
          'A small monthly number can hide a big total. Multiply it out '
          'before you agree.',
    ),
    QuizQuestion(
      id: 'kt12b',
      skillId: QuizSkills.moveInCosts,
      prompt: 'When people move to a new home, what else can cost money?',
      options: [
        'Nothing at all',
        'Only the door',
        'Free pizza',
        'Boxes, a truck and things for the home',
      ],
      correctIndex: 3,
      explanation:
          'Moving costs more than the rent: boxes, a truck, and things '
          'like beds and pans.',
    ),
    QuizQuestion(
      id: 'kt12c',
      skillId: QuizSkills.carCosts,
      prompt: 'Why does a car keep costing money after you buy it?',
      options: [
        'Cars eat money',
        'Roads cost nothing',
        'It does not',
        'It needs gas, fixes and more',
      ],
      correctIndex: 3,
      explanation: 'Gas, repairs and other costs go on every month you own it.',
    ),
    QuizQuestion(
      id: 'kt12d',
      skillId: QuizSkills.buyOrWait,
      prompt:
          'A bike costs 100 dollars. You save 10 dollars a week. How many '
          'weeks until you can buy it?',
      options: ['5', '10', '100', '1'],
      correctIndex: 1,
      explanation: '10 dollars a week, 10 times, makes 100 dollars.',
    ),
  ],

  // ---- Unit 10: Investing Basics -------------------------------------
  'quiz_4': <QuizQuestion>[
    QuizQuestion(
      id: 'kq4a',
      skillId: QuizSkills.whyInvest,
      prompt: 'People put money in things that can grow. Why?',
      options: [
        'So it can grow over time',
        'To lose it fast',
        'To hide it',
        'Because it is a game',
      ],
      correctIndex: 0,
      explanation:
          'People invest so their money can grow over many years, though '
          'it can go down too.',
    ),
    QuizQuestion(
      id: 'kq4b',
      skillId: QuizSkills.risk,
      prompt: 'What does "risk" mean with money?',
      options: [
        'You always win',
        'You might lose some money',
        'Money is free',
        'Nothing can change',
      ],
      correctIndex: 1,
      explanation:
          'Risk is the chance of losing some money. Things that can grow '
          'more usually have more risk.',
    ),
    QuizQuestion(
      id: 'kq4c',
      skillId: QuizSkills.compounding,
      prompt:
          'You earn a little extra on your savings. Next year you earn '
          'extra on that extra too. What is this called?',
      options: ['Spending', 'A bill', 'A tax', 'Compound growth'],
      correctIndex: 3,
      explanation:
          'Growth on top of growth is compound growth. It is why '
          'starting early helps so much.',
    ),
  ],
  'test_4': <QuizQuestion>[
    QuizQuestion(
      id: 'kt4a',
      skillId: QuizSkills.investorMindset,
      prompt:
          'Your money went down a little this week. What do patient '
          'people do?',
      options: [
        'Panic and quit',
        'Wait, because it can go up again over years',
        'Spend it all',
        'Hide under a blanket',
      ],
      correctIndex: 1,
      explanation:
          'Prices go up and down every week. Patient people think in '
          'years, not days.',
    ),
    QuizQuestion(
      id: 'kt4b',
      skillId: QuizSkills.assetTypes,
      prompt: 'If you own a tiny part of a company, what do you own?',
      options: ['A stock', 'A bike', 'A ticket', 'A coupon'],
      correctIndex: 0,
      explanation: 'A stock, or share, is a small piece of a company.',
    ),
    QuizQuestion(
      id: 'kt4c',
      skillId: QuizSkills.risk,
      prompt: 'Why is it smart not to put all your money in one place?',
      options: [
        'It is against the law',
        'Banks say so',
        'If that one thing goes bad, you do not lose it all',
        'It makes money vanish',
      ],
      correctIndex: 2,
      explanation:
          'Spreading it out means one bad choice only hurts part of your '
          'money.',
    ),
    QuizQuestion(
      id: 'kt4d',
      skillId: QuizSkills.whyInvest,
      prompt: 'Money left in a box for 10 years usually ends up how?',
      options: [
        'Doubled by itself',
        'Turned into gold',
        'Able to buy a little less, because prices go up',
        'Grown like a plant',
      ],
      correctIndex: 2,
      explanation:
          'Money in a box stays the same number, but prices rise, so it '
          'buys less later.',
    ),
  ],

  // ---- Unit 11: Stocks and Trading -----------------------------------
  'quiz_6': <QuizQuestion>[
    QuizQuestion(
      id: 'kq6a',
      skillId: QuizSkills.shareOwnership,
      prompt: 'What is a share of a company?',
      options: [
        'A tiny piece of the company',
        'A free toy',
        'A job there',
        'A coupon',
      ],
      correctIndex: 0,
      explanation:
          'A share is a small piece of the company. If the company does '
          'well, the piece can be worth more.',
    ),
    QuizQuestion(
      id: 'kq6b',
      skillId: QuizSkills.priceMovement,
      prompt:
          'Lots of people want to buy a stock. What often happens to its '
          'price?',
      options: [
        'It goes down',
        'It goes up',
        'It stays the same forever',
        'It disappears',
      ],
      correctIndex: 1,
      explanation:
          'When more people want to buy than sell, the price usually '
          'goes up.',
    ),
    QuizQuestion(
      id: 'kq6c',
      skillId: QuizSkills.tradingCosts,
      prompt:
          'Some apps charge a fee each time you buy or sell. Why does '
          'that matter?',
      options: [
        'Fees are free',
        'Fees give you money',
        'It does not matter',
        'Buying and selling a lot means paying lots of fees',
      ],
      correctIndex: 3,
      explanation:
          'Every fee takes a little. Trading often adds up to a lot of '
          'little fees.',
    ),
  ],
  'test_6': <QuizQuestion>[
    QuizQuestion(
      id: 'kt6a',
      skillId: QuizSkills.timeInMarket,
      prompt:
          'Is it usually better to keep a good stock for years, or sell '
          'it the next day?',
      options: [
        'The next day, always',
        'Sell it before you buy it',
        'Keeping it for years often works out better',
        'Never buy anything',
      ],
      correctIndex: 2,
      explanation:
          'Over many years, good companies tend to grow. Day-to-day '
          'swings matter less the longer you wait.',
    ),
    QuizQuestion(
      id: 'kt6b',
      skillId: QuizSkills.diversification,
      prompt: 'Why own bits of lots of companies, not just one?',
      options: [
        'So one bad company does not hurt as much',
        'To get more mail',
        'Because one is too boring',
        'It is the only way to buy',
      ],
      correctIndex: 0,
      explanation:
          'With many companies, one doing badly only hurts a small part '
          'of what you own.',
    ),
    QuizQuestion(
      id: 'kt6c',
      skillId: QuizSkills.priceMovement,
      prompt:
          'A stock was 10 dollars. Now it is 12. Did it go up or down, '
          'and by how much?',
      options: ['Down by 2', 'Up by 2', 'Up by 12', 'It did not change'],
      correctIndex: 1,
      explanation: 'From 10 to 12 is up by 2 dollars.',
    ),
    QuizQuestion(
      id: 'kt6d',
      skillId: QuizSkills.shareOwnership,
      prompt: 'A company you own a piece of does well. What can happen?',
      options: [
        'You have to pay the company',
        'You lose your piece',
        'Nothing ever happens',
        'Your piece can be worth more',
      ],
      correctIndex: 3,
      explanation:
          'When the company does well, people pay more for its pieces, '
          'so yours is worth more.',
    ),
  ],

  // ---- Unit 12: Retirement -------------------------------------------
  'quiz_9': <QuizQuestion>[
    QuizQuestion(
      id: 'kq9a',
      skillId: QuizSkills.retirementAccounts,
      prompt: 'Some old people stop work for good. What is that called?',
      options: [
        'Retirement',
        'A kind of candy',
        'The first day of school',
        'A job for kids',
      ],
      correctIndex: 0,
      explanation:
          'Retirement is when people stop working. They live on money '
          'they saved while they worked.',
    ),
    QuizQuestion(
      id: 'kq9b',
      skillId: QuizSkills.startingEarly,
      prompt:
          'Two people save the same each year. One starts at 20, one at '
          '30. Who likely has more later?',
      options: [
        'The one who started at 30',
        'The one who started at 20',
        'They will have the same',
        'Neither of them',
      ],
      correctIndex: 1,
      explanation:
          'Starting earlier gives money more years to grow, so it ends '
          'up bigger.',
    ),
    QuizQuestion(
      id: 'kq9c',
      skillId: QuizSkills.employerMatch,
      prompt:
          'Some jobs add extra money to what you save for when you are '
          'old. Is that a good deal?',
      options: [
        'No, never take it',
        'It costs too much',
        'Yes, it is like free extra savings',
        'Only on Fridays',
      ],
      correctIndex: 2,
      explanation:
          'Extra money from your job for saving is free money. Most '
          'people should take all of it.',
    ),
  ],
  'test_9': <QuizQuestion>[
    QuizQuestion(
      id: 'kt9a',
      skillId: QuizSkills.startingEarly,
      prompt: 'Why does starting to save early help so much?',
      options: [
        'Early money is bigger',
        'Banks like kids',
        'It does not help',
        'Money has more time to grow',
      ],
      correctIndex: 3,
      explanation:
          'Each extra year lets growth build on growth. Time does most '
          'of the work.',
    ),
    QuizQuestion(
      id: 'kt9b',
      skillId: QuizSkills.retirementAccounts,
      prompt: 'Why do grown-ups save money for when they stop working?',
      options: [
        'So they still have money to live on',
        'So they can work more',
        'Because they must spend it all',
        'To buy toys for the bank',
      ],
      correctIndex: 0,
      explanation: 'When the pay stops, savings pay for food, home and bills.',
    ),
    QuizQuestion(
      id: 'kt9c',
      skillId: QuizSkills.feesAndVesting,
      prompt:
          'A small fee comes out of savings every year. Over many years, '
          'what happens?',
      options: [
        'It stays tiny forever',
        'It adds up to a lot',
        'It gives you money back',
        'It goes away',
      ],
      correctIndex: 1,
      explanation:
          'A small fee every year, for many years, adds up to a big '
          'amount.',
    ),
    QuizQuestion(
      id: 'kt9d',
      skillId: QuizSkills.rothVsTraditional,
      prompt:
          'Some savings plans take tax now and some take it later. What '
          'should you do before picking one?',
      options: [
        'Pick the one with the best name',
        'Never save at all',
        'Learn how each one works',
        'Ask a toy store',
      ],
      correctIndex: 2,
      explanation:
          'Plans that look alike can work very differently. Learning how '
          'each works is how you pick well.',
    ),
  ],

  // ---- Unit 13: Protecting Your Money --------------------------------
  'quiz_13': <QuizQuestion>[
    QuizQuestion(
      id: 'kq13a',
      skillId: QuizSkills.identityTheft,
      prompt: 'Someone online asks for your password. What should you do?',
      options: [
        'Never share it, and tell a grown-up',
        'Share it if they are nice',
        'Post it for everyone',
        'Write it on your hand',
      ],
      correctIndex: 0,
      explanation:
          'Passwords are only for you. Anyone asking for one is trying to '
          'get into your things.',
    ),
    QuizQuestion(
      id: 'kq13b',
      skillId: QuizSkills.avoidableFees,
      prompt:
          'A bank charges a fee if you take out more than you have. How '
          'can you stay clear of it?',
      options: [
        'Take out more anyway',
        'Keep track and only use what you have',
        'Close your eyes',
        'Ask for a bigger fee',
      ],
      correctIndex: 1,
      explanation:
          'Knowing how much you have stops you taking out more, so the '
          'fee never happens.',
    ),
    QuizQuestion(
      id: 'kq13c',
      skillId: QuizSkills.complaints,
      prompt:
          'You bought a toy and it broke on the first day. What can you '
          'do?',
      options: [
        'Throw it away and say nothing',
        'Buy three more',
        'Ask the store to fix it, swap it or give the money back',
        'Break another one',
      ],
      correctIndex: 2,
      explanation:
          'Stores should make it right when something breaks straight '
          'away. Keep the receipt and ask.',
    ),
  ],
  'test_13': <QuizQuestion>[
    QuizQuestion(
      id: 'kt13a',
      skillId: QuizSkills.identityTheft,
      prompt: 'Someone uses your name to take money. What is it called?',
      options: [
        'Losing your lunch',
        'Forgetting your name',
        'Trading cards with a friend',
        'Identity theft',
      ],
      correctIndex: 3,
      explanation:
          'Identity theft is someone using your name or details to get '
          'money or things as if they were you.',
    ),
    QuizQuestion(
      id: 'kt13b',
      skillId: QuizSkills.creditReports,
      prompt:
          'Some places keep a record of how people pay back what they '
          'borrow. Why check your own record?',
      options: [
        'To spot mistakes, or someone using your name',
        'To change your name',
        'To get candy',
        'It is a game',
      ],
      correctIndex: 0,
      explanation:
          'Checking your record shows mistakes, or borrowing you never '
          'did, early enough to fix.',
    ),
    QuizQuestion(
      id: 'kt13c',
      skillId: QuizSkills.creditFreeze,
      prompt:
          'A "freeze" stops anyone borrowing money in your name. Who is '
          'it meant to stop?',
      options: [
        'You, from buying food',
        'Your school',
        'A stranger pretending to be you',
        'Your pet',
      ],
      correctIndex: 2,
      explanation:
          'A freeze locks your name so a stranger cannot borrow money '
          'pretending to be you.',
    ),
    QuizQuestion(
      id: 'kt13d',
      skillId: QuizSkills.avoidableFees,
      prompt:
          'A game app charges 1 dollar a month and you never play it. '
          'What should you do?',
      options: [
        'Keep paying anyway',
        'Cancel it to stop the charge',
        'Pay 2 dollars instead',
        'Buy another one',
      ],
      correctIndex: 1,
      explanation:
          'Canceling stops the charge. A dollar a month you never use is '
          '12 dollars a year gone.',
    ),
  ],
};

/// Every id in [kKidQuizAdditions].
final Set<String> kKidQuestionIds = <String>{
  for (final list in kKidQuizAdditions.values)
    for (final q in list) q.id,
};
