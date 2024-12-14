import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_contact.dart';
import '../models/healthcare_appointment.dart';
import '../constants/relationship_types.dart';
import '../services/emergency_contact_service.dart';
import '../services/healthcare_appointment_service.dart';
import 'package:intl/intl.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> with SingleTickerProviderStateMixin {
  final EmergencyContactService _contactService = EmergencyContactService();
  final HealthcareAppointmentService _appointmentService = HealthcareAppointmentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAuthentication();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkAuthentication() {
    final user = _auth.currentUser;
    print('Current user: ${user?.uid}'); // Debug print
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Medical Helper'),
        ),
        body: const Center(
          child: Text('Please sign in to access your medical information'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Helper'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.contact_phone),
              text: 'Emergency Contacts',
            ),
            Tab(
              icon: Icon(Icons.calendar_today),
              text: 'Appointments',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmergencyContactsTab(),
          _buildAppointmentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showContactDialog(context);
          } else {
            _showAppointmentDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmergencyContactsTab() {
    return StreamBuilder<List<EmergencyContact>>(
      stream: _contactService.getContacts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contacts = snapshot.data ?? [];

        if (contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No emergency contacts yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showContactDialog(context),
                  child: const Text('Add Contact'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return _buildContactCard(contact);
          },
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    return StreamBuilder<List<HealthcareAppointment>>(
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
                const Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
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
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Dismissible(
      key: Key(contact.id ?? ''),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Contact'),
            content: Text('Are you sure you want to delete ${contact.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await _contactService.deleteContact(contact.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${contact.name} deleted')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting contact: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: contact.isPrimaryContact 
                ? Theme.of(context).primaryColor 
                : Colors.grey,
            child: Text(
              contact.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(contact.name),
          subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () => _makePhoneCall(contact.phoneNumber),
              ),
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: () => _sendSMS(contact.phoneNumber),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showContactDialog(context, contact: contact),
              ),
            ],
          ),
          onTap: () => _showContactDetails(context, contact),
        ),
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
                _showDeleteAppointmentConfirmation(context, appointment);
                break;
            }
          },
        ),
        onTap: () => _showAppointmentDetails(context, appointment),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showContactDetails(BuildContext context, EmergencyContact contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Relationship: ${contact.relationship}'),
            Text('Phone: ${contact.phoneNumber}'),
            if (contact.notes != null && contact.notes!.isNotEmpty)
              Text('Notes: ${contact.notes}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(contact.phoneNumber),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendSMS(contact.phoneNumber),
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showContactDialog(context, contact: contact),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, {EmergencyContact? contact}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = contact != null;
    
    String name = contact?.name ?? '';
    String phoneNumber = contact?.phoneNumber ?? '';
    String relationship = contact?.relationship ?? RelationshipTypes.relationships[0];
    String? notes = contact?.notes;
    bool isPrimaryContact = contact?.isPrimaryContact ?? false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Contact' : 'Add Emergency Contact'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        icon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                      onSaved: (value) => name = value!,
                    ),
                    TextFormField(
                      initialValue: phoneNumber,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        icon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                      onSaved: (value) => phoneNumber = value!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        icon: Icon(Icons.family_restroom),
                      ),
                      value: relationship,
                      items: RelationshipTypes.relationships
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? value) {
                        setDialogState(() {
                          relationship = value!;
                        });
                      },
                    ),
                    TextFormField(
                      initialValue: notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        icon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                      onSaved: (value) => notes = value,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Primary Contact'),
                      subtitle: const Text('Mark as primary emergency contact'),
                      value: isPrimaryContact,
                      onChanged: (bool value) {
                        setDialogState(() {
                          isPrimaryContact = value;
                        });
                      },
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
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final updatedContact = EmergencyContact(
                      id: contact?.id,
                      name: name,
                      phoneNumber: phoneNumber,
                      relationship: relationship,
                      notes: notes,
                      isPrimaryContact: isPrimaryContact,
                      createdAt: contact?.createdAt,
                    );

                    try {
                      if (isEditing) {
                        await _contactService.updateContact(updatedContact);
                      } else {
                        await _contactService.addContact(updatedContact);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing 
                                ? 'Contact updated successfully' 
                                : 'Contact added successfully'
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAppointmentDialog(BuildContext context, {HealthcareAppointment? appointment}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: appointment?.title ?? '');
    final providerController = TextEditingController(text: appointment?.provider ?? '');
    final specialityController = TextEditingController(text: appointment?.speciality ?? '');
    final locationController = TextEditingController(text: appointment?.location ?? '');
    final notesController = TextEditingController(text: appointment?.notes ?? '');
    
    DateTime selectedDate = appointment?.appointmentDate ?? DateTime.now();
    bool hasReminder = appointment?.hasReminder ?? true;
    int reminderMinutes = appointment?.reminderMinutes ?? 60;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment == null ? 'Add Appointment' : 'Edit Appointment'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: providerController,
                  decoration: const InputDecoration(labelText: 'Doctor/Institution'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: specialityController,
                  decoration: const InputDecoration(labelText: 'Speciality'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
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
                        setState(() {});
                      }
                    }
                  },
                ),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                SwitchListTile(
                  title: const Text('Reminder'),
                  value: hasReminder,
                  onChanged: (value) => setState(() => hasReminder = value),
                ),
                if (hasReminder)
                  DropdownButtonFormField<int>(
                    value: reminderMinutes,
                    decoration: const InputDecoration(labelText: 'Remind me before'),
                    items: [15, 30, 60, 120, 1440] // 15min, 30min, 1h, 2h, 1day
                        .map((minutes) => DropdownMenuItem(
                              value: minutes,
                              child: Text(_formatReminderDuration(minutes)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => reminderMinutes = value);
                      }
                    },
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
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
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
                    userId: _auth.currentUser!.uid,
                    createdAt: appointment?.createdAt ?? DateTime.now(),
                  );

                  if (appointment == null) {
                    await _appointmentService.addAppointment(newAppointment);
                  } else {
                    await _appointmentService.updateAppointment(newAppointment);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        appointment == null
                            ? 'Appointment added successfully'
                            : 'Appointment updated successfully',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAppointmentConfirmation(
      BuildContext context, HealthcareAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text(
            'Are you sure you want to delete the appointment "${appointment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _appointmentService.deleteAppointment(appointment.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appointment.title} deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppointmentDetails(BuildContext context, HealthcareAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: ${appointment.provider}'),
            Text('Speciality: ${appointment.speciality}'),
            Text('Date: ${_dateFormat.format(appointment.appointmentDate)}'),
            Text('Location: ${appointment.location}'),
            if (appointment.notes?.isNotEmpty ?? false)
              Text('Notes: ${appointment.notes}'),
            if (appointment.hasReminder)
              Text('Reminder: ${_formatReminderDuration(appointment.reminderMinutes ?? 60)} before'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatReminderDuration(int minutes) {
    if (minutes == 1440) return '1 day';
    if (minutes == 60) return '1 hour';
    if (minutes == 120) return '2 hours';
    return '$minutes minutes';
  }
}