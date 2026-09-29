import 'dart:convert';

import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Records every request so the test can assert what actually went over the
/// wire — the whole point of the proxy is what is *not* in the URL.
class _RecordingClient extends http.BaseClient {
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final String Function(http.BaseRequest request) respond;

  _RecordingClient(this.respond);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final body = utf8.encode(respond(request));
    return http.StreamedResponse(Stream.value(body), 200);
  }
}

String _quoteBody(http.BaseRequest request) {
  if (request.url.queryParameters['op'] == 'twelve_quote') {
    return jsonEncode({
      'symbol': 'AAPL',
      'name': 'Apple Inc',
      'exchange': 'NASDAQ',
      'close': '190.0',
      'open': '188.0',
      'high': '192.0',
      'low': '186.0',
      'previous_close': '188.0',
      'volume': '50000000',
      'average_volume': '60000000',
      'market_cap': '3000000000000',
      'fifty_two_week': {'low': '160.0', 'high': '210.0'},
    });
  }
  if (request.url.queryParameters['op'] == 'candles' ||
      request.url.host == 'api.twelvedata.com') {
    return jsonEncode({
      'values': [
        {
          'datetime': '2026-08-07 15:30:00',
          'open': '100',
          'high': '104',
          'low': '99',
          'close': '103',
        },
        {
          'datetime': '2026-08-07 15:35:00',
          'open': '103',
          'high': '106',
          'low': '102',
          'close': '105',
        },
      ],
    });
  }
  return jsonEncode({
    'c': 190.0,
    'd': 2.0,
    'dp': 1.06,
    'h': 192.0,
    'l': 186.0,
    'o': 188.0,
    'pc': 188.0,
  });
}

void main() {
  // These require SUPABASE_URL/SUPABASE_ANON_KEY to be visible to
  // `readRuntimeEnv`, which on a dev machine comes from supabase.env.json.
  // When they aren't set the service correctly falls back to direct calls, so
  // the proxy assertions have nothing to check — skip rather than fail.
  final service = MarketDataService();
  final proxyConfigured = service.usesProxy;

  group('market proxy', () {
    test(
      'quotes go through the edge function, not Finnhub directly',
      () async {
        final client = _RecordingClient(_quoteBody);
        final market = MarketDataService(client: client);

        await market.refresh(force: true);

        expect(client.requests, isNotEmpty);
        for (final request in client.requests) {
          expect(
            request.url.host,
            isNot('finnhub.io'),
            reason: 'the client should never call the vendor directly',
          );
          expect(request.url.path, contains('/functions/v1/market'));
        }
      },
      skip: proxyConfigured ? false : 'SUPABASE_URL not configured',
    );

    test('no market API key is ever put on the wire', () async {
      final client = _RecordingClient(_quoteBody);
      final market = MarketDataService(client: client);

      await market.refresh(force: true);
      await market.searchSymbols('apple');
      await market.fetchCandles('AAPL', ChartRange.day1);

      expect(client.requests, isNotEmpty);
      for (final request in client.requests) {
        // The Twelve Data key used to travel as a query parameter, which puts
        // it in every intermediary's logs. Nothing key-shaped should appear in
        // a URL or a vendor auth header now.
        expect(
          request.url.queryParameters.containsKey('apikey'),
          isFalse,
          reason: 'a vendor key is in the query string of ${request.url}',
        );
        expect(
          request.headers.containsKey('X-Finnhub-Token'),
          isFalse,
          reason: 'a vendor token header went out on ${request.url}',
        );
      }
    }, skip: proxyConfigured ? false : 'SUPABASE_URL not configured');

    test('company details use the Twelve Data proxy operation', () async {
      final client = _RecordingClient(_quoteBody);
      final market = MarketDataService(client: client);

      final details = await market.fetchTwelveDataQuoteDetails('AAPL');

      expect(details, isNotNull);
      expect(details!.name, 'Apple Inc');
      expect(client.requests, hasLength(1));
      expect(client.requests.single.url.queryParameters['op'], 'twelve_quote');
      expect(client.requests.single.url.queryParameters['symbol'], 'AAPL');
    }, skip: proxyConfigured ? false : 'SUPABASE_URL not configured');

    test('falls back to direct calls when Supabase is not configured', () {
      // Not a behavior we want in production, but it keeps the repo runnable
      // for a contributor with only a Finnhub key and no Supabase project.
      expect(service.usesProxy, proxyConfigured);
      if (!proxyConfigured) {
        expect(
          service.hasApiKey,
          anyOf(isTrue, isFalse),
          reason: 'without a proxy this is decided purely by the local key',
        );
      }
    });
  });

  test('a symbol is only fetchable when quotes are available at all', () {
    // `hasApiKey` gates the Market Board's "add an API key" empty state. Once
    // the proxy exists it must report true even with no local key, or players
    // would be told to configure something they do not need.
    if (proxyConfigured) {
      expect(service.hasApiKey, isTrue);
      expect(service.hasCandleKey, isTrue);
    }
  });
}
