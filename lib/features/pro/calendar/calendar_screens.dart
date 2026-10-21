import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../booking/booking_widgets.dart';
import '../jobs/jobs_screens.dart';
import '../onboarding/pro_onboarding.dart';
import '../pro_widgets.dart';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Calendar tab: pick a day, see jobs, manage availability.
class ProCalendarTab extends StatefulWidget {
  const ProCalendarTab({super.key});

  @override
  State<ProCalendarTab> createState() => _ProCalendarTabState();
}

class _ProCalendarTabState extends State<ProCalendarTab> {
  DateTime _day = DateTime.now();
  List<Booking> _jobs = [];
  List<(String, DateTime, String?)> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final j = await ProService.myJobs();
      final b = await ProService.blockedDates();
      if (mounted) setState(() {
        _jobs = j.where((x) => x.status != BookingStatus.cancelled && x.scheduledAt != null).toList();
        _blocked = b;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayJobs = _jobs.where((j) => _sameDay(j.scheduledAt!, _day)).toList();
    final blocked = _blocked.where((b) => _sameDay(b.$2, _day)).firstOrNull;
    final week = _jobs.where((j) {
      final d = j.scheduledAt!.difference(DateTime.now()).inDays;
      return j.status == BookingStatus.active && d >= 0 && d < 7;
    }).length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 130),
        children: [
          Row(
            children: [
              Expanded(child: StatTile(label: 'Jobs in next 7 days', value: '$week', icon: Icons.event_note_rounded, color: AppColors.blue)),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Blocked days',
                  value: '${_blocked.where((b) => !b.$2.isBefore(DateTime.now().subtract(const Duration(days: 1)))).length}',
                  icon: Icons.event_busy_rounded,
                  color: AppColors.failed,
                  onTap: () async {
                    await Navigator.of(context).push(appRoute(const BlockDatesScreen()));
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CalendarPicker(selected: _day, onSelect: (d) => setState(() => _day = d)),
          const SizedBox(height: 18),
          ProSectionTitle(longDate(_day)),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else ...[
            if (blocked != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFEDE8), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded, color: AppColors.failed),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Blocked${blocked.$3 == null || blocked.$3!.isEmpty ? '' : ': ${blocked.$3}'}', style: AppTextStyles.smallBold.copyWith(color: AppColors.failed))),
                    TextButton(
                      onPressed: () async {
                        await ProService.unblock(blocked.$1);
                        _load();
                      },
                      child: Text('Unblock', style: AppTextStyles.smallBold.copyWith(color: AppColors.dark)),
                    ),
                  ],
                ),
              ),
            if (dayJobs.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(18)),
                child: Text(blocked != null ? 'You are not taking jobs on this day.' : 'No jobs on this day.', style: AppTextStyles.small),
              )
            else
              for (final j in dayJobs)
                JobCard(
                  booking: j,
                  badge: j.status == BookingStatus.done ? 'Done' : progressLabel(j.progress),
                  badgeColor: j.status == BookingStatus.done ? AppColors.dark : AppColors.success,
                  onTap: () async {
                    await Navigator.of(context)
                        .push(appRoute(j.status == BookingStatus.active ? JobWorkspaceScreen(bookingId: j.id) : CompletedJobScreen(bookingId: j.id)));
                    _load();
                  },
                ),
            const SizedBox(height: 14),
            if (blocked == null && !_day.isBefore(DateTime.now().subtract(const Duration(days: 1))))
              OutlineButtonX(
                label: 'Block this day',
                onPressed: () async {
                  await ProService.blockDate(_day, null);
                  _load();
                },
              ),
            const SizedBox(height: 10),
            MenuTile(
              icon: Icons.schedule_rounded,
              title: 'Weekly working hours',
              subtitle: 'Set the days and times you work',
              onTap: () => Navigator.of(context).push(appRoute(const WorkingHoursScreen(editing: true))),
            ),
          ],
        ],
      ),
    );
  }
}

/// Block days off (holidays, personal time).
class BlockDatesScreen extends StatefulWidget {
  const BlockDatesScreen({super.key});

  @override
  State<BlockDatesScreen> createState() => _BlockDatesScreenState();
}

class _BlockDatesScreenState extends State<BlockDatesScreen> {
  DateTime? _day;
  final _reason = TextEditingController();
  List<(String, DateTime, String?)> _list = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final l = await ProService.blockedDates();
    final today = DateTime.now().subtract(const Duration(days: 1));
    if (mounted) setState(() => _list = l.where((b) => b.$2.isAfter(today)).toList());
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await ProService.blockDate(_day!, _reason.text.trim().isEmpty ? null : _reason.text.trim());
      _reason.clear();
      setState(() => _day = null);
      await _load();
      if (mounted) showAppSnack(context, 'Day blocked');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Block Dates',
      bottom: PrimaryButton(label: _day == null ? 'Pick a day' : 'Block ${shortDate(_day!)}', enabled: _day != null, loading: _busy, onPressed: _add),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
        children: [
          Text('Customers can’t book you on blocked days.', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 16),
          CalendarPicker(selected: _day, onSelect: (d) => setState(() => _day = d)),
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            decoration: InputDecoration(
              hintText: 'Reason (optional), e.g. Holiday',
              filled: true,
              fillColor: AppColors.field,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 22),
          if (_list.isNotEmpty) const ProSectionTitle('Blocked days'),
          for (final b in _list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy_rounded, color: AppColors.failed),
              title: Text(longDate(b.$2), style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
              subtitle: b.$3 == null ? null : Text(b.$3!, style: AppTextStyles.small),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  await ProService.unblock(b.$1);
                  _load();
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Ask the customer to move a job to a new time.
class RescheduleRequestScreen extends StatefulWidget {
  const RescheduleRequestScreen({super.key, required this.booking});
  final Booking booking;

  @override
  State<RescheduleRequestScreen> createState() => _RescheduleRequestScreenState();
}

class _RescheduleRequestScreenState extends State<RescheduleRequestScreen> {
  DateTime? _day;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final at = DateTime(_day!.year, _day!.month, _day!.day, _time.hour, _time.minute);
    if (at.isBefore(DateTime.now())) {
      showAppSnack(context, 'Pick a time in the future', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ProService.requestReschedule(widget.booking.id, at, _note.text.trim());
      if (!mounted) return;
      showAppSnack(context, 'Request sent to the customer');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return ServiceChrome(
      title: 'Reschedule',
      bottom: PrimaryButton(label: 'Send request', enabled: _day != null && _note.text.trim().length >= 3, loading: _busy, onPressed: _send),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
        children: [
          if (b.scheduledAt != null)
            Text('Currently: ${longDate(b.scheduledAt!)}${b.timeSlot != null ? ', ${b.timeSlot}' : ''}', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 16),
          CalendarPicker(selected: _day, onSelect: (d) => setState(() => _day = d)),
          const SizedBox(height: 14),
          MenuTile(
            icon: Icons.schedule_rounded,
            title: 'New time',
            subtitle: _time.format(context),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLines: 3,
            maxLength: 300,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Reason for the change',
              filled: true,
              fillColor: AppColors.field,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
