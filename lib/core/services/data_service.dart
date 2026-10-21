import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// All reads/writes for marketplace data. Screens never talk to Supabase directly.
class DataService {
  DataService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  static List<ServiceCategory>? _categoryCache;

  static Future<List<ServiceCategory>> categories({bool refresh = false}) async {
    if (_categoryCache != null && !refresh) return _categoryCache!;
    final rows = await _db.from('service_categories').select().order('sort');
    _categoryCache = rows.map(ServiceCategory.fromMap).toList();
    return _categoryCache!;
  }

  static Future<List<ServiceCategory>> homeSection(String section) async {
    final all = await categories();
    return all.where((c) => c.homeSection == section).toList()..sort((a, b) => a.homeSort.compareTo(b.homeSort));
  }

  static Future<List<Offer>> offers({String? section}) async {
    var q = _db.from('offers').select();
    if (section != null) q = q.eq('section', section);
    final rows = await q.order('sort');
    return rows.map(Offer.fromMap).toList();
  }

  static Future<List<Booking>> myBookings() async {
    if (_uid == null) return [];
    final rows = await _db.from('bookings').select().eq('customer_id', _uid!).order('created_at', ascending: false);
    return rows.map(Booking.fromMap).toList();
  }

  static Future<List<AppNotification>> myNotifications() async {
    if (_uid == null) return [];
    final rows = await _db.from('notifications').select().eq('user_id', _uid!).order('created_at', ascending: false).limit(50);
    return rows.map(AppNotification.fromMap).toList();
  }

  static Future<bool> hasUnread() async {
    if (_uid == null) return false;
    final rows = await _db.from('notifications').select('id').eq('user_id', _uid!).eq('is_read', false).limit(1);
    return rows.isNotEmpty;
  }

  static Future<void> markAllRead() async {
    if (_uid == null) return;
    await _db.from('notifications').update({'is_read': true}).eq('user_id', _uid!).eq('is_read', false);
  }

  static Future<void> cancelBooking(String id) =>
      _db.from('bookings').update({'status': 'cancelled'}).eq('id', id);
}
