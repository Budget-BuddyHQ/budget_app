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
