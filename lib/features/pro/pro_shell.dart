import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/models/pro_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/data_service.dart';
import '../../core/services/pro_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shell/app_chrome.dart';
import '../shell/bottom_nav.dart';
import 'business/business_screens.dart';
import 'calendar/calendar_screens.dart';
import 'jobs/jobs_screens.dart';
import 'money/money_screens.dart';
import 'pro_widgets.dart';

/// Professional app shell: Home, Jobs, Calendar, Earnings, Profile.
class ProHomeScreen extends StatefulWidget {
  const ProHomeScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<ProHomeScreen> createState() => _ProHomeScreenState();
}

class _ProHomeScreenState extends State<ProHomeScreen> {
  late int _tab = widget.initialTab;
  bool _unread = false;
  int _reload = 0;
  StreamSubscription? _sub;

  static const _items = [
    NavItem(Icons.space_dashboard_rounded, 'Home'),
    NavItem(Icons.work_rounded, 'Jobs'),
    NavItem(Icons.calendar_month_rounded, 'Calendar'),
    NavItem(Icons.account_balance_wallet_rounded, 'Earnings'),
    NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _checkUnread();
    // New job requests arrive in real time.
    var first = true;
    _sub = ProService.offersStream().listen((_) {
      if (first) {
        first = false;
        return;
      }
      if (mounted) setState(() => _reload++);
      _checkUnread();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _checkUnread() {
    DataService.hasUnread().then((v) {
      if (mounted) setState(() => _unread = v);
    }).catchError((_) {});
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(appRoute(const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ProDashboardTab(key: ValueKey('d$_reload'), onTab: (i) => setState(() => _tab = i)),
      ProJobsTab(key: ValueKey('j$_reload')),
      const ProCalendarTab(),
      const ProEarningsTab(),
      ProProfileTab(onLogout: _logout),
    ];
    return Scaffold(
      extendBody: true,
      body: AppChrome(
        title: _tab == 0 ? null : _items[_tab].label,
        leading: _ChromeIcon(icon: Icons.chat_bubble_rounded, onTap: () => Navigator.of(context).push(appRoute(const ConversationsScreen(asPro: true)))),
        onBell: () async {
          await Navigator.of(context).push(appRoute(const NotificationsScreen()));
          _checkUnread();
        },
        hasUnread: _unread,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim), child: child),
          ),
          child: KeyedSubtree(key: ValueKey(_tab), child: tabs[_tab]),
        ),
      ),
      bottomNavigationBar: BottomNav(items: _items, index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

class _ChromeIcon extends StatelessWidget {
  const _ChromeIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.white10, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      );
}

class ProDashboardTab extends StatefulWidget {
  const ProDashboardTab({super.key, required this.onTab});
  final ValueChanged<int> onTab;

  @override
  State<ProDashboardTab> createState() => _ProDashboardTabState();
}

class _ProDashboardTabState extends State<ProDashboardTab> {
  ProProfile? _p;
  Map<String, dynamic>? _stats;
  List<(JobOffer, Booking)> _requests = [];
  List<Booking> _upcoming = [];
  String _name = '';
  bool _error = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ProService.me(),
        ProService.stats(),
        ProService.requests(),
        ProService.myJobs(),
        DataService.profile(),
      ]);
      if (!mounted) return;
      setState(() {
        _error = false;
        _p = results[0] as ProProfile?;
        _stats = results[1] as Map<String, dynamic>;
        _requests = results[2] as List<(JobOffer, Booking)>;
        _upcoming = (results[3] as List<Booking>).where((b) => b.status == BookingStatus.active).toList();
        _name = (((results[4] as Map<String, dynamic>?)?['full_name'] as String?) ?? '').split(' ').first;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _toggleOnline(bool v) async {
    setState(() => _toggling = true);
    try {
      await ProService.update({'is_online': v});
      await _load();
      if (mounted) showAppSnack(context, v ? 'You’re online. New requests will come in.' : 'You’re offline. No new requests.');
    } catch (_) {
      if (mounted) showAppSnack(context, 'Could not update. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Center(child: TextButton(onPressed: _load, child: Text('Could not load. Tap to retry.', style: AppTextStyles.smallBold.copyWith(color: AppColors.primary))));
    }
    final p = _p;
    final s = _stats;
    if (p == null || s == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 130),
        children: [
          Text('Hello${_name.isEmpty ? '' : ', $_name'} 👋', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(p.businessName ?? 'Your business', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 20),
          // Online card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.online ? AppColors.success : AppColors.dark,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: p.online ? Colors.white : AppColors.label, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.online ? 'You’re online' : 'You’re offline',
                          style: AppTextStyles.navTitle.copyWith(color: Colors.white, fontSize: 18)),
                    ),
                    _toggling
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Switch(
                            value: p.online,
                            activeTrackColor: Colors.white,
                            activeColor: AppColors.success,
                            inactiveTrackColor: Colors.white24,
                            onChanged: p.approved ? _toggleOnline : null,
                          ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  !p.approved
                      ? 'Your account is waiting for approval.'
                      : p.online
                          ? 'Customers within ${p.radiusKm} km can send you requests.'
                          : 'Go online to start receiving job requests.',
                  style: AppTextStyles.small.copyWith(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _darkStat('Today', money(s['today'] as num?))),
                    Expanded(child: _darkStat('This week', money(s['week'] as num?))),
                    Expanded(child: _darkStat('Balance', money(s['balance'] as num?))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatTile(label: 'New requests', value: '${s['requests']}', icon: Icons.notifications_active_rounded, onTap: () => widget.onTab(1)),
              StatTile(label: 'Active jobs', value: '${s['active']}', icon: Icons.handyman_rounded, color: AppColors.blue, onTap: () => widget.onTab(1)),
              StatTile(
                label: 'Rating (${p.ratingCount})',
                value: p.ratingCount == 0 ? 'New' : p.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: AppColors.yellow,
                onTap: () => Navigator.of(context).push(appRoute(const ReviewsScreen())),
              ),
              StatTile(label: 'Jobs done', value: '${s['done']}', icon: Icons.task_alt_rounded, color: AppColors.success, onTap: () => widget.onTab(3)),
            ],
          ),
          const SizedBox(height: 26),
          ProSectionTitle('New requests', action: _requests.isEmpty ? null : 'See all', onAction: () => widget.onTab(1)),
          if (_requests.isEmpty)
            _emptyCard(Icons.inbox_rounded, p.online ? 'No requests right now. We’ll notify you when one comes in.' : 'Go online to receive requests.')
          else
            for (final r in _requests.take(3))
              JobCard(
                booking: r.$2,
                badge: r.$1.status == 'quoted' ? 'Quote sent' : 'New',
                badgeColor: r.$1.status == 'quoted' ? AppColors.blue : AppColors.primary,
                onTap: () async {
                  await Navigator.of(context).push(appRoute(JobRequestScreen(bookingId: r.$2.id)));
                  _load();
                },
              ),
          const SizedBox(height: 16),
          ProSectionTitle('Upcoming jobs', action: _upcoming.isEmpty ? null : 'Calendar', onAction: () => widget.onTab(2)),
          if (_upcoming.isEmpty)
            _emptyCard(Icons.event_available_rounded, 'No upcoming jobs yet.')
          else
            for (final b in _upcoming.take(3))
              JobCard(
                booking: b,
                badge: progressLabel(b.progress),
                badgeColor: AppColors.success,
                onTap: () async {
                  await Navigator.of(context).push(appRoute(JobWorkspaceScreen(bookingId: b.id)));
                  _load();
                },
              ),
          const SizedBox(height: 16),
          const ProSectionTitle('Quick actions'),
          Row(
            children: [
              _quick(Icons.event_busy_rounded, 'Block dates', () => Navigator.of(context).push(appRoute(const BlockDatesScreen()))),
              _quick(Icons.photo_library_rounded, 'Portfolio', () => Navigator.of(context).push(appRoute(const PortfolioScreen()))),
              _quick(Icons.insights_rounded, 'Insights', () => Navigator.of(context).push(appRoute(const InsightsScreen()))),
              _quick(Icons.share_rounded, 'Share', () => Navigator.of(context).push(appRoute(const ShareProfileScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _darkStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.small.copyWith(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTextStyles.navTitle.copyWith(color: Colors.white, fontSize: 17))),
        ],
      );

  Widget _emptyCard(IconData icon, String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.label),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: AppTextStyles.small.copyWith(fontSize: 13))),
          ],
        ),
      );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFFFF1EA), borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.dark)),
            ],
          ),
        ),
      );
}
