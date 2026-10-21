import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../home/home_screen.dart';

/// Opened from the password-reset email link.
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  bool get _passwordOk => _password.text.length >= 6;
  bool get _match => _confirm.text.isNotEmpty && _confirm.text == _password.text;
  bool get _mismatch => _confirm.text.isNotEmpty && _confirm.text != _password.text;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await AuthService.updatePassword(_password.text);
      if (!mounted) return;
      showAppSnack(context, 'Password updated');
      Navigator.of(context).pushAndRemoveUntil(appRoute(const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) showAppSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pwStatus = _mismatch || (_password.text.isNotEmpty && !_passwordOk) ? FieldStatus.error : FieldStatus.normal;
    final confirmStatus = _mismatch ? FieldStatus.error : (_match && _passwordOk ? FieldStatus.success : FieldStatus.normal);

    return AuthScaffold(
      children: [
        const AuthHeading(title: 'Set new password', subtitle: 'Create strong and secured\nnew password.'),
        const SizedBox(height: 30),
        AppTextField(
          label: 'Password',
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          status: pwStatus,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 23),
        AppTextField(
          label: 'Confirm Password',
          controller: _confirm,
          obscure: true,
          status: confirmStatus,
          onChanged: (_) => setState(() {}),
        ),
        if (_mismatch)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Text('Passwords do not match',
                style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.warning)),
          ),
        const SizedBox(height: 30),
        PrimaryButton(label: 'Save Password', enabled: _passwordOk && _match, loading: _loading, onPressed: _save),
      ],
    );
  }
}
