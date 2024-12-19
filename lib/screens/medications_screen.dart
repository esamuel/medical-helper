import 'package:flutter/material.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMedicationCard(
            context,
            'Medication Name',
            'Dosage: 1 pill',
            'Schedule: Daily',
            Icons.medication,
            Colors.blue,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add medication screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, String name, String dosage,
      String schedule, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dosage),
            Text(schedule),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // TODO: Navigate to edit medication screen
          },
        ),
        isThreeLine: true,
      ),
    );
  }
} 