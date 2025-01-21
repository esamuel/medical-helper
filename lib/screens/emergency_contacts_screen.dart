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
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  _EmergencyContactsScreenState createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyContactService _contactService = EmergencyContactService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: StreamBuilder<List<EmergencyContact>>(
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
                  const Icon(Icons.contacts_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No emergency contacts',
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(context),
        child: const Icon(Icons.add),
      ),
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
                  onPressed: () =>
                      _showContactDialog(context, contact: contact),
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
    String relationship =
        contact?.relationship ?? RelationshipTypes.relationships[0];
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
                      items:
                          RelationshipTypes.relationships.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
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
                          content: Text(isEditing
                              ? 'Contact updated successfully'
                              : 'Contact added successfully'),
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
}
