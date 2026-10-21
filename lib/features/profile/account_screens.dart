import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/data/locations.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../booking/booking_widgets.dart';
import 'support_screens.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.profile['full_name'] as String? ?? '');
  late final _email = TextEditingController(text: widget.profile['email'] as String? ?? '');
  late final _phone = TextEditingController(text: widget.profile['phone'] as String? ?? '');
  late final _address = TextEditingController(text: widget.profile['address'] as String? ?? '');
  late final _zip = TextEditingController(text: widget.profile['zip_code'] as String? ?? '');
  late final _state = TextEditingController(text: widget.profile['state'] as String? ?? '');
  late String? _avatar = widget.profile['avatar_url'] as String?;
  bool _busy = false;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address, _zip, _state]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final ext = name.endsWith('.png') ? 'png' : (name.endsWith('.webp') ? 'webp' : 'jpg');
      final url = await DataService.uploadAvatar(bytes, ext);
      if (mounted) setState(() => _avatar = url);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickState() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scroll) => ListView(
          controller: scroll,
          children: [
            for (final s in nigerianStates)
              ListTile(title: Text(s, style: AppTextStyles.bodyMedium), onTap: () => Navigator.pop(context, s)),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _state.text = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      showAppSnack(context, 'Enter your full name', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await DataService.updateProfile({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'zip_code': _zip.text.trim(),
        'state': _state.text.trim(),
      });
      final newEmail = _email.text.trim();
      if (newEmail.isNotEmpty && newEmail != widget.profile['email']) {
        await Supabase.instance.client.auth.updateUser(UserAttributes(email: newEmail), emailRedirectTo: AppConfig.webUrl);
        if (mounted) showAppSnack(context, 'Check $newEmail to confirm your new email');
      } else if (mounted) {
        showAppSnack(context, 'Profile updated');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    final initials = name.isEmpty ? '?' : name.split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
    return ServiceChrome(
      title: 'Edit Profile',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 30),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploading ? null : _pickPhoto,
              child: Container(
                width: 118,
                height: 118,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: const Color(0xFFE05B57), borderRadius: BorderRadius.circular(34)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_avatar != null)
                      Image.network(_avatar!, fit: BoxFit.cover)
                    else
                      Center(child: Text(initials, style: AppTextStyles.headline1.copyWith(color: Colors.white))),
                    Container(color: Colors.black.withAlpha(90)),
                    Center(
                      child: _uploading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          AppTextField(label: 'Full Name', controller: _name, onChanged: (_) => setState(() {})),
          const SizedBox(height: 23),
          AppTextField(label: 'Email Address', controller: _email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 23),
          AppTextField(
            label: 'Phone Number',
            controller: _phone,
            keyboardType: TextInputType.phone,
            suffix: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.check_rounded, color: AppColors.dark, size: 20)),
          ),
          const SizedBox(height: 23),
          AppTextField(label: 'Current Address', controller: _address),
          const SizedBox(height: 23),
          Row(
            children: [
              Expanded(flex: 128, child: AppTextField(label: 'Zip Code', controller: _zip, keyboardType: TextInputType.number)),
              const SizedBox(width: 15),
              Expanded(
                flex: 152,
                child: AppTextField(
                  label: 'State',
                  controller: _state,
                  readOnly: true,
                  onTap: _pickState,
                  suffix: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFC4C4C4), size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          GestureDetector(
            onTap: () => Navigator.of(context).push(appRoute(const ChangePasswordScreen())),
            child: AbsorbPointer(
              child: AppTextField(label: 'Password', controller: TextEditingController(text: '••••••••'), enabled: false),
            ),
          ),
          const SizedBox(height: 22),
          OutlineButtonX(
            label: 'Change Password',
            trailingArrow: true,
            onPressed: () => Navigator.of(context).push(appRoute(const ChangePasswordScreen())),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Save Changes', loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _wrongCurrent = false;

  bool get _ok => _current.text.isNotEmpty && _new.text.length >= 6 && _new.text == _confirm.text;

  @override
  void dispose() {
    for (final c in [_current, _new, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final email = AuthService.currentUser?.email;
    if (email == null) return;
    setState(() => _busy = true);
    try {
      try {
        await AuthService.login(email, _current.text);
      } catch (_) {
        setState(() => _wrongCurrent = true);
        if (mounted) showAppSnack(context, 'Current password is incorrect', error: true);
        return;
      }
      await AuthService.updatePassword(_new.text);
      await AuthService.logout();
      if (!mounted) return;
      showAppSnack(context, 'Password changed. Please log in again.');
      Navigator.of(context).pushAndRemoveUntil(appRoute(const LoginScreen()), (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mismatch = _confirm.text.isNotEmpty && _confirm.text != _new.text;
    return ServiceChrome(
      title: 'Change Password',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const PageIntro(title: 'Change Password', text: 'Please note changing password will require logging in to the app again.'),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 34, 40, 0),
            child: Column(
              children: [
                AppTextField(
                  label: 'Current Password',
                  controller: _current,
                  obscure: true,
                  status: _wrongCurrent ? FieldStatus.error : FieldStatus.normal,
                  onChanged: (_) => setState(() => _wrongCurrent = false),
                ),
                const SizedBox(height: 23),
                AppTextField(
                  label: 'New Password',
                  controller: _new,
                  obscure: true,
                  status: _new.text.isNotEmpty && _new.text.length < 6 ? FieldStatus.error : FieldStatus.normal,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 23),
                AppTextField(
                  label: 'Confirm New Password',
                  controller: _confirm,
                  obscure: true,
                  status: mismatch ? FieldStatus.error : (_ok ? FieldStatus.success : FieldStatus.normal),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 23),
                PrimaryButton(label: 'Save Password', enabled: _ok, loading: _busy, onPressed: _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _gLogo = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#FFC107" d="M43.6 20.1H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.6-.4-3.9z"/><path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/><path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z"/><path fill="#1976D2" d="M43.6 20.1H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.6-.4-3.9z"/></svg>''';

class SocialAccountsScreen extends StatefulWidget {
  const SocialAccountsScreen({super.key, required this.links});
  final Map<String, dynamic> links;

  @override
  State<SocialAccountsScreen> createState() => _SocialAccountsScreenState();
}

class _SocialAccountsScreenState extends State<SocialAccountsScreen> {
  late final Map<String, dynamic> _links = Map.of(widget.links);

  Future<void> _connect(String key, String name, String hint) async {
    final ctrl = TextEditingController(text: _links[key] as String? ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Connect $name', style: AppTextStyles.navTitle),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: hint)),
        actions: [
          if ((_links[key] as String?)?.isNotEmpty ?? false)
            TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Remove', style: TextStyle(color: AppColors.failed))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Save', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (value == null) return;
    setState(() {
      if (value.isEmpty) {
        _links.remove(key);
      } else {
        _links[key] = value;
      }
    });
    try {
      await DataService.updateProfile({'social_links': _links});
      if (mounted) showAppSnack(context, value.isEmpty ? '$name removed' : '$name connected');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String key, String name, Widget logo, Color bg, String hint) {
      final v = _links[key] as String?;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _connect(key, name, hint),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  logo,
                  Expanded(
                    child: Text(
                      v == null ? 'Connect with $name' : '$name · $v',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline6.copyWith(fontSize: 13),
                    ),
                  ),
                  if (v != null) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ServiceChrome(
      title: 'Add Social Accounts',
      bottom: OutlineButtonX(label: 'Go to Homepage', trailingArrow: true, onPressed: () => goHome(context)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 46, 30, 30),
        children: [
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(color: Color(0xFFE6EEFB), shape: BoxShape.circle),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF2F6FDB), size: 34),
            ),
          ),
          const SizedBox(height: 22),
          Text('Add Social Accounts', textAlign: TextAlign.center, style: AppTextStyles.navTitle.copyWith(fontSize: 21)),
          const SizedBox(height: 10),
          Text('Connecting with your friends and family has never been easier. Simply add your social accounts to stay connected',
              textAlign: TextAlign.center, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 30),
          row('google', 'Google', SvgPicture.string(_gLogo, width: 16, height: 16), const Color(0xFFF5F7F6), 'your.name@gmail.com'),
          row('facebook', 'Facebook', const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 20), const Color(0xFFEFF4FE), 'facebook.com/yourname'),
          row('twitter', 'Twitter', const Icon(Icons.alternate_email_rounded, color: Color(0xFF1D9BF0), size: 18), const Color(0xFFE5F5FD), '@yourhandle'),
        ],
      ),
    );
  }
}

class ReferFriendsScreen extends StatelessWidget {
  const ReferFriendsScreen({super.key, required this.code});
  final String code;

  String get link => '${AppConfig.webUrl}?ref=$code';

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Refer to Friends',
      bottom: OutlineButtonX(label: 'Go to Homepage', trailingArrow: true, onPressed: () => goHome(context)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
        children: [
          Center(
            child: SizedBox(
              width: 140,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10,
                    child: Container(
                      width: 90,
                      height: 120,
                      decoration: BoxDecoration(color: const Color(0xFFFFF1EA), borderRadius: BorderRadius.circular(60)),
                    ),
                  ),
                  const Icon(Icons.card_giftcard_rounded, size: 76, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Refer to Friends', textAlign: TextAlign.center, style: AppTextStyles.navTitle.copyWith(fontSize: 21)),
          const SizedBox(height: 10),
          Text('Get a ₦2,000 coupon code when someone signs up using your refer link',
              textAlign: TextAlign.center, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              showAppSnack(context, 'Link copied');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              margin: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(color: const Color(0xFFE6EEFB), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(link,
                        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(color: const Color(0xFF2F6FDB), fontSize: 15)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2F6FDB)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Your code: $code', textAlign: TextAlign.center, style: AppTextStyles.smallBold),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: PrimaryButton(
              label: 'Share link',
              onPressed: () => Share.share('Book trusted home services on ${AppConfig.appName}. Sign up with my link: $link'),
            ),
          ),
        ],
      ),
    );
  }
}
