import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../services_backend_and_other_services/market_data_service.dart';
import '../../../widgets_custom_lotties/price_chart.dart';

/// What kind of order the player is placing.
///
/// A market order crosses the spread and fills now. A limit order fills now if
/// it is already marketable; if it isn't (a buy below the ask, a sell above the
/// bid) it *rests as a working order* and fills later when the price comes to
/// it — which is the entire point of a limit order.
enum OrderType { market, limit }

/// The order handed back to the caller, which owns the gold/holdings.
@immutable
class OrderRequest {
  const OrderRequest({
    required this.isBuy,
    required this.quantity,
    required this.pricePerShare,
    this.isWorking = false,
  });

  final bool isBuy;

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
  late bool _isBuy = widget.startAsBuy;
  OrderType _orderType = OrderType.limit;
  ChartRange _range = ChartRange.day1;
  ChartMode _chartMode = ChartMode.line;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  List<Candle> _candles = const <Candle>[];
  bool _loadingChart = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = '${widget.lastPrice}';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChart());
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

  /// True when a limit order would fill the instant it is placed: a buy limit
  /// at or above the ask, a sell limit at or below the bid.
  bool get _marketableNow {
    if (_orderType != OrderType.limit) {
      return true;
    }
    return _isBuy
        ? _limitPrice >= widget.askPrice
        : _limitPrice <= widget.bidPrice;
  }

  /// True when the order rests as a working (pending) order rather than filling
  /// immediately. This is a normal, expected state — not an error.
  bool get _restsAsWorkingOrder =>
      _orderType == OrderType.limit && !_marketableNow;

  double get _maxQuantity {
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

  @override
  Widget build(BuildContext context) {
    final blockReason = _blockReason;
    final workingNote = _workingOrderNote;
    final sideColor = _isBuy
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
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
            ),
            const SizedBox(height: 18),
            _QuoteRow(
              bid: widget.bidPrice,
              ask: widget.askPrice,
              last: widget.lastPrice,
            ),
            const SizedBox(height: 18),
            _LabelledRow(
              label: 'Side',
              child: _SideToggle(
                isBuy: _isBuy,
                onChanged: (value) => setState(() => _isBuy = value),
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
            const SizedBox(height: 18),
            _EstimateCard(
              isBuy: _isBuy,
              quantity: _quantity,
              pricePerShare: _effectivePrice,
              availableGold: widget.availableGold,
              ownedLots: widget.ownedLots,
              maxQuantity: _maxQuantity,
            ),
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
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
                disabledForegroundColor: Colors.white38,
              ),
              onPressed: blockReason != null
                  ? null
                  : () => Navigator.of(context).pop(
                      OrderRequest(
                        isBuy: _isBuy,
                        quantity: _quantity,
                        pricePerShare: _effectivePrice,
                        isWorking: _restsAsWorkingOrder,
                      ),
                    ),
              child: Text(
                _restsAsWorkingOrder
                    ? 'Place ${_isBuy ? 'buy' : 'sell'} limit order'
                    : '${_isBuy ? 'Buy' : 'Sell'} ${widget.symbol}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
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
  });

  final List<Candle> candles;
  final List<double> fallbackSeries;
  final bool loading;
  final ChartRange range;
  final ChartMode mode;
  final Color accent;
  final ValueChanged<ChartRange> onRangeChanged;
  final ValueChanged<ChartMode> onModeChanged;

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
                          onTap: () => onRangeChanged(option),
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
  const _SideToggle({required this.isBuy, required this.onChanged});

  final bool isBuy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SideHalf(
              label: 'Buy',
              selected: isBuy,
              color: const Color(0xFF00C287),
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SideHalf(
              label: 'Sell',
              selected: !isBuy,
              color: const Color(0xFFE1454A),
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
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
                border: InputBorder.none,
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
    required this.quantity,
    required this.pricePerShare,
    required this.availableGold,
    required this.ownedLots,
    required this.maxQuantity,
  });

  final bool isBuy;
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
