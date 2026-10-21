import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../pro/onboarding/pro_onboarding.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 4;
  static const _resendSeconds = 50;

  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _left = _resendSeconds;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      if (mounted) setState(() => _left = (_left - 1).clamp(0, _resendSeconds));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    // Real SMS verification plugs in here once an SMS provider is connected.
    if (AppConfig.otpDevMode && _code.text.length == _length) {
      Navigator.of(context).pushReplacement(appRoute(RoleChoiceScreen(phone: widget.phone)));
    } else {
      setState(() => _error = true);
    }
  }

  void _resend() {
    _code.clear();
    _startTimer();
    showAppSnack(context, 'A new code has been sent to ${widget.phone}');
  }

  @override
  Widget build(BuildContext context) {
    final complete = _code.text.length == _length;
    final timer = '00:${_left.toString().padLeft(2, '0')}';

    return AuthScaffold(
      navTitle: 'OTP Verification',
      children: [
        const SizedBox(height: 40),
        Text('An Authentication code has been sent to',
            textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 15)),
        const SizedBox(height: 4),
        Text(widget.phone,
            textAlign: TextAlign.center,
            style: AppTextStyles.smallBold.copyWith(fontSize: 15, color: AppColors.primary)),
        const SizedBox(height: 34),
        // Hidden input drives the four boxes.
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 1,
                  child: TextField(
                    controller: _code,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_length)],
                    onChanged: (v) {
                      setState(() => _error = false);
                      if (v.length == _length) _submit();
                    },
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _focus,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_length, (i) {
                    final text = _code.text;
                    final filled = i < text.length;
                    final active = _focus.hasFocus && i == text.length;
                    return Padding(
                      padding: EdgeInsets.only(right: i == _length - 1 ? 0 : 13),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 48,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _error
                                ? AppColors.warning
                                : active
                                    ? AppColors.primary
                                    : AppColors.border,
                          ),
                        ),
                        child: filled
                            ? Text(text[i],
                                style: AppTextStyles.headline1.copyWith(fontSize: 34, height: 1))
                            : active
                                ? const _Caret()
                                : null,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Submit', enabled: complete, onPressed: _submit),
        const SizedBox(height: 24),
        Center(
          child: _left > 0
              ? Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Code Sent. ', style: AppTextStyles.smallBold.copyWith(fontSize: 12)),
                    TextSpan(text: 'Resend Code in ', style: AppTextStyles.small.copyWith(fontSize: 12)),
                    TextSpan(text: timer, style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.primary)),
                  ]),
                )
              : GestureDetector(
                  onTap: _resend,
                  child: Text('Resend Code',
                      style: AppTextStyles.smallBold.copyWith(fontSize: 13, color: AppColors.primary)),
                ),
        ),
        if (AppConfig.otpDevMode) ...[
          const SizedBox(height: 28),
          Text('Test mode: any 4-digit code works until SMS is connected.',
              textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.label)),
        ],
      ],
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(width: 1.5, height: 25, color: AppColors.dark),
    );
  }
}
