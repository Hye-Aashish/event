import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _isNameFocused = false;
  bool _isEmailFocused = false;

  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late Animation<Offset> _blob1Anim;
  late Animation<Offset> _blob2Anim;

  @override
  void initState() {
    super.initState();

    // Focus state listeners
    _nameFocus.addListener(() {
      setState(() => _isNameFocused = _nameFocus.hasFocus);
    });
    _emailFocus.addListener(() {
      setState(() => _isEmailFocused = _emailFocus.hasFocus);
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.registerScanner(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (mounted) {
      CustomSnackBar.show(
        context,
        message: auth.errorMessage ?? 'Registration failed',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Glass back button
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
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your details to register as a scanner',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Name field with neon glow focus outline
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isNameFocused
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
                          borderColor: _isNameFocused
                              ? AppColors.primary.withOpacity(0.7)
                              : Colors.white.withOpacity(0.1),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _isNameFocused
                                    ? const Icon(Icons.person,
                                        color: AppColors.primary, size: 24)
                                    : const Icon(Icons.person_outline,
                                        color: AppColors.textMuted, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16),
                                  decoration: const InputDecoration(
                                    hintText: 'Full Name',
                                    hintStyle:
                                        TextStyle(color: AppColors.textMuted),
                                    border: InputBorder.none,
                                    filled: false,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email field with neon glow focus outline
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isEmailFocused
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
                          borderColor: _isEmailFocused
                              ? AppColors.primary.withOpacity(0.7)
                              : Colors.white.withOpacity(0.1),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _isEmailFocused
                                    ? const Icon(Icons.email,
                                        color: AppColors.primary, size: 24)
                                    : const Icon(Icons.email_outlined,
                                        color: AppColors.textMuted, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16),
                                  decoration: const InputDecoration(
                                    hintText: 'Email Address',
                                    hintStyle:
                                        TextStyle(color: AppColors.textMuted),
                                    border: InputBorder.none,
                                    filled: false,
                                  ),
                                  validator: (val) {
                                    if (val == null ||
                                        val.trim().isEmpty ||
                                        !val.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      GradientButton(
                        label: 'Register',
                        isLoading: auth.isLoading,
                        onPressed: auth.isLoading ? null : _register,
                        gradient: AppColors.gradientNavratri,
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
