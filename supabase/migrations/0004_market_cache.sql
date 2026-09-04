-- A cache the market edge function can actually rely on.
--
-- **Why an in-memory cache was not enough.** The function kept quotes in a
-- plain `Map` inside the isolate. Measured against the deployed function, that
-- does not work: eight identical requests sent back to back all reported
-- `X-Cache: 0/3 HIT`, and a health check immediately afterwards reported
-- `cacheSize: 3`. The cache was being written and never read, because Supabase
-- spreads requests across isolates and each one starts empty.
--
-- That is not a small inefficiency, it is a rate-limit incident waiting to
-- happen. The board polls every two seconds for sixteen symbols; with no
-- shared cache that is 480 calls a minute against a Finnhub limit of 60, so
-- the first person to open the Market Board would be throttled within seconds
-- and every other user would be throttled with them.
--
-- Postgres is the one thing every isolate does share.
--
-- **Why it is safe to expose nothing.** No policy is created and RLS is on,
-- which means anon and authenticated clients can read and write exactly
-- nothing. Only the edge function touches this table, and it does so with the
-- service-role key, which bypasses RLS by design. The data is public share
-- prices anyway; the table is locked down because a cache somebody else can
-- write to is a cache that can be poisoned.

create table if not exists public.market_cache (
  key text primary key,
  body jsonb not null,
  expires_at timestamptz not null,
  updated_at timestamptz not null default timezone('utc', now())
);

-- The function only ever asks for unexpired rows.
create index if not exists market_cache_expires_at_idx
  on public.market_cache (expires_at);

alter table public.market_cache enable row level security;

-- Deliberately no grants and no policies: see the note above. Revoked
-- explicitly rather than relying on the default, so that a later
-- `grant all on all tables` cannot quietly open it.
revoke all on table public.market_cache from anon, authenticated;

-- Housekeeping. The table is small by construction -- one row per symbol per
-- operation -- but a symbol that stops being tracked would otherwise sit here
-- forever. Called by the function on write; cheap because of the index.
create or replace function public.prune_market_cache()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.market_cache
  where expires_at < timezone('utc', now()) - interval '1 hour';
$$;

revoke all on function public.prune_market_cache() from public, anon, authenticated;
