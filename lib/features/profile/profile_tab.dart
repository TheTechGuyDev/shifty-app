import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_scaffold.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.profile, required this.onLogout});

  final Map<String, dynamic>? profile;
  final VoidCallback onLogout;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _push = true;
  bool _promo = true;

  void _soon(String what) => showAppSnack(context, '$what is coming in the next build');

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = (p?['full_name'] as String?) ?? '';
    final email = (p?['email'] as String?) ?? '';
    final avatar = p?['avatar_url'] as String?;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

    return ListView(
      padding: const EdgeInsets.only(top: 40, bottom: 150),
      children: [
        Center(
          child: Container(
            width: 86,
            height: 86,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFFE05B57), borderRadius: BorderRadius.circular(24)),
            alignment: Alignment.center,
            child: avatar != null
                ? Image.network(avatar, fit: BoxFit.cover, width: 86, height: 86)
                : Text(initials, style: AppTextStyles.headline1.copyWith(color: Colors.white, fontSize: 30)),
          ),
        ),
        const SizedBox(height: 14),
        Text(name.isEmpty ? 'Your name' : name, textAlign: TextAlign.center, style: AppTextStyles.navTitle),
        const SizedBox(height: 4),
        Text(email, textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(color: AppColors.primary, fontSize: 13)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: () => _soon('Edit profile'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
            ),
            child: Text('Edit', style: AppTextStyles.small.copyWith(color: AppColors.dark, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 26),
        _section('GENERAL'),
        _row(Icons.credit_card_rounded, 'Payment Methods', 'Add your credit & debit cards', () => _soon('Payment methods')),
        _row(Icons.location_on_rounded, 'Locations', 'Add your home & work locations', () => _soon('Locations')),
        _row(Icons.camera_alt_outlined, 'Add Social Account', 'Add Facebook, Instagram, Twitter etc', () => _soon('Social accounts')),
        _row(Icons.ios_share_rounded, 'Refer to Friends', 'Get ₦2,000 for referring friends', () => _soon('Referrals')),
        const SizedBox(height: 18),
        _section('NOTIFICATIONS'),
        _switchRow('Push Notifications', 'For daily update and others.', _push, (v) => setState(() => _push = v)),
        _switchRow('Promotional Notifications', 'New Campaign & Offers', _promo, (v) => setState(() => _promo = v)),
        const SizedBox(height: 18),
        _section('MORE'),
        _row(Icons.phone_in_talk_rounded, 'Contact Us', 'For more information', () => _soon('Contact us')),
        _row(Icons.logout_rounded, 'Logout', null, widget.onLogout, last: true),
      ],
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(t,
            style: AppTextStyles.smallBold.copyWith(color: const Color(0xFFFD8A4E), fontSize: 15, letterSpacing: 0.8)),
      );

  Widget _row(IconData icon, String title, String? sub, VoidCallback onTap, {bool last = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5A5C60), size: 20),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: last ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.bodyMedium),
                          if (sub != null) ...[
                            const SizedBox(height: 4),
                            Text(sub, style: AppTextStyles.small.copyWith(fontSize: 13, color: const Color(0xFF7A7A7A))),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.dark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.notifications_rounded, color: Color(0xFF5A5C60), size: 20),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 4),
                        Text(sub, style: AppTextStyles.small.copyWith(fontSize: 13, color: const Color(0xFF7A7A7A))),
                      ],
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
