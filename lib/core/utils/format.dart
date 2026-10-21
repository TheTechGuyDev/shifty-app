import 'package:intl/intl.dart';

import '../config/app_config.dart';

final _money = NumberFormat('#,##0', 'en_US');

String money(num? v) => '${AppConfig.currency}${_money.format(v ?? 0)}';

String longDate(DateTime d) => DateFormat('EEEE, MMM d, y').format(d);
String shortDate(DateTime d) => DateFormat('EEE, MMM d').format(d);
String timeOf(DateTime d) => DateFormat('h:mm a').format(d);

String friendlyDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  return longDate(d);
}

String distanceLabel(double meters) =>
    meters < 1000 ? '${meters.round()}m' : '${(meters / 1000).toStringAsFixed(1)}km';
