// lib/models/dashboard_stats.dart

class DashboardStats {
  final int callsToday;
  final int apptBooked;
  final int failedOrMissed;
  final int transferred;
  final double avgDurationSeconds;
  final int apptTotal; // upcoming appointments count

  const DashboardStats({
    required this.callsToday,
    required this.apptBooked,
    required this.failedOrMissed,
    required this.transferred,
    required this.avgDurationSeconds,
    required this.apptTotal,
  });

  static const empty = DashboardStats(
    callsToday: 0,
    apptBooked: 0,
    failedOrMissed: 0,
    transferred: 0,
    avgDurationSeconds: 0,
    apptTotal: 0,
  );

  String get avgDurationLabel {
    if (avgDurationSeconds < 60) return '${avgDurationSeconds.round()}s';
    final m = (avgDurationSeconds / 60).floor();
    final s = (avgDurationSeconds % 60).round();
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  double get bookingRate {
    if (callsToday == 0) return 0;
    return apptBooked / callsToday;
  }
}
