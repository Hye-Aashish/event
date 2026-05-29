import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulse;
  late Animation<Offset> _blob1Anim;
  late Animation<Offset> _blob2Anim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _blob1Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat(reverse: true);
    _blob2Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 9))
          ..repeat(reverse: true);

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
            parent: _logoController, curve: Curves.elasticOut));
    _textFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _blob1Anim = Tween<Offset>(
      begin: const Offset(-100, -100),
      end: const Offset(-60, -70),
    ).animate(
        CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));
    _blob2Anim = Tween<Offset>(
      begin: const Offset(-80, -100),
      end: const Offset(-50, -70),
    ).animate(
        CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400),
        () => _textController.forward());
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    int attempts = 0;
    while (attempts < 20 &&
        (auth.state == AuthState.initial || auth.state == AuthState.loading)) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    if (!mounted) return;
    if (auth.isAuthenticated) {
      if (auth.user?.name == null ||
          auth.user!.name.isEmpty ||
          auth.user!.name == 'Guest') {
        Navigator.pushReplacementNamed(context, '/register');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            // Animated glow blobs
            AnimatedBuilder(
              animation: _blob1Anim,
              builder: (_, __) => Positioned(
                top: _blob1Anim.value.dy,
                left: _blob1Anim.value.dx,
                child: _glowBlob(AppColors.primary, 320),
              ),
            ),
            AnimatedBuilder(
              animation: _blob2Anim,
              builder: (_, __) => Positioned(
                bottom: _blob2Anim.value.dy,
                right: _blob2Anim.value.dx,
                child: _glowBlob(AppColors.secondary, 280),
              ),
            ),

            // Frosted glass accent strip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(height: 1, color: Colors.transparent),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with elastic entrance + slow pulse
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) =>
                            Transform.scale(scale: _pulse.value, child: child),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.gradientNavratri,
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.55),
                                  blurRadius: 40,
                                  spreadRadius: 6),
                              BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  blurRadius: 60,
                                  spreadRadius: 10),
                            ],
                          ),
                          child: const Center(
                            child: Text('🪔', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title text
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.gradientNavratri.createShader(b),
                            child: const Text(
                              'NAVRATRI',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2 0 2 6',
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientNavratri,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 64),

                  // Neon loading indicator
                  FadeTransition(
                    opacity: _textFade,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.8)),
                      ),
                    ),
                  ),
                ],
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
          color: color.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 80,
                spreadRadius: 20),
          ],
        ),
      );
}
