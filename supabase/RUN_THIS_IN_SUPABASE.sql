-- ============================================================
--  Budget Buddy — everything the live database is missing
-- ============================================================
--
--  HOW TO RUN IT
--  1. Open your project at https://supabase.com/dashboard
--  2. Left sidebar -> SQL Editor -> New query
--  3. Paste this whole file in
--  4. Press Run (or Ctrl+Enter)
--
--  It takes a couple of seconds and prints "Success. No rows returned".
--
--  Safe to run more than once. Every statement checks for itself first, so
--  re-running it does nothing rather than erroring or duplicating.
--
--  WHAT BREAKS UNTIL YOU DO
--  * Friends does not work at all. Adding a code fails with Postgres 42501
--    ("new row violates row-level security policy") because the table has RLS
--    switched on and no INSERT policy to satisfy. This is the banner you keep
--    seeing on the Profile screen.
--  * "Delete my account" fails with 42883 (undefined_function). Google Play
--    requires that route to actually work, so this one blocks release.
--
--  GENERATED FILE — do not edit.
--  Source: supabase/migrations/*.sql, joined by tool/build_pending_sql.py
-- ============================================================


-- ----------------------------------------------------------
-- 0001_feedback_and_avatars.sql
-- ----------------------------------------------------------

-- Pieces the app uses that were never in `SupabaseService.schemaSql`.
--
-- `schemaSql` covers user_stats, the leaderboard view, and RLS policies. The
-- feedback screen and the profile-picture upload were added later and their
-- backing objects never got written down anywhere, so a fresh project (or a
-- project that predates those features) silently degrades: feedback queues
-- forever in SharedPreferences and never lands, and avatar uploads throw.
--
-- Safe to run more than once.

-- ---------------------------------------------------------------------------
-- app_feedback  — written by SupabaseService.submitFeedback()
-- ---------------------------------------------------------------------------
create table if not exists public.app_feedback (
  id          bigint generated always as identity primary key,
  category    text not null,
  message     text not null,
  user_id     text,
  user_email  text,
  submitted_at timestamptz not null default timezone('utc', now()),
  created_at  timestamptz not null default timezone('utc', now())
);

alter table public.app_feedback enable row level security;

-- Anyone signed in may file feedback. Nobody may read it back through the
-- API — you read it in the Supabase dashboard. Without this asymmetry one
-- user could read everyone else's reports.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'app_feedback'
      and policyname = 'Signed-in users can submit feedback'
  ) then
    create policy "Signed-in users can submit feedback"
      on public.app_feedback
      for insert
      to authenticated
      with check (true);
  end if;
end
$$;

grant insert on table public.app_feedback to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- ---------------------------------------------------------------------------
-- profile_pictures bucket — written by SupabaseService.uploadProfileImage()
--
-- Paths are `avatars/<auth uid>/avatar_<timestamp>.<ext>`, and the app calls
-- getPublicUrl() on the result, so the bucket must be public-read.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('profile_pictures', 'profile_pictures', true)
on conflict (id) do update set public = true;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Avatars are publicly readable'
  ) then
    create policy "Avatars are publicly readable"
      on storage.objects
      for select
      to public
      using (bucket_id = 'profile_pictures');
  end if;

  -- The folder check is what stops one player overwriting another's avatar.
  -- Path is avatars/<uid>/..., so foldername() gives {avatars, <uid>} and the
  -- uid is element 2 (Postgres arrays are 1-based).
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Users manage their own avatar folder'
  ) then
    create policy "Users manage their own avatar folder"
      on storage.objects
      for all
      to authenticated
      using (
        bucket_id = 'profile_pictures'
        and (storage.foldername(name))[2] = (select auth.uid())::text
      )
      with check (
        bucket_id = 'profile_pictures'
        and (storage.foldername(name))[2] = (select auth.uid())::text
      );
  end if;
end
$$;


-- ----------------------------------------------------------
-- 0002_friendships_rls.sql
-- ----------------------------------------------------------

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


-- ----------------------------------------------------------
-- 0003_account_deletion.sql
-- ----------------------------------------------------------

-- In-app account deletion.
--
-- WHY THIS IS A DATABASE FUNCTION AND NOT CLIENT CODE
-- ---------------------------------------------------
-- Removing a row from `auth.users` needs the service-role key. A mobile app
-- cannot hold that key -- anything shipped to a device is readable by anyone
-- who has the device, and a leaked service-role key is every account in the
-- project, not just this one. So the client cannot delete an auth user
-- directly, and the delete has to happen server-side.
--
-- `security definer` runs this function as its owner rather than as the
-- caller, which is what gives it the reach to touch `auth.users`. That makes
-- the function itself the security boundary, so it takes **no arguments**:
-- there is no user id to pass and therefore no user id to tamper with. It
-- deletes `auth.uid()` -- whoever is actually calling -- and nobody else.
-- A version taking `user_id uuid` would be a one-line "delete any account"
-- endpoint published to the internet.
--
-- Google Play requires an in-app deletion path for any app that lets you
-- create an account. Budget Buddy is aimed at ages 4-21, where "let me out"
-- ought to be easier than average rather than harder, and the previous
-- answer -- email us and ask -- is not something a nine-year-old is going to
-- do.
--
-- Run against the project before shipping:
--   supabase db push       (or paste into the SQL editor)

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
-- Pinned so a caller cannot shadow `auth` or `public` with a schema of their
-- own on the search path and have this run their tables instead of ours.
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'delete_own_account: no authenticated user';
  end if;

  -- Friendships are directed edges, so this user appears in two roles and
  -- both sides have to go. Deleting only the rows they own would leave other
  -- players with a friend entry pointing at an account that no longer exists.
  delete from public.friendships where user_id = uid or friend_id = uid;

  delete from public.user_stats where user_id = uid;
  delete from public.app_feedback where user_id = uid;

  -- Last, because everything above is keyed on it: removing the auth row
  -- first would leave the rest orphaned if any statement after it failed.
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;

comment on function public.delete_own_account() is
  'Deletes the calling user''s data and their auth record. Takes no '
  'arguments on purpose: it acts on auth.uid() so it cannot be aimed at '
  'another account.';




-- ============================================================
--  Did it work?
--  Run these two afterwards. The first should return 3 rows,
--  the second exactly 1.
-- ============================================================
--
--   select policyname, cmd from pg_policies
--   where schemaname = 'public' and tablename = 'friendships';
--
--   select proname from pg_proc
--   where proname = 'delete_own_account';
