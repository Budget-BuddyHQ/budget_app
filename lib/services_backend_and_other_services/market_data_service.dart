import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/runtime_env.dart';

/// A real-world stock quote from Finnhub.
@immutable
class LiveQuote {
  const LiveQuote({
    required this.symbol,
    required this.company,
    required this.current,
    required this.change,
    required this.percentChange,
    required this.high,
    required this.low,
    required this.open,
    required this.previousClose,
    required this.fetchedAt,
  });

  final String symbol;
  final String company;
  final double current;
  final double change;
  final double percentChange;
  final double high;
  final double low;
  final double open;
  final double previousClose;
  final DateTime fetchedAt;

  bool get isUp => change >= 0;

  /// Finnhub returns all-zero payloads for unknown symbols rather than a 404.
  bool get isValid => current > 0;

  /// A tiny **chronological** fallback shape for an inline sparkline, built
  /// from numbers the quote endpoint already returns — no extra API calls.
  ///
  /// Deliberately only the three points whose order in time is known:
  /// yesterday's close → today's open → the current price. An earlier version
  /// also spliced in [low] and [high], which made every stock render the exact
  /// same silhouette (low is always the minimum and high always the maximum, so
  /// the line always dipped to the floor then spiked to the ceiling). Real
  /// intraday shape comes from [MarketDataService.seriesFor].
  List<double> get miniSeries => [previousClose, open, current];
}

/// One hit from Finnhub's symbol-search endpoint.
///
/// This is what makes the Trade tab's search work like Webull's: the player
/// types any ticker or company name and gets real matches from the whole US
/// market, not just the handful of symbols hard-coded in [kLiveSymbols].
@immutable
class SymbolMatch {
  const SymbolMatch({required this.symbol, required this.company});

  final String symbol;
  final String company;
}

/// One OHLC bar. [Candle] is what both the line chart and the candlestick
/// chart draw from — a line just uses [close].
@immutable
class Candle {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  bool get isUp => close >= open;

  bool get isValid =>
      open.isFinite &&
      high.isFinite &&
      low.isFinite &&
      close.isFinite &&
      close > 0;
}

/// Chart timeframes, mirroring the row of range buttons in a real broker app.
enum ChartRange {
  day1('1D', '5min', 78),
  day5('5D', '30min', 65),
  month1('1M', '1day', 30),
  month3('3M', '1day', 90),
  year1('1Y', '1week', 52);

  const ChartRange(this.label, this.interval, this.points);

  final String label;

  /// Twelve Data `interval` parameter.
  final String interval;

  /// How many bars to request.
  final int points;
}

/// Which real-world tickers the Market Board can trade.
///
/// [common] ones are shown by default (household names a teenager already
/// recognises); the rest only surface once the player searches for them —
/// same idea as Webull's "most common stocks, then search reveals more."
@immutable
class LiveSymbol {
  const LiveSymbol(this.symbol, this.company, {this.common = false});

  final String symbol;
  final String company;
  final bool common;
}

const List<LiveSymbol> kLiveSymbols = <LiveSymbol>[
  LiveSymbol('AAPL', 'Apple', common: true),
  LiveSymbol('MSFT', 'Microsoft', common: true),
  LiveSymbol('NKE', 'Nike', common: true),
  LiveSymbol('SBUX', 'Starbucks', common: true),
  LiveSymbol('DIS', 'Disney', common: true),
  LiveSymbol('SPY', 'S&P 500 Fund', common: true),
  LiveSymbol('AMZN', 'Amazon'),
  LiveSymbol('GOOGL', 'Alphabet'),
  LiveSymbol('TSLA', 'Tesla'),
  LiveSymbol('NFLX', 'Netflix'),
  LiveSymbol('NVDA', 'Nvidia'),
  LiveSymbol('META', 'Meta'),
  LiveSymbol('KO', 'Coca-Cola'),
  LiveSymbol('MCD', "McDonald's"),
  LiveSymbol('PYPL', 'PayPal'),
  LiveSymbol('AMD', 'AMD'),
];

/// How many in-game coins one US dollar of share price is worth.
///
/// Real quotes come back in dollars; the Market Board trades in coins. Keeping
/// coins distinct from dollars (rather than the old 1:1) makes it read as game
/// currency — a $337 share costs ~3,370 coins — and is why buying *fractions*
/// of a share matters: a few thousand coins is a slice of one pricey share.
const int kCoinsPerDollar = 10;

/// Converts a real-world dollar price into coins.
int coinsForUsd(double usd) => (usd * kCoinsPerDollar).round();

/// Converts in-game coins back to the real-world dollar amount they track.
double usdForCoins(num coins) => coins / kCoinsPerDollar;

/// Formats a coin amount as the real money it represents, e.g. `$338.20`.
String usdLabel(num coins) {
  final usd = usdForCoins(coins);
  if (usd.abs() >= 100000) {
    return '\$${(usd / 1000).toStringAsFixed(1)}k';
  }
  return '\$${usd.toStringAsFixed(2)}';
}

/// Formats a coin amount with a thousands separator, e.g. `3,382g`.
String coinLabel(num coins) {
  final whole = coins.round();
  final digits = whole.abs().toString();
  final buffer = StringBuffer(whole < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  buffer.write('g');
  return buffer.toString();
}

/// Formats a (possibly fractional) share count without a trailing `.0`:
/// `2` → "2", `0.5` → "0.5", `1.25` → "1.25".
String formatShares(num shares) {
  final value = shares.toDouble();
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

/// Why live data is unavailable, so the UI can explain rather than just fail.
enum LiveMarketStatus {
  /// Never attempted yet.
  idle,

  /// Request in flight.
  loading,

  /// Real quotes available.
  ready,

  /// No FINNHUB_API_KEY configured. This is a normal, supported state —
  /// the app is fully playable without one.
  noApiKey,

  /// Network failure, timeout, or Finnhub returned an error.
  unavailable,
}

/// Fetches real market quotes from Finnhub — this is now the data source the
/// Market Board trades against directly (see stock_market_page.dart).
///
/// Still optional by design: a teammate can clone the repo and run it with
/// zero setup. When no key is present the service reports
/// [LiveMarketStatus.noApiKey] and the Market Board shows a message asking
/// for one instead of a trade list — the rest of the app is unaffected.
class MarketDataService extends ChangeNotifier {
  MarketDataService({http.Client? client}) : _client = client ?? http.Client();

  static const String _host = 'finnhub.io';
  static const Duration _timeout = Duration(seconds: 8);

  /// Finnhub's free tier allows 60 calls/minute and one refresh costs one call
  /// per tracked symbol. A 20s floor lets the board poll live (~3 refreshes a
  /// minute) while staying well inside the limit.
  static const Duration _minRefreshInterval = Duration(seconds: 20);

  /// How often the Market Board re-polls quotes while it is open.
  static const Duration livePollInterval = Duration(seconds: 30);

  final http.Client _client;

  final Map<String, LiveQuote> _quotes = <String, LiveQuote>{};

  /// Real intraday closes per symbol, powering the inline card sparklines.
  /// Without this the cards can only draw the 3-point quote fallback, which
  /// carries almost no shape.
  final Map<String, List<double>> _series = <String, List<double>>{};
  DateTime? _lastSeriesFetch;

  LiveMarketStatus _status = LiveMarketStatus.idle;
  DateTime? _lastFetch;
  String? _errorDetail;

  LiveMarketStatus get status => _status;
  String? get errorDetail => _errorDetail;
  DateTime? get lastFetch => _lastFetch;

  List<LiveQuote> get quotes => kLiveSymbols
      .map((entry) => _quotes[entry.symbol])
      .whereType<LiveQuote>()
      .toList(growable: false);

  /// Any cached quote, including one pulled in by a search rather than by the
  /// scheduled [refresh] of [kLiveSymbols].
  LiveQuote? quoteFor(String symbol) => _quotes[symbol];

  /// Real intraday closes for [symbol] (oldest first), or the quote-derived
  /// 3-point fallback when no candle key is configured or the fetch failed.
  List<double> seriesFor(String symbol) {
    final cached = _series[symbol];
    if (cached != null && cached.length >= 2) {
      return cached;
    }
    return _quotes[symbol]?.miniSeries ?? const <double>[];
  }

  /// True once at least one symbol has real intraday shape to draw.
  bool get hasIntradaySeries => _series.isNotEmpty;

  /// Fetches real intraday closes for [symbols] so the cards draw a true
  /// shape rather than a 3-point sketch.
  ///
  /// Twelve Data's free tier allows 8 requests/minute, so this is throttled and
  /// deliberately fetches only the handful of symbols actually on screen.
  Future<void> refreshSeries(
    List<String> symbols, {
    bool force = false,
  }) async {
    if (_candleApiKey == null || symbols.isEmpty) {
      return;
    }
    final last = _lastSeriesFetch;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 5)) {
      return;
    }
    _lastSeriesFetch = DateTime.now();

    var changed = false;
    // Cap the batch so a long watchlist can't trip the per-minute limit.
    for (final symbol in symbols.take(8)) {
      final candles = await fetchCandles(symbol, ChartRange.day1);
      if (candles.length >= 2) {
        _series[symbol] = candles
            .map((c) => c.close)
            .toList(growable: false);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool get hasApiKey => _apiKey != null;

  String? get _apiKey {
    final raw = readRuntimeEnv('FINNHUB_API_KEY');
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    // The .example ships a placeholder; treat any placeholder-looking value
    // as "not configured" so a half-filled env file behaves like no key.
    if (trimmed.isEmpty ||
        trimmed.toUpperCase().contains('OPTIONAL') ||
        trimmed.toUpperCase().contains('YOUR_')) {
      return null;
    }
    return trimmed;
  }

  /// Fetches quotes for every symbol in [kLiveSymbols].
  ///
  /// Respects [_minRefreshInterval] unless [force] is set. Never throws — all
  /// failures land in [status] so the caller can render an explanation.
  Future<void> refresh({bool force = false}) async {
    final key = _apiKey;
    if (key == null) {
      _status = LiveMarketStatus.noApiKey;
      notifyListeners();
      return;
    }

    final last = _lastFetch;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minRefreshInterval) {
      return;
    }

    _status = LiveMarketStatus.loading;
    _errorDetail = null;
    notifyListeners();

    try {
      // Sequential rather than parallel: the free tier throttles by request
      // rate, and six quick sequential calls stay comfortably inside it while
      // a burst of six can trip a 429.
      final fetched = <String, LiveQuote>{};
      for (final entry in kLiveSymbols) {
        final quote = await _fetchQuote(entry, key);
        if (quote != null) {
          fetched[entry.symbol] = quote;
        }
      }

      if (fetched.isEmpty) {
        _status = LiveMarketStatus.unavailable;
        _errorDetail ??= 'No quotes returned.';
      } else {
        _quotes
          ..clear()
          ..addAll(fetched);
        _lastFetch = DateTime.now();
        _status = LiveMarketStatus.ready;
      }
    } catch (error) {
      _status = LiveMarketStatus.unavailable;
      _errorDetail = '$error';
      debugPrint('Finnhub refresh failed: $error');
    }

    notifyListeners();
  }

  Future<LiveQuote?> _fetchQuote(LiveSymbol entry, String apiKey) async {
    // Token goes in a header, not the query string, so the key does not end up
    // in proxy or crash logs.
    final uri = Uri.https(_host, '/api/v1/quote', {'symbol': entry.symbol});

    try {
      final response = await _client
          .get(uri, headers: {'X-Finnhub-Token': apiKey})
          .timeout(_timeout);

      if (response.statusCode == 429) {
        _errorDetail = 'Rate limited by Finnhub. Try again in a minute.';
        return null;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        _errorDetail = 'Finnhub rejected the API key.';
        return null;
      }
      if (response.statusCode != 200) {
        _errorDetail = 'Finnhub returned HTTP ${response.statusCode}.';
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }

      final quote = LiveQuote(
        symbol: entry.symbol,
        company: entry.company,
        current: _readDouble(decoded['c']),
        change: _readDouble(decoded['d']),
        percentChange: _readDouble(decoded['dp']),
        high: _readDouble(decoded['h']),
        low: _readDouble(decoded['l']),
        open: _readDouble(decoded['o']),
        previousClose: _readDouble(decoded['pc']),
        fetchedAt: DateTime.now(),
      );

      return quote.isValid ? quote : null;
    } on TimeoutException {
      _errorDetail = 'Finnhub request timed out.';
      return null;
    } catch (error) {
      _errorDetail = '$error';
      return null;
    }
  }

  /// Searches the whole US market for [query].
  ///
  /// Finnhub's `/search` is free, unlike its historical-candle endpoint. This
  /// is what lets the Trade tab find WDC, Vanguard funds, or anything else
  /// that is not one of the pre-listed [kLiveSymbols]. Never throws — a
  /// failure just yields no matches.
  Future<List<SymbolMatch>> searchSymbols(String query) async {
    final key = _apiKey;
    final trimmed = query.trim();
    if (key == null || trimmed.isEmpty) {
      return const <SymbolMatch>[];
    }

    final uri = Uri.https(_host, '/api/v1/search', {
      'q': trimmed,
      'exchange': 'US',
    });

    try {
      final response = await _client
          .get(uri, headers: {'X-Finnhub-Token': key})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return const <SymbolMatch>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const <SymbolMatch>[];
      }
      final result = decoded['result'];
      if (result is! List) {
        return const <SymbolMatch>[];
      }

      final matches = <SymbolMatch>[];
      final seen = <String>{};
      for (final entry in result) {
        if (entry is! Map) {
          continue;
        }
        final symbol = (entry['symbol'] ?? '').toString().trim();
        final description = (entry['description'] ?? '').toString().trim();
        // Skip options, warrants, and foreign listings — their symbols carry
        // dots or dashes and cannot be quoted on the free tier anyway.
        if (symbol.isEmpty ||
            description.isEmpty ||
            symbol.contains('.') ||
            symbol.contains(':') ||
            !seen.add(symbol)) {
          continue;
        }
        matches.add(
          SymbolMatch(symbol: symbol, company: _titleCase(description)),
        );
        if (matches.length >= 20) {
          break;
        }
      }
      return matches;
    } catch (_) {
      return const <SymbolMatch>[];
    }
  }

  /// Fetches (and caches) a quote for a symbol that is not in [kLiveSymbols],
  /// so a searched-for stock becomes tradeable.
  Future<LiveQuote?> fetchQuoteFor(String symbol, {String? company}) async {
    final key = _apiKey;
    if (key == null) {
      return null;
    }
    final quote = await _fetchQuote(
      LiveSymbol(symbol, company ?? symbol),
      key,
    );
    if (quote != null) {
      _quotes[symbol] = quote;
      notifyListeners();
    }
    return quote;
  }

  /// True once a historical-data key is configured. Finnhub moved its
  /// `/stock/candle` endpoint behind a paid plan, so timeframes and
  /// candlestick bars come from Twelve Data's free tier instead.
  bool get hasCandleKey => _candleApiKey != null;

  String? get _candleApiKey {
    final raw = readRuntimeEnv('TWELVE_DATA_API_KEY');
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.toUpperCase().contains('OPTIONAL') ||
        trimmed.toUpperCase().contains('YOUR_')) {
      return null;
    }
    return trimmed;
  }

  /// Historical OHLC bars for [symbol] over [range].
  ///
  /// Returns an empty list when no key is configured or the request fails —
  /// the chart then falls back to the quote-derived mini series so the trade
  /// screen still renders something real.
  Future<List<Candle>> fetchCandles(String symbol, ChartRange range) async {
    final key = _candleApiKey;
    if (key == null) {
      return const <Candle>[];
    }

    final uri = Uri.https('api.twelvedata.com', '/time_series', {
      'symbol': symbol,
      'interval': range.interval,
      'outputsize': '${range.points}',
      'apikey': key,
    });

    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return const <Candle>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const <Candle>[];
      }
      // Twelve Data reports errors in-band with HTTP 200.
      if ((decoded['status'] ?? '').toString() == 'error') {
        debugPrint('Twelve Data error: ${decoded['message']}');
        return const <Candle>[];
      }
      final values = decoded['values'];
      if (values is! List) {
        return const <Candle>[];
      }

      final candles = <Candle>[];
      for (final entry in values) {
        if (entry is! Map) {
          continue;
        }
        final time = DateTime.tryParse((entry['datetime'] ?? '').toString());
        if (time == null) {
          continue;
        }
        final candle = Candle(
          time: time,
          open: _readDouble(entry['open']),
          high: _readDouble(entry['high']),
          low: _readDouble(entry['low']),
          close: _readDouble(entry['close']),
        );
        if (candle.isValid) {
          candles.add(candle);
        }
      }

      // Twelve Data returns newest-first; charts read left-to-right in time.
      return candles.reversed.toList(growable: false);
    } catch (error) {
      debugPrint('Candle fetch failed: $error');
      return const <Candle>[];
    }
  }

  /// Finnhub returns descriptions in caps ("WESTERN DIGITAL CORP"), which
  /// reads as shouting next to the rest of the UI.
  static String _titleCase(String input) {
    return input
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
