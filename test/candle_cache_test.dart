import 'dart:convert';

import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Two bars of plausible Twelve Data `/time_series` output.
String _body() => jsonEncode({
  'status': 'ok',
  'values': [
    {
      'datetime': '2026-08-24 15:30:00',
      'open': '100',
      'high': '104',
      'low': '99',
      'close': '103',
    },
    {
      'datetime': '2026-08-24 15:25:00',
      'open': '98',
      'high': '101',
      'low': '97',
      'close': '100',
    },
  ],
});

void main() {
  group('candle caching', () {
    test('a repeated range is served from cache, not the network', () {
      // The behavior that matters: tapping 1D, then 5D, then back to 1D
      // used to be three network round trips against a free tier that
      // allows eight requests a minute.
      return _withCountingClient((service, calls) async {
        final first = await service.fetchCandles('AAPL', ChartRange.day1);
        expect(first, isNotEmpty);
        expect(calls.value, 1);

        await service.fetchCandles('AAPL', ChartRange.day1);
        expect(
          calls.value,
          1,
          reason: 'the second identical request hit the network again',
        );
      });
    });

    test('a different range is a different cache entry', () {
      return _withCountingClient((service, calls) async {
        await service.fetchCandles('AAPL', ChartRange.day1);
        await service.fetchCandles('AAPL', ChartRange.month1);
        expect(
          calls.value,
          2,
          reason: '1D and 1M are different series and must both be fetched',
        );
      });
    });

    test('a different symbol is a different cache entry', () {
      return _withCountingClient((service, calls) async {
        await service.fetchCandles('AAPL', ChartRange.day1);
        await service.fetchCandles('MSFT', ChartRange.day1);
        expect(calls.value, 2);
      });
    });

    test('concurrent requests for the same series share one call', () {
      // Two widgets asking at the same moment (chart + preview) should not
      // race each other into two identical requests.
      return _withCountingClient((service, calls) async {
        final results = await Future.wait([
          service.fetchCandles('AAPL', ChartRange.day1),
          service.fetchCandles('AAPL', ChartRange.day1),
          service.fetchCandles('AAPL', ChartRange.day1),
        ]);
        expect(calls.value, 1, reason: 'in-flight sharing did not kick in');
        for (final r in results) {
          expect(r, isNotEmpty);
        }
      });
    });

    test('a failed fetch is not cached', () {
      // Caching an empty result would pin a transient outage in place for
      // the whole TTL, so a retry could never recover.
      var fail = true;
      final calls = _Counter();
      final service = MarketDataService(
        client: MockClient((request) async {
          calls.value++;
          if (fail) return http.Response('nope', 500);
          return http.Response(_body(), 200);
        }),
      );
      addTearDown(service.dispose);

      return () async {
        final bad = await service.fetchCandles('AAPL', ChartRange.day1);
        expect(bad, isEmpty);
        expect(calls.value, 1);

        fail = false;
        final good = await service.fetchCandles('AAPL', ChartRange.day1);
        expect(
          good,
          isNotEmpty,
          reason: 'the empty failure result got cached and blocked a retry',
        );
        expect(calls.value, 2);
      }();
    });
  });
}

class _Counter {
  int value = 0;
}

Future<void> _withCountingClient(
  Future<void> Function(MarketDataService service, _Counter calls) body,
) async {
  final calls = _Counter();
  final service = MarketDataService(
    client: MockClient((request) async {
      calls.value++;
      return http.Response(_body(), 200);
    }),
  );
  try {
    await body(service, calls);
  } finally {
    service.dispose();
  }
}
