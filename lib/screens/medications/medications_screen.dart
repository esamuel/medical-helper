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
    final user = context.watch<User?>();
    final theme = Theme.of(context);

    if (user == null) {
      return Center(
        child: Text(
          'Please log in to view medications',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    // Create a new MedicationService instance with the current user ID
    final medicationService = Provider.of<MedicationService>(context);
    debugPrint('Current user ID: ${user.uid}');
    debugPrint('MedicationService user ID: ${medicationService.userId}');

    return Stack(
      children: [
        StreamBuilder<List<MedicationModel>>(
          stream: medicationService.getMedications(),
          builder: (context, snapshot) {
            debugPrint('StreamBuilder state: ${snapshot.connectionState}');
            debugPrint('StreamBuilder hasData: ${snapshot.hasData}');
            debugPrint('StreamBuilder error: ${snapshot.error}');
            if (snapshot.hasData) {
              debugPrint('Number of medications: ${snapshot.data!.length}');
            }

            if (snapshot.hasError) {
              debugPrint('Error in MedicationsScreen: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading medications',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final medications = snapshot.data ?? [];
            debugPrint('Medications data: $medications');

            if (medications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medications added yet',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add a medication',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
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
                debugPrint('Building medication card for: ${medication.name}');
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                medication.name,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () =>
                                      _editMedication(context, medication),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed: () => _deleteMedication(
                                    context,
                                    medication,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dosage: ${medication.dosage}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Frequency: ${medication.frequencyText}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (medication.instructions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Instructions: ${medication.instructions}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Start Date: ${_formatDate(medication.startDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _addMedication(context),
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
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

  void _deleteMedication(
    BuildContext context,
    MedicationModel medication,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final medicationService = context.read<MedicationService>();
              Navigator.pop(context);
              try {
                await medicationService.deleteMedication(medication.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${medication.name} deleted'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error deleting medication'),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
