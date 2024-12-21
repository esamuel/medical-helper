import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take medications',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  NotificationService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Initializing NotificationService');
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  Future<void> requestPermissions() async {
    await initialize();
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? instructions,
  }) async {
    await initialize();
    debugPrint(
        'Scheduling single reminder for medication: $medicationName at $scheduledTime');

    try {
      await _notifications.zonedSchedule(
        id,
        'Time to take $medicationName',
        'Take $dosage${instructions != null ? ' - $instructions' : ''}',
        tz.TZDateTime.from(scheduledTime, tz.local),
        _notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
          'Successfully scheduled single reminder for $medicationName at $scheduledTime');
    } catch (e, stackTrace) {
      debugPrint('Error scheduling single medication reminder: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> scheduleMedicationReminders(MedicationModel medication) async {
    await initialize();
    debugPrint('Scheduling reminders for medication: ${medication.id}');

    try {
      // Cancel existing reminders for this medication
      await cancelMedicationReminders(medication.id);

      if (medication.frequency == MedicationFrequency.asNeeded) {
        debugPrint('Medication is as-needed, skipping reminder scheduling');
        return;
      }

      final now = DateTime.now();

      for (final time in medication.takingTimes) {
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // If the time has passed for today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        // Create unique ID for each reminder time
        final notificationId =
            '${medication.id}_${time.hour}_${time.minute}'.hashCode;

        debugPrint(
            'Scheduling notification for ${medication.name} at $scheduledDate');

        // Schedule the notification
        await _notifications.zonedSchedule(
          notificationId,
          'Time to take ${medication.name}',
          'Take ${medication.dosage}${medication.instructions.isNotEmpty ? ' - ${medication.instructions}' : ''}',
          tz.TZDateTime.from(scheduledDate, tz.local),
          _notificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        debugPrint(
            'Successfully scheduled notification for ${medication.name} at $scheduledDate');
      }
    } catch (e, stackTrace) {
      debugPrint('Error scheduling medication reminders: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - we don't want notification failures to prevent medication saving
    }
  }

  Future<void> cancelMedicationReminders(String medicationId) async {
    await initialize();
    debugPrint('Canceling reminders for medication: $medicationId');

    try {
      final notifications = await _notifications.pendingNotificationRequests();
      for (var notification in notifications) {
        if (notification.id
            .toString()
            .startsWith(medicationId.hashCode.toString())) {
          await _notifications.cancel(notification.id);
          debugPrint('Canceled notification with ID: ${notification.id}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error canceling medication reminders: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - we don't want notification failures to prevent medication saving
    }
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    try {
      await _notifications.cancelAll();
      debugPrint('Canceled all notifications');
    } catch (e, stackTrace) {
      debugPrint('Error canceling all reminders: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
