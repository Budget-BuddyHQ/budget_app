import 'package:budget_app/services_backend_and_other_services/market_data_service.dart'
    show coinLabel;
import 'package:budget_app/utils/number_format.dart';
import 'package:budget_app/widgets_custom_lotties/life_money_panel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three copies of this grouping loop existed before it was consolidated —
/// in `LifeMoneyPanel`, `market_data_service` and the Past Lives screen. They
/// happened to agree; the next edit to any one of them would have broken
/// that. These pin the behaviour so the shared version can't drift.
void main() {
  group('groupedNumber', () {
    test('leaves short numbers alone', () {
      expect(groupedNumber(0), '0');
      expect(groupedNumber(7), '7');
      expect(groupedNumber(999), '999');
    });

    test('groups at every third digit', () {
      expect(groupedNumber(1000), '1,000');
      expect(groupedNumber(12345), '12,345');
      expect(groupedNumber(999999), '999,999');
      expect(groupedNumber(1000000), '1,000,000');
      expect(groupedNumber(1234567890), '1,234,567,890');
    });

    test('keeps the sign outside the grouping', () {
      // Grouping the '-' along with the digits shifts every separator by
      // one, which is the bug this ordering exists to avoid.
      expect(groupedNumber(-1), '-1');
      expect(groupedNumber(-1200), '-1,200');
      expect(groupedNumber(-1000000), '-1,000,000');
    });
  });

  group('callers agree with the shared helper', () {
    test('LifeMoneyPanel.coinsLabel delegates', () {
      for (final value in <int>[0, 5, 999, 1000, -1200, 1234567]) {
        expect(LifeMoneyPanel.coinsLabel(value), groupedNumber(value));
      }
    });

    test('coinLabel groups and suffixes with g', () {
      expect(coinLabel(3382), '3,382g');
      expect(coinLabel(0), '0g');
      expect(coinLabel(-1500), '-1,500g');
    });

    test('coinLabel rounds a fractional coin amount', () {
      expect(coinLabel(1999.6), '2,000g');
      expect(coinLabel(1999.4), '1,999g');
    });
  });
}
