// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/event_model.dart';
import '../providers/ticket_provider.dart';
import '../screens/home_screen.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';
import 'custom_snackbar.dart';

class BookingSheet extends StatefulWidget {
  final EventModel event;
  const BookingSheet({super.key, required this.event});

  /// Shows the booking bottom sheet. Returns true on successful booking.
  static Future<bool?> show(BuildContext context, EventModel event) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BookingSheet(event: event),
    );
  }

  /// Shows a premium success dialog after booking.
  static void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: Colors.white.withOpacity(0.15), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated success icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientSuccess,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.success.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 4),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎉', style: TextStyle(fontSize: 42)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.gradientSuccess.createShader(b),
                    child: const Text(
                      'Ticket Booked!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Your ticket has been booked successfully.\nView it in your Tickets tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13, height: 1.5),
                  ),

                  const SizedBox(height: 28),

                  GradientButton(
                    label: 'View My Tickets',
                    icon: Icons.confirmation_num_rounded,
                    gradient: AppColors.gradientSuccess,
                    onPressed: () {
                      // 1. Switch bottom nav to index 2 (Tickets tab) via public interface
                      final homeState = homeScreenKey.currentState;
                      if (homeState is HomeScreenState) {
                        (homeState as HomeScreenState).setIndex(2);
                      }

                      // 2. Dismiss success dialog
                      Navigator.pop(dialogContext);

                      // 3. Pop detail screen if we are pushed on top of HomeScreen
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet>
    with SingleTickerProviderStateMixin {
  late Razorpay _razorpay;
  String? _selectedDate;
  ZoneModel? _selectedZone;
  String _ticketType = 'daily';
  bool _isLoading = false;
  final int _quantity = 1;

  late AnimationController _sheetController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Slide-up entrance animation
    _sheetController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _sheetController, curve: Curves.easeOut));
    _sheetController.forward();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    if (widget.event.eventDates.isNotEmpty) {
      _selectedDate = widget.event.eventDates[0];
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _sheetController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Premium verifying overlay
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
                    Text('Verifying Payment...',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Please wait',
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

    final res = await context.read<TicketProvider>().verifyPayment({
      'razorpay_order_id': response.orderId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
      'eventId': widget.event.id,
      'zoneId': _selectedZone!.id,
      'type': _ticketType == 'daily' ? 'regular' : _ticketType,
      'category': _selectedZone!.type,
      'quantity': _quantity,
      'date': _ticketType == 'season' ? 'all' : _selectedDate,
    });

    if (mounted) Navigator.of(context).pop(); // Close verifying dialog

    if (res['success'] == true) {
      if (mounted) Navigator.of(context).pop(true); // Signal success
    } else {
      _showError(res['message'] ?? 'Verification failed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    _showError('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet: ${response.walletName}');
  }

  Future<void> _purchase() async {
    if (_selectedZone == null) return;
    if (_ticketType == 'daily' && _selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final res = await context.read<TicketProvider>().createRazorpayOrder(
            eventId: widget.event.id,
            zoneId: _selectedZone!.id,
            type: _ticketType == 'daily' ? 'regular' : _ticketType,
            category: _selectedZone!.type,
            quantity: _quantity,
            date: _ticketType == 'season' ? 'all' : _selectedDate,
          );

      if (res['success'] == true) {
        final order = res['order'];
        final razorpayKey = res['razorpayKey'];
        _razorpay.open({
          'key': razorpayKey,
          'amount': order['amount'],
          'name': 'Navratri 2024',
          'order_id': order['id'],
          'description': '${widget.event.name} — ${_selectedZone!.name}',
          'timeout': 300,
          'prefill': {'contact': '', 'email': ''},
        });
      } else {
        setState(() => _isLoading = false);
        _showError(res['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    CustomSnackBar.show(
      context,
      message: msg,
      type: SnackBarType.error,
    );
  }

  double get _basePrice {
    if (_selectedZone == null) return 0.0;
    final rawPrice = _selectedZone!.priceFor(_ticketType);
    if (widget.event.gstEnabled && widget.event.gstInclusive) {
      return (rawPrice / (1 + (widget.event.gstPercentage / 100))).roundToDouble();
    }
    return rawPrice;
  }

  double get _gstAmount {
    if (_selectedZone == null) return 0.0;
    final rawPrice = _selectedZone!.priceFor(_ticketType);
    if (widget.event.gstEnabled) {
      if (widget.event.gstInclusive) {
        final base = (rawPrice / (1 + (widget.event.gstPercentage / 100))).roundToDouble();
        return rawPrice - base;
      } else {
        return (rawPrice * (widget.event.gstPercentage / 100)).roundToDouble();
      }
    }
    return 0.0;
  }

  double get _totalPrice {
    return _basePrice + _gstAmount;
  }

  String _zonePriceDisplay(ZoneModel zone) {
    final rawPrice = zone.formattedPriceFor(_ticketType);
    if (widget.event.gstEnabled && !widget.event.gstInclusive) {
      return '$rawPrice + GST';
    }
    return rawPrice;
  }

  @override
  Widget build(BuildContext context) {

    return SlideTransition(
      position: _slideAnim,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceLight,
                    AppColors.surface,
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Book Tickets',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5)),
                                Text(widget.event.name,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: AppColors.textMuted, size: 18),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Ticket Type ───────────────────────────────
                      _sectionLabel('Ticket Type'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _typeButton(
                                  'daily', 'Daily Pass', Icons.today_rounded)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _typeButton('season', 'Season Pass',
                                  Icons.stars_rounded)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Date selector (daily only) ─────────────────
                      if (_ticketType == 'daily') ...[
                        _sectionLabel('Select Date'),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.event.eventDates.length,
                            itemBuilder: (ctx, i) =>
                                _dateChip(widget.event.eventDates[i]),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Zone selector ──────────────────────────────
                      _sectionLabel('Select Zone'),
                      const SizedBox(height: 10),
                      ...widget.event.zones
                          .where(
                              (z) => z.type == _ticketType || z.type == 'both')
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => _zoneOption(e.value, e.key)),

                      // ── Price Summary ──────────────────────────────
                      if (_selectedZone != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.15)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Ticket Price',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13)),
                                  Text(
                                    '₹${_basePrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.event.gstEnabled) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('GST (${widget.event.gstPercentage.toStringAsFixed(0)}% ${widget.event.gstInclusive ? "Incl." : "Excl."})',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13)),
                                    Text(
                                      '₹${_gstAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                height: 1,
                                color: AppColors.border,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Amount',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  ShaderMask(
                                    shaderCallback: (b) =>
                                        AppColors.gradientPrimary.createShader(b),
                                    child: Text(
                                      '₹${_totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      GradientButton(
                        label: _selectedZone != null
                            ? 'Pay ₹${_totalPrice.toStringAsFixed(0)}'
                            : 'Select a Zone to Continue',
                        icon: _selectedZone != null
                            ? Icons.payment_rounded
                            : null,
                        isLoading: _isLoading,
                        onPressed: _selectedZone != null && !_isLoading
                            ? _purchase
                            : null,
                        gradient: AppColors.gradientNavratri,
                      ),

                      const SizedBox(height: 8),
                      // Secure payment note
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 12, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text('Secured by Razorpay',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5));
  }

  Widget _typeButton(String type, String label, IconData icon) {
    final isSelected = _ticketType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _ticketType = type;
        _selectedZone = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.gradientPrimary : null,
          color: isSelected ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.6)
                  : AppColors.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.3), blurRadius: 12)
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(String date) {
    final isSelected = _selectedDate == date;
    // Parse a short label from the date string
    String label;
    try {
      final d = DateTime.parse(date);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      label = '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      label = date.split(',')[0];
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.gradientPrimary : null,
          color: isSelected ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.3), blurRadius: 10)
                ]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _zoneOption(ZoneModel zone, int index) {
    final isSelected = _selectedZone?.id == zone.id;
    final zoneColors = [
      AppColors.primary,
      AppColors.gold,
      AppColors.success,
      AppColors.secondary,
      AppColors.accent,
    ];
    final zoneColor = zoneColors[index % zoneColors.length];

    return GestureDetector(
      onTap: () => setState(() => _selectedZone = zone),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected ? zoneColor.withOpacity(0.08) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? zoneColor.withOpacity(0.6) : AppColors.border,
              width: isSelected ? 1.5 : 1.0),
          boxShadow: isSelected
              ? [BoxShadow(color: zoneColor.withOpacity(0.15), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            // Zone color dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: zoneColor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: zoneColor.withOpacity(0.5), blurRadius: 6)
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14)),
                  Text(
                      zone.features.isNotEmpty
                          ? zone.features.first
                          : '${zone.availableSeats} seats left',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            // Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? zoneColor.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected
                        ? zoneColor.withOpacity(0.4)
                        : AppColors.border),
              ),
              child: Text(
                _zonePriceDisplay(zone),
                style: TextStyle(
                    color: isSelected ? zoneColor : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, color: zoneColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
