import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/runtime_env.dart';
import '../utils/number_format.dart';

// real stock quote from finnhub
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

  // finnhub sends all-zero payloads for bad symbols instead of a 404
  bool get isValid => current > 0;

  // quick fallback sparkline shape, no extra api call. only 3 points that
  // are actually in chronological order (close, open, now). used to also
  // throw in low/high but that made every stock look identical (dip then
  // spike). real shape comes from MarketDataService.seriesFor
  List<double> get miniSeries => [previousClose, open, current];
}

// one hit from finnhub's symbol search. lets the trade tab search work
// like a real broker app instead of just the hardcoded symbol list
@immutable
class SymbolMatch {
  const SymbolMatch({required this.symbol, required this.company});

  final String symbol;
  final String company;
}

// extra metadata from twelve data's /quote endpoint, for the company
// info dropdown on the stock card
@immutable
class TwelveDataQuoteDetails {
  const TwelveDataQuoteDetails({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.price,
    required this.open,
    required this.high,
    required this.low,
    required this.previousClose,
    required this.bidSize,
    required this.askSize,
    required this.volume,
    required this.averageVolume,
    required this.marketCap,
    required this.fiftyTwoWeekLow,
    required this.fiftyTwoWeekHigh,
  });

  final String symbol;
  final String name;
  final String exchange;
  final double price;
  final double open;
  final double high;
  final double low;
  final double previousClose;
  final double bidSize;
  final double askSize;
  final double volume;
  final double averageVolume;
  final double marketCap;
  final double fiftyTwoWeekLow;
  final double fiftyTwoWeekHigh;

  String get fiftyTwoWeekRange =>
      '${_formatLargeNumber(fiftyTwoWeekLow)} – ${_formatLargeNumber(fiftyTwoWeekHigh)}';

  static String _formatLargeNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return '-';
    }
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    }
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}M';
    }
    if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

// company background from finnhub's /stock/profile2, the About section
@immutable
class CompanyProfile {
  const CompanyProfile({
    required this.symbol,
    required this.name,
    required this.industry,
    required this.description,
    required this.logoUrl,
    required this.website,
    required this.exchange,
    required this.country,
    required this.marketCapitalization,
    required this.ipoDate,
  });

  final String symbol;
  final String name;
  final String industry;
  // finnhubs free profile2 endpoint doesnt actually give you a long
  // description. keeping this in case that ever changes. callers should read
  // an empty string as "not available", not as an error
  final String description;
  final String logoUrl;
  final String website;
  final String exchange;
  final String country;

  // millions of dollars, thats finnhub's unit
  final double marketCapitalization;
  final String ipoDate;

  String get marketCapLabel {
    if (marketCapitalization <= 0) {
      return '—';
    }
    final billions = marketCapitalization / 1000;
    if (billions >= 1) {
      return '\$${billions.toStringAsFixed(billions >= 100 ? 0 : 1)}B';
    }
    return '\$${marketCapitalization.toStringAsFixed(0)}M';
  }
}

// one finnhub /company-news article
@immutable
class CompanyNewsItem {
  const CompanyNewsItem({
    required this.headline,
    required this.summary,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
  });

  final String headline;
  final String summary;
  final String source;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;
}

// one ohlc bar, both the line chart and candlestick chart use this
// (line chart just uses close)
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

// chart timeframes, same row of buttons a real broker app has
enum ChartRange {
  day1('1D', '5min', 78),
  day5('5D', '30min', 65),
  month1('1M', '1day', 30),
  month3('3M', '1day', 90),
  // added 6M and 5Y so theres somewhere to go *back* to. panning left on a
  // 1D chart cant reach yesterday (intraday series only holds one session)
  // so "let me see older prices" gets answered by the range strip and not by
  // the pan gesture — and the strip used to stop at one year
  month6('6M', '1day', 180),
  year1('1Y', '1week', 52),
  year5('5Y', '1week', 260);

  const ChartRange(this.label, this.interval, this.points);

  final String label;

  // twelve data's interval param
  final String interval;

  // how many bars to ask for
  final int points;
}

// real tickers the market board can trade. common ones show by default,
// rest only show up once you search for them
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

// coins per real dollar of share price. used to be 1:1 but that didnt
// feel like game currency, this way a $337 share = ~3370 coins
const int kCoinsPerDollar = 10;

// dollars -> coins
int coinsForUsd(double usd) => (usd * kCoinsPerDollar).round();

// coins -> dollars
double usdForCoins(num coins) => coins / kCoinsPerDollar;

// coin amount as real money, like "$338.20"
String usdLabel(num coins) {
  final usd = usdForCoins(coins);
  if (usd.abs() >= 100000) {
    return '\$${(usd / 1000).toStringAsFixed(1)}k';
  }
  return '\$${usd.toStringAsFixed(2)}';
}

// coin amount w/ thousands separator, "3,382g"
String coinLabel(num coins) => '${groupedNumber(coins.round())}g';

// share count without a trailing .0, so 2 not 2.0, but 1.25 stays 1.25
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

// why live data isnt available, so the ui can explain instead of just fail
enum LiveMarketStatus {
  idle, // never tried yet
  loading, // request in flight
  ready, // got real quotes
  noApiKey, // no key configured, totally fine, app still works without one
  unavailable, // network fail/timeout/finnhub error
}

// pulls real quotes from finnhub, this is what the market board trades
// against. still optional, no key = app still runs fine, board just
// shows a "add a key" message instead of live prices
class MarketDataService extends ChangeNotifier {
  MarketDataService({http.Client? client}) : _client = client ?? http.Client();

  static const String _host = 'finnhub.io';
  static const Duration _timeout = Duration(seconds: 8);

  // ---------------------------------------------------------------------
  // Server-side proxy
  //
  // preferred over hitting the vendors directly. shipping FINNHUB_API_KEY in
  // the client meant the key sat inside every build for anyone to pull out,
  // and — more practically — Finnhub's 60 calls/minute is *per key*, so every
  // player shared one quota and rate-limited each other. The edge function in
  // `supabase/functions/market` holds the keys and caches responses, so a
  // thousand players cost about the same upstream traffic as one.
  //
  // Direct calls remain as a fallback so a contributor with their own key can
  // still run the app with no Supabase project at all.
  // ---------------------------------------------------------------------

  // url of the market edge function, null if supabase isnt configured
  // (falls back to hitting the vendor directly)
  String? get _proxyBase {
    final url = readRuntimeEnv('SUPABASE_URL');
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed.contains('YOUR-PROJECT')) return null;
    final origin = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return '$origin/functions/v1/market';
  }

  // anon key doubles as the bearer token, its meant to be public. the
  // whole point of the proxy is keeping the ACTUAL market api keys private
  String? get _proxyToken {
    final key = readRuntimeEnv('SUPABASE_ANON_KEY');
    final trimmed = key?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed.contains('YOUR_')) {
      return null;
    }
    return trimmed;
  }

  // can fetch quotes without a key on the client
  bool get usesProxy => _proxyBase != null && _proxyToken != null;

  Uri? _proxyUri(Map<String, String> query) {
    final base = _proxyBase;
    if (base == null) return null;
    return Uri.parse(base).replace(queryParameters: query);
  }

  Map<String, String> get _proxyHeaders => {
    'Authorization': 'Bearer ${_proxyToken ?? ''}',
    'apikey': _proxyToken ?? '',
  };

  Future<http.Response> _getWithProxyFallback(
    Uri uri,
    Map<String, String> headers, {
    Uri? fallbackUri,
    Map<String, String>? fallbackHeaders,
  }) async {
    final response = await _client.get(uri, headers: headers).timeout(_timeout);
    if ((response.statusCode == 404 ||
            response.statusCode == 502 ||
            response.statusCode == 503) &&
        fallbackUri != null) {
      debugPrint(
        'Proxy request failed with ${response.statusCode}; retrying direct vendor request.',
      );
      return _client
          .get(fallbackUri, headers: fallbackHeaders ?? {})
          .timeout(_timeout);
    }
    return response;
  }

  // min gap between 2 fetches of the SAME symbol. short on purpose, the
  // real rate limit is enforced by liveBatchSize below, this just stops
  // a symbol getting double-fetched by overlapping ticks
  static const Duration _minRefreshInterval = Duration(seconds: 4);

  // how often the board asks for a new batch THROUGH the proxy. can be
  // this fast (2s, all 16 symbols) cause the edge function caches vendor
  // responses for 12s, so finnhub only actually gets hit ~5x/min per symbol
  static const Duration proxyPollInterval = Duration(seconds: 2);

  // poll interval with no proxy (local dev only, real builds use the proxy).
  // refreshes a small batch per tick instead of all 16 at once, see
  // refreshBatch. 4 calls every 5s = 48/min, under finnhub's 60/min limit,
  // and whatevers actually on screen gets refreshed way more often
  static const Duration livePollInterval = Duration(seconds: 5);

  // symbols one tick can fetch, leaves headroom for candle/news calls
  // sharing the same rate limit
  static const int liveBatchSize = 4;

  final http.Client _client;

  final Map<String, LiveQuote> _quotes = <String, LiveQuote>{};

  // last fetch time per symbol, for the per-symbol throttle
  final Map<String, DateTime> _lastFetchPerSymbol = <String, DateTime>{};

  final Map<String, TwelveDataQuoteDetails> _details =
      <String, TwelveDataQuoteDetails>{};

  // real intraday closes per symbol for the sparklines. without this the
  // cards only get the 3-point fallback which barely looks like anything
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

  // any cached quote, including ones pulled in from search
  LiveQuote? quoteFor(String symbol) => _quotes[symbol];

  TwelveDataQuoteDetails? detailsFor(String symbol) => _details[symbol];

  // test only, fills quotes without a real network call so widget tests
  // can actually exercise the ticker/trending/card list ui
  @visibleForTesting
  void seedQuotesForTest(Iterable<LiveQuote> quotes) {
    for (final quote in quotes) {
      _quotes[quote.symbol] = quote;
      // seed a fake intraday series too, otherwise seriesFor falls back
      // to the 3-point version and the charted card ui never gets tested
      _series[quote.symbol] = <double>[
        for (var i = 0; i < 24; i++)
          quote.previousClose +
              (quote.current - quote.previousClose) * (i / 23) +
              (i.isEven ? 0.4 : -0.4),
      ];
    }
    notifyListeners();
  }

  // real intraday closes (oldest first), or the 3-point fallback if theres
  // no candle key or the fetch failed
  List<double> seriesFor(String symbol) {
    final cached = _series[symbol];
    if (cached != null && cached.length >= 2) {
      return cached;
    }
    return _quotes[symbol]?.miniSeries ?? const <double>[];
  }

  // at least one symbol has real intraday shape to draw
  bool get hasIntradaySeries => _series.isNotEmpty;

  // fetches real closes for symbols so cards draw an actual shape not just
  // 3 points. throttled cause twelve data's free tier is 8 req/min, only
  // fetches whats actually on screen
  Future<void> refreshSeries(List<String> symbols, {bool force = false}) async {
    if ((_candleApiKey == null && !usesProxy) || symbols.isEmpty) {
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
        _series[symbol] = candles.map((c) => c.close).toList(growable: false);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  // can get quotes at all, proxy or local key. ui checks this for the
  // "add an api key" empty state
  bool get hasApiKey => usesProxy || _apiKey != null;

  String? get _apiKey {
    final raw = readRuntimeEnv('FINNHUB_API_KEY');
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    // .example ships a placeholder, treat placeholder-looking text as
    // no key so a half filled env file doesnt break things
    if (trimmed.isEmpty ||
        trimmed.toUpperCase().contains('OPTIONAL') ||
        trimmed.toUpperCase().contains('YOUR_')) {
      return null;
    }
    return trimmed;
  }

  // where the rotation is at, so batches walk the list instead of
  // refetching the same handful every time
  int _rotation = 0;

  // refreshes a few symbols: whats pinned/owned + the next few in rotation.
  // replaced refreshing all 16 at once, which burned the whole rate limit
  // on stocks nobody was even looking at
  Future<void> refreshBatch({Iterable<String> pinned = const <String>[]}) =>
      refresh(only: selectBatch(pinned: pinned));

  // picks which symbols the next batch asks for. split out from
  // refreshBatch so it can be unit tested without hitting the network.
  // calling it twice gives 2 different batches (rotation advances)
  Set<String> selectBatch({Iterable<String> pinned = const <String>[]}) {
    final known = kLiveSymbols.map((s) => s.symbol).toSet();
    // capped even for pinned ones, otherwise holding 10 stocks = 10
    // symbols every 5s tick = 120 calls/min against a 60 limit
    final wanted = <String>{};
    final owned = pinned.where(known.contains).toList();
    for (var i = 0; wanted.length < liveBatchSize && i < owned.length; i++) {
      wanted.add(owned[(_rotation + i) % owned.length]);
    }
    final rest = kLiveSymbols
        .map((s) => s.symbol)
        .where((s) => !wanted.contains(s))
        .toList();
    for (var i = 0; wanted.length < liveBatchSize && i < rest.length; i++) {
      wanted.add(rest[(_rotation + i) % rest.length]);
    }
    _rotation = rest.isEmpty ? 0 : (_rotation + liveBatchSize) % rest.length;
    return wanted;
  }

  // fetches quotes for only (or everything). respects the min refresh
  // interval unless force is set. never throws, failures just show in status
  Future<void> refresh({bool force = false, Set<String>? only}) async {
    final key = _apiKey;
    if (key == null && !usesProxy) {
      _status = LiveMarketStatus.noApiKey;
      notifyListeners();
      return;
    }

    // throttle is per-symbol now, one shared clock used to block unrelated
    // batches from each other for no reason
    final now = DateTime.now();
    final targets = <LiveSymbol>[
      for (final entry in kLiveSymbols)
        if (only == null || only.contains(entry.symbol))
          if (force ||
              _lastFetchPerSymbol[entry.symbol] == null ||
              now.difference(_lastFetchPerSymbol[entry.symbol]!) >=
                  _minRefreshInterval)
            entry,
    ];
    if (targets.isEmpty) return;

    // only show loading on first fill, a spinner every 5s makes a working
    // board look broken
    if (_quotes.isEmpty) {
      _status = LiveMarketStatus.loading;
      _errorDetail = null;
      notifyListeners();
    }

    try {
      // one at a time not parallel, a burst of calls can trip a 429 on
      // the free tier. batched into one request when theres a proxy tho
      var fetched = <String, LiveQuote>{};
      final batched = usesProxy ? await _fetchAllQuotes(targets) : null;
      if (batched != null) {
        fetched = batched;
        for (final symbol in fetched.keys) {
          _lastFetchPerSymbol[symbol] = DateTime.now();
        }
      } else {
        for (final entry in targets) {
          final quote = await _fetchQuote(entry, key ?? '');
          if (quote != null) {
            fetched[entry.symbol] = quote;
            _lastFetchPerSymbol[entry.symbol] = DateTime.now();
          }
        }
      }

      if (fetched.isEmpty) {
        // only a real failure if NOTHING is cached. an empty batch while
        // 15 good quotes are already showing is a blip, not an outage
        if (_quotes.isEmpty) {
          _status = LiveMarketStatus.unavailable;
          _errorDetail ??= 'No quotes returned.';
        }
      } else {
        // merge, dont replace. used to clear first when every refresh got
        // the whole list, but with batches that wouldve wiped out everything
        // this tick didnt ask for
        _quotes.addAll(fetched);
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

  // every symbol in one request via the proxy's quotes op. null = no
  // proxy, caller falls back to one-at-a-time. keeps partial results,
  // one bad symbol doesnt blank out the 15 good ones
  Future<Map<String, LiveQuote>?> _fetchAllQuotes(
    List<LiveSymbol> wanted,
  ) async {
    final uri = _proxyUri({
      'op': 'quotes',
      'symbols': wanted.map((e) => e.symbol).join(','),
    });
    if (uri == null) return null;

    try {
      final response = await _client
          .get(uri, headers: _proxyHeaders)
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final quotes = decoded['quotes'];
      if (quotes is! Map) return null;

      final byName = <String, LiveSymbol>{
        for (final entry in wanted) entry.symbol: entry,
      };
      final out = <String, LiveQuote>{};
      for (final pair in quotes.entries) {
        final entry = byName[pair.key.toString()];
        final body = pair.value;
        if (entry == null || body is! Map) continue;
        out[entry.symbol] = LiveQuote(
          symbol: entry.symbol,
          company: entry.company,
          current: _readDouble(body['c']),
          change: _readDouble(body['d']),
          percentChange: _readDouble(body['dp']),
          high: _readDouble(body['h']),
          low: _readDouble(body['l']),
          open: _readDouble(body['o']),
          previousClose: _readDouble(body['pc']),
          fetchedAt: DateTime.now(),
        );
      }
      return out;
    } catch (error) {
      debugPrint('Batched quote fetch failed: $error');
      return null;
    }
  }

  Future<LiveQuote?> _fetchQuote(LiveSymbol entry, String apiKey) async {
    // Proxy first; only fall back to a direct call when Supabase is absent.
    final proxied = _proxyUri({'op': 'quote', 'symbol': entry.symbol});
    // Token goes in a header, not the query string, so the key does not end up
    // in proxy or crash logs.
    final uri =
        proxied ?? Uri.https(_host, '/api/v1/quote', {'symbol': entry.symbol});
    final headers = proxied != null
        ? _proxyHeaders
        : {'X-Finnhub-Token': apiKey};

    try {
      final directUri = Uri.https(_host, '/api/v1/quote', {
        'symbol': entry.symbol,
      });
      final response = await _getWithProxyFallback(
        uri,
        headers,
        fallbackUri: proxied == null ? null : directUri,
        fallbackHeaders: proxied == null ? null : {'X-Finnhub-Token': apiKey},
      );

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

  // searches the whole us market. finnhub's /search is free (unlike
  // candles), lets trade tab find any stock not just the pre-listed ones.
  // never throws, just returns no matches on failure
  Future<List<SymbolMatch>> searchSymbols(String query) async {
    final key = _apiKey;
    final trimmed = query.trim();
    if ((key == null && !usesProxy) || trimmed.isEmpty) {
      return const <SymbolMatch>[];
    }

    final proxied = _proxyUri({'op': 'search', 'q': trimmed});
    final directUri = Uri.https(_host, '/api/v1/search', {
      'q': trimmed,
      'exchange': 'US',
    });
    final uri = proxied ?? directUri;
    final headers = proxied != null
        ? _proxyHeaders
        : {'X-Finnhub-Token': key ?? ''};

    try {
      final response = await _getWithProxyFallback(
        uri,
        headers,
        fallbackUri: proxied == null ? null : directUri,
        fallbackHeaders: proxied == null
            ? null
            : {'X-Finnhub-Token': key ?? ''},
      ).timeout(_timeout);

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
        // skip options/warrants/foreign listings, dotted/dashed symbols
        // cant be quoted on the free tier anyway
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

  // fetches + caches a quote for a symbol not in kLiveSymbols, so a
  // searched-for stock becomes tradeable
  Future<LiveQuote?> fetchQuoteFor(String symbol, {String? company}) async {
    final key = _apiKey;
    if (key == null && !usesProxy) {
      return null;
    }
    final quote = await _fetchQuote(
      LiveSymbol(symbol, company ?? symbol),
      key ?? '',
    );
    if (quote != null) {
      _quotes[symbol] = quote;
      notifyListeners();
    }
    return quote;
  }

  Future<TwelveDataQuoteDetails?> fetchTwelveDataQuoteDetails(
    String symbol,
  ) async {
    final key = _candleApiKey;
    if (key == null && !usesProxy) {
      return null;
    }

    final proxied = _proxyUri({'op': 'quote', 'symbol': symbol});
    final directUri = Uri.https('api.twelvedata.com', '/quote', {
      'symbol': symbol,
      'apikey': key ?? '',
    });
    final uri = proxied ?? directUri;
    final headers = proxied != null ? _proxyHeaders : const {};

    try {
      final response = await _getWithProxyFallback(
        uri,
        headers.cast<String, String>(),
        fallbackUri: proxied == null ? null : directUri,
        fallbackHeaders: <String, String>{},
      ).timeout(_timeout);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }

      final symbolValue = (decoded['symbol'] ?? '').toString();
      if (symbolValue.isEmpty) {
        return null;
      }

      final fiftyTwoWeek = decoded['fifty_two_week'];
      final details = TwelveDataQuoteDetails(
        symbol: symbolValue,
        name: (decoded['name'] ?? '').toString(),
        exchange: (decoded['exchange'] ?? '').toString(),
        price: _readDouble(decoded['close']) != 0
            ? _readDouble(decoded['close'])
            : _readDouble(decoded['price']),
        open: _readDouble(decoded['open']),
        high: _readDouble(decoded['high']),
        low: _readDouble(decoded['low']),
        previousClose: _readDouble(decoded['previous_close']),
        bidSize: _readDouble(decoded['bid_size']),
        askSize: _readDouble(decoded['ask_size']),
        volume: _readDouble(decoded['volume']),
        averageVolume: _readDouble(decoded['average_volume']),
        marketCap: _readDouble(decoded['market_cap']),
        fiftyTwoWeekLow: fiftyTwoWeek is Map
            ? _readDouble(fiftyTwoWeek['low'])
            : 0,
        fiftyTwoWeekHigh: fiftyTwoWeek is Map
            ? _readDouble(fiftyTwoWeek['high'])
            : 0,
      );

      _details[symbol] = details;
      notifyListeners();
      return details;
    } catch (_) {
      return null;
    }
  }

  // historical data key configured. finnhub put /stock/candle behind a
  // paywall so candles come from twelve data's free tier instead
  bool get hasCandleKey => usesProxy || _candleApiKey != null;

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

  final Map<String, ({DateTime at, List<Candle> bars})> _candleCache = {};

  // in-flight requests so 2 widgets asking for the same series at once
  // share one call instead of racing each other
  final Map<String, Future<List<Candle>>> _candleInFlight = {};

  // how long a cached series is good for, based on bar size. 1D chart
  // moves constantly (5min bars) but 1M/1Y are daily/weekly bars that
  // literally cant change til market closes, so 1hr cache there is fine
  static Duration _candleTtl(ChartRange range) => switch (range) {
    ChartRange.day1 => const Duration(minutes: 2),
    ChartRange.day5 => const Duration(minutes: 10),
    _ => const Duration(hours: 1),
  };

  // historical ohlc bars for symbol/range. empty list if no key or the
  // request fails, chart falls back to the mini series. cached now, every
  // timeframe tap used to be an uncached round trip which was slow and
  // ate into the 8 req/min limit fast
  Future<List<Candle>> fetchCandles(String symbol, ChartRange range) async {
    final cacheKey = '$symbol:${range.name}';
    final cached = _candleCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.at) < _candleTtl(range)) {
      return cached.bars;
    }
    final pending = _candleInFlight[cacheKey];
    if (pending != null) {
      return pending;
    }

    final request = _fetchCandlesUncached(symbol, range);
    _candleInFlight[cacheKey] = request;
    try {
      final bars = await request;
      // Only cache a real answer. Caching an empty list would pin a
      // transient failure in place for the whole TTL.
      if (bars.isNotEmpty) {
        _candleCache[cacheKey] = (at: DateTime.now(), bars: bars);
      }
      return bars;
    } finally {
      _candleInFlight.remove(cacheKey);
    }
  }

  Future<List<Candle>> _fetchCandlesUncached(
    String symbol,
    ChartRange range,
  ) async {
    final key = _candleApiKey;
    if (key == null && !usesProxy) {
      return const <Candle>[];
    }

    final proxied = _proxyUri({
      'op': 'candles',
      'symbol': symbol,
      'interval': range.interval,
      'outputsize': '${range.points}',
    });
    final directUri = Uri.https('api.twelvedata.com', '/time_series', {
      'symbol': symbol,
      'interval': range.interval,
      'outputsize': '${range.points}',
      'apikey': key ?? '',
    });
    final uri = proxied ?? directUri;

    try {
      final response = await _getWithProxyFallback(
        uri,
        proxied != null ? _proxyHeaders : const {},
        fallbackUri: proxied == null ? null : directUri,
        fallbackHeaders: const {},
      ).timeout(_timeout);
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

      // twelve data returns newest first, charts need oldest first
      return candles.reversed.toList(growable: false);
    } catch (error) {
      debugPrint('Candle fetch failed: $error');
      return const <Candle>[];
    }
  }

  final Map<String, CompanyProfile> _profiles = <String, CompanyProfile>{};

  // symbols already fetching a profile, so a rebuild doesnt double-request
  final Set<String> _profilesInFlight = <String>{};

  // logo url if we already fetched it. sync, never triggers a request,
  // safe to call in build(). null until primeLogos has run
  String? logoUrlFor(String symbol) {
    final url = _profiles[symbol]?.logoUrl;
    return (url == null || url.isEmpty) ? null : url;
  }

  // fetches profiles in the bg so logos are ready for the next rebuild.
  // throttled cause naive would be a request per row per scroll against
  // a 60 call/min limit. skips cached/in-flight, caps to a few new symbols,
  // fails silently, a missing logo is just cosmetic
  Future<void> primeLogos(Iterable<String> symbols, {int limit = 6}) async {
    final wanted = <String>[];
    for (final symbol in symbols) {
      if (_profiles.containsKey(symbol) || _profilesInFlight.contains(symbol)) {
        continue;
      }
      wanted.add(symbol);
      if (wanted.length >= limit) break;
    }
    if (wanted.isEmpty) return;

    _profilesInFlight.addAll(wanted);
    try {
      await Future.wait(wanted.map(fetchCompanyProfile));
    } catch (_) {
      // swallowed on purpose, see above
    } finally {
      _profilesInFlight.removeAll(wanted);
    }
    notifyListeners();
  }

  // static company background, logo/industry/description/market cap.
  // finnhub free tier /stock/profile2. cached for the whole session,
  // this stuff doesnt change minute to minute
  Future<CompanyProfile?> fetchCompanyProfile(String symbol) async {
    final cached = _profiles[symbol];
    if (cached != null) {
      return cached;
    }

    final key = _apiKey;
    if (key == null && !usesProxy) {
      return null;
    }

    final proxied = _proxyUri({'op': 'profile', 'symbol': symbol});
    final directUri = Uri.https(_host, '/api/v1/stock/profile2', {
      'symbol': symbol,
    });
    final uri = proxied ?? directUri;
    final headers = proxied != null
        ? _proxyHeaders
        : {'X-Finnhub-Token': key ?? ''};

    try {
      final response = await _getWithProxyFallback(
        uri,
        headers,
        fallbackUri: proxied == null ? null : directUri,
        fallbackHeaders: proxied == null
            ? null
            : {'X-Finnhub-Token': key ?? ''},
      ).timeout(_timeout);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded.isEmpty) {
        return null;
      }

      final name = (decoded['name'] ?? '').toString();
      if (name.isEmpty) {
        // Finnhub returns `{}` for an unknown/unsupported symbol rather
        // than a 404 — same shape as the quote endpoint's all-zero payload.
        return null;
      }

      final profile = CompanyProfile(
        symbol: symbol,
        name: name,
        industry: (decoded['finnhubIndustry'] ?? '').toString(),
        description: (decoded['description'] ?? '').toString(),
        logoUrl: (decoded['logo'] ?? '').toString(),
        website: (decoded['weburl'] ?? '').toString(),
        exchange: (decoded['exchange'] ?? '').toString(),
        country: (decoded['country'] ?? '').toString(),
        marketCapitalization: _readDouble(decoded['marketCapitalization']),
        ipoDate: (decoded['ipo'] ?? '').toString(),
      );
      _profiles[symbol] = profile;
      return profile;
    } catch (error) {
      debugPrint('Company profile fetch failed: $error');
      return null;
    }
  }

  final Map<String, ({DateTime fetchedAt, List<CompanyNewsItem> items})>
  _newsCache = {};
  static const Duration _newsCacheTtl = Duration(minutes: 15);

  // recent headlines, finnhub free tier /company-news. cached 15 min per
  // symbol, news doesnt need to be as fresh as quotes, saves a ton of
  // proxy budget when lots of players open the same popular stock
  Future<List<CompanyNewsItem>> fetchCompanyNews(String symbol) async {
    final cached = _newsCache[symbol];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _newsCacheTtl) {
      return cached.items;
    }

    final key = _apiKey;
    if (key == null && !usesProxy) {
      return const <CompanyNewsItem>[];
    }

    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 14));
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final proxied = _proxyUri({
      'op': 'news',
      'symbol': symbol,
      'from': iso(from),
      'to': iso(now),
    });
    final directUri = Uri.https(_host, '/api/v1/company-news', {
      'symbol': symbol,
      'from': iso(from),
      'to': iso(now),
    });
    final uri = proxied ?? directUri;
    final headers = proxied != null
        ? _proxyHeaders
        : {'X-Finnhub-Token': key ?? ''};

    try {
      final response = await _getWithProxyFallback(
        uri,
        headers,
        fallbackUri: proxied == null ? null : directUri,
        fallbackHeaders: proxied == null
            ? null
            : {'X-Finnhub-Token': key ?? ''},
      ).timeout(_timeout);
      if (response.statusCode != 200) {
        return const <CompanyNewsItem>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const <CompanyNewsItem>[];
      }

      final items = <CompanyNewsItem>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final headline = (entry['headline'] ?? '').toString();
        final url = (entry['url'] ?? '').toString();
        if (headline.isEmpty || url.isEmpty) {
          continue;
        }
        final epochSeconds = entry['datetime'];
        final publishedAt = epochSeconds is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (epochSeconds * 1000).round(),
                isUtc: true,
              )
            : now;
        items.add(
          CompanyNewsItem(
            headline: headline,
            summary: (entry['summary'] ?? '').toString(),
            source: (entry['source'] ?? '').toString(),
            url: url,
            imageUrl: (entry['image'] ?? '').toString(),
            publishedAt: publishedAt,
          ),
        );
      }
      // Newest first, then de-duplicated, then capped.
      //
      // The two-week window routinely comes back with the same wire story
      // carried by a dozen outlets under near-identical headlines, so a
      // plain 'take(12)' could fill the entire panel with one piece of news
      // and hide everything else that happened. Matching on a normalised
      // headline (lowercased, punctuation stripped, whitespace collapsed)
      // catches the reprints, which differ only in casing and trailing
      // attribution, without needing to compare article bodies.
      items.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      final seenHeadlines = <String>{};
      final unique = <CompanyNewsItem>[];
      for (final item in items) {
        final fingerprint = item.headline
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (fingerprint.isEmpty || !seenHeadlines.add(fingerprint)) continue;
        unique.add(item);
      }
      final capped = unique.take(12).toList(growable: false);
      _newsCache[symbol] = (fetchedAt: DateTime.now(), items: capped);
      return capped;
    } catch (error) {
      debugPrint('Company news fetch failed: $error');
      return const <CompanyNewsItem>[];
    }
  }

  // finnhub sends descriptions in all caps, looks like yelling otherwise
  static String _titleCase(String input) {
    return input
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
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
