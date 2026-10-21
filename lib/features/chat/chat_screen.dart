import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/models.dart';
import '../../core/models/pro_models.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/data_service.dart';
import '../../core/services/pro_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../booking/booking_widgets.dart';
import '../pro/pro_widgets.dart';

/// Real-time chat for one booking. Contact details are hidden by the server.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.bookingId, required this.title, this.subtitle});
  final String bookingId;
  final String title;
  final String? subtitle;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  late final Stream<List<ChatMessage>> _stream = ChatService.thread(widget.bookingId);
  bool _sending = false;
  String? _uploading;
  int _count = 0;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ChatService.sendText(widget.bookingId, t);
      _text.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb) MenuTile(icon: Icons.photo_camera_rounded, title: 'Take a photo', onTap: () => Navigator.pop(context, 'camera')),
              MenuTile(icon: Icons.photo_library_rounded, title: 'Photo from gallery', onTap: () => Navigator.pop(context, 'photo')),
              if (!kIsWeb) MenuTile(icon: Icons.videocam_rounded, title: 'Record a video', subtitle: 'Up to 5 minutes', onTap: () => Navigator.pop(context, 'record')),
              MenuTile(icon: Icons.video_library_rounded, title: 'Video from gallery', subtitle: 'Up to 5 minutes and 20 MB', onTap: () => Navigator.pop(context, 'video')),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    final video = choice == 'record' || choice == 'video';
    final XFile? f = video
        ? await picker.pickVideo(source: choice == 'record' ? ImageSource.camera : ImageSource.gallery, maxDuration: ChatService.maxVideo)
        : await picker.pickImage(source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery, maxWidth: 1800, imageQuality: 80);
    if (f == null) return;

    final size = await f.length();
    if (size > ChatService.maxBytes) {
      if (mounted) showAppSnack(context, 'Files must be 20 MB or smaller. This one is ${(size / 1048576).toStringAsFixed(1)} MB.', error: true);
      return;
    }
    if (video) {
      final d = await _videoDuration(f);
      if (d == null) {
        if (mounted) showAppSnack(context, 'Could not read this video. Try another one.', error: true);
        return;
      }
      if (d > ChatService.maxVideo + const Duration(seconds: 1)) {
        if (mounted) showAppSnack(context, 'Videos must be 5 minutes or shorter. This one is ${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}.', error: true);
        return;
      }
    }
    var ext = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : (video ? 'mp4' : 'jpg');
    if (ext == 'jpeg') ext = 'jpg';
    if (video && !['mp4', 'mov', 'webm', '3gp', 'mkv'].contains(ext)) ext = 'mp4';
    if (!video && !['jpg', 'png', 'webp', 'gif'].contains(ext)) ext = 'jpg';

    setState(() => _uploading = video ? 'Sending video…' : 'Sending photo…');
    try {
      final bytes = await f.readAsBytes();
      await ChatService.sendMedia(widget.bookingId, bytes, ext, video: video);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<Duration?> _videoDuration(XFile f) async {
    VideoPlayerController? c;
    try {
      c = kIsWeb ? VideoPlayerController.networkUrl(Uri.parse(f.path)) : VideoPlayerController.file(File(f.path));
      await c.initialize().timeout(const Duration(seconds: 20));
      return c.value.duration;
    } catch (_) {
      return null;
    } finally {
      await c?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ChatService.uid;
    return ServiceChrome(
      title: widget.title,
      subtitle: widget.subtitle,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFFF7F2),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('For your safety, phone numbers, emails and social handles are hidden. Keep payments in the app.',
                      style: AppTextStyles.small.copyWith(fontSize: 11.5, color: const Color(0xFF8A4A20))),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Chat unavailable. Check your connection.', style: AppTextStyles.small));
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                final list = snap.data!;
                if (list.length != _count) {
                  _count = list.length;
                  _toEnd();
                }
                if (list.isEmpty) {
                  return const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'Say hello', message: 'Agree on details like access, parking or materials here.');
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[i];
                    final showDay = i == 0 || !_sameDay(list[i - 1].createdAt, m.createdAt);
                    return Column(
                      children: [
                        if (showDay)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(friendlyDay(m.createdAt), style: AppTextStyles.small.copyWith(fontSize: 12)),
                          ),
                        _Bubble(message: m, mine: m.senderId == me),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_uploading != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Text(_uploading!, style: AppTextStyles.small.copyWith(fontSize: 12)),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  IconButton(onPressed: _uploading == null ? _attach : null, icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 30)),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Type a message',
                        filled: true,
                        fillColor: AppColors.field,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: _sending
                          ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final bg = m.masked ? const Color(0xFFF1F1F1) : (mine ? AppColors.primary : AppColors.field);
    final fg = m.masked ? AppColors.textMuted : (mine ? Colors.white : AppColors.dark);
    Widget content;
    if (m.masked && m.kind == 'text') {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_rounded, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(mine ? 'Hidden. Contact details can’t be shared.' : 'Hidden message',
                style: AppTextStyles.small.copyWith(color: fg, fontStyle: FontStyle.italic, fontSize: 14)),
          ),
        ],
      );
    } else if (m.kind == 'image' || m.kind == 'video') {
      content = _Media(path: m.mediaPath, video: m.kind == 'video');
    } else {
      content = Text(m.body ?? '', style: AppTextStyles.paragraph.copyWith(color: fg, fontSize: 15, height: 1.35));
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: m.kind == 'text' ? const EdgeInsets.fromLTRB(14, 10, 14, 8) : const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              Padding(
                padding: m.kind == 'text' ? const EdgeInsets.only(top: 3) : const EdgeInsets.fromLTRB(0, 4, 8, 2),
                child: Text(timeOf(m.createdAt), style: AppTextStyles.small.copyWith(fontSize: 10, color: mine && !m.masked && m.kind == 'text' ? Colors.white70 : AppColors.label)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.path, required this.video});
  final String? path;
  final bool video;

  @override
  Widget build(BuildContext context) {
    if (path == null) return const SizedBox(width: 200, height: 60);
    return FutureBuilder<String>(
      future: ChatService.mediaUrl(path!),
      builder: (context, snap) {
        final url = snap.data;
        return GestureDetector(
          onTap: url == null ? null : () => Navigator.of(context).push(appRoute(MediaViewerScreen(url: url, video: video))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 220,
              height: video ? 140 : 220,
              child: url == null
                  ? Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                  : video
                      ? Container(
                          color: AppColors.dark,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 52),
                              const SizedBox(height: 6),
                              Text('Video', style: AppTextStyles.small.copyWith(color: Colors.white70)),
                            ],
                          ),
                        )
                      : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.broken_image_rounded))),
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen photo or video.
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({super.key, required this.url, required this.video, this.caption});
  final String url;
  final bool video;
  final String? caption;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.video) {
      _c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _c!.play();
        }).catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
      _c!.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: widget.video
                  ? _failed
                      ? Text('Could not play this video', style: AppTextStyles.small.copyWith(color: Colors.white70))
                      : c == null || !c.value.isInitialized
                          ? const CircularProgressIndicator(color: Colors.white)
                          : GestureDetector(
                              onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                              child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
                            )
                  : InteractiveViewer(maxScale: 5, child: Image.network(widget.url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28)),
            ),
            if (widget.caption != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Text(widget.caption!, textAlign: TextAlign.center, style: AppTextStyles.paragraph.copyWith(color: Colors.white)),
              ),
            if (c != null && c.value.isInitialized)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
                      icon: Icon(c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                    ),
                    Expanded(child: VideoProgressIndicator(c, allowScrubbing: true, colors: const VideoProgressColors(playedColor: AppColors.primary))),
                    const SizedBox(width: 10),
                    Text('${_fmt(c.value.position)} / ${_fmt(c.value.duration)}', style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// All chats for this person: customers see bookings with an assigned pro, pros see their jobs.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key, required this.asPro});
  final bool asPro;

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late Future<List<(Booking, Party?, ChatMessage?)>> _f = _load();

  Future<List<(Booking, Party?, ChatMessage?)>> _load() async {
    final all = widget.asPro ? await ProService.myJobs() : await DataService.myBookings();
    final list = all.where((b) => b.professionalId != null && b.status != BookingStatus.cancelled).toList();
    final latest = await ChatService.latest(list.map((b) => b.id).toList());
    final parties = await Future.wait(list.map((b) => ChatService.party(b.id).catchError((_) => null)));
    final out = [for (var i = 0; i < list.length; i++) (list[i], parties[i], latest[list[i].id])];
    out.sort((a, b) => (b.$3?.createdAt ?? b.$1.createdAt).compareTo(a.$3?.createdAt ?? a.$1.createdAt));
    return out;
  }

  String _preview(ChatMessage? m) {
    if (m == null) return 'No messages yet';
    if (m.masked) return 'Hidden message';
    return switch (m.kind) { 'image' => '📷 Photo', 'video' => '🎬 Video', _ => m.body ?? '' };
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Messages',
      body: AsyncView<List<(Booking, Party?, ChatMessage?)>>(
        future: _f,
        onRetry: () => setState(() => _f = _load()),
        builder: (context, list) => list.isEmpty
            ? EmptyState(
                icon: Icons.forum_rounded,
                title: 'No chats yet',
                message: widget.asPro ? 'Accept a job to chat with the customer.' : 'Once a professional takes your booking you can chat here.',
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  setState(() => _f = _load());
                  await _f;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final (b, p, m) = list[i];
                    final name = p?.name ?? (widget.asPro ? 'Customer' : 'Professional');
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      leading: PersonAvatar(name: name, url: p?.avatar, size: 48),
                      title: Row(
                        children: [
                          Expanded(child: Text(name, style: AppTextStyles.headline6.copyWith(fontSize: 15))),
                          if (m != null) Text(timeOf(m.createdAt), style: AppTextStyles.small.copyWith(fontSize: 11)),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${b.serviceName} · #${b.reference}', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.primary)),
                          Text(_preview(m), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 13)),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(appRoute(ChatScreen(bookingId: b.id, title: name, subtitle: b.serviceName)));
                        setState(() => _f = _load());
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}
