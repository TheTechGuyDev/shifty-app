import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/service_icons.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../offers/offer_widgets.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';
import 'location_screens.dart';
import 'schedule_screen.dart';

const bookingSetupRoute = 'booking-setup';

/// Entry point for booking any service.
void startBooking(BuildContext context, ServiceCategory service) {
  Navigator.of(context).push(appRoute(ServiceSetupScreen(draft: BookingDraft(service)), name: bookingSetupRoute));
}

class _SizeOption {
  const _SizeOption(this.key, this.title, this.emoji, this.tint, {this.caption, this.icon, this.iconColor});
  final String key;
  final String title;
  final String? caption;
  final String emoji;
  final IconData? icon;
  final Color? iconColor;
  final Color tint;
}

class _Item {
  const _Item(this.key, this.label, this.icon, this.color);
  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

const _houseSizes = [
  _SizeOption('2bed', '2 Bedrooms\n1 Kitchen', '🏡', Color(0xFFFDEDE1)),
  _SizeOption('3bed', '3 Bedrooms\n1 Kitchen', '🏠', Color(0xFFE8F4FB)),
  _SizeOption('4bed', '4 Bedrooms\n1 Kitchen', '🏚️', Color(0xFFFCE9E9)),
];

const _officeSizes = [
  _SizeOption('small', 'Small Office', '', Color(0xFFE6F6FC), caption: '2 or less rooms', icon: Icons.apartment_rounded, iconColor: Color(0xFF1F7A9C)),
  _SizeOption('large', 'Large Office', '', Color(0xFFFFF6DA), caption: '3 rooms', icon: Icons.location_city_rounded, iconColor: Color(0xFFF2A516)),
  _SizeOption('multiple', 'Multiple Office', '', Color(0xFFFFE6DF), caption: '4 or more rooms', icon: Icons.domain_rounded, iconColor: Color(0xFFEA5B3A)),
];

const _paintSizes = [
  _SizeOption('full', 'Full House', '🏡', Color(0xFFFDEDE1), caption: '3 room, 1 Kitchen'),
  _SizeOption('large', 'Large House', '🏠', Color(0xFFE8F4FB), caption: '4 room, 2 Kitchen'),
  _SizeOption('others', 'Others', '🏚️', Color(0xFFFCE9E9), caption: 'Backyard & Garage'),
];

const _cleanSizes = [
  _SizeOption('2bed', '2 Bedrooms\n1 Kitchen', '🏡', Color(0xFFFDEDE1)),
  _SizeOption('3bed', '3 Bedrooms\n1 Kitchen', '🏠', Color(0xFFE8F4FB)),
  _SizeOption('4bed', '4 Bedrooms\n1 Kitchen', '🏚️', Color(0xFFF1EAFB)),
];

const _houseItems = [
  _Item('bed', 'Bed', Icons.bed_rounded, Color(0xFF6C7BF2)),
  _Item('sofa', 'Sofa', Icons.weekend_rounded, Color(0xFFF27E3F)),
  _Item('chair', 'Chair', Icons.chair_rounded, Color(0xFF3FA9F5)),
  _Item('almira', 'Almira', Icons.door_sliding_rounded, Color(0xFFF2994A)),
  _Item('ac', 'AC', Icons.ac_unit_rounded, Color(0xFFEB5757)),
  _Item('fridge', 'Fridge', Icons.kitchen_rounded, Color(0xFF56CCF2)),
  _Item('oven', 'Oven', Icons.microwave_rounded, Color(0xFFF2C94C)),
  _Item('tv', 'TV', Icons.tv_rounded, Color(0xFF27AE60)),
  _Item('wardrobe', 'Wardrobe', Icons.checkroom_rounded, Color(0xFFD86BD8)),
];

const _officeItems = [
  _Item('table', 'Table', Icons.table_restaurant_rounded, Color(0xFF6C7BF2)),
  _Item('sofa', 'Sofa', Icons.weekend_rounded, Color(0xFFF27E3F)),
  _Item('chair', 'Chair', Icons.chair_rounded, Color(0xFF3FA9F5)),
  _Item('ac', 'AC', Icons.ac_unit_rounded, Color(0xFFEB5757)),
  _Item('computer', 'Computer', Icons.desktop_windows_rounded, Color(0xFF27AE60)),
  _Item('cabinet', 'Cabinet', Icons.inventory_2_rounded, Color(0xFFF2994A)),
];

const _paintColors = [
  ('Sunshine Yellow', Color(0xFFFDB921)),
  ('Lavender', Color(0xFF7B61E8)),
  ('Emerald', Color(0xFF15A46B)),
  ('Brick Red', Color(0xFFE84B1A)),
  ('Ocean Blue', Color(0xFF3F8CFF)),
  ('Cream White', Color(0xFFF3EBD8)),
  ('Charcoal', Color(0xFF3A3D42)),
];

class ServiceSetupScreen extends StatefulWidget {
  const ServiceSetupScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<ServiceSetupScreen> createState() => _ServiceSetupScreenState();
}

class _ServiceSetupScreenState extends State<ServiceSetupScreen> {
  BookingDraft get d => widget.draft;
  late final Future<List<Offer>> _offers = DataService.offersForService(d.service.slug);
  final _notes = TextEditingController();
  final _customItems = <_Item>[];

  @override
  void initState() {
    super.initState();
    switch (d.kind) {
      case BookingKind.cleaning:
        d.details.putIfAbsent('persons', () => 1);
        d.details.putIfAbsent('hours', () => 2);
      case BookingKind.painting:
        d.details.putIfAbsent('persons', () => 1);
      case BookingKind.commercial:
        d.details.putIfAbsent('size', () => 'large');
        d.details.putIfAbsent('industry', () => 'Retail Store');
      case BookingKind.vehicle:
        d.details.putIfAbsent('vehicle', () => 'mini');
      case BookingKind.generic:
        d.details.putIfAbsent('workers', () => 1);
      default:
        break;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _set(String key, dynamic v) => setState(() => d.details[key] = v);

  void _selectSize(_SizeOption o) => setState(() {
        d.details['size'] = o.key;
        d.details['size_label'] = o.title.replaceAll('\n', ', ');
      });

  Future<void> _custom() async {
    final ctrl = TextEditingController(text: d.details['custom_note'] as String? ?? '');
    final res = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Describe your space', style: AppTextStyles.navTitle),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          cursorColor: d.accent,
          decoration: InputDecoration(
            hintText: 'e.g. 5 bedrooms, 2 living rooms, 1 store',
            filled: true,
            fillColor: AppColors.field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text('Save', style: TextStyle(color: d.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      setState(() {
        d.details['size'] = 'custom';
        d.details['custom_note'] = res;
        d.details['size_label'] = 'Custom: $res';
      });
    }
  }

  Future<void> _addCustomItem() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add an item', style: AppTextStyles.navTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Piano, Treadmill'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: Text('Add', style: TextStyle(color: d.accent))),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final key = 'custom_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
      setState(() {
        _customItems.add(_Item(key, name, Icons.inventory_rounded, const Color(0xFF8E8E93)));
        _bump(key, 1);
      });
    }
  }

  void _bump(String key, int delta) {
    final f = Map<String, int>.from(d.furniture);
    final v = ((f[key] ?? 0) + delta).clamp(0, 50);
    if (v == 0) {
      f.remove(key);
    } else {
      f[key] = v;
    }
    setState(() => d.details['furniture'] = f);
  }

  bool get _ready => switch (d.kind) {
        BookingKind.house || BookingKind.office || BookingKind.cleaning || BookingKind.painting => d.details['size'] != null,
        BookingKind.generic => (_notes.text.trim().length >= 5),
        _ => true,
      };

  void _proceed() {
    if (d.kind == BookingKind.commercial || d.kind == BookingKind.generic) {
      d.details['notes'] = _notes.text.trim();
    }
    if (d.kind == BookingKind.commercial) {
      d.details['size_label'] = 'Commercial · ${d.details['industry']}';
    }
    if (d.kind == BookingKind.generic) d.details['size_label'] = d.service.name;
    if (d.kind == BookingKind.vehicle) {
      Navigator.of(context).push(appRoute(VehicleLocationScreen(draft: d)));
    } else {
      Navigator.of(context).push(appRoute(ScheduleScreen(draft: d)));
    }
  }

  String get _title => switch (d.kind) {
        BookingKind.house => 'House Size',
        BookingKind.office => 'Office Size',
        BookingKind.commercial => 'Industry Size',
        BookingKind.cleaning => 'Cleaning',
        BookingKind.painting => 'Painting',
        BookingKind.vehicle => 'Vehicle',
        BookingKind.generic => d.service.name,
      };

  String get _subtitle => switch (d.kind) {
        BookingKind.house => 'Select your house rooms and kitchen in order to measure the total cost.',
        BookingKind.office => 'Select your Office rooms and boxes in order to measure the total cost.',
        BookingKind.commercial => 'Select your business type and instruments in order to measure the approximate cost.',
        BookingKind.cleaning => 'Select your house rooms and kitchen in order to measure estimated cleaning costs.',
        BookingKind.painting => 'Select your rooms and place correctly in order to measure estimated cost.',
        BookingKind.vehicle => 'Choose vehicle type as your need, we’ll calculate the cost for you.',
        BookingKind.generic => 'Tell us what you need done and we’ll match you with a verified professional.',
      };

  @override
  Widget build(BuildContext context) {
    final accent = d.accent;
    final showCustom = d.kind == BookingKind.house || d.kind == BookingKind.office || d.kind == BookingKind.cleaning || d.kind == BookingKind.painting;
    final leading = switch (d.kind) {
      BookingKind.cleaning || BookingKind.painting || BookingKind.vehicle || BookingKind.generic =>
        Icon(iconFor(d.service.icon), color: d.kind == BookingKind.generic ? d.service.color : accent, size: 40),
      _ => null,
    };

    return ServiceChrome(
      title: '${d.service.name}${d.service.name.toLowerCase().endsWith('service') ? '' : ' Service'}',
      bottom: PrimaryButton(label: 'Proceed', color: accent, enabled: _ready, onPressed: _proceed),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          BookingHeading(
            title: _title,
            subtitle: _subtitle,
            leading: leading,
            accent: accent,
            actionLabel: showCustom ? 'Custom' : (d.kind == BookingKind.commercial ? 'Add' : null),
            actionActive: d.details['size'] == 'custom',
            onAction: d.kind == BookingKind.commercial ? _addCustomItem : _custom,
          ),
          if (d.kind == BookingKind.cleaning || d.kind == BookingKind.painting || d.kind == BookingKind.vehicle) ...[
            const SizedBox(height: 22),
            _OfferStrip(future: _offers),
          ],
          const SizedBox(height: 26),
          ..._body(accent),
        ],
      ),
    );
  }

  List<Widget> _body(Color accent) {
    switch (d.kind) {
      case BookingKind.house:
        return [
          _sizes(_houseSizes, accent),
          const SizedBox(height: 26),
          const SectionBand(),
          _items('Furnitures', _houseItems, accent),
          const SectionBand(),
          const SizedBox(height: 10),
          CounterRow(
            icon: Icons.inventory_2_rounded,
            title: 'Packed Boxes',
            note: 'Weight below 10 Kg',
            value: d.count('boxes'),
            onChanged: (v) => _set('boxes', v),
            accent: accent,
          ),
        ];
      case BookingKind.office:
        return [
          _sizes(_officeSizes, accent),
          const SizedBox(height: 26),
          const SectionBand(),
          _items('Office Items', _officeItems, accent, countLabel: 'Selected'),
          const SectionBand(),
          const SizedBox(height: 10),
          CounterRow(icon: Icons.inventory_2_rounded, title: 'Packed Boxes', note: 'Weight below 10 Kg', value: d.count('boxes'), onChanged: (v) => _set('boxes', v), accent: accent),
          CounterRow(icon: Icons.engineering_rounded, title: 'Workers', note: 'Regular cost is ₦5,000 each. Total cost will be calculated later', value: d.count('workers'), onChanged: (v) => _set('workers', v), accent: accent),
          CounterRow(icon: Icons.bolt_rounded, title: 'Electrician', note: 'Regular cost is ₦8,000 each. Total cost will be calculated later', value: d.count('electricians'), onChanged: (v) => _set('electricians', v), accent: accent),
        ];
      case BookingKind.commercial:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('FLOOR SIZE'),
                _dropdown(
                  value: d.details['size'] as String,
                  items: const {'small': 'Small (under 100 Sqft)', 'medium': 'Medium (100-200 Sqft)', 'large': 'Large (200 Sqft+)'},
                  onChanged: (v) => _set('size', v),
                ),
                const SizedBox(height: 22),
                _label('INDUSTRY TYPE'),
                _dropdown(
                  value: d.details['industry'] as String,
                  items: const {
                    'Retail Store': 'Retail Store',
                    'Warehouse': 'Warehouse',
                    'Restaurant': 'Restaurant',
                    'Chemical Supplier': 'Chemical Supplier',
                    'Factory': 'Factory',
                    'Hospital / Clinic': 'Hospital / Clinic',
                    'School': 'School',
                    'Other': 'Other',
                  },
                  onChanged: (v) => _set('industry', v),
                ),
                const SizedBox(height: 22),
                _label('NOTES'),
                _notesField('Type here...'),
                if (_customItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final it in _customItems)
                        Chip(
                          label: Text('${it.label} × ${d.furniture[it.key] ?? 0}'),
                          onDeleted: () => setState(() {
                            _bump(it.key, -(d.furniture[it.key] ?? 0));
                            _customItems.remove(it);
                          }),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionBand(),
          const SizedBox(height: 10),
          CounterRow(icon: Icons.precision_manufacturing_rounded, title: 'Heavy Item', note: 'For automated machines we charge ₦5,000 per item', value: d.count('heavy'), onChanged: (v) => _set('heavy', v), accent: accent),
          CounterRow(icon: Icons.engineering_rounded, title: 'Workers', note: 'Regular cost is ₦5,000 each. Total cost will be calculated later', value: d.count('workers'), onChanged: (v) => _set('workers', v), accent: accent),
          CounterRow(icon: Icons.bolt_rounded, title: 'Electrician', note: 'Regular cost is ₦8,000 each. Total cost will be calculated later', value: d.count('electricians'), onChanged: (v) => _set('electricians', v), accent: accent),
        ];
      case BookingKind.cleaning:
        return [
          _sizes(_cleanSizes, accent),
          const SizedBox(height: 22),
          CounterRow(icon: Icons.person_rounded, title: 'Required Person', note: 'Regular cost is ₦2,000/hr. Total cost will be calculated later', value: d.count('persons'), min: 1, onChanged: (v) => _set('persons', v), accent: accent),
          CounterRow(icon: Icons.timer_rounded, title: 'Working Hour', note: 'Cost will increase after 2 hrs of work.', value: d.count('hours'), min: 1, onChanged: (v) => _set('hours', v), accent: accent),
        ];
      case BookingKind.painting:
        final color = d.details['color'] as String?;
        return [
          _sizes(_paintSizes, accent),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Text('Choose Color', style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              itemCount: _paintColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final (name, c) = _paintColors[i];
                final sel = color == name;
                return Tooltip(
                  message: name,
                  child: GestureDetector(
                    onTap: () => _set('color', name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color.lerp(c, Colors.white, 0.15)!, c], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        border: Border.all(color: sel ? AppColors.dark : Colors.transparent, width: 3),
                      ),
                      child: sel ? const Icon(Icons.check_rounded, color: Colors.white) : null,
                    ),
                  ),
                );
              },
            ),
          ),
          if (color != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
              child: Text('Selected: $color', style: AppTextStyles.small.copyWith(fontSize: 12)),
            ),
          const SizedBox(height: 22),
          const SectionBand(),
          const SizedBox(height: 10),
          CounterRow(icon: Icons.person_rounded, title: 'Required Person', note: 'Regular cost is ₦6,000 each. Total cost will be calculated later', value: d.count('persons'), min: 1, onChanged: (v) => _set('persons', v), accent: accent),
        ];
      case BookingKind.vehicle:
        return [_vehicles(accent)];
      case BookingKind.generic:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.service.requiresVerification)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFE9F7EC), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Only professionals with checked qualifications can take this job.',
                              style: AppTextStyles.small.copyWith(color: const Color(0xFF2E7D45))),
                        ),
                      ],
                    ),
                  ),
                _label('DESCRIBE THE JOB'),
                _notesField('What do you need done? Add sizes, brands, problems…', onChanged: (_) => setState(() {})),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionBand(),
          const SizedBox(height: 10),
          CounterRow(icon: Icons.person_rounded, title: 'Professionals needed', note: 'Call-out fee ₦5,000. Final price agreed with the professional', value: d.count('workers'), min: 1, onChanged: (v) => _set('workers', v), accent: accent),
        ];
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: AppTextStyles.small.copyWith(fontSize: 11, letterSpacing: 0.8, color: const Color(0xFF6B6B6B), fontWeight: FontWeight.w500)),
      );

  Widget _notesField(String hint, {ValueChanged<String>? onChanged}) => TextField(
        controller: _notes,
        maxLines: 5,
        minLines: 4,
        onChanged: onChanged,
        cursorColor: d.accent,
        style: AppTextStyles.input.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.small.copyWith(color: const Color(0xFFC4C4C4)),
          filled: true,
          fillColor: const Color(0xFFF7F9F8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );

  Widget _dropdown({required String value, required Map<String, String> items, required ValueChanged<String> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF7F9F8), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFC4C4C4)),
          style: AppTextStyles.headline6.copyWith(fontSize: 14),
          items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }

  Widget _sizes(List<_SizeOption> options, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: SizeTile(
                accent: accent,
                tint: options[i].tint,
                title: options[i].title,
                caption: options[i].caption,
                selected: d.details['size'] == options[i].key,
                onTap: () => _selectSize(options[i]),
                visual: options[i].icon != null
                    ? Icon(options[i].icon, size: 44, color: options[i].iconColor)
                    : Text(options[i].emoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _items(String title, List<_Item> items, Color accent, {String countLabel = 'Item'}) {
    final all = [...items, ..._customItems];
    final total = d.furnitureTotal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
                    Row(
                      children: [
                        Text('Tap to add · hold to remove', style: AppTextStyles.small.copyWith(fontSize: 11, color: const Color(0xFFC4C4C4))),
                        const SizedBox(width: 6),
                        const Icon(Icons.info_rounded, size: 13, color: Color(0xFFC4C4C4)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: total == 0 ? null : () => setState(() => d.details['furniture'] = <String, int>{}),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  decoration: BoxDecoration(color: total == 0 ? const Color(0xFFD9D9D9) : const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total $countLabel', style: AppTextStyles.smallBold.copyWith(color: AppColors.dark, fontSize: 12)),
                      if (total > 0) ...[const SizedBox(width: 6), const Icon(Icons.close_rounded, size: 14)],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: ((MediaQuery.sizeOf(context).width.clamp(300.0, 430.0) - 52 - 300) / 4).clamp(4.0, 30.0),
            runSpacing: 18,
            children: [
              for (final it in all)
                ItemBubble(
                  icon: it.icon,
                  label: it.label,
                  color: it.color,
                  count: d.furniture[it.key] ?? 0,
                  onTap: () => _bump(it.key, 1),
                  onLongPress: () => _bump(it.key, -1),
                ),
              GestureDetector(
                onTap: _addCustomItem,
                child: SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      Container(
                        width: 53,
                        height: 53,
                        decoration: BoxDecoration(color: Color.lerp(Colors.white, accent, 0.12), shape: BoxShape.circle),
                        child: Center(
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Add', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.dark, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicles(Color accent) {
    const options = [
      ('mini', 'Mini Truck', '~ 1.8 Ton, 9 Feet', 'assets/images/app/vehicle_mini.png'),
      ('pickup', 'Pickup', '~ 1.2 Ton, 7 Feet', 'assets/images/app/vehicle_pickup.png'),
      ('large', 'Large Truck', '~ 5 Ton, 14 Feet', 'assets/images/app/vehicle_large.png'),
      ('custom', 'Custom Order', '+8 Ton, 20 Feet', null),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 22,
        crossAxisSpacing: 22,
        childAspectRatio: 150 / 166,
        children: [
          for (final (key, name, cap, img) in options)
            GestureDetector(
              onTap: () => _set('vehicle', key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: d.details['vehicle'] == key ? accent : const Color(0xFFE2E2E2), width: d.details['vehicle'] == key ? 2 : 1),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: img != null
                            ? Padding(padding: const EdgeInsets.all(12), child: Image.asset(img, fit: BoxFit.contain))
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.add_rounded, color: accent, size: 30),
                              ),
                      ),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.border),
                    const SizedBox(height: 10),
                    Text(name, style: AppTextStyles.headline6.copyWith(fontSize: 14)),
                    Text(cap, style: AppTextStyles.small.copyWith(fontSize: 10, color: const Color(0xFFBDBDBD))),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Banner strip at the top of service pages.
class _OfferStrip extends StatelessWidget {
  const _OfferStrip({required this.future});
  final Future<List<Offer>> future;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 137,
      child: FutureBuilder<List<Offer>>(
        future: future,
        builder: (context, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemBuilder: (context, i) => OfferBanner(offer: list[i]),
          );
        },
      ),
    );
  }
}
