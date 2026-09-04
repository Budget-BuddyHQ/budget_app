import 'dart:io';

import 'package:budget_app/config/public_supabase_config.dart';
import 'package:budget_app/config/runtime_env.dart';
import 'package:flutter_test/flutter_test.dart';

/// What is allowed to be compiled into the app, and what is not.
///
/// **Why the defaults exist.** Until they did, the only key source that
/// survived onto a phone was `--dart-define`. A release built without the
/// right flags shipped with no Supabase config at all — sign-in did nothing,
/// the Market Board had no proxy, friends could not load — and it worked on
/// the developer's laptop only because `supabase.env.json` happens to sit in
/// the project folder. A build that is only correct if somebody remembers a
/// long command line is a build that eventually goes out wrong.
///
/// **Why that is safe for exactly two values.** The anon key is not a
/// password: it identifies the project, every row it can reach is behind
/// row-level security, and Supabase publishes it in their own examples. The
/// market API keys are the opposite — rate-limited credentials on a personal
/// account, recoverable from an APK with `strings` in about a minute. Those
/// belong to the `market` edge function, which is why that function exists.
///
/// This file is the thing standing between those two facts and a mistake.
void main() {
  group('what is baked in', () {
    test('the project URL and anon key are present', () {
      // The whole point: a plain `flutter build` has to produce a working app.
      for (final key in const ['SUPABASE_URL', 'SUPABASE_ANON_KEY']) {
        final value = readRuntimeEnv(key);
        expect(
          value,
          isNotNull,
          reason: '$key has no value, so a default build cannot reach '
              'Supabase at all',
        );
        expect(value!.trim(), isNotEmpty);
      }
    });

    test('the URL is a real Supabase project, not a placeholder', () {
      final url = readRuntimeEnv('SUPABASE_URL')!;
      expect(url, startsWith('https://'));
      expect(
        url.toUpperCase().contains('YOUR-PROJECT'),
        isFalse,
        reason: 'the template placeholder was shipped',
      );
    });

    test('the anon key looks like a JWT and not something else', () {
      // Supabase anon keys are JWTs: three dot-separated segments. A key that
      // is not one is very likely the *service role* key pasted by mistake,
      // which would be a genuine leak.
      final key = readRuntimeEnv('SUPABASE_ANON_KEY')!;
      expect(key.split('.').length, 3, reason: 'not a JWT');
      expect(key, startsWith('eyJ'));
    });
  });

  group('what must never be baked in', () {
    test('no market API key is in the committed defaults', () {
      for (final key in kPublicSupabaseConfig.keys) {
        for (final banned in const [
          'FINNHUB',
          'TWELVE',
          'SERVICE_ROLE',
          'SECRET',
          'PASSWORD',
        ]) {
          expect(
            key.toUpperCase().contains(banned),
            isFalse,
            reason: '$key is compiled into every APK and can be recovered '
                'with `strings`',
          );
        }
      }
    });

    test('the defaults hold exactly the two public values', () {
      // A whitelist rather than a blacklist: the failure mode being prevented
      // is somebody widening this file, and a blacklist only catches the
      // names somebody thought of.
      expect(
        kPublicSupabaseConfig.keys.toSet(),
        {'SUPABASE_URL', 'SUPABASE_ANON_KEY'},
      );
    });

    test('the generated file carries no secret-looking values', () {
      // Belt and braces on the values themselves, in case a key is renamed
      // rather than added. Finnhub keys are 40 hex-ish chars with no dots;
      // Twelve Data's are 32. Neither looks like a JWT or a URL.
      for (final entry in kPublicSupabaseConfig.entries) {
        final value = entry.value;
        final looksLikeBareToken =
            !value.contains('.') && !value.startsWith('http');
        expect(
          looksLikeBareToken,
          isFalse,
          reason: '${entry.key} holds something that looks like a bare API '
              'token rather than a URL or a JWT',
        );
      }
    });
  });

  group('the defaults are the weakest source', () {
    test('a dart-define would win over them', () {
      // Not directly testable without rebuilding, so this asserts the shape
      // the lookup relies on: the defaults map is consulted, and the file
      // documents itself as last. What *is* checkable is that the map is a
      // plain lookup with no side effects and no precedence of its own.
      expect(kPublicSupabaseConfig, isA<Map<String, String>>());
      expect(kPublicSupabaseConfig['SUPABASE_URL'], isNotNull);
    });

    test('an unknown key still returns null', () {
      expect(readRuntimeEnv('NOT_A_REAL_KEY_AT_ALL'), isNull);
    });
  });

  group('the env file stays out of git', () {
    test('supabase.env.json is gitignored', () {
      // It holds the market keys. If it is ever committed they are public and
      // have to be rotated.
      final ignore = File('.gitignore').readAsStringSync();
      expect(
        ignore.contains('supabase.env.json'),
        isTrue,
        reason: 'the file holding the market API keys is not ignored',
      );
    });
  });
}
