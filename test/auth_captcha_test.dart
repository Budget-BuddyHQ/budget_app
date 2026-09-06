import 'dart:io';

import 'package:budget_app/config/turnstile_config.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sign-in captcha, and the placeholder user id.
///
/// **Why these are worth a test file.** Both were found in a device log rather
/// than by anything in the suite, and one of them meant *nobody could sign in
/// on any platform*:
///
/// * The Turnstile widget was rendered with `size: 'invisible'`. Cloudflare
///   removed that value — invisible is a property of the widget in their
///   dashboard now — so `turnstile.render()` threw, no callback ever fired,
///   and the app answered every attempt with "Still checking" forever.
/// * Signed out, the app queries Supabase with the local placeholder id
///   `user_123`. The friendship columns reference `auth.users` and are
///   `uuid`, so that is not an empty result but a 22P02 syntax error, fired
///   on every cold start.
void main() {
  group('the Turnstile challenge HTML', () {
    // Read from the auth screen's own source. The HTML is a const string in
    // Dart, so a widget test cannot see inside the WebView -- but the values
    // Cloudflare rejects are right there in the file, and those are what
    // broke.
    late final String source = _authScreenSource();

    test('does not use a size Cloudflare rejects', () {
      // The exact string that took sign-in down. Cloudflare's error was:
      //   Invalid value for parameter "size", expected "compact",
      //   "flexible", or "normal", got "invisible"
      expect(
        source.contains("size: 'invisible'"),
        isFalse,
        reason:
            'size: invisible makes turnstile.render() throw, so no token '
            'is ever produced and every sign-in is blocked',
      );
    });

    test('uses one of the three sizes Cloudflare accepts', () {
      final match = RegExp(r"size: '(\w+)'").firstMatch(source);
      expect(match, isNotNull, reason: 'no size parameter at all');
      expect(const <String>[
        'compact',
        'flexible',
        'normal',
      ], contains(match!.group(1)));
    });

    test('reports a render failure instead of failing silently', () {
      // The bug hid for as long as it did because the exception happened
      // inside a WebView positioned off-screen, where nothing could surface
      // it. The JS now posts failures back to Dart.
      expect(source.contains('StatusChannel'), isTrue);
      expect(
        source.contains("StatusChannel.postMessage('render-failed"),
        isTrue,
        reason: 'a render exception has to reach Dart',
      );
    });

    test('the widget is not hidden off-screen any more', () {
      // It used to be inside an IgnorePointer, translated -10000,-10000.
      // Harmless while the widget completed itself; fatal the moment
      // Cloudflare started rendering a real, interactive one.
      expect(
        source.contains('Offset(-10000, -10000)'),
        isFalse,
        reason: 'a challenge nobody can see or tap cannot be completed',
      );
    });

    test('a site key is configured', () {
      expect(turnstileSiteKey.trim(), isNotEmpty);
      expect(turnstileSiteKey, startsWith('0x'));
    });
  });

  group('the placeholder user id never reaches Postgres', () {
    test('the local stand-in is rejected', () {
      // `UserStatsController` starts every session as this, so it is what
      // gets passed to every query before somebody signs in.
      expect(SupabaseService.isRealUserId('user_123'), isFalse);
    });

    test('empty and null are rejected', () {
      expect(SupabaseService.isRealUserId(null), isFalse);
      expect(SupabaseService.isRealUserId(''), isFalse);
      expect(SupabaseService.isRealUserId('   '), isFalse);
    });

    test('a real auth uuid is accepted', () {
      expect(
        SupabaseService.isRealUserId('3f8a1c2e-9b4d-4a17-8e55-1d2c3b4a5f60'),
        isTrue,
      );
      // Case should not matter -- Postgres does not care.
      expect(
        SupabaseService.isRealUserId('3F8A1C2E-9B4D-4A17-8E55-1D2C3B4A5F60'),
        isTrue,
      );
    });

    test('things that merely look like ids are rejected', () {
      // A partial uuid is the interesting case: the friend *code* is the
      // first eight characters of one, and passing a code where an id is
      // expected would be the same 22P02 in a different disguise.
      for (final bad in const <String>[
        '3f8a1c2e',
        '3f8a1c2e-9b4d-4a17-8e55',
        'not-a-uuid-at-all-really-no',
        '3f8a1c2e_9b4d_4a17_8e55_1d2c3b4a5f60',
      ]) {
        expect(
          SupabaseService.isRealUserId(bad),
          isFalse,
          reason: '"$bad" would be a 22P02 at the database',
        );
      }
    });
  });
}

/// The auth screen's source with comments stripped.
///
/// Comments have to go, and the first version of this file proved why: it
/// failed on the explanatory comment that *describes* the bug it is guarding
/// against. A test that cannot tell code from prose about code will either be
/// wrong or force the explanation out of the file, and the explanation is the
/// more valuable of the two.
String _authScreenSource() {
  const path = 'lib/screens_minigames_admin_etc/auth/auth_screen.dart';
  final lines = File(path).readAsLinesSync();
  return lines.where((line) => !line.trimLeft().startsWith('//')).join('\n');
}
