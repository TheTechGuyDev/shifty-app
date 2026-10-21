import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../profile/support_screens.dart';
import 'booking_widgets.dart';
import 'order_screens.dart';

(String, Color) statusStyle(BookingStatus s) => switch (s) {
      BookingStatus.active => ('Active', AppColors.success),
      BookingStatus.cancelled => ('Cancelled', AppColors.warning),
      BookingStatus.done => ('Done', AppColors.dark),
      BookingStatus.pending => ('Pending', AppColors.yellow),
    };

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _b;
  bool _reviewed = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await DataService.booking(widget.bookingId);
    var reviewed = true;
    if (b != null && b.status == BookingStatus.done) reviewed = await DataService.hasReview(b.id);
    if (mounted) setState(() {
      _b = b;
      _reviewed = reviewed;
    });
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancel this booking?', style: AppTextStyles.navTitle),
        content: Text('The professional will be notified. This cannot be undone.', style: AppTextStyles.small),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking', style: TextStyle(color: AppColors.failed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await DataService.cancelBooking(widget.bookingId);
      await _load();
      if (mounted) showAppSnack(context, 'Booking cancelled');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    return ServiceChrome(
      title: 'Order Details',
      bodyColor: const Color(0xFFF6F6F6),
      bottom: b == null
          ? null
          : b.status == BookingStatus.pending
              ? PrimaryButton(label: 'Cancel Booking', color: AppColors.failed, loading: _busy, onPressed: _cancel)
              : b.status == BookingStatus.done && !_reviewed
                  ? PrimaryButton(
                      label: 'Rate this service',
                      onPressed: () async {
                        await Navigator.of(context).push(appRoute(ReviewScreen(booking: b)));
                        _load();
                      },
                    )
                  : OutlineButtonX(
                      label: 'Contact Support',
                      trailingArrow: true,
                      onPressed: () => Navigator.of(context).push(appRoute(const SupportChatScreen())),
                    ),
      body: b == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              children: [
                Row(
                  children: [
                    Text('#${b.reference}', style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
                    const Spacer(),
                    Builder(builder: (context) {
                      final (label, color) = statusStyle(b.status);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                        child: Text(label, style: AppTextStyles.smallBold.copyWith(color: Colors.white, fontSize: 12)),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                Text(b.serviceName, style: AppTextStyles.headline1.copyWith(fontSize: 28)),
                if (b.scheduledAt != null)
                  Text('${longDate(b.scheduledAt!)} · ${b.timeSlot ?? timeOf(b.scheduledAt!)}', style: AppTextStyles.small),
                const SizedBox(height: 18),
                RouteCard(
                  pickup: b.address,
                  dropoff: b.dropoffAddress,
                  pickupPoint: b.lat == null ? null : LatLng(b.lat!, b.lng!),
                  dropoffPoint: b.dropoffLat == null ? null : LatLng(b.dropoffLat!, b.dropoffLng!),
                ),
                const SizedBox(height: 18),
                BreakdownCard(
                  lines: b.lines,
                  serviceCharge: b.serviceCharge ?? 0,
                  discount: b.discount,
                  total: b.totalAmount ?? 0,
                  promo: b.promoCode,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      Icon(b.paymentMethod == 'card' ? Icons.credit_card_rounded : Icons.account_balance_wallet_rounded, color: AppColors.dark),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(b.paymentMethod == 'card' ? 'Online Payment' : 'Cash on completion',
                            style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)),
                      ),
                      Text(b.paymentStatus == 'paid' ? 'Paid' : 'Unpaid',
                          style: AppTextStyles.smallBold.copyWith(color: b.paymentStatus == 'paid' ? AppColors.success : AppColors.warning)),
                    ],
                  ),
                ),
                if ((b.details['notes'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NOTES', style: AppTextStyles.small.copyWith(fontSize: 11, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(b.details['notes'] as String, style: AppTextStyles.small.copyWith(color: AppColors.dark)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// "How was your Experience?" emoji rating.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.booking});
  final Booking booking;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final _text = TextEditingController();
  bool _busy = false;

  static const _faces = ['😢', '🙁', '😐', '😄', '😍'];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await DataService.submitReview(widget.booking.id, _rating, _text.text.trim());
      if (!mounted) return;
      showAppSnack(context, 'Thanks for your feedback!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Review',
      body: ListView(
        padding: const EdgeInsets.only(top: 50, bottom: 30),
        children: [
          Text('How was your Experience?', textAlign: TextAlign.center, style: AppTextStyles.navTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('Your order is Successfully Done, Do you mind giving a small feedback about your experience?',
                textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 14)),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              height: 86,
              decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(43)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < 5; i++)
                    GestureDetector(
                      onTap: () => setState(() => _rating = i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: _rating == i + 1 ? 70 : 40,
                        height: _rating == i + 1 ? 70 : 40,
                        alignment: Alignment.center,
                        decoration: _rating == i + 1
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 16, offset: const Offset(0, 8))],
                              )
                            : null,
                        child: Text(_faces[i], style: TextStyle(fontSize: _rating == i + 1 ? 54 : 30)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WRITE A REVIEW', style: AppTextStyles.small.copyWith(fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                TextField(
                  controller: _text,
                  maxLines: 5,
                  minLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Type here...',
                    hintStyle: AppTextStyles.small.copyWith(color: const Color(0xFFC4C4C4)),
                    filled: true,
                    fillColor: const Color(0xFFF7F9F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlineButtonX(label: 'Skip', onPressed: () => Navigator.pop(context))),
                    const SizedBox(width: 14),
                    Expanded(child: PrimaryButton(label: 'Submit', loading: _busy, onPressed: _submit)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
