# -*- coding: utf-8 -*-
"""Concatenate every migration into one paste-ready file.

**Why this exists.** The migrations are correct and have been for weeks; they
have simply never been run, and friends has been broken the whole time
because of it. Twice now the answer has been "see `supabase/migrations/`",
which is a folder, and a folder is a decision about which file to open and in
what order. This is the version with no decisions in it: one file, top to
bottom, into the SQL editor.

Every statement is `if not exists` / `create or replace` / `do $$ ... $$` with
its own existence check, so running the whole thing repeatedly is safe and
running it when half of it is already applied is safe too.

Run:  python tool/build_pending_sql.py
"""
from __future__ import annotations

import glob
import os

SRC = os.path.join('supabase', 'migrations')
OUT = os.path.join('supabase', 'RUN_THIS_IN_SUPABASE.sql')

HEADER = """-- ============================================================
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


"""

FOOTER = """

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
"""


def main() -> None:
    files = sorted(glob.glob(os.path.join(SRC, '*.sql')))
    if not files:
        raise SystemExit(f'no migrations found in {SRC}')

    chunks = [HEADER]
    for path in files:
        name = os.path.basename(path)
        chunks.append(
            '-- ' + '-' * 58 + f'\n-- {name}\n-- ' + '-' * 58 + '\n\n'
        )
        with open(path, encoding='utf8') as handle:
            chunks.append(handle.read().rstrip())
        chunks.append('\n\n\n')
    chunks.append(FOOTER)

    with open(OUT, 'w', encoding='utf8') as handle:
        handle.write(''.join(chunks))

    print(f'{OUT}  ({len(files)} migrations, '
          f'{os.path.getsize(OUT) // 1024}KB)')
    for path in files:
        print(f'  + {os.path.basename(path)}')


if __name__ == '__main__':
    main()
