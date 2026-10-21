import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/locations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

/// "Welcome Mobile": enter phone number to get started.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _phone = TextEditingController();
  Country _country = countries.first;

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length >= 7;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Select country', style: AppTextStyles.navTitle),
            const SizedBox(height: 8),
            for (final c in countries)
              ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                title: Text('${c.name} (${c.dialCode})', style: AppTextStyles.bodyMedium),
                trailing: c == _country ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(context, c),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _country = picked);
  }

  void _continue() {
    final phone = '${_country.dialCode}${_digits.replaceFirst(RegExp(r'^0'), '')}';
    Navigator.of(context).push(appRoute(OtpScreen(phone: phone)));
  }

  void _showPrivacy() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy and agreements', style: AppTextStyles.navTitle),
            const SizedBox(height: 12),
            Text(
              'We use your phone number to verify your account and to let service professionals '
              'contact you about your bookings. We never sell your data. Full terms will be published before launch.',
              style: AppTextStyles.paragraph,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: Navigator.of(context).canPop(),
      children: [
        const SizedBox(height: 20),
        Text('Welcome', style: AppTextStyles.headline1),
        const SizedBox(height: 6),
        Text('Enter your phone number to get started.', style: AppTextStyles.subtitle),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: _pickCountry,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Text(_country.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${_country.name} (${_country.dialCode})',
                              style: AppTextStyles.input.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.dark),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              SizedBox(
                height: 56,
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(15)],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _valid ? _continue() : null,
                  cursorColor: AppColors.primary,
                  style: AppTextStyles.input.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: AppTextStyles.input.copyWith(fontSize: 14, color: AppColors.label),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: GestureDetector(
            onTap: _showPrivacy,
            child: Text('Privacy and agreements', style: AppTextStyles.headline6),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Continue', enabled: _valid, onPressed: _continue),
        const SizedBox(height: 24),
        AuthSwitchLine(
          text: 'Already have an account ?',
          action: 'Login',
          onTap: () => Navigator.of(context).push(appRoute(const LoginScreen())),
        ),
      ],
    );
  }
}
