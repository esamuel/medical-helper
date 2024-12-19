import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'add_blood_pressure_screen.dart';
import 'add_weight_screen.dart';
import 'add_heart_rate_screen.dart';

class HealthDataScreen extends StatelessWidget {
  const HealthDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Data'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Blood Pressure'),
              Tab(text: 'Weight'),
              Tab(text: 'Heart Rate'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMetricList(
              context,
              'blood_pressure',
              (data) => '${data['systolic']}/${data['diastolic']} mmHg',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBloodPressureScreen(),
                ),
              ),
            ),
            _buildMetricList(
              context,
              'weight',
              (data) => '${data['weight']} kg',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddWeightScreen(),
                ),
              ),
            ),
            _buildMetricList(
              context,
              'heart_rate',
              (data) => '${data['value']} bpm',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddHeartRateScreen(),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final currentIndex = DefaultTabController.of(context).index;
            switch (currentIndex) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddBloodPressureScreen(),
                  ),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddWeightScreen(),
                  ),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddHeartRateScreen(),
                  ),
                );
                break;
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMetricList(BuildContext context, String collection,
      String Function(Map<String, dynamic>) formatValue, VoidCallback onAdd) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No data available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAdd,
                  child: const Text('Add First Entry'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp).toDate();

            return Card(
              child: ListTile(
                title: Text(formatValue(data)),
                subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(timestamp)),
                trailing: data['notes']?.isNotEmpty == true
                    ? IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Notes'),
                              content: Text(data['notes']),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
} 