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

### 12. The reset page was never being served, and neither was the privacy policy

**Symptom.** Same screenshot as #5 — *"This site can't be reached"* — reported
again after #5 was fixed, with *"I'm not sure if you fixed that or not."*

**Investigation.** #5 above concluded that the app was innocent and the
dashboard needed configuring, and every part of that reasoning was sound: the
constant pointed at an https page, `docs/password-reset.html` existed and
forwarded the payload correctly, `config.toml` carried the Site URL, and
`auth_redirect_test.dart` asserted the whole chain. The suite was green. The
obvious next step was to go and set the dashboard values.

Before doing that, the page itself got a ten-second check:

```
curl -o /dev/null -w "%{http_code}" \
  https://budget-buddyhq.github.io/budget_app/password-reset.html
404
```

Then the privacy policy, on the same host: **404**. Then the site root: **404**.

Not a redirect problem at all. #5's fix rests on the phrase *"a real page on the
existing GitHub Pages site"* — and there is no existing GitHub Pages site. The
repository is **private**, and GitHub Pages does not publish private
repositories on a free plan. Confirmed by the repo itself answering 404
unauthenticated.

So configuring the dashboard would have produced no visible change whatsoever,
which is the expensive kind of dead end: the next step after "I set it and it
still doesn't work" is usually to go back and doubt the parts that were already
correct.

**Root cause.** Two independent claims got collapsed into one. *"The file is in
the repository"* was true and was being tested. *"The file is being served"* was
false and was never tested. There was a passing test called "the landing page
exists where the constant says it does" that checked only the first.

**The worse half, found by grepping for the dead host.** `kPrivacyPolicyUrl`
pointed at the same origin. Google Play **requires** a reachable privacy-policy
URL for any app that collects user data, and checks it during review. That was a
store rejection sitting behind a green test, invisible because nothing in the
app ever opens that link.

**Fix.** `tool/build_pages_function.py` bakes both pages into a Supabase edge
function (`supabase/functions/pages`). Rejected alternatives, briefly: making
the repo public is the user's decision and not one to take quietly; Netlify or
Vercel means a new account and new credentials. Edge functions are already
deployed successfully in this project, so this adds no account, no credential
and no change to repository visibility — and it puts the landing page on the
**same origin as the auth server that issued the link**, which removes the
allow-list failure mode rather than documenting it.

Two things that would have broken it later:

* The page links to `privacy-policy.html` as a sibling file. Under a route that
  resolves to a *different function* and 404s, so the generator absolutises
  those links at build time.
* It must deploy with `--no-verify-jwt`. Somebody clicking a link in an email
  carries no Authorization header, and the resulting 401 looks identical to the
  404 being replaced.

**Verified by.** Rewritten tests that assert what was actually wrong: the
constant's route exists in the function, the baked HTML is in sync with the
`docs/` source (it is embedded, so editing the source without regenerating would
ship a stale page), and neither URL is on `github.io` — pinned with the reason
so it cannot return. Full suite green at 1,331.

**What it cost.** Nothing in the app can show this. The constants are right, the
deep link is right, the page HTML is right, and the only evidence lives in an
email opened on a phone. It survived a dedicated investigation (#5) that got
every step right except checking whether the destination existed.

**Still needs a person.** `supabase functions deploy pages --no-verify-jwt`,
then the Site URL and redirect allow-list in the dashboard. The function's bare
root deliberately serves the reset page, so if the dashboard is still wrong,
Supabase's silent substitution now lands somewhere useful instead of nowhere.

### 13. A test accused the code of a bug that was not there

**Symptom.** `audio_mix_test.dart` failing on a clean, committed tree:

```
initialize is a single shared future, not a flag set early
Expected: a value greater than <15498>
  Actual: <-1>
_playersReady is set before the setup it is supposed to gate
```

**Investigation.** The message is a specific accusation about statement order,
so the ordering got read first — and it was correct. `_playersReady = true;` is
the final statement of `_initialize()`, after `_attachLifecycleObserver()`, with
a comment above it saying "Last, not first."

Confirmed pre-existing rather than collateral from this session's edits by
`git stash` + re-run, which reproduced it on the committed tree.

The tell was the **shape of the number**. A real ordering failure produces two
plausible offsets in the wrong order. `-1` is `indexOf` reporting **not found**,
which is a different fact reusing the same failure message. The pattern searched
for was `'_playersReady = true;\n  }'` — spanning a line break — and the file is
checked out with **CRLF** endings, so every `\n` is really `\r\n`. That pattern
cannot match on this machine at any time. The neighbouring checks in the same
file passed only because they happened to be single-line.

**Root cause.** A source-scanning test that was sensitive to line-ending
convention, reporting the absence of its search string as a defect in the code.

**Fix.** `serviceSource()` normalises `\r\n` to `\n` once — fixing every
source-scan in the file rather than the one that happened to fail.

**What it cost.** Read correct code twice looking for a fault that was not
there. The lesson is about diagnosis, not line endings: read the *shape* of a
failing value, not just the message. A sentinel like `-1` means the search
failed, and a test that says "your code is in the wrong order" when it means "I
could not find the text" sends you somewhere there is nothing to find.

### 14. The analyser was a report card, and it was down six tabs

**Symptom.** *"Make the coach more, not just in the daily, since the coach
should be everywhere... and make the coach actually think."*

**Investigation.** Two separate things are called coach in this repo:
`coach_mark.dart` (the tutorial spotlight) and the Coach tab in Money Habits.
The request is the second.

What was there was better than expected. `analyseMoney` scores five areas
*separately* — with a comment explaining why they are never averaged, because
somebody can be extremely consistent and save nothing — and every finding
carries an `evidence` line described as "the number out of their own data that
says so". The rules are quiet on thin data. It is careful work.

It was also reachable through exactly one route: tab index 5 of one screen.

The tell that this was unfinished rather than merely buried:
`MoneyReport.headline` is documented as *"the single line to show if there is
only room for one"* and had **zero callers**. The hook for this feature had
been designed and never connected.

**Root cause, and the more interesting half.** Reachability was the reported
problem. The deeper one is that every rule read *one* area and reported on it,
which is five report cards in a row. A report card is not a coach. The
findings that matter are the ones that compare two areas and notice they
disagree.

**Fix.**

* **Cross-domain rules.** The headline case: a player scoring 90% on needs
  versus wants whose Coin Cascade boards run 42% wants. Also the inverse
  (good at the game, never assessed on the rule underneath it), the same
  high-wants shape appearing in *both* the arcade and the life sim, and
  reading a lot while never deciding anything. No individual screen can
  produce any of these.
* **The behaviour to compare against.** Coin Cascade records how the board was
  divided. It is the right source precisely because that screen never says the
  word budget while it is being played, so the split is a habit rather than an
  answer to a question about habits. Stored as totals, not an average — a lost
  write costs one run's accuracy instead of permanently corrupting a
  re-weighted figure.
* **`CoachSpot`.** One card, placed on Home and the arcade, with an optional
  dimension filter so the arcade shows learning/saving findings and not "log a
  habit today". When nothing relevant matches it renders **nothing** rather
  than falling back to something off-topic.

**A bug avoided by thinking about the empty state first.** The card renders
nothing for a player with no history. Dropped between two `SizedBox`es it
would still leave a double gap, on exactly the screens a new player sees
first. Spacing moved onto the widget as a `margin` that disappears with it;
`coach_cross_domain_test.dart` asserts the rendered height is zero.

**Verified by.** 13 new tests, including one that the three mutually exclusive
split rules stay mutually exclusive — they share a branch today, and a
refactor into independent `if`s would let the coach tell somebody they budget
well and badly in the same list.

### 15. The owner of the game could not explain its rules

**Symptom.** *"I'm not sure what the coin cascade of this even mean, like does
it mean that you have to pay the bill, how are the bills determined etc and
what does the next level even mean."*

**Why this is a severe report rather than a question.** It came from the
person who commissioned the game. If the owner cannot state the rules after
watching it played, nobody is deriving them from the board.

**Investigation.** Read the model expecting to find the rules were incoherent.
They are not. Needs clear bills; wants score well and add bills; bills also
arrive on a schedule set per level; savings fill the goal; coins buy moves.
The ladder is an explicit curriculum with its reasoning written above it.

Then read the help dialog, which lists the five tile kinds and stops. Every
one of the three things being asked about was absent from it: what the bills
counter means, where bills come from, and what a level is.

**Root cause.** The design was documented where the designer could see it —
in comments — and nowhere the player could. The level banner's one-line rule
is a reminder for somebody who already knows the game, which is what help
written while holding the whole design in your head looks like.

**Fix.** Four sections: what you are trying to do (fill savings, do not let
bills reach the cap), the five tiles, **where bills come from** — naming both
sources, since "your own wants create them" is the entire game and was written
nowhere — and what a level is. The lesson is named last on purpose: leading
with "this is 50/30/20" makes it a worksheet; naming it after the rules lets
a player recognise something they have already been doing.

**What it cost.** Nothing crashed and no test could have caught it. The only
evidence a game has not explained itself is somebody saying so, and the person
best placed to notice is the one person who already knows the answer.

### 16. The Academy stated its own size as two different numbers

**Symptom.** *"The lesson count under 'Every lesson is sourced' and the total
lessons in 'Your learning stats' don't match up."*

**Investigation.** Both were right, about different things. The sourcing card
counts `type == LessonNodeType.lesson` — **63** — which is correct for its own
sentence, because it says "63 lessons and N questions" and counts the questions
separately. Your Learning Stats used `progression.totalCount`, which is every
node on the path — **89**, made of 63 lessons, 13 quizzes and 13 unit tests —
which is also correct, because that total drives the progress bar and the
unlock rules, where a quiz genuinely is a step you have to finish.

Neither was a bug alone. Together they made the app contradict itself about
the size of its own curriculum, on the one screen whose entire pitch is that
the content is checked and trustworthy.

**Root cause.** Two definitions, one word. Nothing named which "lessons" it
meant.

**Fix.** `teachingTotal` / `teachingCompleted` on `ProgressionService`, and the
stats card uses those. Fixed by naming rather than by forcing the numbers
equal — both measures are worth having.

**The half-fix that was avoided.** Changing only the denominator to 63 and
leaving the numerator counting all 89 node completions would show a player who
had done the quizzes something like **71/63**. Both sides move together, and
there is a test that completes every non-teaching node and asserts the lesson
count stays at zero.

**Verified by.** `curriculum_counts_test.dart`, which pins the two counts to
the same *definition* rather than to a number — so writing lesson 64 does not
fail the suite, and disagreeing does.

### 17. Two HUD panels, same border, different heights

**Symptom.** *"The header box sizes in finance brawl are all different sizes,
making it visually jarring."*

**Investigation.** Structural, not spacing. The wave panel draws a progress bar
plus its caption (~30px); the net-worth panel drew a single line of flavour
text (~14px). `Expanded` equalises **widths** and says nothing about height, so
two boxes with identical borders sat side by side at different sizes — and the
difference *moved*, because the wave panel drops its bar at narrow widths.

**Two fixes were tried and both failed, and the reasons generalise.**

`IntrinsicHeight` + `CrossAxisAlignment.stretch` is the textbook answer. It
throws:

```
LayoutBuilder does not support returning intrinsic dimensions.
```

`FittedLabel`, `_PixelPanel` and `PixelProgressBar` all use `LayoutBuilder`
internally, so `IntrinsicHeight` is unavailable across essentially this entire
app, not just this screen. Worth knowing before reaching for it again.

`stretch` on its own then failed differently — *"BoxConstraints forces an
infinite height"* — because the HUD row sits inside a top-aligned `Align` and
has no bounded height to stretch to.

A third option, a fixed height, was rejected without being written: it is
correct for exactly one font size and one text scale, and nothing tells you
when it stops being correct.

**Fix.** Both panels render the **same widgets**. The net-worth panel gains a
bar, so the heights match by construction and no number anywhere states a
height. It is not a spacer in disguise either — that panel's flavour line was
"Don't Let it Hit Zero!", which is precisely what a bar communicates better
than a sentence, and communicates at a glance mid-fight.

**Found on the way.** Each panel ran its own `LayoutBuilder` and reached its
own `tight` decision from its own width. They are both `Expanded` in one row so
they normally agree, but nothing guaranteed it — two adjacent boxes disagreeing
about whether to show their icons would have been a worse version of the same
complaint. One measurement now, at the row, passed to both.

### 18. The best thing in the app was the sixth tab of a scrollable strip

**Symptom.** *"Make the coach like an official tab or something, because it is
one of the most advanced technologies that we have here."*

**Investigation.** Agreed with the premise after reading it. `analyseMoney`
scores five areas separately, every finding carries the number it came from,
and the rules stay quiet on thin data. It was reached by opening Money Habits
and scrolling a tab bar sideways past Today, Week, Find, Challenges and Jar.

**Fix.**

* `CoachReportView` extracted from `money_habits_screen.dart` into its own
  file — one widget, two entry points, so the tab and the new screen cannot
  drift.
* `CoachScreen`, a real `IndexedStack` slot at `AppTabIndex.coach`, reached
  from the top strip beside Profile.
* `openCoach` pushes that instead of the whole Money Habits screen opened on
  tab six — which had been mounting five other tabs to show one, on top of an
  instance already alive in the stack.

**Why the top strip and not the bottom bar.** The bottom bar was seven wide
once and "got crowded fast"; it is deliberately five, with Home as the middle
anchor. Daily and Profile already live in the top strip with real slots, so
this follows a pattern rather than reversing a decision made for good reasons.

### 19. A quiz score is a photograph of one afternoon

**Symptom.** Not a bug report — *"add more technologies... and then make the
user actually learn."* Researched what wins the Congressional App Challenge
first: judges score purpose, concept, technicality, creativity and design, and
recent winners lean on real inference applied to a real problem.

**The gap.** The Academy recorded that somebody scored 90% on compound growth
in March and then never mentioned it again. That is a *record* of learning
rather than a system for it. The best-established result in memory research is
that recall decays on a curve and that the way to beat it is to be tested again
shortly before you would have forgotten — and the app had every input needed to
do that except one.

**Fix.** `review_schedule.dart`: a simplified **SM-2**, the scheduler behind
Anki. Each concept carries an ease factor (how well it sticks for this
particular person) and an interval. It runs entirely on the device — no model,
no API, nothing leaves the phone, works offline.

**Two deliberate departures from textbook SM-2**, both for this audience:

* **An ease floor at 1.3.** Without it a run of bad answers drives ease toward
  zero and the concept is scheduled every single day forever. For a
  nine-year-old that is a punishment loop, which is how an app gets deleted.
* **An interval ceiling at 180 days.** Real SM-2 runs to years, which is right
  for a language learner and wrong here: nobody uses one app for three years,
  and a concept that never returns is indistinguishable from one that was
  dropped.

Failure also does **not** reset the ease factor, only the streak. How easily
this person holds this idea is a slower-moving fact than one bad answer, and
resetting it makes the schedule thrash between "every day" and "in a month".

**The missing input was a date.** Accuracy was stored per node; *when* was not.
`completeLesson` is the only place that knows both, so the schedule updates
there, and only for assessment nodes — reading a lesson is not a test of
recall, and counting it would push the interval out on the strength of somebody
scrolling to the bottom of a page.

**A bug the tests caught before it shipped.** `(map['r'] as num?)` throws on a
String, and this map comes back from a `jsonb` column whose contents are
whatever any version of the app — or a hand edit in the table editor — has ever
put there. A throw while parsing would take the whole Coach screen down. Now
coerced, with the correct reading of an unparseable value being "never
reviewed".

**Verified by.** 16 tests in `review_schedule_test.dart`, pinning *properties*
rather than outputs — an interval of 6 versus 7 does not matter; "hard things
come back sooner than easy ones" and "repeated failure cannot produce a daily
loop" do.

### 20. The landing pages had no logo

**Symptom.** *"For the html pages can you make our logo on there."*

**Fix.** `tool/build_pages_function.py` generates a data URI from
`assets/images/logo.png` at build time — resized to 144px (2x display size, so
retina is covered) and optimised, 94KB down to 17KB of base64.

**Three decisions worth recording.** Generated rather than pasted in as a blob,
so the page cannot drift from the app's actual mark. Inlined rather than an
`<img src>` to a host, because that would put an image server in the path of
the one flow whose failure mode is "nobody can get back into their account" —
and email clients block remote images by default anyway. And the two pages have
different shapes, so the branding falls back: the reset page has a badge to
replace, the privacy page opens straight into an `<h1>` and gets the mark placed
above it, rather than having a badge invented for it.

**Note on the localhost screenshot.** The reset email still shows
`redirect_to=http://localhost:3000`. That is not the app — it sends the edge
function URL. Supabase substitutes the project's Site URL whenever `redirect_to`
is not allow-listed, and the `pages` function is still un-deployed (verified:
404). Both halves are server-side and need a person. See entry 12.

### 21. A score cannot tell knowing from guessing

**Symptom.** Not a bug — a brief: *"make something more advanced to help
people learn."*

**The gap, measured.** Every quiz in the app has **four options** (185 of 186
questions; the histogram was counted rather than assumed). So a blind answer
is right a quarter of the time, and the most likely outcome of answering four
questions with no knowledge at all is 1/4 — but roughly a fifth of the time it
is **2/4**, which the Academy records as 50% and the coach reads as "half
understood".

Nothing in the app distinguished knowing from being lucky. That matters most
for exactly the learners who need help most: a child who guesses to 50% twice
looks like steady progress and has learnt nothing.

**Fix.** Bayesian Knowledge Tracing — the model under intelligent tutoring
systems since Corbett & Anderson (1995) and still the standard baseline in
educational data mining. It tracks one hidden variable per concept, `P(known)`,
and weighs every answer by how likely it was to have happened by accident.

The parameter worth pointing at is **guess = 0.25**, which is *measured from
the quiz bank rather than tuned*. There is a test asserting it still matches
the commonest option count — if questions ever become three-option, 0.25 is
wrong and the model silently starts overrating everybody.

**A second layer, because knowing someone is stuck is not much use.**
`kConceptPrerequisites` is a DAG over the sixteen ideas, and `diagnose()`
walks it for the **deepest unmastered prerequisite**. Failing compound growth
is usually not a compound growth problem: nothing compounds until something is
being set aside. The coach now names the earliest missing idea instead of the
visible symptom — sending somebody back to the thing they are failing when the
real gap is two steps upstream is how learners decide they are bad at maths.

The walk follows the **weakest** unmastered prerequisite rather than the first
listed, so a diagnosis never depends on the order somebody typed a list.

**A misunderstanding the tests caught — mine.** I wrote a test asserting "a
wrong answer moves belief further than a right one" and it failed:

```
Expected: a value greater than <0.35>
  Actual: <0.093>
```

The test was wrong, not the model. In *likelihood-ratio* terms a wrong answer
really is stronger evidence — 7.5x against knowing, versus 3.6x for — but from
a low prior there is more headroom above 0.25 than below it, so the first
correct answer moves `pKnown` by about +0.35 and the first wrong answer by
about -0.09. Both are true at once. **Evidence strength lives in the odds, not
in the change to the probability**, and I had written the intuitive phrasing
into a doc comment as well. Both are corrected, and the test now asserts the
odds version, which is a property of the model rather than of where the prior
happens to sit.

Worth recording because it is the failure mode this whole entry is about: a
plausible-sounding claim about probability that is false, and would have been
pinned into the suite as correct.

**Guards against the obvious ways this goes wrong.**

* Belief is clamped strictly below 1. A `pKnown` of exactly 1 is
  unrecoverable — no later evidence could move it, so a learner could never be
  found to have forgotten.
* A slip parameter, so one careless answer cannot erase eight correct ones.
* Never-assessed is a distinct state from assessed-badly, and an unassessed
  prerequisite counts as missing: not knowing whether somebody has a
  foundation is a reason to check, not a reason to assume.
* Corrupt `jsonb` reads as unassessed rather than throwing. The Coach screen
  would otherwise go down over a hand edit in the table editor.

**Verified by.** 24 tests, on properties rather than numbers — nobody can look
at `pKnown = 0.7314` and say whether it is right, but "a coin-flip performance
never reads as mastery" and "the prerequisite graph is acyclic" can both be
checked.

### 22. The newest screen was not in the layout sweep

**Found while** adding the Coach tab, by asking what the sweep covered rather
than assuming it covered everything.

It did not. And the Coach is the densest screen in the app — a header, a
five-row score grid, a diagnosis panel, a review panel and a card per finding,
every one of them text over a coloured box, which is the shape that overflows
first on a 320px phone.

**Fix.** Added to both sweeps: the direct-screen list and the nav-tab list, so
it is exercised standalone and inside `MainNavigation`. 347 layout tests pass
with it included.

**Why this is in the log at all.** The single most expensive entry in this file
is #(the layout sweep that filtered its own exceptions) — a suite that reported
clean for months while screens were crashing. The lesson from it was not "fix
the filter", it was *be suspicious of what a green suite is not looking at*.
A new screen is exactly that gap, every time, and it costs two lines to close.

### 23. The map was a second menu with a longer walk

**Symptom.** *"Here at the library there is like a menu tab that already
offers that, so don't make things duplicate in the world and the menu, and
make it like a minigame not a shop dialogue — and same for everything else in
the MAP."* Flagged as the most important item.

**The diagnosis, in the player's own words.** Walking into the library
produced: *"You need somewhere quiet for three hours"* — Book the room / Go to
the cafe / Work at home. Three buttons, no wrong answer, and the Life menu
already had a "Visit the library" row doing the same job. Every building was
the same shape, so the only thing the map added over the menu was distance.

**Root cause.** A dialogue asks what you would like. Nothing in the town could
be got *wrong*, so nothing in it could teach — and if the outcome is a
preference rather than an answer, a menu row is strictly the better UI for it.

**Fix.** `town_challenges.dart`: gradeable money puzzles attached to buildings.
There is a right answer, you find out immediately, and the arithmetic that
decided it is shown either way. Five skills, each an expensive real-world
mistake — unit price, percentage versus flat amount, compound growth,
subscription true cost, tip and total.

**Every number is computed, never authored**, and that is the load-bearing
decision:

* It cannot be wrong. A hand-written "best value" answer is one typo away from
  teaching a child the opposite of the truth, on the screen that claims to be
  checking their arithmetic.
* It cannot be memorised. Prices move with the day's seed.
* It is effectively unlimited content out of a small amount of code, which is
  what a town meant to be revisited for years of in-game time needs.

**Two things deliberately kept.** The park and your own house still have
conversations — they are places to *be*, and arithmetic in them would turn the
whole town into a worksheet. And the payout goes through the existing
`TownChoice` rather than a new reward path, because the caller already owns
the ledger and already applies the anti-farming rule. A second payout route is
a second place for the farming bug to return, and it has returned once already
through the coins.

**A wrong answer still pays a little.** Paying nothing teaches a nine-year-old
that the safe move is to stop opening buildings, which is the opposite of what
a town full of practice is for. Right is worth about three times as much, so
the incentive survives without the punishment.

**Verified by.** 20 tests that re-derive the arithmetic independently —
parsing the per-unit price back out of the label the player reads, rather than
trusting the score the generator set, so a bug in the generator cannot hide
behind its own maths. Plus: no ties anywhere across thousands of seeds (a tie
marks a right answer wrong, which is the worst thing this file could do and
would be invisible), and the seed is FNV-1a rather than `Object.hash`, which
Dart seeds per isolate — that bug has been shipped in this town once already.

### 24. A cafe in the middle of the road, and the measurement that said otherwise

**Symptom.** *"Make the options actually line up with the house please, I'm
having a cafe in the middle of the road."*

**Investigation, and the first answer was wrong.** `place_town_spots.py` snaps
every marker to a walkable tile touching a building, and a measurement said it
had worked perfectly: **all 24 markers, across both maps, sat exactly one tile
from a solid cluster.** By the tool's own test there was nothing to fix.

Being next to *a* building is necessary and not sufficient. Nothing stopped
two markers snapping to the **same** building:

```
village : 8 of 12 markers shared a building with another
market  : 9 of 12, with bank + notice board + market stalls all on one house
```

The clinic and the library were opposite walls of one building. The cafe and
the park were one building. So walking up to a house told you nothing about
what was inside it, and a marker on the far side of a building you had
mentally assigned to something else reads exactly like a marker floating in a
road.

The second map made it worse for a structural reason: it has **13 distinct
buildings against the village's 23**, so the same greedy snapping crowds nine
markers onto four houses.

**Fix.** `tool/assign_town_buildings.py` treats it as an assignment problem
rather than twelve independent snaps — each marker matched to a *distinct*
building, minimising total displacement so the town stays recognisable instead
of being reshuffled wholesale. Greedy by cost then a 2-opt improvement pass;
with twelve markers that is exact in practice, and the Hungarian algorithm
would be sixty more lines for no gain at this size. Result: **map two now has
zero shared buildings.**

**A second bug fell out of it.** Moving the house broke the spawn point, which
was a hardcoded tile carrying a comment claiming `spot_home` was at 13,30 — it
had been at 27,42 for some time. The constant had drifted from the house
twice, and the comment documenting it was wrong both times. `townSpawnTile()`
now derives from `spot_home`, so they cannot disagree again.

**My own test was wrong first.** The regression test asserted "each marker's
building is unclaimed", walking four neighbours and taking the first hit. A
doorstep can belong to two buildings at once, so it failed on a placement that
was correct. The property that actually matters is whether a distinct
assignment *exists* — a bipartite matching — so the test does that instead, and
now passes for any valid placement rather than only the one the tool happened
to produce.

### 25. Ranked among friends, and absent from the ranking

**Symptom.** *"Push yourself on the friend leaderboard, fix that."* The
screenshot shows a podium with one player on it and two empty plinths marked
with dashes.

**Root cause.** `fetchFriendsLeaderboard` collected the friend ids from the
friendship edges and queried exactly those — so the signed-in player was the
one person guaranteed to be missing from a board about them. On an account
with one friend it produced a winner and two blanks, and no way to see where
you stood, which is the entire question a friends leaderboard exists to
answer.

**Fix.** The current user joins the id set before the query. The "no friends
at all" early return stays: that is a different screen, and answering "ranked
among friends" with a list containing only you reads as a bug rather than an
invitation.

**Also fixed while there.** The podium built all three places unconditionally,
so a two-player board drew a real winner beside an empty stand with a dash
under it — which reads as "third place failed to load". Places are now built
only for people who exist.

### 26. The coach scolded a player for playing on purpose

**Symptom.** *"Look at the 'your runs are getting worse' — what if they are
doing this for the ending?"*

**A fair hit.** The `lives_flat` finding fires on three lives that are not
increasing in net worth and tells the player to open the Money menu earlier.
Net worth is the obvious measure of a life and it is not the only thing
somebody plays for. A player working through the endings deliberately gets
poorer runs, and being told off for doing the thing the game rewards is the
fastest way to teach somebody that the coach is not paying attention.

**Fix.** The app already tracked `discovered_endings`, and nothing read it.
The analyser now does: three or more distinct endings across a handful of
lives is somebody exploring on purpose, and the finding becomes a *strength*
that names the trade honestly — the unusual endings do finish poorer, and that
is a cost rather than a mistake — instead of advice they did not need.

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
