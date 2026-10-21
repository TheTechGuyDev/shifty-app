import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';
import 'location_screens.dart';

/// Builds the white summary pill items for moving jobs.
List<(Widget, String)> movingSummary(BookingDraft d) {
  Widget emoji(String e) => Text(e, style: const TextStyle(fontSize: 24));
  final items = <(Widget, String)>[
    (emoji(d.kind == BookingKind.office ? '🏢' : (d.kind == BookingKind.commercial ? '🏭' : '🏡')), d.sizeLabel.replaceAll(', ', '\n')),
  ];
  if (d.kind == BookingKind.commercial) {
    items.add((emoji('🏗️'), '${d.count('heavy')} Heavy'));
  } else {
    items.add((emoji('🛋️'), '${d.furnitureTotal} Furniture'));
  }
  items.add((emoji('📦'), '${d.count('boxes')} Boxs'));
  return items;
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  BookingDraft get d => widget.draft;
  late String _period = _defaultPeriod();

  bool get _usePeriods => d.kind == BookingKind.cleaning || d.kind == BookingKind.painting || d.kind == BookingKind.generic;
  bool get _moving => d.kind == BookingKind.house || d.kind == BookingKind.office || d.kind == BookingKind.commercial;

  String _defaultPeriod() {
    final h = DateTime.now().hour;
    if (h < 9) return 'Morning';
    if (h < 12) return 'Late Morning';
    if (h < 16) return 'Afternoon';
    return 'Evening';
  }

  /// Hide time slots that have already passed when the date is today.
  List<String> _slots(List<String> slots) {
    final date = d.date;
    final now = DateTime.now();
    if (date == null || date.year != now.year || date.month != now.month || date.day != now.day) return slots;
    return slots.where((s) {
      final draft = BookingDraft(d.service)
        ..date = date
        ..timeSlot = s;
      return draft.scheduledAt!.isAfter(now.add(const Duration(hours: 1)));
    }).toList();
  }

  void _proceed() {
    if (d.scheduledAt == null) {
      showAppSnack(context, 'Pick a date and a time', error: true);
      return;
    }
    Navigator.of(context).push(appRoute(LocationScreen(draft: d)));
  }

  @override
  Widget build(BuildContext context) {
    final accent = d.accent;
    final title = switch (d.kind) {
      BookingKind.house || BookingKind.office || BookingKind.commercial => 'Schedule Shifting',
      BookingKind.painting => 'Choose Date & Time',
      _ => '${d.service.name}${d.service.name.toLowerCase().endsWith('service') ? '' : ' Service'}',
    };
    final slots = _slots(_usePeriods ? timeSlotsByPeriod[_period]! : allTimeSlots);

    return ServiceChrome(
      title: title,
      bottom: PrimaryButton(label: 'Proceed', color: accent, enabled: d.scheduledAt != null, onPressed: _proceed),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_moving) Padding(padding: const EdgeInsets.fromLTRB(0, 0, 0, 0), child: SummaryBar(items: movingSummary(d))),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 0),
            child: CalendarPicker(
              selected: d.date,
              accent: accent,
              onSelect: (date) => setState(() {
                d.date = date;
                if (d.timeSlot != null && !_slots([d.timeSlot!]).contains(d.timeSlot)) d.timeSlot = null;
              }),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Text('Pick time', style: AppTextStyles.paragraph.copyWith(fontSize: 15, color: const Color(0xFF9B9B9B))),
          ),
          const SizedBox(height: 14),
          if (_usePeriods) ...[
            PillChoices(
              options: timeSlotsByPeriod.keys.toList(),
              selected: _period,
              accent: accent,
              big: true,
              onSelect: (p) => setState(() {
                _period = p;
                d.timeSlot = null;
              }),
            ),
            const SizedBox(height: 12),
          ],
          if (d.date == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text('Choose a date first', style: AppTextStyles.small.copyWith(fontSize: 12, color: const Color(0xFFBDBDBD))),
            )
          else if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text('No more slots today for this time of day. Pick another date or period.',
                  style: AppTextStyles.small.copyWith(fontSize: 12, color: const Color(0xFFBDBDBD))),
            )
          else
            PillChoices(
              options: slots,
              selected: d.timeSlot,
              accent: accent,
              onSelect: (s) => setState(() => d.timeSlot = s),
            ),
          const SizedBox(height: 22),
          if (d.kind == BookingKind.cleaning || d.kind == BookingKind.painting)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 26, 20),
              child: CheckLine(
                value: (d.details['instruments'] as bool?) ?? false,
                accent: accent,
                label: d.kind == BookingKind.cleaning ? 'Include cleaning Instruments' : 'Include All painting Instruments',
                onChanged: (v) => setState(() => d.details['instruments'] = v),
              ),
            ),
          if (d.kind == BookingKind.house) ...[
            const SectionBand(),
            const SizedBox(height: 14),
            CounterRow(
              icon: Icons.engineering_rounded,
              title: 'Workers',
              note: 'Regular cost is ₦5,000 each. Total cost will be calculated later',
              value: d.count('workers'),
              onChanged: (v) => setState(() => d.details['workers'] = v),
            ),
            CounterRow(
              icon: Icons.bolt_rounded,
              title: 'Electrician',
              note: 'Regular cost is ₦8,000 each. Total cost will be calculated later',
              value: d.count('electricians'),
              onChanged: (v) => setState(() => d.details['electricians'] = v),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
