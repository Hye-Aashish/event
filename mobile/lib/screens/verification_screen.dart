import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _selfieCaptured = false;
  bool _idUploaded = false;
  bool _isSubmitting = false;
  String? _selfieBytes;
  String? _idBytes;

  final _imagePicker = ImagePicker();

  Future<void> _takeSelfie() async {
    final img = await _imagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 70);
    if (img != null) {
      setState(() => _selfieCaptured = true);
    }
  }

  Future<void> _uploadId() async {
    final img = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() => _idUploaded = true);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top, color: AppColors.warning),
            SizedBox(width: 10),
            Text('Submitted!',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
            'Your verification documents have been submitted. We will review them within 24 hours.',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selfieCaptured && _idUploaded;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(0.08)),
                )),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.textPrimary),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                        const Text('ID Verification',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info banner
                    GlassCard(
                      borderRadius: 14,
                      borderColor: AppColors.gold.withOpacity(0.4),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.gold, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Identity verification is required for Season Passes. Your data is encrypted & secure.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Steps
                    _buildStepCard(
                      step: '1',
                      title: 'Take a Selfie',
                      subtitle: 'Ensure your face is clearly visible',
                      icon: Icons.camera_alt,
                      isCompleted: _selfieCaptured,
                      onTap: _takeSelfie,
                    ),

                    const SizedBox(height: 14),

                    _buildStepCard(
                      step: '2',
                      title: 'Upload ID Proof',
                      subtitle: 'Aadhaar Card, PAN Card or Driving License',
                      icon: Icons.badge,
                      isCompleted: _idUploaded,
                      onTap: _uploadId,
                    ),

                    const Spacer(),

                    // Progress indicator
                    if (_selfieCaptured || _idUploaded) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:
                                    (_selfieCaptured ? 0.5 : 0) +
                                        (_idUploaded ? 0.5 : 0),
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(_selfieCaptured ? 1 : 0) + (_idUploaded ? 1 : 0)}/2',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    GradientButton(
                      label: 'Submit for Verification',
                      isLoading: _isSubmitting,
                      onPressed: canSubmit ? _submit : null,
                      gradient: canSubmit ? AppColors.gradientNavratri : null,
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 16,
        borderColor: isCompleted
            ? AppColors.primary.withOpacity(0.5)
            : null,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Step indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCompleted ? AppColors.gradientPrimary : null,
                color: isCompleted ? null : AppColors.surfaceLight,
                border: isCompleted
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check : icon,
                  color: isCompleted ? Colors.white : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20)
            else
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
