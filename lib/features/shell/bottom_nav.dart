import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Dark bottom bar with a raised white circle that slides to the active tab,
/// sitting in a smooth bump cut into the bar (as in the Figma designs).
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.items, required this.index, required this.onTap});

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const double barHeight = 78;
  static const double bump = 26;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final slot = w / items.length;
      return TweenAnimationBuilder<double>(
        tween: Tween(end: index.toDouble()),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (context, pos, _) {
          final cx = slot * pos + slot / 2;
          return SizedBox(
            height: barHeight + bump + bottomInset,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _BarPainter(cx: cx, bump: bump)),
                ),
                // Inactive icons.
                for (var i = 0; i < items.length; i++)
                  Positioned(
                    left: slot * i,
                    width: slot,
                    top: bump,
                    height: barHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: (pos - i).abs() < 0.5 ? 0 : 1,
                        child: Icon(items[i].icon, color: AppColors.white, size: 26),
                      ),
                    ),
                  ),
                // Active raised circle + label.
                Positioned(
                  left: cx - 35,
                  top: bump - 35 + 8,
                  child: IgnorePointer(
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                          child: Icon(items[index].icon, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 90,
                          child: Text(
                            items[index].label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.small.copyWith(color: AppColors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.cx, required this.bump});
  final double cx;
  final double bump;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 48.0; // half-width of the bump
    final top = bump;
    final path = Path()
      ..moveTo(0, top)
      ..lineTo(cx - r - 22, top)
      ..cubicTo(cx - r + 2, top, cx - r + 4, 0, cx, 0)
      ..cubicTo(cx + r - 4, 0, cx + r - 2, top, cx + r + 22, top)
      ..lineTo(size.width, top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.dark);
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.cx != cx;
}
