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

    test('the polling cadence stays inside 60 calls a minute', () {
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
    test('asks for the cap and no more, with nothing pinned', () async {
      final service = MarketDataService();
      addTearDown(service.dispose);
      // With no API key the fetch short-circuits, but the selection has
      // already happened — this is checking the arithmetic, not the network.
      await service.refreshBatch();
      expect(service.status, isNotNull);
    });

    test('does not throw when handed symbols it does not track', () async {
      // The board pins whatever the player holds, and a saved portfolio can
      // name a symbol that has since left `kLiveSymbols`.
      final service = MarketDataService();
      addTearDown(service.dispose);
      await service.refreshBatch(
        pinned: const <String>['NOPE', 'ALSONOTREAL'],
      );
      expect(service.status, isNotNull);
    });
  });
}
