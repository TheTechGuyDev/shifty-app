import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/services/geo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../shell/app_chrome.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';
import 'payment_screens.dart';
import 'setup_screens.dart';

IconData lineIcon(String? key) => switch (key) {
      'size' => Icons.home_rounded,
      'furniture' => Icons.weekend_rounded,
      'box' => Icons.inventory_2_rounded,
      'heavy' => Icons.precision_manufacturing_rounded,
      'worker' => Icons.engineering_rounded,
      'electrician' => Icons.bolt_rounded,
      'vehicle' => Icons.local_shipping_rounded,
      _ => Icons.handyman_rounded,
    };

Color lineTint(String? key) => switch (key) {
      'size' => const Color(0xFFE6F4FB),
      'furniture' || 'box' => const Color(0xFFFCEBF5),
      'worker' || 'electrician' => const Color(0xFFFDEEF4),
      'vehicle' => const Color(0xFFEDE3FB),
      _ => const Color(0xFFF1F1F1),
    };

/// Route map card: map + distance pill + address rows.
class RouteCard extends StatelessWidget {
  const RouteCard({super.key, required this.pickup, this.dropoff, this.pickupPoint, this.dropoffPoint, this.accent = AppColors.primary});

  final String? pickup;
  final String? dropoff;
  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final a = pickupPoint ?? GeoService.fallback;
    final b = dropoffPoint;
    final dist = b == null ? null : GeoService.distanceMeters(a, b);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          SizedBox(
            height: 132,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppMap(
                      center: a,
                      interactive: false,
                      fitPoints: b == null ? null : [a, b],
                      markers: [
                        Marker(point: a, width: 36, height: 36, child: MapPin(color: b == null ? accent : AppColors.yellow, size: 36)),
                        if (b != null) Marker(point: b, width: 30, height: 30, child: const MapPin(color: AppColors.blue, icon: Icons.home_rounded, size: 30)),
                      ],
                    ),
                  ),
                  if (dist != null)
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        child: Text(distanceLabel(dist), style: AppTextStyles.headline6.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              children: [
                _addr(pickup ?? '-', dropoff == null),
                if (dropoff != null) ...[
                  Row(children: [
                    const SizedBox(width: 9),
                    Container(width: 1.5, height: 12, color: AppColors.success),
                    const SizedBox(width: 18),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ]),
                  _addr(dropoff!, true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addr(String text, bool green) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (green)
              const Icon(Icons.location_on_rounded, color: AppColors.success, size: 22)
            else
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.dark, width: 5)),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(text,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline6.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

/// Price breakdown card (shared by order summary and booking details).
class BreakdownCard extends StatelessWidget {
  const BreakdownCard({
    super.key,
    required this.lines,
    required this.serviceCharge,
    required this.discount,
    required this.total,
    this.promo,
    this.onAddPromo,
    this.onRemovePromo,
    this.onEdit,
    this.accent = AppColors.primary,
  });

  final List<QuoteLine> lines;
  final num serviceCharge;
  final num discount;
  final num total;
  final String? promo;
  final VoidCallback? onAddPromo;
  final VoidCallback? onRemovePromo;
  final VoidCallback? onEdit;
  final Color accent;

  static const _bigIcons = {'size', 'furniture', 'worker', 'vehicle', 'heavy'};

  @override
  Widget build(BuildContext context) {
    final big = lines.where((l) => _bigIcons.contains(l.icon)).toList();
    final small = lines.where((l) => !_bigIcons.contains(l.icon)).toList();
    final divider = const Divider(height: 1, color: AppColors.border);

    Widget smallRow(String label, String value, {String? hint, Color? valueColor, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Text(label, style: AppTextStyles.headline6.copyWith(fontSize: bold ? 15 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
              if (hint != null) ...[const SizedBox(width: 10), Text(hint, style: AppTextStyles.small.copyWith(fontSize: 9, color: const Color(0xFFBDBDBD)))],
              const Spacer(),
              Text(value,
                  style: AppTextStyles.headline6.copyWith(
                      fontSize: bold ? 16 : 13, color: valueColor ?? const Color(0xFF9B9B9B), fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 14, 14),
            child: Row(
              children: [
                Text('Order Details', style: AppTextStyles.headline6.copyWith(fontSize: 12)),
                const Spacer(),
                if (onEdit != null)
                  IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6B6B6B), size: 20)),
              ],
            ),
          ),
          divider,
          for (final l in big) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 70,
                    decoration: BoxDecoration(color: lineTint(l.icon), borderRadius: BorderRadius.circular(12)),
                    child: Icon(lineIcon(l.icon), size: 32, color: AppColors.dark.withAlpha(200)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.label, style: AppTextStyles.navTitle.copyWith(fontSize: 17)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(l.note ?? '',
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 11, color: const Color(0xFFC4C4C4))),
                            ),
                            Text(money(l.amount), style: AppTextStyles.headline6.copyWith(fontSize: 13, color: accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            divider,
          ],
          for (final l in small) ...[smallRow(l.label, money(l.amount), hint: l.note), divider],
          smallRow('Service Charge', money(serviceCharge)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Row(
              children: [
                Text('Promo Code', style: AppTextStyles.headline6.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                if (promo != null && discount > 0)
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                    decoration: BoxDecoration(color: const Color(0xFFC8DBF4), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(promo!, style: AppTextStyles.headline6.copyWith(fontSize: 14, color: const Color(0xFF2E67C9), fontWeight: FontWeight.w500)),
                        if (onRemovePromo != null)
                          GestureDetector(
                            onTap: onRemovePromo,
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF2E67C9))),
                          ),
                      ],
                    ),
                  )
                else if (onAddPromo != null)
                  GestureDetector(
                    onTap: onAddPromo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(8)),
                      child: Text('+ Add code', style: AppTextStyles.smallBold.copyWith(fontSize: 12, color: accent)),
                    ),
                  )
                else
                  Text('-', style: AppTextStyles.small),
                const Spacer(),
                Text(discount > 0 ? '-${money(discount)}' : money(0),
                    style: AppTextStyles.headline6.copyWith(fontSize: 13, color: const Color(0xFF9B9B9B))),
              ],
            ),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24, color: AppColors.border),
          smallRow('Total', money(total), hint: '(Estimated Cost)', valueColor: accent, bold: true),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  BookingDraft get d => widget.draft;
  Quote? _quote;
  Object? _error;
  String _method = 'card';
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!DataService.signedIn) {
      setState(() => _error = 'login');
      return;
    }
    setState(() => _error = null);
    try {
      final q = await DataService.quote(d.kind.name, d.details, promo: d.promo);
      if (mounted) setState(() => _quote = q);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _addPromo() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Promo code', style: AppTextStyles.navTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(20)],
          decoration: const InputDecoration(hintText: 'e.g. HOME40'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: Text('Apply', style: TextStyle(color: d.accent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    try {
      final pct = await DataService.validatePromo(code);
      if (!mounted) return;
      if (pct == 0) {
        showAppSnack(context, 'That code is not valid', error: true);
        return;
      }
      d.promo = code.toUpperCase();
      showAppSnack(context, '$pct% discount applied');
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _confirm() async {
    if (_method == 'card') {
      final card = await showCardsSheet(context, total: _quote?.total ?? 0, accent: d.accent);
      if (card == null || !mounted) return;
      await _place(card);
    } else {
      await _place(null);
    }
  }

  Future<void> _place(PaymentCard? card) async {
    setState(() => _placing = true);
    try {
      final id = await DataService.placeBooking(
        serviceSlug: d.service.slug,
        kind: d.kind.name,
        details: d.details,
        scheduledAt: d.scheduledAt!,
        timeSlot: d.timeSlot!,
        address: d.address!,
        lat: d.point?.latitude,
        lng: d.point?.longitude,
        dropoffAddress: d.dropoffAddress,
        dropoffLat: d.dropoffPoint?.latitude,
        dropoffLng: d.dropoffPoint?.longitude,
        promo: d.promo,
        paymentMethod: card == null ? 'cash' : 'card',
        cardId: card?.id,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        appRoute(OrderPlacedScreen(draft: d, bookingId: id)),
        (r) => r.isFirst,
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _edit() => Navigator.of(context).popUntil((r) => r.settings.name == bookingSetupRoute || r.isFirst);

  @override
  Widget build(BuildContext context) {
    final q = _quote;
    final title = d.twoPoints ? 'Order Details' : 'Confirmation';
    return ServiceChrome(
      title: title,
      bodyColor: const Color(0xFFF6F6F6),
      bottom: PrimaryButton(
        label: q == null ? 'Confirm' : 'Confirm (${money(q.total)})',
        color: d.accent,
        enabled: q != null,
        loading: _placing,
        onPressed: _confirm,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        children: [
          RouteCard(
            pickup: d.address,
            dropoff: d.dropoffAddress,
            pickupPoint: d.point,
            dropoffPoint: d.dropoffPoint,
            accent: d.accent,
          ),
          const SizedBox(height: 22),
          if (_error == 'login')
            _LoginPrompt(onLogin: () async {
              await Navigator.of(context).push(appRoute(const LoginScreen()));
              _load();
            })
          else if (_error != null)
            Column(children: [
              Text('Could not get the price. Check your connection.', style: AppTextStyles.small),
              TextButton(onPressed: _load, child: Text('Retry', style: TextStyle(color: d.accent))),
            ])
          else if (q == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
            )
          else
            BreakdownCard(
              lines: q.lines,
              serviceCharge: q.serviceCharge,
              discount: q.discount,
              total: q.total,
              promo: d.promo,
              accent: d.accent,
              onEdit: _edit,
              onAddPromo: _addPromo,
              onRemovePromo: () {
                d.promo = null;
                _load();
              },
            ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _methodCard('card', 'Online Payment', Icons.credit_card_rounded)),
              const SizedBox(width: 22),
              Expanded(child: _methodCard('cash', 'Cash', Icons.account_balance_wallet_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          if (d.scheduledAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Scheduled: ${longDate(d.scheduledAt!)} at ${d.timeSlot}',
                  textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _methodCard(String key, String label, IconData icon) {
    final sel = _method == key;
    return GestureDetector(
      onTap: () => setState(() => _method = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 118,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Positioned(
              right: 14,
              top: 14,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? d.accent : Colors.transparent,
                  border: Border.all(color: sel ? d.accent : const Color(0xFFC4C4C4), width: 1.5),
                ),
                child: sel ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 30, color: sel ? AppColors.dark : const Color(0xFFD0D0D0)),
                  const SizedBox(height: 10),
                  Text(label,
                      style: AppTextStyles.small.copyWith(
                          fontSize: 13, color: sel ? AppColors.dark : const Color(0xFFBDBDBD), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 34),
          const SizedBox(height: 12),
          Text('Log in to see your price', style: AppTextStyles.navTitle),
          const SizedBox(height: 6),
          Text('Your selections are kept. Log in to get the exact cost and place the order.',
              textAlign: TextAlign.center, style: AppTextStyles.small),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Log in', onPressed: onLogin),
        ],
      ),
    );
  }
}

/// "Order Placed" with schedule, calendar link and next steps.
class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key, required this.draft, required this.bookingId});
  final BookingDraft draft;
  final String bookingId;

  Future<void> _addToCalendar() async {
    final start = draft.scheduledAt!.toUtc();
    final end = start.add(Duration(hours: (draft.details['hours'] as int?) ?? 2));
    String f(DateTime t) => '${t.toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': '${draft.service.name} (${AppConfig.appName})',
      'dates': '${f(start)}/${f(end)}',
      'details': 'Booked on ${AppConfig.appName}. Support: ${AppConfig.supportPhone}',
      'location': draft.address ?? '',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final shield = draft.kind == BookingKind.cleaning;
    final driver = draft.kind == BookingKind.vehicle;
    final accent = draft.accent;
    final when = draft.scheduledAt!;

    void home() => Navigator.of(context).popUntil((r) => r.isFirst);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: AppChrome(
          title: shield ? 'Order Placed' : 'Order Confirmation',
          leading: IconButton(onPressed: home, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
          body: ListView(
            padding: const EdgeInsets.only(top: 34, bottom: 30),
            children: [
              Center(child: _Burst(shield: shield)),
              const SizedBox(height: 22),
              Text('Order Placed', textAlign: TextAlign.center, style: AppTextStyles.headline1),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Your order has been Successfully placed,\nOur team will contact you soon.\nFor any help, call ',
                      style: AppTextStyles.paragraph.copyWith(fontSize: 14),
                    ),
                    TextSpan(
                      text: AppConfig.supportPhone,
                      style: AppTextStyles.paragraph.copyWith(fontSize: 14, color: accent, fontWeight: FontWeight.w700),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!AppConfig.paymentsLive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 10, 40, 0),
                  child: Text('Test mode: no money was charged.',
                      textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.label)),
                ),
              const SizedBox(height: 26),
              const Divider(color: AppColors.border),
              const SizedBox(height: 22),
              Text(driver ? 'YOUR DRIVER' : 'SCHEDULE',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small.copyWith(fontSize: 10, letterSpacing: 1.5, color: const Color(0xFFC4C4C4))),
              const SizedBox(height: 10),
              Text('${friendlyDay(when)} @ ${draft.timeSlot}',
                  textAlign: TextAlign.center, style: AppTextStyles.headline6.copyWith(fontSize: 13)),
              const SizedBox(height: 18),
              if (driver)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(32)),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: const Color(0xFFFFE6D6), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Finding your driver', style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('You will get their name and phone in Notifications once assigned.',
                                  style: AppTextStyles.small.copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Center(
                child: GestureDetector(
                  onTap: _addToCalendar,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFE2F5E6), borderRadius: BorderRadius.circular(20)),
                    child: Text('ADD TO CALENDER',
                        style: AppTextStyles.smallBold.copyWith(color: AppColors.success, fontSize: 12, letterSpacing: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(color: AppColors.border),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: shield
                    ? OutlineButtonX(label: 'Go to Homepage', trailingArrow: true, onPressed: home)
                    : PrimaryButton(label: 'Go to Homepage', color: accent, onPressed: home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Concentric circles with a party popper or a shield, gently popping in.
class _Burst extends StatelessWidget {
  const _Burst({required this.shield});
  final bool shield;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: SizedBox(
        width: 192,
        height: 192,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final (size, alpha) in [(192.0, 18), (150.0, 26), (110.0, 34)])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (shield ? const Color(0xFF8E8E8E) : AppColors.success).withAlpha(alpha),
                ),
              ),
            if (shield)
              const Icon(Icons.verified_user_rounded, size: 86, color: AppColors.success)
            else
              const Text('🎉', style: TextStyle(fontSize: 84)),
          ],
        ),
      ),
    );
  }
}
