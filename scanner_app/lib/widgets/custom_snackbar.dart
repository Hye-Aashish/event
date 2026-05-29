import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear any active snackbars first
    scaffoldMessenger.hideCurrentSnackBar();

    IconData icon;
    Color color;
    Gradient gradient;

    switch (type) {
      case SnackBarType.success:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        gradient = const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF00B248)],
        );
        break;
      case SnackBarType.error:
        icon = Icons.error_rounded;
        color = AppColors.error;
        gradient = const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFC62828)],
        );
        break;
      case SnackBarType.warning:
        icon = Icons.warning_rounded;
        color = AppColors.warning;
        gradient = const LinearGradient(
          colors: [Color(0xFFFFAB40), Color(0xFFFF6D00)],
        );
        break;
      case SnackBarType.info:
        icon = Icons.info_rounded;
        color = AppColors.primary;
        gradient = AppColors.gradientPrimary;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left indicator bar/icon with gradient
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? _defaultTitleFor(type),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      scaffoldMessenger.hideCurrentSnackBar();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _defaultTitleFor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return 'Success';
      case SnackBarType.error:
        return 'Error';
      case SnackBarType.warning:
        return 'Warning';
      case SnackBarType.info:
        return 'Notice';
    }
  }
}
