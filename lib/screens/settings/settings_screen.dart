import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = true;
  bool allNotifications = true;
  bool medicationReminders = true;
  bool healthTracking = true;
  bool appointments = true;
  bool emergencyUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Appearance',
            [
              _buildSwitchTile(
                icon: Icons.dark_mode,
                iconColor: const Color(0xFF80CBC4),
                title: 'Dark Mode',
                subtitle: 'Dark theme enabled',
                value: isDarkMode,
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                  });
                },
              ),
            ],
          ),
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                icon: Icons.notifications,
                iconColor: const Color(0xFF80CBC4),
                title: 'All Notifications',
                subtitle: 'Enable or disable all notifications',
                value: allNotifications,
                onChanged: (value) {
                  setState(() {
                    allNotifications = value;
                  });
                },
              ),
              _buildNavigationTile(
                icon: Icons.bug_report,
                iconColor: const Color(0xFF80CBC4),
                title: 'Test Notifications',
                subtitle: 'Try out different notification types',
                onTap: () {
                  // Handle test notifications
                },
              ),
              _buildSwitchTile(
                icon: Icons.medication,
                iconColor: const Color(0xFF80CBC4),
                title: 'Medication Reminders',
                subtitle: 'Daily schedules and refill alerts',
                value: medicationReminders,
                onChanged: (value) {
                  setState(() {
                    medicationReminders = value;
                  });
                },
              ),
              _buildSwitchTile(
                icon: Icons.monitor_heart,
                iconColor: const Color(0xFF80CBC4),
                title: 'Health Tracking',
                subtitle: 'Blood pressure, sugar, and other metrics',
                value: healthTracking,
                onChanged: (value) {
                  setState(() {
                    healthTracking = value;
                  });
                },
              ),
              _buildSwitchTile(
                icon: Icons.calendar_today,
                iconColor: const Color(0xFF80CBC4),
                title: 'Appointments',
                subtitle: 'Medical visits and follow-ups',
                value: appointments,
                onChanged: (value) {
                  setState(() {
                    appointments = value;
                  });
                },
              ),
              _buildSwitchTile(
                icon: Icons.emergency,
                iconColor: const Color(0xFF80CBC4),
                title: 'Emergency Updates',
                subtitle: 'Contact verification and updates',
                value: emergencyUpdates,
                onChanged: (value) {
                  setState(() {
                    emergencyUpdates = value;
                  });
                },
              ),
            ],
          ),
          _buildSection(
            'Privacy',
            [
              _buildNavigationTile(
                icon: Icons.security,
                iconColor: const Color(0xFF80CBC4),
                title: 'Privacy Policy',
                subtitle: '',
                onTap: () {
                  // Handle privacy policy navigation
                },
              ),
              _buildNavigationTile(
                icon: Icons.description,
                iconColor: const Color(0xFF80CBC4),
                title: 'Terms of Service',
                subtitle: '',
                onTap: () {
                  // Handle terms of service navigation
                },
              ),
            ],
          ),
          _buildSection(
            'Account',
            [
              _buildNavigationTile(
                icon: Icons.person,
                iconColor: const Color(0xFF80CBC4),
                title: 'Edit Profile',
                subtitle: '',
                onTap: () {
                  // Handle edit profile navigation
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.redAccent.shade200,
                  size: 28,
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.redAccent.shade200,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  // Handle sign out
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
          _buildSection(
            'About',
            [
              const ListTile(
                leading: Icon(
                  Icons.info,
                  color: Color(0xFF80CBC4),
                  size: 28,
                ),
                title: Text(
                  'Version',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () {
                // Handle print report
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF00695C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Print Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF80CBC4),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF80CBC4),
        activeTrackColor: const Color(0xFF80CBC4).withOpacity(0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white,
      ),
      onTap: onTap,
    );
  }
}
