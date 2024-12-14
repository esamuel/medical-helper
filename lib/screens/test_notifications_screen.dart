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
          // Permissions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Permissions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final result = await notificationService.requestPermissions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notification permission status: ${result ?? "unknown"}'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Request Notification Permission'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
              await notificationService.showNotification(
                id: 1,
                title: 'Test Notification',
                body: 'This is an immediate test notification',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Immediate notification sent')),
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
              await notificationService.scheduleNotification(
                id: 2,
                title: 'Delayed Notification',
                body: 'This notification was scheduled for 30 seconds',
                scheduledDate: scheduledTime,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification scheduled for 30 seconds')),
                );
              }
            },
            icon: const Icon(Icons.timer),
            label: const Text('Schedule 30s Delayed Notification'),
          ),
          const SizedBox(height: 8),

          // 1 Minute Notification
          ElevatedButton.icon(
            onPressed: () async {
              final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
              await notificationService.scheduleNotification(
                id: 3,
                title: '1 Minute Notification',
                body: 'This notification was scheduled for 1 minute',
                scheduledDate: scheduledTime,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification scheduled for 1 minute')),
                );
              }
            },
            icon: const Icon(Icons.access_time),
            label: const Text('Schedule 1 Minute Notification'),
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

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Troubleshooting Section
          Text(
            'Troubleshooting',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If notifications are not working:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Check if app notifications are enabled in device settings'),
                  const Text('2. Ensure "All Notifications" is turned on above'),
                  const Text('3. Try restarting the app'),
                  const Text('4. Check if Do Not Disturb is enabled on your device'),
                ],
              ),
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