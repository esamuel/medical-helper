import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import 'add_medication_screen.dart';
import '../../services/notification_service.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final medicationService = context.read<MedicationService>();
    final user = context.watch<User?>();
    
    if (user == null) {
      debugPrint('User is null in MedicationsScreen');
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view medications'),
        ),
      );
    }
    
    debugPrint('Building MedicationsScreen for user: ${user.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
      ),
      body: StreamBuilder<List<MedicationModel>>(
        stream: medicationService.getMedicationsForUser(user.uid),
        builder: (context, snapshot) {
          debugPrint('StreamBuilder state: ${snapshot.connectionState}');
          debugPrint('StreamBuilder hasData: ${snapshot.hasData}');
          debugPrint('StreamBuilder hasError: ${snapshot.hasError}');
          debugPrint('StreamBuilder data length: ${snapshot.data?.length ?? 0}');
          
          if (snapshot.hasError) {
            debugPrint('StreamBuilder error: ${snapshot.error}');
            debugPrint('StreamBuilder error stack trace: ${snapshot.stackTrace}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading medications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force a rebuild of the screen
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('StreamBuilder waiting for data...');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final medications = snapshot.data ?? [];
          debugPrint('StreamBuilder received ${medications.length} medications');
          medications.forEach((med) => debugPrint('Medication in view: ${med.name} (${med.id})'));

          if (medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No medications added yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _addMedication(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medication'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editMedication(context, medication),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteMedication(
                                  context,
                                  medicationService,
                                  medication,
                                ),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dosage: ${medication.dosage}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Frequency: ${medication.frequencyText}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (medication.instructions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Instructions:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          medication.instructions,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Start Date: ${_formatDate(medication.startDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Taking Times: ${medication.formatTakingTimes()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMedication(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _addMedication(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
      ),
    );
  }

  void _editMedication(BuildContext context, MedicationModel medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          medicationToEdit: medication,
        ),
      ),
    );
  }

  Future<void> _deleteMedication(
    BuildContext context,
    MedicationService medicationService,
    MedicationModel medication,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text(
          'Are you sure you want to delete ${medication.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Cancel notifications before deleting
        final notificationService = context.read<NotificationService>();
        await notificationService.cancelMedicationReminders(medication.id);
        
        // Delete the medication
        await medicationService.deleteMedication(medication.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting medication: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting medication: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 