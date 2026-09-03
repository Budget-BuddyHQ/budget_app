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

## Switching it on

Three commands, once.

**1. Put the secret keys on Supabase.** They live there, not in the repo:

```bash
supabase secrets set FINNHUB_API_KEY=xxxx TWELVE_DATA_API_KEY=yyyy
```

**2. Deploy the function:**

```bash
supabase functions deploy market
```

**3. Check it answers.** Replace the URL and anon key with yours:

```bash
curl -H "Authorization: Bearer YOUR_ANON_KEY" "https://YOUR-PROJECT.supabase.co/functions/v1/market?op=quote&symbol=AAPL"
```

A price comes back and you are done. The "Proxy request failed with 404" line
disappears from the logs, and every user of the app now shares your keys
without ever holding one.

## Building the release

Only the two public values go in, via `--dart-define`:

```bash
flutter build appbundle --release --dart-define SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

`--dart-define-from-file` is tidier if you keep them in a JSON file:

```bash
flutter build appbundle --release --dart-define-from-file=supabase.env.json
```

`supabase.env.json` is gitignored and should stay that way — not because the
anon key is secret, but because that file is also where the market keys sit
during local development, and the habit is worth keeping.

## How to tell it worked

Two checks, in order.

**The keys are not in the binary.** Build it, then look:

```bash
strings build/app/outputs/bundle/release/app-release.aab | grep -i -E "finnhub|twelve"
```

Nothing should come back except possibly a URL. If your key appears, the build
picked up the market keys from `supabase.env.json` and you have shipped them.

**The app is using the proxy.** Open the Market Board with the device offline
from your dev machine — on someone else's phone is the real test. Prices load,
and nothing in the logs mentions a direct vendor request.

## Rate limits become shared

Worth knowing before release. Finnhub's free tier is 60 calls a minute **for
the account**, not per user. Through the proxy that is now shared by everyone
using the app at once, so ten simultaneous players are ten times the traffic.

The board already helps here — it fetches four symbols per tick rather than
sixteen (see `MarketDataService.selectBatch`), which cut its own usage by three
quarters. But if the app gets real traffic, the next step is caching *inside*
the edge function: one fetch per symbol per interval, served to every caller,
instead of one per caller. That is a change to `index.ts` alone and needs no
app release.

## The other keys

There are none. Supabase auth, storage and the database all go through the anon
key plus row-level security, and there is no analytics or advertising SDK in the
app to have a key for — see `docs/PLAY_STORE_DATA_SAFETY.md`.
