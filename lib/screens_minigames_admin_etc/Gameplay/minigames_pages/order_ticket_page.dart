import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_assets.dart';
import '../../../services_backend_and_other_services/market_data_service.dart';
import '../../../widgets_custom_lotties/price_chart.dart';

/// What kind of order the player is placing.
///
/// A market order crosses the spread and fills now. A limit order fills now if
/// it is already marketable; if it isn't (a buy below the ask, a sell above the
/// bid) it *rests as a working order* and fills later when the price comes to
/// it — which is the entire point of a limit order.
enum OrderType { market, limit }

enum TradeAction { buy, sell, short, cover }

/// The order handed back to the caller, which owns the gold/holdings.
@immutable
class OrderRequest {
  const OrderRequest({
    required this.action,
    required this.quantity,
    required this.pricePerShare,
    this.isWorking = false,
  });

  final TradeAction action;

  bool get isBuy => action == TradeAction.buy;
  bool get isShort => action == TradeAction.short;
  bool get isCover => action == TradeAction.cover;

  /// Fractional — a coin buys a slice of a share, so 0.5 is a valid quantity.
  final double quantity;

  /// The immediate fill price, or — when [isWorking] — the resting limit price.
  final int pricePerShare;

  /// True when this order can't fill right now and should rest as a working
  /// (pending) limit order instead of executing immediately.
  final bool isWorking;

  int get total => (quantity * pricePerShare).round();
}

class OrderTicketPage extends StatefulWidget {
  const OrderTicketPage({
    super.key,
    required this.symbol,
    required this.company,
    required this.icon,
    required this.accent,
    required this.lastPrice,
    required this.bidPrice,
    required this.askPrice,
    required this.ownedLots,
    required this.availableGold,
    required this.fallbackSeries,
    this.startAsBuy = true,
  });

  final String symbol;
  final String company;
  final IconData icon;
  final Color accent;
  final int lastPrice;

  /// What a seller receives, and what a buyer pays.
  final int bidPrice;
  final int askPrice;

  final double ownedLots;
  final int availableGold;

  /// Quote-derived prices, drawn when no historical-data key is configured.
  final List<double> fallbackSeries;

  final bool startAsBuy;

  @override
  State<OrderTicketPage> createState() => _OrderTicketPageState();
}

class _OrderTicketPageState extends State<OrderTicketPage> {
  late TradeAction _action = widget.ownedLots < 0
      ? TradeAction.cover
      : (widget.startAsBuy ? TradeAction.buy : TradeAction.sell);
  OrderType _orderType = OrderType.limit;
  ChartRange _range = ChartRange.day1;
  ChartMode _chartMode = ChartMode.line;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  List<Candle> _candles = const <Candle>[];
  bool _loadingChart = false;
  bool _detailsLoading = false;
  String? _detailsError;
  TwelveDataQuoteDetails? _details;
  bool _detailsExpanded = false;
  bool _hideShortingWarning = false;
  static const String _shortingWarningKey = 'budget_buddy_shorting_warning_hidden';

  @override
  void initState() {
    super.initState();
    _priceController.text = '${widget.lastPrice}';
    _loadShortingWarningPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChart();
      _loadDetails();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadChart() async {
    if (!mounted) return;
    setState(() => _loadingChart = true);
    final candles = await context.read<MarketDataService>().fetchCandles(
      widget.symbol,
      _range,
    );
    if (!mounted) return;
    setState(() {
      _candles = candles;
      _loadingChart = false;
    });
  }

  Future<void> _loadShortingWarningPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hideShortingWarning = prefs.getBool(_shortingWarningKey) ?? false;
    });
  }

  Future<void> _saveShortingWarningPreference(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shortingWarningKey, hide);
    if (!mounted) return;
    setState(() => _hideShortingWarning = hide);
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;
    final cached = context.read<MarketDataService>().detailsFor(widget.symbol);
    if (cached != null) {
      setState(() => _details = cached);
      return;
    }

    setState(() {
      _detailsLoading = true;
      _detailsError = null;
    });

    final details = await context.read<MarketDataService>().fetchTwelveDataQuoteDetails(widget.symbol);
    if (!mounted) return;

    setState(() {
      _detailsLoading = false;
      if (details == null) {
        _detailsError = 'Company details unavailable right now.';
      } else {
        _details = details;
      }
    });
  }

  /// Fractional: a coin is a slice of a share, so 0.5 of a share is valid.
  double get _quantity {
    final parsed = double.tryParse(_quantityController.text.trim()) ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  int get _limitPrice {
    final parsed = int.tryParse(_priceController.text.trim()) ?? 0;
    return parsed < 1 ? 1 : parsed;
  }

  /// Market orders cross the spread; limit orders fill at their own price.
  int get _effectivePrice => _orderType == OrderType.market
      ? (_isBuy ? widget.askPrice : widget.bidPrice)
      : _limitPrice;

  int get _effectiveTotal => (_quantity * _effectivePrice).round();

  bool get _isBuy => _action == TradeAction.buy;
  bool get _isShort => _action == TradeAction.short;
  bool get _isCover => _action == TradeAction.cover;

  int get _dailyBorrowCost => _isShort ? ((
        _effectiveTotal * 0.0015
      )).round() : 0;

  /// True when a limit order would fill the instant it is placed: a buy limit
  /// at or above the ask, a sell limit at or below the bid.
  bool get _marketableNow {
    if (_orderType != OrderType.limit) {
      return true;
    }
    if (_isShort || _isCover) {
      return true;
    }
    return _isBuy
        ? _limitPrice >= widget.askPrice
        : _limitPrice <= widget.bidPrice;
  }

  /// True when the order rests as a working (pending) order rather than filling
  /// immediately. This is a normal, expected state — not an error.
  bool get _restsAsWorkingOrder =>
      _orderType == OrderType.limit && !_marketableNow && !_isShort && !_isCover;

  double get _maxQuantity {
    if (_isShort) {
      final price = _effectivePrice;
      return price <= 0 ? 0 : widget.availableGold / price;
    }
    if (_isCover) {
      return widget.ownedLots.abs();
    }
    if (!_isBuy) {
      return widget.ownedLots;
    }
    final price = _effectivePrice;
    return price <= 0 ? 0 : widget.availableGold / price;
  }

  /// Why this order genuinely cannot be placed, or null when it can.
  ///
  /// A non-marketable limit is *not* a block — it rests as a working order. The
  /// only real blocks are running out of gold on an immediate buy, or not
  /// owning the shares a sell (immediate or resting) needs to reserve.
  String? get _blockReason {
    if (_quantity <= 0) {
      return 'Enter a quantity greater than zero.';
    }
    if (_isCover) {
      final held = widget.ownedLots.abs();
      if (held <= 0) {
        return 'You are not short ${widget.symbol} right now.';
      }
      if (_quantity > held) {
        return 'You are only short ${formatShares(held)} share(s) of ${widget.symbol}.';
      }
      return null;
    }
    if (_isShort) {
      return null;
    }
    if (!_isBuy) {
      if (widget.ownedLots <= 0) {
        return 'You do not own any ${widget.symbol} to sell.';
      }
      if (_quantity > widget.ownedLots) {
        return 'You only own ${formatShares(widget.ownedLots)} share(s) to '
            'sell or reserve.';
      }
      return null;
    }
    // Buying. A resting buy reserves nothing now — it only needs gold when it
    // fills — so it is never blocked for affordability here.
    if (!_restsAsWorkingOrder) {
      if (widget.availableGold < _effectiveTotal) {
        return 'You need ${_effectiveTotal}g for this order — you have '
            '${widget.availableGold}g.';
      }
    }
    return null;
  }

  /// A friendly, non-blocking explanation shown when the order will rest.
  String? get _workingOrderNote {
    if (!_restsAsWorkingOrder) {
      return null;
    }
    return _isBuy
        ? 'Limit ${_limitPrice}g is below the ask (${widget.askPrice}g), so '
              'this rests as a working order and fills if ${widget.symbol} '
              'trades down to ${_limitPrice}g.'
        : 'Limit ${_limitPrice}g is above the bid (${widget.bidPrice}g), so '
              'this rests as a working order and fills if ${widget.symbol} '
              'trades up to ${_limitPrice}g.';
  }

  Future<void> _showShortingEducationDialog() async {
    if (_hideShortingWarning) {
      return;
    }

    var dontShowAgain = false;
    final acknowledged = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF14231B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
              contentTextStyle: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFD166),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Shorting is risky')),
                ],
              ),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shorting means borrowing shares and selling them now, then buying them back later. It can work well if the price falls, but it can also cause fast losses if the stock rises. Daily borrow costs and price swings are both real risks.',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Key risks:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('• Unlimited loss potential if price climbs.'),
                          Text('• Daily borrow interest can add up.'),
                          Text('• Covering at a higher price can erase gains fast.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: dontShowAgain,
                      onChanged: (value) {
                        setState(() => dontShowAgain = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF58C7FF),
                      checkColor: Colors.black,
                      title: const Text(
                        "Don't show again",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD166),
                    foregroundColor: const Color(0xFF1B1B1B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    'I understand',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (acknowledged == true && dontShowAgain) {
      await _saveShortingWarningPreference(true);
    }
  }

  void _nudgePrice(int direction) {
    // Prices are in the thousands of coins, so step by ~1% (min 1) instead of
    // a single coin, which would barely move the field.
    final step = math.max(1, (_limitPrice * 0.01).round());
    setState(() {
      _priceController.text =
          '${(_limitPrice + direction * step).clamp(1, 100000000)}';
    });
  }

  void _nudgeQuantity(double delta) {
    // Half-share steps so buying fractions (the point of the coin rate) is one
    // tap away, while whole-share counts still land on round numbers.
    final next = (_quantity + delta).clamp(0.5, 1000000.0);
    setState(() {
      _quantityController.text = formatShares(next);
    });
  }

  /// Sets the quantity to a fraction of the most that's affordable (buy) or
  /// held (sell). Rounded down to 2dp so "Max" can never land a hair over
  /// the balance and get rejected by [_blockReason].
  void _applyQuantityFraction(double fraction) {
    final max = _maxQuantity;
    if (max <= 0) {
      return;
    }
    final target = (max * fraction * 100).floor() / 100;
    setState(() {
      _quantityController.text = formatShares(math.max(0, target));
    });
  }

  @override
  Widget build(BuildContext context) {
    final blockReason = _blockReason;
    final workingNote = _workingOrderNote;
    final sideColor = switch (_action) {
      TradeAction.buy => const Color(0xFF85EFAC),
      TradeAction.sell => const Color(0xFFFF8A80),
      TradeAction.short => const Color(0xFFFFD166),
      TradeAction.cover => const Color(0xFF8BC6FF),
    };

    // Same backdrop pattern as the Market Board: art behind a transparent,
    // normally-laid-out Scaffold — never `extendBodyBehindAppBar`, which
    // pushes content up under the title.
    return Stack(
      children: [
        // Same welcome-screen backdrop recipe as the Market Board.
        Positioned.fill(
          child: Image.asset(
            AppAssets.villageMapBackground,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0C2418).withValues(alpha: 0.66),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.5),
                radius: 0.95,
                colors: [
                  const Color(0xFF78E08F).withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Icon(widget.icon, color: widget.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        widget.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _ChartSection(
                  candles: _candles,
                  fallbackSeries: widget.fallbackSeries,
                  loading: _loadingChart,
                  range: _range,
                  mode: _chartMode,
                  accent: widget.accent,
                  onRangeChanged: (range) {
                    setState(() => _range = range);
                    _loadChart();
                  },
                  onModeChanged: (mode) => setState(() => _chartMode = mode),
                  rangesEnabled: context.read<MarketDataService>().hasCandleKey,
                ),
                const SizedBox(height: 18),
                _QuoteRow(
                  bid: widget.bidPrice,
                  ask: widget.askPrice,
                  last: widget.lastPrice,
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _detailsExpanded ? 'Hide company details' : 'Show additional company details',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          _detailsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_detailsExpanded) ...[
                  const SizedBox(height: 12),
                  _CompanyDetailsSection(
                    details: _details,
                    loading: _detailsLoading,
                    error: _detailsError,
                  ),
                ],
                const SizedBox(height: 18),
                _LabelledRow(
                  label: 'Side',
                  child: _SideToggle(
                    action: _action,
                    canCover: widget.ownedLots < 0,
                    onChanged: (value) {
                      if (value == TradeAction.short) {
                        _showShortingEducationDialog();
                      }
                      setState(() => _action = value);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _LabelledRow(
                  label: 'Order Type',
                  child: _OrderTypeSelector(
                    value: _orderType,
                    onChanged: (value) => setState(() => _orderType = value),
                  ),
                ),
                if (_orderType == OrderType.limit) ...[
                  const SizedBox(height: 14),
                  _LabelledRow(
                    label: 'Limit Price',
                    child: _StepperField(
                      controller: _priceController,
                      accent: widget.accent,
                      suffix: 'g',
                      onDecrement: () => _nudgePrice(-1),
                      onIncrement: () => _nudgePrice(1),
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _LabelledRow(
                  label: 'Quantity',
                  child: _StepperField(
                    controller: _quantityController,
                    accent: widget.accent,
                    suffix: 'sh',
                    allowDecimal: true,
                    onDecrement: () => _nudgeQuantity(-0.5),
                    onIncrement: () => _nudgeQuantity(0.5),
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(height: 10),
                // Quick amounts. Without these the only way to size an order was
                // typing a number or tapping +0.5 — and since a share costs
                // thousands of coins while balances run into the millions, that
                // meant hundreds of taps to spend a meaningful amount. `_maxQuantity`
                // was already being computed and shown; this makes it usable.
                _QuickAmountRow(
                  accent: widget.accent,
                  isBuy: _isBuy,
                  enabled: _maxQuantity > 0,
                  onSelect: _applyQuantityFraction,
                ),
                const SizedBox(height: 18),
                _EstimateCard(
                  isBuy: _isBuy,
                  isShort: _isShort,
                  quantity: _quantity,
                  pricePerShare: _effectivePrice,
                  availableGold: widget.availableGold,
                  ownedLots: widget.ownedLots,
                  maxQuantity: _maxQuantity,
                ),
                if (_isShort) ...[
                  const SizedBox(height: 12),
                  _NoteCard(
                    text: 'Daily borrow cost estimate: ${_dailyBorrowCost}g (~0.15% of notional per day).',
                    color: const Color(0xFFE1BB72),
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
                if (blockReason != null) ...[
                  const SizedBox(height: 12),
                  _NoteCard(
                    text: blockReason,
                    color: const Color(0xFFFFB084),
                    icon: Icons.info_outline_rounded,
                  ),
                ] else if (workingNote != null) ...[
                  const SizedBox(height: 12),
                  _NoteCard(
                    text: workingNote,
                    color: const Color(0xFF58C7FF),
                    icon: Icons.schedule_rounded,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _restsAsWorkingOrder
                        ? const Color(0xFF58C7FF)
                        : sideColor,
                    foregroundColor: const Color(0xFF08251A),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.10,
                    ),
                    disabledForegroundColor: Colors.white38,
                  ),
                  onPressed: blockReason != null
                      ? null
                      : () => Navigator.of(context).pop(
                          OrderRequest(
                            action: _action,
                            quantity: _quantity,
                            pricePerShare: _effectivePrice,
                            isWorking: _restsAsWorkingOrder,
                          ),
                        ),
                  child: Text(
                    _restsAsWorkingOrder
                        ? 'Place ${_isBuy ? 'buy' : 'sell'} limit order'
                        : switch (_action) {
                            TradeAction.buy => 'Buy ${widget.symbol}',
                            TradeAction.sell => 'Sell ${widget.symbol}',
                            TradeAction.short => 'Short ${widget.symbol}',
                            TradeAction.cover => 'Cover ${widget.symbol}',
                          },
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.candles,
    required this.fallbackSeries,
    required this.loading,
    required this.range,
    required this.mode,
    required this.accent,
    required this.onRangeChanged,
    required this.onModeChanged,
    required this.rangesEnabled,
  });

  final List<Candle> candles;
  final List<double> fallbackSeries;
  final bool loading;
  final ChartRange range;
  final ChartMode mode;
  final Color accent;
  final ValueChanged<ChartRange> onRangeChanged;
  final ValueChanged<ChartMode> onModeChanged;

  /// False when no historical-data key is configured — every range would
  /// return the same empty result, so the buttons are disabled rather than
  /// silently doing nothing.
  final bool rangesEnabled;

  /// Without a historical-data key there are no OHLC bars, but the quote
  /// endpoint still gives real prices — show those as a flat-bodied series so
  /// the chart is never empty.
  List<Candle> get _effectiveCandles {
    if (candles.isNotEmpty) {
      return candles;
    }
    final now = DateTime.now();
    return [
      for (var i = 0; i < fallbackSeries.length; i++)
        Candle(
          time: now.subtract(Duration(minutes: fallbackSeries.length - i)),
          open: fallbackSeries[i],
          high: fallbackSeries[i],
          low: fallbackSeries[i],
          close: fallbackSeries[i],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasRealCandles = candles.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final option in ChartRange.values) ...[
                        _RangeChip(
                          label: option.label,
                          selected: option == range,
                          // Without a Twelve Data key `fetchCandles` returns
                          // an empty list for *every* range, so all five
                          // buttons produced the identical quote-derived
                          // shape and looked broken. Disabling them says so
                          // honestly — the alternative would be inventing
                          // price history, which this app must never do.
                          enabled: rangesEnabled,
                          onTap: rangesEnabled
                              ? () => onRangeChanged(option)
                              : null,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ModeToggle(mode: mode, onChanged: onModeChanged),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF58C7FF),
                      strokeWidth: 2,
                    ),
                  )
                : InteractivePriceChart(
                    candles: _effectiveCandles,
                    mode: mode,
                    accent: accent,
                  ),
          ),
          if (!loading && hasRealCandles) ...[
            const SizedBox(height: 8),
            Text(
              'Pinch to zoom • drag to pan • prices on the right',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10.5,
              ),
            ),
          ],
          if (!loading && !hasRealCandles) ...[
            const SizedBox(height: 10),
            Text(
              'Add a TWELVE_DATA_API_KEY for real ${range.label} history and '
              'candlestick bars.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small info panel — orange for a genuine block, blue for the (normal)
/// "this will rest as a working order" explanation.
/// 25% / 50% / 75% / Max — the standard sizing row every real trading app
/// has, and the thing that makes fractional-share buying usable here.
class _QuickAmountRow extends StatelessWidget {
  const _QuickAmountRow({
    required this.accent,
    required this.isBuy,
    required this.enabled,
    required this.onSelect,
  });

  final Color accent;
  final bool isBuy;
  final bool enabled;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = <(String, double)>[
      ('25%', 0.25),
      ('50%', 0.50),
      ('75%', 0.75),
      ('Max', 1.0),
    ];

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              label: isBuy
                  ? 'Buy ${options[i].$1} of what you can afford'
                  : 'Sell ${options[i].$1} of your position',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled
                    ? () {
                        HapticFeedback.selectionClick();
                        onSelect(options[i].$2);
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled
                        ? accent.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: enabled
                          ? accent.withValues(alpha: 0.38)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    options[i].$1,
                    style: TextStyle(
                      color: enabled
                          ? accent
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2F6BFF)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final ChartMode mode;
  final ValueChanged<ChartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in ChartMode.values)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: option == mode
                      ? const Color(0xFF2F6BFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  option == ChartMode.line
                      ? Icons.show_chart_rounded
                      : Icons.candlestick_chart_rounded,
                  size: 18,
                  color: option == mode ? Colors.white : Colors.white54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.bid, required this.ask, required this.last});

  final int bid;
  final int ask;
  final int last;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuoteChip(
            label: 'Bid',
            value: '${bid}g',
            color: const Color(0xFF85EFAC),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuoteChip(
            label: 'Ask',
            value: '${ask}g',
            color: const Color(0xFFFF8A80),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuoteChip(
            label: 'Last',
            value: '${last}g',
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _QuoteChip extends StatelessWidget {
  const _QuoteChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyDetailsSection extends StatelessWidget {
  const _CompanyDetailsSection({
    required this.details,
    required this.loading,
    required this.error,
  });

  final TwelveDataQuoteDetails? details;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF58C7FF),
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
        ),
        child: Text(
          error!,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    if (details == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Text(
          'Company details are not available for this stock.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final loadedDetails = details!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         // _DetailRow(label: 'Bid Size', value: loadedDetails.bidSize.toStringAsFixed(0)),
          //_DetailRow(label: 'Ask Size', value: loadedDetails.askSize.toStringAsFixed(0)),
          
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _DetailRow(label: 'Last Price', value: usdLabel(loadedDetails.price)),
              _DetailRow(label: 'Today High', value: usdLabel(loadedDetails.high)),
              _DetailRow(label: 'Today Low', value: usdLabel(loadedDetails.low)),
              _DetailRow(label: 'Volume', value: loadedDetails.volume.toStringAsFixed(0)),
              _DetailRow(label: 'Avg Volume', value: loadedDetails.averageVolume.toStringAsFixed(0)),
              //_DetailRow(label: 'Market Cap', value: _formatLargeNumber(loadedDetails.marketCap)),
              _DetailRow(label: '52 week Range', value: loadedDetails.fiftyTwoWeekRange),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelledRow extends StatelessWidget {
  const _LabelledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SideToggle extends StatelessWidget {
  const _SideToggle({
    required this.action,
    required this.canCover,
    required this.onChanged,
  });

  final TradeAction action;
  final bool canCover;
  final ValueChanged<TradeAction> onChanged;

  @override
  Widget build(BuildContext context) {
    final actions = <_SideOption>[
      _SideOption(
        label: 'Buy',
        selected: action == TradeAction.buy,
        color: const Color(0xFF00C287),
        value: TradeAction.buy,
      ),
      _SideOption(
        label: 'Sell',
        selected: action == TradeAction.sell,
        color: const Color(0xFFE1454A),
        value: TradeAction.sell,
      ),
      _SideOption(
        label: 'Short',
        selected: action == TradeAction.short,
        color: const Color(0xFFFFD166),
        value: TradeAction.short,
      ),
      if (canCover)
        _SideOption(
          label: 'Cover',
          selected: action == TradeAction.cover,
          color: const Color(0xFF8BC6FF),
          value: TradeAction.cover,
        ),
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final option in actions)
            Expanded(
              child: _SideHalf(
                label: option.label,
                selected: option.selected,
                color: option.color,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SideOption {
  const _SideOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.value,
  });

  final String label;
  final bool selected;
  final Color color;
  final TradeAction value;
}

class _SideHalf extends StatelessWidget {
  const _SideHalf({
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _OrderTypeSelector extends StatelessWidget {
  const _OrderTypeSelector({required this.value, required this.onChanged});

  final OrderType value;
  final ValueChanged<OrderType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrderType>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1C222B),
          iconEnabledColor: Colors.white54,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          items: const [
            DropdownMenuItem(value: OrderType.limit, child: Text('LIMIT')),
            DropdownMenuItem(value: OrderType.market, child: Text('MARKET')),
          ],
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.controller,
    required this.accent,
    required this.suffix,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
    this.allowDecimal = false,
  });

  final TextEditingController controller;
  final Color accent;
  final String suffix;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onChanged;

  /// Quantity allows fractional shares; price stays whole coins.
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.numberWithOptions(
                decimal: allowDecimal,
              ),
              inputFormatters: allowDecimal
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                  : [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                isDense: true,
                // All four must be cleared, not just `border`. The app theme
                // sets enabled/focused/error borders, and those still draw
                // even when `border` is none — which stacked a second
                // outline inside this field's own container border.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                suffixText: suffix,
                suffixStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDecrement,
            icon: const Icon(
              Icons.remove_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onIncrement,
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.isBuy,
    required this.isShort,
    required this.quantity,
    required this.pricePerShare,
    required this.availableGold,
    required this.ownedLots,
    required this.maxQuantity,
  });

  final bool isBuy;
  final bool isShort;
  final double quantity;
  final int pricePerShare;
  final int availableGold;
  final double ownedLots;
  final double maxQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          _EstimateLine(
            label: isBuy ? 'Estimated cost' : 'Estimated credit',
            value: '${(quantity * pricePerShare).round()}g',
            emphasise: true,
          ),
          const SizedBox(height: 10),
          _EstimateLine(label: 'Price per share', value: '${pricePerShare}g'),
          const SizedBox(height: 10),
          _EstimateLine(
            label: isBuy ? 'Available gold' : 'Shares owned',
            value: isBuy ? '${availableGold}g' : formatShares(ownedLots),
          ),
          if (isShort) ...[
            const SizedBox(height: 10),
            _EstimateLine(
              label: 'Daily borrow',
              value: '${((quantity * pricePerShare * 0.0015).round())}g',
            ),
          ],
          const SizedBox(height: 10),
          _EstimateLine(
            label: 'Max at this price',
            value: formatShares(maxQuantity),
          ),
        ],
      ),
    );
  }
}

class _EstimateLine extends StatelessWidget {
  const _EstimateLine({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: emphasise ? 0.85 : 0.6),
            fontWeight: emphasise ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasise ? const Color(0xFFE1BB72) : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: emphasise ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
