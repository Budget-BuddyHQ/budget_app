# -*- coding: utf-8 -*-
"""Build the Supabase auth email templates.

**Where these go.** Supabase Dashboard -> Authentication -> Emails ->
Templates. Each file this writes is pasted into the "Message body" of the
matching template. They are not bundled with the app and nothing imports
them -- the emails are sent by Supabase's servers, not by us, which is
exactly why they looked like nobody had touched them: the default template is
a bare `<h2>` and a naked link on a white page, and it goes out to the same
child the rest of the app is careful with.

**Why the HTML looks like it is from 2004.** Because email is. Every rule
below is a real constraint, not a style choice:

* **Tables for layout.** Outlook renders through Word's engine, which has no
  flexbox and no grid, and float support that gives up on nested elements.
  Tables are the only layout primitive every client agrees on.
* **Inline styles only.** Gmail strips `<style>` blocks in several contexts,
  including forwarded mail and its own mobile apps. A stylesheet that vanishes
  takes the whole design with it.
* **No external images.** Most clients block remote images by default until
  the reader clicks "show images", so a logo-as-image design arrives as a
  broken box. The mark here is drawn with a table cell and a text character,
  which cannot fail to load.
* **A bulletproof button.** A styled `<a>` with padding is a link that happens
  to look like a button; Outlook collapses its padding and it arrives as blue
  underlined text. Wrapping it in its own single-cell table is the standard
  workaround and the reason the markup is heavier than it looks like it needs
  to be.
* **Web-safe fonts.** Custom faces are stripped or ignored almost everywhere.
  The stack degrades to something reasonable rather than pretending.
* **A dark-on-light body.** The app is a dark forest theme and the temptation
  is to carry that over, but a dark email is a real risk: several clients
  force their own background, and dark-mode inversion in Gmail and Outlook
  mangles hand-set dark palettes far more often than light ones. The header
  band carries the brand; the part somebody has to read stays legible.

**The plain-text fallback matters more than usual here.** A password reset is
exactly the mail that gets opened on a locked-down work client or a watch, and
a link that is only reachable through HTML is a support ticket.

Run:  python tool/build_auth_emails.py
"""
from __future__ import annotations

import os

OUT = os.path.join('docs', 'auth_emails')

# The app's own palette, from `AppTheme`.
FOREST = '#0F2E20'
PANEL = '#264F3D'
MINT = '#4BD2A3'
MINT_DEEP = '#0F2E20'
INK = '#16241D'
INK_SOFT = '#4C6157'
RULE = '#DCE6E1'
PAPER = '#FFFFFF'
GROUND = '#EEF3F0'

PRIVACY = 'https://budget-buddyhq.github.io/budget_app/privacy-policy.html'


def shell(title: str, heading: str, lede: str, button: str, body: str,
          footer_note: str) -> str:
    """One template.

    `{{ .ConfirmationURL }}` is Supabase's own placeholder and is substituted
    server-side, so it has to survive into the output verbatim.
    """
    return f'''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{title}</title>
</head>
<body style="margin:0; padding:0; background:{GROUND}; -webkit-font-smoothing:antialiased;">

<!-- Preheader: the grey line the inbox shows next to the subject. Hidden in
     the message itself, and the run of non-breaking spaces after it stops
     clients pulling body copy in behind it. -->
<div style="display:none; font-size:1px; color:{GROUND}; line-height:1px; max-height:0; max-width:0; opacity:0; overflow:hidden;">
{lede}&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;
</div>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:{GROUND};">
<tr>
<td align="center" style="padding:28px 12px 40px 12px;">

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px; width:100%; background:{PAPER}; border-radius:14px; overflow:hidden; border:1px solid {RULE};">

    <!-- Header band -->
    <tr>
      <td style="background:{FOREST}; padding:26px 30px 24px 30px;">
        <table role="presentation" cellpadding="0" cellspacing="0" border="0">
        <tr>
          <td width="38" style="width:38px; padding-right:12px;">
            <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="38" style="width:38px; height:38px; background:{MINT}; border-radius:10px;">
            <tr><td align="center" valign="middle" style="height:38px; font-family:Georgia,'Times New Roman',serif; font-size:20px; font-weight:bold; color:{MINT_DEEP}; line-height:38px;">B</td></tr>
            </table>
          </td>
          <td valign="middle" style="font-family:Georgia,'Times New Roman',serif; font-size:19px; font-weight:bold; color:#FFFFFF; letter-spacing:.2px;">
            Budget&nbsp;Buddy
          </td>
        </tr>
        </table>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:32px 30px 8px 30px; font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;">
        <h1 style="margin:0 0 12px 0; font-family:Georgia,'Times New Roman',serif; font-size:24px; line-height:1.25; color:{INK}; font-weight:bold;">{heading}</h1>
        <p style="margin:0 0 22px 0; font-size:16px; line-height:1.6; color:{INK_SOFT};">{lede}</p>
      </td>
    </tr>

    <!-- Bulletproof button -->
    <tr>
      <td style="padding:0 30px 26px 30px;">
        <table role="presentation" cellpadding="0" cellspacing="0" border="0">
        <tr>
          <td align="center" bgcolor="{MINT}" style="border-radius:10px;">
            <a href="{{{{ .ConfirmationURL }}}}"
               style="display:inline-block; padding:14px 30px; font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif; font-size:16px; font-weight:bold; color:{MINT_DEEP}; text-decoration:none; border-radius:10px;">{button}</a>
          </td>
        </tr>
        </table>
      </td>
    </tr>

    <!-- The link in full, because buttons do not always survive -->
    <tr>
      <td style="padding:0 30px 26px 30px; font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;">
        <p style="margin:0 0 6px 0; font-size:13px; line-height:1.5; color:{INK_SOFT};">If the button does not work, copy this into your browser:</p>
        <p style="margin:0; font-size:12px; line-height:1.5; word-break:break-all;">
          <a href="{{{{ .ConfirmationURL }}}}" style="color:{PANEL}; text-decoration:underline;">{{{{ .ConfirmationURL }}}}</a>
        </p>
      </td>
    </tr>

    <!-- What to do if this was not you -->
    <tr>
      <td style="padding:0 30px 30px 30px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:{GROUND}; border-radius:10px;">
        <tr>
          <td style="padding:14px 16px; font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif; font-size:13.5px; line-height:1.55; color:{INK_SOFT};">
            {body}
          </td>
        </tr>
        </table>
      </td>
    </tr>

    <!-- Footer -->
    <tr>
      <td style="padding:0 30px 28px 30px; border-top:1px solid {RULE};">
        <p style="margin:18px 0 0 0; font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif; font-size:12px; line-height:1.6; color:#7A8B83;">
          {footer_note}<br />
          Budget Buddy is a free financial-literacy game. We never ask for your
          password, and we will never ask you to pay for anything by email.<br />
          <a href="{PRIVACY}" style="color:#7A8B83; text-decoration:underline;">Privacy policy</a>
        </p>
      </td>
    </tr>

  </table>

</td>
</tr>
</table>

</body>
</html>
'''


TEMPLATES = {
    'reset_password': dict(
        title='Reset your Budget Buddy password',
        heading='Reset your password',
        lede='Someone asked to reset the password for this Budget Buddy '
             'account. If it was you, use the button below — the link works '
             'once and expires in an hour.',
        button='Choose a new password',
        body='<strong style="color:#16241D;">If this was not you</strong>, you '
             'can ignore this email and nothing will change. Your password '
             'stays as it is until somebody opens this link.',
        footer_note='You are getting this because someone entered this '
                    'address on the Budget Buddy sign-in screen.',
    ),
    'confirm_signup': dict(
        title='Confirm your Budget Buddy account',
        heading='One tap and you are in',
        lede='Welcome to Budget Buddy. Confirm this address and your account '
             'is ready — your level, coins and saved games all live on it.',
        button='Confirm my account',
        body='<strong style="color:#16241D;">Did not sign up?</strong> Ignore '
             'this email. The account is not created until somebody opens '
             'this link, so nothing happens if you do nothing.',
        footer_note='You are getting this because this address was used to '
                    'sign up for Budget Buddy.',
    ),
    'magic_link': dict(
        title='Your Budget Buddy sign-in link',
        heading='Here is your way in',
        lede='Use the button below to sign in. The link works once and '
             'expires in an hour, so it is no use to anyone afterwards.',
        button='Sign me in',
        body='<strong style="color:#16241D;">If you did not ask for this</strong>, '
             'ignore it — nobody can get into your account without opening '
             'this link from your inbox.',
        footer_note='You are getting this because someone asked for a sign-in '
                    'link for this address.',
    ),
    'change_email': dict(
        title='Confirm your new Budget Buddy email',
        heading='Confirm your new address',
        lede='You asked to change the email on your Budget Buddy account to '
             'this one. Confirm it and the change takes effect.',
        button='Confirm this address',
        body='<strong style="color:#16241D;">Not expecting this?</strong> '
             'Ignore this email and the address on the account stays exactly '
             'as it was.',
        footer_note='You are getting this because this address was entered as '
                    'a new email on a Budget Buddy account.',
    ),
}


PLAIN = {
    'reset_password':
        'Reset your Budget Buddy password\n\n'
        'Someone asked to reset the password for this account. If it was you,\n'
        'open this link — it works once and expires in an hour:\n\n'
        '{{ .ConfirmationURL }}\n\n'
        'If this was not you, ignore this email. Nothing changes until\n'
        'somebody opens the link.\n\n'
        'Budget Buddy will never ask you for your password.\n',
}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, fields in TEMPLATES.items():
        path = os.path.join(OUT, f'{name}.html')
        with open(path, 'w', encoding='utf8') as handle:
            handle.write(shell(**fields))
        print(f'{path}  ({os.path.getsize(path) // 1024 or 1}KB)')

    for name, text in PLAIN.items():
        path = os.path.join(OUT, f'{name}.txt')
        with open(path, 'w', encoding='utf8') as handle:
            handle.write(text)
        print(f'{path}')


if __name__ == '__main__':
    main()
