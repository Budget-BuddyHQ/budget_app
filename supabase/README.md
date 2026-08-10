# Supabase pieces

## `functions/market` — the market-data proxy

### Why

The app used to read `FINNHUB_API_KEY` and `TWELVE_DATA_API_KEY` on the client,
from an environment variable or `supabase.env.json`. Two problems with that:

1. **The key ships inside the build.** Anyone with the app can pull a string
   out of the binary. There is no way to hide a secret in client code.
2. **The free tiers are per key, not per user.** Finnhub allows 60 calls a
   minute *in total*; Twelve Data allows 8 a minute and 800 a day. With one
   shared key, fifty players opening the Market Board at once rate-limit each
   other, and the app shows "Rate limited by Finnhub" to all of them.

The second problem is the one that actually breaks the app at any real user
count, and hiding the key does nothing for it. The fix for both is a proxy that
holds the key **and caches the response**: one upstream call serves every
player who asks for the same symbol inside the TTL.

### Cache TTLs

| Op | TTL | Reason |
| --- | --- | --- |
| `quote` | 30s | The board polls every 30s anyway |
| `candles` | 5 min | Intraday bars barely move within that |
| `search` | 1 hour | Ticker lists are effectively static |

The cache is per warm instance, not shared across them. That is deliberate —
it needs no extra infrastructure, and even a handful of instances each holding
their own copy is orders of magnitude fewer upstream calls than one per user.

### Deploy

```bash
supabase secrets set FINNHUB_API_KEY=your_finnhub_key TWELVE_DATA_API_KEY=your_twelve_data_key
```

```bash
supabase functions deploy market
```

Check it came up:

```bash
curl -s "$SUPABASE_URL/functions/v1/market?op=health" -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

That returns `{"ok":true,"finnhub":true,"twelveData":true,"cacheSize":0}` when
both secrets are set.

### Auth

`verify_jwt` is on by default and the **anon key is itself a valid JWT**, so
signed-out players still get market data while the vendor keys stay
server-side. The anon key is public by design — it is already in every build,
and Row Level Security is what protects user data, not that key's secrecy.

### Client behaviour

`MarketDataService.usesProxy` is true whenever `SUPABASE_URL` and
`SUPABASE_ANON_KEY` are configured, and all three fetch paths (quotes, search,
candles) then route through the function. When Supabase is *not* configured the
service falls back to calling the vendors directly with a local key, so a
contributor can still clone the repo, drop in their own Finnhub key, and run
the app with no Supabase project at all.

`test/market_proxy_test.dart` asserts that nothing key-shaped reaches the wire:
no `apikey` query parameter, no `X-Finnhub-Token` header, and no request to
`finnhub.io` from the client.

### After deploying

The client keys become unnecessary. Remove `FINNHUB_API_KEY` and
`TWELVE_DATA_API_KEY` from `supabase.env.json` and from any build
`--dart-define`s — if they are still there the app works either way, but the
key is still shipping to users for no benefit.
