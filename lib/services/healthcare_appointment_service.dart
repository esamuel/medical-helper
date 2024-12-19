import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/healthcare_appointment.dart';

class HealthcareAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collection = 'healthcare_appointments';

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<String> addAppointment(HealthcareAppointment appointment) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final data = appointment.toMap();
      final docRef = await _firestore.collection(collection).add({
        ...data,
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Appointment saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      rethrow;
    }
  }

  Future<void> updateAppointment(HealthcareAppointment appointment) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }
      if (appointment.id == null) {
        throw Exception('Appointment ID is required for update');
      }

      final data = appointment.toMap();
      await _firestore
          .collection(collection)
          .doc(appointment.id)
          .update({
            ...data,
            'userId': _userId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      debugPrint('Appointment updated successfully');
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection(collection).doc(appointmentId).delete();
      debugPrint('Appointment deleted successfully');
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      rethrow;
    }
  }

  Stream<List<HealthcareAppointment>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      if (_userId.isEmpty) {
        return Stream.value([]);
      }

      var query = _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .orderBy('appointmentDate', descending: false);

      if (startDate != null) {
        query = query.where('appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return HealthcareAppointment.fromMap(data, doc.id);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting appointments stream: $e');
      return Stream.value([]);
    }
  }

  Stream<List<HealthcareAppointment>> getUpcomingAppointments() {
    try {
      if (_userId.isEmpty) {
        return Stream.value([]);
      }

      final now = DateTime.now();
      var query = _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .orderBy('appointmentDate', descending: false);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return HealthcareAppointment.fromMap(data, doc.id);
          })
          .where((appointment) => appointment.appointmentDate.isAfter(now))
          .toList();
      });
    } catch (e) {
      debugPrint('Error getting upcoming appointments: $e');
      return Stream.value([]);
    }
  }

  Future<List<HealthcareAppointment>> getAppointmentsByProvider(String provider) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .where('provider', isEqualTo: provider)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return HealthcareAppointment.fromMap(data, doc.id);
          })
          .toList();
    } catch (e) {
      debugPrint('Error getting appointments by provider: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsForReport() async {
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
                'date': (doc.data()['appointmentDate'] as Timestamp).toDate(),
                'provider': doc.data()['provider'] ?? '',
                'purpose': doc.data()['purpose'] ?? '',
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting appointments: $e');
      return [];
    }
  }
}
