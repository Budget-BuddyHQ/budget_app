# -*- coding: utf-8 -*-
"""Bake the *public* Supabase config into the app.

**What problem this solves.** Until now the only key source that survived into
an installed build was `--dart-define`, so a release built without the right
flags shipped with no Supabase config at all: sign-in did nothing, the Market
Board had no proxy, and friends could not load. It worked on the developer's
laptop because `supabase.env.json` sits in the project folder, and a phone has
no such folder. That is a build you can only make correctly by remembering a
long command line, which is a build that will eventually go out wrong.

So the two values that are *public by design* get written into a Dart source
file and committed, and a plain `flutter build` produces a working app.

**Why it is safe, stated precisely.** `SUPABASE_ANON_KEY` is not a password.
It identifies the project and nothing else; every row it can reach is guarded
by row-level security, and Supabase publishes it in their own client examples.
It is designed to sit in a browser bundle where anyone can read it. Same for
the project URL.

**What must never end up here.** `FINNHUB_API_KEY` and `TWELVE_DATA_API_KEY`
are rate-limited credentials tied to a personal account, and anything inside an
APK can be recovered with `strings` in about a minute. Those live as Supabase
secrets on the `market` edge function, which is the entire reason that function
exists. This script refuses to write them — see [FORBIDDEN] — rather than
trusting whoever edits it next to remember.

Run:  python tool/write_public_config.py
"""
from __future__ import annotations

import json
import os
import sys

SOURCE = 'supabase.env.json'
TARGET = os.path.join('lib', 'config', 'public_supabase_config.dart')

# Only these. Everything else in the env file stays out of the binary.
PUBLIC_KEYS = ('SUPABASE_URL', 'SUPABASE_ANON_KEY')

# Substrings that must never appear in a key that gets written. Checked as a
# guard against a future edit widening PUBLIC_KEYS by accident.
FORBIDDEN = ('FINNHUB', 'TWELVE', 'SERVICE_ROLE', 'SECRET', 'PASSWORD')

TEMPLATE = '''// GENERATED FILE — do not edit by hand.
// Regenerate with: python tool/write_public_config.py
//
// **These two values are public on purpose, and this file is committed.**
//
// `SUPABASE_ANON_KEY` is not a password. It identifies the project and
// nothing more; every row it can reach is guarded by row-level security, and
// Supabase publishes it in their own client examples — it is designed to live
// in a browser bundle where anybody can read it.
//
// Baking it in is what makes a plain `flutter build` produce a working app.
// Before this, the only source that survived onto a phone was
// `--dart-define`, so a release built without the right flags shipped with no
// Supabase config at all: sign-in did nothing, the Market Board had no proxy,
// and friends could not load. It worked on a laptop only because
// `supabase.env.json` happens to sit in the project folder.
//
// **The market API keys are deliberately absent.** Finnhub and Twelve Data
// credentials are rate-limited and tied to a personal account, and anything
// in an APK can be recovered with `strings`. They live as Supabase secrets on
// the `market` edge function, which is the whole reason that function exists.
// `tool/write_public_config.py` refuses to write them here.
//
// These are still the *lowest* priority source — an environment variable or a
// `--dart-define` overrides them, so a different build can point at a
// different project without touching this file.
library;

const Map<String, String> kPublicSupabaseConfig = <String, String>{
%s};
'''


def main() -> None:
    if not os.path.exists(SOURCE):
        sys.exit(
            f'{SOURCE} not found. It is gitignored and holds the project '
            f'values; create it before running this.'
        )

    with open(SOURCE, encoding='utf8') as handle:
        env = json.load(handle)

    lines = []
    for key in PUBLIC_KEYS:
        for banned in FORBIDDEN:
            if banned in key.upper():
                sys.exit(
                    f'refusing to write {key}: it looks like a secret, and '
                    f'a secret in a committed Dart file is a secret in every '
                    f'APK you ship'
                )
        value = str(env.get(key, '')).strip()
        if not value:
            sys.exit(f'{key} is missing or empty in {SOURCE}')
        if "'" in value or '\\' in value or '\n' in value:
            sys.exit(f'{key} contains a character that needs escaping')
        lines.append(f"  '{key}': '{value}',\n")

    os.makedirs(os.path.dirname(TARGET), exist_ok=True)
    with open(TARGET, 'w', encoding='utf8') as handle:
        handle.write(TEMPLATE % ''.join(lines))

    # Deliberately reports shape rather than content: this runs in terminals
    # and CI logs that get pasted into issues.
    print(f'wrote {TARGET}')
    for key in PUBLIC_KEYS:
        print(f'  {key:22} {len(str(env[key]).strip())} chars')
    skipped = [k for k in env if k not in PUBLIC_KEYS]
    print(f'  left out of the binary: {", ".join(sorted(skipped))}')


if __name__ == '__main__':
    main()
