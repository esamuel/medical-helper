import 'package:flutter/material.dart';
import 'health/health_data_screen.dart';
import 'medications/medications_screen.dart';
import 'profile/profile_screen.dart';
import 'emergency_contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<(Widget, String)> _screens = [
    (const HealthDataScreen(), 'Health Data'),
    (const MedicationsScreen(), 'Medications'),
    (const EmergencyContactsScreen(), 'Emergency Contacts'),
    (const ProfileScreen(), 'Profile'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _selectedIndex == 0 ? null : AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          _screens[_selectedIndex].$2,
          style: TextStyle(color: theme.appBarTheme.foregroundColor),
        ),
      ),
      body: SafeArea(
        child: _screens[_selectedIndex].$1,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medications',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Emergency',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}