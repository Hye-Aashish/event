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
  late AnimationController _qrController;
  late Animation<double> _qrScale;
  TicketModel? _cachedTicket;

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
    final activeTicket =
        ticketId != null ? provider.getTicketById(ticketId) : null;

    if (activeTicket != null) {
      _cachedTicket = activeTicket;
    }

    final ticket = activeTicket ?? _cachedTicket;

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
                          // ── Ticket Card ────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _TicketQRCard(
                                ticket: ticket, scaleAnim: _qrScale),
                          ),

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
          if (ticket.quantity > 1) ...[
            _infoRow(
                Icons.people_rounded, 'Quantity', '${ticket.quantity} Passes'),
            _divider(),
          ],
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

  void _showTransfer(BuildContext context, TicketModel ticket) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransferBottomSheet(ticket: ticket),
    );

    if (res != null && res['success'] == true && context.mounted) {
      CustomSnackBar.show(
        context,
        message: res['message'] ?? 'Ticket transferred successfully! 🎉',
        type: SnackBarType.success,
        duration: const Duration(seconds: 4),
      );
      Navigator.pop(context);
    }
  }
}

// ── 2-Step OTP Transfer Bottom Sheet ─────────────────────────────────────────
class _TransferBottomSheet extends StatefulWidget {
  final TicketModel ticket;
  const _TransferBottomSheet({required this.ticket});

  @override
  State<_TransferBottomSheet> createState() => _TransferBottomSheetState();
}

class _TransferBottomSheetState extends State<_TransferBottomSheet> {
  // Step: 'details' → 'otp'
  String _step = 'details';

  // Step 1 state
  final _phoneController = TextEditingController();
  int _transferQty = 1;
  bool _sending = false;

  // Step 2 state
  final _otpController = TextEditingController();
  bool _confirming = false;
  int _secondsLeft = 300; // 5 minutes
  bool _canResend = false;

  late int _maxQty;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _maxQty = widget.ticket.quantity;
    _phoneController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    });
    _otpController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _secondsLeft = 300;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, 300);
        if (_secondsLeft <= 240) _canResend = true; // allow resend after 60s
      });
      return _secondsLeft > 0 && mounted;
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() {
        _errorMessage = 'Enter a valid 10-digit phone number';
      });
      return;
    }
    setState(() {
      _sending = true;
      _errorMessage = null;
    });
    final provider = context.read<TicketProvider>();
    final res = await provider.initiateTransfer(
      ticketId: widget.ticket.id,
      quantity: _transferQty,
      toPhone: phone,
    );
    setState(() => _sending = false);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _step = 'otp';
        _errorMessage = null;
      });
      _startCountdown();
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to send OTP';
      });
    }
  }

  Future<void> _confirmTransfer() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Enter the 6-digit OTP';
      });
      return;
    }
    setState(() {
      _confirming = true;
      _errorMessage = null;
    });
    final provider = context.read<TicketProvider>();
    final res = await provider.confirmTransfer(
      ticketId: widget.ticket.id,
      quantity: _transferQty,
      toPhone: _phoneController.text.trim(),
      otp: otp,
    );
    setState(() => _confirming = false);
    if (!mounted) return;

    if (res['success'] == true) {
      final returnData = Map<String, dynamic>.from(res);
      returnData['message'] ??=
          '$_transferQty pass${_transferQty > 1 ? 'es' : ''} transferred! 🎉';
      Navigator.pop(context, returnData);
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Transfer failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.border),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: _step == 'details' ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transfer Passes',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                Text('Send to another user',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recipient phone
        const Text('Recipient Phone',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 14,
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '98765 43210',
              hintStyle: TextStyle(color: AppColors.textMuted),
              prefixIcon:
                  Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
              prefixText: '+91  ',
              prefixStyle: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Quantity stepper (only shown if >1 pass available)
        if (_maxQty > 1) ...[
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Passes to Transfer',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
              // Minus
              _stepBtn(
                icon: Icons.remove_rounded,
                enabled: _transferQty > 1,
                onTap: () => setState(
                    () => _transferQty = (_transferQty - 1).clamp(1, _maxQty)),
              ),
              // Count
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: SizedBox(
                  key: ValueKey(_transferQty),
                  width: 44,
                  child: Center(
                    child: Text('$_transferQty',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                  ),
                ),
              ),
              // Plus
              _stepBtn(
                icon: Icons.add_rounded,
                enabled: _transferQty < _maxQty,
                onTap: () => setState(
                    () => _transferQty = (_transferQty + 1).clamp(1, _maxQty)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_transferQty of $_maxQty active passes selected',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
        ],

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Warning card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'An OTP will be sent to your registered number to confirm this transfer. This cannot be undone.',
                  style: TextStyle(
                      color: Colors.orange, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Send OTP button
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: _sending ? 'Sending OTP...' : 'Send OTP',
            icon: Icons.sms_rounded,
            isLoading: _sending,
            onPressed: _sending ? null : _sendOtp,
            gradient: AppColors.gradientPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Back to step 1
        GestureDetector(
          onTap: () => setState(() {
            _step = 'details';
            _otpController.clear();
          }),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text('Back  •  ${_phoneController.text.trim()}',
                  style:
                      const TextStyle(color: AppColors.primary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Title
        const Text('Enter OTP',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(
          'Sent to your registered phone. Expires in $_timerLabel',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // OTP input — large centered field
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(
              hintText: '• • • • • •',
              hintStyle: TextStyle(
                  color: AppColors.textMuted, fontSize: 22, letterSpacing: 8),
              border: InputBorder.none,
              counterText: '',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive it?  ",
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            GestureDetector(
              onTap: _canResend
                  ? () {
                      _otpController.clear();
                      setState(() => _step = 'details');
                    }
                  : null,
              child: Text(
                _canResend ? 'Resend OTP' : 'Resend in $_timerLabel',
                style: TextStyle(
                    color: _canResend ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Confirm button
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: _confirming
                ? 'Transferring...'
                : 'Confirm Transfer ($_transferQty ${_transferQty == 1 ? 'pass' : 'passes'})',
            icon: Icons.check_circle_rounded,
            isLoading: _confirming,
            onPressed: _confirming ? null : _confirmTransfer,
            gradient: AppColors.gradientNavratri,
          ),
        ),
      ],
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.gradientPrimary : null,
          color: enabled ? null : AppColors.border,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : AppColors.textMuted, size: 16),
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
                  color: ticket.isActive
                      ? AppColors.background
                      : AppColors.textMuted,
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
