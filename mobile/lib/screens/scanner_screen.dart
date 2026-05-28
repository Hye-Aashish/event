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
    with TickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  String? _lastResult;
  bool _success = false;
  bool _torchOn = false;
  Map<String, dynamic>? _ticketData;

  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _lastResult != null) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final qrData = barcode!.rawValue!;
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
            ? res['message'] ?? 'Ticket verified successfully!'
            : res['message'] ?? 'Invalid ticket';
        _ticketData = res['ticket'];
        _isProcessing = false;
      });
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
        _ticketData = null;
        _isProcessing = false;
      });
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
    final borderColor = _lastResult != null
        ? (_success ? AppColors.success : AppColors.error)
        : AppColors.primary;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────────────────
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
                            width: 40,
                            height: 40,
                            color: Colors.white.withOpacity(0.12),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.textPrimary, size: 18),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text('QR Scanner',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3),
                          textAlign: TextAlign.center),
                    ),
                    GestureDetector(
                      onTap: () {
                        _controller?.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _torchOn ? AppColors.gradientGold : null,
                          color: _torchOn ? null : AppColors.surface,
                          border: Border.all(
                              color:
                                  _torchOn ? AppColors.gold : AppColors.border),
                          boxShadow: _torchOn
                              ? [
                                  BoxShadow(
                                      color: AppColors.gold.withOpacity(0.4),
                                      blurRadius: 12)
                                ]
                              : [],
                        ),
                        child: Icon(
                            _torchOn
                                ? Icons.flashlight_on_rounded
                                : Icons.flashlight_off_rounded,
                            color:
                                _torchOn ? Colors.white : AppColors.textMuted,
                            size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Camera frame label
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Align QR code within the frame',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center),
              ),

              const SizedBox(height: 16),

              // ── Camera View ──────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller!,
                          onDetect: _onDetect,
                        ),

                        // Dark corner vignette
                        Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.0,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),

                        // Animated border
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: borderColor
                                    .withOpacity(_pulseAnim.value * 0.9),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),

                        // Scan frame with corner decorations
                        Center(
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              children: [
                                // Scanning line
                                if (!_isProcessing && _lastResult == null)
                                  AnimatedBuilder(
                                    animation: _scanLineAnim,
                                    builder: (_, __) => Positioned(
                                      top: _scanLineAnim.value * 200,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              AppColors.primary
                                                  .withOpacity(0.8),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.5),
                                                blurRadius: 8)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                // Corner decorations
                                ..._buildCorners(),
                              ],
                            ),
                          ),
                        ),

                        // Processing overlay
                        if (_isProcessing)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                          color: AppColors.primary),
                                      SizedBox(height: 16),
                                      Text('Verifying...',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Success / Error overlay
                        if (_lastResult != null && !_isProcessing)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                color: (_success
                                        ? AppColors.success
                                        : AppColors.error)
                                    .withOpacity(0.2),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _success
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        color: _success
                                            ? AppColors.success
                                            : AppColors.error,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _success ? '✅ Verified!' : '❌ Failed',
                                        style: TextStyle(
                                            color: _success
                                                ? AppColors.success
                                                : AppColors.error,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
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
                ),
              ),

              const SizedBox(height: 20),

              // ── Result / Hint Card ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _lastResult != null
                      ? GlassCard(
                          key: ValueKey(_lastResult),
                          borderColor:
                              _success ? AppColors.success : AppColors.error,
                          borderRadius: 18,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (_success
                                              ? AppColors.success
                                              : AppColors.error)
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _success
                                          ? Icons.check_circle_rounded
                                          : Icons.error_rounded,
                                      color: _success
                                          ? AppColors.success
                                          : AppColors.error,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _success
                                              ? 'TICKET VERIFIED'
                                              : 'VERIFICATION FAILED',
                                          style: TextStyle(
                                            color: _success
                                                ? AppColors.success
                                                : AppColors.error,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _lastResult!,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
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
                      : GlassCard(
                          key: const ValueKey('idle'),
                          borderRadius: 18,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text('Point camera at QR code',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 3.0;
    final color = AppColors.primary;

    return [
      // Top-left
      Positioned(
          top: 0,
          left: 0,
          child: _corner(color, size, thickness, topLeft: true)),
      // Top-right
      Positioned(
          top: 0,
          right: 0,
          child: _corner(color, size, thickness, topRight: true)),
      // Bottom-left
      Positioned(
          bottom: 0,
          left: 0,
          child: _corner(color, size, thickness, bottomLeft: true)),
      // Bottom-right
      Positioned(
          bottom: 0,
          right: 0,
          child: _corner(color, size, thickness, bottomRight: true)),
    ];
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
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500),
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

  Widget _corner(Color color, double size, double thickness,
      {bool topLeft = false,
      bool topRight = false,
      bool bottomLeft = false,
      bool bottomRight = false}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: thickness,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({
    required this.color,
    required this.thickness,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (topLeft) {
      canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
      canvas.drawLine(
          Offset(0, size.height), Offset(size.width, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(
          Offset(0, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
