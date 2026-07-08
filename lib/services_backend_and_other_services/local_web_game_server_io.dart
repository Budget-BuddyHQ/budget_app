import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../constants/app_assets.dart';

class LocalWebGameServer {
  HttpServer? _server;
  Uri? _entryUri;
  final Map<String, String> _assetLookup = <String, String>{};

  Uri? get entryUri => _entryUri;

  Future<Uri> start({
    String assetRoot = AppAssets.webGameRoot,
    Map<String, String> queryParameters = const <String, String>{},
  }) async {
    if (_server != null && _entryUri != null) {
      return _entryUri!.replace(queryParameters: queryParameters);
    }

    await _loadAssetManifest(assetRoot);

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(_server!.forEach(_handleRequest));

    _entryUri = Uri(
      scheme: 'http',
      host: _server!.address.address,
      port: _server!.port,
      path: '/index.html',
    );

    return _entryUri!.replace(queryParameters: queryParameters);
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _entryUri = null;
    _assetLookup.clear();
    await server?.close(force: true);
  }

  Future<void> _loadAssetManifest(String assetRoot) async {
    if (_assetLookup.isNotEmpty) {
      return;
    }

    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifestJson = jsonDecode(manifestRaw);
    final manifest = manifestJson is Map<String, dynamic>
        ? manifestJson
        : <String, dynamic>{};

    for (final assetPath in manifest.keys) {
      if (!assetPath.startsWith(assetRoot)) {
        continue;
      }

      final relativePath = assetPath.substring(assetRoot.length);
      _assetLookup['/$relativePath'] = assetPath;
    }

    _assetLookup.putIfAbsent('/index.html', () => '${assetRoot}index.html');
    _assetLookup.putIfAbsent('/', () => '${assetRoot}index.html');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final normalizedPath = request.uri.path == '/'
        ? '/index.html'
        : request.uri.path;
    final assetPath = _assetLookup[normalizedPath];

    if (assetPath == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.html
        ..write('Missing asset for $normalizedPath');
      await request.response.close();
      return;
    }

    try {
      final assetData = await rootBundle.load(assetPath);
      final contentType = _contentTypeFor(assetPath);

      request.response
        ..headers.contentType = contentType
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..add(assetData.buffer.asUint8List());
    } catch (error) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.text
        ..write('Failed to load $assetPath: $error');
    } finally {
      await request.response.close();
    }
  }

  ContentType _contentTypeFor(String assetPath) {
    final lowerPath = assetPath.toLowerCase();
    if (lowerPath.endsWith('.html')) {
      return ContentType.html;
    }
    if (lowerPath.endsWith('.js') || lowerPath.endsWith('.mjs')) {
      return ContentType('application', 'javascript', charset: 'utf-8');
    }
    if (lowerPath.endsWith('.css')) {
      return ContentType('text', 'css', charset: 'utf-8');
    }
    if (lowerPath.endsWith('.json')) {
      return ContentType.json;
    }
    if (lowerPath.endsWith('.svg')) {
      return ContentType('image', 'svg+xml');
    }
    if (lowerPath.endsWith('.png')) {
      return ContentType('image', 'png');
    }
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return ContentType('image', 'jpeg');
    }
    return ContentType('application', 'octet-stream');
  }
}
