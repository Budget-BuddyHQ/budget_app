# -*- coding: utf-8 -*-
"""Bake the two public web pages into a Supabase edge function.

WHY THIS EXISTS
---------------
`docs/password-reset.html` and `docs/privacy-policy.html` were served from
GitHub Pages at `budget-buddyhq.github.io/budget_app/...`. Both URLs return
**404**, and they always will: the repository is private, and GitHub Pages
does not serve private repositories on a free plan. Nothing about that is
visible from inside the app, which is why it survived — the constants are
right, the page HTML is right, and the failure only appears in an email
somebody opens on a phone.

Two things were broken by it, and the second one is worse than the first:

  1. Password reset. The emailed link lands on a dead page ("This site can't
     be reached"), so nobody who forgets their password can get back in.
  2. The privacy policy URL. Google Play **requires** a reachable privacy
     policy for any app that collects user data. A 404 there is a store
     rejection, not a cosmetic bug.

WHY AN EDGE FUNCTION RATHER THAN A HOST
---------------------------------------
The options were: make the repo public, pay for Pages, add a Netlify/Vercel
account, or use something already working. The project already deploys
Supabase edge functions (`market`), so this needs no new account, no new
credentials, no change to the repository's visibility, and one command the
user has already run successfully.

It also puts the landing page on the **same origin as the auth server**,
which removes a whole class of redirect-allow-list mistakes: the page the
reset link returns to is now a sibling of the endpoint that issued it.

The HTML is embedded rather than fetched so the function has no runtime
dependency on anything — it cannot 404 because a bucket was renamed.

USAGE
-----
    python tool/build_pages_function.py
    supabase functions deploy pages --no-verify-jwt

`--no-verify-jwt` is required. Without it Supabase demands an Authorization
header, and a person clicking a link in an email does not have one — the page
would answer 401, which looks exactly like the bug this replaces.
"""
import io
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'supabase', 'functions', 'pages', 'index.ts')

PROJECT_URL = 'https://cwqjduingvevagrxbwts.supabase.co'
BASE = PROJECT_URL + '/functions/v1/pages'

PAGES = [
    ('password-reset', os.path.join(ROOT, 'docs', 'password-reset.html')),
    ('privacy-policy', os.path.join(ROOT, 'docs', 'privacy-policy.html')),
]


def embed(html):
    """Make an HTML string safe inside a TypeScript template literal.

    Only three sequences can end or escape a template literal: a backslash, a
    backtick, and `${`. Escaping more than that would corrupt the page.
    """
    html = html.replace('\\', '\\\\')
    html = html.replace('`', '\\`')
    html = html.replace('${', '\\${')
    return html


def logo_data_uri():
    """The real app logo, resized and base64'd for inlining.

    Generated from `assets/images/logo.png` at build time rather than pasted
    in as a blob, so the page cannot drift from the app's actual mark. The
    full file is 429x316 and 94KB; a reset page does not need that, and an
    edge function carrying 125KB of base64 per page is a deploy nobody wants
    to debug. 144px wide is 2x the display size, which is the retina case.

    An external <img src> would be simpler and is exactly what must not
    happen here: it would put an image host in the path of the one flow whose
    failure mode is "nobody can get back into their account", and email
    clients block remote images by default anyway.
    """
    try:
        from PIL import Image
    except ImportError:
        print('  WARNING: Pillow not installed, pages will have no logo')
        return None

    import base64
    src = os.path.join(ROOT, 'assets', 'images', 'logo.png')
    if not os.path.isfile(src):
        print('  WARNING: %s missing, pages will have no logo' % src)
        return None

    im = Image.open(src).convert('RGBA')
    width = 144
    im = im.resize((width, round(im.height * width / im.width)),
                   Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, 'PNG', optimize=True)
    encoded = base64.b64encode(buf.getvalue()).decode('ascii')
    print('  logo embedded    %6d bytes (base64)' % len(encoded))
    return 'data:image/png;base64,' + encoded


def brand(html, uri):
    """Swap the text-only badge for the real mark.

    The pages already carried a `<p class="badge">Budget Buddy</p>` — a
    wordmark in a pill. Replacing rather than adding, because two brand
    elements stacked is worse than either alone.
    """
    if uri is None:
        return html

    logo = (
        '<p class="badge">'
        '<img src="%s" alt="" width="72" class="brand-logo">'
        '<span>Budget Buddy</span>'
        '</p>' % uri
    )
    # `alt=""` on purpose: the word "Budget Buddy" is right beside it in the
    # same element, so a screen reader announcing the image as well would
    # read the name twice.
    style = (
        '<style>'
        '.badge{display:inline-flex;align-items:center;gap:9px;}'
        '.brand-logo{display:block;height:auto;}'
        '</style>'
    )
    replaced = html.replace(
        '<p class="badge">Budget Buddy</p>', logo, 1)

    if replaced == html:
        # The privacy page has no badge — it opens straight into an <h1>.
        # Put the mark above the heading rather than inventing a badge, so
        # the two pages stay recognisably the same brand without forcing
        # them into the same layout.
        replaced = html.replace(
            '<main>',
            '<main>\n<p class="badge">'
            '<img src="%s" alt="" width="72" class="brand-logo"></p>' % uri,
            1)

    if replaced == html:
        print('  WARNING: nowhere to put the logo')
        return html
    return replaced.replace('</head>', style + '</head>', 1)


def absolutise(html):
    """Rewrite relative links, which do not survive the move.

    `docs/password-reset.html` links to `privacy-policy.html` as a sibling
    file. Under `/functions/v1/pages/password-reset` that resolves to
    `/functions/v1/privacy-policy` — a different function, and a 404. Served
    from a flat directory it was correct; served from a route it is not.
    """
    html = html.replace('href="privacy-policy.html"',
                        'href="%s/privacy-policy"' % BASE)
    html = html.replace('href="password-reset.html"',
                        'href="%s/password-reset"' % BASE)
    # The old dead host, wherever it is still named in the page chrome.
    html = re.sub(
        r'https://budget-buddyhq\.github\.io/budget_app/privacy-policy\.html',
        BASE + '/privacy-policy', html)
    html = re.sub(
        r'https://budget-buddyhq\.github\.io/budget_app/password-reset\.html',
        BASE + '/password-reset', html)
    return html


def main():
    uri = logo_data_uri()
    parts = []
    for name, path in PAGES:
        html = io.open(path, encoding='utf8').read()
        html = absolutise(html)
        html = brand(html, uri)
        const = name.replace('-', '_').upper()
        parts.append('const %s = `%s`;\n' % (const, embed(html)))
        print('  embedded %-16s %6d bytes' % (name, len(html)))

    body = '''// GENERATED BY tool/build_pages_function.py - DO NOT EDIT BY HAND.
//
// Serves Budget Buddy's two public web pages.
//
// These were on GitHub Pages and returned 404 on every request, because the
// repository is private and Pages does not serve private repos on a free
// plan. That broke password reset (the emailed link landed on "This site
// can't be reached") and left the Play Store privacy-policy URL dead, which
// is a store-listing requirement rather than a nicety.
//
// Deploy with:   supabase functions deploy pages --no-verify-jwt
//
// The --no-verify-jwt matters. A person clicking a link in an email carries
// no Authorization header, so without it every visit answers 401 and the
// symptom is identical to the 404 this replaced.

%s
const HTML_HEADERS = {
  "Content-Type": "text/html; charset=utf-8",
  // The reset link carries a single-use token in its query string. Telling
  // caches and crawlers to keep out of it is cheap and obviously correct.
  "Cache-Control": "no-store, max-age=0",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
};

function page(html: string): Response {
  return new Response(html, { status: 200, headers: HTML_HEADERS });
}

Deno.serve((req: Request): Response => {
  const url = new URL(req.url);

  // Match on the last non-empty path segment rather than the whole path.
  // Supabase has changed how much of the prefix reaches the function before,
  // and a route that depends on the exact prefix is a route that breaks
  // silently on a platform update - in a flow whose failure mode is "nobody
  // can get back into their account".
  const segments = url.pathname.split("/").filter((s) => s.length > 0);
  const leaf = segments.length > 0 ? segments[segments.length - 1] : "";

  switch (leaf) {
    case "privacy-policy":
    case "privacy":
      return page(PRIVACY_POLICY);

    case "password-reset":
    case "reset":
      return page(PASSWORD_RESET);

    // The bare function root is deliberately the reset page, not a 404.
    //
    // Supabase substitutes the project's Site URL whenever redirect_to is
    // not on the allow-list, and it does that silently. If the Site URL is
    // set to this function's root, a dashboard mistake that used to produce
    // a dead link now produces the correct page instead. The whole reason
    // this file exists is that a misconfiguration was indistinguishable from
    // a broken app, so the root answers usefully on purpose.
    default:
      return page(PASSWORD_RESET);
  }
});
''' % ('\n'.join(parts))

    outdir = os.path.dirname(OUT)
    if not os.path.isdir(outdir):
        os.makedirs(outdir)
    io.open(OUT, 'w', encoding='utf8', newline='\n').write(body)
    print('wrote %s (%d bytes)' % (OUT, len(body)))
    print()
    print('Deploy with:')
    print('  supabase functions deploy pages --no-verify-jwt')
    print()
    print('Then in the Supabase dashboard, Authentication > URL Configuration:')
    print('  Site URL              %s/password-reset' % BASE)
    print('  Redirect allow-list   %s/password-reset' % BASE)
    print('                        budgetbuddy://password-reset')


if __name__ == '__main__':
    main()
