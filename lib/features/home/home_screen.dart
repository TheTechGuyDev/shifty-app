import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/data_service.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_tab.dart';
import '../history/history_tab.dart';
import '../notifications/notifications_screen.dart';
import '../offers/offers_tab.dart';
import '../profile/profile_tab.dart';
import '../services/service_screens.dart';
import '../shell/app_chrome.dart';
import '../shell/bottom_nav.dart';

/// Main app shell: dark header, four tabs, raised bottom nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Map<String, dynamic>? _profile;
  bool _unread = false;

  static const _items = [
    NavItem(Icons.home_rounded, 'Home'),
    NavItem(Icons.sticky_note_2_rounded, 'History'),
    NavItem(Icons.local_activity_rounded, 'Offers'),
    NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    AuthService.myProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    }).catchError((_) {});
    _checkUnread();
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

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(appRoute(const NotificationsScreen()));
    _checkUnread();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = ((_profile?['full_name'] as String?) ?? '').trim().split(' ').first;
    final tabs = [
      DashboardTab(firstName: firstName),
      HistoryTab(onBookNow: () => setState(() => _tab = 0)),
      const OffersTab(),
      ProfileTab(profile: _profile, onLogout: _logout),
    ];

    return Scaffold(
      extendBody: true,
      body: AppChrome(
        title: _tab == 0 ? null : _items[_tab].label,
        onMenu: () => Navigator.of(context).push(appRoute(const AllServicesScreen())),
        onBell: _openNotifications,
        hasUnread: _unread,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_tab), child: tabs[_tab]),
        ),
      ),
      bottomNavigationBar: BottomNav(items: _items, index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}
