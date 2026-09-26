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

  -- `user_stats.id` and `app_feedback.user_id` are both `text` (the app also
  -- stores non-uuid ids like the local guest placeholder 'user_123' there),
  -- not `uuid` like `uid`. Postgres has no `text = uuid` operator, so without
  -- the cast both of these throw `42883 operator does not exist` and abort
  -- the whole function -- silently, from the caller's point of view, because
  -- the client-side error handling reported it as the same generic failure
  -- as the earlier wrong-column-name bug this line already fixed once.
  delete from public.user_stats where id = uid::text;
  delete from public.app_feedback where user_id = uid::text;

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
