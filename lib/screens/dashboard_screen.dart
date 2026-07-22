// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/call_record.dart';
import '../models/appointment.dart';
import '../models/dashboard_stats.dart';
import '../services/firestore_service.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/error_state.dart';

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
    final transferred =
        calls.where((c) => c.outcome == 'transferred').length;

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
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: AppTheme.primary,
          backgroundColor: AppTheme.surfaceCard,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'AVA Dashboard',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Live indicator
                          _LiveBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Stats
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
                    return _StatsGrid(stats: s);
                  },
                ),
              ),
              // Recent activity header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 15, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'RECENT CALLS',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
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

// ─── Stats grid ────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rate = stats.bookingRate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Row 1: calls today + appts booked
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Calls Today',
                  value: '${stats.callsToday}',
                  icon: Icons.phone_rounded,
                  color: AppTheme.primary,
                  subtitle: 'total',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Appointments Booked',
                  value: '${stats.apptBooked}',
                  icon: Icons.calendar_month_rounded,
                  color: AppTheme.booked,
                  subtitle: 'today',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: failed + avg duration
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Failed / Missed',
                  value: '${stats.failedOrMissed}',
                  icon: Icons.cancel_rounded,
                  color: AppTheme.failed,
                  subtitle: 'today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Avg Call Duration',
                  value: stats.avgDurationLabel,
                  icon: Icons.timer_rounded,
                  color: AppTheme.transferred,
                  subtitle: 'today',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: booking rate (full width) + transferred
          Row(
            children: [
              Expanded(
                flex: 2,
                child: StatCard(
                  label: 'Booking Rate',
                  value: stats.callsToday == 0
                      ? '—'
                      : '${(rate * 100).round()}%',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.completed,
                  bottom: stats.callsToday > 0
                      ? _BookingBar(rate: rate)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Transferred',
                  value: '${stats.transferred}',
                  icon: Icons.swap_calls_rounded,
                  color: AppTheme.transferred,
                  subtitle: 'today',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  final double rate;
  const _BookingBar({required this.rate});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: rate.clamp(0.0, 1.0),
        backgroundColor: AppTheme.border,
        valueColor:
            const AlwaysStoppedAnimation<Color>(AppTheme.completed),
        minHeight: 5,
      ),
    );
  }
}

// ─── Live badge ───────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.booked.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.booked.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulse,
            child: const Icon(Icons.circle,
                size: 7, color: AppTheme.booked),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.booked,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent calls (last 5 from live stream) ───────────────────────────────

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
                    fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(AppTheme.outcomeIcon(call.outcome), size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              call.patientNumber,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            DateFormat('h:mm a').format(call.timestamp),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _shimmerBox(90)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(90)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double h) => Container(
        height: h,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
      );
}
