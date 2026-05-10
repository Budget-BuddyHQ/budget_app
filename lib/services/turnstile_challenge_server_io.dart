import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TurnstileChallengeServer {
  HttpServer? _server;
  String? _html;
  Uri? _entryUri;
  Completer<String?>? _tokenCompleter;

  Future<Uri> start({required String html}) async {
    _html = html;

    if (_server != null && _entryUri != null) {
      return _entryUri!;
    }

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(_server!.forEach(_handleRequest));

    _entryUri = Uri(
      scheme: 'http',
      host: 'localhost',
      port: _server!.port,
      path: '/',
    );

    return _entryUri!;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _html = null;
    _entryUri = null;
    if (!(_tokenCompleter?.isCompleted ?? true)) {
      _tokenCompleter?.complete(null);
    }
    _tokenCompleter = null;
    await server?.close(force: true);
  }

  Future<String?> requestToken({required String html}) async {
    await startTokenRequest(html: html);
    return waitForToken();
  }

  Future<Uri> startTokenRequest({required String html}) async {
    _tokenCompleter = Completer<String?>();
    return start(html: html);
  }

  Future<String?> waitForToken() async {
    final tokenCompleter = _tokenCompleter;
    if (tokenCompleter == null) {
      return null;
    }

    return tokenCompleter.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/token') {
      final token = await utf8.decoder.bind(request).join();
      if (!(_tokenCompleter?.isCompleted ?? true)) {
        _tokenCompleter?.complete(token.trim().isEmpty ? null : token.trim());
      }
      request.response
        ..headers.contentType = ContentType.html
        ..write('Security check complete. You can return to Budget Buddy.');
      await request.response.close();
      return;
    }

    if (request.uri.path != '/' && request.uri.path != '/index.html') {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.text
        ..write('Not found');
      await request.response.close();
      return;
    }

    request.response
      ..headers.contentType = ContentType.html
      ..headers.add('Cache-Control', 'no-store')
      ..write(_html ?? '');
    await request.response.close();
  }
}
