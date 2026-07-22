// lib/services/calendar_service.dart
// Uses Google Calendar API v3 via HTTP (API key auth, read-only public calendar)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/appointment.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  static const _baseUrl = 'https://www.googleapis.com/calendar/v3/calendars';

  /// Fetches events from now through [lookaheadDays] days out.
  Future<List<Appointment>> getUpcomingAppointments({
    int? lookaheadDays,
  }) async {
    final days = lookaheadDays ?? AppConfig.appointmentLookaheadDays;
    final now = DateTime.now().toUtc();
    final maxTime = now.add(Duration(days: days));

    final uri = Uri.parse(
      '$_baseUrl/${Uri.encodeComponent(AppConfig.calendarId)}/events',
    ).replace(queryParameters: {
      'key': AppConfig.googleCalendarApiKey,
      'timeMin': now.toIso8601String(),
      'timeMax': maxTime.toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'maxResults': '250',
      'fields':
          'items(id,summary,description,start,end,location,status)',
    });

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw CalendarException(
        'Calendar API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];

    return items
        .map((e) => Appointment.fromGoogleEvent(e as Map<String, dynamic>))
        .where((a) => a.status != 'cancelled')
        .toList();
  }

  /// Returns only today's appointments.
  Future<List<Appointment>> getTodayAppointments() async {
    final all = await getUpcomingAppointments(lookaheadDays: 1);
    final today = DateTime.now();
    return all.where((a) {
      final s = a.start;
      return s.year == today.year &&
          s.month == today.month &&
          s.day == today.day;
    }).toList();
  }
}

class CalendarException implements Exception {
  final String message;
  CalendarException(this.message);

  @override
  String toString() => message;
}
