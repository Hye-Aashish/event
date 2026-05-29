import 'package:flutter/material.dart';

/// Premium gradient button with press-scale animation and shimmer loading state.
class GradientButton extends StatefulWidget {
  final String label;
  final Gradient? gradient;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.gradient,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = (widget.gradient is LinearGradient)
        ? (widget.gradient as LinearGradient).colors.first.withOpacity(0.35)
        : Colors.black.withOpacity(0.1);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: (widget.onPressed != null || widget.isLoading)
                ? widget.gradient
                : null,
            color: (widget.onPressed == null && !widget.isLoading)
                ? Colors.grey.withOpacity(0.2)
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                (widget.onPressed != null || widget.isLoading) && !_pressed
                    ? [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: _pressed ? 6 : 16,
                          offset: Offset(0, _pressed ? 2 : 8),
                        )
                      ]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shimmer sweep when loading
                if (widget.isLoading)
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (_, __) {
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment(
                              -1.5 + _shimmerController.value * 3, -0.5),
                          end: Alignment(
                              -0.5 + _shimmerController.value * 3, 0.5),
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.0),
                          ],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Container(color: Colors.white),
                      );
                    },
                  ),
                // Content
                widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
