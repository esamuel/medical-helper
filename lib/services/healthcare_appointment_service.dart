import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/healthcare_appointment.dart';

class HealthcareAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collection = 'healthcare_appointments';

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<String> addAppointment(HealthcareAppointment appointment) async {
    print('Starting to add appointment'); // Debug print
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final data = appointment.toMap();
      print('Appointment data to save: $data'); // Debug print

      final docRef = await _firestore.collection(collection).add({
        ...data,
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Appointment saved with ID: ${docRef.id}'); // Debug print
      return docRef.id;
    } catch (e, stackTrace) {
      print('Error adding appointment: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<void> updateAppointment(HealthcareAppointment appointment) async {
    print('Starting to update appointment: ${appointment.id}'); // Debug print
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }
      if (appointment.id == null) {
        throw Exception('Appointment ID is required for update');
      }

      final data = appointment.toMap();
      print('Appointment data to update: $data'); // Debug print

      await _firestore
          .collection(collection)
          .doc(appointment.id)
          .update({
            ...data,
            'userId': _userId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('Appointment updated successfully'); // Debug print
    } catch (e, stackTrace) {
      print('Error updating appointment: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    print('Starting to delete appointment: $appointmentId'); // Debug print
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection(collection).doc(appointmentId).delete();
      print('Appointment deleted successfully'); // Debug print
    } catch (e, stackTrace) {
      print('Error deleting appointment: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Stream<List<HealthcareAppointment>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    print('Getting appointments for user: $_userId'); // Debug print
    try {
      if (_userId.isEmpty) {
        print('No user ID - returning empty stream'); // Debug print
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
        print('Received ${snapshot.docs.length} appointments'); // Debug print
        return snapshot.docs.map((doc) {
          final data = doc.data();
          print('Document data: $data'); // Debug print
          return HealthcareAppointment.fromMap(data, doc.id);
        }).toList();
      });
    } catch (e, stackTrace) {
      print('Error getting appointments: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      return Stream.value([]);
    }
  }

  Stream<List<HealthcareAppointment>> getUpcomingAppointments() {
    print('Getting upcoming appointments for user: $_userId'); // Debug print
    try {
      if (_userId.isEmpty) {
        print('No user ID - returning empty stream'); // Debug print
        return Stream.value([]);
      }

      final now = DateTime.now();
      var query = _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          // Temporarily remove the date filter until index is built
          .orderBy('appointmentDate', descending: false);

      return query.snapshots().map((snapshot) {
        print('Received ${snapshot.docs.length} appointments'); // Debug print
        return snapshot.docs
          .map((doc) {
            final data = doc.data();
            print('Document data: $data'); // Debug print
            return HealthcareAppointment.fromMap(data, doc.id);
          })
          // Filter the appointments in memory instead
          .where((appointment) => appointment.appointmentDate.isAfter(now))
          .toList();
      });
    } catch (e, stackTrace) {
      print('Error getting upcoming appointments: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      return Stream.value([]);
    }
  }

  Future<List<HealthcareAppointment>> getAppointmentsByProvider(String provider) async {
    print('Getting appointments by provider: $provider'); // Debug print
    try {
      if (_userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: _userId)
          .where('provider', isEqualTo: provider)
          .get();

      print('Received ${snapshot.docs.length} appointments by provider'); // Debug print
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            print('Document data: $data'); // Debug print
            return HealthcareAppointment.fromMap(data, doc.id);
          })
          .toList();
    } catch (e, stackTrace) {
      print('Error getting appointments by provider: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }
}
