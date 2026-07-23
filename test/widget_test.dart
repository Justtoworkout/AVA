// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ava_app/models/appointment.dart';
import 'package:ava_app/models/call_record.dart';
import 'package:ava_app/widgets/appointment_card.dart';
import 'package:ava_app/widgets/call_list_tile.dart';
import 'package:ava_app/widgets/outcome_badge.dart';

void main() {
  testWidgets('OutcomeBadge renders booked status correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OutcomeBadge(outcome: 'booked'),
        ),
      ),
    );

    expect(find.text('Booked'), findsOneWidget);
  });

  testWidgets('AppointmentCard renders appointment details and handles tap',
      (WidgetTester tester) async {
    final appt = Appointment(
      id: 'test_1',
      title: 'Dental appointment for Kevin',
      start: DateTime.now().add(const Duration(hours: 2)),
      end: DateTime.now().add(const Duration(hours: 3)),
      location: 'Main Clinic Room 204',
      status: 'confirmed',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppointmentCard(appt: appt),
        ),
      ),
    );

    expect(find.text('Dental appointment for Kevin'), findsOneWidget);
    expect(find.text('Main Clinic Room 204'), findsOneWidget);
  });

  testWidgets('CallListTile renders call record patient number and outcome',
      (WidgetTester tester) async {
    final call = CallRecord(
      id: 'call_1',
      patientNumber: '+919876543210',
      timestamp: DateTime.now(),
      durationSeconds: 90,
      outcome: 'booked',
      transcript: 'Patient: Hello\nAVA: Booked',
      summary: 'Patient booked appointment for tomorrow at 10 AM.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallListTile(call: call),
        ),
      ),
    );

    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
  });
}
