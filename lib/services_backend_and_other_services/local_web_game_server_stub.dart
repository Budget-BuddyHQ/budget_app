import '../constants/app_assets.dart';

class LocalWebGameServer {
  Uri? get entryUri => null;

  Future<Uri> start({
    String assetRoot = AppAssets.webGameRoot,
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    throw UnsupportedError(
      'A localhost asset server is not available on this platform.',
    );
  }

  Future<void> stop() async {}
}
