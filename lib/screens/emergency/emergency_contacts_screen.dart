import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? alternativePhone;
  final String? email;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.alternativePhone,
    this.email,
    this.isPrimary = false,
  });
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<EmergencyContact> _contacts = [];
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternativePhoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _alternativePhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await url_launcher.canLaunchUrl(phoneUri)) {
      await url_launcher.launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name*',
                  labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _relationshipController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Relationship*',
                  labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number*',
                  labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4), width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _alternativePhoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Alternative Phone',
                  labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4), width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color(0xFF80CBC4)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF80CBC4), width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF80CBC4)),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty &&
                  _relationshipController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty) {
                setState(() {
                  _contacts.add(
                    EmergencyContact(
                      name: _nameController.text,
                      relationship: _relationshipController.text,
                      phoneNumber: _phoneController.text,
                      alternativePhone: _alternativePhoneController.text.isEmpty
                          ? null
                          : _alternativePhoneController.text,
                      email: _emailController.text.isEmpty
                          ? null
                          : _emailController.text,
                      isPrimary: _contacts.isEmpty,
                    ),
                  );
                });
                Navigator.pop(context);
                _clearControllers();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
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
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _relationshipController.clear();
    _phoneController.clear();
    _alternativePhoneController.clear();
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
      ),
      body: _contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_phone_outlined,
                    size: 64,
                    color: const Color(0xFF80CBC4).withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No emergency contacts yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add contacts that should be notified in case of emergency',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: const Color(0xFF2A2A2A),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF80CBC4),
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          contact.relationship,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.87),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.phoneNumber,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        if (contact.alternativePhone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Alt: ${contact.alternativePhone}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (contact.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            contact.email!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.phone,
                            color: Color(0xFF80CBC4),
                          ),
                          onPressed: () => _makePhoneCall(contact.phoneNumber),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _contacts.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
