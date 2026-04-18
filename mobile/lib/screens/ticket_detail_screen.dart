import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/ticket_model.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _transferPhoneController = TextEditingController();
  bool _showTransferDialog = false;
  bool _isTransferring = false;

  @override
  void dispose() {
    _transferPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketId = ModalRoute.of(context)?.settings.arguments as String?;
    final provider = context.watch<TicketProvider>();
    final ticket = ticketId != null
        ? provider.getTicketById(ticketId)
        : null;

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket')),
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
            Positioned(top: -60, right: -60, child: _glow(AppColors.primary, 240)),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text('Ticket Details'),
                    actions: [
                      if (ticket.isActive)
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () => _showTransfer(context, ticket),
                        ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Ticket Card with QR
                          _ticketCard(ticket),

                          const SizedBox(height: 24),

                          // Info Grid
                          _infoGrid(ticket),

                          const SizedBox(height: 24),

                          // Transfer button
                          if (ticket.isActive && !ticket.isTransferred)
                            GradientButton(
                              label: 'Transfer Ticket',
                              icon: Icons.swap_horiz,
                              gradient: const LinearGradient(
                                  colors: [AppColors.secondary, AppColors.primary]),
                              onPressed: () => _showTransfer(context, ticket),
                            ),

                          const SizedBox(height: 40),
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

  Widget _ticketCard(TicketModel ticket) {
    return Container(
      decoration: BoxDecoration(
        gradient: ticket.isActive
            ? AppColors.gradientPrimary
            : const LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceLight]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (ticket.isActive)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NAVRATRI 2024',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      ticket.ticketType == 'season'
                          ? 'SEASON PASS ⭐'
                          : 'SINGLE DAY',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
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

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ticket.qrCode.isNotEmpty
                  ? QrImageView(
                      data: ticket.qrCode,
                      version: QrVersions.auto,
                      size: 200,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black),
                    )
                  : const Icon(Icons.qr_code_2, size: 200, color: Colors.black87),
            ),

            const SizedBox(height: 16),
            const Text('Scan at entry gate',
                style: TextStyle(color: Colors.white70, fontSize: 13)),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ticketStat('Zone', ticket.zoneName ?? 'General'),
                _ticketStat('Price', ticket.formattedPrice),
                _ticketStat('Date', ticket.formattedDate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoGrid(TicketModel ticket) {
    return GlassCard(
      borderRadius: 18,
      child: Column(
        children: [
          _infoRow(Icons.event, 'Event', ticket.eventName ?? 'Navratri Event'),
          const Divider(color: AppColors.border),
          _infoRow(Icons.location_on, 'Venue', ticket.eventVenue ?? 'Navratri Ground'),
          const Divider(color: AppColors.border),
          _infoRow(Icons.layers, 'Zone Type', ticket.zoneType ?? 'General'),
          const Divider(color: AppColors.border),
          _infoRow(Icons.confirmation_number, 'Ticket ID',
              ticket.id.substring(0, 12) + '...'),
          if (ticket.isScanned) ...[
            const Divider(color: AppColors.border),
            _infoRow(Icons.check_circle, 'Scanned At',
                ticket.scannedAt?.toString() ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
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

  Widget _ticketStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  void _showTransfer(BuildContext context, TicketModel ticket) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Transfer Ticket',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the phone number to transfer to:',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: _transferPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '+91 98765 43210',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
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
          ElevatedButton(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['success'] == true
                            ? '✅ Ticket transferred!'
                            : (res['message'] ?? 'Transfer failed')),
                        backgroundColor: res['success'] == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(0.1)));
}
