import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/notification_provider.dart';

class TestNotificationsScreen extends StatelessWidget {
  const TestNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = context.read<NotificationService>();
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow('All Notifications', notificationProvider.allNotifications),
                  _buildStatusRow('Medication Reminders', notificationProvider.medicationReminders),
                  _buildStatusRow('Health Tracking', notificationProvider.healthTracking),
                  _buildStatusRow('Appointments', notificationProvider.appointments),
                  _buildStatusRow('Emergency Updates', notificationProvider.emergencyUpdates),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Test Buttons
          Text(
            'Test Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Immediate Notification
          ElevatedButton.icon(
            onPressed: () async {
              await notificationService.showEmergencyNotification(
                id: 1,
                title: 'Test Emergency',
                body: 'This is a test emergency notification',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency notification sent')),
                );
              }
            },
            icon: const Icon(Icons.notification_important),
            label: const Text('Send Immediate Notification'),
          ),
          const SizedBox(height: 8),

          // Delayed Notification (30 seconds)
          ElevatedButton.icon(
            onPressed: () async {
              final scheduledTime = DateTime.now().add(const Duration(seconds: 30));
              await notificationService.scheduleMedicationReminder(
                id: 2,
                title: 'Test Medication',
                body: 'This is a test medication reminder (30 seconds delay)',
                scheduledDate: scheduledTime,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medication reminder scheduled for 30 seconds')),
                );
              }
            },
            icon: const Icon(Icons.timer),
            label: const Text('Schedule 30s Delayed Notification'),
          ),
          const SizedBox(height: 8),

          // Health Tracking Reminder
          ElevatedButton.icon(
            onPressed: () async {
              final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
              await notificationService.scheduleHealthTrackingReminder(
                id: 3,
                title: 'Test Health Tracking',
                body: 'Time to check your blood pressure (1 minute delay)',
                scheduledDate: scheduledTime,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Health tracking reminder scheduled for 1 minute')),
                );
              }
            },
            icon: const Icon(Icons.favorite),
            label: const Text('Schedule Health Tracking Reminder'),
          ),
          const SizedBox(height: 8),

          // Appointment Reminder
          ElevatedButton.icon(
            onPressed: () async {
              final scheduledTime = DateTime.now().add(const Duration(minutes: 2));
              await notificationService.scheduleAppointmentReminder(
                id: 4,
                title: 'Test Appointment',
                body: 'Upcoming doctor appointment (2 minutes delay)',
                scheduledDate: scheduledTime,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment reminder scheduled for 2 minutes')),
                );
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Schedule Appointment Reminder'),
          ),
          const SizedBox(height: 16),

          // Cancel Notifications
          FilledButton.icon(
            onPressed: () async {
              await notificationService.cancelAllNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cancelled')),
                );
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel All Notifications'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String title, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
} 