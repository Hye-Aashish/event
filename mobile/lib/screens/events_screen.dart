import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/event_model.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EventProvider>().fetchEvents());
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text('Events',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        Text('Navratri 2024 — 9 Nights',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  GlassCard(
                    padding: const EdgeInsets.all(10),
                    borderRadius: 12,
                    child: const Icon(Icons.filter_list,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: events.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : events.errorMessage != null
                      ? _errorState(events.errorMessage!)
                      : events.events.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              itemCount: events.events.length,
                              itemBuilder: (ctx, i) =>
                                  _EventCard(event: events.events[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 60),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.read<EventProvider>().fetchEvents(),
            child: const Text('Retry',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🪔', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text('No events yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Check back soon for upcoming events',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Gradient header
            Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: AppColors.gradientNavratri,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪔', style: TextStyle(fontSize: 40)),
                        Text(event.dayOfWeek,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusBadge(
                      label: event.isActive ? 'Active' : 'Upcoming',
                      color: event.isActive
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 6),
                      Text(event.formattedDate,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on,
                          color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(event.venue,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (event.zones.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),
                    // Zone pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: event.zones.take(3).map((z) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${z.name} • ${z.formattedPrice}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  GradientButton(
                    label: 'Book Tickets',
                    height: 44,
                    gradient: AppColors.gradientPrimary,
                    onPressed: () => _showBookingSheet(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BookingSheet(event: event),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final EventModel event;
  const _BookingSheet({required this.event});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  ZoneModel? _selectedZone;
  String _ticketType = 'single';
  bool _isLoading = false;

  Future<void> _purchase() async {
    if (_selectedZone == null) return;
    setState(() => _isLoading = true);

    // Backend compatible object
    final res = await context.read<TicketProvider>().buyTicket(
          eventId: widget.event.id,
          zoneId: _selectedZone!.id,
          ticketType: _ticketType,
          pricePaid: _selectedZone!.price,
          extra: {
            'date': _ticketType == 'single' ? _selectedDate : 'all',
          }
        );

    setState(() => _isLoading = false);
    if (!mounted) return;
    
    if (res['success'] == true) {
      Navigator.pop(context); // Close sheet
      _showSuccessDialog();
    } else {
      _showError(res['message'] ?? 'Payment failed');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Success!', style: TextStyle(color: Colors.white)),
        content: const Text('Your ticket has been booked successfully. You can find it in the Tickets tab.',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to tickets tab if needed
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String _selectedDate = 'Oct 3, 2024';
  final List<String> _dates = [
    'Oct 3, 2024', 'Oct 4, 2024', 'Oct 5, 2024', 'Oct 6, 2024',
    'Oct 7, 2024', 'Oct 8, 2024', 'Oct 9, 2024', 'Oct 10, 2024', 'Oct 11, 2024'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Book Tickets',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Ticket Type
            const Text('Ticket Type',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _typeButton('single', 'Daily Pass')),
                const SizedBox(width: 10),
                Expanded(child: _typeButton('season', 'Season Pass (9 Days)')),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date Selection (Only for Daily)
            if (_ticketType == 'single') ...[
              const Text('Match Date',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  itemBuilder: (ctx, i) => _dateChip(_dates[i]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text('Select Zone',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...widget.event.zones.map((z) => _zoneOption(z)),
            
            const SizedBox(height: 24),
            GradientButton(
              label: _selectedZone != null
                  ? 'Pay ${_selectedZone!.formattedPrice}'
                  : 'Select a Zone',
              isLoading: _isLoading,
              onPressed: _selectedZone != null ? _purchase : null,
              gradient: AppColors.gradientPrimary,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(String date) {
    final isSelected = _selectedDate == date;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(date.split(',')[0],
              style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _zoneOption(ZoneModel zone) {
    final isSelected = _selectedZone?.id == zone.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedZone = zone),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(zone.features.isNotEmpty ? zone.features.first : '${zone.availableSeats} seats left',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Text(zone.formattedPrice,
                style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String type, String label) {
    final isSelected = _ticketType == type;
    return GestureDetector(
      onTap: () => setState(() => _ticketType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
