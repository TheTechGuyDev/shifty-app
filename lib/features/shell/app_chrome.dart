import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Dark header (menu, logo or title, bell) above a white body with large rounded top corners.
class AppChrome extends StatelessWidget {
  const AppChrome({
    super.key,
    required this.body,
    this.title,
    this.onMenu,
    this.onBell,
    this.hasUnread = false,
    this.leading,
    this.bodyColor = AppColors.white,
  });

  final Widget body;

  /// Null shows the logo.
  final String? title;
  final VoidCallback? onMenu;
  final VoidCallback? onBell;
  final bool hasUnread;

  /// Replaces the menu button (e.g. a back arrow).
  final Widget? leading;
  final Color bodyColor;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.dark,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      leading ??
                          _HeaderButton(
                            onTap: onMenu,
                            child: const _GridIcon(),
                          ),
                      Expanded(
                        child: Center(
                          child: title == null
                              ? const AppLogo()
                              : Text(title!, style: AppTextStyles.navTitle.copyWith(color: AppColors.white)),
                        ),
                      ),
                      _HeaderButton(
                        onTap: onBell,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_rounded, color: AppColors.white, size: 24),
                            if (hasUnread)
                              Positioned(
                                right: -1,
                                top: -2,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: AppColors.failed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.dark, width: 1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                child: ColoredBox(color: bodyColor, child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: SizedBox(width: 44, height: 44, child: Center(child: child)),
    );
  }
}

/// Four rounded squares, one dimmed, as in the design.
class _GridIcon extends StatelessWidget {
  const _GridIcon();

  @override
  Widget build(BuildContext context) {
    Widget sq(double o) => Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: AppColors.white.withAlpha((o * 255).round()), borderRadius: BorderRadius.circular(3)),
        );
    return SizedBox(
      width: 22,
      height: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [sq(1), sq(0.55)]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [sq(1), sq(1)]),
        ],
      ),
    );
  }
}

/// Logo mark + app name (the name comes from AppConfig so renaming is one change).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.color = AppColors.white, this.size = 1});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/app/logo_mark_white.png', width: 40 * size, height: 32 * size, color: color),
        SizedBox(width: 4 * size),
        Text(
          AppConfig.appName,
          style: GoogleFonts.dmSans(
            fontSize: 22 * size,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.6,
            color: color,
          ),
        ),
      ],
    );
  }
}
