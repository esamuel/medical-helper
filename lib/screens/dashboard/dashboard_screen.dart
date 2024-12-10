import 'package:flutter/material.dart';
import '../health/health_data_screen.dart';
import '../medications/medications_screen.dart';
import '../contacts/emergency_contacts_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Helper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
        children: [
          _buildDashboardCard(
            context,
            'Health Data',
            Icons.favorite,
            'Track your vital signs and health metrics',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HealthDataScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Medications',
            Icons.medication,
            'Manage your medications and reminders',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MedicationsScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Emergency Contacts',
            Icons.emergency,
            'Quick access to important contacts',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Profile',
            Icons.person,
            'Manage your personal information',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 