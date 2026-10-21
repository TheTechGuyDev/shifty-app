import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/primary_button.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key, required this.onBookNow});
  final VoidCallback onBookNow;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

enum _Range { month, all }

class _HistoryTabState extends State<HistoryTab> {
  late Future<List<Booking>> _future = DataService.myBookings();
  _Range _range = _Range.month;
  bool _grid = false;

  Future<void> _refresh() async => setState(() => _future = DataService.myBookings());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(32, 26, 20, 18),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _range = _range == _Range.month ? _Range.all : _Range.month),
                child: Text(_range == _Range.month ? 'This Month' : 'All Time',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _range = _range == _Range.month ? _Range.all : _Range.month),
                icon: const Icon(Icons.tune_rounded, color: AppColors.dark),
              ),
              Container(width: 1, height: 22, color: AppColors.border),
              IconButton(
                onPressed: () => setState(() => _grid = !_grid),
                icon: Icon(_grid ? Icons.view_agenda_rounded : Icons.grid_view_rounded, color: AppColors.dark),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF9F9F9),
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: AsyncView<List<Booking>>(
                future: _future,
                onRetry: _refresh,
                builder: (context, all) {
                  final now = DateTime.now();
                  final list = _range == _Range.all
                      ? all
                      : all.where((b) => b.createdAt.year == now.year && b.createdAt.month == now.month).toList();
                  if (list.isEmpty) {
                    return ListView(
                      children: [
                        EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'No bookings yet',
                          message: _range == _Range.month
                              ? 'Your bookings this month will show here.'
                              : 'Book a service and track it here.',
                          action: PrimaryButton(label: 'Book a service', onPressed: widget.onBookNow),
                        ),
                      ],
                    );
                  }
                  if (_grid) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
                      itemCount: list.length,
                      itemBuilder: (context, i) => _BookingCard(booking: list[i], compact: true),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 150),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (context, i) => _BookingCard(booking: list[i]),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.compact = false});
  final Booking booking;
  final bool compact;

  static const _lagos = LatLng(6.5244, 3.3792);

  (String, Color) get _status => switch (booking.status) {
        BookingStatus.active => ('Active', AppColors.success),
        BookingStatus.cancelled => ('Cancelled', AppColors.warning),
        BookingStatus.done => ('Done', AppColors.dark),
        BookingStatus.pending => ('Pending', AppColors.yellow),
      };

  @override
  Widget build(BuildContext context) {
    final point = booking.lat != null && booking.lng != null ? LatLng(booking.lat!, booking.lng!) : _lagos;
    final date = DateFormat('EEEE, MMM d, y').format(booking.scheduledAt ?? booking.createdAt);
    final (label, color) = _status;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 90 : 132,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(initialCenter: point, initialZoom: 15),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.vastagency.shifty',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: point,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.location_on_rounded, color: AppColors.yellow, size: 22),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  // Grey wash to match the muted map style in the design.
                  const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x33EBEBEB)))),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 6 : 10),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      child: Text(label, style: AppTextStyles.smallBold.copyWith(color: Colors.white, fontSize: compact ? 11 : 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 8 : 20, 14, compact ? 8 : 20, compact ? 8 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.navTitle.copyWith(fontSize: compact ? 14 : 18)),
                const SizedBox(height: 2),
                Text(date, style: AppTextStyles.small.copyWith(fontSize: compact ? 11 : 14)),
                if (!compact && booking.address != null) ...[
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(booking.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small.copyWith(color: AppColors.dark, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
