import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('MMM d').format(date); // e.g. Jun 13
  }

  static String formatFull(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date); // e.g. 2026-06-13 07:00
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date); // e.g. 2026-06-13
  }
}
