// lib/models/alert.dart

import 'call_record.dart';

enum AlertSeverity { high, medium, low }

class Alert {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final AlertSeverity severity;
  final CallRecord? relatedCall;

  Alert({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.severity,
    this.relatedCall,
  });

  factory Alert.fromCallRecord(CallRecord call) {
    return Alert(
      id: 'alert_${call.id}',
      title: call.outcome == 'failed' ? 'Call Failed' : 'Call Transferred',
      body:
          'Patient ${call.patientNumber} — ${call.summary ?? "No summary available"}',
      timestamp: call.timestamp,
      severity:
          call.outcome == 'failed' ? AlertSeverity.high : AlertSeverity.medium,
      relatedCall: call,
    );
  }
}
