// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_record.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _calls =>
      _db.collection('calls');

  /// Real-time stream of all calls, newest first.
  Stream<List<CallRecord>> callsStream() {
    return _calls
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CallRecord.fromFirestore(d.data(), d.id)).toList());
  }

  /// One-time fetch of calls from today (midnight to now).
  Future<List<CallRecord>> getCallsToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final snap = await _calls
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp',
            isLessThan: Timestamp.fromDate(start.add(const Duration(days: 1))))
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) => CallRecord.fromFirestore(d.data(), d.id))
        .toList();
  }

  /// Fetch a single call by doc ID.
  Future<CallRecord?> getCall(String id) async {
    final doc = await _calls.doc(id).get();
    if (!doc.exists) return null;
    return CallRecord.fromFirestore(doc.data()!, doc.id);
  }

  /// Stream of failed + transferred calls only (Alerts tab).
  Stream<List<CallRecord>> alertCallsStream() {
    return _calls
        .where('outcome', whereIn: ['failed', 'transferred'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CallRecord.fromFirestore(d.data(), d.id)).toList());
  }
}
