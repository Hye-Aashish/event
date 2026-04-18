import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  String? _lastResult;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final qrData = barcode!.rawValue!;
    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      final res = await ApiService.scanQr(qrData);
      if (!mounted) return;
      setState(() {
        _success = res['success'] == true;
        _lastResult = res['success'] == true
            ? '✅ ${res['message'] ?? 'Ticket verified successfully!'}'
            : '❌ ${res['message'] ?? 'Invalid ticket'}';
        _isProcessing = false;
      });

      // Auto-reset after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _lastResult = null);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _lastResult = '❌ Network error. Try again.';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.textPrimary),
                    ),
                    const Expanded(
                      child: Text('QR Scanner',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center),
                    ),
                    IconButton(
                      onPressed: () => _controller?.toggleTorch(),
                      icon: const Icon(Icons.flashlight_on,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

                        // Overlay
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _lastResult != null
                                  ? (_success
                                      ? AppColors.success
                                      : AppColors.error)
                                  : AppColors.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),

                        // Scan frame
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        // Processing indicator
                        if (_isProcessing)
                          Container(
                            color: Colors.black54,
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
                                          fontWeight: FontWeight.bold)),
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

              // Result box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _lastResult != null
                      ? GlassCard(
                          key: ValueKey(_lastResult),
                          borderColor: _success
                              ? AppColors.success
                              : AppColors.error,
                          borderRadius: 16,
                          child: Row(
                            children: [
                              Icon(
                                _success ? Icons.check_circle : Icons.error,
                                color: _success
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _lastResult!,
                                  style: TextStyle(
                                    color: _success
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GlassCard(
                          key: const ValueKey('idle'),
                          borderRadius: 16,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('Point camera at QR code',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
