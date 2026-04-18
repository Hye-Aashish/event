import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/ticket_model.dart';

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

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                                color: AppColors.textPrimary)),
                        Text('Your event passes',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => provider.fetchTickets(),
                    child: GlassCard(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 12,
                      child: const Icon(Icons.refresh,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Used / Cancelled'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _TicketList(
                          tickets: provider.activeTickets,
                          emptyLabel: 'No active tickets',
                          emptyIcon: '🎟️',
                        ),
                        _TicketList(
                          tickets: provider.usedTickets,
                          emptyLabel: 'No used tickets',
                          emptyIcon: '✅',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<TicketModel> tickets;
  final String emptyLabel;
  final String emptyIcon;

  const _TicketList({
    required this.tickets,
    required this.emptyLabel,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyIcon, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(emptyLabel,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your tickets will appear here',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: tickets.length,
      itemBuilder: (ctx, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isActive = ticket.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/ticket-detail',
            arguments: ticket.id),
        child: GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(18),
          borderColor: isActive
              ? AppColors.primary.withOpacity(0.3)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? AppColors.gradientPrimary
                          : const LinearGradient(
                              colors: [AppColors.surfaceLight, AppColors.surface]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ticket.isSeasonPass
                          ? Icons.stars
                          : Icons.confirmation_num,
                      color: Colors.white,
                      size: 22,
                    ),
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
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ticket.ticketType == 'season'
                              ? 'Season Pass'
                              : 'Single Day',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                      label: ticket.statusDisplay, color: statusColor),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),

              Row(
                children: [
                  _infoItem(Icons.location_on_outlined,
                      ticket.zoneName ?? 'Zone'),
                  const SizedBox(width: 16),
                  _infoItem(Icons.calendar_today_outlined,
                      ticket.formattedDate),
                  const Spacer(),
                  Text(ticket.formattedPrice,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),

              if (isActive) ...[
                const SizedBox(height: 14),
                // Mini QR preview
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
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
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Tap to view full QR',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
