import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// All reads/writes for marketplace data. Screens never talk to Supabase directly.
class DataService {
  DataService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static String? get uid => _db.auth.currentUser?.id;
  static bool get signedIn => uid != null;

  // ---------- Catalogue ----------
  static List<ServiceCategory>? _categoryCache;

  static Future<List<ServiceCategory>> categories({bool refresh = false}) async {
    if (_categoryCache != null && !refresh) return _categoryCache!;
    final rows = await _db.from('service_categories').select().order('sort', ascending: true);
    _categoryCache = rows.map(ServiceCategory.fromMap).toList();
    return _categoryCache!;
  }

  static Future<ServiceCategory?> categoryBySlug(String slug) async {
    final all = await categories();
    for (final c in all) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  static Future<List<ServiceCategory>> homeSection(String section) async {
    final all = await categories();
    return all.where((c) => c.homeSection == section).toList()..sort((a, b) => a.homeSort.compareTo(b.homeSort));
  }

  /// General offers (not tied to one service page).
  static Future<List<Offer>> offers({String? section}) async {
    var q = _db.from('offers').select().isFilter('service_slug', null);
    if (section != null) q = q.eq('section', section);
    final rows = await q.order('sort', ascending: true);
    return rows.map(Offer.fromMap).toList();
  }

  /// Banners shown at the top of a service page (falls back to general offers).
  static Future<List<Offer>> offersForService(String slug) async {
    final rows = await _db.from('offers').select().eq('service_slug', slug).order('sort', ascending: true);
    final list = rows.map(Offer.fromMap).toList();
    return list.isNotEmpty ? list : offers(section: 'latest');
  }

  // ---------- Pricing / booking ----------
  static Future<Quote> quote(String kind, Map<String, dynamic> details, {String? promo}) async {
    final res = await _db.rpc('quote_booking', params: {'p_kind': kind, 'p_details': details, 'p_promo': promo});
    return Quote.fromMap((res as Map).cast<String, dynamic>());
  }

  static Future<int> validatePromo(String code) async {
    final res = await _db.rpc('validate_promo', params: {'p_code': code});
    return (res as num?)?.toInt() ?? 0;
  }

  static Future<String> placeBooking({
    required String serviceSlug,
    required String kind,
    required Map<String, dynamic> details,
    required DateTime scheduledAt,
    required String timeSlot,
    required String address,
    double? lat,
    double? lng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? promo,
    required String paymentMethod,
    String? cardId,
  }) async {
    final res = await _db.rpc('place_booking', params: {
      'p_service_slug': serviceSlug,
      'p_kind': kind,
      'p_details': details,
      'p_promo': promo,
      'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'p_time_slot': timeSlot,
      'p_address': address,
      'p_lat': lat,
      'p_lng': lng,
      'p_dropoff_address': dropoffAddress,
      'p_dropoff_lat': dropoffLat,
      'p_dropoff_lng': dropoffLng,
      'p_payment_method': paymentMethod,
      'p_card_id': cardId,
    });
    return res as String;
  }

  static Future<List<Booking>> myBookings() async {
    if (uid == null) return [];
    final rows = await _db.from('bookings').select().eq('customer_id', uid!).order('created_at', ascending: false);
    return rows.map(Booking.fromMap).toList();
  }

  static Future<Booking?> booking(String id) async {
    final row = await _db.from('bookings').select().eq('id', id).maybeSingle();
    return row == null ? null : Booking.fromMap(row);
  }

  static Future<void> cancelBooking(String id) =>
      _db.from('bookings').update({'status': 'cancelled'}).eq('id', id);

  static Future<bool> hasReview(String bookingId) async {
    final rows = await _db.from('reviews').select('id').eq('booking_id', bookingId).limit(1);
    return rows.isNotEmpty;
  }

  static Future<void> submitReview(String bookingId, int rating, String comment) =>
      _db.from('reviews').insert({'booking_id': bookingId, 'user_id': uid, 'rating': rating, 'comment': comment});

  // ---------- Notifications ----------
  static Future<List<AppNotification>> myNotifications() async {
    if (uid == null) return [];
    final rows =
        await _db.from('notifications').select().eq('user_id', uid!).order('created_at', ascending: false).limit(50);
    return rows.map(AppNotification.fromMap).toList();
  }

  static Future<bool> hasUnread() async {
    if (uid == null) return false;
    final rows = await _db.from('notifications').select('id').eq('user_id', uid!).eq('is_read', false).limit(1);
    return rows.isNotEmpty;
  }

  static Future<void> markAllRead() async {
    if (uid == null) return;
    await _db.from('notifications').update({'is_read': true}).eq('user_id', uid!).eq('is_read', false);
  }

  // ---------- Profile ----------
  static Future<Map<String, dynamic>?> profile() async {
    if (uid == null) return null;
    return _db.from('profiles').select().eq('id', uid!).maybeSingle();
  }

  static Future<void> updateProfile(Map<String, dynamic> values) async {
    if (uid == null) return;
    await _db
        .from('profiles')
        .update({...values, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', uid!);
  }

  static Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}'),
        );
    final url = _db.storage.from('avatars').getPublicUrl(path);
    await updateProfile({'avatar_url': url});
    return url;
  }

  // ---------- Addresses ----------
  static Future<List<SavedAddress>> addresses() async {
    if (uid == null) return [];
    final rows = await _db.from('addresses').select().eq('user_id', uid!).order('created_at', ascending: true);
    return rows.map(SavedAddress.fromMap).toList();
  }

  static Future<SavedAddress> addAddress(String label, String address, double? lat, double? lng) async {
    // One home and one work address: replace the old one.
    if (label != 'other') {
      await _db.from('addresses').delete().eq('user_id', uid!).eq('label', label);
    }
    final row = await _db
        .from('addresses')
        .insert({'user_id': uid, 'label': label, 'address': address, 'lat': lat, 'lng': lng})
        .select()
        .single();
    return SavedAddress.fromMap(row);
  }

  static Future<void> deleteAddress(String id) => _db.from('addresses').delete().eq('id', id);

  // ---------- Cards (display data only; no full numbers or CVV) ----------
  static Future<List<PaymentCard>> cards() async {
    if (uid == null) return [];
    final rows = await _db.from('payment_cards').select().eq('user_id', uid!).order('created_at', ascending: true);
    return rows.map(PaymentCard.fromMap).toList();
  }

  static Future<PaymentCard> addCard({
    required String holder,
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
  }) async {
    final existing = await cards();
    final row = await _db
        .from('payment_cards')
        .insert({
          'user_id': uid,
          'holder': holder,
          'brand': brand,
          'last4': last4,
          'exp_month': expMonth,
          'exp_year': expYear,
          'is_default': existing.isEmpty,
        })
        .select()
        .single();
    return PaymentCard.fromMap(row);
  }

  static Future<void> deleteCard(String id) => _db.from('payment_cards').delete().eq('id', id);

  static Future<void> setDefaultCard(String id) async {
    await _db.from('payment_cards').update({'is_default': false}).eq('user_id', uid!);
    await _db.from('payment_cards').update({'is_default': true}).eq('id', id);
  }

  // ---------- Help ----------
  static Future<List<Faq>> faqs() async {
    final rows = await _db.from('faqs').select().order('category', ascending: false).order('sort', ascending: true);
    return rows.map(Faq.fromMap).toList();
  }

  static Stream<List<SupportMessage>> supportThread() {
    return _db
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid!)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(SupportMessage.fromMap).toList());
  }

  static Future<void> sendSupport(String body) =>
      _db.from('support_messages').insert({'user_id': uid, 'sender': 'user', 'body': body});
}
