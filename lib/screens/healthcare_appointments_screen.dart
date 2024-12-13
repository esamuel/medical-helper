import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/healthcare_appointment.dart';
import '../services/healthcare_appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthcareAppointmentsScreen extends StatefulWidget {
  const HealthcareAppointmentsScreen({super.key});

  @override
  State<HealthcareAppointmentsScreen> createState() => _HealthcareAppointmentsScreenState();
}

class _HealthcareAppointmentsScreenState
    extends State<HealthcareAppointmentsScreen> {
  final HealthcareAppointmentService _appointmentService =
      HealthcareAppointmentService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthcare Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Implement calendar view
            },
          ),
        ],
      ),
      body: StreamBuilder<List<HealthcareAppointment>>(
        stream: _appointmentService.getUpcomingAppointments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No upcoming appointments',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAppointmentDialog(context),
                    child: const Text('Add Appointment'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppointmentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentCard(HealthcareAppointment appointment) {
    final now = DateTime.now();
    final isUpcoming = appointment.appointmentDate.isAfter(now);
    final isPast = appointment.appointmentDate.isBefore(now);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUpcoming
              ? Colors.blue
              : isPast
                  ? Colors.grey
                  : Colors.green,
          child: Icon(
            isUpcoming
                ? Icons.calendar_today
                : isPast
                    ? Icons.calendar_today_outlined
                    : Icons.check_circle,
            color: Colors.white,
          ),
        ),
        title: Text(
          appointment.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${appointment.provider} - ${appointment.speciality}'),
            Text(
              _dateFormat.format(appointment.appointmentDate),
              style: TextStyle(
                color: isUpcoming ? Colors.blue : Colors.grey,
              ),
            ),
            if (appointment.location.isNotEmpty)
              Text('📍 ${appointment.location}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showAppointmentDialog(context, appointment: appointment);
                break;
              case 'delete':
                _showDeleteConfirmation(context, appointment);
                break;
            }
          },
        ),
        onTap: () => _showAppointmentDetails(context, appointment),
      ),
    );
  }

  Future<void> _showAppointmentDialog(BuildContext context,
      {HealthcareAppointment? appointment}) async {
    final formKey = GlobalKey<FormState>();
    final titleController =
        TextEditingController(text: appointment?.title ?? '');
    final providerController =
        TextEditingController(text: appointment?.provider ?? '');
    final specialityController =
        TextEditingController(text: appointment?.speciality ?? '');
    final locationController =
        TextEditingController(text: appointment?.location ?? '');
    final notesController =
        TextEditingController(text: appointment?.notes ?? '');
    
    DateTime selectedDate = appointment?.appointmentDate ?? DateTime.now();
    bool hasReminder = appointment?.hasReminder ?? true;
    int reminderMinutes = appointment?.reminderMinutes ?? 60;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(appointment == null ? 'Add Appointment' : 'Edit Appointment'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: providerController,
                  decoration: const InputDecoration(
                      labelText: 'Doctor/Institution'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: specialityController,
                  decoration: const InputDecoration(labelText: 'Speciality'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date & Time'),
                  subtitle: Text(_dateFormat.format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      }
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Reminder'),
                  value: hasReminder,
                  onChanged: (value) => setState(() => hasReminder = value),
                ),
                if (hasReminder)
                  DropdownButtonFormField<int>(
                    value: reminderMinutes,
                    items: [
                      const DropdownMenuItem(
                          value: 15, child: Text('15 minutes before')),
                      const DropdownMenuItem(
                          value: 30, child: Text('30 minutes before')),
                      const DropdownMenuItem(
                          value: 60, child: Text('1 hour before')),
                      const DropdownMenuItem(
                          value: 120, child: Text('2 hours before')),
                      const DropdownMenuItem(
                          value: 1440, child: Text('1 day before')),
                    ],
                    onChanged: (value) =>
                        setState(() => reminderMinutes = value ?? 60),
                  ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be logged in to add appointments')),
                  );
                  return;
                }

                final newAppointment = HealthcareAppointment(
                  id: appointment?.id,
                  title: titleController.text,
                  provider: providerController.text,
                  speciality: specialityController.text,
                  appointmentDate: selectedDate,
                  location: locationController.text,
                  notes: notesController.text,
                  hasReminder: hasReminder,
                  reminderMinutes: reminderMinutes,
                  userId: user.uid,
                  createdAt: appointment?.createdAt ?? DateTime.now(),
                );

                try {
                  if (appointment == null) {
                    print('Adding new appointment: ${newAppointment.toMap()}'); 
                    await _appointmentService.addAppointment(newAppointment);
                    print('Successfully added appointment'); 
                  } else {
                    print('Updating appointment: ${newAppointment.toMap()}'); 
                    await _appointmentService.updateAppointment(newAppointment);
                    print('Successfully updated appointment'); 
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          appointment == null 
                              ? 'Appointment added successfully' 
                              : 'Appointment updated successfully'
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error saving appointment: $e'); 
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, HealthcareAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _appointmentService.deleteAppointment(appointment.id!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAppointmentDetails(
      BuildContext context, HealthcareAppointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appointment.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${appointment.provider} - ${appointment.speciality}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(_dateFormat.format(appointment.appointmentDate)),
              ],
            ),
            if (appointment.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Text(appointment.location),
                ],
              ),
            ],
            if (appointment.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(appointment.notes!),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement navigation
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Navigate'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add to calendar
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Add to Calendar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
