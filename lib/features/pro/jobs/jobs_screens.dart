import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';
import '../../../core/models/pro_models.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../booking/booking_widgets.dart';
import '../../chat/chat_screen.dart';
import '../calendar/calendar_screens.dart';
import '../pro_widgets.dart';

/// Jobs tab: Requests / Active / Completed.
class ProJobsTab extends StatefulWidget {
  const ProJobsTab({super.key});

  @override
  State<ProJobsTab> createState() => _ProJobsTabState();
}

class _ProJobsTabState extends State<ProJobsTab> {
  int _seg = 0;
  late Future<List<(JobOffer, Booking)>> _req;
  late Future<List<Booking>> _jobs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _req = ProService.requests();
    _jobs = ProService.myJobs();
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(appRoute(page));
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Requests', 'Active', 'Completed'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _seg = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _seg == i ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _seg == i ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8)] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(labels[i],
                            style: AppTextStyles.smallBold.copyWith(color: _seg == i ? AppColors.dark : AppColors.label, fontSize: 13)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              setState(_load);
              await (_seg == 0 ? _req : _jobs);
            },
            child: _seg == 0 ? _requests() : _jobList(_seg == 1),
          ),
        ),
      ],
    );
  }

  Widget _requests() => AsyncView<List<(JobOffer, Booking)>>(
        future: _req,
        onRetry: () => setState(_load),
        builder: (context, list) => list.isEmpty
            ? ListView(children: const [
                EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'No requests yet',
                  message: 'Stay online. New requests matching your services and area show up here instantly.',
                )
              ])
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 130),
                children: [
                  for (final r in list)
                    JobCard(
                      booking: r.$2,
                      badge: r.$1.status == 'quoted' ? 'Quote sent' : 'New',
                      badgeColor: r.$1.status == 'quoted' ? AppColors.blue : AppColors.primary,
                      onTap: () => _open(JobRequestScreen(bookingId: r.$2.id)),
                    ),
                ],
              ),
      );

  Widget _jobList(bool active) => AsyncView<List<Booking>>(
        future: _jobs,
        onRetry: () => setState(_load),
        builder: (context, all) {
          final list = all.where((b) => active ? b.status == BookingStatus.active : b.status != BookingStatus.active).toList();
          if (!active) list.sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
          if (list.isEmpty) {
            return ListView(children: [
              EmptyState(
                icon: active ? Icons.handyman_rounded : Icons.history_rounded,
                title: active ? 'No active jobs' : 'No completed jobs yet',
                message: active ? 'Jobs you accept appear here until they are finished.' : 'Finished jobs and their earnings appear here.',
              )
            ]);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 130),
            children: [
              for (final b in list)
                JobCard(
                  booking: b,
                  badge: active ? progressLabel(b.progress) : (b.status == BookingStatus.cancelled ? 'Cancelled' : 'Done'),
                  badgeColor: active ? AppColors.success : (b.status == BookingStatus.cancelled ? AppColors.warning : AppColors.dark),
                  amount: active ? null : b.proEarning,
                  onTap: () => _open(active ? JobWorkspaceScreen(bookingId: b.id) : CompletedJobScreen(bookingId: b.id)),
                ),
            ],
          );
        },
      );
}

/// Shows what the customer asked for: items, details, notes.
class JobDetailsCard extends StatelessWidget {
  const JobDetailsCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final extras = <(String, String)>[];
    b.details.forEach((k, v) {
      if (v == null || v is Map || (v is List && v.isEmpty) || v.toString().isEmpty) return;
      if (k.endsWith('_id') || k == 'card') return;
      final label = k.replaceAll('_', ' ');
      extras.add((label[0].toUpperCase() + label.substring(1), v is List ? v.join(', ') : v.toString()));
    });
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job details', style: AppTextStyles.headline6.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          for (final l in b.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text('${l.label}${l.note == null ? '' : ' · ${l.note}'}', style: AppTextStyles.small.copyWith(color: AppColors.dark, fontSize: 14))),
                  Text(money(l.amount), style: AppTextStyles.smallBold.copyWith(color: AppColors.dark)),
                ],
              ),
            ),
          for (final e in extras)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, child: Text(e.$1, style: AppTextStyles.small.copyWith(fontSize: 13))),
                  Expanded(child: Text(e.$2, style: AppTextStyles.small.copyWith(color: AppColors.dark, fontSize: 13))),
                ],
              ),
            ),
          if (b.lines.isEmpty && extras.isEmpty) Text('No extra details given.', style: AppTextStyles.small),
          const Divider(height: 24),
          Row(
            children: [
              Text('Customer pays', style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
              const Spacer(),
              Text(b.totalAmount == null || b.totalAmount == 0 ? 'Needs your quote' : money(b.totalAmount),
                  style: AppTextStyles.navTitle.copyWith(fontSize: 17, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(b.paymentMethod == 'cash' ? 'Paid in cash after the job' : 'Paid by card in the app', style: AppTextStyles.small.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

Widget _infoRow(IconData icon, String title, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFFFF1EA), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.small.copyWith(fontSize: 12)),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );

Widget _jobMap(Booking b) {
  if (b.lat == null) return const SizedBox.shrink();
  final pickup = LatLng(b.lat!, b.lng!);
  final drop = b.dropoffLat == null ? null : LatLng(b.dropoffLat!, b.dropoffLng!);
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: SizedBox(
      height: 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AppMap(
          center: pickup,
          zoom: 14,
          interactive: false,
          fitPoints: drop == null ? null : [pickup, drop],
          markers: [
            Marker(point: pickup, width: 40, height: 40, child: const MapPin(color: AppColors.primary, size: 40)),
            if (drop != null) Marker(point: drop, width: 40, height: 40, child: const MapPin(color: AppColors.dark, icon: Icons.flag_rounded, size: 40)),
          ],
        ),
      ),
    ),
  );
}

Future<void> openDirections(Booking b) async {
  if (b.lat == null) return;
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${b.lat},${b.lng}&travelmode=driving');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// A single job request: accept, quote or decline.
class JobRequestScreen extends StatefulWidget {
  const JobRequestScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> {
  Booking? _b;
  JobOffer? _offer;
  Party? _customer;
  String? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = Booking.fromMap(await ProService.bookingRaw(widget.bookingId));
      final o = await ProService.myOffer(widget.bookingId);
      final c = await ChatService.party(widget.bookingId);
      if (mounted) setState(() {
        _b = b;
        _offer = o;
        _customer = c;
      });
    } catch (_) {
      if (mounted) setState(() => _err = 'This request is no longer available.');
    }
  }

  Future<void> _accept() async {
    final b = _b!;
    if (b.totalAmount == null || b.totalAmount == 0) {
      showAppSnack(context, 'This job has no price yet. Send a quote instead.', error: true);
      return;
    }
    if (!await confirmDialog(context, 'Accept this job?', 'You’ll earn about ${money(b.totalAmount)} before commission. The customer will be told you’re coming.', yes: 'Accept')) return;
    setState(() => _busy = true);
    try {
      await ProService.accept(b.id);
      if (!mounted) return;
      showAppSnack(context, 'Job accepted');
      Navigator.of(context).pushReplacement(appRoute(JobWorkspaceScreen(bookingId: b.id)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    if (!await confirmDialog(context, 'Decline this request?', 'It will be removed from your list.', yes: 'Decline', color: AppColors.failed)) return;
    try {
      await ProService.decline(widget.bookingId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    final quoted = _offer?.status == 'quoted';
    return ServiceChrome(
      title: 'Job Request',
      bottom: b == null || _offer == null || !['sent', 'quoted'].contains(_offer!.status) || b.status != BookingStatus.pending
          ? null
          : Row(
              children: [
                Expanded(
                  child: OutlineButtonX(
                    label: quoted ? 'Edit quote' : 'Send quote',
                    onPressed: () async {
                      final sent = await Navigator.of(context).push<bool>(appRoute(SendQuoteScreen(booking: b, current: _offer)));
                      if (sent == true) _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: PrimaryButton(label: 'Accept', loading: _busy, enabled: (b.totalAmount ?? 0) > 0, onPressed: _accept)),
              ],
            ),
      body: _err != null
          ? EmptyState(icon: Icons.block_rounded, title: 'Not available', message: _err!)
          : b == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                  children: [
                    Text(b.serviceName, style: AppTextStyles.headline1.copyWith(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text('#${b.reference} · requested ${timeOf(b.createdAt)}, ${shortDate(b.createdAt)}', style: AppTextStyles.small),
                    const SizedBox(height: 18),
                    if (b.status != BookingStatus.pending || !['sent', 'quoted'].contains(_offer?.status))
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(14)),
                        child: Text('This request has been taken or closed.', style: AppTextStyles.small.copyWith(color: const Color(0xFF8A5A00))),
                      ),
                    if (quoted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFE8F1FF), borderRadius: BorderRadius.circular(14)),
                        child: Text('Your quote of ${money(_offer!.quoteAmount)} was sent. Waiting for the customer.',
                            style: AppTextStyles.small.copyWith(color: AppColors.blue, fontWeight: FontWeight.w600)),
                      ),
                    _jobMap(b),
                    if (_customer != null) _infoRow(Icons.person_rounded, 'Customer', _customer!.name),
                    if (b.scheduledAt != null)
                      _infoRow(Icons.event_rounded, 'When', '${longDate(b.scheduledAt!)}${b.timeSlot != null ? '\n${b.timeSlot}' : ''}'),
                    if (b.address != null) _infoRow(Icons.location_on_rounded, b.dropoffAddress != null ? 'Pickup' : 'Address', b.address!),
                    if (b.dropoffAddress != null) _infoRow(Icons.flag_rounded, 'Drop-off', b.dropoffAddress!),
                    const SizedBox(height: 4),
                    JobDetailsCard(booking: b),
                    const SizedBox(height: 18),
                    if (b.status == BookingStatus.pending && _offer?.status == 'sent')
                      Center(
                        child: TextButton(
                          onPressed: _decline,
                          child: Text('Decline request', style: AppTextStyles.smallBold.copyWith(color: AppColors.failed)),
                        ),
                      ),
                  ],
                ),
    );
  }
}

/// Send or update a price for a job.
class SendQuoteScreen extends StatefulWidget {
  const SendQuoteScreen({super.key, required this.booking, this.current});
  final Booking booking;
  final JobOffer? current;

  @override
  State<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends State<SendQuoteScreen> {
  late final _amount = TextEditingController(text: widget.current?.quoteAmount?.round().toString() ?? '');
  late final _note = TextEditingController(text: widget.current?.quoteNote ?? '');
  bool _busy = false;
  int _pct = 10;

  @override
  void initState() {
    super.initState();
    ProService.stats().then((s) {
      if (mounted) setState(() => _pct = ((s['commission_pct'] as num?) ?? 10).round());
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  num get _value => num.tryParse(_amount.text) ?? 0;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ProService.quote(widget.booking.id, _value, _note.text.trim());
      if (!mounted) return;
      await Navigator.of(context).push(appRoute(QuoteSentScreen(amount: _value, service: widget.booking.serviceName)));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fee = (_value * _pct / 100).round();
    return ServiceChrome(
      title: 'Send Quote',
      bottom: PrimaryButton(label: 'Send quote', enabled: _value >= 500, loading: _busy, onPressed: _send),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
        children: [
          Text('Your price', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
          const SizedBox(height: 6),
          Text('for ${widget.booking.serviceName}. Include labour and any materials you will bring.', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 26),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.headline1.copyWith(fontSize: 36),
            decoration: InputDecoration(
              prefixText: '₦ ',
              prefixStyle: AppTextStyles.headline1.copyWith(fontSize: 36, color: AppColors.label),
              hintText: '0',
              border: InputBorder.none,
            ),
          ),
          const Divider(),
          if (_value > 0 && _value < 500) Text('Minimum quote is ₦500', style: AppTextStyles.small.copyWith(color: AppColors.warning)),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'What’s included? e.g. “Replace 2 taps, includes parts. About 2 hours.”',
              hintStyle: AppTextStyles.small,
              filled: true,
              fillColor: AppColors.field,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _row('Customer pays', money(_value)),
                _row('Commission ($_pct%)', '- ${money(fee)}'),
                const Divider(height: 18),
                _row('You earn', money(_value - fee), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Contact details in notes are hidden automatically. Keep all talk in the app.', style: AppTextStyles.small.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(a, style: bold ? AppTextStyles.headline6 : AppTextStyles.small.copyWith(color: AppColors.dark)),
            const Spacer(),
            Text(b, style: bold ? AppTextStyles.navTitle.copyWith(color: AppColors.success, fontSize: 17) : AppTextStyles.smallBold.copyWith(color: AppColors.dark)),
          ],
        ),
      );
}

class QuoteSentScreen extends StatelessWidget {
  const QuoteSentScreen({super.key, required this.amount, required this.service});
  final num amount;
  final String service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(color: Color(0xFFE8F1FF), shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, size: 54, color: AppColors.blue),
                ),
              ),
              const SizedBox(height: 26),
              Text('Quote sent!', style: AppTextStyles.headline1.copyWith(fontSize: 30)),
              const SizedBox(height: 10),
              Text('Your quote of ${money(amount)} for $service is with the customer. You’ll be notified as soon as they accept.',
                  textAlign: TextAlign.center, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
              const Spacer(),
              PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everything needed while doing a job: status steps, chat, directions, photos, finish.
class JobWorkspaceScreen extends StatefulWidget {
  const JobWorkspaceScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<JobWorkspaceScreen> createState() => _JobWorkspaceScreenState();
}

class _JobWorkspaceScreenState extends State<JobWorkspaceScreen> {
  Booking? _b;
  Party? _customer;
  bool _busy = false;
  bool _uploading = false;

  static const _steps = ['assigned', 'on_the_way', 'arrived', 'started', 'completed'];
  static const _titles = ['Job accepted', 'On my way', 'Arrived', 'Work started', 'Completed'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = Booking.fromMap(await ProService.bookingRaw(widget.bookingId));
      final c = await ChatService.party(widget.bookingId);
      if (mounted) setState(() {
        _b = b;
        _customer = c;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  int get _index => _steps.indexOf(_b?.progress ?? 'assigned').clamp(0, 4);

  Future<void> _advance() async {
    final next = _steps[_index + 1];
    if (next == 'completed') {
      final done = await Navigator.of(context).push<bool>(appRoute(FinishJobScreen(booking: _b!)));
      if (done == true && mounted) {
        Navigator.of(context).pushReplacement(appRoute(JobCompletedScreen(bookingId: _b!.id)));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await ProService.progress(_b!.id, next);
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _photo(bool before) async {
    final f = await pickPhoto(context);
    if (f == null) return;
    setState(() => _uploading = true);
    try {
      await ProService.addJobPhoto(_b!.id, f.$1, f.$2, before);
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    if (b == null) return const ServiceChrome(title: 'Job', body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    final active = b.status == BookingStatus.active;
    final nextLabel = active && _index < 4 ? ['Start driving', 'I’ve arrived', 'Start work', 'Finish job'][_index] : null;

    return ServiceChrome(
      title: 'Job #${b.reference}',
      bottom: nextLabel == null ? null : PrimaryButton(label: nextLabel, loading: _busy, onPressed: _advance),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          children: [
            Text(b.serviceName, style: AppTextStyles.headline1.copyWith(fontSize: 26)),
            const SizedBox(height: 14),
            if (b.rescheduleAt != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(14)),
                child: Text('Waiting for the customer to accept the new time: ${shortDate(b.rescheduleAt!)}, ${timeOf(b.rescheduleAt!)}',
                    style: AppTextStyles.small.copyWith(color: const Color(0xFF8A5A00))),
              ),
            // Customer card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  PersonAvatar(name: _customer?.name ?? 'Customer', url: _customer?.avatar),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_customer?.name ?? 'Customer', style: AppTextStyles.headline6.copyWith(fontSize: 15)),
                        Text('Customer', style: AppTextStyles.small.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  _circle(Icons.chat_bubble_rounded, () => Navigator.of(context).push(appRoute(ChatScreen(bookingId: b.id, title: _customer?.name ?? 'Customer')))),
                  const SizedBox(width: 8),
                  _circle(Icons.directions_rounded, () => openDirections(b)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _jobMap(b),
            // Steps
            Text('Progress', style: AppTextStyles.headline6.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
            for (var i = 0; i < _steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= _index ? AppColors.success : Colors.white,
                          border: Border.all(color: i <= _index ? AppColors.success : AppColors.border, width: 2),
                        ),
                        child: i <= _index ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                      ),
                      if (i < _steps.length - 1) Container(width: 2, height: 26, color: i < _index ? AppColors.success : AppColors.border),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_titles[i],
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, color: i <= _index ? AppColors.dark : AppColors.label, fontWeight: i == _index ? FontWeight.w700 : FontWeight.w500)),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            if (b.scheduledAt != null) _infoRow(Icons.event_rounded, 'Scheduled', '${longDate(b.scheduledAt!)}${b.timeSlot != null ? '\n${b.timeSlot}' : ''}'),
            if (b.address != null) _infoRow(Icons.location_on_rounded, 'Address', b.address!),
            if (b.dropoffAddress != null) _infoRow(Icons.flag_rounded, 'Drop-off', b.dropoffAddress!),
            JobDetailsCard(booking: b),
            const SizedBox(height: 20),
            PhotoStrip(title: 'Before photos', urls: b.beforePhotos, onAdd: active && !_uploading ? () => _photo(true) : null),
            const SizedBox(height: 14),
            PhotoStrip(title: 'After photos', urls: b.afterPhotos, onAdd: active && !_uploading ? () => _photo(false) : null),
            if (_uploading) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(color: AppColors.primary)),
            const SizedBox(height: 20),
            if (active && _index < 3)
              OutlineButtonX(
                label: 'Ask to reschedule',
                onPressed: () async {
                  await Navigator.of(context).push(appRoute(RescheduleRequestScreen(booking: b)));
                  _load();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(IconData i, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: Color(0xFFFFF1EA), shape: BoxShape.circle),
          child: Icon(i, color: AppColors.primary, size: 20),
        ),
      );
}

/// Horizontal list of job photos with an add button.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.title, required this.urls, this.onAdd});
  final String title;
  final List<String> urls;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headline6.copyWith(fontSize: 15)),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (onAdd != null)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 86,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: const Icon(Icons.add_a_photo_rounded, color: AppColors.label),
                  ),
                ),
              for (final u in urls)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(appRoute(MediaViewerScreen(url: u, video: false))),
                  child: Container(
                    width: 86,
                    margin: const EdgeInsets.only(right: 10),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    child: Image.network(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.field)),
                  ),
                ),
              if (urls.isEmpty && onAdd == null) Center(child: Text('No photos', style: AppTextStyles.small)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Final check before marking a job complete.
class FinishJobScreen extends StatefulWidget {
  const FinishJobScreen({super.key, required this.booking});
  final Booking booking;

  @override
  State<FinishJobScreen> createState() => _FinishJobScreenState();
}

class _FinishJobScreenState extends State<FinishJobScreen> {
  bool _done = false;
  bool _cash = false;
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ProService.progress(widget.booking.id, 'completed');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final cash = b.paymentMethod == 'cash';
    return ServiceChrome(
      title: 'Finish Job',
      bottom: PrimaryButton(label: 'Mark as completed', color: AppColors.success, enabled: _done && (!cash || _cash), loading: _busy, onPressed: _finish),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
        children: [
          Text('All done?', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
          const SizedBox(height: 6),
          Text('Confirm the job is finished. The customer will be asked to rate you.', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Text('Job total', style: AppTextStyles.bodyMedium),
                const Spacer(),
                Text(money(b.totalAmount), style: AppTextStyles.navTitle.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (b.afterPhotos.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(14)),
              child: Text('Tip: add “after” photos first. They protect you if there is a dispute and can go in your portfolio.',
                  style: AppTextStyles.small.copyWith(color: const Color(0xFF8A5A00))),
            ),
          CheckLine(value: _done, onChanged: (v) => setState(() => _done = v), label: 'The work is finished and the customer has seen it'),
          if (cash) CheckLine(value: _cash, onChanged: (v) => setState(() => _cash = v), label: 'I received ${money(b.totalAmount)} in cash'),
        ],
      ),
    );
  }
}

class JobCompletedScreen extends StatelessWidget {
  const JobCompletedScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: ProService.bookingRaw(bookingId),
          builder: (context, snap) {
            final b = snap.data == null ? null : Booking.fromMap(snap.data!);
            return Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) => Transform.scale(scale: v, child: child),
                    child: const Text('🎉', style: TextStyle(fontSize: 90)),
                  ),
                  const SizedBox(height: 20),
                  Text('Great job!', style: AppTextStyles.headline1.copyWith(fontSize: 30)),
                  const SizedBox(height: 10),
                  Text(b == null ? 'Saving…' : 'You earned ${money(b.proEarning)} on this job after ${money(b.commission)} commission.',
                      textAlign: TextAlign.center, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
                  const Spacer(),
                  PrimaryButton(label: 'Back to jobs', onPressed: () => Navigator.pop(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Finished job: earnings, photos and the customer's review.
class CompletedJobScreen extends StatelessWidget {
  const CompletedJobScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Job Summary',
      body: AsyncView<(Booking, List<ProReview>)>(
        future: () async {
          final b = Booking.fromMap(await ProService.bookingRaw(bookingId));
          final r = (await ProService.reviews()).where((x) => x.bookingId == bookingId).toList();
          return (b, r);
        }(),
        builder: (context, data) {
          final (b, reviews) = data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
            children: [
              Text(b.serviceName, style: AppTextStyles.headline1.copyWith(fontSize: 26)),
              const SizedBox(height: 4),
              Text('#${b.reference}${b.completedAt != null ? ' · completed ${shortDate(b.completedAt!)}' : ''}', style: AppTextStyles.small),
              const SizedBox(height: 20),
              if (b.status == BookingStatus.done)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _moneyRow('Job total', money(b.totalAmount)),
                      _moneyRow('Commission', '- ${money(b.commission)}'),
                      const Divider(color: Colors.white24, height: 20),
                      _moneyRow('Your earnings', money(b.proEarning), big: true),
                    ],
                  ),
                )
              else
                Text('This job was cancelled.', style: AppTextStyles.paragraph),
              const SizedBox(height: 20),
              if (b.address != null) _infoRow(Icons.location_on_rounded, 'Address', b.address!),
              JobDetailsCard(booking: b),
              const SizedBox(height: 20),
              PhotoStrip(title: 'Before photos', urls: b.beforePhotos),
              const SizedBox(height: 14),
              PhotoStrip(title: 'After photos', urls: b.afterPhotos),
              const SizedBox(height: 20),
              Text('Customer review', style: AppTextStyles.headline6.copyWith(fontSize: 15)),
              const SizedBox(height: 10),
              if (reviews.isEmpty)
                Text('No review yet.', style: AppTextStyles.small)
              else
                for (final r in reviews)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [for (var i = 0; i < 5; i++) Icon(Icons.star_rounded, size: 20, color: i < r.rating ? AppColors.yellow : AppColors.border)]),
                      if (r.comment != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.comment!, style: AppTextStyles.paragraph.copyWith(fontSize: 14))),
                    ],
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _moneyRow(String a, String b, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(a, style: AppTextStyles.small.copyWith(color: Colors.white70, fontSize: big ? 15 : 13)),
            const Spacer(),
            Text(b, style: (big ? AppTextStyles.navTitle : AppTextStyles.smallBold).copyWith(color: big ? const Color(0xFF7BE495) : Colors.white)),
          ],
        ),
      );
}
