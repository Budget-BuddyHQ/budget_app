import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

/// The password-reset link has to survive four files agreeing with each other.
///
/// **The bug this exists because of.** The reset email arrived pointing at
/// `http://localhost:3000` and tapping it on a phone said "This site can't be
/// reached". Every line of Dart involved was correct — the redirect constant,
/// the Android intent-filter, the recovery-session branch in `main.dart`. The
/// fault was one empty field in a web dashboard, and the reason it was so hard
/// to see is that Supabase does not fail loudly when `redirect_to` is not
/// allow-listed. It **substitutes the Site URL**, and a new project's Site URL
/// is that localhost placeholder.
///
/// So the failure mode is: a correct app, a silent substitution, and a symptom
/// that looks like broken code. Nothing in a compiler connects a Dart constant
/// to a TOML file to an XML manifest to a page of JavaScript, and this is that
/// connection. Change one side and this fails, instead of the reset flow dying
/// quietly for everybody who forgot their password.
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// The TOML with its `#` comment lines removed.
  ///
  /// The comments in `config.toml` deliberately quote the two strings this
  /// file bans — the `localhost:3000` placeholder, because explaining the bug
  /// means naming it, and a `re_your_key_here` example in the `supabase
  /// secrets set` line. Scanning raw text flagged both, which would have made
  /// the only sane way to document the fix a test failure.
  String settingsOnly(String path) => read(path)
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n');

  group('the reset link is the same URL everywhere', () {
    test('the app sends people to an https page, not a custom scheme', () {
      // Not cosmetic. A 302 from Supabase directly to `budgetbuddy://` is
      // refused by several in-app browsers (Gmail's WebView especially),
      // which reproduces the dead link on a perfectly configured project.
      expect(passwordResetRedirectUrl, startsWith('https://'));
      expect(passwordResetRedirectUrl, passwordResetLandingUrl);
      expect(
        passwordResetRedirectUrl,
        isNot(contains('localhost')),
        reason: 'the mobile reset link points at a dev server again',
      );
    });

    test('the landing page is served by something that exists', () {
      // This test used to assert that the last path segment of the URL was a
      // real file in docs/, on the theory that GitHub Pages published docs/
      // on main. Every part of that was true and the URL 404'd anyway: the
      // repository is private, and Pages does not serve private repositories
      // on a free plan. "The file is in the repo" and "the file is being
      // served" are different claims, and only the first was being checked.
      //
      // The page is now baked into a Supabase edge function, so the check
      // that is actually worth making is that the function exists and its
      // route matches the constant.
      final leaf = Uri.parse(passwordResetLandingUrl).pathSegments.last;
      final fn = File('supabase/functions/pages/index.ts');
      expect(
        fn.existsSync(),
        isTrue,
        reason: 'the pages edge function is missing — run '
            'tool/build_pages_function.py',
      );
      expect(
        fn.readAsStringSync(),
        contains('case "$leaf":'),
        reason:
            'passwordResetLandingUrl ends in /$leaf, but the pages function '
            'has no route for it — the reset link will 404',
      );
    });

    test('the baked copy has not drifted from the source page', () {
      // The function embeds the HTML rather than fetching it, so editing
      // docs/password-reset.html and forgetting to regenerate would leave
      // the deployed page silently stale. Nothing else would catch that.
      final source = read('docs/password-reset.html');
      final baked = read('supabase/functions/pages/index.ts');
      final marker = source.contains('id="open"')
          ? 'id="open"'
          : passwordResetDeepLink;
      expect(
        baked,
        contains(marker),
        reason: 'supabase/functions/pages/index.ts is out of date — run '
            'python tool/build_pages_function.py',
      );
    });

    test('the embedded HTML cannot break out of its template literal', () {
      // The function holds both pages as TypeScript template literals. Three
      // sequences can end or escape one: a backslash, a backtick, and `${`.
      // Both pages already contain backticks in their comments, so this is
      // not hypothetical — if the generator's escaping regressed, the file
      // would stop parsing and the failure would land at *deploy* time, on
      // the server, in the one flow whose failure mode is "nobody can get
      // back into their account".
      //
      // Exactly four unescaped backticks: an opening and closing delimiter
      // for each of the two constants. Any other number means the HTML
      // terminated a literal early.
      final ts = read('supabase/functions/pages/index.ts');
      final unescaped = RegExp(r'(?<!\\)`').allMatches(ts).length;
      expect(
        unescaped,
        4,
        reason:
            'supabase/functions/pages/index.ts has $unescaped unescaped '
            'backticks, not 4 — an embedded page is breaking out of its '
            'template literal and the function will not parse',
      );
      expect(
        RegExp(r'(?<!\\)\$\{').allMatches(ts).length,
        0,
        reason: 'an embedded page contains an unescaped \${, which the '
            'runtime would try to interpolate',
      );
    });

    test('the reset page is not on a host that cannot serve it', () {
      // The specific mistake this replaced, pinned so it cannot come back.
      expect(
        passwordResetLandingUrl,
        isNot(contains('github.io')),
        reason:
            'GitHub Pages does not serve this repository — it is private, '
            'and a free plan does not publish private repos. This URL 404s.',
      );
    });

    test('the landing page forwards to the scheme the app registered', () {
      expect(
        read('docs/password-reset.html'),
        contains(passwordResetDeepLink),
        reason: 'the page no longer hands the reset payload to the app',
      );
    });

    test('Android claims that scheme', () {
      // Without the intent-filter the OS has no idea who owns budgetbuddy://
      // and the forward from the page does nothing at all.
      final uri = Uri.parse(passwordResetDeepLink);
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest,
        contains('android:scheme="${uri.scheme}"'),
        reason: 'the deep-link scheme is not declared in the manifest',
      );
      expect(manifest, contains('android:host="${uri.host}"'));
    });

    test('the Supabase config carries the same URLs', () {
      // The half that is not code, written down so it can be reviewed and
      // re-applied rather than remembered.
      final config = read('supabase/config.toml');
      expect(
        config,
        contains('site_url = "$passwordResetLandingUrl"'),
        reason:
            'site_url is the value Supabase falls back to when a redirect '
            'fails validation. If it is not this page, a bad allow-list '
            'produces a dead link again',
      );
      expect(
        config,
        contains('"$passwordResetDeepLink"'),
        reason: 'the app scheme is missing from additional_redirect_urls',
      );
      expect(
        settingsOnly('supabase/config.toml'),
        isNot(contains('localhost:3000')),
        reason: 'the placeholder Site URL is back',
      );
    });
  });

  group('the config file carries no secrets', () {
    test('the SMTP password is an env reference, never a literal', () {
      // Changing the "Supabase Auth" sender requires custom SMTP, which
      // requires a provider API key. This file is committed; that key must
      // only ever arrive through `supabase secrets set`.
      final config = settingsOnly('supabase/config.toml');
      for (final line in config.split('\n')) {
        final trimmed = line.trimLeft();
        if (!trimmed.startsWith('pass')) continue;
        expect(
          trimmed,
          contains('env('),
          reason: 'an SMTP credential is written literally into config.toml',
        );
      }
      // The obvious provider key prefixes, in case one is pasted somewhere
      // other than a `pass =` line.
      for (final prefix in const <String>['re_', 'SG.', 'xkeysib-']) {
        expect(
          config,
          isNot(contains(prefix)),
          reason: 'what looks like an API key ($prefix…) is in config.toml',
        );
      }
    });
  });
}
