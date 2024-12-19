import 'package:flutter/material.dart';

class HealthMetricsScreen extends StatelessWidget {
  const HealthMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Metrics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricCard(
            context,
            'Blood Pressure',
            Icons.favorite,
            Colors.red,
            () {
              // TODO: Navigate to blood pressure input screen
            },
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            context,
            'Weight',
            Icons.monitor_weight,
            Colors.blue,
            () {
              // TODO: Navigate to weight input screen
            },
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            context,
            'Heart Rate',
            Icons.monitor_heart,
            Colors.purple,
            () {
              // TODO: Navigate to heart rate input screen
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show metric type selection dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        subtitle: const Text('Tap to add new measurement'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
} 