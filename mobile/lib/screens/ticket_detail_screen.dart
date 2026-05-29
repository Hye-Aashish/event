// ignore_for_file: unused_field

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/gradient_button.dart';
import '../models/ticket_model.dart';
import '../widgets/custom_snackbar.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  final _transferPhoneController = TextEditingController();
  bool _isTransferring = false;
  late AnimationController _qrController;
  late Animation<double> _qrScale;

  @override
  void initState() {
    super.initState();
    _qrController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _qrScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _qrController, curve: Curves.elasticOut));
    Future.delayed(
        const Duration(milliseconds: 300), () => _qrController.forward());
    // #3 Light status bar for white QR screen (no layout side-effects)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _transferPhoneController.dispose();
    _qrController.dispose();
    // Restore dark status bar icons for the rest of the app
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketId = ModalRoute.of(context)?.settings.arguments as String?;
    final provider = context.watch<TicketProvider>();
    final ticket = ticketId != null ? provider.getTicketById(ticketId) : null;

    if (ticket == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Ticket'), backgroundColor: Colors.transparent),
        body: const Center(
          child: Text('Ticket not found',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ─────────────────────────────────────────
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    leading: Padding(
                      padding:
                          const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.white.withOpacity(0.12),
                              child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.textPrimary,
                                  size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: const Text('Ticket Details',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3)),
                    actions: [
                      // #14 Share ticket
                      if (ticket.isActive)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Semantics(
                            label: 'Share ticket',
                            child: GestureDetector(
                              onTap: () {
                                final msg = '🎟️ My Navratri 2026 Ticket\n'
                                    'Event: ${ticket.eventName ?? 'Navratri Event'}\n'
                                    'Zone: ${ticket.zoneName ?? 'General'}\n'
                                    'Date: ${ticket.formattedDate}\n'
                                    'Ticket ID: ${ticket.id}';
                                Share.share(msg);
                              },
                              child: const GlassCard(
                                padding: EdgeInsets.all(8),
                                borderRadius: 12,
                                child: Icon(Icons.share_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                            ),
                          ),
                        ),
                      if (ticket.isActive)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _showTransfer(context, ticket),
                            child: const GlassCard(
                              padding: EdgeInsets.all(8),
                              borderRadius: 12,
                              child: Icon(Icons.swap_horiz_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        children: [
                          // ── Ticket Card ────────────────────────────
                          _TicketQRCard(ticket: ticket, scaleAnim: _qrScale),

                          const SizedBox(height: 20),

                          // ── Info Grid ──────────────────────────────
                          _infoGrid(ticket),

                          const SizedBox(height: 20),

                          // ── Transfer button ─────────────────────────
                          if (ticket.isActive && !ticket.isTransferred)
                            GradientButton(
                              label: 'Transfer Ticket',
                              icon: Icons.swap_horiz_rounded,
                              gradient: AppColors.gradientPrimary,
                              onPressed: () => _showTransfer(context, ticket),
                            ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoGrid(TicketModel ticket) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          _infoRow(Icons.event_rounded, 'Event',
              ticket.eventName ?? 'Navratri Event'),
          _divider(),
          _infoRow(Icons.location_on_rounded, 'Venue',
              ticket.eventVenue ?? 'Navratri Ground'),
          _divider(),
          _infoRow(
              Icons.layers_rounded, 'Zone Type', ticket.zoneType ?? 'General'),
          _divider(),
          _infoRow(Icons.confirmation_number_rounded, 'Ticket ID',
              '${ticket.id.substring(0, 12)}...'),
          if (ticket.isScanned) ...[
            _divider(),
            _infoRow(Icons.check_circle_rounded, 'Scanned At',
                ticket.scannedAt?.toString() ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.border.withOpacity(0.5));

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  void _showTransfer(BuildContext context, TicketModel ticket) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Transfer Ticket',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the phone number to transfer to:',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 12,
              child: TextField(
                controller: _transferPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: '+91 98765 43210',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.phone_rounded,
                      color: AppColors.primary, size: 20),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: _isTransferring
                  ? null
                  : () async {
                      final phone = _transferPhoneController.text.trim();
                      if (phone.isEmpty) return;
                      setState(() => _isTransferring = true);
                      final res = await context
                          .read<TicketProvider>()
                          .transferTicket(ticket.id, phone);
                      setState(() => _isTransferring = false);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      CustomSnackBar.show(
                        context,
                        message: res['success'] == true
                            ? 'Ticket transferred successfully!'
                            : (res['message'] ?? 'Transfer failed'),
                        type: res['success'] == true
                            ? SnackBarType.success
                            : SnackBarType.error,
                      );
                    },
              child: const Text('Transfer',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket QR Card ────────────────────────────────────────────────────────
class _TicketQRCard extends StatelessWidget {
  final TicketModel ticket;
  final Animation<double> scaleAnim;

  const _TicketQRCard({required this.ticket, required this.scaleAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ticket.isActive
            ? AppColors.gradientNavratri
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ticket.isActive
                ? AppColors.primary.withOpacity(0.4)
                : Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NAVRATRI 2026',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      ticket.isSeasonPass ? 'SEASON PASS ⭐' : 'SINGLE DAY',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
                StatusBadge(
                  label: ticket.statusDisplay,
                  color: ticket.isActive ? Colors.white : AppColors.textMuted,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // QR with elastic entrance
            ScaleTransition(
              scale: scaleAnim,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: ticket.qrCode.isNotEmpty
                    ? QrImageView(
                        data: ticket.qrCode,
                        version: QrVersions.auto,
                        size: 190,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black),
                      )
                    : const Icon(Icons.qr_code_2,
                        size: 190, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 16),

            // Scan hint
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    size: 14, color: Colors.white70),
                SizedBox(width: 6),
                Text('Show this at the entry gate',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),

            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Zone', ticket.zoneName ?? 'General'),
                _vDivider(),
                _stat('Price', ticket.formattedPrice),
                _vDivider(),
                _stat('Date', ticket.formattedDate),
              ],
            ),

            // Copy ID button
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: ticket.id));
                CustomSnackBar.show(
                  context,
                  message: 'Ticket ID copied to clipboard!',
                  type: SnackBarType.success,
                  duration: const Duration(seconds: 1),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      '#${ticket.id.substring(0, 10)}...',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: -0.2)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2));
}
