import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _firestore;
  final String collection = 'medications';
  final String? _userId;

  // Add public getter for userId
  String? get userId => _userId;

  MedicationService({String? userId}) 
    : _userId = userId,
      _firestore = FirebaseFirestore.instance {
    debugPrint('MedicationService initialized with user ID: $_userId');
  }

  Future<String> addMedication(MedicationModel medication) async {
    if (_userId == null) throw Exception('User not authenticated');
    try {
      // Convert the TimeOfDay to a string in the format "HH:mm"
      final defaultTimeStr = '${medication.defaultTime.hour.toString().padLeft(2, '0')}:${medication.defaultTime.minute.toString().padLeft(2, '0')}';
      
      final data = {
        'name': medication.name,
        'dosage': medication.dosage,
        'frequency': medication.frequency.index,
        'instructions': medication.instructions,
        'startDate': Timestamp.fromDate(medication.startDate),
        'userId': medication.userId,
        'defaultTime': defaultTimeStr,
      };
      
      debugPrint('Adding medication to Firestore: $data');
      final docRef = await _firestore
          .collection(collection)
          .add(data);
      debugPrint('Successfully added medication with ID: ${docRef.id}');
      
      // Verify the document was created
      final newDoc = await docRef.get();
      debugPrint('Verification - New document data: ${newDoc.data()}');
      
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('Error adding medication: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<MedicationModel>> getMedications() {
    debugPrint('getMedications called with user ID: $_userId');
    if (_userId == null) {
      debugPrint('getMedications: No user ID available');
      return Stream.value([]);
    }
    
    // First, let's check if the collection exists and has any documents
    _firestore.collection(collection).get().then((snapshot) {
      debugPrint('Total documents in collection: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        debugPrint('Document ${doc.id} data: ${doc.data()}');
      }
    }).catchError((error) {
      debugPrint('Error checking collection: $error');
    });

    final query = _firestore
        .collection(collection)
        .where('userId', isEqualTo: _userId);
    
    debugPrint('Querying Firestore collection: $collection where userId = $_userId');
    
    return query
        .snapshots()
        .map((snapshot) {
          try {
            debugPrint('getMedications: Got ${snapshot.docs.length} documents');
            if (snapshot.docs.isEmpty) {
              debugPrint('No medications found for user $_userId');
            } else {
              for (var doc in snapshot.docs) {
                debugPrint('Found document ${doc.id} with data: ${doc.data()}');
              }
            }
            return snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                debugPrint('Processing document ${doc.id}: $data');
                
                // Ensure all required fields are present
                if (!data.containsKey('defaultTime')) {
                  // If defaultTime is missing but takingTimes is present, use the first taking time
                  if (data.containsKey('takingTimes') && (data['takingTimes'] as List).isNotEmpty) {
                    data['defaultTime'] = (data['takingTimes'] as List)[0];
                  } else {
                    // Default to 8:00 AM if no time is specified
                    data['defaultTime'] = '08:00';
                  }
                }
                
                return MedicationModel.fromMap(data, doc.id);
              } catch (e, stackTrace) {
                debugPrint('Error processing medication document ${doc.id}: $e');
                debugPrint('Stack trace: $stackTrace');
                rethrow;
              }
            }).toList();
          } catch (e, stackTrace) {
            debugPrint('Error processing medications snapshot: $e');
            debugPrint('Stack trace: $stackTrace');
            rethrow;
          }
        });
  }

  Future<void> updateMedication(String id, MedicationModel medication) async {
    if (_userId == null) throw Exception('User not authenticated');
    try {
      debugPrint('Updating medication with ID: $id');
      await _firestore
          .collection(collection)
          .doc(id)
          .update(medication.toMap());
      debugPrint('Successfully updated medication');
    } catch (e, stackTrace) {
      debugPrint('Error updating medication: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteMedication(String id) async {
    if (_userId == null) throw Exception('User not authenticated');
    try {
      debugPrint('Deleting medication with ID: $id');
      await _firestore
          .collection(collection)
          .doc(id)
          .delete();
      debugPrint('Successfully deleted medication');
    } catch (e, stackTrace) {
      debugPrint('Error deleting medication: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
