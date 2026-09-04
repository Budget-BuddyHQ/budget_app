import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Batched quote refresh, and the rate limit it has to stay inside.
///
/// **The problem this replaced.** Every tick refreshed all sixteen tracked
/// symbols, sequentially. Against Finnhub's free tier — 60 calls a minute —
/// that caps the whole board at one update per sixteen seconds, and almost
/// every one of those calls was spent on a price scrolled off the screen.
/// The board looked frozen because, for anything the player was actually
/// looking at, it very nearly was.
///
/// Now a tick fetches a small batch, weighted to the symbols the player holds
/// and rotating through the rest. That is only safe if the batch is capped —
/// a player with ten holdings would otherwise pin ten symbols into a
/// five-second tick and make 120 calls a minute. The arithmetic is the point
/// of this file, because getting it wrong means a 429 and a dead board rather
/// than anything visible in a test.
void main() {
  group('the rate budget', () {
    test('a batch never exceeds the cap, however much is pinned', () {
      // The failure being prevented: `{...pinned}` first and truncate second
      // reads as a cap and is not one.
      expect(MarketDataService.liveBatchSize, lessThanOrEqualTo(6));
    });

    test('the proxy cadence is fast enough to read as live', () {
      // The whole point of caching in the edge function: the board's poll
      // rate stops being the same constraint as Finnhub's call limit.
      expect(
        MarketDataService.proxyPollInterval.inSeconds,
        lessThanOrEqualTo(3),
        reason: 'behind a cache there is no reason to be slower than this',
      );
      expect(
        MarketDataService.proxyPollInterval.inSeconds,
        greaterThanOrEqualTo(1),
        reason: 'sub-second polling is battery cost with nothing to show '
            'for it — the cache only refreshes every 12s upstream',
      );
    });

    test('the direct cadence still respects the vendor limit', () {
      final ticksPerMinute =
          60 / MarketDataService.livePollInterval.inSeconds;
      final callsPerMinute =
          ticksPerMinute * MarketDataService.liveBatchSize;
      expect(
        callsPerMinute,
        lessThanOrEqualTo(52),
        reason:
            'the board alone would make ${callsPerMinute.round()} calls a '
            'minute, and candles and news share the same 60-call budget',
      );
    });

    test('every tracked symbol still comes round in reasonable time', () {
      // The trade-off of batching: something off screen updates less often.
      // It still has to update. Sixteen symbols, four a tick, five seconds a
      // tick is a full sweep every twenty seconds — the same freshness the
      // *whole* board used to have, now as the worst case rather than the
      // best.
      final sweepSeconds =
          (kLiveSymbols.length / MarketDataService.liveBatchSize).ceil() *
          MarketDataService.livePollInterval.inSeconds;
      expect(
        sweepSeconds,
        lessThanOrEqualTo(30),
        reason: 'a symbol can go ${sweepSeconds}s without an update',
      );
    });

    test('a watched symbol updates far more often than the sweep', () {
      // The whole point. A pinned symbol is in every batch, so it refreshes
      // at the tick rate rather than the sweep rate.
      final sweepSeconds =
          (kLiveSymbols.length / MarketDataService.liveBatchSize).ceil() *
          MarketDataService.livePollInterval.inSeconds;
      final watchedSeconds = MarketDataService.livePollInterval.inSeconds;
      expect(
        sweepSeconds / watchedSeconds,
        greaterThanOrEqualTo(4),
        reason: 'batching is not buying enough to be worth its complexity',
      );
    });
  });

  group('the batch itself', () {
    // `selectBatch` rather than `refreshBatch`: this is about which four
    // strings come out of a list, and the first version of these tests went
    // through the fetching path — so they made real HTTP requests, took
    // seconds each, and failed intermittently in a full run with "Proxy
    // request failed with 404".
    test('asks for exactly the cap with nothing pinned', () {
      final service = MarketDataService();
      addTearDown(service.dispose);
      expect(service.selectBatch().length, MarketDataService.liveBatchSize);
    });

    test('a big portfolio cannot blow the cap', () {
      // The rate-limit bug this guards: `{...pinned}` first and truncate
      // second reads as a cap and is not one. Ten holdings at a five-second
      // tick would be 120 calls a minute against a limit of 60.
      final service = MarketDataService();
      addTearDown(service.dispose);
      final everything = kLiveSymbols.map((s) => s.symbol).toList();
      expect(
        service.selectBatch(pinned: everything).length,
        MarketDataService.liveBatchSize,
      );
    });

    test('what the player holds comes first', () {
      final service = MarketDataService();
      addTearDown(service.dispose);
      final batch = service.selectBatch(pinned: const <String>['NKE']);
      expect(
        batch,
        contains('NKE'),
        reason: 'a held symbol was left out of the batch',
      );
    });

    test('symbols it does not track are ignored, not crashed on', () {
      // A saved portfolio can name a symbol that has since left the list.
      final service = MarketDataService();
      addTearDown(service.dispose);
      final batch = service.selectBatch(
        pinned: const <String>['NOPE', 'ALSONOTREAL'],
      );
      expect(batch, isNot(contains('NOPE')));
      expect(batch.length, MarketDataService.liveBatchSize);
    });

    test('successive batches move through the list', () {
      // Otherwise the same four refresh forever and the other twelve never
      // update at all.
      final service = MarketDataService();
      addTearDown(service.dispose);
      final first = service.selectBatch();
      final second = service.selectBatch();
      expect(
        first.intersection(second).length,
        lessThan(first.length),
        reason: 'the rotation is standing still',
      );
    });

    test('every symbol is reached within one sweep', () {
      final service = MarketDataService();
      addTearDown(service.dispose);
      final seen = <String>{};
      final sweeps =
          (kLiveSymbols.length / MarketDataService.liveBatchSize).ceil();
      for (var i = 0; i < sweeps; i++) {
        seen.addAll(service.selectBatch());
      }
      expect(
        seen.length,
        kLiveSymbols.length,
        reason: '${kLiveSymbols.length - seen.length} symbols never came up '
            'in a full sweep',
      );
    });
  });
}
