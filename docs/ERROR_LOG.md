# Error log

Every fault worked on, with the reasoning that found it — not just what
changed. The entries are written so that somebody who has never seen the bug
can follow how it was cornered, because the *method* transfers and the fix
usually does not.

Format per entry: **Symptom** (what was actually reported), **Investigation**
(what was checked, in order, including the wrong turns), **Root cause**,
**Fix**, **Verified by**, and **What it cost** — how the bug stayed hidden,
which is the part worth reading twice.

Sessions are newest-first.

---

## Session — 2026-09-06

Reported in one message: eleven separate things, one of which turned out to be
three bugs wearing a trench coat.

### 1. The case-opening roll sounded bad

**Symptom.** *"I want to change the rolling sound since it's pretty bad."*
No detail beyond that, which is the normal amount of detail for a sound
complaint — people can hear that something is wrong long before they can say
what.

**Investigation.** The file is generated, not recorded, so the answer had to
be in `tool/make_sounds.py`. `case_roll()` mixes 72 ticks, one per skin tile
crossing the reel's marker. Each tick came from `_tick()`:

```python
env  = math.exp(-60 * t)            # tau ~ 17ms, over a 45ms tick
prev += 0.5 * ((rng.random()*2-1) - prev)   # filtered noise
body  = math.sin(2*math.pi*freq*t) * 0.42   # freq 1200 -> 1660 Hz
out.append((prev * 0.85 + body) * env)
```

Three things are wrong there and all three point the same way, which is what
made it worth measuring rather than tweaking:

* **Noise is the loudest component** — 0.85 against the body's 0.42. A click's
  noise is *contact*: three milliseconds, then gone. Carried for 45ms at the
  top of the mix it is not a mechanism, it is static with a pitch behind it.
* **1200–1660 Hz** is where a phone speaker is harshest and where a small
  driver has no body to put underneath. The roll read thin and shrill.
* **45ms is longer than the gap between early ticks.** Inverting the reel's
  easing curve gives a first gap of **10.5 ms**. So each tick was still
  ringing when the next two arrived, and the deceleration — which is the
  entire effect — was smeared into a buzz for its first second.

Measured, over the whole file: **4,602 zero crossings per second**, and
**9,872/s** through the first half-second. That is a number for "shrill".

**Root cause.** The tick was designed as noise with a tone under it. A ratchet
detent is the opposite: a body with a contact burst on top.

**Fix.** Rewrote `_tick()` as a struck detent — 3.2 ms contact transient
*under* a struck body at 520 → 370 Hz with inharmonic partials at 2.74× and
4.91×, a short sub-thump at 0.27× for weight on a phone speaker, ±1.5% pitch
jitter per tick so 72 of them do not sound like a loop, and 30 ms long instead
of 45. Pitch now **falls** across the roll rather than rising: the old version
climbed on the theory that rising pitch reads as tension, which is true of
something speeding up and wrong under a decelerating rhythm.

Added `_spin_bed()` — a filtered noise bed whose level tracks the reel's actual
speed and is gone by the time the ticks can be counted individually. The fast
stretch needed body that the ticks could not provide at that density.

Deliberately **no reverb**, unlike every other sound in the file. A tail long
enough to hear would fill the gaps between ticks, and the gaps *are* the
effect.

First attempt at the bed used a multiplier of 3.6. Measured: bed peak 0.65
against a tick's 0.74, and 75% of the energy in the opening third of a second.
That is not a bed, it is a noise wash with ticks somewhere behind it. Dropped
to 1.1 → 11% of the energy.

**Verified by.** `test/audio_quality_test.dart`, new group *the case ratchet is
a mechanism, not static*: whole-file brightness `< 1500` (was 4,602), opening
`< 2000` (was 9,872), pitch falls rather than rises, and the structural shape —
dense head, a silent second, one heavy landing — is asserted as three RMS
measurements. `case_roll_sync_test.dart` still passes, so the ticks and the
reel are still the same event.

**What it cost.** Nothing in code review can hear a sound. The generator reads
perfectly; every constant in it is defensible in isolation. The only way to
find this was to measure the output, which is why the measurements are now
tests.

---

### 2. Music inaudible, effects too loud

**Symptom.** *"I want the background sound to be louder and the other sounds
toned down a bit."*

**Investigation.** `AppSoundService` has two levers: per-file peak targets
baked in by `make_sounds.py` (the *mix*, how sounds sit against each other) and
runtime `_volumes` (the app's overall loudness). The complaint is about the
ratio, so it belongs to the runtime table.

The music was at **0.18**. The quietest effect — navigation, which fires on
every tab switch — was **0.22**. So the background track was quieter than the
interface's own punctuation. That is not "a bit quiet", it is inaudible in
practice, and it explains why it read as not playing at all.

**Fix.** Music 0.18 → **0.34**. Every effect down about 30%, preserving the
existing order, which was right: loudness is the inverse of how often a sound
fires.

**Verified by.** `test/audio_mix_test.dart` — the loop must be louder than the
quietest effect, no effect above 0.5, and navigation must stay quietest by a
margin of at least 6 dB against celebration. The last one matters because
turning everything down uniformly would have preserved the ordering by
accident rather than on purpose.

---

### 3. Sound stopped playing until the Music toggle was cycled

**Symptom.** *"The sound sometimes just wouldn't play and then I would have to
toggle off and on the music button in the profile."*

**Investigation.** The workaround is the clue. What does that toggle do that
nothing else does? `setMusicEnabled(false)` → `_disposeMusic()` →
`setMusicEnabled(true)` → `startMusic()`. It is the only path in the entire app
that **disposes and recreates** an `AudioPlayer`.

So the question became: what state can a player get into that only a rebuild
escapes? Reading `startMusic()`:

```dart
if (_music != null) return;
```

There it is. *"Already running"* was implemented as *"the object exists"*. An
`AudioPlayer` that exists and one that is playing are different things — the OS
can stop it in the background, an interruption can leave it paused, and
`play()` can fail after the field has already been assigned. In every one of
those the field stays non-null forever, so every later `startMusic()` — and it
is called from most screen entry points — returns immediately. The loop never
comes back, and the only recovery is the toggle.

Two more faults found while in there, both capable of producing the same
symptom for effects rather than music:

* **`initialize()` set `_playersReady = true` as its first statement**, then
  spent a dozen `await`s configuring sixteen players. Any `play()` arriving in
  that window saw the flag, skipped setup, and used an unconfigured player —
  meaning one still on `audioplayers`' default `AndroidAudioFocus.gain`, the
  "sole source of audio" setting that `audio_focus_test.dart` exists to keep
  out. One player holding it silences everything else in the app. **The focus
  bug could come back through a race even though the value it depends on never
  changed.**
* **No recovery path anywhere.** Every failure in `play()` was caught, logged,
  downgraded to a system click, and the broken player left in the map for the
  life of the process. One transient fault meant that effect was gone until
  restart.

And one hypothesis that cannot be proven from Dart but fits: the low-latency
path is a `SoundPool`, whose loaded samples Android may reclaim while the app
is backgrounded. When that happens `SoundPool.play()` returns 0 and plays
nothing **without throwing**, so no amount of error handling inside `play()`
can notice. Nothing in `audioplayers` reacts to the Android lifecycle — the
plugin only hears about the engine detaching.

**Fix.** Four changes:

1. `startMusic()` asks the player what state it is in, tries `resume()` first,
   and rebuilds if that fails.
2. `initialize()` is a single shared `Future`; `_playersReady` is set **last**,
   so it can only ever mean "finished" rather than "started".
3. `play()` heals — on failure it rebuilds that player and retries once before
   falling back to a system sound.
4. A `WidgetsBindingObserver` inside the service rebuilds all effect players
   and re-confirms the music on every resume. Unconditional, because the
   SoundPool case cannot be detected.

**Verified by.** `test/audio_mix_test.dart`, group *the music can come back*.
These are source assertions rather than behaviour tests, and that is a stated
limitation: `audioplayers` has no usable fake — every method goes to a platform
channel that does not exist under `flutter test` — so a "does the music
restart" test would be testing a no-op. What can be pinned is the *shape of the
code that got it wrong*, and that is what they pin.

**What it cost.** Intermittent, platform-specific, and invisible on a desktop.
The user found it by feel and the workaround they discovered was the diagnosis.

---

### 4. "Saved to Supabase." on every reward

**Symptom.** *"Whenever something is gained like coins or experience, the toast
always says something like saved to supabase — can we remove that part for all
the toasts."*

**Investigation.** `grep` for the literal string found nothing in the working
tree. `git log -S "Saved to Supabase" -- lib` found it in commit `8c45668`,
where it had been **renamed** to "Added to your account." So it was already
half-fixed, and the user was running an older build.

Renaming is not the fix, and that is the interesting part. Every reward flow
goes through `UserStatsController._saveStats`:

```dart
return StatsActionResult(
  success: true,
  message: syncState.message,   // <- the sync status, not a game event
  syncState: syncState,
);
```

So `result.message` on a **successful** save is not a description of what
happened in the game. Ten call sites had appended it to a reward line, giving:

> What Is Money? saved. Earned +12 XP, +50 Gold! Saved to Supabase.

Rename it to "Added to your account." and it is still a sentence about a
database in a nine-year-old's reward popup, present whether or not anything
went wrong.

**Fix.** Removed the sync tail from all ten reward toasts. Kept `result.message`
on genuine **failure** paths, where it carries a real reason ("Not enough
gold", "That skin is still locked"). A save that actually fails is still
surfaced — `CloudSyncBanner` renders nothing while sync is healthy and a
standing warning on the Profile screen when it is not, which is the right shape
for that information: persistent, and only present when it means something.

Also replaced two toasts whose entire message was the sync status with copy
about the thing that happened ("Your look is updated everywhere", the duplicate
skin's actual gold refund).

**Verified by.** `test/toast_copy_test.dart` — structural, not textual. No file
containing `GameToast.show` may read `syncState.message`, and no
player-visible string in the screens/widgets/controllers layers may name the
backend. Two deliberate exceptions in `supabase_service.dart` are documented
and out of scope: a `StateError` that is never rendered, and a "run the
migration" message aimed at whoever deploys this.

---

### 5. The password-reset email went to `localhost:3000`

**Symptom.** Tapping the reset link on a phone: **"This site can't be reached —
localhost refused to connect."**

**Investigation.** Checked the app side first, expecting to find the bug there.
Found the opposite — all three pieces were already correct and had been for
weeks:

* `passwordResetRedirectUrl` was `budgetbuddy://password-reset`.
* `AndroidManifest.xml` declared the intent-filter for that scheme.
* `main.dart` handled `AuthChangeEvent.passwordRecovery` and pushed
  `SetNewPasswordScreen`.

The emailed URL held the answer:
`…/auth/v1/verify?token=pkce_…&type=recovery&redirect_to=http://localhost:3000`.
The app never sends that value. `localhost:3000` is the **Site URL** a fresh
Supabase project ships with.

Supabase validates `redirect_to` against Site URL plus the Redirect allow-list.
When the value is not on that list it does **not** return an error — it
*silently substitutes the Site URL*. So one missing allow-list entry produces a
symptom that looks exactly like a broken app.

The `pkce_` token prefix also settled a second question: the flow is PKCE, so
the code verifier lives in the app instance that requested the reset. The link
must open **on that device**; there is no way around it, and the failure needs
explaining to the player rather than engineering away.

**Fix.** Three parts, all now in the repository rather than in somebody's
memory of a dashboard:

1. `docs/password-reset.html` — a real page on the existing GitHub Pages site,
   which reads the auth payload out of the URL and hands it to
   `budgetbuddy://`, and explains itself when the app is not installed or the
   link has expired.
2. `supabase/config.toml` — Site URL and allow-list as code, appliable with
   `supabase config push`.
3. `passwordResetRedirectUrl` now points at that page.

**Why the page, rather than just fixing the allow-list.** Two reasons, and the
second is the load-bearing one:

* Making the Site URL the *same page* as the allow-listed redirect removes the
  failure mode entirely. Getting the dashboard wrong can no longer produce a
  dead link, because the fallback and the intended target are the same.
* A `302` straight to a custom scheme is refused by several in-app browsers —
  Gmail's WebView especially — which reproduces the identical dead link on a
  perfectly configured project and is not fixable from the dashboard. Landing
  on an ordinary https page and letting *that* invoke the scheme is the path
  browsers actually permit.

**A bug introduced and caught during this fix.** The page's first version
classified the payload with substring matching:

```js
var hasCode = search.indexOf('code=') !== -1 || …
```

Tested it against four sample URLs before shipping it. The third one —
`?error=access_denied&error_code=otp_expired`, which is exactly what Supabase
sends for an **expired** link — came back `hasCode: true`, because
`error_code=` *contains* `code=`. The one branch written to catch a dead link
was guaranteed to treat a dead link as a live one and forward it to the app.
Rewrote it with `URLSearchParams`, which also allowed showing Supabase's own
`error_description` ("Email link is invalid or has expired") instead of
inferring one. Re-tested all five cases.

**Verified by.** `test/auth_redirect_test.dart` — the Dart constant, the
landing page, `config.toml` and `AndroidManifest.xml` must all agree, and the
config must contain no loopback address and no literal SMTP credential.
Nothing in a compiler connects a Dart constant to a TOML file to an XML
manifest to a page of JavaScript; this is that connection.

**What it cost.** The single most expensive shape of bug there is: correct
code, a silent substitution in a system nobody owns a diff of, and a symptom
that points at the wrong layer. Every instinct says "debug the app".

---

### 6. The email came from "Supabase Auth"

**Symptom.** *"Can I change the way that it says Supabase Auth and then change
the email on that."*

**Investigation.** The From header is `Supabase Auth
<noreply@mail.app.supabase.io>`. To a parent looking at their child's inbox
that is an unrecognised sender on an unrecognised domain asking them to click a
password link — which is a description of a phishing email. It is also a strong
spam signal.

There is no dashboard field for it. With Supabase's built-in mailer the From
header is fixed; the sender name and address only become settable once custom
SMTP is configured. The built-in mailer is additionally rate-limited to a few
messages an hour and documented as not for production, so this is worth doing
regardless.

**Fix.** Cannot be completed from the repository alone — it needs a provider
account, which is the user's to create. What is in the repo:

* `supabase/config.toml` carries the `[auth.email.smtp]` block, commented out,
  with `sender_name = "Budget Buddy"` and the password as `env(SMTP_PASSWORD)`.
* `docs/auth_emails/README.md` has the three steps, with Resend as the shortest
  path (free tier, sends from `onboarding@resend.dev` before any domain is
  verified, so the change can be seen today).
* A warning that matters: until a domain is verified, sending from it is
  **worse** than the Supabase default — it fails SPF/DKIM and goes to spam
  rather than to the inbox. Use the provider's sandbox sender first.

**Verified by.** `test/auth_redirect_test.dart` refuses a literal credential in
`config.toml`, scanning uncommented lines only — the comments necessarily quote
a `re_your_key_here` example, and a test that banned that would have made the
only sane way to document the fix a test failure.

---

### 7. Coin Cascade paid nothing, saved nothing, taught nothing out loud

**Symptom.** *"I want to know how the coin cascade game is going to teach them
about the financial literacy… sure it's satisfying but I don't even know what
to work for in that game."*

Read as a design question. It was two design gaps and one outright bug, and the
bug is the reason the sentence is literally true.

**Investigation.** Grepped the page for `UserStatsController`, `applyChallengePayload`,
anything that credits a player. Nothing. Then read the caller:

```dart
// MinigamesPage._openCoinCascade
await controller.recordArcadeRun(gameId: 'coin_cascade', score: game.score);
GameToast.show(context, message: '… +${game.goldEarned} gold');
```

And `recordArcadeRun`'s own documentation:

> Rewards are granted by the games themselves through `applyChallengePayload`;
> this only tracks the scoreboard, **so it must not touch gold or XP.**

The result card printed `+N gold`. The arcade toast printed it again. Nothing
anywhere paid it. **Every Coin Cascade run ever played announced a payout twice
and credited none of it.** "I don't know what to work for" was an accurate
description of the game, and the game had been telling players otherwise.

Two more gaps underneath:

* `_unlocked` was a field on the screen's `State` — thirteen levels of ladder
  progress deleted every time the page was popped. The comment defending that
  argued persisting it would hand a returning player level 7 with no idea what
  the earlier rules were. Real concern, wrong fix: the picker opens on the
  ladder in order, so an unlocked level is somewhere you *may* go, not where
  you are put.
* The mechanics have always been 50/30/20 — needs clear bills, wants raise
  them, savings win — and **the game never said so, at any point, to anybody.**
  A player could beat all thirteen levels without learning that the thing they
  had got good at had a name.

**Fix.**

* **The money is real.** `cascadePayoutFor()` — a pure function in the model,
  so the reward rules are testable instead of buried in a widget. First clear
  pays properly; a replay pays a token; a loss still pays for what it managed.
  Literacy points are first-clear only, because each level teaches one specific
  twist and replaying a solved level does not teach its rule again. Same rule
  the town uses: reward the progress, not the repetition.
* **Progress persists** to `spending_habits.cascade_cleared`.
* **`CascadeReport`** reads the finished run back as an allocation — the
  player's own board, not a worked example — with three bars in the tile
  colours they have been looking at for two minutes. It follows the rule the
  rest of the app follows: never say a number is good or bad, show what it did.
  No grade. `"Your wants added 18 bills. Clearing needs paid off 27. That gap
  is the reason a budget has a wants column rather than no wants at all."`
* **Payday Rush** — the timed mode that was asked for. 90 seconds, unlimited
  moves, bills on a 4-second clock instead of on turns. It changes the
  *pressure* rather than the numbers: the ladder's scarce resource is moves, so
  it rewards looking at the board; Rush's is time, so it rewards covering needs
  fast. Two different money skills, both real.

**A detail worth recording.** `game.goldEarned` was deleted rather than left
alone. A getter named that, computing a payout nothing credits, is exactly the
trap that caused this — it reads like it is already doing the job. Its one
useful property (savings must out-earn raw score, or the payout teaches the
opposite of the game) moved to the new function and kept its test.

**Verified by.** `test/cascade_teaching_test.dart` — 12 tests. The report's
arithmetic including a 500-iteration check that three independent roundings
still sum to ~100%; a check that the report never grades a child, run against
the worst possible run; Rush's mode-specific status rules including a late
timer tick being unable to retroactively lose a survived run; and a source
assertion that `applyChallengePayload` is called and that the hub no longer
quotes the uncredited figure. Rendered to
`build/screens/cascade_result.png` and looked at.

---

### 8. Friends were a list you could not open

**Symptom.** *"For the friends thing, make like a friend profile screen when you
tap on them."*

**Investigation.** The row showed a name and `6325 literacy · 8645956 gold`, and
tapping did nothing. That is a contact list, and it is the wrong shape: the
reason to add somebody in a game about money is to have a second data point for
how you are doing.

**Fix.** `FriendProfileScreen`, built around **comparison rather than display**
— every number against the viewer's own, with bars scaled to the larger of the
two so the bigger figure is always full width, and a sentence saying which way
round it is. Reachable from the Friends card (with Remove) and from the
leaderboard (view-only — a destructive action does not belong in a browsing
screen, and the global board lists people who are not friends at all).

**The constraint that shaped it.** Three of the sections need columns the
`leaderboard` view does not have. This project shipped the friends feature
ahead of `0002_friendships_rls.sql` and spent weeks showing players a raw
Postgres error code, so a feature that *requires* a migration is a feature that
breaks whenever somebody forgets to run one. Every new field defaults to empty
and its section is hidden rather than zeroed; `0005_leaderboard_profile.sql`
adds them, and the screen is worth opening either way.

`_lastSeen` rounds down in specificity as it ages — days, then weeks, then "not
played in a while". "Active 3 minutes ago" on a children's app is a presence
indicator, and a presence indicator tells other people when a child is on their
phone.

**Verified by.** Rendered to `build/screens/friend_profile.png` and looked at.
Caught the name printing twice — once in the app bar, once under the avatar,
200px apart — and a `? 'day streak' : 'day streak'` ternary that did nothing.

---

### 9. The town was a money farm

**Symptom.** *"By repeatedly entering certain places and town, users can get
more and more money for doing the exact same thing, so we need to fix that…
and make the map change or the options change as age gets older."*

**Investigation.** `AdventureWorldScreen._openSpot` hands the chosen option's
gold, XP and literacy to `applyChallengePayload` on every visit and remembers
nothing.

The precedent was two hundred lines above it. Coins on the floor **are**
de-duplicated, with a comment saying in as many words that a respawning coin
would be *"an unlimited tap on the economy"*. The buildings, which pay several
times more, had no equivalent — because the gold there is one indirection
further away.

Worse, the anti-repetition work had made it faster rather than causing it.
`TownCondition` is rolled once per entry and feeds the scene rotation, so
stepping outside and back in **re-deals all twelve buildings**. Exactly right
for keeping the place interesting; exactly wrong for the economy. The loop was:
leave, re-enter, take twelve paying choices, repeat.

The second half of the report was a separate fault. `townEncounterFor` already
mixed the character's age into *which* scene shows, but picked uniformly from
everything a building had. So a six-year-old could be handed `pawn_quick_cash`
("rent is short by $70 and payday is nine days away"), `bank_overdraft_fee`, or
a room-share advert — while `OutingPermission` was refusing to let that same
child leave the house alone.

**Fix.**

* A persisted ledger of resolved encounters, keyed on the **conversation**, not
  the building. Keying on the building would mean one visit shuts a shop
  forever and throws away the rotation; keying on the encounter means each
  distinct decision pays once and the town still has something different
  tomorrow.
* A settled encounter is free in **both** directions. Zeroing only the income
  would be worse than doing nothing — the shop would still take money for a
  purchase it no longer rewards, so re-reading a scene you had worked through
  would *cost* you.
* Said **before** the choice, not after. Letting somebody pick and then handing
  them nothing is the shape of a bug even when it is the intended rule.
* Age bands in a side table (`town_age_bands.dart`) rather than an argument on
  fifty-seven `const` entries — the policy is reviewable on one screen, which
  is the thing that actually needs checking.
* `hires` still passes through on a settled encounter. The job board saying
  "you already read this notice" and refusing to employ somebody now old enough
  would be a bug wearing an anti-farming rule as a disguise.

**Verified by.** `test/town_economy_test.dart` — 10 tests. The payout pool is
bounded and enumerable; the ledger key is stable within a day and names the
conversation rather than the building; no scene above a character's age is ever
offered between 6 and 12; growing up only ever *adds* content; and no building
runs out of things to say at any age from 6 to 90.

---

### 10. The desktop captcha opened a browser

**Symptom.** *"Make it so that even for PC it uses the captcha instead of going
to the website."*

**Investigation.** `_supportsEmbeddedWebView` returned true for Android, iOS and
macOS. Windows fell through to `_usesExternalSecurityCheck`, which starts a
loopback HTTP server, launches the **system browser**, and asks the player to
solve a captcha in Edge and then alt-tab back to a Flutter window that has been
sitting on "Still checking" the whole time.

That is not a sign-in flow, it is a detour — and the kind that loses people. A
browser tab opening unprompted during a login looks like something has gone
wrong even when everything is working, and on desktop it means the app loses
focus at the exact moment it is asking for credentials.

`webview_flutter` has no Windows implementation and will not get one; its
federated platform packages are Android, iOS and macOS. So this needed
`webview_windows`, which wraps Microsoft's WebView2 — already present on
Windows 10 and 11.

**The trap avoided.** The obvious approach is `loadStringContent(html)`. That
hands the page an `about:blank` origin, and Turnstile validates the page's
hostname against the site key's allowed domains. It would fail in the least
debuggable way possible: a widget that renders and then silently refuses to
issue a token.

Serving the same HTML from the loopback server that **already exists** puts the
page on `http://localhost` — the origin the Android path already uses via
`baseUrl`, and one the site key already allows. It also reuses the tested
`/token` POST, so there is no JavaScript bridge and no second delivery path.

**Fix.** `WindowsTurnstileView`, rendering WebView2 inline. Added a `/status`
route to the loopback server so a render failure can reach Dart — the embedded
view has no tab to close, so without it a broken widget is indistinguishable
from a slow one and the app waits forever. That exact state was the original
sign-in outage.

The browser flow is **kept** as a fallback: if WebView2 cannot initialise,
`onNeedsBrowserFallback` flips back to it. Losing the embedded widget is much
better than losing sign-in.

**Verified by.** `flutter build windows --debug` succeeds with the plugin
linked (318s, CMake dev warnings only, matching the ones the pre-existing
`flutter_inappwebview_windows` already produces). `flutter analyze` clean.
**Not verified:** that the widget renders and issues a token on screen — that
needs the app run on Windows with a live Cloudflare challenge.

---

### 11. `localhost` in the reset redirect

**Symptom.** *"For the reset don't use localhost please."*

**Investigation.** Entry 5 fixed the mobile branch but left
`kIsWeb ? 'http://localhost:5960/' : …` — the Flutter web dev server. The same
class of mistake as the `localhost:3000` that started all of this: an address
that resolves on exactly one machine, in one terminal, while a dev server
happens to be running on one particular port.

A reset link is **emailed**. Emails get opened on phones, on other people's
computers, and days later. There is no situation in which the correct
destination for one is a loopback address.

**Fix.** One constant for every platform. Also removed the now-dead
`localhost:5960` entries from the `config.toml` allow-list — an unused
allow-list entry is not harmless, it is a documented-looking invitation to
point a real email at a loopback address.

Recorded in the code what has to change when a web build is deployed: that
build's real origin, because on web the app *is* the page and the PKCE verifier
lives in that origin's storage.

---

## Open — found, not fixed

### `supabase.env.json` holds template placeholders

**Found while** investigating two whole-suite test failures in
`public_config_test.dart` that looked at first like collateral damage from this
session's changes.

**They were not.** `git stash` + re-run on a clean tree reproduced both
failures, and `git diff --stat -- lib/config/` was empty. The file was never
touched.

**What it actually is.** `readRuntimeEnv` resolves in order: `--dart-define`,
then `supabase.env.json`, then the committed `kPublicSupabaseConfig` defaults.
The local `supabase.env.json` — gitignored, so it is a per-machine file —
contains the values from `supabase.env.json.example`:

```
SUPABASE_URL       https://your-project.supabase.co
SUPABASE_ANON_KEY  your-public-anon-key
```

Those **override** the real, committed defaults. So on this machine, running
from source, the app points at a project that does not exist: `Supabase.initialize`
fails, `_isSupabaseConnected` goes false, and there is no authentication at all.

**Why it matters beyond a red test.** This is a plausible cause of sign-in
appearing broken on PC *independently of the captcha*, and it would look
identical to a captcha fault from the outside.

**Not fixed here** because it is a local, gitignored file belonging to the
developer, and deleting somebody's config is their call. Either delete it —
the committed defaults are correct and complete — or fill it with the real
values from `lib/config/public_supabase_config.dart`.

---

## How to add an entry

Write the **Investigation** section as it happened, wrong turns included. The
localhost entry is more useful for recording that the app was checked first and
found correct than it would be for stating the answer; the roll-sound entry is
more useful for the measurement that turned "sounds bad" into 4,602
crossings-per-second than for the synthesis that replaced it.

If a fault could not be seen by reading the code, say so in **What it cost**,
and add the measurement as a test. Most of this file is faults that read
perfectly.
