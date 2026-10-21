import 'package:flutter/material.dart';

/// A positioned piece of the onboarding hero, in Figma coordinates (375 x 406 hero).
class HeroLayer {
  const HeroLayer.image(
    this.asset, {
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.float = false,
  }) : child = null;

  const HeroLayer.widget(
    this.child, {
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.float = false,
  }) : asset = null;

  final String? asset;
  final Widget? child;
  final double left;
  final double top;
  final double width;
  final double height;

  /// Gently bobs up and down (used for the floating bubbles).
  final bool float;
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.background,
    required this.backgroundTop,
    required this.dots,
    required this.layers,
  });

  final String title;
  final String body;
  final String background;

  /// The gradient card is 437px tall and starts above the screen top.
  final double backgroundTop;

  /// Small translucent dots: (left, top, size).
  final List<(double, double, double)> dots;
  final List<HeroLayer> layers;
}

const _dir = 'assets/images/onboarding';

/// Glass bubble used where an exported asset is not available.
class GlassBubble extends StatelessWidget {
  const GlassBubble({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x33FFFFFF),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

final List<OnboardingPageData> onboardingPages = [
  const OnboardingPageData(
    title: 'Easy Process',
    body: 'Find all your house needs in one place. We provide every service to make your home experience smooth.',
    background: '$_dir/onb1_bg.png',
    backgroundTop: -31,
    dots: [(67.0, 79.0, 8.0), (268.0, 343.0, 24.0), (326.0, 165.0, 12.0), (30.0, 140.0, 12.0), (158.0, 109.0, 12.0), (32.0, 239.0, 6.0)],
    layers: [
      HeroLayer.image('$_dir/onb1_illustration.png', left: -6, top: 108, width: 388, height: 232),
      HeroLayer.image('$_dir/onb1_tree_bubble.png', left: 37, top: 281, width: 68, height: 77.5, float: true),
      HeroLayer.image('$_dir/onb1_house_bubble.png', left: 233, top: 87, width: 84, height: 84, float: true),
    ],
  ),
  const OnboardingPageData(
    title: 'Fast Transportation',
    body: 'We provide the best transportation service and organize your furniture properly to prevent any damage.',
    background: '$_dir/onb2_bg.png',
    backgroundTop: -32,
    dots: [(292.0, 348.0, 10.0), (110.0, 67.0, 8.0), (326.0, 165.0, 12.0), (35.0, 186.0, 12.0)],
    layers: [
      HeroLayer.image('$_dir/onb2_truck.png', left: 57.7, top: 153.4, width: 275.3, height: 159.1),
      HeroLayer.image('$_dir/onb2_avatar_bubble.png', left: 222, top: 78, width: 72, height: 72, float: true),
      HeroLayer.image('$_dir/onb2_car_bubble.png', left: 108, top: 299, width: 66, height: 73.1, float: true),
      HeroLayer.image('$_dir/onb2_heart_bubble.png', left: 50, top: 83, width: 36, height: 36, float: true),
    ],
  ),
  OnboardingPageData(
    title: 'Expert People',
    body: 'We have the best in class individuals working just for you. They are well trained and capable of handling anything you need.',
    background: '$_dir/onb3_bg.png',
    backgroundTop: -32,
    dots: const [(110.0, 67.0, 8.0), (323.0, 55.0, 12.0), (35.0, 186.0, 12.0)],
    layers: [
      const HeroLayer.image('$_dir/onb3_person.png', left: 63, top: 85, width: 260, height: 249),
      const HeroLayer.widget(
        GlassBubble(child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 30)),
        left: 109, top: 42, width: 66, height: 66, float: true,
      ),
      const HeroLayer.widget(
        GlassBubble(child: Text('💛', style: TextStyle(fontSize: 14))),
        left: 44, top: 262, width: 28, height: 28, float: true,
      ),
      HeroLayer.widget(
        GlassBubble(
          child: Container(
            width: 34,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFFFFD527), Color(0xFF08C118)],
              ),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
          ),
        ),
        left: 273, top: 145, width: 66, height: 66, float: true,
      ),
    ],
  ),
];
