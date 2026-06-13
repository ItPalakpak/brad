import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: 'PHP ',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatNoDecimal(double amount) {
    final fmt = NumberFormat.currency(
      locale: 'en_PH',
      symbol: 'PHP ',
      decimalDigits: 0,
    );
    return fmt.format(amount);
  }
}
