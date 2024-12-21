import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final MedicationModel? medicationToEdit;

  const AddMedicationScreen({
    Key? key,
    this.medicationToEdit,
  }) : super(key: key);

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
    _defaultTime =
        medication?.defaultTime ?? const TimeOfDay(hour: 8, minute: 0);
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
          id: widget.medicationToEdit?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
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
            debugPrint(
                'Scheduling notifications for medication: $medicationId');
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
                  : 'Medication added successfully'),
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
              content: Text(
                  'Error ${widget.medicationToEdit != null ? 'updating' : 'adding'} medication: $e'),
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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          widget.medicationToEdit != null
              ? 'Edit Medication'
              : 'Add Medication',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF80CBC4)))
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
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF80CBC4)),
                        ),
                        prefixIcon:
                            Icon(Icons.medication, color: Color(0xFF80CBC4)),
                      ),
                      style: const TextStyle(color: Colors.white),
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
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF80CBC4)),
                        ),
                        hintText: 'e.g., 1 pill, 5ml',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon:
                            Icon(Icons.straighten, color: Color(0xFF80CBC4)),
                      ),
                      style: const TextStyle(color: Colors.white),
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
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF80CBC4)),
                        ),
                        prefixIcon:
                            Icon(Icons.schedule, color: Color(0xFF80CBC4)),
                      ),
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      items: MedicationFrequency.values.map((frequency) {
                        final name = frequency.toString().split('.').last;
                        final displayName = name
                            .replaceAllMapped(
                              RegExp(r'([A-Z])'),
                              (match) => ' ${match.group(1)}',
                            )
                            .toLowerCase();

                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(
                            displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
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
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF80CBC4)),
                        ),
                        hintText: 'e.g., Take with food',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon:
                            Icon(Icons.description, color: Color(0xFF80CBC4)),
                      ),
                      style: const TextStyle(color: Colors.white),
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
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF80CBC4)),
                          ),
                          prefixIcon: Icon(Icons.calendar_today,
                              color: Color(0xFF80CBC4)),
                        ),
                        child: Text(
                          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white),
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
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF80CBC4)),
                            ),
                            prefixIcon: Icon(Icons.access_time,
                                color: Color(0xFF80CBC4)),
                          ),
                          child: Text(
                            '${_defaultTime.hour.toString().padLeft(2, '0')}:${_defaultTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Other times will be automatically set based on frequency:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveMedication,
                      icon: const Icon(Icons.save, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        padding: const EdgeInsets.all(16.0),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      label: Text(
                        _isLoading
                            ? 'Saving...'
                            : (widget.medicationToEdit != null
                                ? 'Update Medication'
                                : 'Save Medication'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
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
