import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
  unknown
}

extension BloodTypeExtension on BloodType {
  String get display {
    switch (this) {
      case BloodType.aPositive: return 'A+';
      case BloodType.aNegative: return 'A-';
      case BloodType.bPositive: return 'B+';
      case BloodType.bNegative: return 'B-';
      case BloodType.abPositive: return 'AB+';
      case BloodType.abNegative: return 'AB-';
      case BloodType.oPositive: return 'O+';
      case BloodType.oNegative: return 'O-';
      case BloodType.unknown: return 'Unknown';
    }
  }
}

enum Gender {
  male,
  female,
  other,
  preferNotToSay
}

extension GenderExtension on Gender {
  String get display {
    switch (this) {
      case Gender.male: return 'Male';
      case Gender.female: return 'Female';
      case Gender.other: return 'Other';
      case Gender.preferNotToSay: return 'Prefer not to say';
    }
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController(text: '1.7');
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  DateTime? _dateOfBirth;
  BloodType _bloodType = BloodType.unknown;
  Gender _gender = Gender.preferNotToSay;
  bool _isLoading = true;
  bool _isEditing = false;
  
  String? _allergies;
  String? _medications;
  String? _chronicConditions;
  String? _primaryPhysician;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to view your profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          
          // Handle height value safely
          try {
            final heightValue = data['height'];
            if (heightValue is num) {
              _heightController.text = heightValue.toDouble().toString();
            } else if (heightValue is String) {
              final parsedHeight = double.tryParse(heightValue);
              _heightController.text = (parsedHeight ?? 1.7).toString();
            } else {
              _heightController.text = '1.7';
            }
          } catch (e) {
            _heightController.text = '1.7';
          }

          _addressController.text = data['address'] ?? '';
          
          // Handle date conversion safely
          try {
            _dateOfBirth = data['dateOfBirth'] != null 
                ? (data['dateOfBirth'] as Timestamp).toDate()
                : null;
          } catch (e) {
            _dateOfBirth = null;
          }

          // Handle enums safely
          try {
            _bloodType = BloodType.values[data['bloodType'] ?? BloodType.unknown.index];
          } catch (e) {
            _bloodType = BloodType.unknown;
          }

          try {
            _gender = Gender.values[data['gender'] ?? Gender.preferNotToSay.index];
          } catch (e) {
            _gender = Gender.preferNotToSay;
          }

          // Handle string fields safely
          _allergies = data['allergies']?.toString();
          _medications = data['medications']?.toString();
          _chronicConditions = data['chronicConditions']?.toString();
          _primaryPhysician = data['primaryPhysician']?.toString();
          
          _isLoading = false;
        });
      } else {
        // Create default profile if it doesn't exist
        final defaultData = {
          'fullName': '',
          'email': _auth.currentUser?.email ?? '',
          'height': 1.7,
          'bloodType': BloodType.unknown.index,
          'gender': Gender.preferNotToSay.index,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(userId).set(defaultData);

        setState(() {
          _emailController.text = _auth.currentUser?.email ?? '';
          _heightController.text = '1.7';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _heightController.text = '1.7';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final profileData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'height': double.parse(_heightController.text),
        'address': _addressController.text.trim(),
        'dateOfBirth': _dateOfBirth != null ? Timestamp.fromDate(_dateOfBirth!) : null,
        'bloodType': _bloodType.index,
        'gender': _gender.index,
        'allergies': _allergies?.trim(),
        'medications': _medications?.trim(),
        'chronicConditions': _chronicConditions?.trim(),
        'primaryPhysician': _primaryPhysician?.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Check if document exists
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update(profileData);
      } else {
        await docRef.set(profileData);
      }

      if (!mounted) return;
      
      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Widget _buildHeightConversions() {
    try {
      final height = double.parse(_heightController.text);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Height in other units:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${(height * 100).toStringAsFixed(1)} cm',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '${(height * 39.3701).toStringAsFixed(1)} inches',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '${((height * 39.3701) / 12).floor()}\' ${((height * 39.3701) % 12).toStringAsFixed(1)}"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Gender>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: Gender.values.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender.display),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() => _gender = value);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _isEditing ? _selectDate : null,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _dateOfBirth != null
                                ? DateFormat('MMM d, y').format(_dateOfBirth!)
                                : 'Not set',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<BloodType>(
                        value: _bloodType,
                        decoration: const InputDecoration(
                          labelText: 'Blood Type',
                          border: OutlineInputBorder(),
                        ),
                        items: BloodType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.display),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() => _bloodType = value);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _heightController,
                        enabled: _isEditing,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Height (m)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height < 0.5 || height > 2.5) {
                            return 'Please enter a valid height (0.5-2.5 m)';
                          }
                          return null;
                        },
                      ),
                      if (!_isEditing) ...[
                        const SizedBox(height: 8),
                        _buildHeightConversions(),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _allergies,
                        enabled: _isEditing,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Allergies',
                          hintText: 'List any allergies',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _allergies = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _medications,
                        enabled: _isEditing,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Current Medications',
                          hintText: 'List any medications you are currently taking',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _medications = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _chronicConditions,
                        enabled: _isEditing,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Chronic Conditions',
                          hintText: 'List any chronic conditions or ongoing health issues',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _chronicConditions = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _primaryPhysician,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Primary Physician',
                          hintText: 'Name and contact information',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _primaryPhysician = value,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        enabled: _isEditing,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
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