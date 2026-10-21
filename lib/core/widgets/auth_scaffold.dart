import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared layout for the auth screens: back arrow (+ optional centred nav title),
/// then a scrollable body with 40px side padding.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.navTitle,
    this.showBack = true,
    this.onBack,
    this.bottom,
  });

  final List<Widget> children;
  final String? navTitle;
  final bool showBack;
  final VoidCallback? onBack;

  /// Pinned to the bottom (e.g. "Go to Login page").
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (showBack)
                      Positioned(
                        left: 14,
                        child: IconButton(
                          splashRadius: 22,
                          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.dark, size: 26),
                        ),
                      ),
                    if (navTitle != null) Text(navTitle!, style: AppTextStyles.navTitle),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 12, 40, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
                  child: bottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big title + grey subtitle used at the top of every auth screen.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headline1),
        const SizedBox(height: 14),
        Text(subtitle, style: AppTextStyles.subtitle),
      ],
    );
  }
}

/// "Already have an account ? Login" style line.
class AuthSwitchLine extends StatelessWidget {
  const AuthSwitchLine({super.key, required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: AppTextStyles.small),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onTap,
          child: Text(action, style: AppTextStyles.smallBold.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.small.copyWith(color: AppColors.white)),
        backgroundColor: error ? AppColors.failed : AppColors.dark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

/// Slide-and-fade route used for all forward navigation.
Route<T> appRoute<T>(Widget page, {String? name}) => PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
