# -*- coding: utf-8 -*-
"""Is the market edge function live, and is its cache working?

Run this after deploying. It reads the project URL and anon key from
`supabase.env.json`, calls the function the way the app does, and prints only
statuses and shapes -- never a key, because this gets run in terminals whose
output gets pasted into issues.

    python tool/check_market_proxy.py
"""
from __future__ import annotations

import json
import re
import sys
import time
import urllib.error
import urllib.request

SOURCE = 'supabase.env.json'


def call(url: str, key: str, query: str):
    request = urllib.request.Request(
        f'{url}/functions/v1/market?{query}',
        headers={'Authorization': f'Bearer {key}', 'apikey': key},
    )
    try:
        with urllib.request.urlopen(request, timeout=25) as response:
            return response.status, dict(response.headers), response.read().decode()
    except urllib.error.HTTPError as error:
        return error.code, dict(error.headers), error.read().decode()
    except Exception as error:  # noqa: BLE001 - reported, not raised
        return 'ERR', {}, str(error)


def redact(text: str) -> str:
    """Anything long and token-shaped goes, in case an error echoes a key."""
    return re.sub(r'[A-Za-z0-9_\-]{30,}', '<redacted>', text)[:200]


def main() -> None:
    try:
        env = json.load(open(SOURCE, encoding='utf8'))
    except FileNotFoundError:
        sys.exit(f'{SOURCE} not found')

    url = env['SUPABASE_URL'].rstrip('/')
    key = env['SUPABASE_ANON_KEY']
    print(f'project: {url.split("//")[1].split(".")[0]}\n')

    status, _, body = call(url, key, 'op=health')
    if status == 404:
        print('NOT DEPLOYED - the function does not exist yet.')
        print('  Setting the secrets does not create it; the code still has')
        print('  to be pushed. See docs/SHIPPING_KEYS.md.')
        sys.exit(1)
    if status == 401:
        print('DEPLOYED but rejecting the anon key (401).')
        print('  Turn off "Verify JWT" on the function, or redeploy with')
        print('  --no-verify-jwt. The app sends the anon key, not a user JWT.')
        sys.exit(1)
    print(f'health          {status}  {redact(body)}')

    try:
        health = json.loads(body)
    except Exception:  # noqa: BLE001
        health = {}
    if health.get('sharedCache') is False:
        print()
        print('  WARNING: the shared cache is not reachable.')
        print('  Run supabase/RUN_THIS_IN_SUPABASE.sql - it creates the')
        print('  market_cache table. Without it every isolate caches')
        print('  separately, nothing is ever a hit, and at a 2s poll that')
        print('  is 480 vendor calls a minute against a limit of 60.')
        print()

    for op in ('op=quote&symbol=AAPL', 'op=search&q=apple'):
        status, _, body = call(url, key, op)
        print(f'{op.split("op=")[1][:22]:22} {status}  {redact(body)[:90]}')

    # The batch endpoint twice, to prove the cache is serving the second call.
    for attempt in (1, 2):
        status, headers, body = call(
            url, key, 'op=quotes&symbols=AAPL,MSFT,NKE'
        )
        cache = headers.get('x-cache') or headers.get('X-Cache') or '-'
        got = 0
        try:
            got = sum(1 for v in json.loads(body)['quotes'].values() if v)
        except Exception:  # noqa: BLE001
            pass
        print(f'quotes (call {attempt})  {status}  X-Cache={cache}  '
              f'{got}/3 symbols priced')
        if attempt == 1:
            time.sleep(1)

    print()
    print('X-Cache on the second call should read 3/3 -- HIT from this')
    print('isolate, or HIT-DB from the shared table. 0/3 twice means the')
    print('cache is not working and the board must not poll at 2s.')


if __name__ == '__main__':
    main()
