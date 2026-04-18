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
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
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
            // Glow blobs
            Positioned(top: -120, left: -60, child: _glow(AppColors.primary, 300)),
            Positioned(top: 200, right: -80, child: _glow(AppColors.secondary, 250)),
            Positioned(bottom: -60, left: 40, child: _glow(AppColors.accent, 200)),

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

                        // Header
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.gradientNavratri.createShader(b),
                          child: const Text(
                            '🪔',
                            style: TextStyle(fontSize: 48),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome to\nNavratri 2024',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: AppColors.textPrimary,
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

                        const SizedBox(height: 50),

                        // Phone field
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          borderRadius: 14,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
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
                              const Icon(Icons.phone_android,
                                  color: AppColors.textMuted, size: 20),
                            ],
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

                        const SizedBox(height: 24),

                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Features grid
                        _featuresGrid(),
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

  Widget _featuresGrid() {
    final features = [
      (Icons.confirmation_num_outlined, 'Buy Tickets', 'Instant booking'),
      (Icons.qr_code_2, 'QR Entry', 'Fast gate entry'),
      (Icons.swap_horiz, 'Transfer', 'Share tickets'),
      (Icons.verified_user_outlined, 'Season Pass', 'Full festival'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: features
          .map(
            (f) => GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderRadius: 12,
              child: Row(
                children: [
                  Icon(f.$1, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f.$2,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(f.$3,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
