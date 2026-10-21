import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/welcome_screen.dart';
import 'onboarding_data.dart';
import 'onboarding_hero.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String seenKey = 'onboarding_seen';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  double _page = 0;

  int get _index => _page.round().clamp(0, onboardingPages.length - 1);
  bool get _isLast => _index == onboardingPages.length - 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen.seenKey, true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(anim),
            child: child,
          ),
        ),
      ),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = onboardingPages[_index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            // Illustration card + Skip.
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).width.clamp(0.0, 430.0) * 406 / 375,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingPages.length,
                    itemBuilder: (context, i) => OnboardingHero(
                      page: onboardingPages[i],
                      pageOffset: (i - _page).clamp(-1.0, 1.0),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 30, 0),
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(ignoring: _isLast, child: _SkipPill(onTap: _finish)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 49),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(_index),
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(page.title, style: AppTextStyles.headline1, textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 314),
                            child: Text(page.body, style: AppTextStyles.paragraph, textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _Dots(count: onboardingPages.length, page: _page),
                    const SizedBox(height: 26),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: PrimaryButton(label: _isLast ? 'Get Started' : 'Next', onPressed: _next),
                    ),
                    SizedBox(height: 44 + MediaQuery.paddingOf(context).bottom * 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipPill extends StatelessWidget {
  const _SkipPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            width: 69,
            height: 41,
            alignment: Alignment.center,
            color: AppColors.white10,
            child: Text('Skip', style: AppTextStyles.button),
          ),
        ),
      ),
    );
  }
}

/// Active dot is a 28x9 orange pill, others are 9x9 grey circles (5px gap).
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
        return Container(
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : 5),
          width: 9 + 19 * t,
          height: 9,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.disabled, AppColors.primary, t),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
