import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _nairaFormat = NumberFormat('#,##0', 'en_US');

  static String formatNaira(num amount) {
    return '₦${_nairaFormat.format(amount)}';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy · h:mm a').format(date.toLocal());
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('h:mm a').format(date.toLocal());
  }
}
