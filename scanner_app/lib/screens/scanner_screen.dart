import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  String? _lastResult;
  bool _success = false;
  Map<String, dynamic>? _ticketData;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    // Futuristic laser scanning line sweep
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _lastResult != null) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final qrData = barcode!.rawValue!;
    debugPrint('ScannerScreen._onDetect() called with QR: $qrData');

    setState(() {
      _isProcessing = true;
      _lastResult = null;
      _ticketData = null;
    });

    try {
      final res = await ApiService.scanQr(qrData);
      if (!mounted) return;
      setState(() {
        _success = res['success'] == true;
        _lastResult = res['success'] == true
            ? 'Ticket verified successfully!'
            : (res['message'] ?? 'Invalid ticket');
        _ticketData = res['ticket'];
        _isProcessing = false;
      });

      // Auto-reset after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _lastResult = null;
            _ticketData = null;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _lastResult = 'Network error. Try again.';
        _isProcessing = false;
      });

      // Auto-reset after 5 seconds even on network error
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _lastResult = null;
            _ticketData = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final frameColor = _lastResult != null
        ? (_success ? AppColors.success : AppColors.error)
        : AppColors.primary;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
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
                        const Expanded(
                          child: Text(
                            'Gate Scanner',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _controller?.toggleTorch(),
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
                                  child: Icon(Icons.flashlight_on,
                                      color: AppColors.textSecondary, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Camera View
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _controller!,
                              onDetect: _onDetect,
                            ),

                            // Outer edge overlay transition glow
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: frameColor.withOpacity(0.6),
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),

                            // Central scanning frame brackets with sweeping laser line
                            Center(
                              child: SizedBox(
                                width: 220,
                                height: 220,
                                child: Stack(
                                  children: [
                                    // Sweeping Laser Beam
                                    AnimatedBuilder(
                                      animation: _laserAnimation,
                                      builder: (context, child) {
                                        return Positioned(
                                          top: 10 + _laserAnimation.value * 200,
                                          left: 10,
                                          right: 10,
                                          child: Container(
                                            height: 2.5,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  frameColor.withOpacity(0.1),
                                                  frameColor,
                                                  frameColor.withOpacity(0.1),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: frameColor.withOpacity(0.8),
                                                  blurRadius: 10,
                                                  spreadRadius: 1.5,
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // L-shaped Corner Brackets
                                    // Top-left
                                    Positioned(
                                      top: 0, left: 0,
                                      child: Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: frameColor, width: 4.5),
                                            left: BorderSide(color: frameColor, width: 4.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Top-right
                                    Positioned(
                                      top: 0, right: 0,
                                      child: Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: frameColor, width: 4.5),
                                            right: BorderSide(color: frameColor, width: 4.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Bottom-left
                                    Positioned(
                                      bottom: 0, left: 0,
                                      child: Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: frameColor, width: 4.5),
                                            left: BorderSide(color: frameColor, width: 4.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Bottom-right
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: frameColor, width: 4.5),
                                            right: BorderSide(color: frameColor, width: 4.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Results slide panel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Stack(
                      children: [
                        // We use a clean interactive builder to slide-in/slide-out the results
                        AnimatedSlide(
                          offset: _lastResult != null ? Offset.zero : const Offset(0, 0.4),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: _lastResult != null ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: _lastResult != null
                                ? GlassCard(
                                    borderColor: _success
                                        ? AppColors.success.withOpacity(0.5)
                                        : AppColors.error.withOpacity(0.5),
                                    borderRadius: 18,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (_success
                                                        ? AppColors.success
                                                        : AppColors.error)
                                                    .withOpacity(0.12),
                                                border: Border.all(
                                                  color: (_success
                                                          ? AppColors.success
                                                          : AppColors.error)
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Icon(
                                                _success
                                                    ? Icons.verified_user_rounded
                                                    : Icons.gpp_bad_rounded,
                                                color: _success
                                                    ? AppColors.success
                                                    : AppColors.error,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _success
                                                        ? 'ACCESS GRANTED'
                                                        : 'ACCESS DENIED',
                                                    style: TextStyle(
                                                      color: _success
                                                          ? AppColors.success
                                                          : AppColors.error,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 12,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    _lastResult!,
                                                    style: const TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_ticketData != null) ...[
                                          const SizedBox(height: 16),
                                          const Divider(color: Colors.white12),
                                          const SizedBox(height: 12),
                                          if (_ticketData!['user'] != null) ...[
                                            _buildDetailRow(
                                                Icons.person_rounded,
                                                'Pass Holder Name',
                                                _ticketData!['user']['name'] ?? 'N/A'),
                                            const SizedBox(height: 10),
                                            _buildDetailRow(
                                                Icons.phone_iphone_rounded,
                                                'Mobile Number',
                                                _ticketData!['user']['phone'] ?? 'N/A'),
                                            const SizedBox(height: 10),
                                          ],
                                          _buildDetailRow(
                                              Icons.confirmation_number_rounded,
                                              'Ticket Category / Zone',
                                              '${_ticketData!['zone'] ?? 'N/A'} ( ${_ticketData!['type'] ?? ''} )'
                                                  .toUpperCase()),
                                        ],
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),

                        // Placeholder when idle/waiting for QR
                        AnimatedOpacity(
                          opacity: _lastResult == null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: _lastResult == null
                              ? const GlassCard(
                                  borderRadius: 18,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code_scanner_rounded,
                                          color: AppColors.primary),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Align QR code inside scanner frame',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Glassmorphism Full Screen Processing Overlay blocking double-scans
            if (_isProcessing)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                      child: Center(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          borderRadius: 20,
                          borderColor: AppColors.primary.withOpacity(0.3),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 3.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'VERIFYING PASS DETAILS',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Securing active session...',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
