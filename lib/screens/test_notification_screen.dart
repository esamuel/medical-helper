import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class TestNotificationScreen extends StatefulWidget {
  const TestNotificationScreen({super.key});

  @override
  State<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  bool _isLoading = false;
  String _status = '';
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      setState(() {
        _status = 'Notifications initialized';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing notifications: $e';
      });
    }
  }

  Future<void> _scheduleNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Scheduling notification...';
    });

    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 2));
      await _notificationService.scheduleMedicationReminder(
        id: 1,
        medicationName: 'Test Medicine',
        dosage: '1 pill',
        scheduledTime: scheduledTime,
      );
      
      if (mounted) {
        setState(() {
          _status = 'Notification scheduled for ${scheduledTime.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification scheduled for 2 seconds from now'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelNotifications() async {
    setState(() {
      _isLoading = true;
      _status = 'Canceling notifications...';
    });

    try {
      await _notificationService.cancelAllReminders();
      
      if (mounted) {
        setState(() {
          _status = 'All notifications cancelled';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cancelled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _scheduleNotification,
                      child: const Text('Test Notification (2s)'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cancelNotifications,
                      child: const Text('Cancel All Notifications'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 