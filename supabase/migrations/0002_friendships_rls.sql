-- Friends: the row-level security this table has been missing.
--
-- **The symptom.** Adding a friend code shows "Could not add that friend
-- right now (42501)". Probing the live database directly returns:
--
--     42501 — new row violates row-level security policy for table
--     "friendships"
--
-- Note *which* 42501 it is. "permission denied for table" would mean the
-- GRANT is missing; "new row violates row-level security policy" means the
-- grant is fine and there is no INSERT **policy** that accepts the row. The
-- table was created and RLS was switched on, but the policies below were
-- never applied — so with RLS enabled and no policy, every write is refused.
--
-- The same block lives as a comment in `supabase_service.dart` next to the
-- code that depends on it. It is repeated here as a file you can paste
-- straight into the Supabase SQL editor, because a schema comment is
-- documentation and this is the thing that actually has to be run.
--
-- Safe to run more than once: everything is `if not exists`.

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, friend_id)
);

-- `delete` as well as insert: a friends list you cannot leave is not a
-- friends list. No `update` on purpose — nothing about an edge can change,
-- and withholding it means a stray upsert fails loudly rather than quietly
-- rewriting somebody else's row. The client sends
-- `resolution=ignore-duplicates` (ON CONFLICT DO NOTHING) for exactly this
-- reason, so re-adding a friend you already have needs no UPDATE.
grant select, insert, delete on table public.friendships to authenticated;

alter table public.friendships enable row level security;

do $$
begin
  -- A row is a directed edge, "user_id added friend_id", and both ends can
  -- read it — which is what lets a friendship read as mutual once either
  -- person has added the other's code.
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'friendships'
      and policyname = 'Users can read friendships they are part of'
  ) then
    create policy "Users can read friendships they are part of"
      on public.friendships
      for select
      to authenticated
      using (user_id = (select auth.uid()) or friend_id = (select auth.uid()));
  end if;

  -- The one that was missing. Without it, RLS is on and nothing may insert.
  -- `with check` rather than `using`: it constrains the row being written,
  -- so you can only ever create an edge that starts at yourself.
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'friendships'
      and policyname = 'Users can only add friends as themselves'
  ) then
    create policy "Users can only add friends as themselves"
      on public.friendships
      for insert
      to authenticated
      with check (user_id = (select auth.uid()));
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'friendships'
      and policyname = 'Users can remove their own friendships'
  ) then
    create policy "Users can remove their own friendships"
      on public.friendships
      for delete
      to authenticated
      using (user_id = (select auth.uid()));
  end if;
end
$$;

-- Check it took. Expect three rows.
--
--   select policyname, cmd from pg_policies
--   where schemaname = 'public' and tablename = 'friendships';
