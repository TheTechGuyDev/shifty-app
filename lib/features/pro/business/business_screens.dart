import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/pro_models.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/service_icons.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../booking/booking_widgets.dart';
import '../../chat/chat_screen.dart';
import '../../profile/account_screens.dart';
import '../../profile/support_screens.dart';
import '../money/money_screens.dart';
import '../onboarding/pro_onboarding.dart';
import '../pro_router.dart';
import '../pro_widgets.dart';

String profileLink(String? slug) => '${AppConfig.webUrl}?pro=${slug ?? ''}';

/// Profile tab for professionals.
class ProProfileTab extends StatefulWidget {
  const ProProfileTab({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<ProProfileTab> createState() => _ProProfileTabState();
}

class _ProProfileTabState extends State<ProProfileTab> {
  ProProfile? _p;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProService.me();
    final u = await DataService.profile();
    if (mounted) setState(() {
      _p = p;
      _user = u;
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(appRoute(page));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    final name = p.businessName ?? (_user?['full_name'] as String?) ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 140),
      children: [
        Center(child: PersonAvatar(name: name, url: _user?['avatar_url'] as String?, size: 86)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(name, textAlign: TextAlign.center, style: AppTextStyles.navTitle)),
            if (p.level >= 2) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: AppColors.blue, size: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          p.ratingCount == 0 ? 'New professional' : '★ ${p.rating.toStringAsFixed(1)} (${p.ratingCount} reviews) · ${p.jobsDone} jobs',
          textAlign: TextAlign.center,
          style: AppTextStyles.small.copyWith(color: AppColors.primary, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => _open(PublicProfileScreen(proId: p.userId)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text('View public profile', style: AppTextStyles.small.copyWith(color: AppColors.dark)),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => _open(EditProfileScreen(profile: _user!)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text('Edit photo', style: AppTextStyles.small.copyWith(color: AppColors.dark)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _section('BUSINESS'),
        MenuTile(icon: Icons.badge_rounded, title: 'Business details', subtitle: 'Name, bio and experience', onTap: () => _open(const BusinessDetailsScreen(editing: true))),
        MenuTile(icon: Icons.design_services_rounded, title: 'Services & prices', subtitle: 'What you offer and how you charge', onTap: () => _open(const ChooseServicesScreen(editing: true))),
        MenuTile(icon: Icons.map_rounded, title: 'Service area', subtitle: '${p.radiusKm} km from ${p.baseAddress ?? 'your base'}', onTap: () => _open(const ServiceAreaScreen(editing: true))),
        MenuTile(icon: Icons.schedule_rounded, title: 'Working hours', onTap: () => _open(const WorkingHoursScreen(editing: true))),
        MenuTile(icon: Icons.photo_library_rounded, title: 'Portfolio', subtitle: 'Photos of your past work', onTap: () => _open(const PortfolioScreen())),
        if (p.accountType == 'company') MenuTile(icon: Icons.groups_rounded, title: 'Team members', onTap: () => _open(const TeamScreen())),
        const SizedBox(height: 10),
        _section('REPUTATION'),
        MenuTile(icon: Icons.star_rounded, title: 'Reviews', subtitle: 'Read and reply to customers', onTap: () => _open(const ReviewsScreen())),
        MenuTile(icon: Icons.people_alt_rounded, title: 'My customers', onTap: () => _open(const CustomersScreen())),
        MenuTile(icon: Icons.insights_rounded, title: 'Insights', subtitle: 'Acceptance rate, repeat customers', onTap: () => _open(const InsightsScreen())),
        MenuTile(icon: Icons.share_rounded, title: 'Share my profile', onTap: () => _open(const ShareProfileScreen())),
        const SizedBox(height: 10),
        _section('VERIFICATION'),
        MenuTile(
          icon: Icons.verified_user_rounded,
          title: 'Identity',
          subtitle: p.level >= 2 ? 'Verified' : 'Upload a valid ID',
          onTap: () => _open(const IdentityScreen(editing: true)),
        ),
        MenuTile(icon: Icons.workspace_premium_rounded, title: 'Certificates & licences', onTap: () => _open(const QualificationsScreen(editing: true))),
        MenuTile(icon: Icons.account_balance_rounded, title: 'Payout account', subtitle: p.bankName ?? 'Not added', onTap: () => _open(const PayoutAccountScreen())),
        const SizedBox(height: 10),
        _section('MORE'),
        MenuTile(icon: Icons.chat_bubble_rounded, title: 'Messages', onTap: () => _open(const ConversationsScreen(asPro: true))),
        MenuTile(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'Notifications and account', onTap: () => _open(const ProSettingsScreen())),
        MenuTile(icon: Icons.phone_in_talk_rounded, title: 'Contact support', onTap: () => _open(const ContactUsScreen())),
        MenuTile(icon: Icons.help_outline_rounded, title: 'FAQ', onTap: () => _open(const FaqScreen())),
        MenuTile(icon: Icons.swap_horiz_rounded, title: 'Switch to customer mode', subtitle: 'Book services for yourself', color: AppColors.primary, onTap: () => switchMode(context, 'customer')),
        MenuTile(icon: Icons.logout_rounded, title: 'Logout', color: AppColors.failed, onTap: widget.onLogout, trailing: const SizedBox.shrink()),
      ],
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(t, style: AppTextStyles.smallBold.copyWith(color: const Color(0xFFFD8A4E), fontSize: 14, letterSpacing: 0.8)),
      );
}

/// What customers see. Also used by the pro to preview their profile.
class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, this.proId, this.slug});
  final String? proId;
  final String? slug;

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Professional',
      body: AsyncView<(Map<String, dynamic>?, List<Map<String, dynamic>>, List<PortfolioItem>, List<ProReview>)>(
        future: (() async {
          final p = await ProService.publicProfile(userId: proId, slug: proId == null ? slug : null);
          if (p == null) return (null, <Map<String, dynamic>>[], <PortfolioItem>[], <ProReview>[]);
          final id = p['user_id'] as String;
          return (p, await ProService.publicServices(id), await ProService.portfolio(id), await ProService.reviews(id));
        })(),
        builder: (context, data) {
          final (p, services, portfolio, reviews) = data;
          if (p == null) return const EmptyState(icon: Icons.person_off_rounded, title: 'Profile not available', message: 'This professional is not visible yet.');
          final name = (p['business_name'] as String?) ?? (p['full_name'] as String?) ?? 'Professional';
          final rating = (p['rating'] as num?)?.toDouble() ?? 0;
          final count = (p['rating_count'] as int?) ?? 0;
          final level = (p['verification_level'] as int?) ?? 1;
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
            children: [
              Row(
                children: [
                  PersonAvatar(name: name, url: p['avatar_url'] as String?, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(child: Text(name, style: AppTextStyles.navTitle.copyWith(fontSize: 20))),
                          if (level >= 2) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: AppColors.blue, size: 18)),
                        ]),
                        const SizedBox(height: 4),
                        Text(count == 0 ? 'New on ${AppConfig.appName}' : '★ ${rating.toStringAsFixed(1)} · $count reviews',
                            style: AppTextStyles.small.copyWith(color: AppColors.primary)),
                        if (p['base_address'] != null)
                          Text(p['base_address'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _pill('${p['jobs_done'] ?? 0}', 'Jobs done')),
                  const SizedBox(width: 10),
                  Expanded(child: _pill('${p['years_experience'] ?? 0} yrs', 'Experience')),
                  const SizedBox(width: 10),
                  Expanded(child: _pill(level >= 3 ? 'Pro' : (level >= 2 ? 'ID ✓' : 'Basic'), 'Verification')),
                ],
              ),
              if ((p['bio'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                const ProSectionTitle('About'),
                Text(p['bio'] as String, style: AppTextStyles.paragraph.copyWith(fontSize: 14)),
              ],
              const SizedBox(height: 20),
              const ProSectionTitle('Services'),
              if (services.isEmpty) Text('No services listed.', style: AppTextStyles.small),
              for (final s in services)
                Builder(builder: (context) {
                  final cat = (s['service_categories'] as Map?)?.cast<String, dynamic>() ?? {};
                  final o = OfferedService.fromMap(s);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(iconFor((cat['icon'] as String?) ?? 'build'), color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Text((cat['name'] as String?) ?? 'Service', style: AppTextStyles.bodyMedium.copyWith(fontSize: 14))),
                        Text(o.priceLabel, style: AppTextStyles.smallBold.copyWith(color: AppColors.dark)),
                      ],
                    ),
                  );
                }),
              if (portfolio.isNotEmpty) ...[
                const SizedBox(height: 16),
                const ProSectionTitle('Portfolio'),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final i in portfolio)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(appRoute(MediaViewerScreen(url: i.url, video: false, caption: i.caption))),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
                            child: Image.network(i.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.field)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ProSectionTitle('Reviews ($count)'),
              if (reviews.isEmpty) Text('No reviews yet.', style: AppTextStyles.small),
              for (final r in reviews.take(10)) ReviewTile(review: r),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String v, String l) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(v, style: AppTextStyles.headline6.copyWith(fontSize: 15)),
            Text(l, style: AppTextStyles.small.copyWith(fontSize: 11)),
          ],
        ),
      );
}

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.onReply});
  final ProReview review;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++) Icon(Icons.star_rounded, size: 18, color: i < r.rating ? AppColors.yellow : AppColors.border),
              const Spacer(),
              Text(shortDate(r.createdAt), style: AppTextStyles.small.copyWith(fontSize: 12)),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.comment!, style: AppTextStyles.paragraph.copyWith(fontSize: 14, color: AppColors.dark)),
          ],
          if (r.reply != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(12)),
              child: Text('Reply: ${r.reply}', style: AppTextStyles.small.copyWith(color: AppColors.dark, fontSize: 13)),
            ),
          ] else if (onReply != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onReply, child: Text('Reply', style: AppTextStyles.smallBold.copyWith(color: AppColors.primary))),
            ),
        ],
      ),
    );
  }
}

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late Future<List<ProReview>> _f = ProService.reviews();
  int _filter = 0;

  Future<void> _reply(ProReview r) async {
    final c = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reply publicly', style: AppTextStyles.navTitle),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              maxLines: 4,
              maxLength: 400,
              decoration: InputDecoration(
                hintText: 'Thank the customer or respond to their feedback',
                filled: true,
                fillColor: AppColors.field,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            PrimaryButton(label: 'Post reply', onPressed: () => Navigator.pop(context, c.text.trim())),
          ],
        ),
      ),
    );
    if (text == null || text.length < 2) return;
    try {
      await ProService.reply(r.id, text);
      setState(() => _f = ProService.reviews());
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Reviews',
      body: AsyncView<List<ProReview>>(
        future: _f,
        builder: (context, all) {
          if (all.isEmpty) {
            return const EmptyState(icon: Icons.star_outline_rounded, title: 'No reviews yet', message: 'Customers can rate you after a job is completed.');
          }
          final avg = all.map((r) => r.rating).reduce((a, b) => a + b) / all.length;
          final list = _filter == 0 ? all : all.where((r) => r.rating == 6 - _filter).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
            children: [
              Row(
                children: [
                  Text(avg.toStringAsFixed(1), style: AppTextStyles.headline1.copyWith(fontSize: 48)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        for (var s = 5; s >= 1; s--)
                          Row(
                            children: [
                              Text('$s', style: AppTextStyles.small.copyWith(fontSize: 12)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: all.where((r) => r.rating == s).length / all.length,
                                    minHeight: 6,
                                    backgroundColor: AppColors.field,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < 6; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(i == 0 ? 'All' : '${6 - i} ★'),
                          selected: _filter == i,
                          selectedColor: const Color(0xFFFFE6D6),
                          side: BorderSide(color: _filter == i ? AppColors.primary : AppColors.border),
                          onSelected: (_) => setState(() => _filter = i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final r in list) ReviewTile(review: r, onReply: () => _reply(r)),
            ],
          );
        },
      ),
    );
  }
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'My Customers',
      body: AsyncView<List<Map<String, dynamic>>>(
        future: ProService.customers(),
        builder: (context, list) => list.isEmpty
            ? const EmptyState(icon: Icons.people_outline_rounded, title: 'No customers yet', message: 'People you work for appear here.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
                children: [
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          PersonAvatar(name: (c['name'] as String?) ?? 'Customer', url: c['avatar'] as String?),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((c['name'] as String?) ?? 'Customer', style: AppTextStyles.headline6.copyWith(fontSize: 14)),
                                Text(
                                  '${c['jobs']} job${c['jobs'] == 1 ? '' : 's'}${c['last_job'] != null ? ' · last ${shortDate(DateTime.parse(c['last_job'] as String).toLocal())}' : ''}',
                                  style: AppTextStyles.small.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(money(c['spent'] as num?), style: AppTextStyles.smallBold.copyWith(color: AppColors.dark)),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Insights',
      body: AsyncView<(Map<String, dynamic>, ProProfile?)>(
        future: (() async => (await ProService.stats(), await ProService.me()))(),
        builder: (context, data) {
          final (s, p) = data;
          final total = (s['offers_total'] as num?) ?? 0;
          final accepted = (s['offers_accepted'] as num?) ?? 0;
          final rate = total == 0 ? 0 : (accepted * 100 / total).round();
          final customers = (s['customers'] as num?) ?? 0;
          final repeat = (s['repeat_customers'] as num?) ?? 0;
          final daily = ((s['daily'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
          final tips = <String>[
            if ((p?.level ?? 1) < 2) 'Verify your ID. Verified pros are shown first to customers.',
            if (rate < 50 && total > 3) 'You win $rate% of requests. Replying quickly with a clear quote helps.',
            if ((p?.ratingCount ?? 0) < 3) 'Ask happy customers to leave a review after each job.',
            'Add photos of finished work to your portfolio.',
            if (!(p?.online ?? false)) 'Stay online during your working hours to get more requests.',
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  StatTile(label: 'Requests won', value: '$rate%', icon: Icons.emoji_events_rounded),
                  StatTile(label: 'Requests received', value: '$total', icon: Icons.inbox_rounded, color: AppColors.blue),
                  StatTile(label: 'Customers', value: '$customers', icon: Icons.people_rounded, color: AppColors.success),
                  StatTile(label: 'Repeat customers', value: '$repeat', icon: Icons.repeat_rounded, color: AppColors.yellow),
                ],
              ),
              const SizedBox(height: 22),
              const ProSectionTitle('Earnings, last 7 days'),
              EarningsChart(daily: daily),
              const SizedBox(height: 22),
              const ProSectionTitle('Tips to get more jobs'),
              for (final t in tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppColors.yellow, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t, style: AppTextStyles.paragraph.copyWith(fontSize: 14))),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<List<PortfolioItem>> _f = ProService.portfolio();
  bool _busy = false;

  Future<void> _add() async {
    final f = await pickPhoto(context);
    if (f == null || !mounted) return;
    final caption = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add a caption', style: AppTextStyles.navTitle),
        content: TextField(controller: caption, decoration: const InputDecoration(hintText: 'e.g. Kitchen rewiring, Lekki')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Upload', style: AppTextStyles.smallBold.copyWith(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ProService.addPortfolio(f.$1, f.$2, caption.text.trim().isEmpty ? null : caption.text.trim());
      setState(() => _f = ProService.portfolio());
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Portfolio',
      bottom: PrimaryButton(label: 'Add photo', loading: _busy, onPressed: _add),
      body: AsyncView<List<PortfolioItem>>(
        future: _f,
        builder: (context, list) => list.isEmpty
            ? const EmptyState(icon: Icons.photo_library_outlined, title: 'Show off your work', message: 'Customers trust pros with photos of real jobs. Add your best ones.')
            : GridView.count(
                padding: const EdgeInsets.all(22),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final i in list)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(appRoute(MediaViewerScreen(url: i.url, video: false, caption: i.caption))),
                      onLongPress: () async {
                        if (await confirmDialog(context, 'Delete photo?', 'It will be removed from your profile.', yes: 'Delete', color: AppColors.failed)) {
                          await ProService.deletePortfolio(i.id);
                          setState(() => _f = ProService.portfolio());
                        }
                      },
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(i.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.field)),
                            if (i.caption != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.black45,
                                  child: Text(i.caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<List<TeamMember>> _f = ProService.team();

  Future<void> _add() async {
    final name = TextEditingController();
    final role = TextEditingController();
    final phone = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add team member', style: AppTextStyles.navTitle),
            const SizedBox(height: 18),
            AppTextField(label: 'Full name', controller: name),
            const SizedBox(height: 16),
            AppTextField(label: 'Role (e.g. Cleaner, Driver)', controller: role),
            const SizedBox(height: 16),
            AppTextField(label: 'Phone (private)', controller: phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Add', onPressed: () => Navigator.pop(context, name.text.trim().length >= 2)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ProService.addTeamMember(name.text.trim(), phone.text.trim().isEmpty ? null : phone.text.trim(), role.text.trim().isEmpty ? null : role.text.trim());
      setState(() => _f = ProService.team());
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Team',
      bottom: PrimaryButton(label: 'Add team member', onPressed: _add),
      body: AsyncView<List<TeamMember>>(
        future: _f,
        builder: (context, list) => list.isEmpty
            ? const EmptyState(icon: Icons.groups_rounded, title: 'No team members', message: 'Add the people who work with you so you can plan bigger jobs.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
                children: [
                  for (final m in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PersonAvatar(name: m.name),
                      title: Text(m.name, style: AppTextStyles.headline6.copyWith(fontSize: 14)),
                      subtitle: Text([m.role, m.phone].whereType<String>().join(' · '), style: AppTextStyles.small.copyWith(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.failed),
                        onPressed: () async {
                          await ProService.removeTeamMember(m.id);
                          setState(() => _f = ProService.team());
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class ShareProfileScreen extends StatelessWidget {
  const ShareProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Share Profile',
      body: AsyncView<ProProfile?>(
        future: ProService.me(),
        builder: (context, p) {
          final link = profileLink(p?.slug);
          return ListView(
            padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(color: const Color(0xFFFFF1EA), borderRadius: BorderRadius.circular(40)),
                  child: const Icon(Icons.campaign_rounded, size: 60, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 22),
              Text('Get booked directly', textAlign: TextAlign.center, style: AppTextStyles.headline1.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text('Share your profile on WhatsApp, Instagram or your business card. Customers can see your reviews and book you.',
                  textAlign: TextAlign.center, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(child: Text(link, style: AppTextStyles.small.copyWith(color: AppColors.dark))),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        showAppSnack(context, 'Link copied');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Share link',
                onPressed: () => Share.share('Book me on ${AppConfig.appName}: ${p?.businessName ?? ''}\n$link'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProSettingsScreen extends StatefulWidget {
  const ProSettingsScreen({super.key});

  @override
  State<ProSettingsScreen> createState() => _ProSettingsScreenState();
}

class _ProSettingsScreenState extends State<ProSettingsScreen> {
  ProProfile? _p;
  bool _jobs = true;
  bool _msgs = true;

  @override
  void initState() {
    super.initState();
    ProService.me().then((p) {
      if (p == null || !mounted) return;
      setState(() {
        _p = p;
        _jobs = p.notifyJobs;
        _msgs = p.notifyMessages;
      });
    });
  }

  Future<void> _set(String key, bool v) async {
    setState(() => key == 'notify_jobs' ? _jobs = v : _msgs = v);
    try {
      await ProService.update({key: v});
    } catch (_) {
      if (mounted) showAppSnack(context, 'Could not save setting', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget sw(String t, String s, bool v, ValueChanged<bool> on) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)),
                    Text(s, style: AppTextStyles.small.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Switch(value: v, activeTrackColor: AppColors.primary, activeColor: Colors.white, onChanged: on),
            ],
          ),
        );
    return ServiceChrome(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
        children: [
          const ProSectionTitle('Notifications'),
          sw('New job requests', 'Get alerted when a customer near you needs your service', _jobs, (v) => _set('notify_jobs', v)),
          sw('Messages', 'Get alerted when a customer messages you', _msgs, (v) => _set('notify_messages', v)),
          const SizedBox(height: 16),
          const ProSectionTitle('Account'),
          MenuTile(icon: Icons.lock_rounded, title: 'Change password', onTap: () => Navigator.of(context).push(appRoute(const ChangePasswordScreen()))),
          MenuTile(
            icon: Icons.business_center_rounded,
            title: 'Account type',
            subtitle: _p?.accountType == 'company' ? 'Company' : 'Individual',
            onTap: () async {
              final next = _p?.accountType == 'company' ? 'individual' : 'company';
              if (await confirmDialog(context, 'Switch account type?', 'Change to ${next == 'company' ? 'Company' : 'Individual'}?', yes: 'Switch')) {
                await ProService.update({'account_type': next});
                final p = await ProService.me();
                if (mounted) setState(() => _p = p);
              }
            },
          ),
          MenuTile(icon: Icons.swap_horiz_rounded, title: 'Switch to customer mode', onTap: () => switchMode(context, 'customer')),
          MenuTile(
            icon: Icons.pause_circle_outline_rounded,
            title: 'Go offline',
            subtitle: 'Stop receiving new requests',
            onTap: () async {
              await ProService.update({'is_online': false});
              if (context.mounted) showAppSnack(context, 'You’re offline');
            },
          ),
        ],
      ),
    );
  }
}
