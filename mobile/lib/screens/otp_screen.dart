import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNodes[0].requestFocus();
    });
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

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      _showError('Please enter the 6-digit OTP');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(otp);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      _showError(auth.errorMessage ?? 'Invalid OTP');
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            Positioned(top: -80, right: -60, child: _glow(AppColors.secondary, 260)),
            Positioned(bottom: -80, left: -40, child: _glow(AppColors.primary, 240)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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

                    // OTP Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _buildOtpBox(i)),
                    ),

                    const SizedBox(height: 40),

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
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 60,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 12,
        borderColor: _controllers[index].text.isNotEmpty
            ? AppColors.primary
            : null,
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (val) {
            setState(() {});
            if (val.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            }
            if (val.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
            if (_otpValue.length == 6) {
              _verify();
            }
          },
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
        ),
      );
}
