import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'onboarding_data.dart';

/// Renders one onboarding illustration card at Figma scale (375 x 406),
/// scaled to the available width.
class OnboardingHero extends StatefulWidget {
  const OnboardingHero({super.key, required this.page, required this.pageOffset});

  final OnboardingPageData page;

  /// -1..1, how far this page is from being centred (for parallax).
  final double pageOffset;

  static const double designW = 375;
  static const double designH = 406;

  @override
  State<OnboardingHero> createState() => _OnboardingHeroState();
}

class _OnboardingHeroState extends State<OnboardingHero> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.page;
    final offset = widget.pageOffset;

    return AspectRatio(
      aspectRatio: OnboardingHero.designW / OnboardingHero.designH,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: OnboardingHero.designW,
          height: OnboardingHero.designH,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient card with rounded bottom corners.
                Positioned(
                  left: 0,
                  top: p.backgroundTop,
                  width: 375,
                  height: 406,
                  child: Image.asset(p.background, fit: BoxFit.fill),
                ),
                // Large soft circle behind the illustration.
                Positioned(
                  left: 78,
                  top: 114,
                  width: 220,
                  height: 220,
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1AFFFFFF)),
                  ),
                ),
                // Small translucent dots.
                for (final d in p.dots)
                  Positioned(
                    left: d.$1,
                    top: d.$2,
                    width: d.$3,
                    height: d.$3,
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1AFFFFFF)),
                    ),
                  ),
                for (var i = 0; i < p.layers.length; i++) _layer(p.layers[i], i, offset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _layer(HeroLayer l, int index, double offset) {
    final content = l.asset != null ? Image.asset(l.asset!, fit: BoxFit.fill) : l.child!;

    // Parallax: floating bubbles drift faster than the main illustration.
    final parallax = offset * (l.float ? 60 : 25);

    return Positioned(
      left: l.left,
      top: l.top,
      width: l.width,
      height: l.height,
      child: Transform.translate(
        offset: Offset(parallax, 0),
        child: l.float
            ? AnimatedBuilder(
                animation: _float,
                builder: (context, child) {
                  final t = _float.value * 2 * math.pi + index * 1.3;
                  return Transform.translate(offset: Offset(0, math.sin(t) * 4), child: child);
                },
                child: content,
              )
            : content,
      ),
    );
  }
}
