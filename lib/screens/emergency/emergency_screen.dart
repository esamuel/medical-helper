import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: Text(
            'Please log in to view emergency contacts',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Emergency',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_contacts')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Error loading contacts: ${snapshot.error}');
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
                  const Text(
                    'Error loading contacts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF80CBC4),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          debugPrint('Number of contacts loaded: ${docs.length}');

          // Sort contacts in memory
          final contacts = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return MapEntry(doc.id, EmergencyContact.fromMap(data));
          }).toList()
            ..sort((a, b) {
              // First sort by primary contact (primary contacts first)
              if (a.value.isPrimaryContact != b.value.isPrimaryContact) {
                return b.value.isPrimaryContact ? 1 : -1;
              }
              // Then sort by name
              return a.value.name.compareTo(b.value.name);
            });

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emergency_outlined,
                    size: 64,
                    color: const Color(0xFF80CBC4).withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Emergency Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Add important emergency information and contacts that can be quickly accessed when needed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _addContact(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Emergency Contact',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index].value;
              final contactId = contacts[index].key;
              return _buildContactCard(contact, contactId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addContact(context),
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, String contactId) {
    return Builder(
      builder: (BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: const Color(0xFF2A2A2A),
        child: ExpansionTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF80CBC4),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (contact.isPrimaryContact)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00695C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          iconColor: const Color(0xFF80CBC4),
          collapsedIconColor: const Color(0xFF80CBC4),
          title: Text(
            contact.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            contact.relationship,
            style: TextStyle(
              color: Colors.white.withOpacity(0.87),
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      Icons.phone, 'Primary Phone', contact.phoneNumber),
                  if (contact.alternativePhone.isNotEmpty)
                    _buildInfoRow(Icons.phone_forwarded, 'Alternative Phone',
                        contact.alternativePhone),
                  if (contact.email.isNotEmpty)
                    _buildInfoRow(Icons.email, 'Email', contact.email),
                  if (contact.address.isNotEmpty)
                    _buildInfoRow(
                        Icons.location_on, 'Address', contact.address),
                  if (contact.notes.isNotEmpty)
                    _buildInfoRow(Icons.note, 'Notes', contact.notes),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.phone,
                          color: Color(0xFF80CBC4),
                        ),
                        onPressed: () =>
                            _makePhoneCall(context, contact.phoneNumber),
                      ),
                      if (contact.alternativePhone.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.phone_forwarded,
                            color: Color(0xFF80CBC4),
                          ),
                          onPressed: () =>
                              _makePhoneCall(context, contact.alternativePhone),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                        onPressed: () =>
                            _editContact(context, contact, contactId),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteContact(context, contactId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF80CBC4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteContact(BuildContext context, String contactId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Delete Contact',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this contact?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF80CBC4)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('emergency_contacts')
            .doc(contactId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact deleted'),
              backgroundColor: Color(0xFF00695C),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting contact: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _addContact(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final alternativePhoneController = TextEditingController();
    final emailController = TextEditingController();
    final relationshipController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    bool isPrimaryContact = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: alternativePhoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Alternative Phone',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Relationship *',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Primary Contact',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Set as primary emergency contact',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: isPrimaryContact,
                  onChanged: (value) {
                    setState(() => isPrimaryContact = value);
                  },
                  activeColor: const Color(0xFF80CBC4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF80CBC4)),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    relationshipController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Name, phone number, and relationship are required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('emergency_contacts')
                        .add({
                      'userId': user.uid,
                      'name': nameController.text.trim(),
                      'phoneNumber': phoneController.text.trim(),
                      'relationship': relationshipController.text.trim(),
                      'alternativePhone':
                          alternativePhoneController.text.trim(),
                      'email': emailController.text.trim(),
                      'address': addressController.text.trim(),
                      'notes': notesController.text.trim(),
                      'isPrimaryContact': isPrimaryContact,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact added successfully'),
                          backgroundColor: Color(0xFF00695C),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding contact: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editContact(
      BuildContext context, EmergencyContact contact, String contactId) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phoneNumber);
    final alternativePhoneController =
        TextEditingController(text: contact.alternativePhone);
    final emailController = TextEditingController(text: contact.email);
    final relationshipController =
        TextEditingController(text: contact.relationship);
    final addressController = TextEditingController(text: contact.address);
    final notesController = TextEditingController(text: contact.notes);
    bool isPrimaryContact = contact.isPrimaryContact;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Edit Emergency Contact',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: alternativePhoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Alternative Phone',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Relationship *',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF80CBC4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF80CBC4), width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Primary Contact',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Set as primary emergency contact',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: isPrimaryContact,
                  onChanged: (value) {
                    setState(() => isPrimaryContact = value);
                  },
                  activeColor: const Color(0xFF80CBC4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF80CBC4)),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    relationshipController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Name, phone number, and relationship are required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('emergency_contacts')
                      .doc(contactId)
                      .update({
                    'name': nameController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'relationship': relationshipController.text.trim(),
                    'alternativePhone': alternativePhoneController.text.trim(),
                    'email': emailController.text.trim(),
                    'address': addressController.text.trim(),
                    'notes': notesController.text.trim(),
                    'isPrimaryContact': isPrimaryContact,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact updated successfully'),
                        backgroundColor: Color(0xFF00695C),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating contact: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;
  final String alternativePhone;
  final String email;
  final String address;
  final String notes;
  final bool isPrimaryContact;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.alternativePhone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.isPrimaryContact = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'alternativePhone': alternativePhone,
      'email': email,
      'address': address,
      'notes': notes,
      'isPrimaryContact': isPrimaryContact,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
      alternativePhone: map['alternativePhone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      isPrimaryContact: map['isPrimaryContact'] ?? false,
    );
  }
}
