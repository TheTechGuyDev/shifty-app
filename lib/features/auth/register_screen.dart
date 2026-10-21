import 'package:flutter/material.dart';

import '../../core/data/locations.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'info_screen.dart';
import 'login_screen.dart';

/// "Getting Started" registration form.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.phone = ''});

  final String phone;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _zip = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _stateCtrl = TextEditingController();
  String? _state;
  bool _agreed = false;
  bool _loading = false;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get _emailOk => _emailRe.hasMatch(_email.text.trim());
  bool get _passwordOk => _password.text.length >= 6;
  bool get _confirmOk => _confirm.text.isNotEmpty && _confirm.text == _password.text;

  bool get _canSubmit =>
      _name.text.trim().length >= 2 &&
      _emailOk &&
      _address.text.trim().isNotEmpty &&
      _zip.text.trim().isNotEmpty &&
      _state != null &&
      _passwordOk &&
      _confirmOk &&
      _agreed;

  @override
  void dispose() {
    for (final c in [_name, _email, _address, _zip, _password, _confirm, _stateCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickState() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Select state', style: AppTextStyles.navTitle),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scroll,
                children: [
                  for (final s in nigerianStates)
                    ListTile(
                      title: Text(s, style: AppTextStyles.bodyMedium),
                      trailing: s == _state ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                      onTap: () => Navigator.pop(context, s),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _state = picked;
        _stateCtrl.text = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final active = await AuthService.register(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        phone: widget.phone,
        address: _address.text,
        zipCode: _zip.text,
        state: _state!,
      );
      if (!mounted) return;
      if (active) {
        Navigator.of(context).pushAndRemoveUntil(appRoute(const HomeScreen()), (_) => false);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          appRoute(InfoScreen(
            title: 'Confirm your email',
            message: 'We sent a confirmation link to ${_email.text.trim()}. Open it to activate your account, then log in.',
          )),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) showAppSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void refresh(String _) => setState(() {});

    FieldStatus confirmStatus = FieldStatus.normal;
    if (_confirm.text.isNotEmpty) confirmStatus = _confirmOk ? FieldStatus.success : FieldStatus.error;

    return AuthScaffold(
      navTitle: 'Register',
      children: [
        const AuthHeading(title: 'Getting Started', subtitle: 'Seems you are new here,\nLet’s set up your profile.'),
        const SizedBox(height: 34),
        AppTextField(
          label: 'Full Name',
          controller: _name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: refresh,
        ),
        const SizedBox(height: 23),
        AppTextField(
          label: 'Email Address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          status: _email.text.isNotEmpty && !_emailOk ? FieldStatus.error : FieldStatus.normal,
          onChanged: refresh,
        ),
        const SizedBox(height: 23),
        AppTextField(
          label: 'Current Address',
          controller: _address,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.streetAddressLine1],
          onChanged: refresh,
        ),
        const SizedBox(height: 23),
        Row(
          children: [
            Expanded(
              flex: 128,
              child: AppTextField(
                label: 'Zip Code',
                controller: _zip,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.postalCode],
                onChanged: refresh,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 152,
              child: AppTextField(
                label: 'State',
                controller: _stateCtrl,
                readOnly: true,
                onTap: _pickState,
                suffix: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFC4C4C4), size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 23),
        AppTextField(
          label: 'Password',
          controller: _password,
          obscure: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          status: _password.text.isNotEmpty && !_passwordOk ? FieldStatus.error : FieldStatus.normal,
          onChanged: refresh,
        ),
        if (_password.text.isNotEmpty && !_passwordOk)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text('At least 6 characters', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.warning)),
          ),
        const SizedBox(height: 23),
        AppTextField(
          label: 'Confirm Password',
          controller: _confirm,
          obscure: true,
          status: confirmStatus,
          onChanged: refresh,
          onSubmitted: (_) => _canSubmit ? _submit() : null,
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppCheckbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'By creating an account, you agree to our\n', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.dark.withAlpha(190))),
                    TextSpan(text: 'Term and Conditions', style: AppTextStyles.smallBold.copyWith(fontSize: 12, color: AppColors.primary)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Continue', enabled: _canSubmit, loading: _loading, onPressed: _submit),
        const SizedBox(height: 22),
        AuthSwitchLine(
          text: 'Already have an account ?',
          action: 'Login',
          onTap: () => Navigator.of(context).pushReplacement(appRoute(const LoginScreen())),
        ),
      ],
    );
  }
}
