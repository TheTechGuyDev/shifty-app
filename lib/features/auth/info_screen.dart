import 'package:flutter/material.dart';

import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import 'login_screen.dart';

/// "Reset email sent" layout, reused for "Confirm your email".
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.title, required this.message});

  final String title;
  final String message;

  void _toLogin(BuildContext context) =>
      Navigator.of(context).pushAndRemoveUntil(appRoute(const LoginScreen()), (r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => _toLogin(context),
      bottom: OutlineButtonX(label: 'Go to Login page', trailingArrow: true, onPressed: () => _toLogin(context)),
      children: [
        AuthHeading(title: title, subtitle: message),
      ],
    );
  }
}
