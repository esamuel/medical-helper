import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final MedicationModel? medicationToEdit;

  const AddMedicationScreen({
    super.key,
    this.medicationToEdit,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  late String _name;
  late String _dosage;
  late MedicationFrequency _frequency;
  late String _instructions;
  late DateTime _startDate;
  late TimeOfDay _defaultTime;
  
  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing
    final medication = widget.medicationToEdit;
    _name = medication?.name ?? '';
    _dosage = medication?.dosage ?? '';
    _frequency = medication?.frequency ?? MedicationFrequency.daily;
    _instructions = medication?.instructions ?? '';
    _startDate = medication?.startDate ?? DateTime.now();
    _defaultTime = medication?.defaultTime ?? const TimeOfDay(hour: 8, minute: 0);
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      
      try {
        final medicationService = context.read<MedicationService>();
        final notificationService = context.read<NotificationService>();
        final user = context.read<User?>();
        
        if (user == null) {
          debugPrint('Error: User is null when trying to save medication');
          throw Exception('User not logged in');
        }
        
        debugPrint('Creating medication for user: ${user.uid}');
        
        final medication = MedicationModel(
          id: widget.medicationToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: _name,
          dosage: _dosage,
          frequency: _frequency,
          instructions: _instructions,
          startDate: _startDate,
          userId: user.uid,
          defaultTime: _defaultTime,
        );

        debugPrint('Saving medication with data: ${medication.toMap()}');

        String? medicationId;
        if (widget.medicationToEdit != null) {
          debugPrint('Updating existing medication with ID: ${medication.id}');
          await medicationService.updateMedication(medication);
          medicationId = medication.id;
          debugPrint('Successfully updated medication');
        } else {
          debugPrint('Adding new medication');
          medicationId = await medicationService.addMedication(medication);
          debugPrint('Successfully added medication with ID: $medicationId');
        }

        // Try to schedule notifications, but don't let failures prevent saving
        try {
          if (_frequency != MedicationFrequency.asNeeded) {
            debugPrint('Scheduling notifications for medication: $medicationId');
            await notificationService.scheduleMedicationReminders(
              medication.copyWith(id: medicationId),
            );
            debugPrint('Successfully scheduled notifications');
          }
        } catch (e) {
          debugPrint('Failed to schedule notifications: $e');
          // Don't rethrow - we don't want notification failures to prevent medication saving
        }
        
        if (mounted) {
          debugPrint('Navigating back to medications list');
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.medicationToEdit != null 
                ? 'Medication updated successfully'
                : 'Medication added successfully'
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stackTrace) {
        debugPrint('Error saving medication: $e');
        debugPrint('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ${widget.medicationToEdit != null ? 'updating' : 'adding'} medication: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicationToEdit != null ? 'Edit Medication' : 'Add Medication'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication),
                      ),
                      initialValue: _name,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medication name';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 1 pill, 5ml',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      initialValue: _dosage,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage';
                        }
                        return null;
                      },
                      onSaved: (value) => _dosage = value!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<MedicationFrequency>(
                      value: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: MedicationFrequency.values.map((frequency) {
                        final name = frequency.toString().split('.').last;
                        final displayName = name.replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (match) => ' ${match.group(1)}',
                        ).toLowerCase();
                        
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _frequency = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Take with food',
                        prefixIcon: Icon(Icons.description),
                      ),
                      initialValue: _instructions,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onSaved: (value) => _instructions = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    if (_frequency != MedicationFrequency.asNeeded) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _defaultTime,
                          );
                          if (picked != null) {
                            setState(() => _defaultTime = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'First Taking Time',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            '${_defaultTime.hour.toString().padLeft(2, '0')}:${_defaultTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Other times will be automatically set based on frequency:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MedicationModel(
                          id: '',
                          name: '',
                          dosage: '',
                          frequency: _frequency,
                          instructions: '',
                          startDate: DateTime.now(),
                          userId: '',
                          defaultTime: _defaultTime,
                        ).formatTakingTimes(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveMedication,
                      icon: const Icon(Icons.save),
                      label: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _isLoading ? 'Saving...' : (widget.medicationToEdit != null ? 'Update Medication' : 'Save Medication'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 