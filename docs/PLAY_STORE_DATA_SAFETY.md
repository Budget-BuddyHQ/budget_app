# Google Play — Data safety answers

Google Play makes you fill in a Data safety form before you can publish, and
the answers have to match what the app actually does. A mismatch between this
form, the privacy policy and the binary is one of the more common reasons a
submission is rejected, and it is the kind of rejection that costs a week.

These answers were worked out by reading the source, the same way
`docs/PRIVACY_POLICY.md` was. Copy them into the Play Console form.

**Privacy policy URL to paste into the listing:**

```
https://budget-buddyhq.github.io/budget_app/privacy-policy.html
```

To make that URL live: repository **Settings → Pages → Source: `main`, folder
`/docs`**. Then check the link loads in a private window before submitting —
Play does fetch it.

---

## Data collection and security — the headline answers

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — everything goes over HTTPS |
| Do you provide a way for users to request that their data is deleted? | **Yes**, by email — **see the gap below** |

> **Before you tick that last box.** Play expects an in-app route to request
> deletion, not only an email address. The app does not have one yet. Either
> build it first, or answer honestly that deletion is by request and give the
> contact address — do not claim an in-app flow that is not there.

---

## Data types

For every row: collected = **yes**, shared with third parties = **no**,
processed ephemerally = **no**, required = as marked, purpose as listed.

"Shared" in Play's sense means passing data to another *company* for their own
use. Supabase is our processor and hosting provider, which Play does not count
as sharing — but say so in the policy, which we do.

### Personal info

| Data type | Collected | Required | Purpose |
|---|---|---|---|
| Email address | Yes | Required | Account management |
| User IDs | Yes | Required | Account management, App functionality |
| Name | **No** | — | We ask for a username, not a real name |
| Address, phone, race, political or religious beliefs, sexual orientation | **No** | — | — |
| Other info — self-declared age band | Yes | Optional | App functionality (age-appropriate lesson content) |
| Other info — self-declared gender / pronoun | Yes | Optional | App functionality (the player's character) |

### Photos and videos

| Data type | Collected | Required | Purpose |
|---|---|---|---|
| Photos | Yes | Optional | App functionality (profile picture) |

Only when the player taps "change photo" and picks one. The app never reads
the photo library otherwise.

### App activity

| Data type | Collected | Required | Purpose |
|---|---|---|---|
| In-app actions | Yes | Required | App functionality (saving game progress) |
| Other user-generated content — feedback messages | Yes | Optional | App functionality, Customer support |

### Not collected — say **no** to all of these

- Location (approximate or precise)
- Financial info — **including payment info, purchase history and credit
  score.** The Market Board is play money; no real financial data is touched
- Health and fitness
- Messages (SMS, email or in-app) — there is no messaging in this app
- Audio, music files, voice or sound recordings
- Files and docs, calendar, contacts
- App info and performance — **no crash logs, no diagnostics.** There is no
  crash reporter in the build
- Device or other IDs — **no advertising ID**, no device identifiers
- Web browsing history
- Installed apps

---

## Advertising and tracking

| Question | Answer |
|---|---|
| Does your app contain ads? | **No** |
| Does your app use an advertising ID? | **No** |
| Does your app share data for advertising or marketing? | **No** |
| Does your app use data for tracking (in Apple's sense)? | **No** |

There is no ad SDK, no analytics SDK and no attribution SDK in `pubspec.yaml`.
That is worth re-checking any time a dependency is added, because it is the
claim on this page most easily invalidated by accident.

---

## Families policy

Budget Buddy is intended for children as well as adults, so it goes in
**Designed for Families** and the target-audience answer includes under-13.
That brings extra requirements:

- **Target age groups:** all bands, including "Ages 5 and under" and "Ages
  6–8", since the Academy starts at 4–6 and Coin Cascade is playable by a
  non-reader.
- **A privacy policy link is mandatory** — both in the listing and reachable
  in the app. Both are done: Profile → Privacy Policy opens the same URL.
- **No ads** — nothing to declare.
- **Content rating:** the questionnaire should come out at Everyone. There is
  no violence, no gambling with real money, no user-to-user communication and
  no mature content. Answer the "simulated gambling" question carefully: the
  Market Board simulates investing, not gambling, and there is no wagering
  mechanic.

> **The COPPA question you have to answer for real.** Because the app targets
> under-13s and collects an email address, US COPPA requires verifiable
> parental consent before that collection. The app currently asks a child for
> an email and a password directly. This is not something to answer optimistically
> on a form — get advice, and expect that you may need either a parental
> consent step or a no-account mode for under-13s.

---

## Before you submit — checklist

- [ ] GitHub Pages turned on, and the privacy URL loads in a private window
- [ ] A real contact email in the policy (there is a placeholder in it now),
      then re-run `python tool/build_privacy_page.py`
- [ ] In-app account deletion built, or the deletion answer worded honestly
- [ ] The Notifications toggle either wired up or removed — it currently
      promises "Quest reminders and reward alerts" and does nothing
- [ ] COPPA position settled with advice
- [ ] `flutter analyze` clean and `flutter test` green
- [ ] Re-read the Data types tables above against the current
      `pubspec.yaml` — one new dependency can invalidate half of this page
