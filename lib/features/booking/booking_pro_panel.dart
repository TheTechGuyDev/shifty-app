import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/models/pro_models.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/data_service.dart';
import '../../core/services/pro_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../chat/chat_screen.dart';
import '../pro/business/business_screens.dart';
import '../pro/jobs/jobs_screens.dart';
import '../pro/pro_widgets.dart';
import 'booking_widgets.dart';

/// Customer view of who is doing the job: quotes, assigned pro, progress, chat, reschedule.
class BookingProPanel extends StatefulWidget {
  const BookingProPanel({super.key, required this.booking, required this.onChanged});
  final Booking booking;
  final VoidCallback onChanged;

  @override
  State<BookingProPanel> createState() => _BookingProPanelState();
}

class _BookingProPanelState extends State<BookingProPanel> {
  Party? _pro;
  List<(Map<String, dynamic>, Map<String, dynamic>?)> _quotes = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BookingProPanel old) {
    super.didUpdateWidget(old);
    if (old.booking != widget.booking) _load();
  }

  Future<void> _load() async {
    final b = widget.booking;
    try {
      if (b.professionalId != null) {
        final p = await ChatService.party(b.id);
        if (mounted) setState(() => _pro = p);
      } else if (b.status == BookingStatus.pending) {
        final q = await DataService.quotesFor(b.id);
        final withPros = <(Map<String, dynamic>, Map<String, dynamic>?)>[];
        for (final o in q) {
          withPros.add((o, await ProService.publicProfile(userId: o['pro_id'] as String)));
        }
        if (mounted) setState(() => _quotes = withPros);
      }
    } catch (_) {}
  }

  Future<void> _accept(Map<String, dynamic> offer, String name) async {
    if (!await confirmDialog(context, 'Accept this quote?', '$name will do the job for ${money(offer['quote_amount'] as num?)} plus the service charge.', yes: 'Accept')) return;
    setState(() => _busy = true);
    try {
      await DataService.acceptQuote(offer['id'] as String);
      widget.onChanged();
      if (mounted) showAppSnack(context, 'Quote accepted. You can now chat with $name.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      await DataService.respondReschedule(widget.booking.id, accept);
      widget.onChanged();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  BoxDecoration get _card => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24));

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    if (b.status == BookingStatus.cancelled) return const SizedBox.shrink();

    if (b.professionalId == null) {
      if (b.status != BookingStatus.pending) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: _card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Finding a professional', style: AppTextStyles.headline6.copyWith(fontSize: 15))),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: AppColors.label)),
                ],
              ),
              Text(
                _quotes.isEmpty ? 'Nearby professionals have been notified. You’ll be alerted when one accepts or sends a quote.' : 'Compare quotes and pick the one you like.',
                style: AppTextStyles.small.copyWith(fontSize: 13),
              ),
              for (final (o, p) in _quotes) ...[
                const Divider(height: 26),
                Builder(builder: (context) {
                  final name = (p?['business_name'] as String?) ?? (p?['full_name'] as String?) ?? 'Professional';
                  final rating = (p?['rating'] as num?)?.toDouble() ?? 0;
                  final count = (p?['rating_count'] as int?) ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PersonAvatar(name: name, url: p?['avatar_url'] as String?),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(appRoute(PublicProfileScreen(proId: o['pro_id'] as String))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: AppTextStyles.headline6.copyWith(fontSize: 14)),
                                  Text(count == 0 ? 'New · view profile' : '★ ${rating.toStringAsFixed(1)} ($count) · view profile',
                                      style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                          Text(money(o['quote_amount'] as num?), style: AppTextStyles.navTitle.copyWith(fontSize: 17)),
                        ],
                      ),
                      if ((o['quote_note'] as String?)?.isNotEmpty == true)
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text(o['quote_note'] as String, style: AppTextStyles.small.copyWith(color: AppColors.dark))),
                      const SizedBox(height: 10),
                      PrimaryButton(label: 'Accept quote', loading: _busy, onPressed: () => _accept(o, name)),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      );
    }

    final steps = ['assigned', 'on_the_way', 'arrived', 'started', 'completed'];
    const titles = ['Assigned', 'On the way', 'Arrived', 'Working', 'Done'];
    final idx = steps.indexOf(b.progress ?? 'assigned').clamp(0, 4);
    final name = _pro?.name ?? 'Your professional';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          if (b.rescheduleAt != null && b.status == BookingStatus.active)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New time requested', style: AppTextStyles.headline6.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('$name asked to move the job to ${longDate(b.rescheduleAt!)}, ${timeOf(b.rescheduleAt!)}.',
                      style: AppTextStyles.small.copyWith(color: AppColors.dark)),
                  if (b.rescheduleNote?.isNotEmpty == true)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text('“${b.rescheduleNote}”', style: AppTextStyles.small.copyWith(fontStyle: FontStyle.italic))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: OutlineButtonX(label: 'Decline', onPressed: _busy ? () {} : () => _respond(false))),
                      const SizedBox(width: 10),
                      Expanded(child: PrimaryButton(label: 'Accept', loading: _busy, onPressed: () => _respond(true))),
                    ],
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _card,
            child: Column(
              children: [
                Row(
                  children: [
                    PersonAvatar(name: name, url: _pro?.avatar, size: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(appRoute(PublicProfileScreen(proId: b.professionalId!))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(child: Text(name, style: AppTextStyles.headline6.copyWith(fontSize: 15))),
                              if ((_pro?.level ?? 0) >= 2) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, color: AppColors.blue, size: 16)),
                            ]),
                            Text(
                              (_pro?.ratingCount ?? 0) == 0 ? 'Your professional' : '★ ${_pro!.rating.toStringAsFixed(1)} · ${_pro!.jobsDone} jobs',
                              style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (b.status != BookingStatus.cancelled)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(appRoute(ChatScreen(bookingId: b.id, title: name, subtitle: b.serviceName))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('Chat', style: AppTextStyles.smallBold.copyWith(color: Colors.white)),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(color: i <= idx ? AppColors.success : AppColors.field, borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(height: 6),
                            Text(titles[i],
                                style: AppTextStyles.small.copyWith(fontSize: 10.5, color: i <= idx ? AppColors.dark : AppColors.label, fontWeight: i == idx ? FontWeight.w700 : FontWeight.w400)),
                          ],
                        ),
                      ),
                      if (i < steps.length - 1) const SizedBox(width: 4),
                    ],
                  ],
                ),
                if (b.beforePhotos.isNotEmpty || b.afterPhotos.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  if (b.beforePhotos.isNotEmpty) PhotoStrip(title: 'Before', urls: b.beforePhotos),
                  if (b.afterPhotos.isNotEmpty) ...[const SizedBox(height: 12), PhotoStrip(title: 'After', urls: b.afterPhotos)],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
