import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_scaffold.dart';
import 'features/auth/set_new_password_screen.dart';
import 'features/splash/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Starts Supabase. The UI is shown straight away and the splash waits on this,
/// so a slow or failed start never leaves the phone stuck on the launch logo.
Future<bool> bootApp() => _boot ??= _start();
Future<bool>? _boot;

Future<bool> _start() async {
  try {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseKey).timeout(const Duration(seconds: 20));
    // Password-reset email link opens the app with a recovery session.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        SplashScreen.recoveryPending = true;
        navigatorKey.currentState?.pushAndRemoveUntil(appRoute(const SetNewPasswordScreen()), (_) => false);
      }
    }, onError: (_) {});
    return true;
  } catch (e) {
    debugPrint('Startup failed: $e');
    _boot = null; // allow a retry
    return false;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  bootApp();
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
      // Let mouse and trackpad drag horizontal lists and carousels on web/desktop.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
      ),
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
