# Budget Buddy — Privacy Policy

**Last updated: 1 September 2026**

Budget Buddy is a financial-literacy game for ages 4 and up. This policy
explains exactly what the app collects, where it goes, and what it never does.

It was written by reading the app's own source code rather than from a
template, so everything below describes behaviour that is actually in the
build. Where something is optional, it says so; where a third party receives
anything, it names them.

> **Not yet legal advice.** This is an accurate technical description written
> by the development team. Before publishing it as your store-listing policy,
> have someone qualified review it — particularly the children's-privacy
> section, because an app aimed partly at under-13s in the US falls under
> COPPA, and in the EU/UK under GDPR-K and the Age Appropriate Design Code.
> Those regimes may require a verifiable parental-consent step this app does
> not currently have.

---

## The short version

* Budget Buddy needs an account, so that your progress follows you between
  devices. We store your email, a username, your game progress, and anything
  else you choose to add.
* There is **no advertising, no analytics SDK, no crash reporting, no
  tracking, and no advertising identifier** in this app. We do not sell or
  share your data with anyone for marketing.
* No real money is ever involved. Every "coin", "$" and "portfolio" in the app
  is fictional.
* Accounts that say they belong to someone **under 13 never appear on the
  public leaderboard** — that is a default, not a setting you have to find.

---

## What we collect

### When you create an account

An account is required to play. Progress is saved to it so it is not lost when
you change device, and the leaderboard needs something to attach a score to.

| What | Why | Required? |
|---|---|---|
| Email address | Signing in, and resetting your password | Yes |
| Password | Signing in | Yes |
| Username | Shown on the leaderboard and your profile | Yes |
| Profile photo | Shown on your profile | No |
| Age band | Picks age-appropriate lessons and examples | No |
| Gender / pronoun | Your character in the life simulation | No |

Your password is handled by our authentication provider (Supabase) and is
stored hashed. The app never sees or stores your password itself.

**Age is a band, not a birthday.** You pick one of "under 13", "13–15",
"16–17", "18+" or "prefer not to say". We never ask for a date of birth,
because the app only needs to know roughly which examples to show you.

### Created by playing, if you have an account

Your progress is saved to your account so it follows you between devices:

* Gold, XP and literacy points
* Which lessons you have finished and your quiz scores
* Money habits you have saved, and which days you logged them
* Jar progress and challenge progress
* Finished lives from the life simulation (net worth, ending, age reached)
* Which places in the town you have visited
* Skins you have unlocked and which one you have equipped
* Your in-game transaction ledger, holdings and portfolio history — **all of
  this is play money.** No real account, card or brokerage is ever connected.

### Stored only on your device, never uploaded

* Sound and music toggles
* Whether you have seen the tutorial
* How many times the app has been opened
* A cached copy of your progress, so the app works offline
* Feedback you have written that has not been sent yet

Clearing the app's data or uninstalling it removes all of this.

### If you send feedback

The Feedback screen sends the category you picked, your message, and — if you
are signed in — your user ID and email, so we can reply and so we can tell
whether two reports are the same person. If you are offline it is held on your
device until it can be sent.

---

## What we do **not** collect

* **No location.** The app never asks for or receives your location.
* **No contacts, calendar, microphone or camera.** The only device permission
  the app can request is access to your photo library, and only at the moment
  you tap "change photo".
* **No advertising ID, no device fingerprint, no analytics SDK, no crash
  reporting.** There is no Firebase, no Google Analytics, no Sentry, no
  AppsFlyer, no Meta SDK and no ad network in this app.
* **No behavioural profiles for advertising.** We do not build one, sell one,
  or let anybody else build one from your use of this app.
* **No real financial data.** We never ask for a bank account, card, brokerage
  login, income or net worth. The Market Board shows real *prices*; it never
  touches real *money*.

---

## Who else receives anything

We keep this list short deliberately. Every entry is something the app
genuinely contacts.

**Supabase** — our backend. Holds your account, your saved progress and your
profile photo. This is where your data lives.

**Cloudflare Turnstile** — a "are you a human" check shown when you create an
account. It loads in a small web view from `challenges.cloudflare.com`, and
Cloudflare receives your IP address and some browser signals in order to make
that judgement. It is used only at sign-up.

**Finnhub and Twelve Data** — real stock prices for the Market Board. Where
our price proxy is configured, only a ticker symbol is sent and your device
never contacts these companies directly. If the proxy is unavailable the app
falls back to requesting prices directly, in which case your device's IP
address reaches them as part of an ordinary web request. Either way, no
account information, username or progress is ever sent.

**Wikimedia Commons** — company logos shown next to tickers on the Market
Board are loaded as images from `upload.wikimedia.org`, which means your IP
address reaches Wikimedia the same way it would if you visited any website.

**Government and regulator websites** — every lesson cites a primary source
(CFPB, SEC/Investor.gov, IRS, FDIC, FTC and similar). Those are **links**.
Nothing is sent to them unless you tap one, and when you do it opens in your
own browser.

Fonts are bundled inside the app, so no font service is contacted at any point.

---

## Children

Budget Buddy is built to be used by children, and that shapes several
decisions:

* **Under-13 accounts are kept off the public leaderboard.** If the account
  says it belongs to someone under 13, it is excluded from the leaderboard by
  the database itself. It is not a preference that can be toggled on.
* **Email addresses are masked on the profile screen** so a screenshot of a
  child's profile does not contain a real contact detail.
* **There is no chat and no messaging.** Players cannot send each other
  anything, in any form.
* **What another player can see about you** is your username, your level, your
  score, and your profile photo if you have set one. That is the whole list —
  your email, age band, lessons, habits and life-simulation history are never
  shown to anyone else.
* **Friends are added by a code you choose to share**, not by scanning
  contacts or by any kind of suggestion system.
* **No ads.** There is nothing in the app for anyone to advertise to a child.

**A note for parents about profile photos.** A photo you add is shown next to
your name on the public leaderboard. Under-13 accounts are kept off that
leaderboard entirely, so a younger child's photo is not shown to other
players — but for a 13-or-over account it is. The photo is optional and can be
removed at any time, and if you would rather your child did not have one, the
app works exactly the same without it.

If you are a parent or guardian and want your child's account and its data
deleted, contact us using the details below and we will remove it.

---

## How long we keep things

Your account and progress are kept until the account is deleted. Feedback
messages are kept while we work through them. The copies stored on your own
device disappear when you uninstall the app or clear its data.

## Deleting your account

**From inside the app:** Profile → *Delete my account*, at the bottom of the
screen under Log Out. You will be shown exactly what is about to go and asked
to type DELETE to confirm. It happens immediately and it cannot be undone.

That removes your account and everything attached to it:

* your level, coins and every skin you own;
* every life you have played and every ending you found;
* your lessons, quiz scores and streak;
* your friends list, and your entry on other people's;
* your profile photo, if you uploaded one;
* any feedback you sent us;
* your sign-in record, so the email address is free to use again.

**By email:** you can also write to us at the address below from the address
the account uses, and we will delete it within 30 days. Use this if you have
lost access to the account and cannot sign in to delete it yourself.

## Your choices

* Age, gender, pronoun and profile photo are all optional and all have a
  "prefer not to say" or "skip" option.
* You can sign out at any time from the Profile screen, and delete your
  account from the same screen.
* Depending on where you live you may have the right to ask for a copy of
  your data, to correct it, or to have it deleted. Email us and we will do it.

## Changes to this policy

If this policy changes we will update the date at the top and note what
changed. If a change materially affects what we collect, we will say so in the
app rather than only here.

## Contact

**Email:** `budgetbuddyhq@gmail.com`

A privacy policy has to give a real way to reach a human. Use an address you
are willing to publish — a project address rather than a personal one is
usually the right call, since this page will be linked from a public store
listing.
