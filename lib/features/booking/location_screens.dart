import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/services/geo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';
import 'order_screens.dart';
import 'schedule_screen.dart';

/// Full-screen map to choose an address. The pin stays in the centre; move the map under it.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, required this.title, this.initial, this.pinColor = AppColors.yellow, this.accent = AppColors.primary});

  final String title;
  final Place? initial;
  final Color pinColor;
  final Color accent;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _map = MapController();
  late LatLng _center = widget.initial?.point ?? GeoService.fallback;
  String _address = '';
  bool _loading = false;
  bool _locating = false;
  bool _moving = false;
  Timer? _debounce;
  final _search = TextEditingController();
  List<Place> _results = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _address = widget.initial!.address;
    } else {
      _locate(initial: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() => _loading = true);
    final a = await GeoService.reverse(_center);
    if (mounted) setState(() {
      _address = a;
      _loading = false;
    });
  }

  Future<void> _locate({bool initial = false}) async {
    setState(() => _locating = true);
    final p = await GeoService.currentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (p == null) {
      if (!initial) showAppSnack(context, 'Could not get your location. Allow location access or move the map.', error: true);
      _resolve();
      return;
    }
    _center = p;
    _map.move(p, 16.5);
    _resolve();
  }

  void _onSearch(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      final r = await GeoService.search(q);
      if (mounted) setState(() => _results = r);
    });
  }

  void _pick(Place p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _results = [];
      _center = p.point;
      _address = p.address;
      _search.clear();
    });
    _map.move(p.point, 16.5);
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: widget.title,
      bottom: PrimaryButton(
        label: 'Confirm',
        color: widget.accent,
        enabled: _address.isNotEmpty && !_loading && !_moving,
        onPressed: () => Navigator.pop(context, Place(_address, _center)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AppMap(
              center: _center,
              zoom: 16,
              controller: _map,
              onPositionChanged: (camera, gesture) {
                _center = camera.center;
                if (gesture) {
                  if (!_moving) setState(() => _moving = true);
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 700), () {
                    if (!mounted) return;
                    setState(() => _moving = false);
                    _resolve();
                  });
                }
              },
            ),
          ),
          // Centre pin.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: AnimatedSlide(
                  offset: Offset(0, _moving ? -0.15 : 0),
                  duration: const Duration(milliseconds: 160),
                  child: MapPin(color: widget.pinColor, size: 48),
                ),
              ),
            ),
          ),
          Positioned(
            left: 26,
            right: 26,
            top: 34,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.dark, width: 5)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: _onSearch,
                          style: AppTextStyles.headline6.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: _loading ? 'Finding address…' : (_address.isEmpty ? 'Search address' : _address),
                            hintStyle: AppTextStyles.headline6.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      const Icon(Icons.search_rounded, color: AppColors.label),
                    ],
                  ),
                ),
                if (_results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 16)],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined, color: AppColors.label),
                        title: Text(_results[i].address, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(color: AppColors.dark)),
                        onTap: () => _pick(_results[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(right: 26, bottom: 30, child: LocateButton(onTap: _locate, busy: _locating)),
          const Positioned(
            left: 8,
            bottom: 6,
            child: Text('© OpenStreetMap', style: TextStyle(fontSize: 9, color: Color(0xFF8A8A8A))),
          ),
        ],
      ),
    );
  }
}

Future<Place?> pickPlace(BuildContext context, {required String title, Place? initial, Color pin = AppColors.yellow, Color accent = AppColors.primary}) {
  return Navigator.of(context).push<Place>(appRoute(MapPickerScreen(title: title, initial: initial, pinColor: pin, accent: accent)));
}

/// Shared start point: the saved home address, else current location.
Future<Place?> defaultPlace() async {
  try {
    final saved = await DataService.addresses();
    final home = saved.where((a) => a.label == 'home' && a.lat != null).toList();
    if (home.isNotEmpty) return Place(home.first.address, LatLng(home.first.lat!, home.first.lng!));
  } catch (_) {}
  final p = await GeoService.currentLocation();
  if (p == null) return null;
  return Place(await GeoService.reverse(p), p);
}

class _PointRow extends StatelessWidget {
  const _PointRow({required this.isDropoff, required this.text, required this.onTap, this.onClear, this.placeholder = ''});
  final bool isDropoff;
  final String? text;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (isDropoff)
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
              child: Text(
                text ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headline6.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: text == null ? AppColors.label : AppColors.dark,
                ),
              ),
            ),
            if (onClear != null && text != null)
              IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.dark))
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.dark),
          ],
        ),
      ),
    );
  }
}

/// Location step: pickup + destination + vehicle for moving jobs, single address for others.
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  BookingDraft get d => widget.draft;
  List<SavedAddress> _saved = [];
  bool _locating = false;
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    DataService.addresses().then((v) {
      if (mounted) setState(() => _saved = v);
    }).catchError((_) {});
    if (d.address == null) _autoLocate();
    if (d.twoPoints) d.details.putIfAbsent('vehicle', () => 'mini');
  }

  Future<void> _autoLocate() async {
    setState(() => _locating = true);
    final p = await defaultPlace();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (p != null && d.address == null) {
        d.address = p.address;
        d.point = p.point;
      }
    });
    _fit();
  }

  void _fit() {
    final pts = [if (d.point != null) d.point!, if (d.dropoffPoint != null) d.dropoffPoint!];
    try {
      if (pts.length == 2) {
        _map.fitCamera(CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.fromLTRB(60, 120, 60, 60)));
      } else if (pts.length == 1) {
        _map.move(pts.first, 16);
      }
    } catch (_) {}
  }

  Future<void> _pickPickup() async {
    final p = await pickPlace(context,
        title: d.twoPoints ? 'Loading Point' : 'Select Location',
        initial: d.point == null ? null : Place(d.address!, d.point!),
        pin: d.twoPoints ? AppColors.primary : d.accent,
        accent: d.accent);
    if (p != null) {
      setState(() {
        d.address = p.address;
        d.point = p.point;
      });
      _fit();
    }
  }

  Future<void> _pickDropoff() async {
    final p = await pickPlace(context,
        title: 'Select Destination',
        initial: d.dropoffPoint == null ? null : Place(d.dropoffAddress!, d.dropoffPoint!),
        accent: d.accent);
    if (p != null) {
      setState(() {
        d.dropoffAddress = p.address;
        d.dropoffPoint = p.point;
      });
      _fit();
    }
  }

  Future<void> _useSaved(String label) async {
    final match = _saved.where((a) => a.label == label).toList();
    if (match.isNotEmpty && match.first.lat != null) {
      setState(() {
        d.address = match.first.address;
        d.point = LatLng(match.first.lat!, match.first.lng!);
      });
      _fit();
      return;
    }
    // Not saved yet: pick on the map and save it.
    final p = await pickPlace(context, title: label == 'home' ? 'Set Home' : (label == 'work' ? 'Set Work' : 'Add New'), accent: d.accent, pin: d.accent);
    if (p == null) return;
    setState(() {
      d.address = p.address;
      d.point = p.point;
    });
    _fit();
    if (DataService.signedIn) {
      try {
        final a = await DataService.addAddress(label, p.address, p.point.latitude, p.point.longitude);
        setState(() => _saved = [..._saved.where((s) => label == 'other' || s.label != label), a]);
        if (mounted) showAppSnack(context, 'Saved to your locations');
      } catch (_) {}
    }
  }

  bool get _ready => d.address != null && (!d.twoPoints || d.dropoffAddress != null);

  void _proceed() => Navigator.of(context).push(appRoute(OrderSummaryScreen(draft: d)));

  @override
  Widget build(BuildContext context) {
    final when = d.scheduledAt;
    final center = d.point ?? GeoService.fallback;
    final markers = <Marker>[
      if (d.point != null)
        Marker(point: d.point!, width: 48, height: 48, child: MapPin(color: d.twoPoints ? AppColors.primary : d.accent)),
      if (d.dropoffPoint != null)
        Marker(point: d.dropoffPoint!, width: 48, height: 48, child: const MapPin(color: AppColors.yellow)),
    ];

    final summary = d.twoPoints
        ? movingSummary(d)
        : <(Widget, String)>[
            (const Text('🏡', style: TextStyle(fontSize: 22)), d.sizeLabel),
            (Icon(Icons.person_rounded, color: d.accent), '${d.count(d.kind == BookingKind.generic ? 'workers' : 'persons').clamp(1, 99)} Person'),
          ];

    return ServiceChrome(
      title: when == null ? 'Location' : longDate(when),
      subtitle: when == null ? null : timeOf(when),
      bottom: PrimaryButton(label: 'Proceed', color: d.accent, enabled: _ready, onPressed: _proceed),
      body: Column(
        children: [
          SummaryBar(items: summary),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppMap(
                    center: center,
                    controller: _map,
                    markers: markers,
                    fitPoints: [if (d.point != null) d.point!, if (d.dropoffPoint != null) d.dropoffPoint!],
                  ),
                ),
                Positioned(
                  right: 26,
                  bottom: 16,
                  child: LocateButton(
                    busy: _locating,
                    onTap: () async {
                      setState(() => _locating = true);
                      final p = await GeoService.currentLocation();
                      if (!mounted) return;
                      setState(() => _locating = false);
                      if (p == null) {
                        showAppSnack(context, 'Could not get your location', error: true);
                        return;
                      }
                      final a = await GeoService.reverse(p);
                      setState(() {
                        d.address = a;
                        d.point = p;
                      });
                      _fit();
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            transform: Matrix4.translationValues(0, -24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetNotch(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 10, 44, 0),
                  child: Column(
                    children: [
                      _PointRow(
                        isDropoff: !d.twoPoints,
                        text: _locating && d.address == null ? 'Finding your location…' : d.address,
                        placeholder: d.twoPoints ? 'Loading point' : 'Choose your location',
                        onTap: _pickPickup,
                        onClear: d.twoPoints ? null : () => setState(() {
                          d.address = null;
                          d.point = null;
                        }),
                      ),
                      if (d.twoPoints) ...[
                        Row(children: [
                          const SizedBox(width: 10),
                          Container(width: 1.5, height: 14, color: AppColors.success),
                          const SizedBox(width: 14),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ]),
                        _PointRow(isDropoff: true, text: d.dropoffAddress, placeholder: 'Destination', onTap: _pickDropoff),
                      ] else
                        const Divider(color: AppColors.border, height: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (d.twoPoints) _vehicleRow() else _savedRow(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedRow() {
    Widget btn(String label, IconData icon, String key) {
      final has = _saved.any((a) => a.label == key);
      final active = has && _saved.firstWhere((a) => a.label == key).address == d.address;
      return GestureDetector(
        onTap: () => _useSaved(key),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 73,
              height: 73,
              decoration: BoxDecoration(
                color: active ? Color.lerp(Colors.white, d.accent, 0.18) : const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: key == 'home' ? d.accent : AppColors.dark, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.headline6.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          btn('Home', Icons.home_rounded, 'home'),
          btn('Work', Icons.work_rounded, 'work'),
          btn('Add New', Icons.add_location_alt_rounded, 'other'),
        ],
      ),
    );
  }

  Widget _vehicleRow() {
    const options = [
      ('mini', 'Mini Truck', '~ 1.8 Ton', 'assets/images/app/vehicle_mini.png'),
      ('pickup', 'Pickup', '~ 1.2 Ton', 'assets/images/app/vehicle_pickup.png'),
      ('large', 'Large Truck', '~ 5 Ton', 'assets/images/app/vehicle_large.png'),
    ];
    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(44, 10, 26, 0),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (key, name, cap, img) = options[i];
          final sel = d.details['vehicle'] == key;
          return GestureDetector(
            onTap: () => setState(() => d.details['vehicle'] = key),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 115,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.dark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? AppColors.dark : const Color(0xFFDDDDDD)),
                  ),
                  child: Column(
                    children: [
                      Expanded(child: Padding(padding: const EdgeInsets.all(10), child: Image.asset(img, fit: BoxFit.contain))),
                      Divider(height: 1, color: sel ? Colors.white24 : AppColors.border),
                      const SizedBox(height: 8),
                      Text(name, style: AppTextStyles.headline6.copyWith(fontSize: 13, color: sel ? Colors.white : AppColors.dark)),
                      Text(cap, style: AppTextStyles.small.copyWith(fontSize: 10, color: sel ? Colors.white70 : AppColors.label)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                if (sel)
                  Positioned(
                    right: -6,
                    top: -10,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Vehicle service: loading + unloading points, date, time and workers on one page.
class VehicleLocationScreen extends StatefulWidget {
  const VehicleLocationScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<VehicleLocationScreen> createState() => _VehicleLocationScreenState();
}

class _VehicleLocationScreenState extends State<VehicleLocationScreen> {
  BookingDraft get d => widget.draft;

  bool get _ready => d.address != null && d.dropoffAddress != null && d.scheduledAt != null;

  Future<void> _pick(bool dropoff) async {
    final p = await pickPlace(
      context,
      title: dropoff ? 'Unloading Point' : 'Loading Point',
      initial: dropoff
          ? (d.dropoffPoint == null ? null : Place(d.dropoffAddress!, d.dropoffPoint!))
          : (d.point == null ? null : Place(d.address!, d.point!)),
      pin: dropoff ? AppColors.yellow : AppColors.primary,
    );
    if (p == null) return;
    setState(() {
      if (dropoff) {
        d.dropoffAddress = p.address;
        d.dropoffPoint = p.point;
      } else {
        d.address = p.address;
        d.point = p.point;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final slots = allTimeSlots.where((s) {
      if (d.date == null) return true;
      final t = (BookingDraft(d.service)
            ..date = d.date
            ..timeSlot = s)
          .scheduledAt!;
      return t.isAfter(DateTime.now().add(const Duration(hours: 1)));
    }).toList();

    return ServiceChrome(
      title: 'Confirm Location',
      bottom: PrimaryButton(
        label: 'Proceed',
        enabled: _ready,
        onPressed: () => Navigator.of(context).push(appRoute(OrderSummaryScreen(draft: d))),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 34, 26, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location', style: AppTextStyles.headline1),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Please choose your destination location accurately. For any info call ', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
                  TextSpan(text: AppConfig.supportPhone, style: AppTextStyles.paragraph.copyWith(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ])),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _PointRow(isDropoff: false, text: d.address, placeholder: 'Loading Point', onTap: () => _pick(false)),
                      const Divider(height: 1, color: AppColors.border),
                      _PointRow(isDropoff: true, text: d.dropoffAddress, placeholder: 'Unloading Point', onTap: () => _pick(true)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CalendarPicker(
                  pillHeader: true,
                  selected: d.date,
                  onSelect: (date) => setState(() {
                    d.date = date;
                    d.timeSlot = null;
                  }),
                ),
                const SizedBox(height: 20),
                Text('Pick time', style: AppTextStyles.paragraph.copyWith(fontSize: 15, color: const Color(0xFF9B9B9B))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (d.date == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text('Choose a date first', style: AppTextStyles.small.copyWith(fontSize: 12, color: const Color(0xFFBDBDBD))),
            )
          else
            PillChoices(options: slots, selected: d.timeSlot, onSelect: (s) => setState(() => d.timeSlot = s)),
          const SizedBox(height: 24),
          const SectionBand(),
          const SizedBox(height: 14),
          CounterRow(
            icon: Icons.engineering_rounded,
            title: 'Workers',
            note: 'Regular cost is ₦5,000 each. Total cost will be calculated later',
            value: d.count('workers'),
            onChanged: (v) => setState(() => d.details['workers'] = v),
          ),
        ],
      ),
    );
  }
}
