import 'public_supabase_config.dart';
import 'runtime_env_defines.dart';

/// Web build. There is no `Platform.environment` and no filesystem to read
/// `supabase.env.json` from, so a `--dart-define` and the committed public
/// defaults are the only two sources — which is the same reason those are the
/// only two that work on a phone.
///
/// The define wins, so a build can still be pointed at another project.
String? readRuntimeEnv(String key) {
  final define = dartDefineFor(key);
  if (define != null) return define;
  final fallback = kPublicSupabaseConfig[key]?.trim();
  return (fallback == null || fallback.isEmpty) ? null : fallback;
}
