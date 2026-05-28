import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _entranceController;
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<Offset> _blob1;
  late Animation<Offset> _blob2;

  bool _nameFocused = false;
  bool _emailFocused = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _blob1Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 9))
          ..repeat(reverse: true);
    _blob2Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat(reverse: true);

    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entranceController, curve: Curves.easeOut));
    _blob1 = Tween<Offset>(
            begin: const Offset(-100, -100), end: const Offset(-60, -70))
        .animate(CurvedAnimation(
            parent: _blob1Controller, curve: Curves.easeInOut));
    _blob2 = Tween<Offset>(
            begin: const Offset(-50, -50), end: const Offset(-80, -80))
        .animate(CurvedAnimation(
            parent: _blob2Controller, curve: Curves.easeInOut));

    _entranceController.forward();

    _nameFocus.addListener(
        () => setState(() => _nameFocused = _nameFocus.hasFocus));
    _emailFocus.addListener(
        () => setState(() => _emailFocused = _emailFocus.hasFocus));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
    );
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } else if (mounted) {
      _showError(auth.errorMessage ?? 'Registration failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _entranceController.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _blob1,
              builder: (_, __) => Positioned(
                top: _blob1.value.dy,
                right: _blob1.value.dx,
                child: _glowBlob(AppColors.primary, 300),
              ),
            ),
            AnimatedBuilder(
              animation: _blob2,
              builder: (_, __) => Positioned(
                bottom: _blob2.value.dy,
                left: _blob2.value.dx,
                child: _glowBlob(AppColors.secondary, 250),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 56),

                          // Logo
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientNavratri,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 20)
                              ],
                            ),
                            child: const Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 30),
                          ),

                          const SizedBox(height: 24),

                          ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.gradientNavratri.createShader(b),
                            child: const Text(
                              'Complete Profile',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tell us a bit about yourself to get started',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 15),
                          ),

                          const SizedBox(height: 40),

                          // Name field
                          _fieldLabel('Full Name', Icons.person_outline_rounded),
                          const SizedBox(height: 8),
                          _focusField(
                            focused: _nameFocused,
                            child: TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              style: const TextStyle(
                                  color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'John Doe',
                                hintStyle:
                                    TextStyle(color: AppColors.textMuted),
                                border: InputBorder.none,
                                filled: false,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (val) => (val == null || val.isEmpty)
                                  ? 'Please enter your name'
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Email field
                          _fieldLabel('Email Address', Icons.email_outlined),
                          const SizedBox(height: 8),
                          _focusField(
                            focused: _emailFocused,
                            child: TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                  color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'john@example.com',
                                hintStyle:
                                    TextStyle(color: AppColors.textMuted),
                                border: InputBorder.none,
                                filled: false,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter email';
                                }
                                if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(val)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 48),

                          GradientButton(
                            label: 'Complete Registration',
                            icon: Icons.how_to_reg_rounded,
                            isLoading: auth.isLoading,
                            onPressed: auth.isLoading ? null : _register,
                            gradient: AppColors.gradientNavratri,
                          ),

                          const SizedBox(height: 32),
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

  Widget _fieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 15),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3)),
      ],
    );
  }

  Widget _focusField({required bool focused, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: focused
            ? [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.22),
                    blurRadius: 20)
              ]
            : [],
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        borderColor: focused
            ? AppColors.primary.withOpacity(0.7)
            : Colors.white.withOpacity(0.1),
        child: child,
      ),
    );
  }

  Widget _glowBlob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
      );
}
