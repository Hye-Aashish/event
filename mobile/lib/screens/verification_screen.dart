import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_snackbar.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with TickerProviderStateMixin {
  XFile? _selfieFile;
  XFile? _idFile;
  bool _isSubmitting = false;

  final _imagePicker = ImagePicker();
  late AnimationController _entranceController;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOut));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    final img = await _imagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 70);
    if (img == null) return;
    if (!mounted) return;

    if (kDebugMode) print('📸 Selfie captured: ${img.path}');

    // Show analyzing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Analyzing Selfie...',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Detecting face offline',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final inputImage = InputImage.fromFilePath(img.path);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);

      // Close analyzing dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      if (faces.isEmpty) {
        CustomSnackBar.show(
          context,
          message:
              'No face detected in the picture. Please capture a clear selfie of your face.',
          type: SnackBarType.error,
        );
        return;
      }

      if (faces.length > 1) {
        CustomSnackBar.show(
          context,
          message:
              'Multiple faces detected. Please make sure only you are in the frame.',
          type: SnackBarType.error,
        );
        return;
      }

      // Success - 1 face detected
      setState(() => _selfieFile = img);
      CustomSnackBar.show(
        context,
        message: 'Selfie verified successfully!',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close analyzing dialog
        CustomSnackBar.show(
          context,
          message: 'Error analyzing face: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      faceDetector.close();
    }
  }

  Future<void> _uploadId() async {
    final img = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      if (kDebugMode) print('🆔 ID: ${img.path}');
      setState(() => _idFile = img);
    }
  }

  Future<void> _submit() async {
    if (_selfieFile == null || _idFile == null) return;
    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final res = await auth.submitVerification(_selfieFile!.path, _idFile!.path);
    setState(() => _isSubmitting = false);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSuccessDialog();
    } else {
      CustomSnackBar.show(
        context,
        message: res['message'] ?? 'Submission failed',
        type: SnackBarType.error,
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.gradientSuccess,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.success.withOpacity(0.4), blurRadius: 20)
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Documents Submitted!',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Our team will review your documents within 24 hours.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Got it',
              gradient: AppColors.gradientSuccess,
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final status = user?.verificationStatus ?? 'none';
    final reason = user?.verificationReason ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            // Positioned(
            //   top: -60,
            //   right: -60,
            //   child: Container(
            //     width: 220,
            //     height: 220,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       color: AppColors.gold.withOpacity(0.08),
            //     ),
            //   ),
            // ),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: RefreshIndicator(
                    onRefresh: () => auth.refreshProfile(),
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 100,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back row
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.white.withOpacity(0.1),
                                        child: const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            color: AppColors.textPrimary,
                                            size: 18),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('ID Verification',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            if (status == 'pending')
                              _buildPendingState()
                            else if (status == 'approved')
                              _buildApprovedState()
                            else
                              _buildUploadState(status, reason),
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

  Widget _buildUploadState(String status, String reason) {
    final isRejected = status == 'rejected';
    final canSubmit = _selfieFile != null && _idFile != null;
    final completedSteps =
        (_selfieFile != null ? 1 : 0) + (_idFile != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Banner
        if (isRejected)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Verification Rejected',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        reason.isNotEmpty
                            ? reason
                            : 'Please re-upload clear, readable documents.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          GlassCard(
            borderRadius: 16,
            borderColor: AppColors.gold.withOpacity(0.4),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.gold.withOpacity(0.4),
                          blurRadius: 12)
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Identity verification is required for Season Passes. Your data is encrypted & secure.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 28),

        // Upload Step 1
        _UploadStepCard(
          step: '1',
          title: 'Take a Selfie',
          subtitle: 'Ensure your face is clearly visible & well lit',
          icon: Icons.camera_alt_rounded,
          isCompleted: _selfieFile != null,
          imagePath: _selfieFile?.path,
          onTap: _takeSelfie,
          gradient: AppColors.gradientPrimary,
        ),

        const SizedBox(height: 14),

        // Upload Step 2
        _UploadStepCard(
          step: '2',
          title: 'Upload ID Proof',
          subtitle: 'Aadhaar, PAN Card or Driving License',
          icon: Icons.badge_rounded,
          isCompleted: _idFile != null,
          imagePath: _idFile?.path,
          onTap: _uploadId,
          gradient: AppColors.gradientPrimary,
        ),

        const SizedBox(height: 28),

        // Progress and submit
        if (_selfieFile != null || _idFile != null) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$completedSteps of 2 steps completed',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        Text('${completedSteps * 50}%',
                            style: TextStyle(
                                color: completedSteps == 2
                                    ? AppColors.success
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completedSteps / 2,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completedSteps == 2
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: isRejected
                ? 'Re-submit for Verification'
                : 'Submit for Verification',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: canSubmit ? _submit : null,
            gradient: canSubmit ? AppColors.gradientNavratri : null,
          ),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [AppColors.warning, Color(0xFFFFCC80)]),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.warning.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5)
                  ],
                ),
                child: const Center(
                    child: Text('⏳', style: TextStyle(fontSize: 48))),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Review in Progress',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text(
              'Your documents are being reviewed by our team.\nThis usually takes less than 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            GlassCard(
              onTap: () => Navigator.pop(context),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              borderRadius: 24,
              child: const Text('Go Back',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientSuccess,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.success.withOpacity(0.45),
                        blurRadius: 30,
                        spreadRadius: 5)
                  ],
                ),
                child: const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 56),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (b) => AppColors.gradientSuccess.createShader(b),
              child: const Text('Verified! 🎉',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your identity has been verified.\nYou can now purchase season passes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Done',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context),
              gradient: AppColors.gradientSuccess,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upload Step Card ──────────────────────────────────────────────────────
class _UploadStepCard extends StatefulWidget {
  final String step;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final String? imagePath;
  final VoidCallback onTap;
  final LinearGradient gradient;

  const _UploadStepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.onTap,
    required this.gradient,
    this.imagePath,
  });

  @override
  State<_UploadStepCard> createState() => _UploadStepCardState();
}

class _UploadStepCardState extends State<_UploadStepCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.isCompleted
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.border,
                width: widget.isCompleted ? 1.5 : 1.0),
            color: AppColors.surface,
            boxShadow: widget.isCompleted
                ? [
                    BoxShadow(
                        color: AppColors.success.withOpacity(0.15),
                        blurRadius: 16)
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail or icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: widget.imagePath != null
                      ? Image.file(File(widget.imagePath!),
                          width: 56, height: 56, fit: BoxFit.cover)
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: widget.isCompleted
                                ? AppColors.gradientSuccess
                                : widget.gradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: widget.isCompleted
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 28)
                                : Icon(widget.icon,
                                    color: Colors.white, size: 24),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: widget.gradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Step ${widget.step}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (widget.isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Done',
                                  style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(widget.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      Text(widget.subtitle,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(
                  widget.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: widget.isCompleted
                      ? AppColors.success
                      : AppColors.textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
