# Budget Buddy — Congressional App Challenge submission

**What it is:** a financial-literacy app for ages 4 to 21+, built as a game.
Eleven screens, a 13-unit sourced curriculum, three arcade games, a life
simulation and a walkable town — all built around one idea: *money lessons
stick when you have to spend money to learn them.*

**Built in:** Flutter/Dart, with Supabase for accounts, cloud save and
leaderboards, and live market data from Finnhub and Twelve Data.

**Scale:** ~79,000 lines of Dart across 129 files, 1,091 automated tests,
`flutter analyze` clean.

---

## The problem

Financial literacy is taught, when it is taught at all, as a subject: a
worksheet on compound interest, a unit on credit scores. The trouble is that
none of it costs anything to get wrong. A student can answer "what is an
emergency fund" correctly and still have no experience of *needing* one.

Meanwhile the apps that do teach money well are aimed at adults who already
have income to manage, and the ones aimed at children are usually allowance
trackers with a parent on the other end.

**Budget Buddy's answer:** put the decision before the definition. Every part
of the app asks you to *spend* something — money, moves, a turn, a year of a
life — and then tells you what that choice was called.

---

## How it teaches

Three mechanisms, deliberately different from each other, because a fourteen-
year-old and a five-year-old do not learn the same way.

### 1. Consequence — the life simulation

You live one year at a time from birth to retirement. Each year offers one of
176 events with real choices, and cash, savings, investments, debt, happiness,
health and smarts all move with them. The pool is deepest where a run spends
the most turns: 20 to 34 eligible events in the school years, 57 to 71 in
adulthood, so neither half of a life is a rerun of the other.

The design rules that make it teach rather than entertain:

* **The money panel always shows all four boxes** — cash, saved, invested,
  owed — including the empty ones. An empty savings box *is* the lesson.
* **Expense shocks are scheduled, not random.** A car repair arrives whether
  or not you were ready, which is the entire argument for an emergency fund
  and cannot be made by a definition.
* **Options are age-gated.** A three-year-old cannot open a brokerage account.
  Before this was enforced, a toddler was being offered adult choices, and the
  simulation stopped being about anything.
* **Every outcome explains itself**, whether the choice was good or not. A
  choice that just deducts money teaches you to fear the button.

### 2. Mechanics — the arcade

Three games where the money idea *is* the rule, not a quiz attached to one.

**Coin Cascade** (match-3, ages 4+) — needs pay your bills down, wants score
best and raise them, savings are the only thing that reaches the goal, coins
buy extra moves. Chase the biggest matches and you lose. That is 50/30/20 with
the numbers taken out, and it is playable by someone who cannot read yet.
Seven levels change *what you have to think about*: bills arriving every three
moves, coins worth double on a short budget, wants costing double.

**Finance Brawl** (survival + quiz) — waves of debts to pay off, with a
level-up every few waves offering three of nine upgrade tracks. Maxed tracks
leave the pool, so the choices narrow and late picks are between things you
actually want. Every few waves a **literacy checkpoint** interrupts with three
questions from a 140-question bank.

**Market Board** — real quotes and real candles, a pan/zoom/scrub chart, and a
portfolio with profit-and-loss history. Ten coins to the dollar with fractional
shares, so a player with a few hundred coins holds something real. Simulated
tickers do not teach volatility; a market that moved while you were asleep
does.

### 3. Instruction — the Academy, with sources

Thirteen units, 63 lessons, 13 quizzes, 13 unit tests and 186 questions, in age
order from "what is money" (4–6) to protecting your money as an adult.

**Every lesson cites a primary source, and the build fails if one does not.**
CFPB, SEC/Investor.gov, IRS, Social Security Administration, FDIC, FTC, Bureau
of Labor Statistics, Department of Labor, Federal Student Aid, Treasury,
MyMoney.gov — federal agencies and the regulators' own education arms, never a
bank's blog. A source with something to sell is an advertisement with
footnotes.

`test/lesson_sources_test.dart` fails on an uncited lesson, a citation pointing
at a source that does not exist, a source that is not HTTPS or not on the
trusted-publisher allowlist, and a source that is defined and never used — an
unused citation is a URL nobody will notice has rotted.

Sources appear in three places: at the foot of every lesson, under each topic
you got **wrong** in a quiz review (the moment a citation is worth most — you
have just been told an answer you did not expect), and in a full list behind
the Academy's credibility card.

---

## The pages, and what each one does

### Home — "what should I do right now?"
The landing screen. Level and gold, the current objective, the daily plan, and
a route into everything else.

**How it was built:** an app with seven tabs and no answer to "what next" is a
menu, not a game. `DailyPlanController` picks the objective from what the
player has and has not done today, so the answer changes rather than being a
static list of features.

### Life — the main game
The life simulation, plus a hub in front of it with past lives and the endings
gallery. A run takes several minutes and ends permanently, so the hub exists to
preserve the moment where a player *decides* to start one.

**How it was built:** `LifeSimController` is a pure-Dart state machine with an
injectable `Random`, so a whole life can be simulated in a test without
pumping a widget. That is what made it possible to check things like "no event
repeats more than seven times in one life" and "every event in the pool can
fire for somebody" across 400 simulated lifetimes.

### Adventure — the town
A tile map you walk around with six buildings and five people. Walking there is
the game; the decision is the lesson. The same question asked on a feed and
asked after a walk are not the same experience.

**How it was built:** Bonfire/Flame over a Tiled map. Twelve buildings and 69
scenes, picked from the date *and* the character's age — so a bank visited at
twenty says something different at thirty, and the town is part of the life
rather than a side attraction. What you decide out there lands on the
character's cash, smarts and happiness, not only on the account. Every encounter has at least one option that costs
nothing, and the test suite refuses to accept one that does not: a scene where
spending is compulsory teaches the opposite of the point.

### Arcade
The three games above, with a catalogue card for each saying what you do, what
it teaches, how hard it is and how long a run takes — so a player can pick
something that fits the time they have.

**How it was built:** each game's *rules* live in a pure-Dart engine separate
from its screen. `coin_cascade_models.dart` has no Flutter import at all, which
is why its 27 tests can play whole runs — including one asserting that a bot
taking the first legal swap it sees does **not** always win, because a game a
random player always wins has no decisions in it.

### Learn — the Academy
The curriculum, the mastery tracking, and the credibility card.

**How it was built:** lesson content, citations and added depth live in
separate keyed tables that merge at render time, so a content edit is a content
diff rather than a change inside a 1,700-line screen file. Worked examples
scale to the reader's life stage — a 13-year-old sees allowance-sized numbers
and an adult sees rent-sized ones, from the same lesson.

### Daily — Money Habits, and the analyser

The analyser is the part that closes the loop. Everything else in the app
*generates* behaviour; this reads it back and says one useful thing about it.

It scores five areas separately — showing up, money moving, finishing,
understanding, trying things — and the separation is the design. A blended
score would hide the case the whole app is most at risk of: somebody who logs
habits every day, fills the jar, keeps a streak, and has saved no money. Habit
points are satisfying and they are not money, and if that is what is happening
the app has to be the thing that says so rather than the thing that celebrates
it.

Every finding is three parts: the number out of the player's own data, exactly
one thing to do today, and the money idea behind it, which links to the lesson
and its source. A finding that cannot show the evidence is a slogan; one that
ends in "consider reviewing your spending" hands the hard part back.


Pin habits, track a week, work through multi-step challenges, and fill a jar.

**How it was built:** the jar is drawn rather than assembled from an asset — a
glass jar that fills with individual coins as habit points accumulate, because
"look how much you have put away" needs a container you can see into. Its fill
is a fraction of the **whole** ladder rather than the current stage: stage-
relative progress resets to zero at each milestone, so the jar used to empty
itself at the exact moment the player was being congratulated.

### Style — Customize
Thirty skins across three families, and the Emerald Case.

**How it was built:** opening a case runs a reel built *around the already-
decided result* — the winner sits at a fixed index with random filler around
it. The ratchet sound is generated from the same easing curve the reel animates
on, so the ticks *are* the tiles crossing the marker rather than a noise
playing near them. A test reads the duration, tile count and curve out of both
the Dart and the Python and fails if they disagree.

### Profile
Account, settings, friends and the leaderboard. Friend codes are a uuid prefix;
adding one is a directed edge and reads as mutual, so either person adding the
other is enough.

**How it was built:** row-level security means a player can only ever insert a
friendship where they are the owner, and only ever delete their own. Under-13
accounts never appear on the global leaderboard — a privacy default, not a
setting.

---

## How it was made, technically

### Everything that can be pure Dart is
The life simulation, the match-3 engine, the quiz banks, the town scenarios and
the habit model have no Flutter dependency and take an injectable `Random`.
That is why 1,091 tests run in under thirty seconds and why the rules can be
tested as *rules* rather than through a UI.

### The art is generated and checked
The UI kit is sliced and recoloured from a source pack by a Python tool that
also emits the nine-slice rectangles. Villager skins are palette swaps of one
hand-drawn template, so a new character costs four colours rather than an art
commission. Sound is synthesised from the standard library — no third-party
audio ships, which was a deliberate decision when the alternative was
copyrighted game audio in a store submission.

The two typefaces are bundled rather than downloaded. `google_fonts` fetches a
face on first use, so a first launch with no network renders the whole app in
the platform fallback — the state a store reviewer or a child on school wifi is
most likely to hit. Neither face still publishes static per-weight files, so
`tool/fetch_fonts.py` downloads the variable font and cuts the nine instances
the app resolves to, and ships the OFL licence alongside them.

### The tests check things a screenshot would
Three suites exist because three classes of bug kept reaching a player:

* **`contrast_audit_test.dart`** walks the real widget tree of ten screens,
  reads every label's resolved colour, composites the backgrounds behind it,
  and fails anything below WCAG AA. Its first run found 47 illegible labels.
* **`responsive_layout_test.dart`** lays out every screen at eight viewports
  including landscape, because "it fits on my phone" is not a design.
* **`playtest_test.dart`** opens each screen and *presses every control on
  it*. The other suites check that a screen paints; almost every bug a player
  reported came from an interaction.
* **`text_fit_test.dart`** asks the renderer which single-line labels ran out
  of room. "The words are clipping" is a real report that source cannot
  answer — whether a label fits is only knowable after layout.

### Accessibility and safety are enforced, not intended
Colour contrast is a build failure. Under-13 accounts are excluded from public
listings by default. Every fact in the curriculum is attributable. No
third-party copyrighted asset ships.

---

## What was hard

**Making a side-view sprite that does not look inflated.** Four procedural
redraws, each fixing the previous one's flaw and introducing a new one, before
the conclusion that the hand-drawn original was the answer and the tooling
should recolour it rather than replace it. The lesson generalises: a generator
that reproduces a person's drawing is a generator that reproduces a person.

**A crash that only happened when the world moved.** Bonfire ticks its
components from inside the game widget's own build, so a proximity sensor
firing calls `setState` during the build phase — which throws. The hazard was
always there and became reproducible the moment NPCs started patrolling,
because an NPC walking *into* the player fires a sensor from a frame the player
did not initiate.

**Sound that is the picture.** The case-opening ratchet is generated by
inverting the reel's own easing curve, one tick per tile crossing the marker.
Getting there meant first making the reel travel a *fixed* distance — it used
to travel `4 × catalogue + index-of-winner` tiles, a different length for every
skin, which no pre-rendered sound can follow.

**Knowing when a fix is worse than the problem.** A detector for a stray pixel
on the sprites' heads was written and then deleted: against the front-facing
row it turned out to be the brim of the character's cap, and the detector only
recognised it in six of sixteen frames. An inconsistent fix to a non-problem is
worse than the non-problem.

---

## Where to look in the code

| | |
|---|---|
| The curriculum and its sources | `lib/models_.../lesson_data.dart`, `lesson_sources.dart`, `lesson_extras.dart` |
| The life simulation | `lib/controllers_.../life_sim_controller.dart` |
| The match-3 engine | `lib/models_.../coin_cascade_models.dart` |
| The town | `lib/models_.../town_spot_models.dart`, `town_scenarios.dart` |
| Colour and legibility | `lib/themes_colors/app_theme.dart` |
| Art and audio tooling | `tool/` |
| The three "would a player see this" suites | `test/contrast_audit_test.dart`, `responsive_layout_test.dart`, `playtest_test.dart` |

`docs/PAGES.md` describes every screen. `docs/ARCHITECTURE.md` is the full
change log, in order, with the reasoning behind each decision — including the
ones that were wrong.
