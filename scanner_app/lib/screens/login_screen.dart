import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFocus = FocusNode();

  late AnimationController _animController;
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late AnimationController _blob3Controller;

  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _blob1Anim;
  late Animation<Offset> _blob2Anim;
  late Animation<Offset> _blob3Anim;

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Infinite drifting background blobs
    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    
    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);
    
    _blob3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _blob1Anim = Tween<Offset>(
      begin: const Offset(-60, -120),
      end: const Offset(-30, -80),
    ).animate(CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));

    _blob2Anim = Tween<Offset>(
      begin: const Offset(200, 200),
      end: const Offset(220, 240),
    ).animate(CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));

    _blob3Anim = Tween<Offset>(
      begin: const Offset(40, -60),
      end: const Offset(60, -40),
    ).animate(CurvedAnimation(parent: _blob3Controller, curve: Curves.easeInOut));

    // Focus state listener
    _phoneFocus.addListener(() {
      setState(() => _isFocused = _phoneFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _animController.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _blob3Controller.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final phone = '+91${_phoneController.text.trim()}';
    final success = await auth.sendOtp(phone);
    if (success && mounted) {
      Navigator.pushNamed(context, '/otp');
    } else if (mounted) {
      _showError(auth.errorMessage ?? 'Failed to send OTP');
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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            // Drifting background glow blobs
            AnimatedBuilder(
              animation: _blob1Anim,
              builder: (_, __) => Positioned(
                top: _blob1Anim.value.dy,
                left: _blob1Anim.value.dx,
                child: _glow(AppColors.primary, 300),
              ),
            ),
            AnimatedBuilder(
              animation: _blob2Anim,
              builder: (_, __) => Positioned(
                top: _blob2Anim.value.dy,
                right: _blob2Anim.value.dx - 300,
                child: _glow(AppColors.secondary, 250),
              ),
            ),
            AnimatedBuilder(
              animation: _blob3Anim,
              builder: (_, __) => Positioned(
                bottom: _blob3Anim.value.dy,
                left: _blob3Anim.value.dx,
                child: _glow(AppColors.accent, 200),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Opacity(opacity: _fadeAnim.value, child: child),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),

                        // Branded Logo Container
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.gradientNavratri,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '🪔',
                              style: TextStyle(fontSize: 38),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Text(
                          'Welcome to\nNavratri 2024',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Enter your mobile number to get started',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Phone field with neon glow focus outline
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isFocused
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.25),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : [],
                          ),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            borderRadius: 16,
                            borderColor: _isFocused
                                ? AppColors.primary.withOpacity(0.7)
                                : Colors.white.withOpacity(0.1),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: Colors.white.withOpacity(0.1)),
                                    ),
                                  ),
                                  child: const Text(
                                    '+91',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '98765 43210',
                                      hintStyle: TextStyle(
                                          color: AppColors.textMuted,
                                          letterSpacing: 1),
                                      border: InputBorder.none,
                                      counterText: '',
                                      filled: false,
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().length != 10) {
                                        return 'Please enter a valid 10-digit number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isFocused
                                      ? const Icon(Icons.phone_android_rounded,
                                          color: AppColors.primary, size: 20)
                                      : const Icon(Icons.phone_android,
                                          color: AppColors.textMuted, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        GradientButton(
                          label: 'Get OTP',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _sendOtp,
                          gradient: AppColors.gradientNavratri,
                        ),

                        const SizedBox(height: 20),

                        // Interactive Terms / Privacy span recognizers
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                color: AppColors.textMuted.withOpacity(0.7),
                                fontSize: 12,
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(
                                    text: 'By continuing, you agree to our\n'),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // Action for Terms
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // Action for Privacy
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 52),

                        // Staggered features grid
                        _StaggeredFeaturesGrid(),
                        const SizedBox(height: 32),
                      ],
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

class _StaggeredFeaturesGrid extends StatefulWidget {
  @override
  State<_StaggeredFeaturesGrid> createState() => _StaggeredFeaturesGridState();
}

class _StaggeredFeaturesGridState extends State<_StaggeredFeaturesGrid> {
  final List<bool> _visible = [false, false, false, false];

  static const _features = [
    (Icons.qr_code_scanner, 'High-Speed Scanner', 'Zero delay entry'),
    (Icons.bolt, 'Offline Verification', 'Backup sync logs'),
    (Icons.history, 'Real-time Stats', 'Gate tracker dashboard'),
    (Icons.security, 'Authorized Gate', 'Security enforced'),
  ];

  static const _gradients = [
    AppColors.gradientPrimary,
    AppColors.gradientNavratri,
    AppColors.gradientGold,
    AppColors.gradientSuccess,
  ];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 120), () {
        if (mounted) setState(() => _visible[i] = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: List.generate(4, (i) {
        final f = _features[i];
        final g = _gradients[i];
        return AnimatedOpacity(
          opacity: _visible[i] ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _visible[i] ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderRadius: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: g,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(f.$1, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          f.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          f.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
