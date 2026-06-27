import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/booking_sheet.dart';
import '../widgets/gradient_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_snackbar.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: CustomScrollView(
          slivers: [
            // ── Expanded Banner Header ─────────────────────────────────
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              backgroundColor: AppColors.surface,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                title: Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background with emoji
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.gradientNavratri,
                      ),
                      child: const Center(
                        child: Text('🥢🥁💃', style: TextStyle(fontSize: 80)),
                      ),
                    ),
                    // Image overlay if available
                    if (event.fullImageUrl != null)
                      Image.network(
                        event.fullImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    // Bottom gradient fade to background
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withOpacity(0.4),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Active badge on banner
                    Positioned(
                      top: 100,
                      right: 16,
                      child: StatusBadge(
                        label: event.isActive ? 'Active' : 'Upcoming',
                        color: event.isActive
                            ? AppColors.success
                            : AppColors.warning,
                        animate: event.isActive,
                      ),
                    ),
                  ],
                ),
              ),
              // Glassmorphism back button
              leading: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 40,
                        height: 40,
                        color: Colors.white.withOpacity(0.15),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name & Day Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.2,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                event.dayOfWeek.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                event.date.day.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Info chips
                    Row(
                      children: [
                        Expanded(
                            child: _infoChip(Icons.calendar_today_rounded,
                                event.formattedDate)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _infoChip(
                                Icons.location_on_rounded, event.venue)),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // About section
                    _sectionTitle('About Event'),
                    const SizedBox(height: 12),
                    Text(
                      event.description.isNotEmpty
                          ? event.description
                          : 'Join us for an unforgettable night of Navratri celebration filled with energy, music, and traditional dance.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Zones section
                    _sectionTitle('Available Zones'),
                    const SizedBox(height: 16),
                    ...event.zones.map((zone) => _ZoneCard(zone: zone)),

                    // Space for sticky bottom bar
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Sticky Bottom Bar ────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Book Tickets Now',
                  gradient: AppColors.gradientPrimary,
                  icon: Icons.confirmation_num_rounded,
                  onPressed: () => _handleBooking(context),
                ),
              ),
              const SizedBox(width: 12),
              GlassCard(
                onTap: () => _shareEvent(context),
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                child: const Icon(Icons.share_outlined,
                    color: AppColors.primary, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBooking(BuildContext context) async {
    final success = await BookingSheet.show(context, event);
    if (success == true && context.mounted) {
      BookingSheet.showSuccessDialog(context);
    }
  }

  void _shareEvent(BuildContext context) {
    CustomSnackBar.show(
      context,
      message: 'Sharing ${event.name} details...',
      type: SnackBarType.info,
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zone Card with Seat Progress Bar ─────────────────────────────────────────
class _ZoneCard extends StatelessWidget {
  final ZoneModel zone;
  const _ZoneCard({required this.zone});

  Color _progressColor(double fill) {
    if (fill < 0.5) return AppColors.success;
    if (fill < 0.8) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final totalSeats = zone.capacity > 0 ? zone.capacity : 100;
    final available = zone.availableSeats;
    final taken = (totalSeats - available).clamp(0, totalSeats);
    final fillRatio = (taken / totalSeats).clamp(0.0, 1.0);
    final progressColor = _progressColor(fillRatio);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.stars_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '$available seats available',
                        style: TextStyle(color: progressColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      zone.formattedPriceFor('daily'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Text(
                      'Starting from',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Seat availability progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(fillRatio * 100).round()}% filled',
                      style: TextStyle(
                          color: progressColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$taken / $totalSeats',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fillRatio,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
