import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against a specific class of failure that has already happened
/// once: a fix landing correctly, then silently disappearing because it was
/// never committed (or a git operation reverted it) before anyone noticed.
/// These are all one-line-of-evidence checks against the actual source
/// files, not the app's runtime behavior, on purpose -- they need to catch
/// the file being wrong, not just the app misbehaving in a way nobody is
/// looking at yet.
void main() {
  group('the release manifest can actually reach the network', () {
    test('AndroidManifest.xml declares the INTERNET permission', () {
      // Missing this produces `SocketException: Failed host lookup ...
      // errno = 7` in every release build -- and *only* in a release build,
      // because Flutter's debug-only manifest grants it for `flutter run`.
      // That gap between "works for every developer" and "works for zero
      // real users" is exactly why this needs a test instead of relying on
      // someone noticing by hand again.
      final manifest = File('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue);
      expect(
        manifest.readAsStringSync(),
        contains('android.permission.INTERNET'),
        reason:
            'Without this, every network call (Supabase, Finnhub, Twelve '
            'Data, Turnstile) fails at the OS level in a release build, '
            'silently, for every real user.',
      );
    });
  });

  group('web sign-in has a real security-check path', () {
    late String authScreen;
    setUpAll(() {
      authScreen = File(
        'lib/screens_minigames_admin_etc/auth/auth_screen.dart',
      ).readAsStringSync();
    });

    test('the Cloudflare Turnstile widget is wired up for kIsWeb', () {
      // `_supportsEmbeddedWebView` returns false for kIsWeb by design (web
      // doesn't use webview_flutter), which means without a dedicated web
      // branch, `_hasEmbeddedChallenge` is false on every browser and
      // sign-in/sign-up is permanently unreachable there -- "Security check
      // unavailable" for every web visitor, forever, not a flaky failure.
      expect(authScreen, contains('CloudFlareTurnstile'));
      expect(authScreen, contains('kIsWeb && _isTurnstileConfigured'));
    });

    test('the web Turnstile widget has a stable key', () {
      // It sits after the confirm-password field and terms card, which only
      // exist in Sign Up mode -- so it changes list position when the user
      // toggles Log In <-> Sign Up. Without a key, Flutter can't tell it's
      // the same widget that moved rather than a new one, and tears the
      // whole challenge down and rebuilds it (dropping any in-progress
      // token) on every single toggle.
      expect(authScreen, contains("ValueKey('web_turnstile')"));
    });
  });

  group('the privacy policy link is not the dead placeholder copy', () {
    test('kPrivacyPolicyUrl is not a supabase.co functions URL', () {
      final constants = File(
        'lib/constants/privacy_policy.dart',
      ).readAsStringSync();
      // The Supabase pages function still serves a copy of this policy for
      // the password-reset landing page's own footer link, but that copy's
      // contact address was still the unfilled placeholder. This is a
      // narrower re-check of what privacy_policy_test.dart already covers,
      // kept here too because this whole file is about catching regressions
      // in one place after they have already happened once for real.
      expect(constants, isNot(contains("supabase.co/functions/v1/pages")));
    });
  });
}
