import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/async_view.dart';
import '../services/service_screens.dart';
import 'offer_widgets.dart';

class OffersTab extends StatefulWidget {
  const OffersTab({super.key});

  @override
  State<OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends State<OffersTab> {
  late Future<(List<Offer>, List<ServiceCategory>)> _future = _load();

  Future<(List<Offer>, List<ServiceCategory>)> _load() async =>
      (await DataService.offers(), await DataService.categories());

  Future<void> _refresh() async => setState(() => _future = _load());

  /// Matches a "Just for you" offer to a service by its subtitle (e.g. "Painting Service").
  ServiceCategory? _serviceFor(Offer o, List<ServiceCategory> cats) {
    final word = (o.subtitle ?? '').split(' ').first.toLowerCase();
    for (final c in cats) {
      if (!c.isGroup && c.name.toLowerCase().contains(word)) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: AsyncView<(List<Offer>, List<ServiceCategory>)>(
        future: _future,
        onRetry: _refresh,
        builder: (context, data) {
          final (offers, cats) = data;
          final latest = offers.where((o) => o.section == 'latest').toList();
          final limited = offers.where((o) => o.section == 'limited').toList();
          final forYou = offers.where((o) => o.section == 'just_for_you').toList();

          return ListView(
            padding: const EdgeInsets.only(top: 26, bottom: 150),
            children: [
              _title('Latest Offers'),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  itemCount: latest.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => OfferCodeCard(offer: latest[i]),
                ),
              ),
              if (limited.isNotEmpty) ...[
                const SizedBox(height: 26),
                _title('Limited Offer'),
                const SizedBox(height: 12),
                for (final o in limited)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 0, 26, 12),
                    child: LimitedOfferCard(offer: o),
                  ),
              ],
              if (forYou.isNotEmpty) ...[
                const SizedBox(height: 14),
                _title('Just for you'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    itemCount: forYou.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final s = _serviceFor(forYou[i], cats);
                      return JustForYouCard(
                        offer: forYou[i],
                        icon: s == null ? Icons.local_offer_rounded : _iconFor(s),
                        onOrder: () {
                          if (s != null) openService(context, s);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  IconData _iconFor(ServiceCategory s) => switch (s.slug) {
        'painting' => Icons.format_paint_rounded,
        'vehicle' => Icons.local_shipping_rounded,
        _ => Icons.home_work_rounded,
      };

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Text(t, style: AppTextStyles.navTitle.copyWith(fontSize: 17)),
      );
}
