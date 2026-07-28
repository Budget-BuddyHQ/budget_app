import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Working (resting limit) orders move real gold and shares, so their
/// accounting is worth pinning down. These run against SupabaseService in its
/// offline/local mode (no keys in the test env), where saves just cache.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  UserStatsController freshController() =>
      UserStatsController(service: SupabaseService.instance);

  test('a buy limit below the ask rests instead of being rejected', () async {
    final controller = freshController();
    final startGold = controller.stats.gold;

    final result = await controller.placeWorkingOrder(
      symbol: 'AAPL',
      isBuy: true,
      quantity: 2,
      limitPrice: 100,
      companyName: 'Apple',
    );

    expect(result.success, isTrue);
    expect(controller.stats.workingOrders, hasLength(1));
    // A resting buy reserves nothing up front — gold only moves on fill.
    expect(controller.stats.gold, startGold);
    expect(controller.stats.holdings['stock_AAPL'] ?? 0, 0);
  });

  test('a buy limit fills once the price falls to it', () async {
    final controller = freshController();
    final startGold = controller.stats.gold;
    await controller.placeWorkingOrder(
      symbol: 'AAPL',
      isBuy: true,
      quantity: 2,
      limitPrice: 100,
      companyName: 'Apple',
    );

    final fills = await controller.settleWorkingOrders(<String, int>{'AAPL': 90});

    expect(fills, 1);
    expect(controller.stats.workingOrders, isEmpty);
    expect(controller.stats.holdings['stock_AAPL'], 2);
    expect(controller.stats.gold, startGold - 200);
    expect(
      controller.stats.transactions.any((t) => t.title == 'Bought AAPL'),
      isTrue,
    );
  });

  test('a buy limit stays working while the price is above it', () async {
    final controller = freshController();
    await controller.placeWorkingOrder(
      symbol: 'AAPL',
      isBuy: true,
      quantity: 1,
      limitPrice: 100,
      companyName: 'Apple',
    );

    final fills = await controller.settleWorkingOrders(<String, int>{
      'AAPL': 120,
    });

    expect(fills, 0);
    expect(controller.stats.workingOrders, hasLength(1));
  });

  test('a sell limit reserves shares and fills when the price rises', () async {
    final controller = freshController();
    await controller.buyStockLot(
      symbol: 'AAPL',
      goldCost: 300,
      companyName: 'Apple',
      quantity: 3,
    );
    expect(controller.stats.holdings['stock_AAPL'], 3);
    final goldAfterBuy = controller.stats.gold;

    await controller.placeWorkingOrder(
      symbol: 'AAPL',
      isBuy: false,
      quantity: 2,
      limitPrice: 500,
      companyName: 'Apple',
    );
    // The two reserved shares leave the live holding immediately.
    expect(controller.stats.holdings['stock_AAPL'], 1);

    final fills = await controller.settleWorkingOrders(<String, int>{
      'AAPL': 500,
    });

    expect(fills, 1);
    expect(controller.stats.workingOrders, isEmpty);
    expect(controller.stats.gold, goldAfterBuy + 1000);
  });

  test('fractional shares: buying 0.5 of a share is recorded as 0.5', () async {
    final controller = freshController();
    final startGold = controller.stats.gold;

    // At 10 coins = $1 a share is thousands of coins, so a few thousand coins
    // buys a slice of one — that slice must persist as a fraction.
    final result = await controller.buyStockLot(
      symbol: 'AAPL',
      goldCost: 1685,
      companyName: 'Apple',
      quantity: 0.5,
    );

    expect(result.success, isTrue);
    expect(controller.stats.holdings['stock_AAPL'], 0.5);
    expect(controller.stats.gold, startGold - 1685);
  });

  test('cancelling a sell limit gives the reserved shares back', () async {
    final controller = freshController();
    await controller.buyStockLot(
      symbol: 'AAPL',
      goldCost: 300,
      companyName: 'Apple',
      quantity: 3,
    );
    await controller.placeWorkingOrder(
      symbol: 'AAPL',
      isBuy: false,
      quantity: 2,
      limitPrice: 500,
      companyName: 'Apple',
    );
    expect(controller.stats.holdings['stock_AAPL'], 1);

    final id = controller.stats.workingOrders.first.id;
    await controller.cancelWorkingOrder(id);

    expect(controller.stats.workingOrders, isEmpty);
    expect(controller.stats.holdings['stock_AAPL'], 3);
  });
}
