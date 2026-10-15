/// Not a browser: phones and desktops play through `audioplayers`, so every
/// call here does nothing. See `web_audio_web.dart`.
class WebAudio {
  WebAudio._();

  static void init({
    required Map<String, String> effects,
    required String music,
    required double musicVolume,
  }) {}

  static void playEffect(String name, double volume) {}

  static void stopEffect(String name) {}

  static void startMusic() {}

  static void stopMusic() {}
}
