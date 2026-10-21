import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum FieldStatus { normal, success, error }

/// Outlined input with the label sitting on the border, as in the Figma forms.
/// Green border + tick when [status] is success, orange when error.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.status = FieldStatus.normal,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController? controller;
  final FieldStatus status;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  Color get _accent => switch (widget.status) {
        FieldStatus.success => AppColors.success,
        FieldStatus.error => AppColors.warning,
        FieldStatus.normal => AppColors.border,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.status == FieldStatus.normal ? null : _accent;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: 1),
        );

    Widget? suffix = widget.suffix;
    if (widget.obscure && widget.status != FieldStatus.success) {
      suffix = IconButton(
        splashRadius: 20,
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: const Color(0xFFB0B0B0),
          size: 24,
        ),
      );
    } else if (widget.status == FieldStatus.success) {
      suffix = const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.check_rounded, color: AppColors.success, size: 20),
      );
    }

    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      obscuringCharacter: '•',
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      cursorColor: AppColors.primary,
      style: AppTextStyles.input.copyWith(
        color: statusColor ?? AppColors.dark,
        letterSpacing: _hidden ? 2 : -0.3,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTextStyles.label.copyWith(color: statusColor?.withAlpha(150)),
        floatingLabelStyle: AppTextStyles.label.copyWith(color: statusColor?.withAlpha(150)),
        contentPadding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
        filled: true,
        fillColor: AppColors.white,
        hoverColor: Colors.transparent,
        suffixIcon: suffix,
        enabledBorder: border(_accent),
        disabledBorder: border(AppColors.border),
        focusedBorder: border(statusColor ?? const Color(0xFFBDBDC2)),
        border: border(_accent),
      ),
    );
  }
}

/// Small rounded square checkbox: orange when checked, light grey when not.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.field,
          borderRadius: BorderRadius.circular(3),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: value ? 1 : 0,
          child: const Icon(Icons.check_rounded, size: 13, color: AppColors.white),
        ),
      ),
    );
  }
}
