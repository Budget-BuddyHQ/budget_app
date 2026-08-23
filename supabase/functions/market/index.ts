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
const TTL_MS = {
  quote: 30_000,
  candles: 5 * 60_000,
  search: 60 * 60_000,
  twelveQuote: 60_000,
  profile: 60 * 60_000,
  news: 15 * 60_000,
} as const;

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
  const hit = cached(cacheKey);
  if (hit !== null) {
    return new Response(hit, {
      status: 200,
      headers: { ...CORS, 'Content-Type': 'application/json', 'X-Cache': 'HIT' },
    });
  }

  const upstream = await fetch(url, { headers });
  const body = await upstream.text();

  // Only cache successes — caching a 429 would extend the rate limit rather
  // than absorb it.
  if (upstream.ok) {
    store(cacheKey, body, ttlMs);
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

      case 'health':
        return json({
          ok: true,
          finnhub: Boolean(FINNHUB_KEY),
          twelveData: Boolean(TWELVE_DATA_KEY),
          cacheSize: cache.size,
        });

      default:
        return json({ error: 'unknown op' }, 400);
    }
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});
