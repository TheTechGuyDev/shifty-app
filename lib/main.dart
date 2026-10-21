import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_scaffold.dart';
import 'features/auth/set_new_password_screen.dart';
import 'features/splash/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseKey);

  // Password-reset email link opens the app with a recovery session.
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      SplashScreen.recoveryPending = true;
      navigatorKey.currentState?.pushAndRemoveUntil(appRoute(const SetNewPasswordScreen()), (_) => false);
    }
  });

  runApp(const ShiftyApp());
}

class ShiftyApp extends StatelessWidget {
  const ShiftyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // On web/desktop, show the app at phone width in the centre of the screen.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFF2F2F4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConfig.maxContentWidth),
            child: ClipRect(
              child: ColoredBox(color: AppColors.white, child: child),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
