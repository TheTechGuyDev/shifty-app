import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../notifications/notifications_screen.dart';
import '../shell/app_chrome.dart';

/// Dark header + white rounded body used by every booking screen.
class ServiceChrome extends StatelessWidget {
  const ServiceChrome({super.key, required this.title, required this.body, this.subtitle, this.bottom, this.bodyColor = AppColors.white});

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? bottom;
  final Color bodyColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: AppChrome(
        title: subtitle == null ? title : null,
        titleWidget: subtitle == null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.navTitle.copyWith(color: Colors.white)),
                  Text(subtitle!, style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 12)),
                ],
              ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onBell: () => Navigator.of(context).push(appRoute(const NotificationsScreen())),
        bodyColor: bodyColor,
        body: body,
      ),
      bottomNavigationBar: bottom == null
          ? null
          : ColoredBox(
              color: bodyColor,
              child: SafeArea(
                top: false,
                child: Padding(padding: const EdgeInsets.fromLTRB(40, 10, 40, 16), child: bottom),
              ),
            ),
    );
  }
}

/// Full-width light grey band separating sections.
class SectionBand extends StatelessWidget {
  const SectionBand({super.key});

  @override
  Widget build(BuildContext context) => Container(height: 10, color: const Color(0xFFF0F0F0));
}

/// Big screen heading with optional leading icon and a "+ Custom" pill.
class BookingHeading extends StatelessWidget {
  const BookingHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.actionLabel,
    this.onAction,
    this.accent = AppColors.primary,
    this.actionActive = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final bool actionActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 34, 26, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(title, style: AppTextStyles.headline1),
                ),
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onAction,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: actionActive ? accent : const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: actionActive ? Colors.white : accent, size: 22),
                        const SizedBox(width: 6),
                        Text(actionLabel!,
                            style: AppTextStyles.smallBold.copyWith(color: actionActive ? Colors.white : accent, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

/// "−  0  +" stepper.
class Counter extends StatelessWidget {
  const Counter({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 99});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) => GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: enabled ? AppColors.dark : AppColors.label),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded, value > min, () => onChanged(value - 1)),
        SizedBox(
          width: 35,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$value', key: ValueKey(value), textAlign: TextAlign.center, style: AppTextStyles.navTitle),
          ),
        ),
        btn(Icons.add_rounded, value < max, () => onChanged(value + 1)),
      ],
    );
  }
}

/// Icon bubble + title + grey note + counter (Workers, Electrician, Packed Boxes…).
class CounterRow extends StatelessWidget {
  const CounterRow({
    super.key,
    required this.icon,
    required this.title,
    required this.note,
    required this.value,
    required this.onChanged,
    this.accent = AppColors.primary,
    this.min = 0,
  });

  final IconData icon;
  final String title;
  final String note;
  final int value;
  final ValueChanged<int> onChanged;
  final Color accent;
  final int min;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: const BoxDecoration(color: Color(0xFFF7F7F7), shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(note, style: AppTextStyles.small.copyWith(fontSize: 11, color: const Color(0xFFC4C4C4), height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Counter(value: value, onChanged: onChanged, min: min),
        ],
      ),
    );
  }
}

/// 100 x 98 tinted tile with an emoji/icon and a two-line caption (house sizes, office sizes…).
class SizeTile extends StatelessWidget {
  const SizeTile({
    super.key,
    required this.visual,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.tint,
    this.caption,
    this.accent = AppColors.primary,
  });

  final Widget visual;
  final String title;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 98,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? accent : Colors.transparent, width: 2),
              boxShadow: selected ? [BoxShadow(color: accent.withAlpha(50), blurRadius: 14, offset: const Offset(0, 6))] : null,
            ),
            child: Center(child: AnimatedScale(scale: selected ? 1.12 : 1, duration: const Duration(milliseconds: 220), child: visual)),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headline6.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600)),
          if (caption != null)
            Text(caption!, textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 10, color: const Color(0xFFBDBDBD))),
        ],
      ),
    );
  }
}

/// Round furniture item with a count badge.
class ItemBubble extends StatelessWidget {
  const ItemBubble({super.key, required this.icon, required this.label, required this.color, required this.count, required this.onTap, this.onLongPress});

  final IconData icon;
  final String label;
  final Color color;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 53,
                  height: 53,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, color, active ? 0.22 : 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: active ? color : Colors.transparent, width: 1.2),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (active)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                      child: Text('$count', style: AppTextStyles.smallBold.copyWith(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.dark, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// White pill under the header summarising the order so far.
class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key, required this.items});
  final List<(Widget, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28), top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(14), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 34, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
            Expanded(
              child: Row(
                children: [
                  items[i].$1,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(items[i].$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headline6.copyWith(fontSize: 11, height: 1.3, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Month calendar, Monday first. Past days are disabled.
class CalendarPicker extends StatefulWidget {
  const CalendarPicker({super.key, required this.selected, required this.onSelect, this.accent = AppColors.primary, this.pillHeader = false});

  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final Color accent;

  /// Orange pill month header (vehicle flow) instead of the big title.
  final bool pillHeader;

  @override
  State<CalendarPicker> createState() => _CalendarPickerState();
}

class _CalendarPickerState extends State<CalendarPicker> {
  late DateTime _month = DateTime((widget.selected ?? DateTime.now()).year, (widget.selected ?? DateTime.now()).month);

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  void _shift(int d) => setState(() => _month = DateTime(_month.year, _month.month + d));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1 = Mon
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final canGoBack = DateTime(_month.year, _month.month).isAfter(DateTime(now.year, now.month));
    final label = '${_months[_month.month - 1]}, ${_month.year}';

    Widget arrow(IconData icon, VoidCallback? onTap, {bool light = false}) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: light ? Colors.transparent : Colors.white,
              shape: BoxShape.circle,
              boxShadow: light ? null : [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, size: 20, color: light ? Colors.white : (onTap == null ? AppColors.label : AppColors.dark)),
          ),
        );

    return Column(
      children: [
        if (widget.pillHeader)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                arrow(Icons.arrow_back_rounded, canGoBack ? () => _shift(-1) : null, light: true),
                Expanded(child: Text(label.replaceFirst(',', ','), textAlign: TextAlign.center, style: AppTextStyles.navTitle.copyWith(color: Colors.white, fontSize: 16))),
                arrow(Icons.arrow_forward_rounded, () => _shift(1), light: true),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: AppTextStyles.headline1.copyWith(fontSize: 34)),
                ),
              ),
              arrow(Icons.arrow_back_rounded, canGoBack ? () => _shift(-1) : null),
              const SizedBox(width: 6),
              arrow(Icons.arrow_forward_rounded, () => _shift(1)),
            ],
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            for (final d in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
              Expanded(
                child: Text(d,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(color: widget.accent, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: GridView.builder(
            key: ValueKey(_month),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 43),
            itemCount: firstWeekday - 1 + days,
            itemBuilder: (context, i) {
              final day = i - (firstWeekday - 1) + 1;
              if (day < 1) return const SizedBox.shrink();
              final date = DateTime(_month.year, _month.month, day);
              final past = date.isBefore(today);
              final sel = widget.selected != null &&
                  widget.selected!.year == date.year &&
                  widget.selected!.month == date.month &&
                  widget.selected!.day == date.day;
              return GestureDetector(
                onTap: past ? null : () => widget.onSelect(date),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 35,
                    height: 35,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: sel ? widget.accent : Colors.transparent, shape: BoxShape.circle),
                    child: Text(
                      '$day',
                      style: AppTextStyles.small.copyWith(
                        fontSize: 14,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : (past ? const Color(0xFFBDBDBD) : AppColors.dark),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Horizontal list of pill choices (time slots, periods).
class PillChoices extends StatelessWidget {
  const PillChoices({super.key, required this.options, required this.selected, required this.onSelect, this.accent = AppColors.primary, this.big = false});

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final Color accent;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final o = options[i];
          final sel = o == selected;
          return GestureDetector(
            onTap: () => onSelect(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: big ? 26 : 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? accent : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: sel ? accent : const Color(0xFFE2E2E2), width: 2),
              ),
              child: Text(o, style: AppTextStyles.navTitle.copyWith(fontSize: 15, color: sel ? Colors.white : AppColors.dark)),
            ),
          );
        },
      ),
    );
  }
}

/// Teardrop pin used on all maps.
class MapPin extends StatelessWidget {
  const MapPin({super.key, this.color = AppColors.yellow, this.icon = Icons.location_on_rounded, this.size = 44});
  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

/// Muted OpenStreetMap (free) matching the grey map style in the designs.
class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers = const [],
    this.controller,
    this.interactive = true,
    this.onPositionChanged,
    this.fitPoints,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final MapController? controller;
  final bool interactive;
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;
  final List<LatLng>? fitPoints;

  static const _grey = ColorFilter.matrix(<double>[
    0.2, 0.4, 0.08, 0, 78, //
    0.2, 0.4, 0.08, 0, 78,
    0.2, 0.4, 0.08, 0, 78,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final fit = fitPoints != null && fitPoints!.length > 1
        ? CameraFit.coordinates(coordinates: fitPoints!, padding: const EdgeInsets.all(50), maxZoom: 16)
        : null;
    final map = FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        initialCameraFit: fit,
        interactionOptions: InteractionOptions(flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
        onPositionChanged: onPositionChanged,
        backgroundColor: const Color(0xFFEBEBEB),
      ),
      children: [
        ColorFiltered(
          colorFilter: _grey,
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.vastagency.shifty',
          ),
        ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
    return interactive ? map : IgnorePointer(child: map);
  }
}

/// Round white button with a crosshair (go to my location).
class LocateButton extends StatelessWidget {
  const LocateButton({super.key, required this.onTap, this.busy = false});
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: busy
            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark))
            : const Icon(Icons.my_location_rounded, color: AppColors.dark, size: 22),
      ),
    );
  }
}

/// Top handle notch on white sheets that sit over maps.
class SheetNotch extends StatelessWidget {
  const SheetNotch({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 6,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}

/// Small checkbox with label ("Include cleaning instruments").
class CheckLine extends StatelessWidget {
  const CheckLine({super.key, required this.value, required this.onChanged, required this.label, this.accent = AppColors.primary});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: value ? accent : AppColors.field, borderRadius: BorderRadius.circular(3)),
            child: value ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
          ),
          const SizedBox(width: 14),
          Text(label, style: AppTextStyles.small.copyWith(fontSize: 12, color: const Color(0xFF8A8A8A))),
        ],
      ),
    );
  }
}

void showError(BuildContext context, Object e) {
  var msg = e.toString();
  final m = RegExp(r'message: ([^,]+)').firstMatch(msg);
  if (m != null) msg = m.group(1)!;
  if (msg.length > 140) msg = 'Something went wrong. Please try again.';
  showAppSnack(context, msg, error: true);
}
