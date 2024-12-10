import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final TimeOfDay time;
  final bool hasReminder;
  final int id;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.id,
    this.hasReminder = true,
  });
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Medication> _medications = [];
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _notificationService = NotificationService();
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _scheduleNotification(Medication medication) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      medication.time.hour,
      medication.time.minute,
    );

    await _notificationService.scheduleMedicationReminder(
      id: medication.id,
      medicationName: medication.name,
      dosage: medication.dosage,
      scheduledTime: scheduledTime,
    );
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g., 1 pill, 5ml)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency (e.g., daily, twice daily)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Reminder Time'),
                trailing: Text(_selectedTime.format(context)),
                onTap: () => _selectTime(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty &&
                  _dosageController.text.isNotEmpty &&
                  _frequencyController.text.isNotEmpty) {
                final medication = Medication(
                  id: _nextId++,
                  name: _nameController.text,
                  dosage: _dosageController.text,
                  frequency: _frequencyController.text,
                  time: _selectedTime,
                );

                setState(() {
                  _medications.add(medication);
                });

                await _scheduleNotification(medication);

                _nameController.clear();
                _dosageController.clear();
                _frequencyController.clear();
                Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medication reminder set'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _medications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No medications added',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your medications and set reminders',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final medication = _medications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.medication),
                    title: Text(medication.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dosage: ${medication.dosage}'),
                        Text('${medication.frequency} at ${medication.time.format(context)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            medication.hasReminder
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: medication.hasReminder
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          onPressed: () async {
                            if (medication.hasReminder) {
                              await _notificationService.cancelReminder(medication.id);
                            } else {
                              await _scheduleNotification(medication);
                            }
                            setState(() {
                              _medications[index] = Medication(
                                id: medication.id,
                                name: medication.name,
                                dosage: medication.dosage,
                                frequency: medication.frequency,
                                time: medication.time,
                                hasReminder: !medication.hasReminder,
                              );
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _notificationService.cancelReminder(medication.id);
                            setState(() {
                              _medications.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        child: const Icon(Icons.add),
      ),
    );
  }
} 