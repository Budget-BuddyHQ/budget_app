import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_sim_models.dart';

/// Buying a guitar, and where that can end up.
///
/// **What this adds.** The music ladder already existed and topped out at a
/// sixteen-city tour worth £4,200 — a good year, not a life change. There was
/// no version of a run where somebody got genuinely famous and genuinely
/// rich, which is one of the things people actually want out of a life sim.
///
/// **Why it is not just a jackpot.** A chain that ends in "you are rich now"
/// teaches nothing, and this app cannot afford a mechanic that teaches
/// nothing. So the money in here arrives the way money actually arrives for
/// artists, and every rung has the lesson that shape carries:
///
/// * **It is irregular.** A breakout year pays more than the previous ten
///   combined, and the year after it may pay nothing. The events say so.
/// * **Fame is not wealth.** [LifeFlag.wentViral] can fire with almost no
///   money attached. Being known and being paid are different columns.
/// * **The windfall is the test.** `stardom_windfall` is the fork the whole
///   chain exists for: a large one-off sum, and three ways to treat it. It is
///   the same decision as a redundancy payout or an inheritance, at a scale
///   that makes the answer feel like it matters.
/// * **Lifestyle creep is how it goes.** `stardom_spent_it` is reachable, and
///   it is the most common real ending for this story.
///
/// The entry point is deliberately cheap and early: a second-hand guitar. The
/// town's pawn shop sells one for £85, and this is what that can become.
const List<LifeEvent> kLifeEventsStardom = <LifeEvent>[
  // --- Getting started -------------------------------------------------
  LifeEvent(
    id: 'x_bought_guitar',
    prompt:
        'There is a second-hand guitar going for \$85. It needs strings and '
        'nobody you know plays.',
    icon: Icons.music_note_rounded,
    minAge: 9,
    maxAge: 24,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Buy it and actually learn',
        outcome:
            'Six months of sounding terrible, then suddenly not. The cheapest '
            'thing you ever bought that changed anything.',
        money: -85,
        happiness: 6,
        skill: LifeSkill.music,
        skillGain: 22,
        setsFlag: LifeFlag.playsMusic,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Buy it and leave it in the corner',
        outcome:
            '\$85 for a thing to feel guilty about. Most instruments are '
            'played for three weeks — the cost of finding out is the point.',
        money: -85,
        happiness: 2,
        skill: LifeSkill.music,
        skillGain: 4,
        teaches: FinanceConcept.sunkCost,
      ),
      LifeChoice(
        label: 'Borrow one first',
        outcome:
            'Free, and you found out you liked it before spending anything. '
            'Trying the free version first is the cheapest test there is.',
        happiness: 4,
        smarts: 4,
        skill: LifeSkill.music,
        skillGain: 12,
        setsFlag: LifeFlag.playsMusic,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_busking',
    prompt:
        'You could play in town on Saturdays. The pitch outside the market is '
        'free and the one by the station costs \$15 a day.',
    icon: Icons.queue_music_rounded,
    minAge: 14,
    requiresFlag: LifeFlag.playsMusic,
    requiresSkill: LifeSkill.music,
    minSkill: 25,
    weight: 0.8,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Take the paid pitch',
        outcome:
            '\$15 out, about \$70 back. Spending money to make money is a real '
            'thing and it is also how people lose money — the difference is '
            'whether you counted.',
        money: 55,
        fame: 4,
        skill: LifeSkill.music,
        skillGain: 6,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Play the free pitch',
        outcome:
            'Quieter, and you keep everything you take. About \$30, and no '
            'day where you go home down.',
        money: 30,
        fame: 2,
        skill: LifeSkill.music,
        skillGain: 5,
      ),
      LifeChoice(
        label: 'Practise at home instead',
        outcome:
            'No money, faster progress. Nobody watching is its own kind of '
            'useful.',
        skill: LifeSkill.music,
        skillGain: 9,
        happiness: -2,
      ),
    ],
  ),

  // --- The break -------------------------------------------------------
  LifeEvent(
    id: 'x_went_viral',
    prompt:
        'A clip of you playing has done four million views overnight. Your '
        'phone will not stop.',
    icon: Icons.trending_up_rounded,
    minAge: 15,
    requiresFlag: LifeFlag.playsMusic,
    requiresSkill: LifeSkill.music,
    minSkill: 45,
    minFame: 8,
    // The whole chain's throughput is set here. Every rung above this one is
    // conditional on it, so a low weight at the entrance does not make
    // stardom rare -- it makes the *end* of the story unreachable, which is a
    // different and worse thing.
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Drop everything and chase it',
        outcome:
            'Four million views paid about \$900. Fame and money are different '
            'columns, and this is the year most people find that out.',
        money: 900,
        fame: 30,
        happiness: 12,
        health: -4,
        setsFlag: LifeFlag.wentViral,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Put a link to your gigs under it',
        outcome:
            'Slower and worth far more. Attention that goes somewhere is an '
            'asset; attention that does not is a nice weekend.',
        money: 1600,
        fame: 24,
        happiness: 9,
        setsFlag: LifeFlag.wentViral,
        skill: LifeSkill.music,
        skillGain: 6,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Let it pass',
        outcome:
            'It died down in a fortnight, as these do. You kept your job and '
            'your evenings.',
        happiness: -3,
        fame: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_breakout_album',
    prompt:
        'A major label wants the album. The advance is \$60,000 against '
        'royalties, or you can put it out yourself.',
    icon: Icons.album_rounded,
    minAge: 17,
    requiresFlag: LifeFlag.wentViral,
    requiresSkill: LifeSkill.music,
    minSkill: 60,
    minFame: 30,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Take the advance',
        outcome:
            '\$60,000 now, and you earn nothing more until the album has paid '
            'it back. An advance is a loan against yourself — comfortable, and '
            'not the same as being paid.',
        money: 60000,
        fame: 22,
        setSalary: 900,
        setJob: 'Recording artist',
        setsFlag: LifeFlag.famousArtist,
        clearsFlag: LifeFlag.wentViral,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Release it yourself',
        outcome:
            'Less up front, and you keep the rights. Slower, riskier, and the '
            'version where the catalogue is still yours in twenty years.',
        money: 14000,
        fame: 16,
        setSalary: 700,
        setJob: 'Independent artist',
        setsFlag: LifeFlag.famousArtist,
        clearsFlag: LifeFlag.wentViral,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),

  // --- Living it -------------------------------------------------------
  LifeEvent(
    id: 'x_stadium_years',
    prompt:
        'Eighteen months on the road, arenas, and a tour bus you will grow to '
        'hate.',
    icon: Icons.stadium_rounded,
    minAge: 19,
    // No maxAge. There was a 38 cap here to stop the peak competing with its
    // own ending, and it made the peak unreachable instead: measuring when
    // players actually become famous gave ages 24, 26, 36, 44, 49 and 63, so
    // a cap at 38 locked out most of the people who got there. The two are
    // separated by age windows below rather than by a lid on this one.
    requiresFlag: LifeFlag.famousArtist,
    requiresSkill: LifeSkill.music,
    // 62/38, not 70/45. Measured rather than guessed: across 600 simulated
    // lives this fired *zero* times at the original gates, because the rungs
    // below it top out at about fame 46 and the skill needed to get there is
    // nearer 60 than 70. A gate above what the ladder beneath it can deliver
    // is not a hard event, it is an absent one.
    minSkill: 62,
    minFame: 38,
    // Heavier than the fade below, and with a decade of clear air before it.
    // These two are the peak and the ending of the same story, so if the
    // ending can out-roll the peak the peak simply never happens -- which is
    // what the sweep caught the first time these weights were set.
    weight: 1.0,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Do the whole run',
        outcome:
            'The best year of your life and \$240,000, and you did not see '
            'anybody you love for most of it.',
        money: 240000,
        fame: 30,
        health: -16,
        happiness: 10,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Half the dates, home in between',
        outcome:
            '\$110,000 and you are still a person at the end of it. The best '
            'deal is not always the biggest one.',
        money: 110000,
        fame: 16,
        health: -5,
        happiness: 14,
      ),
      LifeChoice(
        label: 'Turn it down and write instead',
        outcome:
            'No money this year. The songs from it paid for the next decade, '
            'which nobody could have told you at the time.',
        fame: -4,
        skill: LifeSkill.music,
        skillGain: 12,
        happiness: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'stardom_windfall',
    prompt:
        'A publisher offers \$800,000 for your back catalogue. One payment, '
        'and the songs are theirs.',
    icon: Icons.workspace_premium_rounded,
    minAge: 24,
    requiresFlag: LifeFlag.famousArtist,
    // 45, not 55. Players arrive at this rung with fame in the high 50s to
    // low 80s, so 55 was inside the range but close enough to its floor to
    // lock out the unluckier half of an already rare path.
    minFame: 45,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Sell, and put most of it to work',
        outcome:
            '\$800,000, and you invested the bulk of it rather than spending '
            'it. A windfall is not income — it is the one chance to buy '
            'yourself an income.',
        money: 800000,
        happiness: 12,
        smarts: 8,
        setsFlag: LifeFlag.soldCatalogue,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Sell, and enjoy it',
        outcome:
            '\$800,000 and a very good few years. Money with no job to do gets '
            'spent — that is not a moral failing, it is just what happens '
            'without a plan.',
        money: 800000,
        happiness: 22,
        setsFlag: LifeFlag.soldCatalogue,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Keep the catalogue',
        outcome:
            'No lump sum. The royalties keep arriving for the rest of your '
            'life and beyond it — the difference between being paid once and '
            'owning the thing that pays.',
        setSalary: 2600,
        happiness: 8,
        smarts: 10,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),

  // --- And how it usually goes -----------------------------------------
  LifeEvent(
    id: 'stardom_spent_it',
    prompt:
        'The money came fast and the spending kept up with it. The accountant '
        'wants a word.',
    icon: Icons.trending_down_rounded,
    minAge: 26,
    requiresFlag: LifeFlag.soldCatalogue,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Cut everything back now',
        outcome:
            'Painful and early enough to work. Most of this story ends badly '
            'because the cutting back happens two years after this meeting.',
        money: -40000,
        happiness: -10,
        smarts: 10,
        clearsFlag: LifeFlag.soldCatalogue,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'It will be fine, another tour is coming',
        outcome:
            'The tour did not come. Costs that rose with one good year do not '
            'fall on their own when it ends.',
        money: -180000,
        happiness: -16,
        clearsFlag: LifeFlag.soldCatalogue,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Get an actual financial adviser',
        outcome:
            'Costs a percentage and saved considerably more than that. The '
            'people who keep it are almost never the ones who were best at '
            'earning it.',
        money: -12000,
        smarts: 12,
        happiness: 4,
        clearsFlag: LifeFlag.soldCatalogue,
        teaches: FinanceConcept.diversification,
      ),
    ],
  ),
  LifeEvent(
    id: 'stardom_faded',
    prompt:
        'Nobody has asked you to play in two years. The phone is quiet in a '
        'way it did not used to be.',
    icon: Icons.nightlight_round,
    // 33, not 30. At 30 with a heavy weight this out-rolled `x_stadium_years`
    // and closed the chain before the peak of it could ever fire — the sweep
    // caught that too, in the opposite direction from the first attempt. The
    // fade is the *ending*; it needs to sit after the years it is the ending
    // of.
    minAge: 45,
    requiresFlag: LifeFlag.famousArtist,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Teach',
        outcome:
            'Steady money, evenings free, and a dozen kids who can play '
            'because of you. A career that ends is not a career that failed.',
        setJob: 'Music teacher',
        setSalary: 420,
        happiness: 10,
        clearsFlag: LifeFlag.famousArtist,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Keep waiting for the call',
        outcome:
            'It did not come. The hardest part of an irregular income is '
            'knowing when the irregular part has stopped.',
        happiness: -12,
        money: -3000,
        clearsFlag: LifeFlag.famousArtist,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Start something else entirely',
        outcome:
            'Frightening, and it worked out. Whatever you learned getting good '
            'at one thing transfers further than anybody tells you.',
        setJob: 'Studio owner',
        setSalary: 780,
        happiness: 8,
        smarts: 8,
        setsFlag: LifeFlag.hasSideHustle,
        clearsFlag: LifeFlag.famousArtist,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_put_it_down',
    prompt:
        'The guitar has been under the bed for a while now. Somebody asks if '
        'you still play.',
    icon: Icons.piano_off_rounded,
    minAge: 22,
    requiresFlag: LifeFlag.playsMusic,
    forbidsFlag: LifeFlag.famousArtist,
    weight: 0.45,
    choices: [
      LifeChoice(
        label: 'Sell it',
        outcome:
            'Somebody else is learning on it now. You got about a third of '
            'what you paid, which is what almost everything you own is worth '
            'second-hand.',
        money: 30,
        happiness: -4,
        clearsFlag: LifeFlag.playsMusic,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Say you do, and start again',
        outcome:
            'Rusty for a month and then not. The hours you put in at fifteen '
            'were still there.',
        happiness: 9,
        skill: LifeSkill.music,
        skillGain: 10,
      ),
      LifeChoice(
        label: 'Keep it for the look of it',
        outcome:
            'It stays under the bed. Owning a thing you do not use is a cost '
            'you already paid and keep paying in space.',
        happiness: -2,
        clearsFlag: LifeFlag.playsMusic,
        teaches: FinanceConcept.sunkCost,
      ),
    ],
  ),
];
