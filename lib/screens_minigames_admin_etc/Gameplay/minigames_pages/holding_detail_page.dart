import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/market_data_service.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets_custom_lotties/market_visuals.dart';
import '../../../widgets_custom_lotties/mini_sparkline.dart';
import '../../../widgets_custom_lotties/price_chart.dart';
import '../../../widgets_custom_lotties/symbol_badge.dart';
import 'stock_market_page.dart'
    show kBoardInset, kBoardPanel, parseStockOrderTitle;

const Color _up = Color(0xFF9BE870);
const Color _down = Color(0xFFFF8A80);

/// One stock you own, looked at properly: the chart, what your position is
/// doing, how the stock has moved, how far it tends to swing, the news, and
/// every trade you made in it.
///
/// **Asked for as:** *"when I click on the holdings I want it to take me to a
/// detailed analysis screen on how the stock is doing with line charts, recent
/// news, what is going to happen and like other stock trading apps would
/// do."* Before this a holding opened the order ticket, which is built for
/// placing a trade and puts the position itself nowhere.
///
/// "What is going to happen" is answered the honest way: nobody knows, so the
/// screen shows how much this stock actually moved over the past year and
/// what that range would mean for the player's own position. It is labelled
/// as a range, never as a forecast — a game that teaches money should not
/// teach that prices can be predicted.
///
/// Everything live comes from [MarketDataService] and the position from
/// [UserStatsController], both watched, so a trade made from the buttons at
/// the bottom shows up here as soon as it settles.
class HoldingDetailPage extends StatefulWidget {
  const HoldingDetailPage({
    super.key,
    required this.symbol,
    required this.company,
    required this.icon,
    required this.accent,
    required this.fallbackSeries,
    required this.onTrade,
  });

  final String symbol;
  final String company;
  final IconData icon;
  final Color accent;

  /// The board's own short price history, drawn when no candles come back
  /// (no Twelve Data key, or the free plan does not cover this listing).
  final List<double> fallbackSeries;

  /// Opens the order ticket, as a buy when true and a sell when false.
  final Future<void> Function(bool buy) onTrade;

  @override
  State<HoldingDetailPage> createState() => _HoldingDetailPageState();
}

class _HoldingDetailPageState extends State<HoldingDetailPage> {
  ChartRange _range = ChartRange.month1;
  List<Candle> _candles = const <Candle>[];
  bool _loadingChart = true;
  int? _hoverIndex;

  /// A year of weekly closes, for the returns strip and the swing range.
  /// Fetched once, separately from whatever range the chart is showing.
  List<Candle> _year = const <Candle>[];

  TwelveDataQuoteDetails? _details;
  CompanyProfile? _profile;
  List<CompanyNewsItem> _news = const <CompanyNewsItem>[];
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChart();
      _loadYear();
      _loadCompany();
    });
  }

  Future<void> _loadChart() async {
    setState(() => _loadingChart = true);
    final candles = await context.read<MarketDataService>().fetchCandles(
      widget.symbol,
      _range,
    );
    if (!mounted) return;
    setState(() {
      _candles = candles.where((c) => c.isValid).toList(growable: false);
      _loadingChart = false;
      _hoverIndex = null;
    });
  }

  Future<void> _loadYear() async {
    final year = await context.read<MarketDataService>().fetchCandles(
      widget.symbol,
      ChartRange.year1,
    );
    if (!mounted) return;
    setState(
      () => _year = year.where((c) => c.isValid).toList(growable: false),
    );
  }

  Future<void> _loadCompany() async {
    final service = context.read<MarketDataService>();
    final results = await Future.wait<Object?>([
      service.fetchTwelveDataQuoteDetails(widget.symbol),
      service.fetchCompanyProfile(widget.symbol),
      service.fetchCompanyNews(widget.symbol),
    ]);
    if (!mounted) return;
    setState(() {
      _details = results[0] as TwelveDataQuoteDetails?;
      _profile = results[1] as CompanyProfile?;
      _news = (results[2] as List<CompanyNewsItem>?) ?? const [];
      _loadingNews = false;
    });
  }

  void _pickRange(ChartRange range) {
    if (range == _range) return;
    HapticFeedback.selectionClick();
    _range = range;
    _loadChart();
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketDataService>();
    final stats = context.watch<UserStatsController>().stats;
    final quote = market.quoteFor(widget.symbol);

    final key = 'stock_${widget.symbol}';
    final owned = stats.holdings[key] ?? 0.0;
    final basis = stats.costBasis[key] ?? 0;

    // Price per share in coins. Falls back to the last candle, then to what
    // was paid, so a listing the quote feed dropped still has a number.
    final priceUsd =
        quote?.current ??
        (_candles.isNotEmpty ? _candles.last.close : null) ??
        (owned != 0 ? usdForCoins(basis / owned) : 0.0);
    final price = priceUsd * kCoinsPerDollar;
    final changeUsd = quote?.change ?? 0.0;
    final changePct = quote?.percentChange ?? 0.0;

    // Everything the player owns, at today's prices, for "share of net worth".
    var netWorth = stats.gold.toDouble();
    stats.holdings.forEach((k, lots) {
      if (!k.startsWith('stock_') || lots == 0) return;
      final q = market.quoteFor(k.substring(6));
      netWorth += q != null && q.isValid
          ? lots * coinsForUsd(q.current)
          : (stats.costBasis[k] ?? 0).toDouble();
    });

    final trades = <({DateTime at, String verb, String detail, int amount})>[
      for (final t in stats.transactions)
        if (parseStockOrderTitle(t.title) case final p?
            when p.symbol == widget.symbol)
          (
            at: t.createdAt,
            verb: p.isShort
                ? 'Shorted'
                : p.isCover
                ? 'Covered'
                : p.isBuy
                ? 'Bought'
                : 'Sold',
            detail: t.description,
            amount: t.amount,
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    final hovered = _hoverIndex != null && _hoverIndex! < _candles.length
        ? _candles[_hoverIndex!]
        : null;

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      appBar: AppBar(
        backgroundColor: AppTheme.deepForest,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.symbol,
          style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: _TradeBar(
        owned: owned,
        accent: widget.accent,
        onBuy: () => widget.onTrade(true),
        onSell: () => widget.onTrade(false),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _PriceHeader(
            symbol: widget.symbol,
            company: _profile?.name.isNotEmpty == true
                ? _profile!.name
                : widget.company,
            icon: widget.icon,
            accent: widget.accent,
            price: hovered != null ? hovered.close * kCoinsPerDollar : price,
            change: hovered != null
                ? (hovered.close - (_candles.first.close)) * kCoinsPerDollar
                : changeUsd * kCoinsPerDollar,
            changePct: hovered != null
                ? (hovered.close / _candles.first.close - 1) * 100
                : changePct,
            caption: hovered != null
                ? _dateLabel(hovered.time, _range)
                : 'Today',
          ),
          const SizedBox(height: 14),
          _buddyTake(
            symbol: widget.symbol,
            owned: owned,
            price: price,
            basis: basis,
            netWorth: netWorth,
            year: _year,
          ),
          const SizedBox(height: 14),
          _ChartCard(
            candles: _candles,
            loading: _loadingChart,
            range: _range,
            accent: widget.accent,
            fallbackSeries: widget.fallbackSeries,
            onRange: _pickRange,
            onHover: (i) => setState(() => _hoverIndex = i),
          ),
          if (owned != 0) ...[
            const SizedBox(height: 16),
            _PositionCard(
              owned: owned,
              basis: basis,
              price: price,
              changeUsd: changeUsd,
              netWorth: netWorth,
            ),
          ],
          const SizedBox(height: 16),
          _ReturnsStrip(year: _year),
          const SizedBox(height: 16),
          _StatsCard(quote: quote, details: _details, profile: _profile),
          const SizedBox(height: 16),
          _OutlookCard(
            symbol: widget.symbol,
            year: _year,
            price: price,
            owned: owned,
            netWorth: netWorth,
          ),
          const SizedBox(height: 16),
          _NewsCard(news: _news, loading: _loadingNews),
          if (_profile != null) ...[
            const SizedBox(height: 16),
            _AboutCard(profile: _profile!),
          ],
          const SizedBox(height: 16),
          _TradesCard(symbol: widget.symbol, trades: trades),
        ],
      ),
    );
  }
}

/// The turtle's one-line read of this holding, picked from what matters
/// most right now: too much money in one place, a big loss, a big gain, or
/// just what the year looked like.
Widget _buddyTake({
  required String symbol,
  required double owned,
  required double price,
  required int basis,
  required double netWorth,
  required List<Candle> year,
}) {
  final value = owned * price;
  final share = netWorth > 0 ? value.abs() / netWorth : 0.0;
  final plPct = basis != 0 ? (value - basis) / basis.abs() * 100 : 0.0;
  final yearPct = year.length >= 2
      ? (year.last.close / year.first.close - 1) * 100
      : null;

  if (owned != 0 && share > 0.5) {
    return BuddySaysCard(
      mood: BuddyMood.worried,
      title: 'Lots of eggs, one basket',
      message:
          '${(share * 100).round()}% of everything you own rides on $symbol. '
          'One bad week for one company would hit all of it.',
    );
  }
  if (owned != 0 && plPct <= -10) {
    return BuddySaysCard(
      mood: BuddyMood.worried,
      title: 'Down ${plPct.abs().toStringAsFixed(0)}% on this one',
      message:
          'Selling locks the loss in; holding bets it comes back. Ask what '
          'you would do if you did not own it today.',
    );
  }
  if (owned != 0 && plPct >= 10) {
    return BuddySaysCard(
      mood: BuddyMood.happy,
      title: 'Up ${plPct.toStringAsFixed(0)}% so far',
      message:
          'Nice. It is only real money once you sell, and past gains do not '
          'promise more.',
    );
  }
  if (yearPct != null) {
    return BuddySaysCard(
      mood: BuddyMood.thinking,
      title:
          '$symbol ${yearPct >= 0 ? 'rose' : 'fell'} '
          '${yearPct.abs().toStringAsFixed(0)}% this year',
      message:
          'That is what already happened. The swing range further down shows '
          'how wide the next year could be.',
    );
  }
  return BuddySaysCard(
    mood: BuddyMood.thinking,
    title: 'Look before you trade',
    message:
        'The chart shows where $symbol has been. The news shows why people '
        'think it moved.',
  );
}

String _dateLabel(DateTime t, ChartRange range) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = t.toLocal();
  final day = '${months[local.month - 1]} ${local.day}';
  if (range == ChartRange.day1 || range == ChartRange.day5) {
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$day, $hh:$mm';
  }
  return '$day ${local.year}';
}

String _signed(num v, {int digits = 0}) =>
    '${v >= 0 ? '+' : '-'}${v.abs().toStringAsFixed(digits)}';

String _signedCoins(num v) => '${v >= 0 ? '+' : '-'}${coinLabel(v.abs())}';

/// The shared card shape on this screen: solid, bordered, on a ledge.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  /// A pixel icon from the UI kit beside the title.
  final String? icon;
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBoardPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1.5,
        ),
        boxShadow: AppTheme.ledgeShadow(AppTheme.greenPrimary, restAlpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  KitIcon(icon!, size: 32),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({
    required this.symbol,
    required this.company,
    required this.icon,
    required this.accent,
    required this.price,
    required this.change,
    required this.changePct,
    required this.caption,
  });

  final String symbol;
  final String company;
  final IconData icon;
  final Color accent;
  final double price;
  final double change;
  final double changePct;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final color = change >= 0 ? _up : _down;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SymbolBadge(symbol: symbol, icon: icon, accent: accent, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${price.toStringAsFixed(1)}g',
                style: AppTheme.numeric(color: Colors.white, fontSize: 30),
              ),
              Text(
                '${usdLabel(price)} a share',
                style: AppTheme.numeric(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_signed(change, digits: 1)}g '
                '(${_signed(changePct, digits: 2)}%)  $caption',
                style: AppTheme.numeric(color: color, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.candles,
    required this.loading,
    required this.range,
    required this.accent,
    required this.fallbackSeries,
    required this.onRange,
    required this.onHover,
  });

  final List<Candle> candles;
  final bool loading;
  final ChartRange range;
  final Color accent;
  final List<double> fallbackSeries;
  final ValueChanged<ChartRange> onRange;
  final ValueChanged<int?> onHover;

  @override
  Widget build(BuildContext context) {
    final hasCandles = candles.length >= 2;
    final rangeReturn = hasCandles
        ? (candles.last.close / candles.first.close - 1) * 100
        : null;
    final lineColor = rangeReturn == null
        ? accent
        : (rangeReturn >= 0 ? _up : _down);

    return _Panel(
      title: 'Price',
      icon: AppAssets.kitIconChartUp,
      subtitle: rangeReturn == null
          ? null
          : '${_signed(rangeReturn, digits: 1)}% over ${range.label}. '
                'Drag along the line to read any point.',
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : hasCandles
                ? InteractivePriceChart(
                    candles: candles,
                    mode: ChartMode.line,
                    accent: lineColor,
                    onHoverIndexChanged: onHover,
                  )
                : Column(
                    children: [
                      Expanded(
                        child: MiniSparkline(
                          values: fallbackSeries,
                          color: accent,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only the board\'s recent prices are available for '
                        'this one, so there is no history to pick a range from.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final r in ChartRange.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _Chip(
                      label: r.label,
                      selected: r == range,
                      color: lineColor,
                      onTap: () => onRange(r),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : kBoardInset,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.numeric(
            color: selected ? const Color(0xFF082016) : Colors.white70,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

/// A label over a number, the unit every card below is built from.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.color, this.note});

  final String label;
  final String value;
  final Color? color;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTheme.numeric(color: color ?? Colors.white, fontSize: 15),
        ),
        if (note != null)
          Text(
            note!,
            style: AppTheme.numeric(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

/// Facts laid out two (or four, when there is room) to a row.
class _FactGrid extends StatelessWidget {
  const _FactGrid(this.facts);

  final List<Widget> facts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: [for (final f in facts) SizedBox(width: width, child: f)],
        );
      },
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.owned,
    required this.basis,
    required this.price,
    required this.changeUsd,
    required this.netWorth,
  });

  final double owned;
  final int basis;
  final double price;
  final double changeUsd;
  final double netWorth;

  @override
  Widget build(BuildContext context) {
    final isShort = owned < 0;
    final shares = owned.abs();
    final value = owned * price;
    final pl = value - basis;
    final plPct = basis != 0 ? pl / basis.abs() * 100 : 0.0;
    final today = owned * changeUsd * kCoinsPerDollar;
    final avg = shares > 0 ? basis.abs() / shares : 0.0;
    final share = netWorth > 0 ? (value.abs() / netWorth).clamp(0.0, 1.0) : 0.0;

    return _Panel(
      title: isShort ? 'Your short position' : 'Your position',
      icon: AppAssets.kitIconPiggy,
      subtitle: isShort
          ? 'You borrowed and sold these shares. You make money if the price '
                'falls, and lose it if the price rises.'
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactGrid([
            _Fact('Shares', formatShares(shares)),
            _Fact(
              'Market value',
              coinLabel(value.abs()),
              note: usdLabel(value.abs()),
            ),
            _Fact('Average cost', '${avg.toStringAsFixed(1)}g'),
            _Fact('Cost basis', coinLabel(basis.abs())),
            _Fact(
              'Total return',
              _signedCoins(pl),
              color: pl >= 0 ? _up : _down,
              note: '${_signed(plPct, digits: 1)}%',
            ),
            _Fact(
              "Today's return",
              _signedCoins(today),
              color: today >= 0 ? _up : _down,
            ),
            _Fact(
              'Break-even price',
              '${avg.toStringAsFixed(1)}g',
              note: isShort ? 'You profit below this' : 'You profit above this',
            ),
            _Fact('Share of net worth', '${(share * 100).toStringAsFixed(1)}%'),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              SliceRing(
                fraction: share,
                color: share > 0.25
                    ? const Color(0xFFFFC36B)
                    : AppTheme.greenPrimary,
                size: 84,
                center: Text(
                  '${(share * 100).round()}%',
                  style: AppTheme.numeric(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  share > 0.25
                      ? 'Of everything you own, this slice is in one company.'
                      : 'Of everything you own, this slice is in this '
                            'company. A slice this size is easy to live with.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (share > 0.25) ...[
            const SizedBox(height: 8),
            Text(
              '${(share * 100).round()}% of everything you own is in this one '
              'company. If it fell by half, you would lose about '
              '${(share * 50).round()}% of your net worth. Spreading money '
              'across several companies is called diversifying.',
              style: const TextStyle(
                color: Color(0xFFFFD9A0),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How the price moved over the last week, month, quarter, half and year,
/// read off a year of weekly closes.
class _ReturnsStrip extends StatelessWidget {
  const _ReturnsStrip({required this.year});

  final List<Candle> year;

  @override
  Widget build(BuildContext context) {
    const spans = <(String, int)>[
      ('1W', 1),
      ('1M', 4),
      ('3M', 13),
      ('6M', 26),
      ('1Y', 51),
    ];
    return _Panel(
      title: 'Performance',
      icon: AppAssets.kitIconStack,
      subtitle: year.length < 2
          ? 'Needs a year of price history, which this listing did not return.'
          : 'How much the price changed over each stretch, to the last close.',
      child: year.length < 2
          ? const SizedBox.shrink()
          : ReturnBars(
              entries: [
                for (final (label, weeks) in spans)
                  (
                    label,
                    (year.last.close /
                                year[math.max(0, year.length - 1 - weeks)]
                                    .close -
                            1) *
                        100,
                  ),
              ],
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.quote,
    required this.details,
    required this.profile,
  });

  final LiveQuote? quote;
  final TwelveDataQuoteDetails? details;
  final CompanyProfile? profile;

  String _coins(double? usd) => usd == null || usd <= 0
      ? '—'
      : '${(usd * kCoinsPerDollar).toStringAsFixed(1)}g';

  String _big(double v) {
    if (v <= 0) return '—';
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final d = details;
    final low52 = d?.fiftyTwoWeekLow ?? 0;
    final high52 = d?.fiftyTwoWeekHigh ?? 0;
    final now = q?.current ?? d?.price ?? 0;
    final has52 = low52 > 0 && high52 > low52 && now > 0;
    final cap = d != null && d.marketCap > 0
        ? '\$${_big(d.marketCap)}'
        : (profile?.marketCapLabel ?? '—');

    return _Panel(
      title: 'Key stats',
      icon: AppAssets.kitIconBook,
      subtitle: 'In coins a share. 10 coins is one real dollar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactGrid([
            _Fact('Open', _coins(q?.open ?? d?.open)),
            _Fact(
              'Previous close',
              _coins(q?.previousClose ?? d?.previousClose),
            ),
            _Fact("Today's high", _coins(q?.high ?? d?.high)),
            _Fact("Today's low", _coins(q?.low ?? d?.low)),
            _Fact('Volume', d == null ? '—' : _big(d.volume)),
            _Fact('Average volume', d == null ? '—' : _big(d.averageVolume)),
            _Fact('Market cap', cap),
            _Fact(
              'Exchange',
              d?.exchange.isNotEmpty == true
                  ? d!.exchange
                  : (profile?.exchange.isNotEmpty == true
                        ? profile!.exchange
                        : '—'),
            ),
          ]),
          if (has52) ...[
            const SizedBox(height: 16),
            Text(
              '52-week range',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final t = ((now - low52) / (high52 - low52)).clamp(0.0, 1.0);
                return SizedBox(
                  height: 14,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 5,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: kBoardInset,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: (c.maxWidth - 12) * t,
                        top: 1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: kBoardPanel, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _coins(low52),
                  style: AppTheme.numeric(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _coins(high52),
                  style: AppTheme.numeric(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "What is going to happen", answered honestly.
///
/// The range is one standard deviation of the last year's weekly returns,
/// scaled to a year: roughly two years in three land inside it, if the stock
/// keeps behaving the way it did. That "if" is the whole lesson, so the card
/// says it in words before it shows a single number.
class _OutlookCard extends StatelessWidget {
  const _OutlookCard({
    required this.symbol,
    required this.year,
    required this.price,
    required this.owned,
    required this.netWorth,
  });

  final String symbol;
  final List<Candle> year;
  final double price;
  final double owned;
  final double netWorth;

  /// Yearly swing as a fraction, or null without enough weeks to measure.
  double? get _yearlySwing {
    if (year.length < 12) return null;
    final returns = <double>[
      for (var i = 1; i < year.length; i++)
        math.log(year[i].close / year[i - 1].close),
    ];
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
        (returns.length - 1);
    return math.sqrt(variance) * math.sqrt(52);
  }

  @override
  Widget build(BuildContext context) {
    final swing = _yearlySwing;
    if (swing == null) {
      return _Panel(
        title: 'What could happen next',
        icon: AppAssets.kitIconShield,
        subtitle:
            'Nobody can tell you what a price will do. With a year of history '
            'this card shows how far this one usually swings. That history '
            'did not load for this listing.',
        child: SizedBox.shrink(),
      );
    }

    final risk = swing < 0.2
        ? ('Calmer', AppTheme.greenPrimary)
        : swing < 0.35
        ? ('Average swings', const Color(0xFFFFC36B))
        : ('Big swings', _down);
    final goodPct = (math.exp(swing) - 1) * 100;
    final roughPct = (math.exp(-swing) - 1) * 100;

    // Per share for a watcher, or the player's own position when they own it.
    final base = owned != 0 ? (owned * price).abs() : price;
    final unit = owned != 0 ? 'your shares' : 'one share';
    final drop20 = base * 0.2;

    Widget scenario(String label, double pct, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: kBoardInset,
          borderRadius: BorderRadius.circular(12),
          border: Border(top: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          children: [
            KitIcon(
              pct > 0
                  ? AppAssets.kitIconChartUp
                  : pct < 0
                  ? AppAssets.kitIconChartDown
                  : AppAssets.kitIconCoin,
              size: 36,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                coinLabel(base * (1 + pct / 100)),
                style: AppTheme.numeric(color: Colors.white, fontSize: 15),
              ),
            ),
            Text(
              '${_signed(pct, digits: 0)}%',
              style: AppTheme.numeric(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    return _Panel(
      title: 'What could happen next',
      icon: AppAssets.kitIconShield,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: kBoardInset,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: risk.$2),
        ),
        child: Text(
          risk.$1,
          style: AppTheme.numeric(color: risk.$2, fontSize: 11.5),
        ),
      ),
      subtitle:
          'Nobody can know. What we can show is how much $symbol moved over '
          'the past year — about ${(swing * 100).round()}% either way in a '
          'typical year — and what that would mean for $unit a year from now.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RangeTrack(
            low: base * (1 + roughPct / 100),
            mid: base,
            high: base * (1 + goodPct / 100),
            lowLabel: coinLabel(base * (1 + roughPct / 100)),
            midLabel: 'Now ${coinLabel(base)}',
            highLabel: coinLabel(base * (1 + goodPct / 100)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              scenario('A rough year', roughPct, _down),
              const SizedBox(width: 8),
              scenario('No change', 0, Colors.white54),
              const SizedBox(width: 8),
              scenario('A good year', goodPct, _up),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'About two years in three land between the rough and the good '
            'year, if the stock keeps behaving the way it did. It does not '
            'have to: news, earnings or the whole market can push it outside '
            'that range.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'If it fell 20% tomorrow, $unit would lose ${coinLabel(drop20)}'
            '${owned != 0 && netWorth > 0 ? ' — ${(drop20 / netWorth * 100).toStringAsFixed(1)}% of your net worth' : ''}.',
            style: const TextStyle(
              color: Color(0xFFFFD9A0),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 60) return '${math.max(1, d.inMinutes)}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return '${(d.inDays / 30).floor()}mo ago';
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news, required this.loading});

  final List<CompanyNewsItem> news;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent news',
      icon: AppAssets.kitPackInfo,
      subtitle: news.isEmpty
          ? null
          : 'News moves prices, but a headline is not a reason to trade on '
                'its own. Tap one to read it.',
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : news.isEmpty
          ? Text(
              'No recent news came back for this company.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            )
          : Column(
              children: [
                for (final item in news.take(6))
                  InkWell(
                    onTap: () => _openUrl(item.url),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NewsThumb(item: item),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.source} · ${_ago(item.publishedAt)}',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.headline,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                if (item.summary.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The article's own picture, or the source's initial on a tile when there
/// is none or it will not load (some news sites block other origins).
class _NewsThumb extends StatelessWidget {
  const _NewsThumb({required this.item});

  final CompanyNewsItem item;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: kBoardInset,
      alignment: Alignment.center,
      child: Text(
        item.source.isEmpty ? '?' : item.source.substring(0, 1).toUpperCase(),
        // Not Pixelify: a lone capital in the pixel face is one of its
        // confusable shapes. See AppTheme.caps.
        style: AppTheme.caps(color: const Color(0xFF7FD8F2), fontSize: 26),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: item.imageUrl.isEmpty
            ? fallback
            : Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.profile});

  final CompanyProfile profile;

  @override
  Widget build(BuildContext context) {
    String or(String v) => v.isEmpty ? '—' : v;
    return _Panel(
      title: 'About ${profile.name.isEmpty ? profile.symbol : profile.name}',
      icon: AppAssets.kitIconStar,
      subtitle: profile.description.isEmpty ? null : profile.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactGrid([
            _Fact('Industry', or(profile.industry)),
            _Fact('Country', or(profile.country)),
            _Fact('Listed since', or(profile.ipoDate)),
            _Fact('Market cap', profile.marketCapLabel),
          ]),
          if (profile.website.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openUrl(profile.website),
              child: Text(
                profile.website,
                style: const TextStyle(
                  color: Color(0xFF7FD8F2),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF7FD8F2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TradesCard extends StatelessWidget {
  const _TradesCard({required this.symbol, required this.trades});

  final String symbol;
  final List<({DateTime at, String verb, String detail, int amount})> trades;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Your trades in $symbol',
      icon: AppAssets.kitIconCoin,
      child: trades.isEmpty
          ? Text(
              'You have not traded this one yet.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            )
          : Column(
              children: [
                for (final t in trades.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: kBoardInset,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t.verb,
                            style: AppTheme.numeric(
                              color: t.verb == 'Bought' || t.verb == 'Covered'
                                  ? _up
                                  : const Color(0xFFFFC36B),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.detail,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                              Text(
                                _dateLabel(t.at, ChartRange.month1),
                                style: AppTheme.numeric(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          coinLabel(t.amount.abs()),
                          style: AppTheme.numeric(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TradeBar extends StatelessWidget {
  const _TradeBar({
    required this.owned,
    required this.accent,
    required this.onBuy,
    required this.onSell,
  });

  final double owned;
  final Color accent;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  Widget _button(String label, Color fill, Color ink, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.ledgeShadow(fill, restAlpha: 0.3),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.pixelifySans(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: kBoardPanel,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // A short is closed by buying the shares back, so it gets one
            // button that says so rather than a Sell that would add to it.
            if (owned > 0) ...[
              _button(
                'Sell',
                const Color(0xFFFFB084),
                const Color(0xFF2A1206),
                onSell,
              ),
              const SizedBox(width: 12),
            ],
            _button(
              owned < 0 ? 'Cover' : 'Buy',
              AppTheme.greenPrimary,
              const Color(0xFF062017),
              onBuy,
            ),
          ],
        ),
      ),
    );
  }
}
