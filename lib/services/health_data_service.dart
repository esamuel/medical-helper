import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HealthDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'health_metrics';

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<Map<String, dynamic>> getHealthMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      debugPrint('Fetching health metrics');

      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .get();

      Map<String, dynamic> healthData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        healthData[id] = data;
      }

      debugPrint('Found ${healthData.length} health metrics');
      return healthData;
    } catch (e) {
      debugPrint('Error getting health metrics: $e');
      return {};
    }
  }

  Future<void> addHealthMetric({
    required String type,
    required dynamic value,
    String? unit,
    String? activity,
    String? notes,
  }) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final id = '${_userId}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore.collection(collection).doc(id).set({
        'id': id,
        'userId': _userId,
        'type': type,
        'value': value,
        'unit': unit ?? '',
        'activity': activity ?? '',
        'notes': notes ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Health metric added successfully with ID: $id');
    } catch (e) {
      debugPrint('Error adding health metric: $e');
      rethrow;
    }
  }
} 