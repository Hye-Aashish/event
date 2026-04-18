import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/ticket_model.dart';
import 'events_screen.dart';
import 'tickets_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TicketProvider>().fetchTickets();
      context.read<EventProvider>().fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const EventsScreen(),
      const TicketsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.event_outlined),
                activeIcon: Icon(Icons.event),
                label: 'Events'),
            BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_num_outlined),
                activeIcon: Icon(Icons.confirmation_num),
                label: 'Tickets'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tickets = context.watch<TicketProvider>();
    final events = context.watch<EventProvider>();
    final user = auth.user;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
      child: Stack(
        children: [
          Positioned(
              top: -80,
              right: -60,
              child: _glow(AppColors.primary, 280)),
          Positioned(
              top: 300,
              left: -80,
              child: _glow(AppColors.secondary, 220)),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jai Mata Di 🙏',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                user?.name ?? 'Welcome!',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _avatarButton(context, user?.name),
                      ],
                    ),
                  ),
                ),

                // Stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCard('My Tickets',
                              '${tickets.tickets.length}',
                              Icons.confirmation_num,
                              AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard('Active',
                              '${tickets.activeTickets.length}',
                              Icons.check_circle,
                              AppColors.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard('Events',
                              '${events.activeEvents.length}',
                              Icons.event,
                              AppColors.gold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _banner(context),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quick Actions',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _actionCard(icon: Icons.add_card, label: 'Buy Ticket', color: AppColors.primary, onTap: () {})),
                            const SizedBox(width: 12),
                            Expanded(child: _actionCard(icon: Icons.qr_code_scanner, label: 'Scan QR', color: AppColors.secondary, onTap: () => Navigator.pushNamed(context, '/scanner'))),
                            const SizedBox(width: 12),
                            Expanded(child: _actionCard(icon: Icons.verified_user, label: 'Verify ID', color: AppColors.gold, onTap: () => Navigator.pushNamed(context, '/verification'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent tickets
                if (tickets.tickets.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Tickets',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (tickets.tickets.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final t = tickets.tickets[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 5),
                          child: _ticketRow(context, t),
                        );
                      },
                      childCount: tickets.tickets.take(3).length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(0.09)));

  Widget _avatarButton(BuildContext context, String? name) {
    final initials = name != null && name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradientPrimary,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)],
        ),
        child: Center(
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: AppColors.gradientNavratri,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🪔 Navratri 2024',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1)),
            const Text('Experience 9 Nights\nof Garba & Dandiya',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.3)),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text('Book Now →',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _ticketRow(BuildContext context, TicketModel ticket) {
    final isActive = ticket.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.textMuted;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/ticket-detail',
          arguments: ticket.id),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.confirmation_num,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.eventName ?? 'Navratri Event',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(ticket.zoneName ?? ticket.zoneType ?? 'General',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            StatusBadge(label: ticket.statusDisplay, color: statusColor),
          ],
        ),
      ),
    );
  }
}
