// Market-data proxy.
//
// Why this exists: the app used to read FINNHUB_API_KEY / TWELVE_DATA_API_KEY
// on the client. That meant (a) the key shipped inside every build, where
// anyone can pull it out of the binary, and (b) Finnhub's free tier of 60
// calls/minute is *per key*, not per user — so fifty people opening the
// Market Board at once rate-limited each other.
//
// Both problems go away here. The keys live as Supabase secrets, and the
// response cache below means a thousand users cost the same number of upstream
// calls as one. The cache is the part that actually makes this scale; hiding
// the key is just the part that makes it safe.
//
// Deploy:
//   supabase secrets set FINNHUB_API_KEY=...  TWELVE_DATA_API_KEY=...
//   supabase functions deploy market
//
// Auth: `verify_jwt` is on by default, and the anon key is itself a valid JWT,
// so signed-out players still get data while the market keys stay server-side.

const FINNHUB_KEY = Deno.env.get('FINNHUB_API_KEY') ?? '';
const TWELVE_DATA_KEY = Deno.env.get('TWELVE_DATA_API_KEY') ?? '';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

interface CacheEntry {
  body: string;
  expiresAt: number;
}

// Per-instance cache. Edge functions keep a warm instance between invocations,
// so this absorbs the overwhelming majority of repeat traffic. It is not
// shared across instances, and that is fine — worst case a handful of
// instances each hold their own copy, which is still orders of magnitude
// fewer upstream calls than one-per-user.
const cache = new Map<string, CacheEntry>();

// Quotes go stale fast; candles and search results do not. Company profile
// is effectively static (an hour is generous, not stingy); news is capped
// at 15 minutes since new articles do land through the day.
// How long a cached vendor response stays good.
//
// `quote` is the one that matters for how live the board feels. It is the
// gap between two calls *to Finnhub*, not between two calls to this function:
// the app can ask as often as it likes and only every Nth request costs a
// vendor call. 12s against a 60-call minute leaves room for sixteen symbols
// plus candles and news, and no real share moves enough in twelve seconds for
// the difference to be visible.
const TTL_MS = {
  quote: 12_000,
  candles: 5 * 60_000,
  search: 60 * 60_000,
  twelveQuote: 60_000,
  profile: 60 * 60_000,
  news: 15 * 60_000,
} as const;

// --- Shared cache (Postgres) ---------------------------------------------
//
// **The in-memory Map below is not enough on its own, and that was measured.**
// Eight identical requests to the deployed function all reported
// `X-Cache: 0/3 HIT`, while a health check straight afterwards reported
// `cacheSize: 3`: Supabase spreads requests across isolates, so the cache was
// being written and never read.
//
// With the board polling every two seconds for sixteen symbols, a cache that
// never hits is 480 vendor calls a minute against a limit of 60 — the first
// person to open the Market Board would be throttled within seconds, and
// everybody else with them.
//
// So the Map stays as a free first look (it does hit when an isolate happens
// to be reused), and Postgres is the one every isolate shares. The
// service-role key bypasses RLS, which is why the table needs no policy and
// has none — see 0004_market_cache.sql.
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const SHARED_CACHE = SUPABASE_URL !== '' && SERVICE_KEY !== '';

function restHeaders() {
  return {
    apikey: SERVICE_KEY,
    Authorization: `Bearer ${SERVICE_KEY}`,
    'Content-Type': 'application/json',
  };
}

/** Unexpired rows for `keys`, as a key -> body map. Never throws. */
async function sharedGet(keys: string[]): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  if (!SHARED_CACHE || keys.length === 0) return out;
  try {
    const list = keys.map((k) => `"${k}"`).join(',');
    const url =
      `${SUPABASE_URL}/rest/v1/market_cache` +
      `?select=key,body&key=in.(${encodeURIComponent(list)})` +
      `&expires_at=gt.${encodeURIComponent(new Date().toISOString())}`;
    const response = await fetch(url, { headers: restHeaders() });
    if (!response.ok) return out;
    const rows = await response.json();
    if (!Array.isArray(rows)) return out;
    for (const row of rows) {
      if (typeof row?.key === 'string' && row.body !== undefined) {
        out.set(row.key, JSON.stringify(row.body));
      }
    }
  } catch {
    // A cache miss is always survivable; a throw here would take down a
    // request that could still have been served from the vendor.
  }
  return out;
}

/** Upserts one entry. Fire-and-forget: the caller already has its answer. */
async function sharedPut(key: string, body: string, ttlMs: number) {
  if (!SHARED_CACHE) return;
  try {
    let parsed: unknown;
    try {
      parsed = JSON.parse(body);
    } catch {
      return; // Only valid JSON goes in a jsonb column.
    }
    await fetch(`${SUPABASE_URL}/rest/v1/market_cache`, {
      method: 'POST',
      headers: { ...restHeaders(), Prefer: 'resolution=merge-duplicates' },
      body: JSON.stringify({
        key,
        body: parsed,
        expires_at: new Date(Date.now() + ttlMs).toISOString(),
        updated_at: new Date().toISOString(),
      }),
    });
  } catch {
    // Same reasoning as above.
  }
}

function cached(key: string): string | null {
  const hit = cache.get(key);
  if (!hit) return null;
  if (Date.now() > hit.expiresAt) {
    cache.delete(key);
    return null;
  }
  return hit.body;
}

function store(key: string, body: string, ttlMs: number) {
  cache.set(key, { body, expiresAt: Date.now() + ttlMs });
  // Cheap bound so a long-lived instance can't grow without limit.
  if (cache.size > 500) {
    const oldest = cache.keys().next().value;
    if (oldest) cache.delete(oldest);
  }
}

function json(body: unknown, status = 200) {
  return new Response(typeof body === 'string' ? body : JSON.stringify(body), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

/** Symbols are `[A-Z.-]{1,12}`; anything else is rejected before it reaches an
 * upstream URL. */
function cleanSymbol(raw: string | null): string | null {
  if (!raw) return null;
  const upper = raw.trim().toUpperCase();
  return /^[A-Z.\-]{1,12}$/.test(upper) ? upper : null;
}

async function passthrough(
  url: string,
  headers: HeadersInit,
  cacheKey: string,
  ttlMs: number,
) {
  const local = cached(cacheKey);
  if (local !== null) {
    return new Response(local, {
      status: 200,
      headers: { ...CORS, 'Content-Type': 'application/json', 'X-Cache': 'HIT' },
    });
  }

  const shared = (await sharedGet([cacheKey])).get(cacheKey);
  if (shared !== undefined) {
    // Warm this isolate too, so a second request landing here is free.
    store(cacheKey, shared, ttlMs);
    return new Response(shared, {
      status: 200,
      headers: {
        ...CORS,
        'Content-Type': 'application/json',
        'X-Cache': 'HIT-DB',
      },
    });
  }

  const upstream = await fetch(url, { headers });
  const body = await upstream.text();

  // Only cache successes — caching a 429 would extend the rate limit rather
  // than absorb it.
  if (upstream.ok) {
    store(cacheKey, body, ttlMs);
    await sharedPut(cacheKey, body, ttlMs);
  }

  return new Response(body, {
    status: upstream.status,
    headers: { ...CORS, 'Content-Type': 'application/json', 'X-Cache': 'MISS' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS });
  }

  const url = new URL(req.url);
  const op = url.searchParams.get('op');

  try {
    switch (op) {
      case 'quote': {
        if (!FINNHUB_KEY) {
          return json({ error: 'FINNHUB_API_KEY is not set' }, 503);
        }
        const symbol = cleanSymbol(url.searchParams.get('symbol'));
        if (!symbol) return json({ error: 'bad symbol' }, 400);
        return await passthrough(
          `https://finnhub.io/api/v1/quote?symbol=${symbol}`,
          { 'X-Finnhub-Token': FINNHUB_KEY },
          `quote:${symbol}`,
          TTL_MS.quote,
        );
      }

      // Every tracked symbol in one response.
      //
      // **Why this exists.** The board used to fetch symbols one at a time,
      // which put its refresh rate directly against Finnhub's 60-call minute:
      // sixteen symbols meant one full update every sixteen seconds at best,
      // and most of those calls were spent on prices scrolled off screen.
      //
      // Batching moves the constraint. One request to this function returns
      // everything, served from cache unless a symbol's twelve seconds are up,
      // so the app can poll every two seconds and the vendor still sees at
      // most five calls a minute per symbol. It also collapses sixteen edge
      // function invocations into one, which matters because those are billed
      // per invocation.
      //
      // Partial failure is deliberate: one symbol that 429s or times out
      // returns null in the map rather than failing the whole response. A
      // board that blanks because one ticker was slow is worse than a board
      // with fifteen fresh prices and one stale one.
      case 'quotes': {
        if (!FINNHUB_KEY) {
          return json({ error: 'FINNHUB_API_KEY is not set' }, 503);
        }
        const raw = (url.searchParams.get('symbols') ?? '').split(',');
        const symbols = raw
          .map(cleanSymbol)
          .filter((s): s is string => s !== null)
          .slice(0, 32);
        if (symbols.length === 0) return json({ quotes: {} });

        const out: Record<string, unknown> = {};
        let hits = 0;

        // One round trip for every symbol, rather than one per symbol. The
        // whole point of this operation is to collapse sixteen calls into
        // one, and doing sixteen cache reads to serve it would put the cost
        // straight back.
        const shared = await sharedGet(symbols.map((s) => `quote:${s}`));

        await Promise.all(
          symbols.map(async (symbol) => {
            const key = `quote:${symbol}`;
            const hit = cached(key) ?? shared.get(key) ?? null;
            if (hit !== null) {
              hits++;
              store(key, hit, TTL_MS.quote);
              try {
                out[symbol] = JSON.parse(hit);
              } catch {
                out[symbol] = null;
              }
              return;
            }
            try {
              const upstream = await fetch(
                `https://finnhub.io/api/v1/quote?symbol=${symbol}`,
                { headers: { 'X-Finnhub-Token': FINNHUB_KEY } },
              );
              const body = await upstream.text();
              if (upstream.ok) {
                store(key, body, TTL_MS.quote);
                await sharedPut(key, body, TTL_MS.quote);
                out[symbol] = JSON.parse(body);
              } else {
                out[symbol] = null;
              }
            } catch {
              out[symbol] = null;
            }
          }),
        );

        return new Response(JSON.stringify({ quotes: out }), {
          status: 200,
          headers: {
            ...CORS,
            'Content-Type': 'application/json',
            // Useful when checking by hand that the cache is doing its job:
            // a board polling every two seconds should show mostly hits.
            'X-Cache': `${hits}/${symbols.length} HIT`,
          },
        });
      }

      case 'search': {
        if (!FINNHUB_KEY) {
          return json({ error: 'FINNHUB_API_KEY is not set' }, 503);
        }
        const q = (url.searchParams.get('q') ?? '').trim().slice(0, 40);
        if (!q) return json({ count: 0, result: [] });
        return await passthrough(
          `https://finnhub.io/api/v1/search?q=${encodeURIComponent(q)}`,
          { 'X-Finnhub-Token': FINNHUB_KEY },
          `search:${q.toLowerCase()}`,
          TTL_MS.search,
        );
      }

      case 'candles': {
        if (!TWELVE_DATA_KEY) {
          return json({ error: 'TWELVE_DATA_API_KEY is not set' }, 503);
        }
        const symbol = cleanSymbol(url.searchParams.get('symbol'));
        if (!symbol) return json({ error: 'bad symbol' }, 400);
        const interval = (url.searchParams.get('interval') ?? '5min').slice(
          0,
          10,
        );
        const outputsize = Math.min(
          Math.max(parseInt(url.searchParams.get('outputsize') ?? '78', 10) || 78, 2),
          500,
        );
        const target =
          `https://api.twelvedata.com/time_series?symbol=${symbol}` +
          `&interval=${encodeURIComponent(interval)}` +
          `&outputsize=${outputsize}&apikey=${TWELVE_DATA_KEY}`;
        return await passthrough(
          target,
          {},
          `candles:${symbol}:${interval}:${outputsize}`,
          TTL_MS.candles,
        );
      }

      case 'twelve_quote': {
        if (!TWELVE_DATA_KEY) {
          return json({ error: 'TWELVE_DATA_API_KEY is not set' }, 503);
        }
        const symbol = cleanSymbol(url.searchParams.get('symbol'));
        if (!symbol) return json({ error: 'bad symbol' }, 400);
        const target =
          `https://api.twelvedata.com/quote?symbol=${symbol}&apikey=${TWELVE_DATA_KEY}`;
        return await passthrough(
          target,
          {},
          `twelve_quote:${symbol}`,
          TTL_MS.twelveQuote,
        );
      }

      case 'profile': {
        if (!FINNHUB_KEY) {
          return json({ error: 'FINNHUB_API_KEY is not set' }, 503);
        }
        const symbol = cleanSymbol(url.searchParams.get('symbol'));
        if (!symbol) return json({ error: 'bad symbol' }, 400);
        return await passthrough(
          `https://finnhub.io/api/v1/stock/profile2?symbol=${symbol}`,
          { 'X-Finnhub-Token': FINNHUB_KEY },
          `profile:${symbol}`,
          TTL_MS.profile,
        );
      }

      case 'news': {
        if (!FINNHUB_KEY) {
          return json({ error: 'FINNHUB_API_KEY is not set' }, 503);
        }
        const symbol = cleanSymbol(url.searchParams.get('symbol'));
        if (!symbol) return json({ error: 'bad symbol' }, 400);
        // YYYY-MM-DD only — same shape Finnhub expects, rejected otherwise
        // rather than passed through unvalidated to an upstream URL.
        const dateRe = /^\d{4}-\d{2}-\d{2}$/;
        const from = url.searchParams.get('from') ?? '';
        const to = url.searchParams.get('to') ?? '';
        if (!dateRe.test(from) || !dateRe.test(to)) {
          return json({ error: 'bad date range' }, 400);
        }
        return await passthrough(
          `https://finnhub.io/api/v1/company-news?symbol=${symbol}&from=${from}&to=${to}`,
          { 'X-Finnhub-Token': FINNHUB_KEY },
          `news:${symbol}:${from}:${to}`,
          TTL_MS.news,
        );
      }

      case 'health': {
        // Reports whether the *shared* cache is reachable, not just
        // configured. `sharedCache: false` here is the difference between a
        // board that polls every two seconds safely and one that makes 480
        // vendor calls a minute, so it is worth an actual round trip.
        let sharedOk = false;
        if (SHARED_CACHE) {
          try {
            const probe = await fetch(
              `${SUPABASE_URL}/rest/v1/market_cache?select=key&limit=1`,
              { headers: restHeaders() },
            );
            sharedOk = probe.ok;
          } catch {
            sharedOk = false;
          }
        }
        return json({
          ok: true,
          finnhub: Boolean(FINNHUB_KEY),
          twelveData: Boolean(TWELVE_DATA_KEY),
          isolateCache: cache.size,
          sharedCache: sharedOk,
        });
      }

      default:
        return json({ error: 'unknown op' }, 400);
    }
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});
