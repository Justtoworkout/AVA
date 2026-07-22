// lib/models/call_record.dart

class CallRecord {
  final String id;
  final String patientNumber;
  final DateTime timestamp;
  final int durationSeconds;
  final String outcome; // 'booked' | 'failed' | 'transferred' | 'completed'
  final String transcript;
  final String? recordingUrl;
  final String? summary;

  CallRecord({
    required this.id,
    required this.patientNumber,
    required this.timestamp,
    required this.durationSeconds,
    required this.outcome,
    required this.transcript,
    this.recordingUrl,
    this.summary,
  });

  factory CallRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return CallRecord(
      id: id,
      patientNumber: data['patientNumber'] ?? '',
      timestamp: (data['timestamp'] as dynamic).toDate(),
      durationSeconds: data['durationSeconds'] ?? 0,
      outcome: data['outcome'] ?? 'completed',
      transcript: data['transcript'] ?? '',
      recordingUrl: data['recordingUrl'],
      summary: data['summary'],
    );
  }

  Map<String, dynamic> toMap() => {
        'patientNumber': patientNumber,
        'timestamp': timestamp,
        'durationSeconds': durationSeconds,
        'outcome': outcome,
        'transcript': transcript,
        'recordingUrl': recordingUrl,
        'summary': summary,
      };
}
