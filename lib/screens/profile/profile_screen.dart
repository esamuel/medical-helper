import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _formatDate(dynamic date) {
    if (date == null) return 'Not set';
    if (date is Timestamp) {
      return DateFormat('MMM d, y').format(date.toDate());
    }
    return 'Not set';
  }

  Future<void> _navigateToEditProfile(BuildContext context,
      Map<String, dynamic> userData, String userId) async {
    try {
      // Convert allergies to List<String>
      List<String> allergies = [];
      if (userData['allergies'] != null) {
        if (userData['allergies'] is List) {
          allergies =
              (userData['allergies'] as List).map((e) => e.toString()).toList();
        } else if (userData['allergies'] is String) {
          allergies = [userData['allergies'].toString()];
        }
      }

      // Convert medications to List<String>
      List<String> medications = [];
      if (userData['medications'] != null) {
        if (userData['medications'] is List) {
          medications = (userData['medications'] as List)
              .map((e) => e.toString())
              .toList();
        } else if (userData['medications'] is String) {
          medications = [userData['medications'].toString()];
        }
      }

      final user = UserModel(
        id: userId,
        email: userData['email']?.toString() ?? '',
        fullName: userData['fullName']?.toString() ?? '',
        dateOfBirth: userData['dateOfBirth'] is Timestamp
            ? (userData['dateOfBirth'] as Timestamp).toDate()
            : DateTime.now(),
        phoneNumber: userData['phoneNumber']?.toString(),
        bloodType: userData['bloodType']?.toString(),
        allergies: allergies,
        medications: medications,
        insuranceProvider: userData['insuranceProvider']?.toString(),
        insuranceNumber: userData['insuranceNumber']?.toString(),
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(user: user),
        ),
      );

      // Refresh the profile screen after returning from edit
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error navigating to edit profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Please log in to view profile',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
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

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    (userData['fullName']?.toString() ?? user.email ?? '?')[0]
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  userData['fullName']?.toString() ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoCard(
                  title: 'Personal Information',
                  items: [
                    _buildInfoItem(
                      icon: Icons.cake_outlined,
                      label: 'Date of Birth',
                      value: _formatDate(userData['dateOfBirth']),
                    ),
                    _buildInfoItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: (userData['phoneNumber'] ?? 'Not set').toString(),
                    ),
                    _buildInfoItem(
                      icon: Icons.medical_information_outlined,
                      label: 'Blood Type',
                      value: (userData['bloodType'] ?? 'Not set').toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Medical Information',
                  items: [
                    _buildInfoItem(
                      icon: Icons.medication_outlined,
                      label: 'Allergies',
                      value: _formatList(userData['allergies']),
                    ),
                    _buildInfoItem(
                      icon: Icons.local_hospital_outlined,
                      label: 'Insurance Provider',
                      value: (userData['insuranceProvider'] ?? 'Not set')
                          .toString(),
                    ),
                    _buildInfoItem(
                      icon: Icons.numbers_outlined,
                      label: 'Insurance Number',
                      value:
                          (userData['insuranceNumber'] ?? 'Not set').toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _navigateToEditProfile(context, userData, user.uid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatList(dynamic list) {
    if (list == null) return 'None';
    if (list is List && list.isEmpty) return 'None';
    if (list is List) return list.join(', ');
    return list.toString();
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).iconTheme.color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
