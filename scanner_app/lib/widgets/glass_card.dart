import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double blurSigma;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.blurSigma = 5, // #3 Reduced from 10 to 5 for major GPU optimization
    this.gradient,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasOnTap = widget.onTap != null;
    return GestureDetector(
      onTapDown: hasOnTap ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: hasOnTap ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: hasOnTap ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius!),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                gradient: widget.gradient ??
                    LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ],
                    ),
                borderRadius: BorderRadius.circular(widget.borderRadius!),
                border: Border.all(
                  color: widget.borderColor ?? Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient,
    this.isLoading = false,
    this.icon,
    this.height = 56,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

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
    final shadowColor = widget.onPressed != null
        ? (widget.gradient is LinearGradient
            ? (widget.gradient as LinearGradient).colors.first.withOpacity(0.35)
            : AppColors.primary.withOpacity(0.35))
        : Colors.transparent;

    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading
          ? () => setState(() => _isPressed = false)
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: (widget.onPressed == null && !widget.isLoading)
                ? const LinearGradient(
                    colors: [Color(0xFF3A3A4A), Color(0xFF2A2A38)],
                  )
                : (widget.gradient ?? AppColors.gradientPrimary),
            borderRadius: BorderRadius.circular(14),
            boxShadow:
                (widget.onPressed != null || widget.isLoading) && !_isPressed
                    ? [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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

class GlowDot extends StatelessWidget {
  final Color color;
  final double size;
  final double blurRadius;

  const GlowDot({
    super.key,
    required this.color,
    this.size = 200,
    this.blurRadius = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: blurRadius,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatefulWidget {
  final String label;
  final Color color;
  final bool animate;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.animate = true,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color
                    .withOpacity(widget.animate ? _pulse.value : 1.0),
                shape: BoxShape.circle,
                boxShadow: widget.animate
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(_pulse.value * 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
