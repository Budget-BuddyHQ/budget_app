import 'dart:convert';
import 'dart:io';

Map<String, dynamic>? _cachedJsonEnv;

String? readRuntimeEnv(String key) {
  final envValue = Platform.environment[key];
  final normalizedEnv = _normalize(envValue);
  if (normalizedEnv != null) {
    return normalizedEnv;
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
