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
  late AnimationController _controller;
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _blob1Anim;
  late Animation<Offset> _blob2Anim;

  @override
  void initState() {
    super.initState();
    
    // Entrance animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _controller.forward();

    // Drifting background blobs
    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    
    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _blob1Anim = Tween<Offset>(
      begin: const Offset(-80, -100),
      end: const Offset(-40, -60),
    ).animate(CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));

    _blob2Anim = Tween<Offset>(
      begin: const Offset(80, -100),
      end: const Offset(40, -60),
    ).animate(CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    // Give it a max of 2 seconds to resolve auth
    int attempts = 0;
    while (attempts < 20 && (auth.state == AuthState.initial || auth.state == AuthState.loading)) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;
    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            // Drifting background glows
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
                bottom: _blob2Anim.value.dy,
                right: _blob2Anim.value.dx - 300,
                child: _glow(AppColors.secondary, 280),
              ),
            ),

            // Center content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo glow
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.gradientNavratri,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.gradientNavratri.createShader(bounds),
                          child: const Text(
                            'NAVRATRI',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '2 0 2 4',
                          style: TextStyle(
                            fontSize: 16,
                            letterSpacing: 8,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 60),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ),
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

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
