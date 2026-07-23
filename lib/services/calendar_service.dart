// lib/services/calendar_service.dart
// Uses Google Calendar API v3 via HTTP (API key auth, read-only public calendar)
// Falls back gracefully to mock appointments if no API key is provided.

import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
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
    // If no Google Calendar API Key is provided, fallback to realistic mock appointments
    if (AppConfig.googleCalendarApiKey.isEmpty || 
        AppConfig.googleCalendarApiKey.trim() == 'your_key_here' ||
        AppConfig.calendarId.isEmpty) {
      debugPrint('[WARN] Google Calendar credentials not configured. Falling back to mock appointments.');
      return _generateMockAppointments();
    }

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
      'fields': 'items(id,summary,description,start,end,location,status)',
    });

    try {
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
    } catch (e) {
      // On network failure or exception, fallback to mock appointments so the app screen stays functional
      debugPrint('[ERROR] Calendar fetch failed, using mock fallback: $e');
      return _generateMockAppointments();
    }
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

  /// Generates a set of realistic mock appointments for development and demo mode.
  List<Appointment> _generateMockAppointments() {
    final now = DateTime.now();
    return [
      Appointment(
        id: 'mock_appt_1',
        title: 'Dental cleaning for Alice Smith',
        description: 'Routine 6-month dental checkup and prophylaxis cleaning.',
        start: DateTime(now.year, now.month, now.day, 9, 30),
        end: DateTime(now.year, now.month, now.day, 10, 15),
        location: 'Room 201 - Dental Care Clinic',
        status: 'confirmed',
      ),
      Appointment(
        id: 'mock_appt_2',
        title: 'Cardiology consultation for John Doe',
        description: 'Echocardiogram review and medication follow-up discussion.',
        start: DateTime(now.year, now.month, now.day, 14, 0),
        end: DateTime(now.year, now.month, now.day, 14, 45),
        location: 'Building B - Cardio Center',
        status: 'confirmed',
      ),
      Appointment(
        id: 'mock_appt_3',
        title: 'General physical checkup for Sarah Miller',
        description: 'Annual wellness exam and comprehensive metabolic lab panel.',
        start: DateTime(now.year, now.month, now.day + 1, 10, 0),
        end: DateTime(now.year, now.month, now.day + 1, 11, 0),
        location: 'Primary Care - Suite A',
        status: 'confirmed',
      ),
      Appointment(
        id: 'mock_appt_4',
        title: 'Orthopedic post-op check for Kevin Watson',
        description: 'Knee arthroscopy recovery progress evaluation and suture check.',
        start: DateTime(now.year, now.month, now.day + 2, 11, 15),
        end: DateTime(now.year, now.month, now.day + 2, 11, 45),
        location: 'Physical Rehab Facility',
        status: 'confirmed',
      ),
      Appointment(
        id: 'mock_appt_5',
        title: 'Pediatric wellness exam for Emily Davis',
        description: 'Standard 4-year-old child wellness check and immunization update.',
        start: DateTime(now.year, now.month, now.day + 3, 15, 30),
        end: DateTime(now.year, now.month, now.day + 3, 16, 15),
        location: 'Pediatrics Department - Room 105',
        status: 'confirmed',
      ),
    ];
  }
}

class CalendarException implements Exception {
  final String message;
  CalendarException(this.message);

  @override
  String toString() => message;
}
