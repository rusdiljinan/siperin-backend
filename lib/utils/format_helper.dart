import 'package:intl/intl.dart';

class FormatHelper {
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _date = DateFormat('dd MMMM yyyy', 'id_ID');

  static String currency(num value) => _currency.format(value);
  static String dateTime(DateTime dt) => _dateTime.format(dt);
  static String date(DateTime dt) => _date.format(dt);

  /// Format DateTime as relative time (e.g., "5 minutes ago", "2 hours ago")
  static String relativeDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'baru saja';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'menit' : 'menit'} yang lalu';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'jam' : 'jam'} yang lalu';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'hari' : 'hari'} yang lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'minggu' : 'minggu'} yang lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'bulan' : 'bulan'} yang lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'tahun' : 'tahun'} yang lalu';
    }
  }
}
