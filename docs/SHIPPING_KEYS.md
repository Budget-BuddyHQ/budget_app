# Making the API keys work for everybody

Short answer: **you never ship the market API keys at all.** The app already
has the mechanism for this; it is simply not switched on yet.

---

## The thing to understand first

There are two kinds of key in this project and they are not interchangeable.

**Public by design.** `SUPABASE_URL` and `SUPABASE_ANON_KEY`. These are meant
to be in the app. The anon key is not a password — it identifies the project,
and every row it can touch is guarded by row-level security. Supabase publishes
both in its own examples. Baking them into the binary is correct.

**Secret.** `FINNHUB_API_KEY` and `TWELVE_DATA_API_KEY`. These are rate-limited
credentials tied to your account. If one ships inside the app, anybody can pull
it out of the APK in about a minute — `strings` on the binary is enough — and
then your 60-call minute is being spent by strangers. There is no way to hide a
key inside a client. That is not a Flutter limitation, it is true of every app
on every platform.

So the market keys do not go in the app. They go on a server, and the app asks
the server.

## What is already built

`supabase/functions/market/index.ts` is that server. It reads the two secret
keys from its own environment and forwards quotes, candles, search and news.
`MarketDataService` already prefers it:

```dart
bool get usesProxy => _proxyBase != null && _proxyToken != null;
```

If `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set, every market call goes
through the function and **no market key exists in the app**. If they are not
set, it falls back to reading the keys directly, which is the local development
path.

Right now the function is not deployed, which is why the test log says
`Proxy request failed with 404; retrying direct vendor request.` — the app asks
the proxy, gets a 404, and quietly falls back to your local keys. That fallback
is why it works on your machine and would not work for anybody else.

## Current status, checked 3 September 2026

**Secrets: done.** `FINNHUB_API_KEY` and `TWELVE_DATA_API_KEY` are both set on
the project.

**Function: not deployed.** Probed directly, every operation returns:

```
404 {"code":"NOT_FOUND","message":"Requested function was not found"}
```

...and so does every other plausible name (`market-data`, `quotes`, `api`,
and five more). The project has no edge functions at all.

**These are two separate steps and it is easy to think the first one is both.**
The Secrets page under Settings → Edge Functions stores environment variables
*for* functions; it does not create one. The code in
`supabase/functions/market/index.ts` still has to be pushed before the URL
exists. Until it is, the app falls back to the keys in `supabase.env.json` —
which is why the Market Board works on your machine and would not work on
anybody else's phone.

The public config *is* now baked in (`lib/config/public_supabase_config.dart`),
so sign-in, friends, profiles and the rest already work on a plain
`flutter build`. The Market Board is the only thing still waiting.

## Switching it on

Three commands, once.

**1. Put the secret keys on Supabase.** They live there, not in the repo:

```bash
supabase secrets set FINNHUB_API_KEY=xxxx TWELVE_DATA_API_KEY=yyyy
```

**2. Deploy the function.** Two ways; either is fine.

*With the CLI.* There is no `supabase` on the PATH here, so use `npx`. The
project also has no `config.toml`, so it needs linking first. Your project ref
is `cwqjduingvevagrxbwts` — it is the subdomain of your Supabase URL, and it is
public:

```bash
npx supabase login
npx supabase link --project-ref cwqjduingvevagrxbwts
npx supabase functions deploy market --no-verify-jwt
```

`login` opens a browser. `link` will ask for the database password.

*From the dashboard, if the CLI is being difficult.* Edge Functions → Deploy a
new function → via editor. Name it exactly **`market`**, delete the sample
code, and paste all of `supabase/functions/market/index.ts`. It has no imports
and no dependencies, so it pastes as a single file with nothing to bundle.
Then turn **off** "Verify JWT with legacy secret" in the function's settings —
same reason as `--no-verify-jwt` below.

`--no-verify-jwt` is deliberate: the app sends the anon key as a bearer token
and Supabase would otherwise require a *user* JWT, so the Market Board would
401 for anybody not signed in.

**3. Check it answers.** Replace the URL and anon key with yours:

```bash
curl -H "Authorization: Bearer YOUR_ANON_KEY" "https://YOUR-PROJECT.supabase.co/functions/v1/market?op=quote&symbol=AAPL"
```

A price comes back and you are done. Worth checking the batch endpoint too,
since that is what the board actually calls now:

```bash
curl -s -H "Authorization: Bearer YOUR_ANON_KEY" "https://YOUR-PROJECT.supabase.co/functions/v1/market?op=quotes&symbols=AAPL,MSFT,NKE" | head -c 300
```

The response header `X-Cache` reads `n/3 HIT` — run it twice and the second
should be `3/3 HIT`, which is the caching doing its job.

Once that answers, the "Proxy request failed with 404" line disappears from the
logs and every user of the app shares your keys without ever holding one.

## Building the release

Nothing special:

```bash
flutter build appbundle --release
```

The project URL and anon key are compiled in from
`lib/config/public_supabase_config.dart`, which is committed on purpose — see
the file's own header for why those two are safe and the market keys are not.
That was the point of generating it: a build that is only correct when
somebody remembers a long `--dart-define` line is a build that eventually goes
out wrong, and it did.

To point a build at a *different* project, override them — an environment
variable or a `--dart-define` both beat the committed defaults:

```bash
flutter build appbundle --release --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...
```

**Do not** use `--dart-define-from-file=supabase.env.json` for a release. That
file also holds `FINNHUB_API_KEY` and `TWELVE_DATA_API_KEY`, and passing it
whole bakes both into the binary — which is the exact thing this whole document
exists to prevent.

Regenerate the committed defaults after changing projects:

```bash
python tool/write_public_config.py
```

## How to tell it worked

Two checks, in order.

**The keys are not in the binary.** Build it, then look:

```bash
strings build/app/outputs/bundle/release/app-release.aab | grep -i -E "finnhub|twelve"
```

Nothing should come back except possibly a URL. If your key appears, the build
was given `supabase.env.json` whole and you have shipped them — rotate both
keys in the vendor dashboards, because an uploaded AAB cannot be unshipped.

`public_config_test.dart` checks the committed defaults hold exactly
`SUPABASE_URL` and `SUPABASE_ANON_KEY` and nothing else, so the common version
of this mistake fails in CI rather than in the store.

**The app is using the proxy.** Open the Market Board with the device offline
from your dev machine — on someone else's phone is the real test. Prices load,
and nothing in the logs mentions a direct vendor request.

## Rate limits become shared

Worth knowing before release. Finnhub's free tier is 60 calls a minute **for
the account**, not per user. Through the proxy that is now shared by everyone
using the app at once, so ten simultaneous players are ten times the traffic.

**This is already handled, and it is what makes the board feel live.** The
function caches each symbol's quote for 12 seconds and serves every caller from
that cache, so a hundred simultaneous players cost the same vendor calls as
one. The `quotes` operation returns all sixteen symbols in a single request,
which also collapses sixteen edge invocations into one — those are billed per
invocation, so it matters.

That decoupling is the reason the board can poll every **2 seconds**. Without
it, sixteen symbols against a 60-call minute caps a full refresh at one every
sixteen seconds; with it, the app's poll rate and the vendor's limit are no
longer the same number.

## The other keys

There are none. Supabase auth, storage and the database all go through the anon
key plus row-level security, and there is no analytics or advertising SDK in the
app to have a key for — see `docs/PLAY_STORE_DATA_SAFETY.md`.
