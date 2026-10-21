import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/welcome_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_data.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Set when the app was opened from a password-reset link.
  static bool recoveryPending = false;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Warm up onboarding images so the first page appears instantly.
    await Future<void>.delayed(Duration.zero);
    if (mounted) {
      for (final p in onboardingPages) {
        precacheImage(AssetImage(p.background), context);
        for (final l in p.layers) {
          if (l.asset != null) precacheImage(AssetImage(l.asset!), context);
        }
      }
    }
    var seenOnboarding = false;
    var remember = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      seenOnboarding = prefs.getBool(OnboardingScreen.seenKey) ?? false;
      remember = prefs.getBool(LoginScreen.rememberKey) ?? true;
    } catch (_) {}
    if (AuthService.isSignedIn && !remember) {
      await AuthService.logout();
    }

    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted || SplashScreen.recoveryPending) return;

    // Design-review shortcut on web: add ?screen=home to the URL to open the dashboard without logging in.
    final preview = Uri.base.queryParameters['screen'] == 'home';
    final Widget next = AuthService.isSignedIn || preview
        ? const HomeScreen()
        : seenOnboarding
            ? const WelcomeScreen()
            : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOut));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.6,
              colors: [Color(0xFFFFC876), Color(0xFFF38A3B), Color(0xFFE84B00)],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween(begin: 0.7, end: 1.0).animate(scale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
                        ],
                      ),
                      child: const Icon(Icons.home_repair_service_rounded, color: AppColors.primary, size: 46),
                    ),
                    // Invisible: makes Flutter web download the emoji font
                    // during the splash, so onboarding emojis never show as boxes.
                    const Opacity(
                      opacity: 0,
                      child: Text('🌲🚙❤️💛', style: TextStyle(fontSize: 2)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppConfig.appName,
                      style: GoogleFonts.dmSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
