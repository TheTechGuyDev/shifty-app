import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart' show OutlineButtonX;
import '../booking/booking_widgets.dart';

void goHome(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);

/// Shared "page title + grey intro" block for profile sub-pages.
class PageIntro extends StatelessWidget {
  const PageIntro({super.key, required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headline1),
          const SizedBox(height: 8),
          Text(text, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget card(String title, String sub, IconData icon, Color fg, Color bg, VoidCallback onTap) => Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: Column(
                children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: fg, size: 32)),
                  const SizedBox(height: 18),
                  Text(title, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(sub, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
        );

    return ServiceChrome(
      title: 'Contact Us',
      bottom: OutlineButtonX(label: 'Go to Homepage', trailingArrow: true, onPressed: () => goHome(context)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const PageIntro(title: 'Contact Us', text: 'Please choose what types of support do you need and let us know.'),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 18,
              crossAxisSpacing: 12,
              childAspectRatio: 150 / 188,
              children: [
                card('Support Chat', '24x7 Online Support', Icons.chat_rounded, AppColors.success, const Color(0xFFE9F7EC),
                    () => Navigator.of(context).push(appRoute(const SupportChatScreen()))),
                card('Call Center', '24x7 Customer Service', Icons.phone_in_talk_rounded, AppColors.warning, const Color(0xFFFFEDE4),
                    () => launchUrl(Uri(scheme: 'tel', path: AppConfig.supportPhone.replaceAll(' ', '')))),
                card('Email', AppConfig.supportEmail, Icons.email_rounded, const Color(0xFF9B51E0), const Color(0xFFF1E8FB),
                    () => launchUrl(Uri(scheme: 'mailto', path: AppConfig.supportEmail, query: 'subject=${Uri.encodeComponent('${AppConfig.appName} support')}'))),
                card('FAQ', 'Quick answers', Icons.help_rounded, const Color(0xFFF2C94C), const Color(0xFFFFF8DD),
                    () => Navigator.of(context).push(appRoute(const FaqScreen()))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Stream<List<SupportMessage>>? _stream;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (DataService.signedIn) _stream = DataService.supportThread();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    setState(() => _sending = true);
    try {
      await DataService.sendSupport(t);
      _text.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Support Chat',
      body: Column(
        children: [
          const PageIntro(title: 'Support Chat', text: 'Please wait our support team will reply you as soon as possible.'),
          const SizedBox(height: 22),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 16, 30, 16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                      child: Text('ST', style: AppTextStyles.smallBold.copyWith(color: Colors.white)),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AppConfig.appName} Support', style: AppTextStyles.headline6),
                    Text('Usually replies within minutes', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.label)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _stream == null
                ? const EmptyState(icon: Icons.lock_outline_rounded, title: 'Log in to chat', message: 'Support chat is available once you are signed in.')
                : StreamBuilder<List<SupportMessage>>(
                    stream: _stream,
                    builder: (context, snap) {
                      final msgs = snap.data ?? [];
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      if (msgs.isEmpty) {
                        return const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'How can we help?', message: 'Send us a message and our team will reply here.');
                      }
                      _toBottom();
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                        itemCount: msgs.length,
                        itemBuilder: (context, i) => _Bubble(m: msgs[i]),
                      );
                    },
                  ),
          ),
          if (_stream != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: AppTextStyles.input.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Aa',
                          hintStyle: AppTextStyles.small.copyWith(color: AppColors.label),
                          filled: true,
                          fillColor: const Color(0xFFF1F1F1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _text.text = '${_text.text}🙂';
                              _text.selection = TextSelection.collapsed(offset: _text.text.length);
                            },
                            icon: const Icon(Icons.emoji_emotions_rounded, color: AppColors.dark),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: Icon(Icons.send_rounded, color: _sending ? AppColors.label : AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m});
  final SupportMessage m;

  @override
  Widget build(BuildContext context) {
    final me = m.fromUser;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width.clamp(0.0, 430.0) * 0.62),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: me ? AppColors.primary : const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(me ? 22 : 6),
                bottomRight: Radius.circular(me ? 6 : 22),
              ),
            ),
            child: Text(m.body, style: AppTextStyles.small.copyWith(color: me ? Colors.white : AppColors.dark, fontSize: 14, height: 1.6)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            child: Text(timeOf(m.createdAt), style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.label)),
          ),
        ],
      ),
    );
  }
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late Future<List<Faq>> _future = DataService.faqs();
  String? _open;

  static const _order = ['General', 'Contact', 'Payments'];

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'FAQs',
      bottom: OutlineButtonX(label: 'Go to Homepage', trailingArrow: true, onPressed: () => goHome(context)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const PageIntro(title: 'FAQ', text: 'Find important information and update about any recent changes and fees here.'),
          const SizedBox(height: 22),
          const Divider(height: 1, color: AppColors.border),
          AsyncView<List<Faq>>(
            future: _future,
            onRetry: () => setState(() => _future = DataService.faqs()),
            builder: (context, list) {
              final cats = list.map((f) => f.category).toSet().toList()
                ..sort((a, b) {
                  final ia = _order.indexOf(a), ib = _order.indexOf(b);
                  return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
                });
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in cats) ...[
                      const SizedBox(height: 26),
                      Text(c, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
                      for (final f in list.where((f) => f.category == c))
                        Container(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _open = _open == f.question ? null : f.question),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(f.question, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15))),
                                      AnimatedRotation(
                                        turns: _open == f.question ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 200),
                                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                child: _open == f.question
                                    ? Padding(
                                        padding: const EdgeInsets.only(bottom: 18),
                                        child: Text(f.answer, style: AppTextStyles.paragraph.copyWith(fontSize: 15, height: 1.8, color: const Color(0xFF9B9B9B))),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Re-exported so Contact Us can be opened from anywhere.
class OpenContact {
  static void contact(BuildContext context) => Navigator.of(context).push(appRoute(const ContactUsScreen()));
}

