import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/register_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';
import 'services/dio_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  DioClient.onUnauthorized = () {
    authProvider.logout(remote: false);
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  runApp(ScannerApp(authProvider: authProvider));
}

class ScannerApp extends StatelessWidget {
  final AuthProvider authProvider;
  const ScannerApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(
        title: 'Navratri Gate Scanner',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/otp': (_) => const OtpScreen(),
          '/register': (_) => const RegisterScreen(),

          // Login ke baad Seedha Scanner par jayega
          '/home': (_) => const ScannerHomeScreen(),
          '/scanner': (_) => const ScannerScreen(),
        },
      ),
    );
  }
}

// Scanner users ke liye premium animated stateful Home
class ScannerHomeScreen extends StatefulWidget {
  const ScannerHomeScreen({super.key});

  @override
  State<ScannerHomeScreen> createState() => _ScannerHomeScreenState();
}

class _ScannerHomeScreenState extends State<ScannerHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotationController;
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;

  late Animation<double> _floatAnimation;
  late Animation<Offset> _blob1Anim;
  late Animation<Offset> _blob2Anim;

  @override
  void initState() {
    super.initState();

    // Floating breathing animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Biometric scanner rotating ring border
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Drifting background glow blobs
    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _blob1Anim = Tween<Offset>(
      begin: const Offset(-50, -50),
      end: const Offset(-20, -20),
    ).animate(
        CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));

    _blob2Anim = Tween<Offset>(
      begin: const Offset(50, -50),
      end: const Offset(20, -20),
    ).animate(
        CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotationController.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  // Premium Glassmorphism Logout Confirmation Dialog
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  borderColor: AppColors.error.withOpacity(0.3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withOpacity(0.12),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.power_settings_new_rounded,
                          color: AppColors.error,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Confirm Logout',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Are you sure you want to logout? You will need to verify via OTP to access the gate scanner again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              label: 'Logout',
                              height: 48,
                              onPressed: () => Navigator.pop(ctx, true),
                              gradient: const LinearGradient(
                                colors: [AppColors.error, Color(0xFFC62828)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                bottom: _blob2Anim.value.dy,
                right: _blob2Anim.value.dx - 300,
                child: _glow(AppColors.secondary, 280),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'GATE KEEPER AGENT',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ShaderMask(
                                        shaderCallback: (bounds) => AppColors
                                            .gradientNavratri
                                            .createShader(bounds),
                                        child: Text(
                                          auth.user?.name ?? 'Scanner Agent',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final confirm =
                                          await _showLogoutDialog(context);
                                      if (confirm == true && context.mounted) {
                                        await context
                                            .read<AuthProvider>()
                                            .logout();
                                        if (context.mounted) {
                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              '/login',
                                              (route) => false);
                                        }
                                      }
                                    },
                                    child: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.08),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.1)),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                                Icons.power_settings_new,
                                                color: AppColors.error,
                                                size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 50),
                              const Center(
                                child: Text(
                                  'NAVRATRI 2024',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Center(
                                child: Text(
                                  'TICKET VERIFICATION',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Majestic Interactive Biometric Scanner Button
                              Center(
                                child: AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _floatAnimation.value),
                                      child: child,
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, '/scanner'),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Sweeping circular glow
                                        RotationTransition(
                                          turns: _rotationController,
                                          child: Container(
                                            width: 240,
                                            height: 240,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: SweepGradient(
                                                colors: [
                                                  AppColors.primary,
                                                  Colors.transparent,
                                                  AppColors.primary
                                                      .withOpacity(0.4),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Nested visual pulse ring
                                        Container(
                                          width: 226,
                                          height: 226,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            border: Border.all(
                                              color: AppColors.primary
                                                  .withOpacity(0.15),
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                        // Central scanner pad glass card
                                        ClipOval(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 12, sigmaY: 12),
                                            child: Container(
                                              width: 210,
                                              height: 210,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(
                                                        0.08),
                                                    Colors.white.withOpacity(
                                                        0.02),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.15),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.qr_code_scanner,
                                                    size: 70,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(height: 14),
                                                  Text(
                                                    'TAP TO SCAN',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 2,
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
                                ),
                              ),

                              const Spacer(),

                              const Center(
                                child: StatusBadge(
                                  label: 'SECURE WORKSTATION',
                                  color: AppColors.success,
                                  animate: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Center(
                                child: Text(
                                  'Authorized Gate Keeper Personnel Only',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
          color: color.withOpacity(0.08),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.04),
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
      );
}
