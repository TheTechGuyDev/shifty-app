import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/login_screen.dart';

/// Temporary home: proves sign-in works. The Figma Dashboard replaces this next.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    AuthService.myProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    }).catchError((_) {});
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(appRoute(const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final name = (_profile?['full_name'] as String?)?.split(' ').first ?? '';
    return AuthScaffold(
      showBack: false,
      bottom: OutlineButtonX(label: 'Log out', onPressed: _logout),
      children: [
        const SizedBox(height: 20),
        Text('Hello${name.isEmpty ? '' : ', $name'} 👋', style: AppTextStyles.headline1),
        const SizedBox(height: 12),
        Text('You are signed in. The dashboard is being built next.', style: AppTextStyles.subtitle),
        const SizedBox(height: 24),
        if (_profile != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final k in ['email', 'phone', 'address', 'state'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${k[0].toUpperCase()}${k.substring(1)}: ${_profile?[k] ?? '-'}',
                        style: AppTextStyles.small.copyWith(color: AppColors.dark)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
