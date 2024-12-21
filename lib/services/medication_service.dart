import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _firestore;
  final String collection = 'medications';

  MedicationService() : _firestore = FirebaseFirestore.instance {
    debugPrint('Initializing MedicationService');
  }

  Future<String> addMedication(MedicationModel medication) async {
    try {
      debugPrint('Adding medication to Firestore: ${medication.toMap()}');
      final docRef =
          await _firestore.collection(collection).add(medication.toMap());
      debugPrint('Successfully added medication with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('Error adding medication: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateMedication(MedicationModel medication) async {
    try {
      debugPrint('Updating medication in Firestore: ${medication.toMap()}');
      await _firestore
          .collection(collection)
          .doc(medication.id)
          .update(medication.toMap());
      debugPrint('Successfully updated medication with ID: ${medication.id}');
    } catch (e, stackTrace) {
      debugPrint('Error updating medication: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      debugPrint('Deleting medication from Firestore: $medicationId');
      await _firestore.collection(collection).doc(medicationId).delete();
      debugPrint('Successfully deleted medication with ID: $medicationId');
    } catch (e, stackTrace) {
      debugPrint('Error deleting medication: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<MedicationModel>> getMedicationsStream(String userId) {
    debugPrint('Getting medications stream for user: $userId');
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        debugPrint(
            'Processing ${snapshot.docs.length} medications from stream');
        final medications = snapshot.docs
            .map((doc) {
              final data = doc.data();
              debugPrint('Processing document: ${doc.id}');

              try {
                final medication = MedicationModel.fromMap(data, doc.id);
                debugPrint(
                    'Successfully converted to MedicationModel: ${medication.name}');
                return medication;
              } catch (e, stackTrace) {
                debugPrint('Error converting document to MedicationModel: $e');
                debugPrint('Stack trace: $stackTrace');
                return null;
              }
            })
            .where((med) => med != null) // Filter out null medications
            .cast<MedicationModel>() // Cast to non-null MedicationModel
            .toList();

        medications.sort((a, b) => b.startDate.compareTo(a.startDate));
        debugPrint('Returning ${medications.length} sorted medications');
        for (var med in medications) {
          debugPrint('Medication in list: ${med.name} (${med.id})');
        }
        return medications;
      } catch (e, stackTrace) {
        debugPrint('Error processing medications stream: $e');
        debugPrint('Stack trace: $stackTrace');
        return []; // Return empty list instead of throwing
      }
    });
  }

  Future<MedicationModel?> getMedication(String medicationId) async {
    try {
      debugPrint('Getting medication from Firestore: $medicationId');
      final doc =
          await _firestore.collection(collection).doc(medicationId).get();
      if (!doc.exists) {
        debugPrint('No medication found with ID: $medicationId');
        return null;
      }
      debugPrint('Found medication: ${doc.data()}');
      return MedicationModel.fromMap(doc.data()!, doc.id);
    } catch (e, stackTrace) {
      debugPrint('Error getting medication: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
