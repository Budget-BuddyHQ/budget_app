-- Four more columns on the leaderboard view, for the friend profile screen.
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
-- WHAT IS DELIBERATELY NOT HERE
-- -----------------------------
-- No email, no age band, no gender, no transaction ledger, no holdings. This
-- view is readable by every authenticated user — that is the whole point of a
-- leaderboard — so anything added to it is published to everyone who can sign
-- in. The four below are all facts about how somebody plays a game. The
-- under-13 exclusion in the WHERE clause is unchanged and is the other half
-- of that: a self-declared child's row never appears here at all.

create or replace view public.leaderboard as
select
  id,
  username,
  literacy_points,
  xp,
  gold,
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

  updated_at
from public.user_stats
where coalesce(spending_habits->>'age_band', '') <> 'under_13';

grant select on table public.leaderboard to authenticated;
