// lib/screens/appointments_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/appointment.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _cal = CalendarService();
  late Future<List<Appointment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cal.getUpcomingAppointments();
  }

  void _refresh() => setState(() {
        _future = _cal.getUpcomingAppointments();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary, size: 20),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ShimmerList();
          }
          if (snap.hasError) {
            return ErrorState(
              message: _friendlyError(snap.error),
              onRetry: _refresh,
            );
          }
          final all = snap.data ?? [];
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_today_rounded,
              title: 'No upcoming appointments',
              subtitle: 'Appointments booked via AVA will appear here.',
            );
          }
          return _AppointmentsList(appointments: all, onRefresh: _refresh);
        },
      ),
    );
  }

  String _friendlyError(Object? err) {
    final s = err.toString();
    if (s.contains('403') || s.contains('API key')) {
      return 'Invalid API key.\nCheck AppConfig.googleCalendarApiKey.';
    }
    if (s.contains('404') || s.contains('calendarId')) {
      return 'Calendar not found.\nCheck AppConfig.calendarId.';
    }
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'No internet connection.';
    }
    return s;
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<Appointment> appointments;
  final VoidCallback onRefresh;

  const _AppointmentsList({
    required this.appointments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Group by date
    final Map<String, List<Appointment>> grouped = {};
    for (final a in appointments) {
      final key = _dayKey(a.start);
      grouped.putIfAbsent(key, () => []).add(a);
    }
    final days = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfaceCard,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 32),
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final day = days[i];
          final appts = grouped[day]!;
          final isToday = _isTodayKey(day);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(label: day, isToday: isToday, count: appts.length),
              ...appts.map((a) => AppointmentCard(
                    appt: a,
                    isToday: isToday,
                  )),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  String _dayKey(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return DateFormat('EEEE, MMM d').format(dt);
  }

  bool _isTodayKey(String key) => key == 'Today';
}

class _DayHeader extends StatelessWidget {
  final String label;
  final bool isToday;
  final int count;

  const _DayHeader({
    required this.label,
    required this.isToday,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isToday ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: isToday ? AppTheme.primary : AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Shimmer.fromColors(
          baseColor: AppTheme.surfaceCard,
          highlightColor: AppTheme.surfaceElevated,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
