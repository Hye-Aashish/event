// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_block.dart';
import '../widgets/status_badge.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> implements HomeScreenState {
  int _selectedIndex = 0;

  @override
  void setIndex(int index) {
    setState(() => _selectedIndex = index);
  }

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

    return Provider<HomeScreenState>.value(
      value: this,
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: pages),
        extendBody: true,
        bottomNavigationBar: _FloatingNavBar(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }
}

// ── Floating Pill Navigation Bar ────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: AppColors.borderLight.withOpacity(0.5), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    selectedIndex: selectedIndex,
                    onTap: onTap),
                _NavItem(
                    icon: Icons.event_outlined,
                    activeIcon: Icons.event_rounded,
                    label: 'Events',
                    index: 1,
                    selectedIndex: selectedIndex,
                    onTap: onTap),
                _NavItemWithBadge(
                    icon: Icons.confirmation_num_outlined,
                    activeIcon: Icons.confirmation_num_rounded,
                    label: 'Tickets',
                    index: 2,
                    selectedIndex: selectedIndex,
                    onTap: onTap),
                _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
                    selectedIndex: selectedIndex,
                    onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Item With Badge (for Tickets) ──────────────────────────────────────
class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItemWithBadge({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tickets = context.watch<TicketProvider>();
    final hasActive = tickets.activeTickets.isNotEmpty;
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: isSelected
                ? BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(24),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  size: 20,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // #9 Red dot badge when there are active tickets
          if (hasActive && !isSelected)
            Positioned(
              top: 4,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with TickerProviderStateMixin {
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late Animation<Offset> _blob1Anim;
  late Animation<Offset> _blob2Anim;

  @override
  void initState() {
    super.initState();
    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _blob1Anim = Tween<Offset>(
      begin: const Offset(-60, -80),
      end: const Offset(-30, -50),
    ).animate(
        CurvedAnimation(parent: _blob1Controller, curve: Curves.easeInOut));
    _blob2Anim = Tween<Offset>(
      begin: const Offset(-80, 300),
      end: const Offset(-50, 330),
    ).animate(
        CurvedAnimation(parent: _blob2Controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 🌅';
    if (h < 17) return 'Good Afternoon ☀️';
    if (h < 19) return 'Good Evening 🌙';
    return 'Jai Mata Di 🙏';
  }

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
          // // Animated drifting glow blobs
          // AnimatedBuilder(
          //   animation: _blob1Anim,
          //   builder: (_, __) => Positioned(
          //     top: _blob1Anim.value.dy,
          //     right: _blob1Anim.value.dx,
          //     child: _glowBlob(AppColors.primary, 280),
          //   ),
          // ),
          // AnimatedBuilder(
          //   animation: _blob2Anim,
          //   builder: (_, __) => Positioned(
          //     top: _blob2Anim.value.dy,
          //     left: _blob2Anim.value.dx,
          //     child: _glowBlob(AppColors.secondary, 220),
          //   ),
          // ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  auth.refreshProfile(),
                  tickets.fetchTickets(),
                  events.fetchEvents(),
                ]);
              },
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_greeting(),
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                ShaderMask(
                                  shaderCallback: (b) => AppColors
                                      .gradientNavratri
                                      .createShader(b),
                                  child: Text(
                                    user?.name ?? 'Welcome!',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _avatarButton(context, user?.name),
                        ],
                      ),
                    ),
                  ),

                  // ── Stats ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: tickets.isLoading || events.isLoading
                            ? [
                                const Expanded(child: StatSkeletonCard()),
                                const SizedBox(width: 12),
                                const Expanded(child: StatSkeletonCard()),
                                const SizedBox(width: 12),
                                const Expanded(child: StatSkeletonCard()),
                              ]
                            : [
                                Expanded(
                                  child: _statCard(
                                      'My Tickets',
                                      tickets.tickets.length,
                                      Icons.confirmation_num_rounded,
                                      AppColors.gradientPrimary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCard(
                                      'Active',
                                      tickets.activeTickets.length,
                                      Icons.check_circle_rounded,
                                      AppColors.gradientSuccess),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCard(
                                      'Events',
                                      events.activeEvents.length,
                                      Icons.event_rounded,
                                      AppColors.gradientGold),
                                ),
                              ],
                      ),
                    ),
                  ),

                  // ── QR Shortcut Banner (#1) ──────────────────────────────────
                  if (!tickets.isLoading && tickets.activeTickets.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: GestureDetector(
                          onTap: () {
                            final ticket = tickets.activeTickets.first;
                            Navigator.pushNamed(context, '/ticket-detail',
                                arguments: ticket.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardGradient,
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.qr_code_rounded,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Show My QR',
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              letterSpacing: -0.2)),
                                      Text(
                                        tickets.activeTickets.first.eventName ??
                                            'Tap to view your entry QR code',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Premium Banner ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _PremiumBanner(context: context),
                    ),
                  ),

                  // ── Upcoming Events ─────────────────────────────────────
                  if (events.isLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Text('Upcoming Events',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3)),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 260,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3,
                                itemBuilder: (ctx, i) =>
                                    const HorizontalEventSkeleton(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (events.activeEvents.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Upcoming Events',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3)),
                                Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: TextButton(
                                    onPressed: () => context
                                        .read<HomeScreenState>()
                                        .setIndex(1),
                                    child: const Text('View All',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 270,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: events.activeEvents.length,
                                itemBuilder: (ctx, i) => _horizontalEventCard(
                                    context, events.activeEvents[i]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Quick Actions ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick Actions',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                  child: _PressableActionCard(
                                icon: Icons.add_card_rounded,
                                label: 'Buy Ticket',
                                gradient: AppColors.gradientPrimary,
                                onTap: () {
                                  final homeState = homeScreenKey.currentState;
                                  if (homeState is HomeScreenState) {
                                    (homeState as HomeScreenState).setIndex(1);
                                  }
                                },
                              )),
                              const SizedBox(width: 12),
                              // Expanded(
                              //     child: _PressableActionCard(
                              //   icon: Icons.qr_code_scanner_rounded,
                              //   label: 'Scan QR',
                              //   gradient: LinearGradient(
                              //       colors: [
                              //         AppColors.secondary,
                              //         AppColors.secondary.withBlue(255)
                              //       ],
                              //       begin: Alignment.topLeft,
                              //       end: Alignment.bottomRight),
                              //   onTap: () =>
                              //       Navigator.pushNamed(context, '/scanner'),
                              // )),
                              Expanded(
                                  child: _PressableActionCard(
                                icon: Icons.confirmation_num_outlined,
                                label: 'My Tickets',
                                gradient: AppColors.gradientPrimary,
                                onTap: () {
                                  final homeState = homeScreenKey.currentState;
                                  if (homeState is HomeScreenState) {
                                    (homeState as HomeScreenState).setIndex(2);
                                  }
                                },
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _PressableActionCard(
                                icon: Icons.verified_user_rounded,
                                label: 'Verify ID',
                                gradient: AppColors.gradientPrimary,
                                onTap: () => Navigator.pushNamed(
                                    context, '/verification'),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Recent Tickets ──────────────────────────────────────
                  if (tickets.isLoading) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text('Recent Tickets',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: TicketSkeletonRow(),
                        ),
                        childCount: 3,
                      ),
                    ),
                  ] else if (tickets.tickets.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Tickets',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3)),
                            TextButton(
                              onPressed: () =>
                                  context.read<HomeScreenState>().setIndex(2),
                              child: const Text('See All',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final t = tickets.tickets[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 5),
                            child: _ticketRow(context, t),
                          );
                        },
                        childCount: tickets.tickets.take(3).length,
                      ),
                    ),
                  ],

                  // Bottom padding for floating nav
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.09),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.04),
                blurRadius: 60,
                spreadRadius: 20),
          ]));

  Widget _avatarButton(BuildContext context, String? name) {
    final initials = name != null && name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradientPrimary,
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

  Widget _statCard(String label, int value, IconData icon, Gradient gradient) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text(
              '$v',
              style: TextStyle(
                color: (gradient).colors.first,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _horizontalEventCard(BuildContext context, EventModel event) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, '/event-detail', arguments: event),
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: event.imageUrl != null
                        ? Image.network(
                            event.imageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _gradientHeader(120),
                          )
                        : _gradientHeader(120),
                  ),
                  // Overlay gradient fade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.surface.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Hot badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 8),
                        ],
                      ),
                      child: const Text('🔥 HOT',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              event.venue,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            event.formattedDate,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Starting price pill
                      if (event.zones.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            'From ${event.zones.first.formattedPriceFor('daily')}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientHeader(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientNavratri,
      ),
      child: const Center(
        child: Text('🪔', style: TextStyle(fontSize: 40)),
      ),
    );
  }

  Widget _ticketRow(BuildContext context, TicketModel ticket) {
    final isActive = ticket.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.textMuted;
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/ticket-detail', arguments: ticket.id),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: isActive
                      ? AppColors.gradientPrimary
                      : const LinearGradient(
                          colors: [Color(0xFF2A2A38), Color(0xFF2A2A38)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10)
                        ]
                      : null),
              child: const Icon(Icons.confirmation_num_rounded,
                  color: Colors.white, size: 20),
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
            StatusBadge(
                label: ticket.statusDisplay,
                color: statusColor,
                animate: isActive),
          ],
        ),
      ),
    );
  }
}

// ── Animated Banner with floating particles ──────────────────────────────────
class _PremiumBanner extends StatefulWidget {
  final BuildContext context;
  const _PremiumBanner({required this.context});

  @override
  State<_PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<_PremiumBanner>
    with TickerProviderStateMixin {
  late List<AnimationController> _particleControllers;
  late List<Animation<Offset>> _particleAnims;
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _particleControllers = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + i * 400),
      )..repeat(reverse: true),
    );
    _particleAnims = List.generate(
      5,
      (i) => Tween<Offset>(
        begin: Offset((_rng.nextDouble() * 220).toDouble(),
            (_rng.nextDouble() * 120).toDouble()),
        end: Offset((_rng.nextDouble() * 220).toDouble(),
            (_rng.nextDouble() * 120).toDouble()),
      ).animate(CurvedAnimation(
          parent: _particleControllers[i], curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    for (final c in _particleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Floating particles
            ...List.generate(5, (i) {
              return AnimatedBuilder(
                animation: _particleAnims[i],
                builder: (_, __) => Positioned(
                  left: _particleAnims[i].value.dx,
                  top: _particleAnims[i].value.dy,
                  child: Container(
                    width: 6 + (i * 2).toDouble(),
                    height: 6 + (i * 2).toDouble(),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1 + i * 0.03),
                    ),
                  ),
                ),
              );
            }),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🪔 Navratri 2026',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  const Text('Experience 9 Nights\nof Garba & Dandiya',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: -0.3)),
                  GestureDetector(
                    onTap: () {
                      final homeState = homeScreenKey.currentState;
                      if (homeState is HomeScreenState) {
                        (homeState as HomeScreenState).setIndex(1);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Book Now',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 14),
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
}

// ── Pressable Action Card with AnimatedScale ─────────────────────────────────
class _PressableActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PressableActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PressableActionCard> createState() => _PressableActionCardState();
}

class _PressableActionCardState extends State<_PressableActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glowColor =
        (widget.gradient as LinearGradient).colors.first.withOpacity(0.3);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// Global key for home screen state to allow switching tabs
final GlobalKey<State<HomeScreen>> homeScreenKey =
    GlobalKey<State<HomeScreen>>();

// Simple interface to access Home Screen State from children
abstract class HomeScreenState {
  void setIndex(int index);
}
