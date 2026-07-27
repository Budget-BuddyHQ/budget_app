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
}

/// Which real-world tickers the Live Market panel follows.
///
/// Deliberately household names — the point is for a teenager to recognise the
/// company, not to model a diversified portfolio.
@immutable
class LiveSymbol {
  const LiveSymbol(this.symbol, this.company);

  final String symbol;
  final String company;
}

const List<LiveSymbol> kLiveSymbols = <LiveSymbol>[
  LiveSymbol('AAPL', 'Apple'),
  LiveSymbol('MSFT', 'Microsoft'),
  LiveSymbol('NKE', 'Nike'),
  LiveSymbol('SBUX', 'Starbucks'),
  LiveSymbol('DIS', 'Disney'),
  LiveSymbol('SPY', 'S&P 500 Fund'),
];

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

/// Fetches real market quotes from Finnhub.
///
/// Everything about this service is optional by design: the app must stay
/// fully usable with no API key at all, so a teammate can clone the repo and
/// run it with zero setup. When no key is present the service reports
/// [LiveMarketStatus.noApiKey] and the UI simply hides the live panel — the
/// simulated trading board that drives the actual game economy is untouched.
class MarketDataService extends ChangeNotifier {
  MarketDataService({http.Client? client}) : _client = client ?? http.Client();

  static const String _host = 'finnhub.io';
  static const Duration _timeout = Duration(seconds: 8);

  /// Free tier allows 60 calls/minute. Refreshing all six symbols costs six
  /// calls, so a 60s floor keeps us at ~6/min with a wide safety margin even
  /// if the user rapidly reopens the screen.
  static const Duration _minRefreshInterval = Duration(seconds: 60);

  final http.Client _client;

  final Map<String, LiveQuote> _quotes = <String, LiveQuote>{};
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
