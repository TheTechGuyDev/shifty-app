import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import 'info_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.email = ''});

  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  bool _loading = false;

  bool get _valid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await AuthService.sendPasswordReset(_email.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(appRoute(const InfoScreen(
        title: 'Reset email sent',
        message: 'We have sent all required instructions details to your mail.',
      )));
    } catch (e) {
      if (mounted) showAppSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const AuthHeading(title: 'Forget Password', subtitle: 'Enter your email address\nto reset password.'),
        const SizedBox(height: 44),
        AppTextField(
          label: 'Email Address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _valid ? _send() : null,
        ),
        const SizedBox(height: 30),
        PrimaryButton(label: 'Reset Password', enabled: _valid, loading: _loading, onPressed: _send),
      ],
    );
  }
}
