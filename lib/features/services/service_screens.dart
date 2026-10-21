import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/service_icons.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../shell/app_chrome.dart';

/// Opens the right flow for a service. Booking flows are wired in the next build.
void openService(BuildContext context, ServiceCategory s) {
  Navigator.of(context).push(appRoute(ServiceIntroScreen(service: s)));
}

/// Lists every group and its services (opened from the menu icon).
class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  late Future<List<ServiceCategory>> _future = DataService.categories();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppChrome(
        title: 'All Services',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
        ),
        body: AsyncView<List<ServiceCategory>>(
          future: _future,
          onRetry: () => setState(() => _future = DataService.categories(refresh: true)),
          builder: (context, all) {
            final groups = all.where((c) => c.isGroup).toList();
            final q = _query.toLowerCase();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  cursorColor: AppColors.primary,
                  style: AppTextStyles.input.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search plumber, tutor, DJ…',
                    hintStyle: AppTextStyles.input.copyWith(fontSize: 15, color: AppColors.label),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.label),
                    filled: true,
                    fillColor: AppColors.field,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                for (final g in groups)
                  Builder(builder: (context) {
                    final kids = all
                        .where((c) => c.parentId == g.id && (q.isEmpty || c.name.toLowerCase().contains(q)))
                        .toList();
                    if (kids.isEmpty) return const SizedBox.shrink();
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: q.isNotEmpty,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: _IconBubble(icon: iconFor(g.icon), color: g.color),
                        title: Text(g.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: Text('${kids.length} services', style: AppTextStyles.small.copyWith(fontSize: 12)),
                        children: [
                          for (final s in kids)
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 60, right: 8),
                              leading: Icon(iconFor(s.icon), color: s.color, size: 22),
                              title: Text(s.name, style: AppTextStyles.small.copyWith(color: AppColors.dark, fontSize: 15)),
                              trailing: s.requiresVerification
                                  ? const Tooltip(
                                      message: 'Only verified, qualified professionals',
                                      child: Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                                    )
                                  : const Icon(Icons.chevron_right_rounded, color: AppColors.label),
                              onTap: () => openService(context, s),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: Color.lerp(Colors.white, color, 0.14), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

/// Temporary landing for a service until its booking flow is built.
class ServiceIntroScreen extends StatelessWidget {
  const ServiceIntroScreen({super.key, required this.service});
  final ServiceCategory service;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      navTitle: service.name,
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(color: Color.lerp(Colors.white, service.color, 0.15), shape: BoxShape.circle),
            child: Icon(iconFor(service.icon), color: service.color, size: 50),
          ),
        ),
        const SizedBox(height: 28),
        Text(service.name, style: AppTextStyles.headline1.copyWith(fontSize: 30), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Booking for this service opens in the next build. You will pick a date, location and get matched with a verified professional.',
          style: AppTextStyles.paragraph,
          textAlign: TextAlign.center,
        ),
        if (service.requiresVerification) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Text('Qualified professionals only', style: AppTextStyles.smallBold.copyWith(color: AppColors.success)),
            ],
          ),
        ],
        const SizedBox(height: 36),
        PrimaryButton(label: 'Back to Home', onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
