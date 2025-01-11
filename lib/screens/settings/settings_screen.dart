import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool allNotifications = true;
  bool medicationReminders = true;
  bool healthTracking = true;
  bool appointments = true;
  bool emergencyUpdates = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF00695C) : Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: const TextStyle(
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
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
                title: 'Dark Mode',
                subtitle: 'Dark theme enabled',
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                icon: Icons.notifications,
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
                title: 'Test Notifications',
                subtitle: 'Try out different notification types',
                onTap: () {
                  // Handle test notifications
                },
              ),
              _buildSwitchTile(
                icon: Icons.medication,
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
                title: 'Privacy Policy',
                subtitle: '',
                onTap: () {
                  // Handle privacy policy navigation
                },
              ),
              _buildNavigationTile(
                icon: Icons.description,
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
                iconColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
          _buildSection(
            'About',
            [
              ListTile(
                leading: Icon(
                  Icons.info,
                  color: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
                  size: 28,
                ),
                title: Text(
                  'Version',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
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
                backgroundColor: themeProvider.isDarkMode ? const Color(0xFF00695C) : Colors.blue,
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
    final themeProvider = context.watch<ThemeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
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
    final themeProvider = context.watch<ThemeProvider>();
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54,
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue,
        activeTrackColor: (themeProvider.isDarkMode ? const Color(0xFF80CBC4) : Colors.blue).withOpacity(0.3),
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
    final themeProvider = context.watch<ThemeProvider>();
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54,
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
