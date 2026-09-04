import 'dart:convert';
import 'dart:io';

import 'public_supabase_config.dart';
import 'runtime_env_defines.dart';

Map<String, dynamic>? _cachedJsonEnv;

/// Looks a key up across every source, most-specific first.
///
/// Order matters. An environment variable beats a `--dart-define`, which beats
/// a stale `supabase.env.json` sitting in a checkout, which beats the
/// committed public defaults. The defaults are deliberately **last**: they are
/// what makes a plain `flutter build` produce a working app, and being last
/// means any of the other three can still point a build at a different
/// project without touching them.
///
/// Only `SUPABASE_URL` and `SUPABASE_ANON_KEY` have defaults — see
/// `public_supabase_config.dart` for why those two are safe to commit and
/// why the market API keys are not.
String? readRuntimeEnv(String key) {
  final envValue = Platform.environment[key];
  final normalizedEnv = _normalize(envValue);
  if (normalizedEnv != null) {
    return normalizedEnv;
  }

  // The only source that survives into an installed app — see
  // runtime_env_defines.dart for why the other two do not.
  final defineValue = dartDefineFor(key);
  if (defineValue != null) {
    return defineValue;
  }

  final jsonValue = _jsonEnv[key];
  if (jsonValue is String) {
    final normalized = _normalize(jsonValue);
    if (normalized != null) return normalized;
  }

  return _normalize(kPublicSupabaseConfig[key]);
}

Map<String, dynamic> get _jsonEnv {
  if (_cachedJsonEnv != null) {
    return _cachedJsonEnv!;
  }

  try {
    final file = File('supabase.env.json');
    if (!file.existsSync()) {
      _cachedJsonEnv = <String, dynamic>{};
      return _cachedJsonEnv!;
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, dynamic>) {
      _cachedJsonEnv = decoded;
      return _cachedJsonEnv!;
    }
    if (decoded is Map) {
      _cachedJsonEnv = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return _cachedJsonEnv!;
    }
  } catch (_) {
    // Keep fallback silent so release builds can still rely on dart-defines.
  }

  _cachedJsonEnv = <String, dynamic>{};
  return _cachedJsonEnv!;
}

String? _normalize(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
