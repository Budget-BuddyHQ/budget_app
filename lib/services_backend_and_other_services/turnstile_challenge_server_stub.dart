class TurnstileChallengeServer {
  /// See the io implementation. Never called here — there is no server.
  void Function(String detail)? onStatus;

  Future<Uri> start({required String html}) async {
    throw UnsupportedError('Local Turnstile server is not available.');
  }

  Future<String?> requestToken({required String html}) async {
    throw UnsupportedError('Local Turnstile server is not available.');
  }

  Future<Uri> startTokenRequest({required String html}) async {
    throw UnsupportedError('Local Turnstile server is not available.');
  }

  Future<String?> waitForToken() async {
    throw UnsupportedError('Local Turnstile server is not available.');
  }

  Future<void> stop() async {}
}
