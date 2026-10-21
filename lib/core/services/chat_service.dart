import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pro_models.dart';

/// In-app chat between a customer and the professional on a booking.
/// Contact details are hidden by the server before messages are stored.
class ChatService {
  ChatService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static String get uid => _db.auth.currentUser!.id;

  static const maxBytes = 20 * 1024 * 1024;
  static const maxVideo = Duration(minutes: 5);

  static Stream<List<ChatMessage>> thread(String bookingId) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('booking_id', bookingId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ChatMessage.fromMap).toList());

  static Future<void> sendText(String bookingId, String text) =>
      _db.from('messages').insert({'booking_id': bookingId, 'sender_id': uid, 'kind': 'text', 'body': text.trim()});

  static Future<void> sendMedia(String bookingId, Uint8List bytes, String ext, {required bool video}) async {
    if (bytes.length > maxBytes) throw Exception('Files must be 20 MB or smaller');
    final path = '$bookingId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('chat-media').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: _mime(ext, video)));
    await _db.from('messages').insert({'booking_id': bookingId, 'sender_id': uid, 'kind': video ? 'video' : 'image', 'media_path': path});
  }

  /// Latest message per booking, for the conversations list.
  static Future<Map<String, ChatMessage>> latest(List<String> bookingIds) async {
    if (bookingIds.isEmpty) return {};
    final rows = await _db.from('messages').select().inFilter('booking_id', bookingIds).order('created_at', ascending: false).limit(300);
    final out = <String, ChatMessage>{};
    for (final r in rows) {
      out.putIfAbsent(r['booking_id'] as String, () => ChatMessage.fromMap(r));
    }
    return out;
  }

  static final _urlCache = <String, String>{};

  static Future<String> mediaUrl(String path) async {
    final cached = _urlCache[path];
    if (cached != null) return cached;
    final url = await _db.storage.from('chat-media').createSignedUrl(path, 60 * 60 * 6);
    _urlCache[path] = url;
    return url;
  }

  static Future<Party?> party(String bookingId) async {
    final res = await _db.rpc('booking_party', params: {'p_booking': bookingId});
    if (res == null) return null;
    return Party((res as Map).cast<String, dynamic>());
  }

  static String _mime(String ext, bool video) {
    if (video) {
      return switch (ext) { 'mov' => 'video/quicktime', 'webm' => 'video/webm', '3gp' => 'video/3gpp', 'mkv' => 'video/x-matroska', _ => 'video/mp4' };
    }
    return switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', 'gif' => 'image/gif', _ => 'image/jpeg' };
  }
}
