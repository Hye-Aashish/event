import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/glass_card.dart';

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

  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late Animation<Offset> _blob1Anim;
  late Animation<Offset> _blob2Anim;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Auto-focus OTP input
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNode.requestFocus();
    });

    // Infinite background drifts
    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _blob1Anim = Tween<Offset>(
      begin: const Offset(-80, -80),
      end: const Offset(-45, -45),
    ).animate(
        CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));

    _blob2Anim = Tween<Offset>(
      begin: const Offset(80, -80),
      end: const Offset(45, -45),
    ).animate(
        CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));
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
      _showError('Please enter the 6-digit OTP');
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyOtp(otp);
    if (result == AuthResult.success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (result == AuthResult.newUser && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
    } else if (mounted) {
      _showError(auth.errorMessage ?? 'Invalid OTP');
      _otpController.clear();
      _otpNotifier.value = '';
      _otpFocusNode.requestFocus();
    }
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
            // Background glow blobs
            AnimatedBuilder(
              animation: _blob1Anim,
              builder: (_, __) => Positioned(
                bottom: _blob1Anim.value.dy,
                left: _blob1Anim.value.dx,
                child: _glow(AppColors.primary, 260),
              ),
            ),
            AnimatedBuilder(
              animation: _blob2Anim,
              builder: (_, __) => Positioned(
                top: _blob2Anim.value.dy,
                right: _blob2Anim.value.dx - 260,
                child: _glow(AppColors.secondary, 260),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Glassmorphism back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.arrow_back_ios_new,
                                    color: AppColors.textPrimary, size: 16),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      // OTP Boxes — only this subtree rebuilds on typing
                      _ScannerOtpBoxes(
                        otpNotifier: _otpNotifier,
                        focusNode: _otpFocusNode,
                        controller: _otpController,
                        onChanged: (val) {
                          _otpNotifier.value = val;
                          if (val.length == 6) _verify();
                        },
                      ),

                      // #18 Paste OTP button
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
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

                      GradientButton(
                        label: 'Verify OTP',
                        isLoading: auth.isLoading,
                        onPressed: auth.isLoading ? null : _verify,
                        gradient: AppColors.gradientNavratri,
                      ),

                      const SizedBox(height: 28),

                      Center(
                        child: _canResend
                            ? TextButton(
                                onPressed: () {
                                  final phone = auth.pendingPhone ?? '';
                                  auth.sendOtp(phone);
                                  setState(() => _canResend = false);
                                  _startCountdown();
                                },
                                child: const Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : Text(
                                'Resend OTP in ${_resendCountdown}s',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 60,
              spreadRadius: 20,
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Separate StatelessWidget — rebuilds are isolated from the parent Scaffold
// ---------------------------------------------------------------------------
class _ScannerOtpBoxes extends StatelessWidget {
  const _ScannerOtpBoxes({
    required this.otpNotifier,
    required this.focusNode,
    required this.controller,
    required this.onChanged,
  });

  final ValueNotifier<String> otpNotifier;
  final FocusNode focusNode;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden TextField that captures input
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: TextField(
                key: const Key('scanner_otp_hidden_textfield'),
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
                      borderRadius: BorderRadius.circular(12),
                      gradient: isFilled ? AppColors.gradientPrimary : null,
                      color: isFilled ? null : AppColors.surface,
                      border: Border.all(
                        color: isFilled
                            ? Colors.transparent
                            : isFocused
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.12),
                        width: isFocused || isFilled ? 1.5 : 1.0,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 14,
                              )
                            ]
                          : isFocused
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  )
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
    );
  }
}
