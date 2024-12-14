import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:js' as js;
import 'package:js/js_util.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService() {
    initializeService();
  }

  Future<void> initializeService() async {
    if (kIsWeb) {
      await _initializeWebNotifications();
    } else {
      await _initializeTimeZone();
      await _initializeNotifications();
    }
  }

  Future<void> _initializeWebNotifications() async {
    // Web notifications are handled through the browser's API
    if (js.context.hasProperty('Notification')) {
      debugPrint('Web notifications are supported');
    } else {
      debugPrint('Web notifications are not supported');
    }
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<String?> requestPermissions() async {
    if (kIsWeb) {
      try {
        if (js.context.hasProperty('Notification')) {
          final result = await promiseToFuture(js.context.callMethod('eval', ['''
            (async function() {
              if ("Notification" in window) {
                const permission = await Notification.requestPermission();
                return permission;
              }
              return "denied";
            })()
          ''']));
          
          debugPrint('Web notification permission result: $result');
          return result as String;
        } else {
          debugPrint('Notifications not supported in this browser');
          return 'not_supported';
        }
      } catch (e) {
        debugPrint('Error requesting web notification permission: $e');
        return 'error';
      }
    } else if (_notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>() != null) {
      final granted = await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted == true ? 'granted' : 'denied';
    }
    return null;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      try {
        if (js.context.hasProperty('Notification')) {
          js.context.callMethod('eval', ['''
            (function() {
              if ("Notification" in window && Notification.permission === "granted") {
                new Notification("$title", { 
                  body: "$body",
                  icon: "/favicon.ico"
                });
              }
            })();
          ''']);
        }
      } catch (e) {
        debugPrint('Error showing web notification: $e');
      }
    } else {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Notifications',
            channelDescription: 'Default notification channel',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) {
      // Web platform doesn't support scheduled notifications directly
      // You might want to implement a custom solution using service workers
      debugPrint('Scheduled notifications are not supported on web');
      return;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription: 'Channel for scheduled notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!kIsWeb) {
      await _notifications.cancel(id);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!kIsWeb) {
      await _notifications.cancelAll();
    }
  }

  Future<void> cancelMedicationReminders(String medicationId) async {
    if (!kIsWeb) {
      final notificationId = medicationId.hashCode;
      await cancelNotification(notificationId);
    }
  }

  Future<void> scheduleMedicationReminders(medication) async {
    if (!kIsWeb) {
      final notificationId = medication.id.hashCode;
      
      await scheduleNotification(
        id: notificationId,
        title: 'Time to take ${medication.name}',
        body: 'Take ${medication.dosage} ${medication.instructions}',
        scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
      );
    }
  }
} 