import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/service_icons.dart';
import '../../core/widgets/async_view.dart';
import '../offers/offer_widgets.dart';
import '../services/service_screens.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.firstName});
  final String firstName;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late Future<List<ServiceCategory>> _hero = DataService.homeSection('hero');
  late Future<List<ServiceCategory>> _other = DataService.homeSection('other');
  late Future<List<Offer>> _offers = DataService.offers(section: 'latest');
  String _chip = 'Trending';

  static const _chips = ['Trending', 'Promotion', 'Summer Offer', 'New', 'Popular'];

  Future<void> _refresh() async {
    await DataService.categories(refresh: true);
    setState(() {
      _hero = DataService.homeSection('hero');
      _other = DataService.homeSection('other');
      _offers = DataService.offers(section: 'latest');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(top: 34, bottom: 150),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.firstName.isEmpty ? 'Welcome 👋' : 'Hi ${widget.firstName} 👋', style: AppTextStyles.headline1),
                const SizedBox(height: 4),
                Text('Need a helping hand today?', style: AppTextStyles.subtitle.copyWith(fontSize: 22, color: const Color(0xFF8E8E8E))),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Hero service cards.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AsyncView<List<ServiceCategory>>(
              future: _hero,
              loadingHeight: 125,
              onRetry: _refresh,
              builder: (context, list) => Row(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _HeroCard(service: list[i])),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 34),
          _SectionTitle('Offers & News'),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _Chip(
                label: _chips[i],
                selected: _chips[i] == _chip,
                onTap: () => setState(() => _chip = _chips[i]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 137,
            child: AsyncView<List<Offer>>(
              future: _offers,
              loadingHeight: 137,
              onRetry: _refresh,
              builder: (context, all) {
                var list = all.where((o) => o.chip == _chip).toList();
                if (list.isEmpty) list = all;
                return ListView.separated(
                  key: ValueKey(_chip),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, i) => OfferBanner(offer: list[i]),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          _SectionTitle('Other Services'),
          const SizedBox(height: 14),
          SizedBox(
            height: 124,
            child: AsyncView<List<ServiceCategory>>(
              future: _other,
              loadingHeight: 110,
              onRetry: _refresh,
              builder: (context, list) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 18),
                itemBuilder: (context, i) => _OtherService(service: list[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Text(text, style: AppTextStyles.navTitle.copyWith(fontSize: 17)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.service});
  final ServiceCategory service;

  @override
  Widget build(BuildContext context) {
    final c = service.color;
    return Material(
      color: Color.lerp(Colors.white, c, 0.13),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openService(context, service),
        child: SizedBox(
          height: 125,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(color: Color.lerp(Colors.white, c, 0.35), shape: BoxShape.circle),
                child: Icon(iconFor(service.icon), color: c, size: 22),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  service.name.replaceFirst(' ', '\n'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.headline6.copyWith(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFF9B9C9E)),
        ),
        child: Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontSize: 13,
            color: selected ? AppColors.white : const Color(0xFF9B9C9E),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _OtherService extends StatelessWidget {
  const _OtherService({required this.service});
  final ServiceCategory service;

  @override
  Widget build(BuildContext context) {
    final c = service.color;
    return GestureDetector(
      onTap: () => openService(context, service),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white, Color.lerp(Colors.white, c, 0.12)!],
                      center: const Alignment(-0.3, -0.4),
                    ),
                    boxShadow: [BoxShadow(color: c.withAlpha(40), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Icon(iconFor(service.icon), color: c, size: 30),
                ),
                if (service.badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(10)),
                      child: Text(service.badge!, style: AppTextStyles.smallBold.copyWith(fontSize: 11, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.dark, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
