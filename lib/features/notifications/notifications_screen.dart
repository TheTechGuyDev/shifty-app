import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/async_view.dart';
import '../shell/app_chrome.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future = DataService.myNotifications();

  @override
  void initState() {
    super.initState();
    _future.then((_) => DataService.markAllRead()).catchError((_) {});
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}min';
    if (d.inHours < 24) return '${d.inHours} hr';
    return '${d.inDays}d';
  }

  (IconData, Color, Color) _style(String type) => switch (type) {
        'message' => (Icons.chat_bubble_rounded, const Color(0xFF3F8CFF), const Color(0xFFEEEEF7)),
        'order' => (Icons.verified_rounded, AppColors.success, const Color(0xFFE1F4E5)),
        'offer' => (Icons.celebration_rounded, AppColors.warning, const Color(0xFFF4E1E1)),
        _ => (Icons.notifications_rounded, const Color(0xFF3F8CFF), const Color(0xFFEEEEF7)),
      };

  String _group(DateTime t) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
    if (d == 0) return 'Today';
    if (d == 1) return 'Yesterday';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppChrome(
        title: 'Notification',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
        ),
        bodyColor: const Color(0xFFF9F9F9),
        body: AsyncView<List<AppNotification>>(
          future: _future,
          onRetry: () => setState(() => _future = DataService.myNotifications()),
          builder: (context, list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'All caught up',
                message: 'Booking updates, messages and offers will appear here.',
              );
            }
            final children = <Widget>[];
            String? current;
            for (final n in list) {
              final g = _group(n.createdAt);
              if (g != current) {
                current = g;
                children.add(Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 22),
                  child: Text(g, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                ));
                children.add(const Divider(height: 1, color: AppColors.border));
              }
              final (icon, fg, bg) = _style(n.type);
              children.add(Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                        child: Icon(icon, color: fg, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: AppTextStyles.headline6.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                                Text(_ago(n.createdAt), style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.label)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.body, style: AppTextStyles.small.copyWith(color: const Color(0xFF8A8A8A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            }
            return ListView(padding: const EdgeInsets.only(bottom: 40), children: children);
          },
        ),
      ),
    );
  }
}
