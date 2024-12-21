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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Appearance',
            [
              _buildSwitchTile(
                icon: Icons.dark_mode,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Dark Mode',
                subtitle: 'Dark theme enabled',
                value: themeProvider.isDarkMode,
                onChanged: (value) {
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
                iconColor: Theme.of(context).colorScheme.primary,
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
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Test Notifications',
                subtitle: 'Try out different notification types',
                onTap: () {
                  // Handle test notifications
                },
              ),
              _buildSwitchTile(
                icon: Icons.medication,
                iconColor: Theme.of(context).colorScheme.primary,
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
                iconColor: Theme.of(context).colorScheme.primary,
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
                iconColor: Theme.of(context).colorScheme.primary,
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
                iconColor: Theme.of(context).colorScheme.primary,
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
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Privacy Policy',
                subtitle: '',
                onTap: () {
                  // Handle privacy policy navigation
                },
              ),
              _buildNavigationTile(
                icon: Icons.description,
                iconColor: Theme.of(context).colorScheme.primary,
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
                iconColor: Theme.of(context).colorScheme.primary,
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Print Report',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
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
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 28
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        inactiveThumbColor: Theme.of(context).unselectedWidgetColor,
        inactiveTrackColor: Theme.of(context).unselectedWidgetColor.withOpacity(0.3),
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
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 28
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).iconTheme.color,
      ),
      onTap: onTap,
    );
  }
}
