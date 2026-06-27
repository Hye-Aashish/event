import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_snackbar.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  // ValueNotifier so only the OTP boxes rebuild on each keystroke
  final ValueNotifier<String> _otpNotifier = ValueNotifier('');

  int _resendCountdown = 60;
  bool _canResend = false;
  bool _hasError = false;

  late AnimationController _entranceController;
  late AnimationController _shakeController;
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _shake;
  late Animation<Offset> _blob1;
  late Animation<Offset> _blob2;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _blob1Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _blob2Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat(reverse: true);

    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOut));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
    _blob1 = Tween<Offset>(
            begin: const Offset(-60, -80), end: const Offset(-30, -50))
        .animate(
            CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));
    _blob2 = Tween<Offset>(
            begin: const Offset(-80, -80), end: const Offset(-50, -50))
        .animate(
            CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));

    _entranceController.forward();
    _startCountdown();
    Future.delayed(
        const Duration(milliseconds: 350), () => _otpFocusNode.requestFocus());
  }

  void _startCountdown() async {
    for (int i = 60; i >= 0; i--) {
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      setState(() {
        _resendCountdown = i;
        _canResend = i == 0;
      });
    }
  }

  String get _otpValue => _otpController.text;

  Future<void> _verify() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      _triggerError();
      return;
    }
    setState(() => _hasError = false);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(otp);
    if (success && mounted) {
      if (auth.isNewUser) {
        Navigator.pushReplacementNamed(context, '/register');
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } else if (mounted) {
      _triggerError();
      _showError(auth.errorMessage ?? 'Invalid OTP');
      _otpController.clear();
      _otpNotifier.value = '';
      _otpFocusNode.requestFocus();
    }
  }

  void _triggerError() {
    if (mounted) {
      setState(() => _hasError = true);
    }
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _hasError = false);
      }
    });
  }

  void _showError(String msg) {
    CustomSnackBar.show(
      context,
      message: msg,
      type: SnackBarType.error,
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _otpNotifier.dispose();
    _entranceController.dispose();
    _shakeController.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            // // Animated blobs
            // AnimatedBuilder(
            //   animation: _blob1,
            //   builder: (_, __) => Positioned(
            //     top: _blob1.value.dy,
            //     right: _blob1.value.dx,
            //     child: _glowBlob(AppColors.secondary, 260),
            //   ),
            // ),
            // AnimatedBuilder(
            //   animation: _blob2,
            //   builder: (_, __) => Positioned(
            //     bottom: _blob2.value.dy,
            //     left: _blob2.value.dx,
            //     child: _glowBlob(AppColors.primary, 240),
            //   ),
            // ),

            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.1),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppColors.textPrimary,
                                      size: 18),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 20)
                              ],
                            ),
                            child: const Icon(Icons.lock_outline_rounded,
                                color: Colors.white, size: 30),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Enter OTP',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 15),
                              children: [
                                const TextSpan(text: 'OTP sent to '),
                                TextSpan(
                                  text: auth.pendingPhone ?? '',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          // OTP boxes — only this subtree rebuilds on typing
                          _OtpBoxes(
                            otpNotifier: _otpNotifier,
                            shakeAnimation: _shake,
                            focusNode: _otpFocusNode,
                            controller: _otpController,
                            hasError: _hasError,
                            onChanged: (val) {
                              _otpNotifier.value = val;
                              if (val.length == 6) _verify();
                            },
                          ),

                          const SizedBox(height: 16),

                          // Digit counter
                          ValueListenableBuilder<String>(
                            valueListenable: _otpNotifier,
                            builder: (_, val, __) => AnimatedOpacity(
                              opacity: val.isNotEmpty ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                '${val.length} / 6 digits entered',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                            ),
                          ),

                          // #18 Paste OTP button
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                    Clipboard.kTextPlain);
                                final text = data?.text?.trim() ?? '';
                                final digits =
                                    text.replaceAll(RegExp(r'[^0-9]'), '');
                                if (digits.length >= 6) {
                                  final otp = digits.substring(0, 6);
                                  _otpController.text = otp;
                                  _otpNotifier.value = otp;
                                  _verify();
                                }
                              },
                              icon: const Icon(Icons.content_paste_rounded,
                                  size: 14, color: AppColors.primary),
                              label: const Text('Paste OTP',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),

                          const SizedBox(height: 32),

                          GradientButton(
                            label: 'Verify OTP',
                            icon: Icons.check_circle_outline_rounded,
                            isLoading: auth.isLoading,
                            onPressed: auth.isLoading ? null : _verify,
                            gradient: AppColors.gradientNavratri,
                          ),

                          const SizedBox(height: 28),

                          Center(
                            child: _canResend
                                ? GestureDetector(
                                    onTap: () {
                                      final phone = auth.pendingPhone ?? '';
                                      auth.sendOtp(phone);
                                      setState(() => _canResend = false);
                                      _startCountdown();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.gradientPrimary,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 12)
                                        ],
                                      ),
                                      child: const Text('Resend OTP',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer_outlined,
                                          size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Resend in ${_resendCountdown}s',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowBlob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.09),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 60,
                spreadRadius: 10),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Separate StatelessWidget so it has its own Element — rebuilds are isolated
// ---------------------------------------------------------------------------
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.otpNotifier,
    required this.shakeAnimation,
    required this.focusNode,
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final ValueNotifier<String> otpNotifier;
  final Animation<double> shakeAnimation;
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(shakeAnimation.value, 0),
        child: child,
      ),
      child: GestureDetector(
        onTap: () => focusNode.requestFocus(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden TextField that captures input — no setState at parent level
            Opacity(
              opacity: 0,
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: TextField(
                  key: const Key('mobile_otp_hidden_textfield'),
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  showCursor: false,
                  cursorColor: Colors.transparent,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableInteractiveSelection: false,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
            // Visual OTP boxes — only rebuild via ValueListenableBuilder
            IgnorePointer(
              child: ValueListenableBuilder<String>(
                valueListenable: otpNotifier,
                builder: (_, text, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final isFilled = text.length > i;
                    final char = isFilled ? text[i] : '';
                    final isCurrent = text.length == i;
                    final isFocused = focusNode.hasFocus && isCurrent;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: isFilled ? AppColors.gradientPrimary : null,
                        color: isFilled ? null : AppColors.surface,
                        border: Border.all(
                          color: hasError
                              ? AppColors.error
                              : isFilled
                                  ? Colors.transparent
                                  : isFocused
                                      ? AppColors.primary
                                      : AppColors.border,
                          width: isFocused || isFilled ? 1.5 : 1.0,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 14)
                              ]
                            : hasError
                                ? [
                                    BoxShadow(
                                        color: AppColors.error.withOpacity(0.3),
                                        blurRadius: 8)
                                  ]
                                : isFocused
                                    ? [
                                        BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.2),
                                            blurRadius: 10,
                                            spreadRadius: 0)
                                      ]
                                    : [],
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                isFilled ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
