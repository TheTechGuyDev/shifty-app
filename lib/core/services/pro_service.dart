import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../models/pro_models.dart';

/// Data access for the professional side.
class ProService {
  ProService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static String get uid => _db.auth.currentUser!.id;

  // ---------- Role / mode ----------
  static Future<void> becomeProfessional() => _db.rpc('become_professional');
  static Future<void> setMode(String mode) => _db.rpc('set_active_mode', params: {'p_mode': mode});

  // ---------- Profile ----------
  static Future<ProProfile?> me() async {
    final row = await _db.from('professional_profiles').select().eq('user_id', uid).maybeSingle();
    return row == null ? null : ProProfile(row);
  }

  static Future<void> update(Map<String, dynamic> values) =>
      _db.from('professional_profiles').update({...values, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('user_id', uid);

  static Future<void> submitApplication() => _db.rpc('pro_submit_application');
  static Future<void> selfApprove() => _db.rpc('pro_self_approve');

  static Future<bool> selfApprovalAllowed() async {
    final row = await _db.from('app_settings').select('value').eq('key', 'allow_self_approval').maybeSingle();
    return row?['value'] == true;
  }

  // ---------- Services ----------
  static Future<List<OfferedService>> services() async {
    final rows = await _db.from('pro_services').select().eq('pro_id', uid);
    return rows.map(OfferedService.fromMap).toList();
  }

  static Future<void> saveServices(List<OfferedService> list) async {
    final keep = list.map((s) => s.categoryId).toList();
    final existing = await services();
    for (final e in existing) {
      if (!keep.contains(e.categoryId)) await _db.from('pro_services').delete().eq('id', e.id!);
    }
    if (list.isEmpty) return;
    await _db.from('pro_services').upsert(
      [
        for (final s in list)
          {
            'pro_id': uid,
            'category_id': s.categoryId,
            'pricing_type': s.pricingType,
            'price': s.pricingType == 'quote' ? null : s.price,
            'description': s.description,
            'is_active': s.isActive,
          }
      ],
      onConflict: 'pro_id,category_id',
    );
  }

  // ---------- Availability ----------
  static Future<List<DayHours>> hours() async {
    final rows = await _db.from('availability').select().eq('pro_id', uid).order('weekday', ascending: true);
    final list = rows.map(DayHours.fromMap).toList();
    for (var d = 1; d <= 7; d++) {
      if (!list.any((h) => h.weekday == d)) list.add(DayHours(weekday: d, enabled: d <= 6, start: '08:00', end: '18:00'));
    }
    list.sort((a, b) => a.weekday.compareTo(b.weekday));
    return list;
  }

  static Future<void> saveHours(List<DayHours> list) => _db.from('availability').upsert([
        for (final h in list)
          {'pro_id': uid, 'weekday': h.weekday, 'enabled': h.enabled, 'start_time': h.start, 'end_time': h.end}
      ]);

  static Future<List<(String, DateTime, String?)>> blockedDates() async {
    final rows = await _db.from('blocked_dates').select().eq('pro_id', uid).order('day', ascending: true);
    return rows.map((r) => (r['id'] as String, DateTime.parse(r['day'] as String), r['reason'] as String?)).toList();
  }

  static Future<void> blockDate(DateTime day, String? reason) => _db.from('blocked_dates').upsert(
      {'pro_id': uid, 'day': '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}', 'reason': reason},
      onConflict: 'pro_id,day');

  static Future<void> unblock(String id) => _db.from('blocked_dates').delete().eq('id', id);

  // ---------- Verification documents ----------
  static Future<List<VerificationDoc>> documents() async {
    final rows = await _db.from('verification_documents').select().eq('pro_id', uid).order('created_at', ascending: true);
    return rows.map(VerificationDoc.fromMap).toList();
  }

  static Future<void> uploadDocument(String kind, String title, Uint8List bytes, String ext) async {
    final path = '$uid/${kind}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('documents').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: _mime(ext)));
    await _db.from('verification_documents').insert({'pro_id': uid, 'kind': kind, 'title': title, 'file_path': path});
  }

  static Future<void> deleteDocument(String id) => _db.from('verification_documents').delete().eq('id', id);

  // ---------- Portfolio / team ----------
  static Future<List<PortfolioItem>> portfolio([String? proId]) async {
    final rows = await _db.from('portfolio_items').select().eq('pro_id', proId ?? uid).order('created_at', ascending: false);
    return rows.map(PortfolioItem.fromMap).toList();
  }

  static Future<String> uploadPublic(String bucket, Uint8List bytes, String ext) async {
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from(bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: _mime(ext)));
    return _db.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> addPortfolio(Uint8List bytes, String ext, String? caption) async {
    final url = await uploadPublic('portfolio', bytes, ext);
    await _db.from('portfolio_items').insert({'pro_id': uid, 'image_url': url, 'caption': caption});
  }

  static Future<void> deletePortfolio(String id) => _db.from('portfolio_items').delete().eq('id', id);

  static Future<List<TeamMember>> team() async {
    final rows = await _db.from('team_members').select().eq('pro_id', uid).order('created_at', ascending: true);
    return rows.map(TeamMember.fromMap).toList();
  }

  static Future<void> addTeamMember(String name, String? phone, String? role) =>
      _db.from('team_members').insert({'pro_id': uid, 'name': name, 'phone': phone, 'role': role});

  static Future<void> removeTeamMember(String id) => _db.from('team_members').delete().eq('id', id);

  // ---------- Jobs ----------
  /// Open requests sent to me (booking still waiting for a pro).
  static Future<List<(JobOffer, Booking)>> requests() async {
    final offers = await _db.from('booking_offers').select().eq('pro_id', uid).inFilter('status', ['sent', 'quoted']).order('created_at', ascending: false);
    final result = <(JobOffer, Booking)>[];
    if (offers.isEmpty) return result;
    final ids = offers.map((o) => o['booking_id'] as String).toList();
    final bookings = await _db.from('bookings').select().inFilter('id', ids).eq('status', 'pending');
    final byId = {for (final b in bookings) b['id'] as String: Booking.fromMap(b)};
    for (final o in offers) {
      final b = byId[o['booking_id']];
      if (b != null) result.add((JobOffer.fromMap(o), b));
    }
    return result;
  }

  static Future<JobOffer?> myOffer(String bookingId) async {
    final row = await _db.from('booking_offers').select().eq('booking_id', bookingId).eq('pro_id', uid).maybeSingle();
    return row == null ? null : JobOffer.fromMap(row);
  }

  static Future<List<Booking>> myJobs() async {
    final rows = await _db.from('bookings').select().eq('professional_id', uid).order('scheduled_at', ascending: true);
    return rows.map(Booking.fromMap).toList();
  }

  static Stream<List<Map<String, dynamic>>> offersStream() =>
      _db.from('booking_offers').stream(primaryKey: ['id']).eq('pro_id', uid);

  static Future<void> accept(String bookingId) => _db.rpc('pro_accept_job', params: {'p_booking': bookingId});
  static Future<void> decline(String bookingId) => _db.rpc('pro_decline_job', params: {'p_booking': bookingId});
  static Future<void> quote(String bookingId, num amount, String note) =>
      _db.rpc('pro_send_quote', params: {'p_booking': bookingId, 'p_amount': amount, 'p_note': note});
  static Future<void> progress(String bookingId, String stage) =>
      _db.rpc('pro_update_progress', params: {'p_booking': bookingId, 'p_stage': stage});
  static Future<void> requestReschedule(String bookingId, DateTime at, String note) => _db.rpc('pro_request_reschedule',
      params: {'p_booking': bookingId, 'p_new': at.toUtc().toIso8601String(), 'p_note': note});

  static Future<void> addJobPhoto(String bookingId, Uint8List bytes, String ext, bool before) async {
    final url = await uploadPublic('job-photos', bytes, ext);
    await _db.rpc('pro_add_job_photo', params: {'p_booking': bookingId, 'p_url': url, 'p_when': before ? 'before' : 'after'});
  }

  static Future<Map<String, dynamic>> bookingRaw(String id) async =>
      (await _db.from('bookings').select().eq('id', id).single());

  // ---------- Money ----------
  static Future<Map<String, dynamic>> stats() async => ((await _db.rpc('pro_stats')) as Map).cast<String, dynamic>();

  static Future<List<Payout>> payouts() async {
    final rows = await _db.from('payouts').select().eq('pro_id', uid).order('created_at', ascending: false);
    return rows.map(Payout.fromMap).toList();
  }

  static Future<void> requestPayout(num amount) => _db.rpc('request_payout', params: {'p_amount': amount});

  static Future<List<Booking>> completedJobs() async {
    final rows = await _db.from('bookings').select().eq('professional_id', uid).eq('status', 'done').order('completed_at', ascending: false);
    return rows.map(Booking.fromMap).toList();
  }

  // ---------- Reputation ----------
  static Future<List<ProReview>> reviews([String? proId]) async {
    final rows = await _db.from('reviews').select().eq('professional_id', proId ?? uid).order('created_at', ascending: false);
    return rows.map(ProReview.fromMap).toList();
  }

  static Future<void> reply(String reviewId, String text) => _db.rpc('reply_review', params: {'p_review': reviewId, 'p_reply': text});

  static Future<List<Map<String, dynamic>>> customers() async =>
      ((await _db.rpc('pro_customers')) as List).cast<Map<String, dynamic>>();

  // ---------- Public profile ----------
  static Future<Map<String, dynamic>?> publicProfile({String? slug, String? userId}) async {
    var q = _db.from('public_professionals').select();
    if (slug != null) q = q.eq('slug', slug);
    if (userId != null) q = q.eq('user_id', userId);
    return q.maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> publicServices(String proId) async =>
      await _db.from('pro_services').select('*, service_categories(name, icon, color)').eq('pro_id', proId).eq('is_active', true);

  static String _mime(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        _ => 'image/jpeg',
      };
}
