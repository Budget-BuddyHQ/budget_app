import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services_backend_and_other_services/market_data_service.dart';

/// Tickers with a real downloaded company logo (Wikimedia Commons — freely
/// licensed, used here only to identify the real public company each ticker
/// trades as) under `assets/images/stock_logos/`. Everything else falls back
/// to the Material-icon treatment above; this set is intentionally small and
/// curated rather than covering every symbol in the Market Board's symbol-style table.
const Set<String> kStockLogoSymbols = {
  'AAPL',
  'TSLA',
  'MSFT',
  'NVDA',
  'AMZN',
  'GOOGL',
};

String? stockLogoAssetFor(String symbol) => kStockLogoSymbols.contains(symbol)
    ? 'assets/images/stock_logos/$symbol.png'
    : null;

/// The mark for a ticker: the real company logo where we have one, the
/// symbol's Material icon otherwise.
///
/// **Why this is one widget.** The logo lookup existed but only the trending
/// strip ever called it, so Apple appeared as an apple on the promo card and
/// as a generic phone glyph in the search results, the ticker tape, the
/// stock card and the holdings list — the same company wearing five
/// different faces on one screen. A shared badge is what keeps them in step.
///
/// **Needs a [MarketDataService] ancestor.** It watches the service so a row
/// repaints the moment its fetched logo arrives, instead of holding a grey
/// glyph until something else happens to rebuild it. Every screen that shows
/// a ticker already has one.
///
/// Logos sit on a **white** plate. Several of these marks (Apple's,
/// Amazon's) are solid black and would nearly vanish against this app's dark
/// panels; real trading apps put a white circle behind ticker logos for the
/// same reason, whatever their own theme. The Material fallback keeps the
/// accent-tinted treatment instead, because a coloured glyph on white would
/// look like a broken image.
class SymbolBadge extends StatelessWidget {
  const SymbolBadge({
    super.key,
    required this.symbol,
    required this.icon,
    required this.accent,
    this.size = 44,
  });

  final String symbol;
  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size <= 20 ? size / 3 : size / 3.1;
    final asset = stockLogoAssetFor(symbol);

    // The fetched logo, if the market service has already loaded this
    // company's profile. Read through `watch` so a row rebuilds the moment
    // its logo arrives rather than staying a grey glyph until the next
    // scroll.
    final fetched = context
        .watch<MarketDataService>()
        .logoUrlFor(symbol);

    Widget fallback() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: accent, size: size * 0.5),
    );

    Widget plate(Widget child) => Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );

    // Bundled art first: it ships with the app, so it is instant and works
    // offline. The network logo is the long tail — six symbols were bundled
    // and the board trades dozens, which is why every other company was
    // showing a generic glyph while its real mark sat one field away in the
    // profile response the order ticket was already fetching.
    if (asset != null) {
      return plate(
        Image.asset(
          asset,
          fit: BoxFit.contain,
          // A missing file must not leave a broken-image glyph sitting in
          // the middle of a price row.
          errorBuilder: (_, _, _) =>
              Icon(icon, color: accent, size: size * 0.5),
        ),
      );
    }

    if (fetched != null) {
      return plate(
        Image.network(
          fetched,
          fit: BoxFit.contain,
          // No spinner: a logo is decoration, and a row of spinners in a
          // price list reads as the prices being unavailable.
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const SizedBox.shrink(),
          errorBuilder: (_, _, _) =>
              Icon(icon, color: accent, size: size * 0.5),
        ),
      );
    }

    return fallback();
  }
}
