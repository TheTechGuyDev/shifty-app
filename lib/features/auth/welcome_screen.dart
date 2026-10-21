import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Placeholder for the "Welcome Mobile" phone-number screen (next build step).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome', style: AppTextStyles.headline1),
              const SizedBox(height: 16),
              Text(
                'Sign up and login screens for ${AppConfig.appName} are coming in the next build.',
                style: AppTextStyles.paragraph,
              ),
              const Spacer(),
              Center(
                child: Text(
                  AppConfig.tagline,
                  style: AppTextStyles.headline6.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
