// lib/models/appointment.dart

class Appointment {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? location;
  final bool isAllDay;
  final String status; // 'confirmed' | 'cancelled' | 'tentative'

  Appointment({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.location,
    this.isAllDay = false,
    this.status = 'confirmed',
  });

  factory Appointment.fromGoogleEvent(Map<String, dynamic> event) {
    final startRaw = event['start'] as Map<String, dynamic>?;
    final endRaw = event['end'] as Map<String, dynamic>?;
    final isAllDay = startRaw?.containsKey('date') ?? false;

    DateTime parseStart() {
      if (isAllDay) return DateTime.parse(startRaw!['date']);
      return DateTime.parse(startRaw!['dateTime']).toLocal();
    }

    DateTime parseEnd() {
      if (isAllDay) return DateTime.parse(endRaw!['date']);
      return DateTime.parse(endRaw!['dateTime']).toLocal();
    }

    return Appointment(
      id: event['id'] as String? ?? '',
      title: event['summary'] as String? ?? 'Appointment',
      description: event['description'] as String?,
      start: parseStart(),
      end: parseEnd(),
      location: event['location'] as String?,
      isAllDay: isAllDay,
      status: event['status'] as String? ?? 'confirmed',
    );
  }

  /// True if this appointment starts today.
  bool get isToday {
    final now = DateTime.now();
    return start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
  }

  /// Duration string like "30 min" or "1h 15m"
  String get durationLabel {
    final minutes = end.difference(start).inMinutes;
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
