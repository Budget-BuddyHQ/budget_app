import 'runtime_env_defines.dart';

/// Web build. There is no `Platform.environment` and no filesystem to read
/// `supabase.env.json` from, so `--dart-define` is the only source — which
/// is the same reason it is the only one that works on a phone.
String? readRuntimeEnv(String key) => dartDefineFor(key);
