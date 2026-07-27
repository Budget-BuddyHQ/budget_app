import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../services_backend_and_other_services/market_data_service.dart';

/// Read-only panel showing real stock prices from Finnhub.
///
/// Deliberately separate from the trading board: the tradeable stocks stay
/// simulated so the game economy remains balanced and playable at any hour,
/// while this panel connects those mechanics to companies a teenager actually
/// recognises. It self-hides when no API key is configured, so the app is
/// fully functional with zero setup.
class LiveMarketPanel extends StatefulWidget {
  const LiveMarketPanel({super.key});

  @override
  State<LiveMarketPanel> createState() => _LiveMarketPanelState();
}

class _LiveMarketPanelState extends State<LiveMarketPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MarketDataService>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketDataService>(
      builder: (context, service, _) {
        // No key configured is a supported, silent state — not an error worth
        // showing a teenager a broken-looking panel over.
        if (service.status == LiveMarketStatus.noApiKey) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFF58C7FF).withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    color: Color(0xFF58C7FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real Market Today',
                      style: GoogleFonts.baloo2(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (service.status == LiveMarketStatus.loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF58C7FF),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Refresh live prices',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => service.refresh(force: true),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF58C7FF),
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'These are real companies with real prices. Notice how small '
                'the daily moves are compared to the game board.',
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.66),
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              if (service.status == LiveMarketStatus.unavailable)
                _UnavailableNote(detail: service.errorDetail)
              else if (service.quotes.isEmpty)
                const _LoadingRows()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Two columns once there is room, so a tablet or landscape
                    // phone does not leave half the panel empty.
                    final columns = constraints.maxWidth >= 520 ? 2 : 1;
                    final quotes = service.quotes;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: quotes.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 62,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) =>
                          _QuoteRow(quote: quotes[index]),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quote});

  final LiveQuote quote;

  @override
  Widget build(BuildContext context) {
    final color = quote.isUp
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  quote.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  quote.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$${quote.current.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    quote.isUp
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: color,
                    size: 16,
                  ),
                  Text(
                    '${quote.percentChange.abs().toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (i != 2) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _UnavailableNote extends StatelessWidget {
  const _UnavailableNote({this.detail});

  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB084).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB084).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFFFB084),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail == null
                  ? 'Live prices are unavailable right now. The game board '
                        'below still works normally.'
                  : '$detail The game board below still works normally.',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
