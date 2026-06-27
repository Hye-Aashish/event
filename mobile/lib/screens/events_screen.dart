// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/shimmer_block.dart';
import '../widgets/status_badge.dart';
import '../widgets/booking_sheet.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _activeFilter = 'All';
  final _filters = ['All', 'Active', 'Upcoming'];
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EventProvider>().fetchEvents());
  }

  List<EventModel> _applyFilter(List<EventModel> events) {
    var result = events;
    if (_activeFilter == 'Active') {
      result = result.where((e) => e.isActive).toList();
    }
    if (_activeFilter == 'Upcoming') {
      result = result.where((e) => !e.isActive).toList();
    }
    final q = _searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        filters: _filters,
        activeFilter: _activeFilter,
        onSelect: (f) {
          setState(() => _activeFilter = f);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Events',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.8)),
                              Text('Navratri 2026 — 9 Nights',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        // #11 Search toggle icon
                        Semantics(
                          label: 'Search events',
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _searchOpen = !_searchOpen);
                              if (!_searchOpen) {
                                _searchController.clear();
                                _searchQuery.value = '';
                              }
                            },
                            child: GlassCard(
                              padding: const EdgeInsets.all(10),
                              borderRadius: 12,
                              borderColor: _searchOpen
                                  ? AppColors.primary.withOpacity(0.5)
                                  : null,
                              child: Icon(
                                _searchOpen
                                    ? Icons.search_off_rounded
                                    : Icons.search_rounded,
                                color: _searchOpen
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showFilterSheet,
                          child: GlassCard(
                            padding: const EdgeInsets.all(10),
                            borderRadius: 12,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_list_rounded,
                                    color: _activeFilter == 'All'
                                        ? AppColors.textSecondary
                                        : AppColors.primary,
                                    size: 20),
                                if (_activeFilter != 'All') ...[
                                  const SizedBox(width: 6),
                                  Text(_activeFilter,
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // #11 Animated search bar
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _searchOpen
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          borderRadius: 14,
                          borderColor: AppColors.primary.withOpacity(0.4),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Search events...',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: AppColors.primary, size: 18),
                            ),
                            onChanged: (v) => _searchQuery.value = v.trim(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => events.fetchEvents(),
                  color: AppColors.primary,
                  child: ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    builder: (context, _, __) => events.isLoading
                        ? ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: 4,
                            itemBuilder: (ctx, i) => const EventListSkeleton(),
                          )
                        : events.errorMessage != null
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: _errorState(events.errorMessage!),
                                ),
                              )
                            : events.events.isEmpty
                                ? SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.6,
                                      child: _emptyState(),
                                    ),
                                  )
                                : () {
                                    final filtered =
                                        _applyFilter(events.events);
                                    return filtered.isEmpty
                                        ? SingleChildScrollView(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            child: SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.6,
                                              child: _noResultsState(),
                                            ),
                                          )
                                        : ListView.builder(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 8, 16, 100),
                                            itemCount: filtered.length,
                                            itemBuilder: (ctx, i) =>
                                                _EventCard(event: filtered[i]),
                                          );
                                  }(),
                  ),
                ),
              ),
            ],
          ),
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
            child:
                const Text('Retry', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: const Text('🥢🥁💃', style: TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 16),
          const Text('No events yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Check back soon for upcoming events',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _noResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.textMuted, size: 60),
          const SizedBox(height: 16),
          Text('No $_activeFilter events',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _activeFilter = 'All'),
            child: const Text('Clear Filter',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onSelect;

  const _FilterSheet({
    required this.filters,
    required this.activeFilter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Text('Filter Events',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: filters.map((f) {
              final isActive = f == activeFilter;
              return GestureDetector(
                onTap: () => onSelect(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppColors.gradientPrimary : null,
                    color: isActive ? null : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                        width: 1),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12)
                          ]
                        : null,
                  ),
                  child: Text(f,
                      style: TextStyle(
                          color:
                              isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  Color _zoneColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.gold,
      AppColors.success,
      AppColors.secondary,
      AppColors.accent,
    ];
    return colors[index % colors.length];
  }

  String? _lowestPrice() {
    if (event.zones.isEmpty) return null;
    return event.zones.first.formattedPriceFor('daily');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: () =>
            Navigator.pushNamed(context, '/event-detail', arguments: event),
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ───────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: event.fullImageUrl != null
                      ? Image.network(
                          event.fullImageUrl!,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientHeader(),
                        )
                      : _gradientHeader(),
                ),
                // Bottom fade overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.surface.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusBadge(
                    label: event.isActive ? 'Active' : 'Upcoming',
                    color: event.isActive
                        ? AppColors.background
                        : AppColors.warning,
                    animate: event.isActive,
                  ),
                ),
                // Price badge
                if (_lowestPrice() != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Text(
                        'From ${_lowestPrice()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Card Body ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary, size: 13),
                      const SizedBox(width: 6),
                      Text(event.formattedDate,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(event.venue,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (event.zones.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    // Zone pills with per-zone color
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children:
                          event.zones.take(3).toList().asMap().entries.map((e) {
                        final color = _zoneColor(e.key);
                        final z = e.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.35)),
                          ),
                          child: Text(
                            '${z.name} • ${z.formattedPriceFor('daily')}',
                            style: TextStyle(
                                color: color,
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
                    gradient: AppColors.gradientPrimary,
                    height: 46,
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

  Widget _gradientHeader() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientNavratri,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥢🥁💃', style: TextStyle(fontSize: 40)),
            Text(event.dayOfWeek,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) async {
    final success = await BookingSheet.show(context, event);
    if (success == true && context.mounted) {
      BookingSheet.showSuccessDialog(context);
    }
  }
}
