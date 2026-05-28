import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A generic shimmer block for building skeletons.
class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF333333),
      highlightColor: const Color(0xFF4D4D4D),
      child: Container(
        margin: margin,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A wrapper that adds a glass card structure around shimmer content.
class SkeletonCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const SkeletonCard({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    // Returning a simple Container rather than GlassCard so the shimmer blocks
    // float directly on the background, matching the clean UI from the screenshot.
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

/// Skeleton for a stat card (e.g. on Home Screen)
class StatSkeletonCard extends StatelessWidget {
  const StatSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      padding: EdgeInsets.all(14),
      borderRadius: 14,
      child: Column(
        children: [
          ShimmerBlock(width: 24, height: 24, borderRadius: 12),
          SizedBox(height: 8),
          ShimmerBlock(width: 40, height: 20),
          SizedBox(height: 6),
          ShimmerBlock(width: 60, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton for horizontal events on the home screen
class HorizontalEventSkeleton extends StatelessWidget {
  const HorizontalEventSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: const SkeletonCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(
              width: double.infinity,
              height: 100,
              borderRadius: 0,
            ),
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 140, height: 18),
                  SizedBox(height: 10),
                  ShimmerBlock(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  ShimmerBlock(width: 180, height: 12),
                  SizedBox(height: 10),
                  ShimmerBlock(width: 120, height: 12),
                  SizedBox(height: 8),
                  ShimmerBlock(width: 80, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for event list on Events Screen
class EventListSkeleton extends StatelessWidget {
  const EventListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: SkeletonCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(
              width: double.infinity,
              height: 130,
              borderRadius: 0,
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 160, height: 20),
                  SizedBox(height: 12),
                  ShimmerBlock(width: 200, height: 14),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      ShimmerBlock(width: 70, height: 28),
                      SizedBox(width: 8),
                      ShimmerBlock(width: 70, height: 28),
                    ],
                  ),
                  SizedBox(height: 18),
                  ShimmerBlock(
                      width: double.infinity, height: 45, borderRadius: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for ticket list on Tickets Screen and Home Screen
class TicketSkeletonRow extends StatelessWidget {
  const TicketSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: SkeletonCard(
        padding: EdgeInsets.all(14),
        borderRadius: 14,
        child: Row(
          children: [
            ShimmerBlock(width: 42, height: 42, borderRadius: 10),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 120, height: 16),
                  SizedBox(height: 8),
                  ShimmerBlock(width: 80, height: 12),
                ],
              ),
            ),
            ShimmerBlock(width: 60, height: 24, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for full ticket cards on Tickets Screen
class TicketCardSkeleton extends StatelessWidget {
  const TicketCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: SkeletonCard(
        padding: EdgeInsets.all(18),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBlock(width: 42, height: 42, borderRadius: 12),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBlock(width: 140, height: 16),
                      SizedBox(height: 8),
                      ShimmerBlock(width: 80, height: 12),
                    ],
                  ),
                ),
                ShimmerBlock(width: 60, height: 24, borderRadius: 20),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                ShimmerBlock(width: 60, height: 14),
                SizedBox(width: 16),
                ShimmerBlock(width: 80, height: 14),
                Spacer(),
                ShimmerBlock(width: 50, height: 16),
              ],
            ),
            SizedBox(height: 24),
            Center(
              child: ShimmerBlock(width: 100, height: 100, borderRadius: 10),
            ),
            SizedBox(height: 8),
            Center(
              child: ShimmerBlock(width: 120, height: 12),
            ),
          ],
        ),
      ),
    );
  }
}

