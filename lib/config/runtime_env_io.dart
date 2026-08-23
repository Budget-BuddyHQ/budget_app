import 'dart:convert';
import 'dart:io';

import 'runtime_env_defines.dart';

Map<String, dynamic>? _cachedJsonEnv;

/// Looks a key up across all three sources, most-specific first.
///
/// Order matters: `--dart-define` beats the local JSON file so a key baked
/// into a build always wins over a stale `supabase.env.json` sitting in a
/// checkout. The JSON file stays last as a developer convenience for
/// `flutter run` on desktop.
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
    return _normalize(jsonValue);
  }

  return null;
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
