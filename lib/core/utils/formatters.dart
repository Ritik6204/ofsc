import 'package:intl/intl.dart';

class Formatters {
  static final _qty = NumberFormat('#,##0.##');
  static final _date = DateFormat('dd MMM yyyy');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final _time = DateFormat('hh:mm a');
  static final _day = DateFormat('dd MMM');

  static String quantity(num value) => _qty.format(value);

  static String qtyUnit(num value, String unit) =>
      '${quantity(value)} $unit';

  static String date(DateTime value) => _date.format(value.toLocal());

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  static String day(DateTime value) => _day.format(value.toLocal());

  static String relative(DateTime value, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final local = value.toLocal();
    final diff = current.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && current.day == local.day) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 48) return 'Yesterday';
    return date(local);
  }

  static String lastSynced(DateTime? value) {
    if (value == null) return 'Not synced yet';
    final local = value.toLocal();
    final now = DateTime.now();
    final prefix = now.day == local.day && now.difference(local).inHours < 24
        ? 'Today'
        : date(local);
    return '$prefix, ${_time.format(local)}';
  }

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
