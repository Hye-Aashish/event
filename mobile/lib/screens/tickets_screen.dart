// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_block.dart';
import '../widgets/status_badge.dart';
import 'home_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => context.read<TicketProvider>().fetchTickets());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Tickets',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.8)),
                          Text('Your event passes',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => provider.fetchTickets(),
                      child: const GlassCard(
                        padding: EdgeInsets.all(10),
                        borderRadius: 12,
                        child: Icon(Icons.refresh_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Gradient Tab Bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 12)
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '🎟️  Active'),
                      Tab(text: '✅  Used'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TicketList(
                      isLoading: provider.isLoading,
                      tickets: provider.activeTickets,
                      emptyLabel: 'No active tickets',
                      emptyIcon: '🎟️',
                      emptySubtitle: 'Buy a ticket to get started',
                    ),
                    _TicketList(
                      isLoading: provider.isLoading,
                      tickets: provider.usedTickets,
                      emptyLabel: 'No past tickets',
                      emptyIcon: '✅',
                      emptySubtitle: 'Used tickets will appear here',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final bool isLoading;
  final List<TicketModel> tickets;
  final String emptyLabel;
  final String emptyIcon;
  final String emptySubtitle;

  const _TicketList({
    required this.isLoading,
    required this.tickets,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.fetchTickets(),
      color: AppColors.primary,
      child: isLoading
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 3,
              itemBuilder: (ctx, i) => const TicketCardSkeleton(),
            )
          : tickets.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOut,
                            builder: (_, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: Text(emptyIcon,
                                style: const TextStyle(fontSize: 70)),
                          ),
                          const SizedBox(height: 16),
                          Text(emptyLabel,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(emptySubtitle,
                              style:
                                  const TextStyle(color: AppColors.textMuted)),
                          if (emptyLabel == 'No active tickets') ...[
                            const SizedBox(height: 20),
                            Semantics(
                              label: 'Browse Events',
                              child: Builder(
                                builder: (ctx) => GestureDetector(
                                  onTap: () {
                                    final homeState =
                                        homeScreenKey.currentState;
                                    if (homeState is HomeScreenState) {
                                      (homeState as HomeScreenState)
                                          .setIndex(1);
                                    }
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.gradientPrimary,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.35),
                                            blurRadius: 12),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.event_rounded,
                                            color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text('Browse Events',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: tickets.length,
                  itemBuilder: (ctx, i) => _TicketCard(
                    ticket: tickets[i],
                  ),
                ),
    );
  }
}

class _TicketCard extends StatefulWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final isActive = ticket.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.textMuted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.pushNamed(context, '/ticket-detail', arguments: ticket.id);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(18),
            borderColor: isActive ? AppColors.primary.withOpacity(0.35) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? (ticket.isSeasonPass
                                    ? AppColors.gradientGold
                                    : AppColors.gradientPrimary)
                                : AppColors.cardGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.3),
                                        blurRadius: 12)
                                  ]
                                : null,
                          ),
                          child: Icon(
                            ticket.isSeasonPass
                                ? Icons.stars_rounded
                                : Icons.confirmation_num_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        // Quantity badge — shown when user owns >1 of this type
                        if (widget.ticket.quantity > 1)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientNavratri,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.background, width: 1.5),
                              ),
                              child: Text(
                                '${widget.ticket.quantity}x',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.eventName ?? 'Navratri Event',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ticket.isSeasonPass
                                ? '⭐ Season Pass'
                                : 'Single Day',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                        label: ticket.statusDisplay,
                        color: statusColor,
                        animate: isActive),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoItem(
                        Icons.location_on_outlined, ticket.zoneName ?? 'Zone'),
                    const SizedBox(width: 16),
                    _infoItem(
                        Icons.calendar_today_outlined, ticket.formattedDate),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(ticket.formattedPrice,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ],
                ),

                // Mini QR preview for active tickets
                if (isActive) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ticket.qrCode.isNotEmpty
                              ? QrImageView(
                                  data: ticket.qrCode,
                                  version: QrVersions.auto,
                                  size: 80,
                                  eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black),
                                  dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black),
                                )
                              : const Icon(Icons.qr_code_2,
                                  size: 80, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 12, color: AppColors.textMuted),
                            SizedBox(width: 4),
                            Text('Tap to view full QR',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
