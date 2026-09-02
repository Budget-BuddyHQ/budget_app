# Congressional App Challenge — submission answers

Drafts for the entry form. Every number here is measured from the repo, not
estimated. **Read the notes before pasting** — two of these answers are yours
to make true, not mine.

Counts as of 1 September 2026: 79,000 lines of Dart across 129 files,
1,091 automated tests, 196 life events, 89 lessons in 13 units, 187 quiz
questions, 57 town scenarios, 40 cited sources, 24 skins, 16 finance concepts.

---

## 1. Please briefly describe what your app does. *(400 words max)*

Budget Buddy teaches financial literacy to people aged 4 to 21 by letting them
practise money decisions instead of reading about them.

The main game is a life simulator. You start at birth and age up a year at a
time, and each year hands you a real decision: split your first paycheck
between needs, wants and savings; decide whether an emergency fund is worth the
month you would spend building it; work out whether a 22% store card is a deal.
There are 196 events, and they chain — buying a second-hand guitar can lead to
busking, a viral clip, a label advance and arena years, or it can lead to the
guitar going under the bed, which is what usually happens. Runs can end badly:
you can go hungry, get ill, or retire at eighty having quietly compounded a
small salary into something. Sixteen finance concepts are tracked, and once you
have met one in play you can arm it as a "money idea" that changes the
simulation for the next several years — so the route to a strong run runs
through actually understanding something.

Around that sits an Academy of 89 lessons and 187 quiz questions, every claim
backed by one of 40 cited sources (Federal Reserve, CFPB, IRS, BLS) so students
can check that what the app told them is true. There is an explorable town with
57 money scenarios, a stock-market board that trades on live quotes, four
arcade mini-games, a daily habit tracker, and a budget-and-habit analyser that
reads the player's own logged behaviour and returns specific findings rather
than a score.

The design rule throughout: never say a number is good or bad, show what it
does. A budget slider does not grade you, it runs your year. An expense shock
does not lecture about emergency funds, it arrives in a year you did not plan
for one.

It is free, has no ads, no in-app purchases and no third-party advertising or
analytics SDKs, because it is built for children.

> **Note:** the form already shows "Budget Buddy immerses the user with" typed
> in that box — clear it before pasting.

---

## 2. What inspired you to create this app? *(400 words max)*

> **This one is yours.** I can tell you what the app argues, but not what
> happened to you. The draft below is a scaffold with the specifics left as
> brackets — judges can tell the difference between a real reason and a
> well-written one, and the real one wins.

Most financial-literacy material aimed at young people tells you facts.
Compound interest is powerful. Emergency funds matter. Credit-card interest is
high. All true, all forgettable, because none of it is attached to a decision
you made and had to live with.

[YOUR SPECIFIC MOMENT — watching a family member handle a bill, a class that
covered this badly or not at all, a first payslip whose deductions you did not
understand, a friend who got a store card at 18.]

What I kept noticing is that people do not fail at money because they do not
know the definition of an emergency fund. They fail because building one is
boring for eleven months and only obviously correct in the twelfth, and nothing
teaches that gap. A textbook cannot; it has no twelfth month.

A simulation can. If you skip savings for six years to buy things you want, the
app does not tell you off — it just eventually hands you a $900 car repair in a
year you have $140. That lands in a way a paragraph does not, and it lands
without shame, because it happened to a character.

I also wanted it to be honest enough to be trusted. Anyone can write a lesson
saying investing beats saving. So every factual claim in the Academy carries a
source link to the Federal Reserve, the CFPB, the IRS or the BLS, and a student
who does not believe a lesson can go and check it. That felt like the minimum
standard for an app trying to influence how somebody handles money.

And it needed to work for a nine-year-old and a nineteen-year-old, because the
gap between "too young to care" and "already made the mistake" is exactly where
this should be taught.

---

## 3. What technical difficulties did you face programming your app? *(400 words max)*

Three that were genuinely hard, all found by testing rather than by looking.

**Text that was clipping without ever erroring.** Labels were being cut off
across the app with nothing in the logs. I wrote a test that walks the rendered
widget tree and asks every paragraph whether it exceeded its lines or its
width. The first run was mostly false positives, and the reason was the test
environment: Flutter substitutes a placeholder font in tests where every glyph
is exactly one em wide, so every measurement came out about 1.7x too wide. The
right fix was not to calibrate around it but to bundle the real typefaces —
which also removed a font download on first launch in production. Once the
audit was honest it found a real bug: a label widget was measuring one font and
painting another, so text ellipsised inside a tile it actually fit in.

**A navigation bar whose labels vanished with no error at all.** The cause was
192px of horizontal padding inside an `Expanded`, which left the children zero
width. Nothing threw, because a Flutter `Column` only reports overflow on its
vertical axis — a child that is too wide paints outside its box silently. My own
audit had been skipping it too, because a zero-width box cannot overflow. I
fixed the audit first, confirmed it then caught the bug, and only then fixed the
bug.

**Balancing a simulation, which is a measurement problem rather than a coding
one.** The first version of hunger and illness produced an average lifespan of
35, with 86% of runs dead before sixty. Running 600 simulated lives and reading
the distributions showed the cause was not the numbers but a missing world —
taking the first option every year usually means never getting a job, so every
adult year starved. The second attempt made hunger mathematically unreachable:
a flat income rate produced an identical shortfall every year, permanently
under the threshold. Rolling it fixed that. Tuning the fame chain took four
attempts, and one of my fixes — an age cap on the peak event — made it worse,
which I only found by measuring the ages at which players actually become
famous, which turned out to span 24 to 63.

The general lesson: for anything with randomness in it, you cannot tell whether
it works by playing it. You have to run it a thousand times and read the shape.

---

## 4. What improvements would you make in a 2.0 version? *(400 words max)*

**Let people play without an account.** Right now you need an email address
before you can do anything, and the youngest players this is built for do not
have one. That is a barrier at exactly the wrong end of the age range, and it
also drags the whole app into territory — collecting a child's email — that a
guest mode would simply avoid. Local-first play with an optional account for
leaderboards and sync is the single biggest change I would make.

**A teacher and parent view.** The app already computes everything a classroom
would want — which concepts a student has met, quiz accuracy per topic, streak
length, which budget decisions they keep making. None of it is visible to
anyone but the player. A read-only class dashboard, with consent, would turn a
single-player game into something a teacher could assign, which is the biggest
available jump in how many people this reaches.

**A second town map, and a map format that carries its own collisions.** I have
the art for a second area but not its collision data, so the main road reads as
solid and cuts the town in half. Automatic detection was not good enough —
three separate heuristics all got it wrong — so 2.0 should import the editor's
own JSON export, where walkability is authored rather than guessed.

**Real notifications.** There was a toggle in Profile promising quest reminders
that controlled nothing, because no notification package was ever wired up. I
took it out rather than ship a setting that lies — but a streak-based app with
no way to remind you is losing the thing streaks are for, so 2.0 should build
it properly and put the switch back.

**Accessibility.** Colour contrast is audited by test, but screen-reader labels
are incomplete and text scaling above 1.3x is not covered. An app for ages 4 to
21 that a child with low vision cannot use is not finished.

**Offline-first sync.** Progress is local plus Supabase, but losing connection
mid-lesson currently loses that session's cloud write. A proper outbox queue
would make the app usable on school wifi.

**More languages.** Every string is hardcoded English, and the money content is
US-centric — dollars, IRS, 401(k) — which limits it geographically as much as
linguistically. Extracting the strings and abstracting the currency and tax
model is a large job and the right one.

**And more lives.** 196 events sounds like a lot until you play five runs. The
chain system makes new content cheap to add; it should get to 400.

---

## 5. If you used AI, tell us how you used it and what your team contributed. *(400 words max)*

> **Read this before you paste it.** This is the one answer I should not write
> for you, because it is a question *about* me. I have drafted it as accurately
> as I can from what actually happened in our sessions, but you are the only
> person who can confirm it is true, and you should edit until it is. The form
> says AI is allowed, that roughly 70% of last year's winners used it, and that
> honest disclosure helps. Overstating your own hand-coding is the one thing
> here that could actually sink the entry.

**Tools used:** Claude Code (Anthropic) as a pair programmer throughout;
Flutter/Dart as the framework; Supabase for the backend.

**What the AI did.** Claude wrote the large majority of the Dart. I described
what a feature should do and it produced the implementation, the tests and the
documentation; I reviewed it, ran it, and sent it back when it was wrong. It
also did work I could not have done by hand at this scale — running 600
simulated lives to tune event probabilities, auditing every colour pair in the
app against WCAG contrast ratios, and writing a test that walks the render tree
hunting for clipped text.

**What I did.** I designed the product. Every feature in this app exists
because I asked for it: the life simulator as the centre, money ideas as
armable powers, ranked mode, the fame chain, hunger and illness as run-enders,
the town, the analyser, the sourced Academy. I set the constraints that shaped
the code — that it must teach by consequence rather than by telling, that it
must never grade a child, that every factual claim needs a citation.

I play-tested continuously, and most of the fixes in this repo started as
something I found and reported: the broken navigation bar, misaligned tutorial
boxes, clipped text, sprite animation errors, sound levels, the map not
resetting. I made the calls when the AI was wrong, or when there was no right
answer in the code — art direction on the sprites, which features were worth
building, what the tone should be.

I also did the parts that are not code: the asset pipeline, the privacy
decisions, the Play Store preparation, and the judgement about what a
nine-year-old should be told about failing.

**Honest summary:** the code is largely AI-written and the product is mine. I
directed, specified, tested, corrected and decided; the AI implemented.

---

## 6. What did you learn or take away from the Congressional App Challenge? *(400 words max)*

> **Also yours.** This one is entirely about your experience and I would be
> making it up. Below are prompts, not a draft — pick two or three and write
> them in your own voice. Short and specific beats long and polished.

Things you could genuinely say, if they are true:

- **Shipping is a different skill from building.** The app worked months before
  it was releasable. The last stretch was a privacy policy, an acceptance flow,
  a data-safety form, contrast audits and account-deletion requirements — none
  of it fun, all of it the difference between a project and a product.
- **You cannot tell whether a game is balanced by playing it.** [The 600-life
  sweep, if it struck you the way it struck me.]
- **What you learned about the subject itself** — did building 89 lessons and
  40 citations change how you think about your own money?
- **What was harder than expected**, and what turned out easier.
- **Who you built it for.** If you tested it on a younger sibling, a cousin, a
  class, a parent — what they did that surprised you is the single most
  valuable sentence you can put in this box.
- **What you would tell someone starting next year.**

Avoid: "I learned a lot about coding and perseverance." True of every entry,
persuasive in none.

---

## Cover photo

One image, displayed in the Capitol for a year if you win. Strongest
candidates, in order:

1. **The life sim mid-run** — the year log with the age markers and the money
   decisions visible. It is the app's whole argument in one screen.
2. **The Play hub** with the hero card and the endings collection.
3. **The town map** with the character in it — most immediately readable as a
   game, least immediately readable as educational.

I would send #1. Judges see a lot of dashboards.
