-- Extra columns on the leaderboard view: the friend profile screen, and
-- the Ranked board.
--
-- **What this is for.** Tapping a friend now opens a profile rather than
-- doing nothing, and a profile built from a username, three numbers and a
-- rank is a leaderboard row drawn larger. These are the fields that make it
-- worth opening: what they look like, how they play, how much of the Academy
-- they have done, and whether they are still around.
--
-- **The app works without this migration**, deliberately. `LeaderboardEntry`
-- defaults every one of these to empty, and `FriendProfileScreen` hides the
-- section rather than showing a zero. That is not politeness — this project
-- shipped the friends feature ahead of `0002_friendships_rls.sql` and spent
-- weeks showing players a raw Postgres error code, and the lesson from that
-- is that a feature which *requires* a migration is a feature that breaks
-- whenever somebody forgets to run one.
--
-- Safe to run more than once: `create or replace` on a view.
--
--
-- WHY THE NEW COLUMNS ARE AT THE END
-- ----------------------------------
-- Running this the first time failed:
--
--   ERROR 42P16: cannot change name of view column "updated_at" to
--   "profile_image_url"
--
-- `create or replace view` may only **append** columns. It cannot insert,
-- reorder or rename them, because anything already selecting from the view
-- is positionally bound to what is there. The original draft put the four new
-- columns in the middle, which meant renaming column six.
--
-- The fix is ordering, not `drop view`. Dropping would work and would also
-- take out anything that had come to depend on the view, silently, at the
-- moment somebody is running a migration by hand in a web console. Column
-- order is invisible to the app — `_leaderboardEntryFrom` reads by name — so
-- appending costs nothing.
--
--
-- WHAT IS DELIBERATELY NOT HERE
-- -----------------------------
-- No email, no age band, no gender, no transaction ledger, no holdings. This
-- view is readable by every authenticated user — that is the whole point of a
-- leaderboard — so anything added to it is published to everyone who can sign
-- in. The four below are all facts about how somebody plays a game.
--
--
-- THE AGE FILTER, WHICH WAS WRONG
-- -------------------------------
-- The `where` clause used to read:
--
--   where coalesce(spending_habits->>'age_band', '') <> 'under_13'
--
-- That was correct when `under_13` was the only child band. It stopped being
-- correct the day the bucket was split into `under_9` (ages 4-8) and
-- `age9to12` — which **kept the stored id `under_13`** so existing accounts
-- would not be re-aged.
--
-- So the split created a band the filter had never heard of, and the newest,
-- youngest one at that: a four-to-eight-year-old's username, gold and profile
-- image were published to every authenticated user of the app. Nothing threw.
-- The filter kept excluding a real band, so it looked like it was working.
--
-- Both ids are now excluded by name. New child bands must be added here as
-- well as in `player_profile.dart`, and `test/child_safety_test.dart` checks
-- that this file names every band that reports itself as a child.

create or replace view public.leaderboard as
select
  id,
  username,
  literacy_points,
  xp,
  gold,
  updated_at,

  spending_habits->>'profile_image_url' as profile_image_url,

  -- Which villager they walk around as. Drawing a friend as their own
  -- character rather than as the first letter of their name is most of what
  -- makes the screen feel like a person.
  spending_habits->>'equipped_skin' as equipped_skin,

  -- "Saver", "Spender", "Investor". The app's own read on how they play, and
  -- the one line on the profile that is about behaviour rather than score.
  personality_type,

  -- How much of the Academy they have finished. `jsonb_array_length` throws
  -- on anything that is not an array, and `completed_lessons` is absent on a
  -- fresh account, so the type is checked before the length is taken.
  case
    when jsonb_typeof(spending_habits->'completed_lessons') = 'array'
      then jsonb_array_length(spending_habits->'completed_lessons')
    else 0
  end as lessons_completed,

  -- Their daily streak. Stored as a JSON number or string depending on how it
  -- was last written, so it is coerced rather than cast: a bad cast here
  -- would take the whole leaderboard down, not just one column.
  coalesce(
    nullif(regexp_replace(
      coalesce(spending_habits->>'daily_streak', '0'), '[^0-9]', '', 'g'
    ), '')::int,
    0
  ) as daily_streak,

  -- The Ranked board.
  --
  -- Ranked is the one-life scored mode, and it had no leaderboard because it
  -- had no memory: the score was shown on the epilogue screen and thrown
  -- away with it. Now that `recordRankedRun` keeps a personal best, these
  -- three make it comparable.
  --
  -- Coerced the same way `daily_streak` is, for the same reason: this is
  -- JSON written by clients of several versions, and a bad cast takes the
  -- whole leaderboard down rather than one column.
  coalesce(
    nullif(regexp_replace(
      coalesce(spending_habits->>'best_ranked_score', '0'), '[^0-9]', '', 'g'
    ), '')::int,
    0
  ) as best_ranked_score,

  coalesce(spending_habits->>'best_ranked_grade', '') as best_ranked_grade,

  coalesce(
    nullif(regexp_replace(
      coalesce(spending_habits->>'best_ranked_age', '0'), '[^0-9]', '', 'g'
    ), '')::int,
    0
  ) as best_ranked_age

from public.user_stats
where coalesce(spending_habits->>'age_band', '') not in ('under_9', 'under_13');

grant select on table public.leaderboard to authenticated;
