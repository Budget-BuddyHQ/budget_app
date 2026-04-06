import 'dart:io';

String? readRuntimeEnv(String key) {
  final value = Platform.environment[key];
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
