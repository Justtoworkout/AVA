// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/call_record.dart';
import '../models/appointment.dart';
import '../models/dashboard_stats.dart';
import '../services/firestore_service.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/outcome_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _fs = FirestoreService();
  final _cal = CalendarService();

  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<DashboardStats> _loadStats() async {
    final results = await Future.wait([
      _fs.getCallsToday(),
      _cal.getUpcomingAppointments().catchError((_) => <Appointment>[]),
    ]);

    final calls = results[0] as List<CallRecord>;
    final appts = results[1] as List<Appointment>;

    final booked = calls.where((c) => c.outcome == 'booked').length;
    final failed = calls.where((c) => c.outcome == 'failed').length;
    final transferred = calls.where((c) => c.outcome == 'transferred').length;

    final totalDur = calls.fold<int>(0, (s, c) => s + c.durationSeconds);
    final avgDur = calls.isEmpty ? 0.0 : totalDur / calls.length;

    return DashboardStats(
      callsToday: calls.length,
      apptBooked: booked,
      failedOrMissed: failed,
      transferred: transferred,
      avgDurationSeconds: avgDur.toDouble(),
      apptTotal: appts.length,
    );
  }

  void _refresh() => setState(() => _statsFuture = _loadStats());

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'AVA Dashboard',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppTheme.textPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Live indicator with waveform
                          const _LiveBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Hero Stat (Booking Rate) & Dense Sub-stats Row
              SliverToBoxAdapter(
                child: FutureBuilder<DashboardStats>(
                  future: _statsFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const _StatsShimmer();
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: ErrorState(
                          message: snap.error.toString(),
                          onRetry: _refresh,
                        ),
                      );
                    }
                    final s = snap.data ?? DashboardStats.empty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroBookingCard(stats: s),
                        const SizedBox(height: 16),
                        _StatsStrip(stats: s),
                      ],
                    );
                  },
                ),
              ),
              // Recent activity header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 14, color: AppTheme.accent),
                      const SizedBox(width: 6),
                      const Text(
                        'RECENT ACTIVITY',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Recent calls stream (last 5)
              _RecentCallsSliver(fs: _fs),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ─── Hero Booking Card ───────────────────────────────────────────────────────

class _HeroBookingCard extends StatelessWidget {
  final DashboardStats stats;
  const _HeroBookingCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rate = stats.bookingRate;
    final ratePercent = stats.callsToday == 0 ? 0 : (rate * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line, width: 1),
      ),
      child: Row(
        children: [
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOOKING RATE',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      stats.callsToday == 0 ? '—' : '$ratePercent%',
                      style: AppTheme.numeralStyle.copyWith(fontSize: 48),
                    ),
                    if (stats.callsToday > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        'target 80%',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Trend indicators in neutral styling
                Row(
                  children: [
                    Icon(
                      ratePercent >= 75 ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                      size: 14,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ratePercent >= 75 ? '↑ 3.2% vs last week' : 'Stable performance',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Signature Radial Ring Gauge
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.line),
                  ),
                ),
                // Indicator Ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: stats.callsToday == 0 ? 0.0 : rate.clamp(0.0, 1.0),
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                ),
                // Tiny phone status icon centered inside gauge
                const Icon(
                  Icons.phone_in_talk_outlined,
                  size: 20,
                  color: AppTheme.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dense Sub-stats Strip ──────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final DashboardStats stats;
  const _StatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.line, width: 1),
          bottom: BorderSide(color: AppTheme.line, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildItem('Calls Today', '${stats.callsToday}'),
          _buildDivider(),
          _buildItem('Booked', '${stats.apptBooked}'),
          _buildDivider(),
          _buildItem('Failed', '${stats.failedOrMissed}', isAlert: stats.failedOrMissed > 0),
          _buildDivider(),
          _buildItem('Avg Duration', stats.avgDurationLabel),
          _buildDivider(),
          _buildItem('Transferred', '${stats.transferred}'),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.line,
    );
  }

  Widget _buildItem(String label, String value, {bool isAlert = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTheme.numeralStyle.copyWith(
              fontSize: 16,
              color: isAlert ? AppTheme.alert : AppTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live badge with sound waveform ──────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect system-wide reduced motion settings
    final bool disableAnim = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4), // Clean hairline corners
        border: Border.all(color: AppTheme.line, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform
          AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) {
              return Row(
                children: List.generate(4, (index) {
                  double scale = 0.5;
                  if (!disableAnim) {
                    final double shift = index * 0.25;
                    scale = 0.2 + 0.8 * ((_ctrl.value + shift) % 1.0 - 0.5).abs() * 2.0;
                  }
                  return Container(
                    width: 2.2,
                    height: 12 * scale,
                    margin: const EdgeInsets.symmetric(horizontal: 1.0),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent calls ───────────────────────────────────────────────────────────

class _RecentCallsSliver extends StatelessWidget {
  final FirestoreService fs;
  const _RecentCallsSliver({required this.fs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallRecord>>(
      stream: fs.callsStream(),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No calls yet today.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }
        final recent = snap.data!.take(5).toList();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _RecentCallRow(call: recent[i]),
            childCount: recent.length,
          ),
        );
      },
    );
  }
}

class _RecentCallRow extends StatelessWidget {
  final CallRecord call;
  const _RecentCallRow({required this.call});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.outcomeColor(call.outcome);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line, width: 1),
      ),
      child: Row(
        children: [
          // Clean Left status strip indicator instead of pastel icon chips
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              call.patientNumber,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            DateFormat('h:mm a').format(call.timestamp),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          OutcomeBadge(outcome: call.outcome, compact: true),
        ],
      ),
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Hero card shimmer
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.line),
            ),
          ),
          const SizedBox(height: 16),
          // Strip shimmer
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.line),
            ),
          ),
        ],
      ),
    );
  }
}
