/// Number formatting shared across the app.
///
/// This exists because the same nine-line thousands-separator loop had been
/// written out three times — in `LifeMoneyPanel`, in `market_data_service`,
/// and again on the Past Lives screen — each a copy of the last. They agreed,
/// which is the only reason nobody noticed; the next one to be edited would
/// have made them disagree.
///
/// Deliberately hand-rolled rather than `intl`'s `NumberFormat`: the app
/// does not otherwise depend on `intl`, and pulling in a localisation stack
/// for a comma every three digits is not a trade worth making. If real
/// locale-aware formatting is ever needed, this is the one place to change.
library;

/// Groups an integer with commas: `1234567` → `1,234,567`.
///
/// Negative values keep the sign in front of the grouping (`-1,200`), which
/// is why the sign is stripped before the digits are walked — grouping the
/// `-` along with the digits shifts every separator by one.
String groupedNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
