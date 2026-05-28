import 'dart:ui';
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

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
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
    
    // Auto-focus first box
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNodes[0].requestFocus();
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
    ).animate(CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));

    _blob2Anim = Tween<Offset>(
      begin: const Offset(80, -80),
      end: const Offset(45, -45),
    ).animate(CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));
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
    final result = await auth.verifyOtp(otp);
    if (result == AuthResult.success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (result == AuthResult.newUser && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
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
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
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

                    // Beautiful stateful OTP Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          }
                          if (val.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          if (_otpValue.length == 6) {
                            _verify();
                          }
                        },
                      )),
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

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 58,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFocused || widget.controller.text.isNotEmpty
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 12,
          borderColor: _isFocused
              ? AppColors.primary
              : (widget.controller.text.isNotEmpty
                  ? AppColors.primary.withOpacity(0.5)
                  : Colors.white.withOpacity(0.12)),
          child: Center(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
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
                widget.onChanged(val);
              },
            ),
          ),
        ),
      ),
    );
  }
}
