import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../test_notifications_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          // Appearance Section
          const _SectionHeader(title: 'Appearance'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          const Divider(),

          // Notifications Section
          const _SectionHeader(title: 'Notifications'),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Column(
                children: [
                  SwitchListTile(
                    title: const Text('All Notifications'),
                    subtitle: const Text('Enable or disable all notifications'),
                    secondary: Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    value: notificationProvider.allNotifications,
                    onChanged: (bool value) {
                      notificationProvider.toggleAllNotifications(value);
                    },
                  ),
                  ListTile(
                    title: const Text('Test Notifications'),
                    subtitle: const Text('Try out different notification types'),
                    leading: Icon(
                      Icons.bug_report_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TestNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Medication Reminders'),
                    subtitle: const Text('Daily schedules and refill alerts'),
                    leading: Icon(
                      Icons.medication_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: Switch(
                      value: notificationProvider.medicationReminders,
                      onChanged: notificationProvider.allNotifications
                          ? (bool value) {
                              notificationProvider.toggleMedicationReminders(value);
                            }
                          : null,
                    ),
                  ),
                  ListTile(
                    title: const Text('Health Tracking'),
                    subtitle: const Text('Blood pressure, sugar, and other metrics'),
                    leading: Icon(
                      Icons.monitor_heart_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: Switch(
                      value: notificationProvider.healthTracking,
                      onChanged: notificationProvider.allNotifications
                          ? (bool value) {
                              notificationProvider.toggleHealthTracking(value);
                            }
                          : null,
                    ),
                  ),
                  ListTile(
                    title: const Text('Appointments'),
                    subtitle: const Text('Medical visits and follow-ups'),
                    leading: Icon(
                      Icons.calendar_today_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: Switch(
                      value: notificationProvider.appointments,
                      onChanged: notificationProvider.allNotifications
                          ? (bool value) {
                              notificationProvider.toggleAppointments(value);
                            }
                          : null,
                    ),
                  ),
                  ListTile(
                    title: const Text('Emergency Updates'),
                    subtitle: const Text('Contact verification and updates'),
                    leading: Icon(
                      Icons.emergency_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: Switch(
                      value: notificationProvider.emergencyUpdates,
                      onChanged: notificationProvider.allNotifications
                          ? (bool value) {
                              notificationProvider.toggleEmergencyUpdates(value);
                            }
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // Privacy Section
          const _SectionHeader(title: 'Privacy'),
          ListTile(
            leading: Icon(
              Icons.security_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // Account Section
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to Edit Profile
            },
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () {
              // TODO: Implement sign out
            },
          ),
          const Divider(),

          // About Section
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 