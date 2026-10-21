import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShiftyApp());
}

class ShiftyApp extends StatelessWidget {
  const ShiftyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
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
