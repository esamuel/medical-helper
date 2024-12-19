import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _firestore;
  final String collection = 'medications';

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  MedicationService() : _firestore = FirebaseFirestore.instance;

  Future<String> addMedication(MedicationModel medication) async {
    try {
      final docRef = await _firestore.collection(collection).add(medication.toMap());
      debugPrint('Successfully added medication with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  Future<void> updateMedication(MedicationModel medication) async {
    try {
      await _firestore
          .collection(collection)
          .doc(medication.id)
          .update(medication.toMap());
      debugPrint('Successfully updated medication with ID: ${medication.id}');
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _firestore.collection(collection).doc(medicationId).delete();
      debugPrint('Successfully deleted medication with ID: $medicationId');
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  Stream<List<MedicationModel>> getMedicationsForUser(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.docs.isEmpty) {
              return [];
            }

            final medications = snapshot.docs
                .map((doc) {
                  try {
                    return MedicationModel.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    debugPrint('Error converting document to MedicationModel: $e');
                    return null;
                  }
                })
                .where((med) => med != null)
                .cast<MedicationModel>()
                .toList();
            
            medications.sort((a, b) => b.startDate.compareTo(a.startDate));
            return medications;
          } catch (e) {
            debugPrint('Error processing medications stream: $e');
            return [];
          }
        });
  }

  Future<MedicationModel?> getMedication(String medicationId) async {
    try {
      final doc = await _firestore.collection(collection).doc(medicationId).get();
      if (!doc.exists) {
        return null;
      }
      return MedicationModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting medication: $e');
      rethrow;
    }
  }

  // Get all medications for the current user (for report)
  Future<List<Map<String, dynamic>>> getMedications() async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .get();

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
                'name': doc.data()['name'] ?? '',
                'dosage': doc.data()['dosage'] ?? '',
                'schedule': doc.data()['schedule'] ?? '',
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting medications: $e');
      return [];
    }
  }
} 