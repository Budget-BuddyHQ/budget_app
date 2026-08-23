/// Compile-time keys, baked into the binary by `--dart-define`.
///
/// **This is the only key source that works on a real phone.** The other two
/// paths in `runtime_env_io.dart` both fail on a device:
///
///  * `Platform.environment` is effectively empty on Android/iOS — there is
///    no shell environment to inherit from.
///  * `File('supabase.env.json')` resolves against the process's working
///    directory. On a phone that is not your project folder, and the file is
///    not bundled with the app, so it never exists.
///
/// So a debug run from your laptop found the keys and an installed build did
/// not — which is why sign-in and the Market Board worked on desktop and
/// silently did nothing on device.
///
/// `String.fromEnvironment` requires a **const literal** key, so it cannot be
/// called with a runtime string. That is why every supported key has to be
/// listed here by hand rather than looked up dynamically. Adding a new key
/// means adding a line to this map.
library;

const Map<String, String> _dartDefines = <String, String>{
  'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
  'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
  'SUPABASE_PROFILE_IMAGE_BUCKET': String.fromEnvironment(
    'SUPABASE_PROFILE_IMAGE_BUCKET',
  ),
  'FINNHUB_API_KEY': String.fromEnvironment('FINNHUB_API_KEY'),
  'TWELVE_DATA_API_KEY': String.fromEnvironment('TWELVE_DATA_API_KEY'),
};

/// The `--dart-define` value for [key], or null when it was not supplied.
///
/// `String.fromEnvironment` defaults to an empty string rather than null when
/// a define is missing, so empty is normalised away here — otherwise an
/// unset key would read as a present-but-blank value and defeat the
/// fallbacks.
String? dartDefineFor(String key) {
  final value = _dartDefines[key];
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
