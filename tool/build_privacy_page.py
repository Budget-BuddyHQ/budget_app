# -*- coding: utf-8 -*-
"""Render docs/PRIVACY_POLICY.md into the page Google Play links to.

**Why generate it rather than keep two copies.** Play wants the policy at a
public URL, and the app wants it readable in-app; the store listing gets taken
down if that link rots or disagrees with what the app does. Two hand-written
copies of a legal document is exactly how they end up disagreeing, so the
Markdown is the source and this makes the page.

No Markdown library on purpose -- the document uses six constructs and pulling
a dependency into the build for that is worse than forty lines of parsing.

Run:  python tool/build_privacy_page.py
"""
from __future__ import annotations

import html
import io
import os
import re
import sys

SRC = os.path.join('docs', 'PRIVACY_POLICY.md')
OUT = os.path.join('docs', 'privacy-policy.html')

STYLE = """
:root {
  color-scheme: light dark;
  --bg: #ffffff; --ink: #1b2420; --muted: #5b6b64;
  --rule: #dfe7e3; --accent: #1d7a55; --card: #f4f8f6;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0f1714; --ink: #e8f2ed; --muted: #9db3aa;
    --rule: #24322c; --accent: #7fe0b0; --card: #16211c;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0; padding: 0 20px 80px;
  background: var(--bg); color: var(--ink);
  font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
        "Helvetica Neue", Arial, sans-serif;
  -webkit-text-size-adjust: 100%;
}
main { max-width: 720px; margin: 0 auto; }
h1 { font-size: 1.9rem; line-height: 1.2; margin: 44px 0 6px; }
h2 { font-size: 1.25rem; margin: 40px 0 10px; padding-top: 18px;
     border-top: 1px solid var(--rule); }
h3 { font-size: 1.02rem; margin: 26px 0 8px; color: var(--accent); }
p, li { color: var(--ink); }
strong { font-weight: 650; }
ul { padding-left: 22px; }
li { margin: 7px 0; }
hr { border: 0; border-top: 1px solid var(--rule); margin: 34px 0; }
blockquote {
  margin: 22px 0; padding: 14px 18px;
  background: var(--card); border-left: 3px solid var(--accent);
  border-radius: 0 8px 8px 0; color: var(--muted);
}
blockquote p { margin: 6px 0; }
table { border-collapse: collapse; width: 100%; margin: 18px 0; font-size: 15px; }
th, td { text-align: left; padding: 9px 10px; border-bottom: 1px solid var(--rule); }
th { color: var(--muted); font-weight: 600; }
code {
  background: var(--card); padding: 2px 6px; border-radius: 5px;
  font-size: 0.9em; font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
}
a { color: var(--accent); }
.updated { color: var(--muted); margin-top: 0; }
footer { margin-top: 56px; padding-top: 18px; border-top: 1px solid var(--rule);
         color: var(--muted); font-size: 14px; }
"""


def inline(text: str) -> str:
    """Escape, then put back the few inline marks the document uses."""
    out = html.escape(text)
    out = re.sub(r'`([^`]+)`', r'<code>\1</code>', out)
    out = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', out)
    out = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', out)
    return out


def convert(md: str) -> str:
    lines = md.split('\n')
    out: list[str] = []
    i = 0
    para: list[str] = []
    quote: list[str] = []

    def flush_para():
        if para:
            out.append(f'<p>{inline(" ".join(para))}</p>')
            para.clear()

    def flush_quote():
        if quote:
            body = ' '.join(quote)
            out.append(f'<blockquote><p>{inline(body)}</p></blockquote>')
            quote.clear()

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if stripped.startswith('>'):
            flush_para()
            quote.append(stripped.lstrip('> ').strip())
            i += 1
            continue
        flush_quote()

        if not stripped:
            flush_para()
            i += 1
            continue

        if stripped.startswith('#'):
            flush_para()
            level = len(stripped) - len(stripped.lstrip('#'))
            out.append(f'<h{level}>{inline(stripped[level:].strip())}</h{level}>')
            i += 1
            continue

        if stripped.startswith('---'):
            flush_para()
            out.append('<hr>')
            i += 1
            continue

        # A table: header row, separator, then body rows.
        if stripped.startswith('|') and i + 1 < len(lines) \
                and set(lines[i + 1].strip()) <= set('|-: '):
            flush_para()
            def cells(row: str) -> list[str]:
                return [c.strip() for c in row.strip().strip('|').split('|')]
            head = cells(stripped)
            out.append('<table><thead><tr>')
            out.extend(f'<th>{inline(c)}</th>' for c in head)
            out.append('</tr></thead><tbody>')
            i += 2
            while i < len(lines) and lines[i].strip().startswith('|'):
                out.append('<tr>')
                out.extend(f'<td>{inline(c)}</td>' for c in cells(lines[i]))
                out.append('</tr>')
                i += 1
            out.append('</tbody></table>')
            continue

        if stripped.startswith('* '):
            flush_para()
            out.append('<ul>')
            while i < len(lines):
                item = lines[i].strip()
                if item.startswith('* '):
                    body = [item[2:].strip()]
                    i += 1
                    # Continuation lines are indented and not a new bullet.
                    while i < len(lines) and lines[i].startswith('  ') \
                            and lines[i].strip() and not lines[i].strip().startswith('* '):
                        body.append(lines[i].strip())
                        i += 1
                    out.append(f'<li>{inline(" ".join(body))}</li>')
                else:
                    break
            out.append('</ul>')
            continue

        para.append(stripped)
        i += 1

    flush_para()
    flush_quote()
    return '\n'.join(out)


def main() -> None:
    if not os.path.exists(SRC):
        sys.exit(f'{SRC} is missing')
    md = io.open(SRC, encoding='utf8').read()

    # The page has to carry the same version string the app compares against.
    match = re.search(r'\*\*Last updated:\s*([^*]+)\*\*', md)
    updated = match.group(1).strip() if match else 'unknown'

    body = convert(md)
    page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Budget Buddy — Privacy Policy</title>
<meta name="description" content="How the Budget Buddy financial-literacy app
handles your data. No ads, no analytics, no tracking.">
<!-- Generated by tool/build_privacy_page.py from docs/PRIVACY_POLICY.md.
     Edit the Markdown, not this file. -->
<style>{STYLE}</style>
</head>
<body>
<main>
{body}
<footer>
Budget Buddy · Privacy policy last updated {html.escape(updated)}.<br>
This page is generated from
<code>docs/PRIVACY_POLICY.md</code> in the app's own repository.
</footer>
</main>
</body>
</html>
"""
    io.open(OUT, 'w', encoding='utf8').write(page)
    size = os.path.getsize(OUT)
    print(f'{OUT}  ({size // 1024}KB, policy dated {updated})')


if __name__ == '__main__':
    main()
