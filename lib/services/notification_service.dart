// lib/services/notification_service.dart
//
// Listens to FirestoreService.alertCallsStream() and fires a local push
// notification whenever a new failed/transferred call appears.
// Uses flutter_local_notifications (Android + iOS).

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/call_record.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<List<CallRecord>>? _sub;
  final _seen = <String>{};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    _startListening();
  }

  bool _firstEmission = true;

  void _startListening() {
    _sub = FirestoreService().alertCallsStream().listen((calls) {
      if (_firstEmission) {
        // Populate seen set on first load without notifying
        _firstEmission = false;
        for (final call in calls) {
          _seen.add(call.id);
        }
        return;
      }
      // Subsequent emissions: only notify for IDs not yet seen
      for (final call in calls) {
        if (_seen.contains(call.id)) continue;
        _seen.add(call.id);
        _fire(call);
      }
    });
  }

  Future<void> _fire(CallRecord call) async {
    final title = call.outcome == 'failed'
        ? '⚠️ Call Failed'
        : '🔁 Call Transferred';
    final body = 'Patient ${call.patientNumber}'
        '${call.summary != null ? ' — ${call.summary}' : ''}';

    await _plugin.show(
      call.id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ava_alerts',
          'AVA Alerts',
          channelDescription: 'Alerts for failed or transferred calls',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Call this from main.dart after Firebase.initializeApp().
  Future<void> showAlertNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ava_alerts',
          'AVA Alerts',
          channelDescription: 'Alerts for failed or transferred calls',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void dispose() {
    _sub?.cancel();
  }
}
