import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/google_button.dart';
import '../../core/widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const rememberKey = 'remember_me';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _loading = false;
  bool _wrong = false;

  bool get _canSubmit => _email.text.trim().contains('@') && _password.text.isNotEmpty && !_wrong;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await AuthService.login(_email.text, _password.text);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(LoginScreen.rememberKey, _remember);
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(appRoute(const HomeScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      final msg = AuthService.friendlyError(e);
      setState(() => _wrong = msg.startsWith('Incorrect'));
      showAppSnack(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    try {
      await AuthService.loginWithGoogle();
    } catch (e) {
      if (mounted) showAppSnack(context, AuthService.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const AuthHeading(title: 'Let’s Sign You In', subtitle: 'Welcome back, you’ve\nbeen missed!'),
        const SizedBox(height: 50),
        AppTextField(
          label: 'Email Address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() => _wrong = false),
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Password',
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.password],
          status: _wrong ? FieldStatus.error : FieldStatus.normal,
          onChanged: (_) => setState(() => _wrong = false),
          onSubmitted: (_) => _canSubmit ? _login() : null,
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const SizedBox(width: 6),
            AppCheckbox(value: _remember && !_wrong, onChanged: (v) => setState(() => _remember = v)),
            const SizedBox(width: 14),
            Text('Remember Me', style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(appRoute(ForgotPasswordScreen(email: _email.text))),
              child: Text('Forgot Password ?',
                  style: AppTextStyles.small.copyWith(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 26),
        PrimaryButton(label: 'Login', enabled: _canSubmit, loading: _loading, onPressed: _login),
        const SizedBox(height: 18),
        Center(
          child: Text('OR',
              style: AppTextStyles.smallBold.copyWith(fontSize: 12, color: AppColors.label, letterSpacing: 1)),
        ),
        const SizedBox(height: 18),
        GoogleButton(onPressed: _google),
        const SizedBox(height: 18),
        AuthSwitchLine(
          text: 'Don’t have an account ?',
          action: 'Sign Up',
          onTap: () => Navigator.of(context).pushReplacement(appRoute(const WelcomeScreen())),
        ),
      ],
    );
  }
}
