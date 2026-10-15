// Browser audio for the web build, and nothing anywhere else.
//
// See `web_audio_web.dart` for why the web build does not go through
// `audioplayers` for sound.
export 'web_audio_stub.dart' if (dart.library.js_interop) 'web_audio_web.dart';
