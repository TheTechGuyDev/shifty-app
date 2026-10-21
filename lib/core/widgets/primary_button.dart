import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The orange 56px button used across the Figma screens (radius 16).
/// Disabled state is grey with dark text, as in the designs.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _active => widget.enabled && !widget.loading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.enabled ? AppColors.white : AppColors.dark;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: _active ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.primary : AppColors.disabled,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: widget.loading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: textColor),
                  )
                : Text(
                    widget.label,
                    key: ValueKey('${widget.label}${widget.enabled}'),
                    style: AppTextStyles.button.copyWith(color: textColor),
                  ),
          ),
        ),
      ),
    );
  }
}

/// White outlined button ("Go to Login page ->").
class OutlineButtonX extends StatelessWidget {
  const OutlineButtonX({super.key, required this.label, required this.onPressed, this.trailingArrow = false});

  final String label;
  final VoidCallback onPressed;
  final bool trailingArrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: AppTextStyles.headline6),
              if (trailingArrow) ...[
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.dark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
